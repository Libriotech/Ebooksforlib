
package Ebooksforlib;
use Dancer ':syntax';
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::DBIC;
use Dancer::Plugin::FlashMessage;
use Dancer::Plugin::Lexicon;
use Dancer::Exception qw(:all);
use Business::ISBN;
use HTML::Strip;
use DateTime;
use DateTime::Duration;
use Data::Dumper; # DEBUG 
use Modern::Perl;
use URI::Escape;

use Ebooksforlib::Util;
use Ebooksforlib::Route::Browse;
use Ebooksforlib::Route::Login;
use Ebooksforlib::Route::MyProfile;
use Ebooksforlib::Route::Circ;
use Ebooksforlib::Route::RestApi;
use Ebooksforlib::Route::Admin;
use Ebooksforlib::Route::Admin::Settings;
use Ebooksforlib::Route::Admin::Books;
use Ebooksforlib::Route::Admin::Covers;
use Ebooksforlib::Route::Admin::Creators;
use Ebooksforlib::Route::Admin::Items;
use Ebooksforlib::Route::Admin::Lists;
use Ebooksforlib::Route::Admin::Stats;
use Ebooksforlib::Route::Admin::Logs;
use Ebooksforlib::Route::Superadmin;
use Ebooksforlib::Route::Superadmin::Providers;
use Ebooksforlib::Route::Superadmin::Libraries;

use Dancer::Plugin::Auth::Basic;
use Dancer::Plugin::EscapeHTML;

use Ebooksforlib::Err;

our $VERSION = '0.1';

hook 'before' => sub {

    errinit();

    var appname  => config->{appname};
    var min_pass => config->{min_pass}; # FIXME Is there a better way to do this? 
    var language_tag => language_tag;
    var installed_langs => installed_langs;

    set_language 'no';

    # Did the user try to access /admin or /superadmin without being logged in? 
    my $request_path = request->path();
    if ( ( $request_path eq '/admin' || $request_path eq '/superadmin' ) && !session('logged_in_user_id') ) {
        return redirect '/in?admin=1';
    }
    
    # Restrict access to the REST API
    if ( request->path =~ /\/rest\/.*/ && !config->{ 'rest_allowed_ips' }{ request->remote_address } ) {
        debug "Denied access to the REST API for " . request->remote_address;
        # Log
        _log2db({
            logcode => 'RESTDENY',
            logmsg  => "IP: " . request->remote_address,
        });
        status 403;
        halt("403 Forbidden");
    }
    
    # Force users to choose a library
    unless ( session('chosen_library') && session('chosen_library_name') ) {
        # Some pages must be reachable without choosing a library 
        # To exempt the front page, include this below: || request->path eq '/'
        unless ( request->path =~ /\/choose/  || # Let users choose a library
                 request->path =~ /\/set\/.*/ || # Let users set a library
                 request->path =~ /\/in/      || # Let users log in
                 request->path =~ /\/blocked/ || # Display the blocked message to blocked users
                 request->path =~ /\/unblock/ || # Let users unblock themselves
                 request->path =~ /\/rest\/.*/   # Don't force choosing a library for the API
               ) {
            return redirect '/choose?return_url=' . request->path();
            # To force users to one library, uncomment this:
            # return redirect '/set/2?return_url=' . request->path();
        }
    }
    
    # We need to show lists and genres on a lot of pages, so we might as well 
    # make the data available from here
    # TODO Perhaps have a list of pages that need the data here, to check
    # against? 
    # FIXME Not sure this is a good idea anymore...
    my @lists = rset('List')->search({
        'library_id' => session('chosen_library')
    });
    var lists => \@lists;

};

hook 'after' => sub {
    errexit();
};

