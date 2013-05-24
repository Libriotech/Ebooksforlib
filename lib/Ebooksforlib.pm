package Ebooksforlib;
use Dancer ':syntax';
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::DBIC;
use Dancer::Plugin::FlashMessage;
use Dancer::Exception qw(:all);
use Ebooksforlib::Util;
use Crypt::SaltedHash;
use Digest::MD5 qw( md5_hex );;
use Business::ISBN;
use HTML::Strip;
use DateTime;
use DateTime::Duration;
use Data::Dumper; # DEBUG 

our $VERSION = '0.1';

hook 'before' => sub {

    var appname  => config->{appname};
    var min_pass => config->{min_pass}; # FIXME Is there a better way to do this? 
    
    # Force users to choose a library
    unless ( session('chosen_library') && session('chosen_library_name') ) {
        # Some pages must be reachable without choosing a library 
        # To exempt the front page, include this below: || request->path eq '/'
        unless ( request->path =~ /\/library\/.*/ || # Let users choose a library
                 request->path =~ /\/log\/.*/ ||     # Let users log in
                 request->path =~ /\/rest\/.*/       # Don't force choosing a library for the API
               ) {
            return redirect '/library/choose?return_url=' . request->path();
        }
    }

};

get '/' => sub {
    
    # Only show books that are available to the chosen library
    # Users should not see the front page without logging in or choosing a library
    # my @books = rset('Book')->search({
    #     'items.library_id' => session('chosen_library')
    # }, {
    #     join     => { 'files' => 'items' },
    #     group_by => [qw{ id }]
    # });
    # template 'index', { books => \@books };
    
    # Show lists and genres from the chosen library
    my @lists = rset('List')->search({
        'library_id' => session('chosen_library')
    });
    var hide_dropdowns => 1;
    template 'index', { lists => \@lists };
    
};

get '/book/:id' => sub {
    
    my $book_id = param 'id';
    my $book = rset('Book')->find( $book_id );
    
    # Get the items for this book and library, that are not deleted
    # We get the items from the book, for now, but leave this here in case it
    # turns out to be a bad idea
    # my @items = rset('Item')->search({
    #     'file.library_id' => session('chosen_library'),
    #     'file.book_id'    => $book->id,
    #     deleted           => 0,
    # }, {
    #     join => 'file',
    # });
    
    my $user_has_borrowed = 0;
    my $limit_reached = 0;
    my $user_belongs_to_library = 0;
    my $library = rset('Library')->find( session('chosen_library') );
    if ( session('logged_in_user_id') ) {
    
        my $user = rset('User')->find( session('logged_in_user_id') );
    
        # Check that the user belongs to the chosen library
        if ( $user->belongs_to_library( session('chosen_library') ) ) {
            $user_belongs_to_library = 1;
        }
    
        # Check if the user has already borrowed this book
        $user_has_borrowed = _user_has_borrowed( $user, $book );

        # Check the number of concurrent loans
        if ( $user->number_of_loans_from_library( $library->id ) == $library->concurrent_loans ) {
            $limit_reached = 1;
        }
        
    }
    
    # Look for descriptions
    my $descriptions = $book->get_descriptions;
    # if ( $book->dataurl ) {
    #     my $sparql = 'SELECT DISTINCT ?krydder ?abstract WHERE {
    #                       OPTIONAL { <' . $book->dataurl . '> <http://data.deichman.no/krydder_beskrivelse> ?krydder . }
    #                       OPTIONAL { <' . $book->dataurl . '> <http://purl.org/dc/terms/abstract> ?abstract . }
    #                   }';
    #     $descriptions = _sparql2data( $sparql );
    #     debug "*** Descriptions: " . Dumper $descriptions;
    #     if ( $descriptions->{'error'} ) {
    #         error $descriptions->{'error'};
    #         flash error => "Sorry, unable to display descriptions (" . $descriptions->{'error'} . ")";
    #     }
    # }
    
    template 'book', { 
        book                    => $book, 
        user_has_borrowed       => $user_has_borrowed,
        # items                 => \@items,
        limit_reached           => $limit_reached,
        user_belongs_to_library => $user_belongs_to_library,
        descriptions            => $descriptions,
        library                 => $library,
    };
};

### Search

get '/search' => sub {

    my $q = param 'q';
    
    # Bail out if no search was specified
    if ( $q && $q eq '' ) {
        return template 'search';
    }
    
    # Search for books
    my @books = rset('Book')->search(
        {},
        { order_by => 'title desc' }
    )->search_literal('MATCH ( title, isbn ) AGAINST( ? IN BOOLEAN MODE )', $q );
    
    # Search for people
    my @creators = rset('Creator')->search(
        {},
        { order_by => 'name desc' }
    )->search_literal('MATCH ( name ) AGAINST( ? IN BOOLEAN MODE )', $q );
    
    template 'search', { books => \@books, creators => \@creators };

};

### Ratings

post '/ratings/add' => require_login sub {

    my $rating  = param 'rating';
    my $book_id = param 'book_id';
    my $user_id = session( 'logged_in_user_id' );
    
    # Save the rating
    try {
        my $new_rating = rset('Rating')->update_or_create({ 
            user_id => $user_id,
            book_id => $book_id,
            rating  => $rating,
        });
        flash info => 'Your rating was added!';
    } catch {
        flash error => "Oops, we got an error:<br />$_"; # FIXME Don't show the raw error to end users
        error "$_";
    };
    
    redirect '/book/' . $book_id;

};

### Comments

