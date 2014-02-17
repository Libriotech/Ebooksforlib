package Ebooksforlib::Route::Comments;

=head1 Ebooksforlib::Route::Comments

Routes for handling comments. Currently not in use. 

=cut

use Dancer ':syntax';
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::FlashMessage;
use Ebooksforlib::Err;

post '/comments/add' => require_login sub {

    my $comment_raw = param 'comment';
    my $book_id     = param 'book_id';
    my $user_id     = session( 'logged_in_user_id' );
    
    # Make sure the user-submitted comment is safe
    my $hs = HTML::Strip->new();
    my $comment_safe = $hs->parse( $comment_raw );
    
    # Save the comment
    try {
        my $new_comment = rset('Comment')->create({
            user_id => $user_id,
            book_id => $book_id,
            comment => $comment_safe,
        });
        flash info => 'Your comment was added!';
    } catch {
        flash error => "Oops, we got an error:<br />".errmsg($_); 
        error "$_";
    };
    
    redirect '/book/' . $book_id;

};

get '/comments/edit/:id' => sub {

    my $comment_id  = param 'id';
    my $user_id     = session( 'logged_in_user_id' );
    
    my $comment = rset('Comment')->find( $comment_id );
    
    # Check that the current user is the author of the comment
    if ( $comment->user_id != $user_id ) {
        flash error => "Are you trying to edit a comment you did not write?";
        return redirect '/book/' . $comment->book->id;
    }
    
    template 'comments_edit', { comment => $comment };

};

post '/comments/edit' => sub {

    my $comment_id  = param 'comment_id';
    my $comment_raw = param 'comment';
    my $user_id     = session( 'logged_in_user_id' );
    
    # Make sure the user-submitted comment is safe
    my $hs = HTML::Strip->new();
    my $comment_safe = $hs->parse( $comment_raw );
    
    my $comment = rset('Comment')->find( $comment_id );
    
    # Check that the current user is the author of the comment
    if ( $comment->user_id != $user_id ) {
        flash error => "Are you trying to edit a comment you did not write?";
    } else {
    
        try {
            $comment->set_column( 'comment', $comment_safe );
            $comment->set_column( 'edited', DateTime->now );
            $comment->update;
            flash info => 'The comment was updated!';
        } catch {
            flash error => "Oops, we got an error:<br />".errmsg($_); 
            error "$_";
        };
        
    }
    redirect '/book/' . $comment->book->id;

};

get '/comments/new' => sub {

    my @comments = rset('Comment')->search( {}, {
      order_by => { -desc => 'id' }, 
      rows     => 10
    } );
    template 'comments_new', { comments => \@comments };

};

true;