get '/choose' => sub {

    my $return_url = param 'return_url';

    $return_url = '' if($return_url =~ /^[a-z]+\:/i);
    $return_url = uri_escape($return_url);

    my @libraries = rset( 'Library' )->all;

    my $belongs_to_library = 0;
    if ( session('logged_in_user_id') ) {
        my $user = rset( 'User' )->find( session('logged_in_user_id') );
        $belongs_to_library = $user->belongs_to_library( session('chosen_library') )
    }

    template 'chooselib', { 
        libraries          => \@libraries, 
        return_url         => $return_url, 
        belongs_to_library => $belongs_to_library,
        disable_search     => 1,
        pagetitle          => l( 'Choose library' ),
    };

};

get '/set/:library_id' => sub {
    my $library_id = param 'library_id';
    # cookie chosen_library => $library_id; # FIXME Expiry
    my $library = rset('Library')->find( $library_id );
    if ( $library ) {
        session chosen_library => $library->id;
        session chosen_library_name => $library->name;
        # flash info => "A library was chosen.";
        if (params->{return_url}) {
           return redirect params->{return_url};
        }
    } else {
        flash error => localize("Not a valid library.");
    }
    redirect '/choose';
};

get '/lang' => sub {
    redirect request->referer;
};

### Local users

get '/users/add' => require_role superadmin => sub { 
    my @libraries = rset('Library')->all;
    template 'users_add', { libraries => \@libraries };
};

post '/users/add' => require_role superadmin => sub {

    my $name       = param 'name';
    my $username   = param 'username';
    my $password1  = param 'password1';
    my $password2  = param 'password2';
    my $email      = param 'email';
    my $library_id = param 'library';  
    
    # Check the provided data
    _check_password_length( $password1 )             or return template 'users_add';
    _check_password_match(  $password1, $password2 ) or return template 'users_add';
    
    # Data looks good, try to save it
    try {
        my $hs = HTML::Strip->new();
        $name  = $hs->parse( $name );
        $username  = $hs->parse( $username );
        $email = $hs->parse( $email );
        $hs->eof;
        my $new_user = rset('User')->create({
            username => $username, 
            password => _encrypt_password($password1), 
            name     => $name,
            email    => $email,
        });
        debug "*** Created new user with ID = " . $new_user->id;
        # debug Dumper $new_user;
        if ( $library_id ) {
            rset('UserLibrary')->create({
                user_id    => $new_user->id, 
                library_id => $library_id, 
            });
        }
        flash info => 'A new user was added!';
        redirect '/superadmin';
    } catch {
        flash error => "Oops, we got an error:<br />".errmsg($_);
        error "$_";
        template 'users_add', { name => $name };
    };

};

get '/users/edit/:id' => require_role superadmin => sub {

    my $id = param 'id';
    my $user = rset('User')->find( $id );
    template 'users_edit', { user => $user };

};

post '/users/edit' => require_role superadmin => sub {

    my $id   = param 'id';
    my $username = param 'username';
    my $name     = param 'name';
    my $email    = param 'email';
    my $user = rset('User')->find( $id );
    try {
        my $hs = HTML::Strip->new();
        my $username = $hs->parse( $username );
        my $name = $hs->parse( $name );
        my $email = $hs->parse( $email );
        $hs->eof;
        $user->set_column('username', $username);
        $user->set_column('name',     $name);
        $user->set_column('email',    $email);
        $user->update;
        flash info => 'A user was updated!';
        redirect '/superadmin';
    } catch {
        flash error => "Oops, we got an error:<br />".errmsg($_);
        error "$_";
        template 'users_edit', { user => $user };
    };

};

get '/users/password/:id' => require_role superadmin => sub {
    template 'users_password';
};

post '/users/password' => require_role superadmin => sub {

    my $id        = param 'id';
    my $password1 = param 'password1';
    my $password2 = param 'password2'; 
    
    my $hs = HTML::Strip->new();
    $id  = $hs->parse( $id );
    $hs->eof;
    $id = HTML::Entities::encode($id); 


    # Check the provided data
    _check_password_length( $password1 )             or return template 'users_password', { id => $id };
    _check_password_match(  $password1, $password2 ) or return template 'users_password', { id => $id };
    
    # Data looks good, try to save it
    my $user = rset('User')->find( $id );
    try {
        $user->set_column( 'password', _encrypt_password($password1) );
        $user->update;
        flash info => "The password was updated for user with ID = $id!";
        redirect '/superadmin';
    } catch {
        flash error => "Oops, error when trying to update password:<br />".errmsg($_);
        error "$_";
        template 'users_password', { id => $id };
    };

};

