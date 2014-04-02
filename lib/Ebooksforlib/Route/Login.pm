package Ebooksforlib::Route::Login;

=head1 Ebooksforlib::Route::Login

Routes for handling login and logout. 

=cut

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::Email;
use Dancer::Plugin::FlashMessage;
use Dancer::Plugin::Lexicon;
use Dancer::Exception qw(:all);
use Ebooksforlib::Util;
use Data::Dumper; # FIXME Debug
use Digest::SHA3 qw(sha3_512_hex);
use Try::Tiny;

get '/in' => sub {
    template 'login', { disable_search => 1, };
};

post '/in' => sub {
    
    my $username  = lc( param 'username' );
    my $password  = param 'password';
    my $userrealm;

    # Remove whitespace around username
    $username =~ s/^ {1,}//;
    $username =~ s/ {1,}$//;
    
    # TODO Check the format of the username
    
    # Do a quick check to see if this user is blocked after too many failed logins
    my $checkuser = resultset('User')->find({ 'username' => $username });
    if ( $checkuser && $checkuser->failed >= setting( 'max_failed_logins' ) ) {
        $checkuser->update({ 'failed' => $checkuser->failed + 1 });
        debug "*** User $username blocked, " . $checkuser->failed . " failed logins";
        return redirect '/blocked';
    }
    
    # Find the realm we should try to athenticate against
    if ( param 'realm' ) {
        $userrealm = param 'realm';
    } elsif( session('chosen_library') ) {
        # /library/set/x (where x = library id) is run when a user chooses a library, 
        # which she has to do to be able to do anything on the site. This route sets 
        # to session variables:
        #   session chosen_library => $library->id;
        #   session chosen_library_name => $library->name;
        # We need to find the realm, based on chosen_library:
        my $library = rset('Library')->find( session('chosen_library') );
        $userrealm = $library->realm;
    } else {
        return redirect '/';
    }
    debug "=== Userrealm: $userrealm";

    # Try Nasjonalt lånekort first, but not for admins with realm = local
    # Also check that realms are defined before we try to authenticate against 
    # them. An undefined realm could happen for a library that has not configured
    # either Nasjonalt lånekort or SIP2
    my ( $success, $realm );
    my $realms = config->{'plugins'}->{'Auth::Extensible'}->{'realms'};
    # Try Nasjonalt lånekort
    my $nl_realm = $userrealm . '_nl';
    if ( $userrealm ne 'local' && defined $realms->{ $nl_realm } ) {
        debug "=== Trying Nasjonalt lånekort: $username, x, $nl_realm";
        ( $success, $realm ) = authenticate_user( $username, $password, $nl_realm );
    } else {
        debug "=== Skipping Nasjonalt lånekort: $username, x, $nl_realm";
    }
    # Try the fallback (probably local ILS over SIP2) if that did not succeed
    if ( !$success && defined $realms->{ $userrealm } ) {
        debug "=== Trying fallback: $username, x, $userrealm";
        ( $success, $realm ) = authenticate_user( $username, $password, $userrealm );
    } else {
        debug "=== Skipping fallback: $username, x, $userrealm";
    }
    # Check if any of the above worked
    if ($success) {

        ## SUCCESSFULL LOGIN

        # Destroy the temporary session, to avoid problems related to session fixation
        session->destroy;
        debug "+++ Temporary session was destroyed after sucessfull login, to prevent session fixation";

        debug "=== Successfull login for $username, x, $realm";
        session logged_in_user => $username;
        # Set the realm to be the real realm temporarily, we will change this later
        session logged_in_user_realm => $realm;
        # Also keep the real realm around in case we need it
        session logged_in_user_real_realm => $realm;
        
        # Get the data about the logged_in_user and store some of it in the session
        my $user = logged_in_user;
        debug "??? User: " . Dumper $user;
        session logged_in_user_name => $user->{name};

        # Store roles in the session (will be used in the templates)
        # FIXME Looks like this does not work
        session logged_in_user_roles => user_roles;
        
        # Create a CSRF token and store it in the session
        session csrftoken => sha3_512_hex( time(), $username, rand(10000000) );

        # Update the local user or create a new one
        my $new_user = rset('User')->update_or_new({
            username => $username,
            name     => $user->{name},
            email    => $user->{email},
            gender   => $user->{gender},
            birthday => $user->{birthday},
            zipcode  => $user->{zipcode},
            place    => $user->{place},
        }, { 
            key => 'username' 
        });

        if( ! $new_user->in_storage ) {
            # do some stuff
            $new_user->insert;
            debug "*** User $username was added, with id = " . $new_user->id;
            # Connect this user to the correct library based on the realm
            # used to sign in
            debug '*** Going to look up library with realm = ' . $userrealm;
            my $library = rset('Library')->find({ realm => $userrealm });
            if ( $library ) {
                debug '*** Going to connect to library with id = ' . $library->id;
                try {
                    rset('UserLibrary')->create({
                        user_id    => $new_user->id, 
                        library_id => $library->id, 
                    });
                    debug '*** Connected: user = ' . $new_user->id . " + library = " . $library->id;
                } catch {
                    # This is a serious error! 
                    debug '*** NOT connected: user = ' . $new_user->id . " + library = " . $library->id;
                    my $error = $_;
                    $error =~ s/\r//g;
                    debug "ERROR: $error";
                    error '*** Error when trying to connect user ' . $new_user->id . ' to library ' . $library->id;
                };
            } else {
                error '*** Could not find library with realm = ' . $userrealm;
            }
            flash info => "Welcome, new user!";
        } else {
            # We are updating an old user
            debug "*** User $username was updated";
            # Reset the counter for failed logins
            $new_user->update({ 'failed' => 0 });
        }
        
        session logged_in_user_id => $new_user->id;

        # Now we need to store the connection to a library in the session
        # This will override any previous choice, but that should be OK.
        # TODO We assume that a user will only be connected to one library. 
        # As long as we are only using SIP2 that should be OK. When/if
        # the national library card is implemented we should let users who
        # are connected to more than one library choose which one they want 
        # to be their chosen library after they log in.
        my @libraries = $new_user->libraries;
        if ( $libraries[0] ) {
            session chosen_library      => $libraries[0]->id;
            session chosen_library_name => $libraries[0]->name;
        } else {
            session chosen_library      => 10000;
            session chosen_library_name => 'x';
        }
        
        # Set the realm to be the local database so that further calls to 
        # logged_in_user will talk to the database, not SIP2
        session logged_in_user_realm => 'local';
        
        # Set a cookie that can be used by the reader app to check if users 
        # are logged in etc, unlesss this cookie already exists and matches the
        # user we are logging in now
        my $set_ebib_cookie = 1;
        if ( cookie 'ebib' && cookie 'ebib' ne '' ) {
            debug "*** Cookie: " . cookie 'ebib';
            # Should we set a new cookie? 
            my $cookie = from_json( cookie 'ebib' );
            if ( $cookie->{'uid'} eq $new_user->id && $cookie->{'username'} eq $new_user->username ) {
                $set_ebib_cookie = 0;
                debug "*** We should NOT set a new cookie";
            } else {
                debug "*** We should set a new cookie";
            }
        }
        if ( $set_ebib_cookie ) {
            # Set a new cookie
            # my $now = DateTime->now;
            # my $hash = md5_hex( $new_user->id . $new_user->username . $now->datetime() );
            my %data = (
                'uid'             => $new_user->id,
                'username'        => $new_user->username,
                'name'            => $new_user->name,
                'realm'           => $realm,
                'realmprettyname' => session( 'chosen_library_name' ),
                # 'hash'     => $hash,
            );
            # Set a cookie with a domain
            my $cookie = Dancer::Cookie->new(
                'name'      => 'ebib', 
                'value'     => to_json( \%data ),
                'domain'    => setting('session_domain'),
                'http_only' => 0, # The reader needs this to be not HttpOnly
                'secure'    => 1,
            );
            debug $cookie->to_header;
            header 'Set-Cookie' => $cookie->to_header;
            
        }

        # Log
        _log2db({
            logcode => 'LOGIN',
            logmsg  => "Username: $username, realm: $realm",
        });
        
        # Keep track of the session for this user
        my $current_session_id = cookie( 'dancer.session' );
        resultset('Sessioncount')->create({
            session_id => $current_session_id,
            user_id    => $new_user->id, 
            ip         => request->remote_address,
            ua         => request->user_agent,
        });
        # Check if this user has other active sessions
        # This should pick up e.g. stolen usernames/passwords
        my @sessions = resultset('Sessioncount')->search({
            user_id    => $new_user->id, 
        });
        my @activesessions;
        foreach my $session ( @sessions ) {
            my $session_id = $session->session_id;
            next if $session_id eq $current_session_id;
            debug "*** Checking session_id = $session_id";
            my $retrieved_session = Dancer::Session::DBI->retrieve( $session_id );
            if ( $retrieved_session ) {
                # flash error => "WARNING! You have more than one active session!";
                push @activesessions, $session;
                debug "*** Active session: $session_id";
            } else {
                debug "*** Inactive session: $session_id";
            }
        }
        debug '*** Done testing sessions';
        if ( scalar @activesessions > 0 ) {
            # Log the incident
            _log2db({
                logcode => 'MULTISESSION',
                logmsg  => "Username: $username, ID: " . $new_user->id,
            });
            error "MULTISESSION - Username: $username, ID: " . $new_user->id;
            # Send an email to the user, if we have an email
            if ( $new_user->email ) {
                # TODO Translation! 
                my $body = l("It looks like you have more than one active session. If you have logged in from more than one browser at the same time, this is probably OK.") . "\n\n";
                $body .= l("Best regards,") . "\n" . config->{'appname'};
                debug "*** Going to try sending an email to: " . $new_user->email;
                try {
                    email({
                        from    => 'ebib@ebib.no',
                        to      => $new_user->email,
                        subject => config->{'appname'} . ": " . l('More than one active session'),
                        body    => $body,
                    });
                    debug "*** Email was sent to " . $new_user->email;
                } catch {
                    error "Could not send email: $_";
                    debug "*** Email was NOT sent to " . $new_user->email;
                };
            } else  {
                debug "*** No email given for username = " . $username;
            }
            # Display information about the sessions to the user
            return template 'sessions', { 'sessions' => \@activesessions };
        }

        # Redirect based on roles
        if ( user_has_role('admin') ) { 
            redirect '/admin';
        } elsif ( user_has_role('superadmin') ) {
            redirect '/superadmin';
        } else {
            redirect params->{return_url} || '/';
        }

    } else {
    
        ## UN-SUCCESSFULL LOGIN
        
        # Record the failed login in the users table
        my $failed_user = resultset( 'User' )->find({ 'username' => $username });
        if ( $failed_user ) {
            # Increment the fail counter
            $failed_user->update({ 'failed' => $failed_user->failed + 1 });
            # Check if this user is now blocked, because of too many ettempts
            if ( $failed_user->failed >= setting( 'max_failed_logins' ) ) {
                # Yes, this user is blocked
                debug "*** User $username is blocked, " . $failed_user->failed . " failed logins";
                if ( $failed_user->failed == setting( 'max_failed_logins' ) ) {
                    # This user became blocked just now, add a token for unblocking
                    debug "*** User $username is blocked NOW, " . $failed_user->failed . " failed logins";
                    _add_logintoken( $failed_user );
                }
                return redirect '/blocked';
            }
        }

        # Log
        _log2db({
            logcode => 'LOGINFAIL',
            logmsg  => "Username: $username, realm: $userrealm",
        });
        
        if ( $userrealm eq 'local' ) {
            redirect '/in?admin=1';
        } else {
            forward '/in', { login_failed => 1 }, { method => 'GET' };
        }

    }
};

