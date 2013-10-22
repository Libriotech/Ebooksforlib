package Ebooksforlib::Route::Admin::Books;

=head1 Ebooksforlib::Route::Admin::Books

Routes for adding and editing metadata about books

=cut

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::FlashMessage;
use Dancer::Exception qw(:all);
use Ebooksforlib::Util;

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

true;