get '/users/roles/:id' => require_role superadmin => sub { 
    
    my $id = param 'id';
    my $user = rset('User')->find( $id );
    my @roles = rset('Role')->all;
    template 'users_roles', { user => $user, roles => \@roles };
    
};

get '/users/roles/add/:user_id/:role_id' => require_role superadmin => sub { 
    
    my $user_id = param 'user_id';
    my $role_id = param 'role_id';
    try {
        rset('UserRole')->create({
            user_id => $user_id, 
            role_id => $role_id, 
        });
        flash info => 'A new role was added!';
        redirect '/users/roles/' . $user_id;
    } catch {
        flash error => "Oops, we got an error:<br />".errmsg($_);
        error "$_";
        redirect '/users/roles/' . $user_id;
    };    
};

get '/users/roles/delete/:user_id/:role_id' => require_role superadmin => sub { 
    
    my $user_id = param 'user_id';
    my $role_id = param 'role_id';
    my $role = rset('UserRole')->find({ user_id => $user_id, role_id => $role_id });
    try {
        $role->delete;
        flash info => 'A role was deleted!';
        redirect '/users/roles/' . $user_id;
    } catch {
        flash error => "Oops, we got an error:<br />".errmsg($_);
        error "$_";
        redirect '/users/roles/' . $user_id;
    };
    
};

get '/users/libraries/:id' => require_role superadmin => sub { 
    
    my $id = param 'id';
    my $user = rset('User')->find( $id );
    my @libraries = rset('Library')->all;
    template 'users_libraries', { user => $user, libraries => \@libraries };
    
};

# Add a connection between user and library
get '/users/libraries/add/:user_id/:library_id' => require_role superadmin => sub { 
    
    my $user_id    = param 'user_id';
    my $library_id = param 'library_id';
    try {
        rset('UserLibrary')->create({
            user_id    => $user_id, 
            library_id => $library_id, 
        });
        flash info => 'A new library was connected!';
        redirect '/users/libraries/' . $user_id;
    } catch {
        flash error => "Oops, we got an error:<br />".errmsg($_);
        error "$_";
        redirect '/users/libraries/' . $user_id;
    };    
};

get '/users/libraries/delete/:user_id/:library_id' => require_role superadmin => sub { 
    
    my $user_id    = param 'user_id';
    my $library_id = param 'library_id';
    my $connection = rset('UserLibrary')->find({ user_id => $user_id, library_id => $library_id });
    # TODO Check that this user is ready to be deleted!
    try {
        $connection->delete;
        flash info => 'A connection was deleted!';
        redirect '/users/libraries/' . $user_id;
    } catch {
        flash error => "Oops, we got an error:<br />".errmsg($_);
        error "$_";
        redirect '/users/libraries/' . $user_id;
    };
    
};

get '/users/delete/:id?' => require_role superadmin => sub { 
    
    # Confirm delete
    my $id = param 'id';
    my $user = rset('User')->find( $id );
    template 'users_delete', { user => $user };
    
};

get '/users/delete_ok/:id?' => require_role superadmin => sub { 
    
    # Do the actual delete
    my $id = param 'id';
    my $user = rset('User')->find( $id );
    # TODO Check that this user is ready to be deleted!
    try {
        $user->delete;
        flash info => 'A user was deleted!';
        info "Deleted user with ID = $id";
        redirect '/superadmin';
    } catch {
        flash error => "Oops, we got an error:<br />".errmsg($_);
        error "$_";
        redirect '/superadmin';
    };
    
};

true;
