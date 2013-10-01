package Ebooksforlib::Route::Ratings;

=head1 Ebooksforlib::Route::Ratings

Routes for handling ratings. Currently not in use. 

=cut

use Dancer ':syntax';
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::FlashMessage;

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

true;
