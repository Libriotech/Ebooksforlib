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
use Ebooksforlib::Err;

## Connections between consortia and libraries

get '/consortia/libraries/:id' => require_role superadmin => sub { 
    
    my $id = param 'id';
    my $consortium = rset('Library')->find( $id );
    my @libraries = rset('Library')->search({ is_consortium => 0 });
    template 'consortia_libraries', { consortium => $consortium, libraries => \@libraries };
    
};

get '/consortia/libraries/add/:consortium_id/:library_id' => require_role superadmin => sub { 
    
    unless ( _check_csrftoken( param 'csrftoken' ) ) {
        return redirect '/';
    }
    
    my $consortium_id    = param 'consortium_id';
    my $library_id = param 'library_id';
    try {
        rset('Consortium')->create({
            consortium_id => $consortium_id,
            library_id    => $library_id,
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
    my $connection = rset('Consortium')->find({ consortium_id => $consortium_id, library_id => $library_id });
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
