package Ebooksforlib::Route::Browse;

=head1 Ebooksforlib::Route::Browse

Routes for finding books, including search, lists, detail view etc. 

=cut

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::FlashMessage;
use Dancer::Plugin::Lexicon;
use Dancer::Exception qw( :all );
use MIME::Base64 qw( decode_base64 );
use Ebooksforlib::Util;

get '/' => sub {

    my @lists = resultset('List')->search({
        'list_libraries.frontpage'      => 1,
        'list_libraries.library_id' => session('chosen_library'),
    },{
        'join'     => 'list_libraries',
        'order_by' => 'list_libraries.frontpage_order',
    });
    template 'index', { 
        lists => \@lists,
    };
    
};

get '/book/:id' => sub {
    
    my $book_id = param 'id';
    my $book = rset('Book')->find( $book_id );
    
    my $user_has_borrowed = 0;
    my $limit_reached = 0;
    my $user_belongs_to_library = 0;
    my $library = rset('Library')->find( session('chosen_library') );
    if ( session('logged_in_user_id') ) {
    
        my $user = rset('User')->find( session('logged_in_user_id') );
    
        # Check that the user belongs to the chosen library
        if ( $user->belongs_to_library( session('chosen_library') ) ) {
            $user_belongs_to_library = 1;
        }
    
        # Check if the user has already borrowed this book
        $user_has_borrowed = _user_has_borrowed( $user, $book );

        # Check the number of concurrent loans
        if ( $user->number_of_loans_from_library( $library->id ) >= $library->concurrent_loans ) {
            $limit_reached = 1;
        }
        
    }
    
    template 'book', { 
        book                    => $book, 
        user_has_borrowed       => $user_has_borrowed,
        # items                 => \@items,
        limit_reached           => $limit_reached,
        user_belongs_to_library => $user_belongs_to_library,
        # descriptions            => $descriptions,
        library                 => $library,
        pagetitle               => $book->title,
    };
};

get '/cover/:id' => sub {

    my $book_id = param 'id';
    my $book = resultset('Book')->find( $book_id );

    my $base64_img = $book->coverimg;
   
    $base64_img =~ s/^.*?base64,//;
    # FIXME Base the content type on the data in coverimg
    header 'Content-type' => 'image/jpeg';
    return decode_base64( $base64_img );

};

### "Static" pages

get '/page/:slug' => sub {

    my $slug = param 'slug';
    
    # Allowed pages
    my %pages = (
        help    => 1,
        newuser => 1,
        about   => 1,
        contact => 1,
        info    => 1,
    );
    if ( $pages{ $slug } == 1 ) {
        my $page = resultset('Page')->find( $slug );
        # This will let us use page.text_html without autoescaping
        $page->{'text_html'} = $page->text;
        template 'page', {
            'slug' => $slug,
            'page' => $page,
        };
    } else {
        return redirect '/';
    }

};

### Search

get '/search' => sub {

    # FIXME! 
    # This does not take into consideration the library that the user belongs to
    # at all... Should find a better way to do search. ElasticSearch, perhaps? 

    my $q = param 'q';
    
    # Bail out if no search was specified
    if ( $q && $q eq '' ) {
        return template 'search';
    }
    
    # Search for books
    my @books = rset('Book')->search(
        {},
        { order_by => 'title desc' }
    )->search_literal('MATCH ( title, isbn ) AGAINST( ? IN BOOLEAN MODE )', $q );
    my $num_books = @books;
    
    # Search for people
    my @creators = rset('Creator')->search(
        {},
        { order_by => 'name desc' }
    )->search_literal('MATCH ( name ) AGAINST( ? IN BOOLEAN MODE )', $q );
    my $num_creators = @creators;
    
    # If we just got one hit for either book or person then redirect to that
    if ( config->{one_hit_redirect} && $num_books == 1 && $num_creators == 0 ) {
        return redirect '/book/' . $books[0]->id;
    }
    if ( config->{one_hit_redirect} && $num_books == 0 && $num_creators == 1 ) {
        return redirect '/creator/' . $creators[0]->id;
    }
    
    template 'search', {
        books     => \@books,
        creators  => \@creators,
        pagetitle => l('Search'),
    };

};

get '/creator/:id' => sub {
    my $creator_id = param 'id';
    my $creator = rset('Creator')->find( $creator_id );
    template 'creator', { 
        creator   => $creator,
        pagetitle => $creator->name,
    };
};

get '/lists' => sub {
    my @genres = rset('List')->search({ library_id => session('chosen_library'), is_genre => 1 });
    my @lists  = rset('List')->search({ library_id => session('chosen_library'), is_genre => 0 });
    template 'lists', { genres => \@genres, lists => \@lists };
};

get '/list/:id' => sub {
    my $list_id = param 'id';
    my $list = rset('List')->find( $list_id );
    # FIXME List display should be limited the currently chosen library. At the
    # moment we are doing this by looping over all items in the template. This
    # is probably far from ideal, it would be better to do it in here, in the
    # DBIC query. https://github.com/Libriotech/Ebooksforlib/issues/18
    template 'list', { 
        list      => $list,
        pagetitle => $list->name,
    };
};

true;