post '/comments/add' => require_login sub {

    my $comment_raw = param 'comment';
    my $book_id     = param 'book_id';
    my $user_id     = session( 'logged_in_user_id' );
    
    # Make sure the user-submitted comment is safe
    my $hs = HTML::Strip->new();
    my $comment_safe = $hs->parse( $comment_raw );
    
    # Save the comment
    try {
        my $new_comment = rset('Comment')->create({
            user_id => $user_id,
            book_id => $book_id,
            comment => $comment_safe,
        });
        flash info => 'Your comment was added!';
    } catch {
        flash error => "Oops, we got an error:<br />$_"; # FIXME Don't show the raw error to end users
        error "$_";
    };
    
    redirect '/book/' . $book_id;

};

get '/comments/edit/:id' => sub {

    my $comment_id  = param 'id';
    my $user_id     = session( 'logged_in_user_id' );
    
    my $comment = rset('Comment')->find( $comment_id );
    
    # Check that the current user is the author of the comment
    if ( $comment->user_id != $user_id ) {
        flash error => "Are you trying to edit a comment you did not write?";
        return redirect '/book/' . $comment->book->id;
    }
    
    template 'comments_edit', { comment => $comment };

};

post '/comments/edit' => sub {

    my $comment_id  = param 'comment_id';
    my $comment_raw = param 'comment';
    my $user_id     = session( 'logged_in_user_id' );
    
    # Make sure the user-submitted comment is safe
    my $hs = HTML::Strip->new();
    my $comment_safe = $hs->parse( $comment_raw );
    
    my $comment = rset('Comment')->find( $comment_id );
    
    # Check that the current user is the author of the comment
    if ( $comment->user_id != $user_id ) {
        flash error => "Are you trying to edit a comment you did not write?";
    } else {
    
        try {
            $comment->set_column( 'comment', $comment_safe );
            $comment->set_column( 'edited', DateTime->now );
            $comment->update;
            flash info => 'The comment was updated!';
        } catch {
            flash error => "Oops, we got an error:<br />$_"; # FIXME Don't show the raw error to end users
            error "$_";
        };
        
    }
    redirect '/book/' . $comment->book->id;

};

get '/comments/new' => sub {

    my @comments = rset('Comment')->search( {}, {
      order_by => { -desc => 'id' }, 
      rows     => 10
    } );
    template 'comments_new', { comments => \@comments };

};

### Borrowing books

get '/borrow/:item_id' => require_login sub {

    my $item_id = param 'item_id';
    my $item = rset('Item')->find( $item_id );
    my $user = rset('User')->find( session('logged_in_user_id') );

    # Check that the user belongs to the same library as the item
    # This should not happen, unless the user is trying to cheat the system
    unless ( $user->belongs_to_library( $item->library_id ) ) {
        flash error => "You are trying to borrow a book from a library you do not belong to!";
        debug '!!! User ' . $user->id . ' tried to borrow item ' . $item->id . ' which does not belong to the users library';
        return redirect '/book/' . $item->file->book_id;
    }
    
    # Check that any item of the book this item belongs to is not already on loan to the user
    if ( _user_has_borrowed( $user, $item->file->book ) ) {
        flash error => "You have already borrowed this book!";
        return redirect '/book/' . $item->file->book_id;
    }

    # Check the number of concurrent loans
    # Users should not see this, unless they try to cheat the system, because the 
    # "Borrow" links should be hidden when they have reached the threshold
    my $library = rset('Library')->find( session('chosen_library') );
    if ( $user->number_of_loans_from_library( $library->id ) == $library->concurrent_loans ) {
        flash error => "You have already reached the number of concurrent loans for your library!";
        debug '!!! User ' . $user->id . ' tried to borrow too many books';
        return redirect '/book/' . $item->file->book_id;
    }
    
    # Calculate the due date/time
    my $dt = DateTime->now( time_zone => setting('time_zone') );
    debug '*** Now: ' . $dt->datetime;
    my $loan_period = DateTime::Duration->new(
        days    => $item->loan_period,
    );
    $dt->add_duration( $loan_period );
    debug '*** Due: ' . $dt->datetime;

    try {
        my $new_loan = rset('Loan')->create({
            item_id => $item_id,
            user_id => $user->id,
            due     => $dt,
        });
        flash info => "You borrowed a book!";
        redirect '/book/' . $item->file->book_id;
    } catch {
        flash error => "Oops, we got an error:<br />$_";
        error "$_";
        redirect '/book/' . $item->file->book_id;
    };
};

get '/creator/:id' => sub {
    my $creator_id = param 'id';
    my $creator = rset('Creator')->find( $creator_id );
    template 'creator', { creator => $creator };
};

get '/lists' => sub {
    my @genres = rset('List')->search({ library_id => session('chosen_library'), is_genre => 1 });
    my @lists  = rset('List')->search({ library_id => session('chosen_library'), is_genre => 0 });
    template 'lists', { genres => \@genres, lists => \@lists };
};

get '/list/:id' => sub {
    my $list_id = param 'id';
    my $list = rset('List')->find( $list_id );
    template 'list', { list => $list };
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
                'uid'      => $new_user->id,
                'username' => $new_user->username,
                'name'     => $new_user->name,
                'realm'    => $realm,
                # 'hash'     => $hash,
            );
            # Set a cookie with a domain
            my $cookie = Dancer::Cookie->new(
                name   => 'ebib', 
                value  => to_json( \%data ),
                domain => setting('session_domain'),
            );
            debug $cookie->to_header;
            header 'Set-Cookie' => $cookie->to_header;
            
        }
        
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

