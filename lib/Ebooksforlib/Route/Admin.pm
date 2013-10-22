package Ebooksforlib::Route::Admin;

=head1 Ebooksforlib::Route::Admin

Routes for admins. 

=cut

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::FlashMessage;
use Dancer::Exception qw(:all);
use Ebooksforlib::Util;

get '/admin' => require_role admin => sub { 
    my $library = rset('Library')->find( _get_library_for_admin_user() );
    my @lists = rset('List')->search({ library_id => _get_library_for_admin_user() });
    template 'admin', { library => $library, lists => \@lists };
};

true;
