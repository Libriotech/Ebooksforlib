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

    my @today = resultset('Log')->search(
        \[ 'DATE(time) = DATE(NOW())' ],
        {
            '+select'   => [ { count => '*' } ],
            '+as'       => [ 'count' ],
            'group_by'  => [ 'logcode' ],
        }
    );   
    my @recent  = resultset('Log')->search(
        {  }, 
        {
            order_by => { -desc => 'time' },
            rows     => 30,
        }
    );
    template 'superadmin_logs', { 
        today  => \@today,
        recent => \@recent,
    };
};

true;