get '/my' => require_login sub {
    debug '*** Showing My Page for user with id = ' . session('logged_in_user_id');
    my $user = rset( 'User' )->find( session('logged_in_user_id') );
    template 'my', { userdata => logged_in_user, user => $user };
};

get '/library/choose' => sub {
    my @libraries = rset( 'Library' )->all;
    my $belongs_to_library = 0;
    if ( session('logged_in_user_id') ) {
        my $user = rset( 'User' )->find( session('logged_in_user_id') );
        $belongs_to_library = $user->belongs_to_library( session('chosen_library') )
    }
    template 'chooselib', { 
        libraries          => \@libraries, 
        return_url         => params->{return_url}, 
        belongs_to_library => $belongs_to_library,
    };
};

get '/library/set/:library_id' => sub {
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
        flash error => "Not a valid library.";
    }
    redirect '/library/choose';
};

get '/anon_toggle' => require_login sub {
    my $user = rset( 'User' )->find( session('logged_in_user_id') );
    template 'anon_toggle', { user => $user };
};

get '/anon_toggle_ok' => require_login sub {
    my $user = rset( 'User' )->find( session('logged_in_user_id') );
    my $new_anonymize = 0;
    if ( $user->anonymize == 0 ) {
        $new_anonymize = 1;
    }
    try {
        $user->set_column( 'anonymize', $new_anonymize );
        $user->update;
        flash info => 'Your anonymization setting was updated!';
    } catch {
        flash error => "Oops, we got an error:<br />$_";
        error "$_";
    };
    redirect '/my';
};

get '/anon/:id' => require_login sub {
    my $id = param 'id';
    my $oldloan = rset( 'OldLoan' )->find( $id );
    template 'anon', { oldloan => $oldloan };
};

get '/anon_ok/:id' => require_login sub {
    my $id = param 'id';
    my $oldloan = rset( 'OldLoan' )->find({ 
        id      => $id,
        user_id => session('logged_in_user_id'),
    });
    if ( $oldloan ) {
        try {
            $oldloan->set_column( 'user_id', 1 );
            $oldloan->update;
            flash info => 'Your loan was anonymized!';
        } catch {
            flash error => "Oops, we got an error:<br />$_";
            error "$_";
        };
    } else {
        flash error => "Sorry, could not find the right loan";
        debug "*** item_id = $id, user_id = " . session('logged_in_user_id');
    }
    redirect '/my';
};

get '/anon_all' => require_login sub {
    template 'anon_all';
};

get '/anon_all_ok' => require_login sub {
    my $user = rset( 'User' )->find( session('logged_in_user_id') );
    my $num_anon = 0;
    foreach my $oldloan ( $user->old_loans ) {
        try {
            $oldloan->set_column( 'user_id', 1 );
            $oldloan->update;
            $num_anon++;
        } catch {
            flash error => "Oops, we got an error:<br />$_";
            error "$_";
            return redirect '/my';
        };
    } 
    flash info => "Anonymized $num_anon loans!";
    redirect '/my';
};

### Routes below this point require admin/superadmin privileges

get '/admin' => require_role admin => sub { 
    my $library = rset('Library')->find( _get_library_for_admin_user() );
    my @lists = rset('List')->search({ library_id => _get_library_for_admin_user() });
    template 'admin', { library => $library, lists => \@lists };
};

get '/superadmin' => require_role superadmin => sub { 
    my @users     = rset('User')->all;
    my @libraries = rset('Library')->all;
    my @providers = rset('Provider')->all;
    template 'superadmin', { 
        'users'     => \@users,
        'libraries' => \@libraries,
        'providers' => \@providers,
    };
};

### Detail view

get '/detailview' => require_role admin => sub { 
    my $library = rset('Library')->find( _get_library_for_admin_user() );
    template 'detailview', { library => $library };
};

post '/detailview' => require_role admin => sub { 
    my $detail_head = param 'detail_head';
    my $soc_links   = param 'soc_links';
    my $library = rset('Library')->find( _get_library_for_admin_user() );
    try {
        $library->set_column( 'detail_head', $detail_head );
        $library->set_column( 'soc_links', $soc_links );
        $library->update;
        flash info => 'The detail view was updated!';
    } catch {
        flash error => "Oops, we got an error:<br />$_";
        error "$_";
    };
    redirect '/admin';
};

### Files

post '/files/add' => require_role admin => sub {

    my $book_id     = param 'book_id';
    my $provider_id = param 'provider_id';
    my $uploadfile  = upload( 'bookfile' );
    my $avail       = param 'availability';
    my $library_id  = _get_library_for_admin_user();

    my $file = undef;
    
    # Look for an existing file
    if ( $avail eq 'local' ) {

        # Local file 
        debug '*** Looking for a local file';   
        my @files = rset('File')->search({
            book_id     => $book_id,
            provider_id => $provider_id,
            library_id  => $library_id,
        });
        $file = $files[0];

    } else {
    
        # Global file
        debug '*** Looking for a global file';
        my @files = rset('File')->search({
            book_id     => $book_id,
            provider_id => $provider_id,
            library_id  => { '=', undef },
        });
        $file = $files[0];
    
    }
    
    # If we found a file, update the content
    if ( $file && $file->id ) {
        try {
            debug '*** Going to replace content of file ' . $file->id;
            $file->set_column( 'file', $uploadfile->content );
            if ( $avail eq 'local' ) {
                $file->set_column( 'library_id', $library_id );
            } else {
                $file->set_column( 'library_id', undef );
            }
            $file->update;
            flash info => 'A file was updated!';
            debug '*** Going to replace content of file ' . $file->id;
        } catch {
            flash error => "Oops, we got an error:<br />$_";
            error "$_";
        };
        return redirect '/books/items/' . $book_id;
    } else {
    
        # If we got this far the file does not exist, so we add the uploaded one
        try {
            my $new_file = rset('File')->create({
                book_id     => $book_id,
                provider_id => $provider_id,
                file        => $uploadfile->content,
            });
            # If this file is only available to the library of the currently logged
            # in librarian we set the the library_id column, otherwise we leave it 
            # empty and the file is available to all libraries
            if ( $avail eq 'local' ) {
                $new_file->set_column( 'library_id', $library_id );
                $new_file->update;
            }
            flash info => 'A new file was added!';
        } catch {
            flash error => "Oops, we got an error:<br />$_";
            error "$_";
        };
        redirect '/books/items/' . $book_id;
    }
};


