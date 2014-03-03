package Ebooksforlib::Route::Superadmin;

=head1 Ebooksforlib::Route::Superadmin

Routes for superadmins. 

=cut

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Auth::Extensible;
use Dancer::Exception qw(:all);
use Ebooksforlib::Util;

get '/superadmin' => require_role superadmin => sub { 
    my @users     = rset('User')->all;
    my @libraries = rset('Library')->all;
    my @providers = rset('Provider')->all;
    template 'superadmin', { 
        'users'     => \@users,
        'libraries' => \@libraries,
        'providers' => \@providers,
    };
};

true;
