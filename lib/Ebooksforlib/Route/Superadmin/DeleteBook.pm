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

get '/superadmin/delete/book/:id' => require_role superadmin => sub { 

    my $book_id = param 'id';
    my $book = rset( 'Book' )->find( $book_id );
    template 'superadmin_delete_book', { book => $book };

};

true;