### Providers

get '/providers/add' => require_role superadmin => sub {
    template 'providers_add';
};

post '/providers/add' => require_role superadmin => sub {

    my $name        = param 'name';
    my $description = param 'description';
    try {
        my $new_provider = rset('Provider')->create({
            name        => $name,
            description => $description,
        });
        flash info => 'A new provider was added!';
        redirect '/superadmin';
    } catch {
        flash error => "Oops, we got an error:<br />$_";
        error "$_";
        redirect '/superadmin';
    };

};

get '/providers/edit/:id' => require_role superadmin => sub {
    my $id = param 'id';
    my $provider = rset('Provider')->find( $id );
    template 'providers_edit', { provider => $provider };
};

post '/providers/edit' => require_role superadmin => sub {

    my $id = param 'id';
    my $name = param 'name';
    my $description = param 'description';
    my $provider = rset('Provider')->find( $id );
    try {
        $provider->set_column( 'name', $name );
        $provider->set_column( 'description', $description );
        $provider->update;
        flash info => 'A provider was updated!';
        redirect '/superadmin';
    } catch {
        flash error => "Oops, we got an error:<br />$_";
        error "$_";
        redirect '/superadmin';
    };

};

get '/providers/delete/:id' => require_role superadmin => sub {
    my $id = param 'id';
    my $provider = rset('Provider')->find( $id );
    template 'providers_delete', { provider => $provider };
};

get '/providers/delete_ok/:id?' => require_role superadmin => sub { 
    
    my $id = param 'id';
    my $provider = rset('Provider')->find( $id );
    # Check that this provider has no items
    my $num_items = rset('Item')->search({ provider_id => $id })->count;
    debug "*** Number of items: $num_items";
    if ( $num_items > 0 ) {
        flash error => "Sorry, that provider still has $num_items items attached!";
        return redirect '/superadmin';
    }
    try {
        $provider->delete;
        flash info => 'A provider was deleted!';
        info "Deleted provider with ID = $id";
        redirect '/superadmin';
    } catch {
        flash error => "Oops, we got an error:<br />$_";
        error "$_";
        redirect '/superadmin';
    };
    
};

### Items

get '/books/items/:book_id' => require_role admin => sub {
    my $book_id    = param 'book_id';
    my $book       = rset('Book')->find( $book_id );
    my $library_id = _get_library_for_admin_user();
    my @files      = rset('File')->search({
        -and => [
            'book_id'    => $book_id,
            -or => [
                'library_id' => $library_id,
                'library_id' => { '=', undef }
            ]
        ]
    }, {
        group_by => [qw/ id /],
        columns => [ 'id', 'book_id', 'provider_id', 'library_id' ]
    });
    my @providers  = rset('Provider')->all;
    template 'books_items', { book => $book, library_id => $library_id, files => \@files, providers => \@providers };
};

get '/books/items/edit/:item_id' => require_role admin => sub {
    my $item_id = param 'item_id';
    my $item = rset('Item')->find( $item_id );
    template 'books_items_edit', { item => $item };
};

post '/books/items/edit' => require_role admin => sub {

    my $item_id     = param 'item_id';
    my $loan_period = param 'loan_period';
    my $item = rset('Item')->find( $item_id );
    try {
        $item->set_column( 'loan_period', $loan_period );
        $item->update;
        flash info => 'An item was updated!';
        redirect '/books/items/' . $item->file->book_id;
    } catch {
        flash error => "Oops, we got an error:<br />$_";
        error "$_";
        redirect '/books/items/' . $item->file->book_id;
    };

};

post '/books/items/editall' => require_role admin => sub {

    my $book_id     = param 'book_id';
    my $loan_period = param 'loan_period';
    my $library_id  = _get_library_for_admin_user();
    my @items = rset('Item')->search({
        'file.book_id' => $book_id,
        library_id     => $library_id,
        deleted        => 0
    }, {
        join => 'file'
    });
    
    my $edited_items_count = 0;
    foreach my $item ( @items ) {
        try {
            $item->set_column( 'loan_period', $loan_period );
            $item->update;
            $edited_items_count++;
        } catch {
            flash error => "Oops, we got an error:<br />$_";
            error "$_";
            return redirect '/books/items/' . $item->book_id;
        };
    }
    flash info => "Updated $edited_items_count items.";
    redirect '/books/items/' . $book_id;

};

get '/books/items/delete/:item_id' => require_role admin => sub {
    my $item_id = param 'item_id';
    my $item    = rset('Item')->find( $item_id );
    my $book    = rset('Book')->find( $item->file->book_id );
    template 'books_items_delete', { item => $item, book => $book };
};

