package Ebooksforlib::Route::Superadmin::Consortia;

=head1 Ebooksforlib::Route::Superadmin::Consortia

Routes for handling consortia. 

=cut

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::FlashMessage;
use Dancer::Exception qw(:all);
use Ebooksforlib::Util;

get '/consortia/add' => require_role superadmin => sub { 
    template 'consortia_add';
};

post '/consortia/add' => require_role superadmin => sub {

    unless ( _check_csrftoken( param 'csrftoken' ) ) {
        return redirect '/';
    }

    my $name = param 'name';
    try {
        my $hs = HTML::Strip->new();
        $name  = $hs->parse( $name );
        $hs->eof;
        my $new_consortium = rset('Consortium')->create({
            name  => $name,
        });
        flash info => 'A new consortium was added!';
        redirect '/superadmin';
    } catch {
        flash error => "Oops, we got an error:<br />".errmsg($_);
        error "$_";
        template 'consortia_add', { name => $name };
    };

};

get '/consortia/edit/:id' => require_role superadmin => sub {

    my $id = param 'id';
    my $consortium = rset('Consortium')->find( $id );
    template 'consortia_edit', { consortium => $consortium };

};

post '/consortia/edit' => require_role superadmin => sub {

    unless ( _check_csrftoken( param 'csrftoken' ) ) {
        return redirect '/';
    }

    my $id    = param 'id';
    my $name  = param 'name';
    my $consortium = rset('Consortium')->find( $id );
    try {
        my $hs = HTML::Strip->new();
        $name  = $hs->parse( $name );
        $hs->eof;
        $consortium->set_column('name',  $name  );
        $consortium->update;
        flash info => 'A consortium was updated!';
        redirect '/superadmin';
    } catch {
        flash error => "Oops, we got an error:<br />".errmsg($_);
        error "$_";
        template 'consortia_edit', { consortium => $consortium };
    };

};

get '/consortia/delete/:id?' => require_role superadmin => sub { 
    
    # Confirm delete
    my $id = param 'id';
    my $consortium = rset('Consortium')->find( $id );
    template 'consortia_delete', { consortium => $consortium };
    
};

get '/consortia/delete_ok/:id?' => require_role superadmin => sub { 

    unless ( _check_csrftoken( param 'csrftoken' ) ) {
        return redirect '/';
    }

    # Do the actual delete
    my $id = param 'id';
    my $consortium = rset('Consortium')->find( $id );
    try {
        $consortium->delete;
        flash info => 'A consortium was deleted!';
        info "Deleted consortium with ID = $id";
        redirect '/superadmin';
    } catch {
        flash error => "Oops, we got an error:<br />".errmsg($_);
        error "$_";
        redirect '/superadmin';
    };
    
};

## Connections between consortia and libraries

get '/consortia/libraries/:id' => require_role superadmin => sub { 
    
    my $id = param 'id';
    my $consortium = rset('Consortium')->find( $id );
    my @libraries = rset('Library')->all;
    template 'consortia_libraries', { consortium => $consortium, libraries => \@libraries };
    
};

get '/consortia/libraries/add/:consortium_id/:library_id' => require_role superadmin => sub { 
    
    unless ( _check_csrftoken( param 'csrftoken' ) ) {
        return redirect '/';
    }
    
    my $consortium_id    = param 'consortium_id';
    my $library_id = param 'library_id';
    try {
        rset('ConsortiumLibrary')->create({
            consortium_id    => $consortium_id, 
            library_id => $library_id, 
        });
        flash info => 'A new library was connected!';
        redirect '/consortia/libraries/' . $consortium_id;
    } catch {
        flash error => "Oops, we got an error:<br />".errmsg($_);
        error "$_";
        redirect '/consortia/libraries/' . $consortium_id;
    };    
};

get '/consortia/libraries/delete/:consortium_id/:library_id' => require_role superadmin => sub { 
    
    unless ( _check_csrftoken( param 'csrftoken' ) ) {
        return redirect '/';
    }
    
    my $consortium_id    = param 'consortium_id';
    my $library_id = param 'library_id';
    my $connection = rset('ConsortiumLibrary')->find({ consortium_id => $consortium_id, library_id => $library_id });
    try {
        $connection->delete;
        flash info => 'A connection was deleted!';
        redirect '/consortia/libraries/' . $consortium_id;
    } catch {
        flash error => "Oops, we got an error:<br />".errmsg($_);
        error "$_";
        redirect '/consortia/libraries/' . $consortium_id;
    };
    
};

true;
