package Ebooksforlib;
use Dancer ':syntax';
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::DBIC;
use Dancer::Plugin::FlashMessage;
use Dancer::Exception qw(:all);
use Crypt::SaltedHash;
use Data::Dumper; # DEBUG 

our $VERSION = '0.1';

hook 'before' => sub {

    var appname  => config->{appname};
    var min_pass => config->{min_pass};

};

get '/' => sub {
    my @books = rset('Book')->all;
    template 'index', { books => \@books };
};

get '/book/:id' => sub {
    my $book_id = param 'id';
    my $book = rset('Book')->find( $book_id );
    template 'book', { book => $book };
};

get '/creator/:id' => sub {
    my $creator_id = param 'id';
    my $creator = rset('Creator')->find( $creator_id );
    template 'creator', { creator => $creator };
};

get '/log/in' => sub {
    my @librariers = rset('Library')->all;
    template 'login', { libraries => \@librariers };
};

post '/log/in' => sub {
    
    my $username  = param 'username';
    my $password  = param 'password';
    my $userrealm = param 'realm';
    
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
        
        # Set the realm to be the local database so that further calls to 
        # logged_in_user will talk to the database, not SIP2
        session logged_in_user_realm => 'local';
        
        redirect params->{return_url} || '/';

    } else {

        debug "*** Login failed for $username, $password, $realm";
        forward '/log/in', { login_failed => 1 }, { method => 'GET' };

    }
};

any ['get','post'] => '/log/out' => sub {
    session->destroy;
    if (params->{return_url}) {
        redirect params->{return_url};
    } else {
        redirect '/';
    }
};

get '/login/denied' => sub {
    redirect '/login';
};

get '/about' => sub {
    template 'about';
};

get '/my' => sub {
    debug '*** Showing My Page for user with id = ' . session('logged_in_user_id');
    my $user = rset( 'User' )->find( session('logged_in_user_id') );
    template 'my', { userdata => logged_in_user, user => $user };
};

### Routes below this point require admin/superadmin privileges

get '/admin' => require_role admin => sub { 
    template 'admin';
};

get '/superadmin' => require_role superadmin => sub { 
    my @users     = rset('User')->all;
    my @libraries = rset('Library')->all;
    template 'superadmin', { 
        'users'     => \@users,
        'libraries' => \@libraries,
    };
};

### Lists

get '/lists' => require_role admin => sub {
    
    my @lists = rset('List')->search({ library_id => _get_library_for_admin_user( session 'logged_in_user_id' ) });
    template 'lists', { lists => \@lists };
};

### Creators

get '/creators/add' => require_role admin => sub {
    template 'creators_add';
};

post '/creators/add' => require_role admin => sub {

    my $name = param 'name';
    try {
        my $new_creator = rset('Creator')->create({
            name  => $name,
        });
        flash info => 'A new creator was added! <a href="/creator/' . $new_creator->id . '">View</a>';
        redirect '/admin';
    } catch {
        flash error => "Oops, we got an error:<br />$_";
        error "$_";
        template 'creators_add', { name => $name };
    };

};

get '/creators/edit/:id' => require_role admin => sub {
    my $creator_id = param 'id';
    my $creator = rset('Creator')->find( $creator_id );
    template 'creators_edit', { creator => $creator };
};


post '/creators/edit' => require_role admin => sub {

    my $id   = param 'id';
    my $name = param 'name';
    my $creator = rset('Creator')->find( $id );
    try {
        $creator->set_column('name', $name);
        $creator->update;
        flash info => 'A creator was updated! <a href="/creator/' . $creator->id . '">View</a>';
        redirect '/admin';
    } catch {
        flash error => "Oops, we got an error:<br />$_";
        error "$_";
        template 'creators_edit', { creator => $creator };
    };

};

### Creators and books

get '/books/creators/add/:bookid' => require_role admin => sub {
    my $book_id = param 'bookid';
    my $book     = rset('Book')->find( $book_id );
    my @creators = rset('Creator')->all;
    template 'books_creators', { book => $book, creators => \@creators };
};

post '/books/creators/add' => require_role admin => sub {
    my $book_id    = param 'bookid';
    my $creator_id = param 'creatorid';
    try {
        rset('BookCreator')->create({
            book_id    => $book_id, 
            creator_id => $creator_id, 
        });
        flash info => 'A new creator was added!';
        redirect '/books/creators/add/' . $book_id;
    } catch {
        flash error => "Oops, we got an error:<br />$_";
        error "$_";
        redirect '/books/creators/add/' . $book_id;
    };
};

get '/books/creators/delete/:book_id/:creator_id' => require_role admin => sub {
    my $book_id    = param 'book_id';
    my $creator_id = param 'creator_id';
    my $book_creator = rset('BookCreator')->find({ book_id => $book_id, creator_id => $creator_id });
    try {
        $book_creator->delete;
        flash info => 'A creator was deleted from this book!';
        redirect '/books/creators/add/' . $book_id;
    } catch {
        flash error => "Oops, we got an error:<br />$_";
        error "$_";
        redirect '/books/creators/add/' . $book_id;
    };
};

### Books

get '/books/add' => require_role admin => sub {
    template 'books_add';
};

post '/books/add' => require_role admin => sub {

    my $title = param 'title';
    my $date  = param 'date';
    my $isbn  = param 'isbn'; # TODO Check the validity 
    try {
        my $new_book = rset('Book')->create({
            title  => $title,
            date   => $date,
            isbn   => $isbn,
        });
        flash info => 'A new book was added! <a href="/book/' . $new_book->id . '">View</a>';
        redirect '/admin';
    } catch {
        flash error => "Oops, we got an error:<br />$_";
        error "$_";
        template 'books_add', { title => $title, date => $date };
    };

};

