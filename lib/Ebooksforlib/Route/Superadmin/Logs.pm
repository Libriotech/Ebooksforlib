package Ebooksforlib::Route::Superadmin::Logs;

=head1 Ebooksforlib::Route::Superadmin::Logs

Routes for viewing logs.

=cut

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::FlashMessage;
use Dancer::Exception qw(:all);
use Ebooksforlib::Util;

### Lists

get '/superadmin/logs' => require_role superadmin => sub { 
    
    my @logs  = resultset('Log')->search(
        {  }, 
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
