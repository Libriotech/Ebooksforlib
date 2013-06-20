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
    _isbn2bokkliden_cover
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

sub _isbn2bokkliden_cover {

    my ( $isbn ) = @_;
    my $url = "http://partner.bokkilden.no/SamboWeb/partner.do?rom=MP&format=XML&uttrekk=5&pid=0&ept=3&xslId=117&antall=3&sok=$isbn&profil=partner&order=DESC&side=0";
    my $http = HTTP::Lite->new;
    my $req = $http->request( $url ) 
        or return { 'error' => "Unable to get document: $!" };
    my $xml = $http->body();
    debug $xml;
    $xml =~ m/<BildeURL>(.*?)<\/BildeURL>/ig;
    my $imgurl = $1;
    $imgurl =~ s/&amp;width.*$//ig;
    debug $imgurl;
    return $imgurl;

}

1;
