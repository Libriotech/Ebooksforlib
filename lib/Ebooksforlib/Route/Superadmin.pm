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
    my @libraries = rset('Library')->all;
    my @consortia = rset('Consortium')->all;
    my @providers = rset('Provider')->all;
    template 'superadmin', { 
        'libraries' => \@libraries,
        'consortia' => \@consortia,
        'providers' => \@providers,
    };
};

get '/superadmin/users' => require_role superadmin => sub { 
    my @users     = rset('User')->all;
    template 'superadmin_users', { 
        'users'     => \@users,
    };
};

true;
