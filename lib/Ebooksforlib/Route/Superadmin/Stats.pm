package Ebooksforlib::Route::Superadmin::Stats;

=head1 Ebooksforlib::Route::Superadmin::Stats

Routes for viewing stats.

=cut

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::FlashMessage;
use Dancer::Exception qw(:all);
use Ebooksforlib::Util;

### Lists

get '/superadmin/stats/failed' => require_role superadmin => sub { 

    my @failed = resultset('User')->search({
        failed => '> 0',
    });   
    template 'superadmin_stats_failed', { 
        failed => \@failed,
    };
};

true;
