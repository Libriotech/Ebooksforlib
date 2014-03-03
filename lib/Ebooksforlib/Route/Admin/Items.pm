package Ebooksforlib::Route::Admin::Items;

=head1 Ebooksforlib::Route::Admin::Items

Routes for handling items.

=cut

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::FlashMessage;
use Dancer::Exception qw(:all);
use Ebooksforlib::Util;
use Ebooksforlib::Err;

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

true;
