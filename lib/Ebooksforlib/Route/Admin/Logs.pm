package Ebooksforlib::Route::Admin::Logs;

=head1 Ebooksforlib::Route::Admin::Logs

Routes for viewing logs.

=cut

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::FlashMessage;
use Dancer::Exception qw(:all);
use Ebooksforlib::Util;

### Lists

get '/admin/logs' => require_role admin => sub { 
    
    my $library_id = _get_library_for_admin_user();
    
    my @logs  = resultset('Log')->search(
        { library_id => $library_id }, 
        {
            order_by => { -desc => 'time' },
            rows     => 30,
        }
    );
    template 'admin_logs', { 
        logs  => \@logs,
    };
};

true;
