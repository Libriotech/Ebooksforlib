package Ebooksforlib::Route::Admin::Covers;

=head1 Ebooksforlib::Route::Admin::Covers

Routes for handling covers.

=cut

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::FlashMessage;
use Dancer::Exception qw(:all);
use Ebooksforlib::Util;
use Ebooksforlib::Err;
use Data::Dumper;

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

    unless ( _check_csrftoken( param 'csrftoken' ) ) {
        return redirect '/';
    }

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


true;