post '/books/items/add' => require_role admin => sub {

    my $library_id  = _get_library_for_admin_user();
    my $file_id     = param 'file_id';
    my $loan_period = param 'loan_period';
    my $num_copies  = param 'num_copies';
    my $book_id     = param 'book_id';
    
    my $new_items_count = 0;
    for ( 1..$num_copies ) {
        try {
            my $new_item = rset('Item')->create({
                library_id  => $library_id,
                file_id     => $file_id,
                loan_period => $loan_period,
            });
            $new_items_count++;
        } catch {
            flash error => "Oops, we got an error:<br />$_";
            error "$_";
            return redirect '/books/items/' . $book_id;
        }
    }
    flash info => "Added $new_items_count new item(s)!";
    redirect '/books/items/' . $book_id;

};

get '/books/items/delete_ok/:item_id?' => require_role admin => sub { 
    
    my $item_id = param 'item_id';
    my $item = rset('Item')->find( $item_id );
    my $book = rset('Book')->find( $item->file->book_id );
    try {
        $item->set_column( 'deleted', 1 );
        $item->update;
        flash info => 'An item was deleted!';
        info "Deleted item with ID = $item_id";
        redirect '/books/items/' . $book->id;
    } catch {
        flash error => "Oops, we got an error:<br />$_";
        error "$_";
        redirect '/books/items/' . $book->id;
    };
    
};

### Lists

get '/lists/add' => require_role admin => sub {
    template 'lists_add';
};

post '/lists/add' => require_role admin => sub {

    my $name     = param 'name';
    my $is_genre = param 'is_genre';
    unless ( defined $is_genre ) {
        $is_genre = 0;
    }
    # Tie the list to the logged in users's library
    my $user = rset('User')->find( session 'logged_in_user_id' );
    my @libraries = $user->libraries;
    my $library = $libraries[0];
    my $library_id = $library->id;
    debug "*** Library ID: $library_id";
    try {
        my $new_list = rset('List')->create({
            name       => $name,
            is_genre   => $is_genre,
            library_id => $library_id,
        });
        flash info => 'A new list was added! <a href="/list/' . $new_list->id . '">View</a>';
        redirect '/admin';
    } catch {
        flash error => "Oops, we got an error:<br />$_";
        error "$_";
        template 'lists_add', { name => $name, is_genre => $is_genre };
    };

};

get '/lists/edit/:id' => require_role admin => sub {
    my $list_id = param 'id';
    my $list = rset('List')->find( $list_id );
    template 'lists_edit', { list => $list };
};

post '/lists/edit' => require_role admin => sub {

    my $id   = param 'id';
    my $name = param 'name';
    my $is_genre = param 'is_genre';
    unless ( defined $is_genre ) {
        $is_genre = 0;
    }
    my $list = rset('List')->find( $id );
    try {
        $list->set_column('name', $name);
        $list->set_column('is_genre', $is_genre);
        $list->update;
        flash info => 'A list was updated! <a href="/list/' . $list->id . '">View</a>';
        redirect '/admin';
    } catch {
        flash error => "Oops, we got an error:<br />$_";
        error "$_";
        template 'lists_edit', { list => $list };
    };

};

get '/lists/delete/:id?' => require_role admin => sub { 
    
    # Confirm delete
    my $id = param 'id';
    my $list = rset('List')->find( $id );
    template 'lists_delete', { list => $list };
    
};

get '/lists/delete_ok/:id?' => require_role admin => sub { 
    
    # Do the actual delete
    my $id = param 'id';
    my $list = rset('List')->find( $id );
    # TODO Check that this library is ready to be deleted!
    try {
        $list->delete;
        flash info => 'A list was deleted!';
        info "Deleted list with ID = $id";
        redirect '/admin';
    } catch {
        flash error => "Oops, we got an error:<br />$_";
        error "$_";
        redirect '/admin';
    };
    
};

### Lists and books

get '/books/lists/:book_id' => require_role admin => sub {
    my $book_id = param 'book_id';
    my $book    = rset('Book')->find( $book_id );
    my $library_id = _get_library_for_admin_user();
    my @lists = rset('List')->search({ library_id => $library_id });
    template 'books_lists', { book => $book, lists => \@lists, library_id => $library_id };
};

post '/books/lists' => require_role admin => sub {
    my $book_id = param 'book_id';
    my $list_id = param 'list_id';
    try {
        rset('ListBook')->create({
            book_id => $book_id, 
            list_id => $list_id, 
        });
        flash info => 'This book was added to a list!';
        redirect '/books/lists/' . $book_id;
    } catch {
        flash error => "Oops, we got an error:<br />$_";
        error "$_";
        redirect '/books/lists/' . $book_id;
    };
};

get '/lists/books/:list_id' => require_role admin => sub {
    my $list_id = param 'list_id';
    my $list    = rset('List')->find( $list_id );
    template 'lists_books', { list => $list };
};

get '/books/lists/delete/:book_id/:list_id' => require_role admin => sub {
    my $book_id = param 'book_id';
    my $list_id = param 'list_id';
    my $book_list = rset('ListBook')->find({ book_id => $book_id, list_id => $list_id });
    try {
        $book_list->delete;
        flash info => 'This book was deleted from a list! <a href="/lists/books/' . $list_id . '">Delete more from this list<a>';
        redirect '/books/lists/' . $book_id;
    } catch {
        flash error => "Oops, we got an error:<br />$_";
        error "$_";
        redirect '/books/lists/' . $book_id;
    };
};

### Creators

get '/creators/add' => require_role admin => sub {
    template 'creators_add';
};

