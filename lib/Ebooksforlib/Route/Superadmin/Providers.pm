package Ebooksforlib::Route::Superadmin::Providers;

=head1 Ebooksforlib::Route::Superadmin::Providers

Routes for handling providers. 

=cut

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::FlashMessage;
use Dancer::Exception qw(:all);
use Ebooksforlib::Util;

get '/providers/add' => require_role superadmin => sub {
    template 'providers_add';
};

post '/providers/add' => require_role superadmin => sub {

    my $name        = param 'name';
    my $description = param 'description';
    my $hs = HTML::Strip->new();
    $name  = $hs->parse( $name );
    $description = $hs->parse( $description );
    $hs->eof;
    try {
        my $new_provider = rset('Provider')->create({
            name        => $name,
            description => $description,
        });
        flash info => 'A new provider was added!';
        redirect '/superadmin';
    } catch {
        flash error => "Oops, we got an error:<br />".errmsg($_);
        error "$_";
        redirect '/superadmin';
    };

};

get '/providers/edit/:id' => require_role superadmin => sub {
    my $id = param 'id';
    my $provider = rset('Provider')->find( $id );
    template 'providers_edit', { provider => $provider };
};

post '/providers/edit' => require_role superadmin => sub {

    my $id = param 'id';
    my $name = param 'name';
    my $description = param 'description';
    my $hs = HTML::Strip->new();
    $name  = $hs->parse( $name );
    $description = $hs->parse( $description );
    $hs->eof;
    my $provider = rset('Provider')->find( $id );
    try {
        $provider->set_column( 'name', $name );
        $provider->set_column( 'description', $description );
        $provider->update;
        flash info => 'A provider was updated!';
        redirect '/superadmin';
    } catch {
        flash error => "Oops, we got an error:<br />".errmsg($_);
        error "$_";
        redirect '/superadmin';
    };

};

get '/providers/delete/:id' => require_role superadmin => sub {
    my $id = param 'id';
    my $provider = rset('Provider')->find( $id );
    template 'providers_delete', { provider => $provider };
};

get '/providers/delete_ok/:id?' => require_role superadmin => sub { 
    
    my $id = param 'id';
    my $provider = rset('Provider')->find( $id );
    # Check that this provider has no items
    my $num_items = rset('Item')->search({ provider_id => $id })->count;
    debug "*** Number of items: $num_items";
    if ( $num_items > 0 ) {
        flash error => "Sorry, that provider still has $num_items items attached!";
        return redirect '/superadmin';
    }
    try {
        $provider->delete;
        flash info => 'A provider was deleted!';
        info "Deleted provider with ID = $id";
        redirect '/superadmin';
    } catch {
        flash error => "Oops, we got an error:<br />".errmsg($_);
        error "$_";
        redirect '/superadmin';
    };
    
};

true;
