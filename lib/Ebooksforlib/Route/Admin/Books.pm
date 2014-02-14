package Ebooksforlib::Route::Admin::Books;

=head1 Ebooksforlib::Route::Admin::Books

Routes for adding and editing metadata about books and files

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

get '/books/imported' => require_role admin => sub {
    my @books = resultset('Book')->search({ title => '' });
    template 'books_imported', { books => \@books };
};

get '/books/add_from_isbn' => require_role admin => sub {

    my $isbn_in = param 'isbn';
    my $hs = HTML::Strip->new();
    $isbn_in  = $hs->parse( $isbn_in );
    $hs->eof;
    $isbn_in = HTML::Entities::encode($isbn_in);
    my $isbn = Business::ISBN->new( $isbn_in );
    if ( $isbn && $isbn->is_valid ) {
        my $data = _get_data_from_isbn( $isbn );
        template 'books_add', { data => $data, isbn => $isbn->common_data };
    
    } else {

        $isbn_in = 'This' if(!$isbn_in);
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
    my $book_id = param 'id';
    
    my $hs = HTML::Strip->new();
    $title = $hs->parse( $title );
    $date  = $hs->parse( $date );
    $isbn_in = $hs->parse( $isbn_in );
    $pages   = $hs->parse( $pages );
    $dataurl = $hs->parse( $dataurl );
    $hs->eof;
            
    my $isbn = Business::ISBN->new( $isbn_in );
    if ( $isbn && $isbn->is_valid ) {
    
        try {
            my $flash_info;
            my $flash_error;
            
            # Check if the book exists, based on ISBN
            my $new_book = rset('Book')->find_or_new({
                isbn => $isbn->common_data,
            });
            # This is a new book
            $new_book->set_column( 'title', $title );
            $new_book->set_column( 'date',  $date );
            $new_book->set_column( 'isbn',  $isbn->common_data );
            $new_book->set_column( 'pages', $pages );
            if( $new_book->in_storage ) {
                $new_book->update;
                $flash_info .= '<cite>' . $new_book->title . '</cite> was updated.<br>';
            } else {
                $new_book->insert;
                $flash_info .= '<cite>' . $new_book->title . '</cite> was added.<br>';
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
        $isbn_in = 'This' if(!$isbn_in);
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
    
    my $hs = HTML::Strip->new();
    $title = $hs->parse( $title );
    $date  = $hs->parse( $date );
    $isbn_in = $hs->parse( $isbn_in );
    $pages   = $hs->parse( $pages );
    $dataurl = $hs->parse( $dataurl );
    $hs->eof;

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
        $isbn_in = 'This' if(!$isbn_in);
        flash error => "$isbn_in is not a valid ISBN!";
        redirect '/books/edit/' . $book->id;
    }
    
};

### Files

post '/files/add' => require_role admin => sub {

    my $book_id     = param 'book_id';
    my $provider_id = param 'provider_id';
    my $uploadfile  = upload( 'bookfile' );
    my $avail       = param 'availability';
    my $library_id  = _get_library_for_admin_user();

    my $file = undef;
    
    # Look for an existing file
    if ( $avail eq 'local' ) {

        # Local file 
        debug '*** Looking for a local file';   
        my @files = rset('File')->search({
            book_id     => $book_id,
            provider_id => $provider_id,
            library_id  => $library_id,
        });
        $file = $files[0];

    } else {
    
        # Global file
        debug '*** Looking for a global file';
        my @files = rset('File')->search({
            book_id     => $book_id,
            provider_id => $provider_id,
            library_id  => { '=', undef },
        });
        $file = $files[0];
    
    }
    
    # If we found a file, update the content
    if ( $file && $file->id ) {
        try {
            debug '*** Going to replace content of file ' . $file->id;
            $file->set_column( 'file', $uploadfile->content );
            if ( $avail eq 'local' ) {
                $file->set_column( 'library_id', $library_id );
            } else {
                $file->set_column( 'library_id', undef );
            }
            $file->update;
            flash info => 'A file was updated!';
            debug '*** Going to replace content of file ' . $file->id;
        } catch {
            flash error => "Oops, we got an error:<br />$_";
            error "$_";
        };
        return redirect '/books/items/' . $book_id;
    } else {
    
        # If we got this far the file does not exist, so we add the uploaded one
        try {
            my $new_file = rset('File')->create({
                book_id     => $book_id,
                provider_id => $provider_id,
                file        => $uploadfile->content,
            });
            # If this file is only available to the library of the currently logged
            # in librarian we set the the library_id column, otherwise we leave it 
            # empty and the file is available to all libraries
            if ( $avail eq 'local' ) {
                $new_file->set_column( 'library_id', $library_id );
                $new_file->update;
            }
            flash info => 'A new file was added!';
        } catch {
            flash error => "Oops, we got an error:<br />$_";
            error "$_";
        };
        redirect '/books/items/' . $book_id;
    }
};

true;