sub _add_logintoken {

    my ( $user ) = @_;
    my $token = sha3_512_hex( time(), $user->username, $user->name, $user->email, rand(10000000) );
    $user->update({ 'token' => $token });
    # Send the token in an email
    try {
        email({
            from    => 'ebib@ebib.no',
            to      => $user->email,
            subject => config->{appname} . ": " . l('Your account has been blocked'),
            body    => l('Please visit this URL to unblock the account: ') . "\n\nhttp://ebib.no/unblock?token=$token",
        });
    } catch {
        error "Could not send email: $_";
    };
    # Log the block event
    _log2db({
        logcode => 'BLOCKED',
        logmsg  => "User " . $user->id . " was blocked because of too many failed attempts",
    });
}

get '/blocked' => sub {
    template 'blocked';
};

get '/unblock' => sub {
    my $token = param 'token';
    if ( $token && length $token >= 64 ) {
        # Find the user based on the token
        my @users = resultset( 'User' )->search({ 'token' => $token });
        my $found_users = @users;
        if ( $found_users == 1 ) {
            my $user = $users[0];
            # Reset the failed logins counter
            $user->update({ 'failed' => 0 });
            # Remove the token
            $user->update({ 'token' => undef });
            flash message => "Your account has been unblocked, please try to log in again.";
            _log2db({
                logcode => 'UNBLOCKED',
                logmsg  => "User " . $user->id . " was unblocked",
            });
            return redirect '/in';
        } else {
            # This hould not happen
            return redirect '/in';
        }
    } else {
        my $token_length = length $token;
        debug "Token was not given or was not long enough (it was $token_length).";
        return redirect '/in';
    }
};

get '/login/denied' => sub {
    redirect '/in';
};

any '/out' => sub {

    unless ( _check_csrftoken( param 'csrftoken' ) ) {
        return redirect '/';
    }
    
    # Remove the session from sessioncount
    my $session = resultset('Sessioncount')->find({ 'session_id' => cookie( 'dancer.session' ) });
    if ( $session ) {
        $session->delete;
    }

    # Log
    _log2db({
        logcode => 'LOGOUT',
        logmsg  => "",
    });

    session->destroy;
    debug "+++ Session was destroyed because the user logged out";

    # Get rid of the ebib cookie
    my $cookie = Dancer::Cookie->new(
        'name'      => 'ebib', 
        'value'     => '',
        'domain'    => setting('session_domain'),
        'http_only' => 0,
        'expires'   => '-1 year',
    );
    header 'Set-Cookie' => $cookie->to_header;

    if (params->{return_url}) {
        redirect params->{return_url};
    } else {
        return redirect '/';
    }
};

true;
