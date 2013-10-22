package Ebooksforlib::Route::Admin::Lists;

=head1 Ebooksforlib::Route::Admin::Lists

Routes for adding and editing lists and their contents

=cut

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::FlashMessage;
use Dancer::Exception qw(:all);
use Ebooksforlib::Util;

### Lists

get '/admin/lists' => require_role admin => sub { 
    my @lists = rset('List')->search({ library_id => _get_library_for_admin_user() });
    template 'admin_lists', { lists => \@lists };
};

get '/lists/add' => require_role admin => sub {
    template 'lists_add';
};

post '/lists/add' => require_role admin => sub {

    my $name      = param 'name';
    my $is_genre  = param 'is_genre';
    my $frontpage = param 'frontpage';
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
            frontpage  => $frontpage,
            library_id => $library_id,
        });
        flash info => 'A new list was added! <a href="/list/' . $new_list->id . '">View</a>';
        redirect '/admin/lists';
    } catch {
        flash error => "Oops, we got an error:<br />$_";
        error "$_";
        template 'lists_add', { name => $name, is_genre => $is_genre };
    };

};

get '/lists/edit/:id' => require_role admin => sub {
    my $list_id = param 'id';
    my $list = rset('List')->find( $list_id );
    my $library_id = _get_library_for_admin_user();
    my @booklist = rset('ListBook')->search({ list_id => $list_id });
    template 'lists_edit', { list => $list, booklist => \@booklist };
};

post '/lists/edit' => require_role admin => sub {

    my $id   = param 'id';
    my $name = param 'name';
    my $is_genre = param 'is_genre';
    my $frontpage = param 'frontpage';
    unless ( defined $is_genre ) {
        $is_genre = 0;
    }
    my $list = rset('List')->find( $id );
    try {
        $list->set_column('name', $name);
        $list->set_column('is_genre', $is_genre);
        $list->set_column('frontpage', $frontpage);
        $list->update;
        flash info => 'A list was updated! <a href="/list/' . $list->id . '">View</a>';
        redirect '/admin/lists';
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
        redirect '/admin/lists';
    } catch {
        flash error => "Oops, we got an error:<br />$_";
        error "$_";
        redirect '/admin';
    };
    
};

get '/lists/promo/:action/:list_id/:book_id' => require_role admin => sub { 
    
    # Do the actual delete
    my $action  = param 'action';
    my $list_id = param 'list_id';
    my $book_id = param 'book_id';
    my $listbook = rset('ListBook')->find({ list_id => $list_id, book_id => $book_id });
    my $value = 0;
    if ( $action eq 'promote' ) {
        $value = 1;
    }
    debug "Going to do action = $action and set promoted = $value for book_id = $book_id in list_id = $list_id";
    
    try {
        $listbook->set_column( 'promoted', $value );
        $listbook->update;
        flash info => 'The list was updated!';
    } catch {
        flash error => "Oops, we got an error:<br />$_";
        error "$_";
    };
    redirect '/lists/edit/' . $list_id;

};

get '/lists/order' => require_role admin => sub { 
    
    my $frontpage_order = param 'frontpage_order';
    debug "*** frontpage_order: $frontpage_order";

    # Set all frontpage_order = 0 for the active library
    my @lists = rset('List')->search({ library_id => _get_library_for_admin_user() });
    foreach my $list ( @lists ) {
        try {
            $list->set_column( 'frontpage_order', 0 );
            $list->update;
            debug "** frontpage_order = 0 for list with id = " . $list->id;
        } catch {
            error "$_";
            return 0;
        };
    }
    
    # Set a new frontpage_order for the lists we were given
    my @ids = split( /,/, $frontpage_order );
    my $position = 1;
    foreach my $id ( @ids ) {
        my $list = rset('List')->find( $id );
        try {
            $list->set_column( 'frontpage_order', $position );
            $list->update;
            debug "** frontpage_order = $position for list with id = " . $id;
            $position++;
        } catch {
            error "$_";
            return 0;
        };
    }    
    
    return 1;

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

true;
