package Ebooksforlib::Util;

use Dancer ':syntax';
use HTTP::Lite;
use URL::Encode 'url_encode';
use MIME::Base64 qw(encode_base64);
use GD;
use Modern::Perl;
use base 'Exporter';

our @EXPORT = qw( 
    _coverurl2base64 
    _sparql2data
);

sub _coverurl2base64 {

    my ( $coverurl ) = @_;
    # debug "*** coverurl: $coverurl";
    my $http = HTTP::Lite->new;
    my $req = $http->request( $coverurl ) 
        or die "Unable to get document: $!";
    my @content_type = $http->get_header ( 'Content-Type' );
    return 'data:' . $content_type[0][0] . ';base64,' . encode_base64( $http->body() );

}

sub _sparql2data {

    my ( $sparql ) = @_;
    # debug "*** SPARQL: $sparql";
    my $url = config->{'sparql_endpoint'} . '?default-graph-uri=&query=' . url_encode( $sparql ) . '&format=application%2Fsparql-results%2Bjson&timeout=0&debug=on';
    # debug "*** URL: $url";
    my $http = HTTP::Lite->new;
    my $req = $http->request( $url ) 
        or return { 'error' => "Unable to get document: $!" };
    # debug $http->body();
    my $data = JSON::from_json( $http->body() );
    # debug $data;
    return $data;
    
}

1;
