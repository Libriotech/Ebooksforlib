package Ebooksforlib::Route::Superadmin::LocalUsers;

=head1 Ebooksforlib::Route::Superadmin::LocalUsers

Routes for handling local users, including passwords, roles, connections to libraries etc. 

=cut

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::FlashMessage;
use Dancer::Exception qw(:all);
use Ebooksforlib::Util;

get '/users/add' => require_role superadmin => sub { 
    my @libraries = rset('Library')->all;
    template 'users_add', { libraries => \@libraries };
};

post '/users/add' => require_role superadmin => sub {

    unless ( _check_csrftoken( param 'csrftoken' ) ) {
        return redirect '/';
    }

    my $name       = param 'name';
    my $username   = param 'username';
    my $password1  = param 'password1';
    my $password2  = param 'password2';
    my $email      = param 'email';
    my $library_id = param 'library';  
    
    # Check the provided data
    _check_password_length(  $password1 )             or return template 'users_add';
    _check_password_match(   $password1, $password2 ) or return template 'users_add';
    my $pwcheck = _check_password_content( $password1 );
    if ( $pwcheck->has_errors ) {
        return template 'users_add', { 'pwerrors' => $pwcheck->error_list };
    }
    
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

    unless ( _check_csrftoken( param 'csrftoken' ) ) {
        return redirect '/';
    }

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

    unless ( _check_csrftoken( param 'csrftoken' ) ) {
        return redirect '/';
    }

    my $id        = param 'id';
    my $password1 = param 'password1';
    my $password2 = param 'password2'; 

    my $hs = HTML::Strip->new();
    $id  = $hs->parse( $id );
    $hs->eof;
    $id = HTML::Entities::encode($id); 

    # Check the provided data
    _check_password_length( $password1 )             or return template 'users_password', { 'id' => $id };
    _check_password_match(  $password1, $password2 ) or return template 'users_password', { 'id' => $id };
    my $pwcheck = _check_password_content( $password1 );
    if ( $pwcheck->has_errors ) {
        return template 'users_password', { 'id' => $id, 'pwerrors' => $pwcheck->error_list };
    }
    
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
    
    unless ( _check_csrftoken( param 'csrftoken' ) ) {
        return redirect '/';
    }
    
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
    
    unless ( _check_csrftoken( param 'csrftoken' ) ) {
        return redirect '/';
    }
    
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
    
    unless ( _check_csrftoken( param 'csrftoken' ) ) {
        return redirect '/';
    }
    
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
    
    unless ( _check_csrftoken( param 'csrftoken' ) ) {
        return redirect '/';
    }
    
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
    
    unless ( _check_csrftoken( param 'csrftoken' ) ) {
        return redirect '/';
    }
    
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