get '/books/edit/:id' => require_role admin => sub {
    my $book_id = param 'id';
    my $book = rset('Book')->find( $book_id );
    template 'books_edit', { book => $book };
};


post '/books/edit' => require_role admin => sub {

    my $id    = param 'id';
    my $title = param 'title';
    my $date  = param 'date';
    my $isbn  = param 'isbn';
    my $book = rset('Book')->find( $id );
    try {
        $book->set_column('title', $title);
        $book->set_column('date', $date);
        $book->set_column('isbn', $isbn);
        $book->update;
        flash info => 'A book was updated! <a href="/book/' . $book->id . '">View</a>';
        redirect '/admin';
    } catch {
        flash error => "Oops, we got an error:<br />$_";
        error "$_";
        template 'books_edit', { book => $book };
    };

};

### Libraries

get '/libraries/add' => require_role superadmin => sub { 
    template 'libraries_add';
};

post '/libraries/add' => require_role superadmin => sub {

    my $name = param 'name';
    try {
        my $new_library = rset('Library')->create({
            name  => $name,
        });
        flash info => 'A new library was added!';
        redirect '/superadmin';
    } catch {
        flash error => "Oops, we got an error:<br />$_";
        error "$_";
        template 'libraries_add', { name => $name };
    };

};

get '/libraries/edit/:id' => require_role superadmin => sub {

    my $id = param 'id';
    my $library = rset('Library')->find( $id );
    template 'libraries_edit', { library => $library };

};

post '/libraries/edit' => require_role superadmin => sub {

    my $id    = param 'id';
    my $name  = param 'name';
    my $realm = param 'realm';
    my $library = rset('Library')->find( $id );
    try {
        $library->set_column('name', $name);
        $library->set_column('realm', $realm);
        $library->update;
        flash info => 'A library was updated!';
        redirect '/superadmin';
    } catch {
        flash error => "Oops, we got an error:<br />$_";
        error "$_";
        template 'libraries_edit', { library => $library };
    };

};

get '/libraries/delete/:id?' => require_role superadmin => sub { 
    
    # Confirm delete
    my $id = param 'id';
    my $library = rset('Library')->find( $id );
    template 'libraries_delete', { library => $library };
    
};

get '/libraries/delete_ok/:id?' => require_role superadmin => sub { 
    
    # Do the actual delete
    my $id = param 'id';
    my $library = rset('Library')->find( $id );
    # TODO Check that this library is ready to be deleted!
    try {
        $library->delete;
        flash info => 'A library was deleted!';
        info "Deleted library with ID = $id";
        redirect '/superadmin';
    } catch {
        flash error => "Oops, we got an error:<br />$_";
        error "$_";
        redirect '/superadmin';
    };
    
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
        flash error => "Oops, we got an error:<br />$_";
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
        $user->set_column('username', $username);
        $user->set_column('name',     $name);
        $user->set_column('email',    $email);
        $user->update;
        flash info => 'A user was updated!';
        redirect '/superadmin';
    } catch {
        flash error => "Oops, we got an error:<br />$_";
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
        flash error => "Oops, error when trying to update password:<br />$_";
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
        flash error => "Oops, we got an error:<br />$_";
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
        flash error => "Oops, we got an error:<br />$_";
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
        flash error => "Oops, we got an error:<br />$_";
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
        flash error => "Oops, we got an error:<br />$_";
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
        flash error => "Oops, we got an error:<br />$_";
        error "$_";
        redirect '/superadmin';
    };
    
};

# Reader-app API
# The server-side component of the reader-app will be talking to this API
# TODO These are dummy functions with hardcoded responses, for now

set serializer => 'JSON';

get '/rest/login' => sub {

    return { 
        hash => '0c86b9ecb91ee1e16f96363956dff7e5'
    };

};

get '/rest/logout' => sub {

    return { 
        logout => 1
    };

};

get '/rest/listbooks' => sub {

    return [ 
        { 
            bid    => 1, 
            title  => 'Three men in a boat', 
            author => 'Jerome K. Jerome'
        },
        { 
            bid    => 2, 
            title  => 'Brand', 
            author => 'Henrik Ibsen' 
        },
    ];

};

get '/rest/getbook' => sub {
    return send_file( 
        config->{books_root} . '1/book-1.epub', 
        system_path  => 1, 
        content_type => 'application/epub+zip', 
        filename     => 'book-1.epub'
    );
};

### Utility functions
# TODO Move these to a separate .pm

# Assumes that admin users are only connected to one library
sub _get_library_for_admin_user {
    my $user_id = shift;
    my $user = rset('User')->find( $user_id );
    my @libraries = $user->libraries;
    return $libraries[0]->id;
}

sub _check_password_length {
    my ( $password1 ) = @_;
    if ( length $password1 < config->{min_pass} ) {
        error "*** Password is too short: " . length $password1;
        flash error => 'Passwords is too short! (The minimum is ' . config->{min_pass} . '.)';
        return 0;
    } else {
        return 1;
    }
}

sub _check_password_match {
    my ( $password1, $password2 ) = @_;
    if ( $password1 ne $password2 ) {
        error "*** Passwords do not match";
        flash error => "Passwords do not match!";
        return 0;
    } else {
        return 1;
    }
}

sub _encrypt_password {
    my $password = shift;
    my $csh = Crypt::SaltedHash->new();
    $csh->add( $password );
    return $csh->generate;
}

true;
