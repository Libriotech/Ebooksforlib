package Ebooksforlib::Route::Login;

=head1 Ebooksforlib::Route::Login

Routes for handling login and logout. 

=cut

use Dancer ':syntax';

get '/login' => sub {
    template 'login';
};

post '/login' => sub {
    
    my $username  = lc( param 'username' );
    my $password  = param 'password';
    my $userrealm;
    
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

    my ($success, $realm) = authenticate_user( $username, $password, $userrealm );
    if ($success) {

        debug "*** Successfull login for $username, $password, $realm";
        session logged_in_user => $username;
        # Set the realm to be the real realm temporarily, we will change this later
        session logged_in_user_realm => $realm;
        # Also keep the real realm around in case we need it
        session logged_in_user_real_realm => $realm;
        
        # Get the data about the logged_in_user and store some of it in the session
        my $user = logged_in_user;
        session logged_in_user_name => $user->{name};

        # Store roles in the session (will be used in the templates)
        session logged_in_user_roles => user_roles;

        # Update the local user or create a new one
        my $new_user = rset('User')->update_or_new({
            username => $username,
            name     => $user->{name},
            email    => $user->{email},
        }, { 
            key => 'username' 
        });

        if( ! $new_user->in_storage ) {
            # do some stuff
            $new_user->insert;
            debug "*** User $username was added, with id = " . $new_user->id;
            # Connect this user to the correct library based on the realm
            # used to sign in
            debug '*** Going to look up library with realm = ' . $realm;
            my $library = rset('Library')->find({ realm => $realm });
            if ( $library ) {
                debug '*** Going to connect to library with id = ' . $library->id;
                try {
                    rset('UserLibrary')->create({
                        user_id    => $new_user->id, 
                        library_id => $library->id, 
                    });
                } catch {
                    # This is a serious error! 
                    error '*** Error when trying to connect user ' . $new_user->id . ' to library ' . $library->id . '. Error message: ' . $_;
                };
            } else {
                error '*** Could not find library with realm = ' . $realm;
            }
            flash info => "Welcome, new user!";
        } else {
            debug "*** User $username was updated";
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
        if ( cookie 'ebib' ) {
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
                'http_only' => 0,
            );
            debug $cookie->to_header;
            header 'Set-Cookie' => $cookie->to_header;
            
        }
        
        redirect params->{return_url} || '/';

    } else {

        debug "*** Login failed for $username, $password, $realm";
        forward '/login', { login_failed => 1 }, { method => 'GET' };

    }
};

get '/login/denied' => sub {
    redirect '/login';
};

any ['get','post'] => '/logout' => sub {
    session->destroy;
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
