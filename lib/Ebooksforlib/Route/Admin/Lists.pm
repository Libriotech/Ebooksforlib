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
use Ebooksforlib::Err;


### Lists

get '/admin/lists' => require_role admin => sub { 
    my @global_lists = resultset('List')->search({
        -and => [
            is_global  => 1,
            -or => [
                'list_libraries.library_id' => _get_library_for_admin_user(),
                'list_libraries.library_id' => undef
            ],
        ],
    },{
        join => 'list_libraries',
    });
    my @local_lists = resultset('List')->search({
        is_global                   => 0,
        is_genre                    => 0,
        'list_libraries.library_id' => _get_library_for_admin_user(),
    },{
        join => 'list_libraries',
    });
    my @frontpage_lists = resultset('List')->search({
        'list_libraries.library_id' => _get_library_for_admin_user(),
        'list_libraries.frontpage'  => 1,
    },{
        join     => 'list_libraries',
        order_by => 'list_libraries.frontpage_order',
    });
    template 'admin_lists', {
        global_lists    => \@global_lists,
        local_lists     => \@local_lists,
        frontpage_lists => \@frontpage_lists,
    };
};

get '/lists/add' => require_role admin => sub {
    template 'lists_add';
};

post '/lists/add' => require_role admin => sub {

    unless ( _check_csrftoken( param 'csrftoken' ) ) {
        return redirect '/';
    }

    my $name      = param 'name';
    my $frontpage = param 'frontpage';
    my $mobile    = param 'mobile';
    # html strip
    try {
        my $new_list = rset('List')->create({
            name      => $name,
            is_genre  => 0, # Admin can not add a genre
            is_global => 0, # Admin can not make a list global
        });

        # Save some more info in ListLibrary
        try {
            my $new_list = rset('ListLibrary')->create({
                list_id    => $new_list->id,
                library_id => _get_library_for_admin_user(),
                frontpage  => $frontpage,
                mobile     => $mobile,
            });
        } catch {
            flash error => "Oops, we got an error:<br />".errmsg($_);
            error "$_";
            template 'lists_add', { name => $name };
        };

        flash info => 'A new list was added! <a href="/list/' . $new_list->id . '">View</a>';
        redirect '/admin/lists';
    } catch {
        flash error => "Oops, we got an error:<br />".errmsg($_);
        error "$_";
        template 'lists_add', { name => $name };
    };

};

get '/lists/edit/:id' => require_role admin => sub {
    my $list_id = param 'id';
    my $list = resultset('List')->find( $list_id );
    my $list_library = resultset('ListLibrary')->find({
        list_id    => $list_id,
        library_id => _get_library_for_admin_user(),
    });
    my @booklist = rset('ListBook')->search({ list_id => $list_id });
    template 'lists_edit', {
        list         => $list,
        list_library => $list_library,
        booklist     => \@booklist
    };
};

post '/lists/edit' => require_role admin => sub {

    unless ( _check_csrftoken( param 'csrftoken' ) ) {
        return redirect '/';
    }

    my $id        = param 'id';
    my $name      = param 'name';
    # Only superadmin should set this: my $is_genre  = param 'is_genre';
    my $frontpage = param 'frontpage';
    my $mobile    = param 'mobile';
    # Save the stuff that goes in the list
    my $list = resultset('List')->find( $id );
    try {

        if ( $name ne '' ) {
            $list->set_column('name', $name);
        }
        # $list->set_column('is_genre', $is_genre);
        $list->update;

        # Save the stuff that goes in the list/library connection
        my $listlibrary = resultset('ListLibrary')->find_or_create({
            list_id    => $id,
            library_id => _get_library_for_admin_user(),
        });
        try {
            $listlibrary->set_column('frontpage', $frontpage);
            $listlibrary->set_column('mobile', $mobile);
            $listlibrary->update;
            flash info => 'A list was updated! <a href="/list/' . $id . '">View</a>';
            redirect '/admin/lists';
        } catch {
            flash error => "Oops, we got an error:<br />".errmsg($_);
            error "$_";
            template 'lists_edit', { list => $listlibrary };
        };

    } catch {
        flash error => "Oops, we got an error:<br />".errmsg($_);
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
    
    unless ( _check_csrftoken( param 'csrftoken' ) ) {
        return redirect '/';
    }
    
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
        flash error => "Oops, we got an error:<br />".errmsg($_);
        error "$_";
        redirect '/admin';
    };
    
};

get '/lists/promo/:action/:list_id/:book_id' => require_role admin => sub { 

    unless ( _check_csrftoken( param 'csrftoken' ) ) {
        return redirect '/';
    }
    
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
        flash error => "Oops, we got an error:<br />".errmsg($_);
        error "$_";
    };
    redirect '/lists/edit/' . $list_id;

};

get '/lists/order' => require_role admin => sub { 
    
    my $frontpage_order = param 'frontpage_order';
    debug "*** frontpage_order: $frontpage_order";

    # Set all frontpage_order = 0 for the active library
    my @lists = rset('ListLibrary')->search({
        library_id => _get_library_for_admin_user(),
    });
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
        my $list = rset('ListLibrary')->find({
            list_id    => $id,
            library_id => _get_library_for_admin_user(),
        });
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
    my $book_id      = param 'book_id';
    my $book         = resultset('Book')->find( $book_id );
    my $library_id   = _get_library_for_admin_user();
    my @global_lists = resultset('List')->search({
        -and => [
            is_global  => 1,
            -or => [
                'list_libraries.library_id' => _get_library_for_admin_user(),
                'list_libraries.library_id' => undef, # Catch lists that are not in list_libraries for this library yet
            ],
        ],
    },{
        join => 'list_libraries',
    });
    my @local_lists = resultset('List')->search({
        is_global                   => 0,
        is_genre                    => 0,
        'list_libraries.library_id' => _get_library_for_admin_user(),
    },{
        join => 'list_libraries',
    });
    template 'books_lists', {
        book         => $book,
        library_id   => $library_id,
        global_lists => \@global_lists,
        local_lists  => \@local_lists,
    };
};

post '/books/lists' => require_role admin => sub {

    unless ( _check_csrftoken( param 'csrftoken' ) ) {
        return redirect '/';
    }

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
        flash error => "Oops, we got an error:<br />".errmsg($_);
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

    unless ( _check_csrftoken( param 'csrftoken' ) ) {
        return redirect '/';
    }

    my $book_id = param 'book_id';
    my $list_id = param 'list_id';
    my $book_list = resultset('ListBook')->find({
        book_id => $book_id,
        list_id => $list_id,
    });
    try {
        $book_list->delete;
        flash info => 'This book was deleted from a list! <a href="/lists/books/' . $list_id . '">Delete more from this list<a>';
        redirect '/lists/books/' . $list_id;
    } catch {
        flash error => "Oops, we got an error:<br />".errmsg($_);
        error "$_";
        redirect '/books/lists/' . $book_id;
    };
};

true;
