package Ebooksforlib::Route::Admin::Settings;

=head1 Ebooksforlib::Route::Admin::Settings

Routes for changing misc settings

=cut

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::FlashMessage;
use Dancer::Exception qw(:all);
use Ebooksforlib::Util;
use Ebooksforlib::Err;

get '/admin/settings' => require_role admin => sub { 
    my $library = rset('Library')->find( _get_library_for_admin_user() );
    template 'admin_settings', { library => $library };
};

### Concurrent loans

post '/admin/settings/concurrent_loans' => require_role admin => sub { 
    
    my $concurrent_loans = param 'concurrent_loans';
    my $library = rset('Library')->find( _get_library_for_admin_user() );
    try {
        $library->set_column( 'concurrent_loans', $concurrent_loans );
        $library->update;
        flash info => 'The number of concurrent loans was updated!';
    } catch {
        flash error => "Oops, we got an error:<br />".errmsg($_);
        error "$_";
    };
    redirect '/admin/settings';

};

### Detail view

post '/admin/settings/detailview' => require_role admin => sub { 
    my $detail_head = param 'detail_head';
    my $soc_links   = param 'soc_links';
    my $library = rset('Library')->find( _get_library_for_admin_user() );
    try {
        $library->set_column( 'detail_head', $detail_head );
        $library->set_column( 'soc_links', $soc_links );
        $library->update;
        flash info => 'The detail view was updated!';
    } catch {
        flash error => "Oops, we got an error:<br />".errmsg($_);
        error "$_";
    };
    redirect '/admin/settings';
};

true;
