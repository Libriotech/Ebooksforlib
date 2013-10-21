package Ebooksforlib::Util;

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::FlashMessage;
use Dancer::Exception qw(:all);
use HTTP::Lite;
use URL::Encode 'url_encode';
use MIME::Base64 qw(encode_base64);
# use GD;
use Modern::Perl;
use base 'Exporter';

our @EXPORT = qw( 
    _coverurl2base64 
    _sparql2data
    _isbn2bokkliden_cover
    _return_loan
    _user_has_borrowed 
    _get_library_for_admin_user
    _check_password_length
    _check_password_match
    _encrypt_password
    check_hash
    hash_pkey
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
    my $url = config->{'sparql_endpoint'} . '?default-graph-uri=&query=' . url_encode( $sparql ) . '&format=application%2Fsparql-results%2Bjson&timeout=0&debug=on';
    my $http = HTTP::Lite->new;
    my $req = $http->request( $url ) 
        or return { 'error' => "Unable to get document: $!" };
    my $http_body = $http->body();
    
    # Check for possible errors
    if ( $http_body =~ m/DOCTYPE HTML/i ) {
        return;
    } else {
        return JSON::from_json( $http_body );
    }
    
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

sub _return_loan {

    my ( $loan ) = @_;
    
    # Add an old loan
    try {
        my $user_id = 1; # This is the hard coded anonymous user
        debug $loan->item->loan_period;
        debug $loan->user->name;
        if ( $loan->user->anonymize == 0 ) {
            # Use the actual user id of the user that has had the book on loan
            $user_id = $loan->user->id;
        }
        my $old_loan = rset('OldLoan')->create({
            item_id  => $loan->item_id,
            user_id  => $user_id,
            loaned   => $loan->loaned,
            due      => $loan->due,
            returned => DateTime->now( time_zone => setting('time_zone') )
        });
    } catch {
        debug "*** Error when returning item: " . $_;
        return { error => 1, errormsg => $_ };
    };
    
    # TODO Move data from the downloads to the old_downloads table
    
    # Delete the loan
    try {
        $loan->delete;
    } catch {
        debug "*** Error when returning item: " . $_;
        return { error => 1, errormsg => $_ };
    };
    
    return { error => 0 };

}

sub _user_has_borrowed {
    my ( $user, $book ) = @_;
    foreach my $loan ( $user->loans ) {
        if ( $loan->item->file->book->id == $book->id ) {
            return 1;
        } 
    }
}

# Assumes that admin users are only connected to one library
sub _get_library_for_admin_user {
    my $user_id = session 'logged_in_user_id';
    my $user = rset('User')->find( $user_id );
    my @libraries = $user->libraries;
    return $libraries[0]->id;
}

sub _check_password_length {
    my ( $password1 ) = @_;
    if ( length $password1 < config->{min_pass} ) {
        error "*** Password is too short: " . length $password1;
        flash error => 'Passwords is too short! (The minimum is ' . config->{min_pass} . '.)';
        return 0;
    } else {
        return 1;
    }
}

sub _check_password_match {
    my ( $password1, $password2 ) = @_;
    if ( $password1 ne $password2 ) {
        error "*** Passwords do not match";
        flash error => "Passwords do not match!";
        return 0;
    } else {
        return 1;
    }
}

sub _encrypt_password {
    my $password = shift;
    my $csh = Crypt::SaltedHash->new();
    $csh->add( $password );
    return $csh->generate;
}

sub check_hash {
    my ( $user_hash, $hash, $pkey ) = @_;
    if ( md5_hex( $user_hash . $pkey ) eq $hash ) {
        return 1;
    } else {
        return;
    }
}

sub hash_pkey {
    my ( $user_hash, $pkey ) = @_;
    return md5_hex( $user_hash . $pkey );
}

1;
