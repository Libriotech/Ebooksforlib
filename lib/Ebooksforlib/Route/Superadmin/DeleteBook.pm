package Ebooksforlib::Route::Superadmin::DeleteBook;

=head1 Ebooksforlib::Route::Superadmin::DeleteBook

Routes for deleting books.

=cut

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::FlashMessage;
use Dancer::Exception qw(:all);
use Ebooksforlib::Util;

get '/superadmin/delete_book/:id' => require_role superadmin => sub { 

    my $book_id = param 'id';
    my $book = rset( 'Book' )->find( $book_id );
    template 'superadmin_delete_book', { book => $book };

};

get '/superadmin/delete_book_ok/:id' => require_role superadmin => sub { 

    unless ( _check_csrftoken( param 'csrftoken' ) ) {
        return redirect '/';
    }

    my $book_id = param 'id';
    my $book = rset( 'Book' )->find( $book_id );
    # Loop over the files
    foreach my $file ( $book->files ) {
        # Loop over the items
        foreach my $item ( $file->items ) {
            try {
                # Check if there are any loans
                if ( $item->loan ) {
                    try {
                        # Delete the loan first of all
                        $item->loan->delete;
                        info "Deleted loan with ID = " . $item->loan->id;
                    } catch {
                        flash error => "Oops, we got an error:<br />".errmsg($_);
                        error "$_";
                    };
                }
                # Now delete the item
                $item->delete;
                info "Deleted item with ID = " . $item->id;
            } catch {
                flash error => "Oops, we got an error:<br />".errmsg($_);
                error "$_";
            };
        }
        try {
            # When all items connected to this file are deleted, we can delete the file
            $file->delete;
            info "Deleted file with ID = " . $file->id;
        } catch {
            flash error => "Oops, we got an error:<br />".errmsg($_);
            error "$_";
        };
    }
    try {
        # All items and files should be gone by now, so let's delete the book itself
        $book->delete;
        flash info => 'A book was deleted!';
        info "Deleted book with ID = $book_id";
    } catch {
        flash error => "Oops, we got an error:<br />".errmsg($_);
        error "$_";
    };
    redirect '/superadmin';

};

true;
