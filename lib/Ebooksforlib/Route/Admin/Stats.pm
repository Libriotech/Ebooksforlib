package Ebooksforlib::Route::Admin::Stats;

=head1 Ebooksforlib::Route::Admin::Stats

Routes for viewing statistics

=cut

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::FlashMessage;
use Dancer::Exception qw(:all);
use Ebooksforlib::Util;

### Lists

get '/admin/stats' => require_role admin => sub { 
    
    my $library_id = _get_library_for_admin_user();
    my $simplestats = _get_simplestats( $library_id );
    template 'admin_stats', { simplestats => $simplestats };
};

true;
