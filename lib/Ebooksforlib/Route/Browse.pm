package Ebooksforlib::Route::Browse;

=head1 Ebooksforlib::Route::Browse

Routes for finding books, including search, lists, detail view etc. 

=cut

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::FlashMessage;
use Dancer::Exception qw(:all);
use Ebooksforlib::Util;

get '/' => sub {

    my @booklists;

    # Find all the lists for this library, that should be shown on the front page
    my @lists = rset('List')->search({
        'library_id' => session('chosen_library'),
        'frontpage'  => 1,
    }, {
        'order_by' => 'frontpage_order',
    });
    # Get the ListBook's for each list
    # FIXME Why do I do this? Can't I get the books from the lists themselves?!? 
    foreach my $list ( @lists ) {
        my @booklist = rset('ListBook')->search({ list_id => $list->id });
        push @booklists, { booklist => \@booklist, list => $list };
    }
        
    my @mobile = rset('List')->search({
        'library_id' => session('chosen_library'),
        'mobile'     => 1,
    });
    my @mobilebooklist;
    if ( $mobile[0] ) {
        @mobilebooklist = rset('ListBook')->search({ list_id => $mobile[0]->id });
    }
    
    var hide_dropdowns => 1;    
    template 'index', { 
        booklists      => \@booklists, 
        mobilebooklist => \@mobilebooklist, 
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
        if ( $user->number_of_loans_from_library( $library->id ) == $library->concurrent_loans ) {
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

### "Static" pages

get '/page/:slug' => sub {

    my $slug = param 'slug';
    
    # Allowed pages
    my @pages = qw( help help2 help3 help4 help5 newuser about contact info );
    # FIXME Apparently, ~~ is deprecated as of Perl 5.18 so replacing it here 
    # would be a good idea
    if ( /$slug/i ~~ @pages ) {
        template 'page', { slug => "page_$slug.tt" };
    } else {
        return redirect '/';
    }

};

### Search

get '/search' => sub {

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
    template 'list', { 
        list      => $list,
        pagetitle => $list->name,
    };
};

true;