get '/creators/add_from_search' => require_role admin => sub {

    my $q = param 'q';
    
    my $sparql = 'SELECT DISTINCT ?person ?name WHERE { 
            { ?person <http://xmlns.com/foaf/0.1/name> "' . $q . '" . 
    } UNION { ?person <http://def.bibsys.no/xmlns/radatana/1.0#catalogueName> "' . $q . '" . 
    } UNION { ?person <http://xmlns.com/foaf/0.1/lastName> "' . $q . '" . 
    } UNION { ?person <http://xmlns.com/foaf/0.1/firstName> "' . $q . '" . }
    ?person a <http://xmlns.com/foaf/0.1/Person> .
    ?person <http://xmlns.com/foaf/0.1/name> ?name . }'; 
    my $results = _sparql2data( $sparql );
    template 'creators_add_from_search', { results => $results };

};

post '/creators/add' => require_role admin => sub {

    my $name    = param 'name';
    my $dataurl = param 'dataurl';
    try {
        my $new_creator = rset('Creator')->create({
            name    => $name,
            dataurl => $dataurl,
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

    my $id      = param 'id';
    my $name    = param 'name';
    my $dataurl = param 'dataurl';
    my $creator = rset('Creator')->find( $id );
    try {
        $creator->set_column( 'name', $name );
        $creator->set_column( 'dataurl', $dataurl );
        $creator->update;
        flash info => 'A creator was updated! <a href="/creator/' . $creator->id . '">View</a>';
        redirect '/creator/' . $creator->id;
    } catch {
        flash error => "Oops, we got an error:<br />$_";
        error "$_";
        redirect '/creator/' . $creator->id;
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

get '/books/add_from_isbn' => require_role admin => sub {

    my $isbn_in = param 'isbn';
    my $isbn = Business::ISBN->new( $isbn_in );
    if ( $isbn && $isbn->is_valid ) {
    
        my $sparql = 'SELECT DISTINCT ?graph ?uri ?title ?published ?pages WHERE { GRAPH ?graph {
                          ?uri a <http://purl.org/ontology/bibo/Document> .
                          ?uri <http://purl.org/ontology/bibo/isbn> "' . $isbn->common_data . '" .
                          ?uri <http://purl.org/dc/terms/title> ?title .
                          ?uri <http://purl.org/dc/terms/issued> ?published .
                          ?uri <http://purl.org/ontology/bibo/numPages> ?pages .
                      } }';
        my $data = _sparql2data( $sparql );
        template 'books_add', { data => $data, isbn => $isbn->common_data };
    
    } else {
    
        flash error => "$isbn_in is not a valid ISBN!";
        redirect '/admin';
    
    }
};

post '/books/add' => require_role admin => sub {

    my $title   = param 'title';
    my $date    = param 'date';
    my $isbn_in = param 'isbn';
    my $pages   = param 'pages';
    my $dataurl = param 'dataurl';
    
    my $isbn = Business::ISBN->new( $isbn_in );
    if ( $isbn && $isbn->is_valid ) {
    
        try {
            
            my $flash_info;
            my $flash_error;
            
            # Check if the book exists, based on dataurl or ISBN
            my $new_book;
            if ( $dataurl ) {
                $new_book = rset('Book')->find_or_new({
                    dataurl => $dataurl,
                });
            } else {
                $new_book = rset('Book')->find_or_new({
                    isbn => $isbn->common_data,
                });
            }
            if( !$new_book->in_storage ) {
                # This is a new book
                $new_book->set_column( 'title', $title );
                $new_book->set_column( 'date', $date );
                $new_book->set_column( 'isbn', $isbn->common_data );
                $new_book->set_column( 'pages', $pages );
                $new_book->insert;
                $flash_info .= '<cite>' . $new_book->title . '</cite> was added.<br>';
            } else {
                # This is an existing book
                flash error => '<cite>' . $new_book->title . '</cite> already exists.<br>';
                debug "*** Trying to save a book that already exists";
                return redirect '/book/' . $new_book->id;
            }
            
            # Check for authors/creators we need to add, if we got a dataurl
            if ( $dataurl ) {
            
                # Request the URIs of all creators for this book
                my $sparql = 'SELECT DISTINCT ?creator ?name WHERE {
                                <' . $dataurl . '> <http://purl.org/dc/terms/creator> ?creator .
                                ?creator <http://xmlns.com/foaf/0.1/name> ?name .
                              }';
                my $data = _sparql2data( $sparql );
                
                # Loop through the creators
                foreach my $creator ( @{ $data->{'results'}->{'bindings'} } ) {
                    
                    my $dataurl = $creator->{'creator'}->{'value'};
                    my $name    = $creator->{'name'}->{'value'};
                    
                    # Check if this author exists, based on the dataurl
                    # If it does exist, tie it to the new book
                    # If it does not exist, create it before tying it to the new book
                    my $new_creator;
                    try {
                        $new_creator = rset('Creator')->find_or_new({
                            dataurl => $dataurl,
                        });
                        if( !$new_creator->in_storage ) {
                            # This is a new creator
                            $new_creator->set_column( 'name', $name );
                            $new_creator->insert;
                            $flash_info .= $name . ' was added.<br>';
                        } else {
                            # This is an existing creator
                            $flash_info .= $new_creator->name . ' already existed.<br>';
                        }
                    } catch {
                        $flash_error .= "Oops, we got an error:<br />$_";
                        error "$_";
                    };
                    
                    # Now tie the creator to the book. When we have got this far
                    # we do not have to worry about it being an old or new creator
                    my $book_id    = $new_book->id;
                    my $creator_id = $new_creator->id;
                    try {
                        rset('BookCreator')->create({
                            book_id    => $book_id, 
                            creator_id => $creator_id, 
                        });
                        $flash_info .= $new_creator->name . ' was added as creator of <cite>' . $new_book->title . '</cite>.<br>';
                    } catch {
                        $flash_error .= "Oops, we got an error:<br />$_";
                        error "$_";
                    };
                }
                
            }
            
            flash info  => $flash_info;
            flash error => $flash_error;
            return redirect '/book/' . $new_book->id;
            
        } catch {
            flash error => "Oops, we got an error:<br />$_";
            error "$_";
            template 'books_add', { title => $title, date => $date };
        };
        
    } else {
        flash error => "$isbn_in is not a valid ISBN!";
        template 'books_add', { title => $title, date => $date };
    }

};



get '/books/edit/:id' => require_role admin => sub {
    my $book_id = param 'id';
    my $book = rset('Book')->find( $book_id );
    template 'books_edit', { book => $book };
};


post '/books/edit' => require_role admin => sub {

    my $id      = param 'id';
    my $title   = param 'title';
    my $date    = param 'date';
    my $isbn_in = param 'isbn';
    my $pages   = param 'pages';
    my $dataurl = param 'dataurl';
    
    my $book = rset('Book')->find( $id );

    my $isbn = Business::ISBN->new( $isbn_in );
    if ( $isbn && $isbn->is_valid ) {
    
        try {
            $book->set_column('title', $title);
            $book->set_column('date', $date);
            $book->set_column('isbn', $isbn->common_data);
            $book->set_column('pages', $pages);
            $book->set_column('dataurl', $dataurl);
            $book->update;
            flash info => 'A book was updated! <a href="/book/' . $book->id . '">View</a>';
            redirect '/book/' . $book->id;
        } catch {
            flash error => "Oops, we got an error:<br />$_";
            error "$_";
            template 'books_edit', { book => $book };
        };
    
    } else {
        flash error => "$isbn_in is not a valid ISBN!";
        redirect '/books/edit/' . $book->id;
    }
    
};

get '/books/covers/:id' => require_role admin => sub {

    my $book_id = param 'id';
    my $book = rset('Book')->find( $book_id );
    
    if ( $book->isbn ) {
    
        my $sparql = 'SELECT DISTINCT ?cover WHERE {
            ?book <http://purl.org/ontology/bibo/isbn> "' . $book->isbn . '" .
            ?book <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://purl.org/spar/fabio/Manifestation> .
            ?book <http://xmlns.com/foaf/0.1/depiction> ?cover .
        }';
        my $covers = _sparql2data( $sparql );
        debug Dumper $covers;
        template 'books_covers', { book => $book, covers => $covers };
        
    } else {
        flash error => 'This book does not have an ISBN!';
        redirect '/book/' . $book->id;
    }

};

post '/books/covers' => require_role admin => sub {

    my $book_id  = param 'id';
    my $coverurl = param 'coverurl';

    # Get the image and base64-encode it
    my $img = _coverurl2base64( $coverurl );
    
    my $book = rset('Book')->find( $book_id );
    try {
        $book->set_column( 'coverurl', $coverurl );
        $book->set_column( 'coverimg', $img );
        $book->update;
        flash info => 'The cover image for this book was updated!';
    } catch {
        flash error => "Oops, we got an error:<br />$_";
        error "$_";
    };
    redirect '/book/' . $book->id;

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

post '/concurrent_loans' => require_role admin => sub { 
    
    my $concurrent_loans = param 'concurrent_loans';
    my $library = rset('Library')->find( _get_library_for_admin_user() );
    try {
        $library->set_column( 'concurrent_loans', $concurrent_loans );
        $library->update;
        flash info => 'The number of concurrent loans was updated!';
    } catch {
        flash error => "Oops, we got an error:<br />$_";
        error "$_";
    };
    redirect '/admin';

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

## APIs

# Default serialization should be JSON
set serializer => 'JSON';

##  Reader-app API

# The server-side component of the reader-app will be talking to this API

get '/rest/libraries' => sub {
    my @libraries = rset('Library')->all;
    my @data;
    foreach my $lib ( @libraries ) {
        my %libdata = (
            name  => $lib->name,
            realm => $lib->realm,
        );
        push @data, \%libdata;
    }
    return \@data;
};

# FIXME Switch from GET to POST before launch, to avoid passwords in logs etc
get '/rest/login' => sub {

    my $username  = param 'username';
    my $password  = param 'password';
    my $userrealm = param 'realm';
    my $pkey      = param 'pkey';
    
    # Check that we have the necessary info
    unless ( $username ) {
        return { 
            status => 1,
            error  => 'Missing parameter: username',
        };
    }
    unless ( $password ) {
        return { 
            status => 1,
            error  => 'Missing parameter: password',
        };
    }
    unless ( $userrealm ) {
        return { 
            status => 1,
            error  => 'Missing parameter: realm',
        };
    }
    unless ( $pkey ) {
        return { 
            status => 1,
            error  => 'Missing parameter: pkey',
        };
    }
    
    # Try to log in
    my ( $success, $realm ) = authenticate_user( $username, $password, $userrealm );
    if ( $success ) {
        # Find the user
        my $user = rset('User')->find({ username => $username });
        # Check if a hash has been saved already
        if ( $user->hash eq '' ) {
            # Create the local_hash
            my $now = DateTime->now;
            my $local_hash = md5_hex( $username . $now->datetime() );
            # Save the new local_hash
            try {
                $user->set_column( 'hash', $local_hash );
                $user->update;
            }
        }
        # Hash the pkey with the user hash and return the result
        my $hash = hash_pkey( $user->hash, $pkey );
        return { 
            'status'   => 0,
            'userdata' => {
                'hash'     => $hash,
                'uid'      => $user->id,
                'username' => $user->username,
                'name'     => $user->name,
                'realm'    => $realm,
            }
        };
    } else {
        return { 
            status => 0,
            error  => 'Login failed',
        };
    }
};

# FIXME Not implemented
get '/rest/logout' => sub {

    return { 
        status => 0
    };

};

get '/rest/:action' => sub {

    my $action  = param 'action';
    my $user_id = param 'uid';
    my $hash    = param 'hash';
    my $pkey    = param 'pkey';
    
    ## Common security checks for all actions
    
    # Check parameters
    unless ( $user_id ) {
        return { 
            status => 1,
            error  => 'Missing parameter: uid',
        };
    }
    unless ( $hash ) {
        return { 
            status => 1,
            error  => 'Missing parameter: hash',
        };
    }
    unless ( $pkey ) {
        return { 
            status => 1,
            error  => 'Missing parameter: pkey',
        };
    }
    
    my $user = rset('User')->find( $user_id );
    
    # Check the user has a hash set
    if ( $user->hash eq '' ) {
        return { 
            status => 1,
            error  => 'User has never logged in',
        };
    }
    
    # Check the saved hash against the supplied hash
    unless ( check_hash( $user->hash, $hash, $pkey ) ) {
        return { 
            status => 1,
            error  => 'Credentials do not match',
        };
    }
    
    ## End of common security checks
    
    if ( $action eq 'listbooks' ) {

        debug "*** /rest/listbooks for user = $user_id";
    
        my @loans;
        foreach my $loan ( $user->loans ) {
            debug "Loan: " . $loan->loaned;
            my %loan;
            $loan{'bookid'}   = $loan->item->file->book->id;
            $loan{'loaned'}   = $loan->loaned->datetime;
            $loan{'due'}      = $loan->due->datetime;
            $loan{'expires'}  = $loan->due->epoch; # Same as 'due', but in seconds since epoch
            $loan{'title'}    = $loan->item->file->book->title;
            $loan{'name'}     = $loan->item->file->book->title;
            $loan{'language'} = 'no'; # FIXME Make this part of the schema
            $loan{'creator'}  = $loan->item->file->book->creators_as_string;
            $loan{'author'}   = $loan->item->file->book->creators_as_string;
            $loan{'coverurl'} = $loan->item->file->book->coverurl;
            $loan{'coverimg'} = $loan->item->file->book->coverimg;
            $loan{'pages'}    = $loan->item->file->book->pages;
            push @loans, \%loan;
        }
        return { 
            'status'   => 0, 
            'booklist' => \@loans
        };
        
    } elsif ( $action eq 'getbook' ) {
    
        debug "*** /rest/getbook for user = $user_id";
    
        my $book_id = param 'bookid';
        # FIXME Check that we got a book_id
        debug "*** /rest/getbook for book_id = $book_id";
        
        foreach my $loan ( $user->loans ) {
            if ( $loan->item->file->book->id == $book_id ) {
                debug "*** /rest/getbook for loan with item_id = " . $loan->item_id . " user_id = " . $loan->user_id . " loaned = " . $loan->loaned;
                debug "*** /rest/getbook for item = " . $loan->item->id . " library_id = " . $loan->item->library_id . " file_id = " . $loan->item->file_id;
                debug "*** /rest/getbook for file = " . $loan->item->file->id;
                my $content = $loan->item->file->file;
                if ( $content ) {
                    return send_file(
                        \$content,
                        content_type => 'application/epub+zip',
                        filename     => 'book-' . $loan->item->file->id . '.epub'
                    );
                } else {
                    status 404;
                    return { 
                        'status' => 1, 
                        'error'  => 'Book not found',
                    };
                }
            }
        }
        # If we got this far we did not find a file representing the given 
        # book that is on loan to the given user, so return an error
        status 500;
        return "This book is not on loan to the given user.";

    } elsif ( $action eq 'ping' ) {
    
        return { 
            'status' => 0, 
        };
    
    } elsif ( $action eq 'whoami' ) {
    
        my $logged_in_user = logged_in_user;
        debug Dumper $logged_in_user;
        debug $user_id;
        if ( $logged_in_user && $logged_in_user->{'id'} eq $user_id ) { 
            my $user = rset('User')->find( $logged_in_user->{'id'} );
            my $hash = hash_pkey( $user->hash, $pkey );
            return { 
                'status'   => 0,
                'userdata' => {
                    'hash'     => $hash,
                    'uid'      => $user->id,
                    'username' => $user->username,
                    'name'     => $user->name,
                    'realm'    => session 'logged_in_user_real_realm',
                }
            };
        } else {
            return { 
                'status'   => 1,
            };
        }
    
    }

};

### Utility functions
# TODO Move these to a separate .pm
# TODO Add documentation

sub check_hash {
    my ( $user_hash, $hash, $pkey ) = @_;
    if ( md5_hex( $user_hash . $pkey ) eq $hash ) {
        return 1;
    } else {
        return;
    }
}

sub hash_pkey{
    my ( $user_hash, $pkey ) = @_;
    return md5_hex( $user_hash . $pkey );
}

sub _user_has_borrowed {
    my ( $user, $book ) = @_;
    foreach my $loan ( $user->loans ) {
        if ( $loan->item->file->book->id == $book->id ) {
            return 1;
        } 
    }
}

# Assumes that admin users are only connected to one library
sub _get_library_for_admin_user {
    my $user_id = session 'logged_in_user_id';
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
