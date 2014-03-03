package Ebooksforlib::Route::Admin::Creators;

=head1 Ebooksforlib::Route::Admin::Creators

Routes for handling creators (authors), as well as for connecting creators to books.

=cut

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::FlashMessage;
use Dancer::Exception qw(:all);
use Ebooksforlib::Util;
use Ebooksforlib::Err;

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

true;
