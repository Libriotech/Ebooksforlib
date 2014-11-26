package Ebooksforlib::Route::Superadmin::Pages;

=head1 Ebooksforlib::Route::Superadmin::Pages

Routes for dealing with pages.

=cut

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::FlashMessage;
use Dancer::Exception qw(:all);
use Ebooksforlib::Util;

### Lists

get '/superadmin/page/edit/:slug' => require_role superadmin => sub { 

    my $slug = param 'slug';

    my $page = resultset('Page')->find( $slug );
    template 'superadmin_pages_edit', {
        'slug' => $slug,
        'page' => $page,
    };

};

post '/superadmin/page/save' => require_role superadmin => sub { 

    unless ( _check_csrftoken( param 'csrftoken' ) ) {
        return redirect '/';
    }

    my $slug  = param 'slug';
    my $title = param 'title';
    my $text  = param 'text';

    my $page = resultset('Page')->find( $slug );
    my $user = resultset('User')->find( session('logged_in_user_id') );
    try {
        $page->set_column( 'title', $title );
        $page->set_column( 'text',  $text );
        $page->set_column( 'last_editor', $user->name );
        $page->update;
        flash info => 'A page was updated!';
        _log2db({
            logcode => 'EDITPAGE',
            logmsg  => "slug: $slug, editor: " . $user->name,
        });
        redirect '/page/' . $slug;
    } catch {
        flash error => "Oops, we got an error:<br />".errmsg($_);
        error "$_";
        redirect '/';
    };

};

true;
