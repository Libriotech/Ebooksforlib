
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
use Ebooksforlib::Route::Login;
use Ebooksforlib::Route::MyProfile;
use Ebooksforlib::Route::Circ;
use Ebooksforlib::Route::RestApi;
use Ebooksforlib::Route::Admin;
use Ebooksforlib::Route::Admin::Settings;
use Ebooksforlib::Route::Admin::Books;
use Ebooksforlib::Route::Admin::Lists;
use Ebooksforlib::Route::Admin::Stats;
use Ebooksforlib::Route::Admin::Logs;
use Ebooksforlib::Route::Superadmin;
use Ebooksforlib::Route::Superadmin::Providers;

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

get '/' => sub {

    # Use HTTP Basic Auth for everything but the REST API
    # unless ( request->path =~ /\/rest\/.*/ ) {
    #    auth_basic user => 'ebib', password => 'passord';
    # }
    
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
    # my @lists = rset('List')->search({
    #     'library_id' => session('chosen_library')
    # });
    # template 'index', { lists => \@lists };
    
    my @booklists;

    # Find all the lists for this library, that should be shown on the front page
    my @lists = rset('List')->search({
        'library_id' => session('chosen_library'),
        'frontpage'  => 1,
    }, {
        'order_by' => 'frontpage_order',
    });
    # Get the ListBook's for each list
    # FIXME Why do I do this? Can't I get the books from the lists themselves?!? 
    foreach my $list ( @lists ) {
        my @booklist = rset('ListBook')->search({ list_id => $list->id });
        push @booklists, { booklist => \@booklist, list => $list };
    }
        
    my @mobile = rset('List')->search({
        'library_id' => session('chosen_library'),
        'mobile'     => 1,
    });
    my @mobilebooklist;
    if ( $mobile[0] ) {
        @mobilebooklist = rset('ListBook')->search({ list_id => $mobile[0]->id });
    }
    
    var hide_dropdowns => 1;    
    template 'index', { 
        booklists      => \@booklists, 
        mobilebooklist => \@mobilebooklist, 
    };
    
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
    # my $descriptions = $book->get_descriptions;
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
        # descriptions            => $descriptions,
        library                 => $library,
        pagetitle               => $book->title,
    };
};

### "Static" pages

get '/page/:slug' => sub {

    my $slug = param 'slug';
    
    # Allowed pages
    my @pages = qw( help help2 help3 help4 help5 newuser about contact info );
    # FIXME Apparently, ~~ is deprecated as of Perl 5.18 so replacing it here 
    # would be a good idea
    if ( /$slug/i ~~ @pages ) {
        template 'page', { slug => "page_$slug.tt" };
    } else {
        return redirect '/';
    }

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
    my $num_books = @books;
    
    # Search for people
    my @creators = rset('Creator')->search(
        {},
        { order_by => 'name desc' }
    )->search_literal('MATCH ( name ) AGAINST( ? IN BOOLEAN MODE )', $q );
    my $num_creators = @creators;
    
    # If we just got one hit for either book or person then redirect to that
    if ( config->{one_hit_redirect} && $num_books == 1 && $num_creators == 0 ) {
        return redirect '/book/' . $books[0]->id;
    }
    if ( config->{one_hit_redirect} && $num_books == 0 && $num_creators == 1 ) {
        return redirect '/creator/' . $creators[0]->id;
    }
    
    template 'search', { books => \@books, creators => \@creators };

};

get '/creator/:id' => sub {
    my $creator_id = param 'id';
    my $creator = rset('Creator')->find( $creator_id );
    template 'creator', { 
        creator   => $creator,
        pagetitle => $creator->name,
    };
};

get '/lists' => sub {
    my @genres = rset('List')->search({ library_id => session('chosen_library'), is_genre => 1 });
    my @lists  = rset('List')->search({ library_id => session('chosen_library'), is_genre => 0 });
    template 'lists', { genres => \@genres, lists => \@lists };
};

get '/list/:id' => sub {
    my $list_id = param 'id';
    my $list = rset('List')->find( $list_id );
    template 'list', { 
        list      => $list,
        pagetitle => $list->name,
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
    # Consider html strip
    my $item = rset('Item')->find( $item_id );
    try {
        $item->set_column( 'loan_period', $loan_period );
        $item->update;
        flash info => 'An item was updated!';
        redirect '/books/items/' . $item->file->book_id;
    } catch {
        flash error => "Oops, we got an error:<br />".errmsg($_);
        error "$_";
        redirect '/books/items/' . $item->file->book_id;
    };

};

post '/books/items/editall' => require_role admin => sub {

    my $book_id     = param 'book_id';
    my $loan_period = param 'loan_period';
    # Consider html strip
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
            flash error => "Oops, we got an error:<br />".errmsg($_);
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
    # Consider html strip
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
            flash error => "Oops, we got an error:<br />".errmsg($_);
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
        flash error => "Oops, we got an error:<br />".errmsg($_);
        error "$_";
        redirect '/books/items/' . $book->id;
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
    # html strip ?
    try {
        my $new_creator = rset('Creator')->create({
            name    => $name,
            dataurl => $dataurl,
        });
        flash info => 'A new creator was added! <a href="/creator/' . $new_creator->id . '">View</a>';
        redirect '/admin';
    } catch {
        flash error => "Oops, we got an error:<br />".errmsg($_);
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
    # html strip
    my $creator = rset('Creator')->find( $id );
    try {
        $creator->set_column( 'name', $name );
        $creator->set_column( 'dataurl', $dataurl );
        $creator->update;
        flash info => 'A creator was updated! <a href="/creator/' . $creator->id . '">View</a>';
        redirect '/creator/' . $creator->id;
    } catch {
        flash error => "Oops, we got an error:<br />".errmsg($_);
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
        flash error => "Oops, we got an error:<br />".errmsg($_);
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
        flash error => "Oops, we got an error:<br />".errmsg($_);
        error "$_";
        redirect '/books/creators/add/' . $book_id;
    };
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
        my $bokkilden = _isbn2bokkliden_cover( $book->isbn );
        debug Dumper $covers;
        template 'books_covers', { book => $book, covers => $covers, bokkilden => $bokkilden };
        
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
        flash error => "Oops, we got an error:<br />".errmsg($_);
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
        my $hs = HTML::Strip->new();
        $name  = $hs->parse( $name );
        $hs->eof;
        my $new_library = rset('Library')->create({
            name  => $name,
        });
        flash info => 'A new library was added!';
        redirect '/superadmin';
    } catch {
        flash error => "Oops, we got an error:<br />".errmsg($_);
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
        my $hs = HTML::Strip->new();
        $name  = $hs->parse( $name );
        $realm = $hs->parse( $realm );
        $hs->eof;
        $library->set_column('name', $name);
        $library->set_column('realm', $realm);
        $library->update;
        flash info => 'A library was updated!';
        redirect '/superadmin';
    } catch {
        flash error => "Oops, we got an error:<br />".errmsg($_);
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
        flash error => "Oops, we got an error:<br />".errmsg($_);
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
