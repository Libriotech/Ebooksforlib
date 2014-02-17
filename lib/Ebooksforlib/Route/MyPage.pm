package Ebooksforlib::Route::MyPage;

=head1 Ebooksforlib::Route::MyPage

Routes for displaying "My page" and handle anonymization. 

=cut

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::FlashMessage;
use Dancer::Exception qw(:all);
use Ebooksforlib::Util;
use Ebooksforlib::Err;
use Data::Dumper; # FIXME Debug

=head2 /my

Display "My page"

=cut

get '/my' => require_login sub {
    debug '*** Showing My Page for user with id = ' . session('logged_in_user_id');
    my $user = rset( 'User' )->find( session('logged_in_user_id') );
    template 'my', { userdata => logged_in_user, user => $user };
};

=head2 /anon_toggle

Display a warning to the user the she is about to change the setting for anonymization.

=cut

get '/anon_toggle' => require_login sub {
    my $user = rset( 'User' )->find( session('logged_in_user_id') );
    template 'anon_toggle', { user => $user };
};

=head2 /anon_toggle_ok

The user has confirmed that she wants to change the anonymization setting, so 
we do the actual change. 

OR

Confirmation for changing the setting has been turned off, using the "toggle_anon_confirm"
setting. 

=cut

get '/anon_toggle_ok' => require_login sub {
    my $user = rset( 'User' )->find( session('logged_in_user_id') );
    my $new_anonymize = 0;
    if ( $user->anonymize == 0 ) {
        $new_anonymize = 1;
    }
    try {
        $user->set_column( 'anonymize', $new_anonymize );
        $user->update;
        flash info => 'Your anonymization setting was updated!';
        # Log
        _log2db({
            logcode => 'ANONTOGGLE',
            logmsg  => "anonymize = $new_anonymize",
        });
    } catch {
        flash error => localize("Oops, we got an error:<br />").errmsg($_);
        error "$_";
    };
    redirect '/my';
};

=head2 /anon/:id

Ask for confirmation before anonymize a single loan. 

=cut

get '/anon/:id' => require_login sub {
    my $id = param 'id';
    my $oldloan = rset( 'OldLoan' )->find( $id );
    template 'anon', { oldloan => $oldloan };
};

=head2 /anon_ok/:id

Actually anonymize a single loan, after confirmation has been given. 

=cut

get '/anon_ok/:id' => require_login sub {
    my $id = param 'id';
    my $oldloan = rset( 'OldLoan' )->find({ 
        id      => $id,
        user_id => session('logged_in_user_id'),
    });
    if ( $oldloan ) {
        try {
            $oldloan->set_column( 'user_id', 1 );
            $oldloan->update;
            flash info => 'Your loan was anonymized!';
            # Log
            _log2db({
                logcode => 'ANONYMIZE',
                logmsg  => "",
            });
        } catch {
            flash error => "Oops, we got an error:<br />".errmsg($_);
            error "$_";
        };
    } else {
        flash error => "Sorry, could not find the right loan";
        debug "*** item_id = $id, user_id = " . session('logged_in_user_id');
    }
    redirect '/my';
};

=head2 /anon_all

Ask for confirmation before anonymizing all old loans that have not been anonymized already. 

=cut

get '/anon_all' => require_login sub {
    template 'anon_all';
};

=head2 /anon_all_ok

Actually anonymize all old loans, after confirmation has been given. 

=cut

get '/anon_all_ok' => require_login sub {
    my $user = rset( 'User' )->find( session('logged_in_user_id') );
    my $num_anon = 0;
    foreach my $oldloan ( $user->old_loans ) {
        try {
            $oldloan->set_column( 'user_id', 1 );
            $oldloan->update;
            $num_anon++;
        } catch {
            flash error => "Oops, we got an error:<br />".errmsg($_);
            error "$_";
            return redirect '/my';
        };
    } 
    flash info => "Anonymized $num_anon loans!";
    redirect '/my';
};

true;
