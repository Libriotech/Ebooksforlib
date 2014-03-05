package Ebooksforlib::Util;

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::FlashMessage;
use Dancer::Exception qw(:all);
use DateTime; 
use DateTime::Format::ISO8601;
use HTTP::Lite;
use URL::Encode 'url_encode';
use MIME::Base64 qw(encode_base64);
use Crypt::SaltedHash;
use Digest::MD5 qw( md5_hex );
use Data::Password::Check;
use Modern::Perl;
use base 'Exporter';

our @EXPORT = qw( 
    _calculate_age
    _munge_zipcode
    _get_simplestats
    _log2db
    _coverurl2base64 
    _get_data_from_isbn
    _sparql2data
    _isbn2bokkliden_cover
    _return_loan
    _user_has_borrowed 
    _get_library_for_admin_user
    _check_password_length
    _check_password_match
    _check_password_content
    _check_csrftoken
    _encrypt_password
    check_hash
    hash_pkey
);

sub _calculate_age {
    # FIXME This returns the exact age in years. It might be better to reduce
    # the age to a range. So if the real age is 50 and we have a range 45-66, 
    # then we return 45. 
    my ( $birthday ) = @_;
    my $now = DateTime->now( time_zone => setting('time_zone') );
    my $bday = DateTime::Format::ISO8601->parse_datetime( $birthday );
    my $diff = $now->subtract_datetime( $bday );
    return $diff->years();
}

# Keep the two first digits, replace the rest with zeros
# FIXME This assumes a 4 digit zipcode, the munging should probably be configurable
sub _munge_zipcode {
    my ( $zip ) = @_;
    # Get the 2 first chars
    my $stub = substr $zip, 0, 2;
    # Pad with zeros
    return $stub . "00";
}

sub _get_simplestats {

    my ( $library_id ) = @_;
    my %stats = (
        'users'    => resultset('UserLibrary')->search({ 'library_id' => $library_id })->count,
        'files'    => resultset('File')->search({        'library_id' => $library_id })->count,
        'items'    => resultset('Item')->search({        'library_id' => $library_id })->count,
        'onloan'   => resultset('Loan')->search({        'library_id' => $library_id })->count,
        'oldloans' => resultset('OldLoan')->search({     'library_id' => $library_id })->count,
    );
    return \%stats;

}

=head2 _log2db

Logs an event to the database. 

Usage:

    _log2db({
        logcode => 'FAILED',
        logmsg  => "Some message",
    });

Logcodes in use:

=over 4

=item * BORROW

=item * LOGIN

=item * LOGINFAIL

=item * LOGOUT

=item * RETURN

=item * RESTDENY

=item * MULTISESSION - A user has more than one active sessions

=back

=cut

sub _log2db {

    my ( $data ) = @_;
    try {
        my $new_logmsg = rset('Log')->create({
            user_id    => session('logged_in_user_id'),
            library_id => session('chosen_library'),
            logcode    => $data->{'logcode'},
            logmsg     => $data->{'logmsg'},
        });
    } catch {
        error "*** Error while logging: $_";
    };

}

sub _coverurl2base64 {

    my ( $coverurl ) = @_;
    # debug "*** coverurl: $coverurl";
    my $http = HTTP::Lite->new;
    my $req = $http->request( $coverurl ) 
        or die "Unable to get document: $!";
    my @content_type = $http->get_header ( 'Content-Type' );
    return 'data:' . $content_type[0][0] . ';base64,' . encode_base64( $http->body() );

}

=head2 _get_data_from_isbn

Takes an Business::ISBN object and queroes a triplestore for data related to it. 

Returns the data as a hasref.

=cut

sub _get_data_from_isbn {

    my ( $isbn ) = @_;
    
    my $sparql = 'SELECT DISTINCT ?graph ?uri ?title ?published ?pages WHERE { GRAPH ?graph {
                      ?uri a <http://purl.org/ontology/bibo/Document> .
                      ?uri <http://purl.org/ontology/bibo/isbn> "' . $isbn->common_data . '" .
                      ?uri <http://purl.org/dc/terms/title> ?title .
                      ?uri <http://purl.org/dc/terms/issued> ?published .
                      ?uri <http://purl.org/ontology/bibo/numPages> ?pages .
                  } }';
    return _sparql2data( $sparql );

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

=head2 _return_loan

Return the given loan. 

Argument: An active loan. 

Creates a copy of the loan in the old_loans table, then deletes the actual 
loan. Old loans are anonymized according to the settings of the user. 

Usage:

    my $item_id = param 'item_id';
    my $user_id = session('logged_in_user_id');
    
    my $loan = rset('Loan')->find({ item_id => $item_id, user_id => $user_id });
    
    my $return = _return_loan( $loan );
    if ( $return->{'error'} == 1 ) {
        # Do something
    } else {
        # Do something else
    }

=cut

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
            item_id    => $loan->item_id,
            user_id    => $user_id,
            library_id => $loan->library_id,
            loaned     => $loan->loaned,
            due        => $loan->due,
            gender     => $loan->gender,
            age        => $loan->age,
            zipcode    => $loan->zipcode,
            returned   => DateTime->now( time_zone => setting('time_zone') )
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
        if ( $loan->item->file && $loan->item->file->book->id == $book->id ) {
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

sub _check_password_content {
    my ( $password ) = @_;
    my $pwcheck = Data::Password::Check->check({
        'password'           => $password,
        'tests'              => [ qw( diverse_characters ) ],
        'diversity_required' => 4,
    });
    return $pwcheck;
}

=head2 _check_csrftoken

Takes a csrftoken as input and compares it to the csrftoken of the currently 
logged in user. 

Returns 1 if the token is OK. 

If the token is not OK, the user will be logged out (by a call to 
session->destroy), and 0 will be returned. 

=cut

sub _check_csrftoken {

    my ( $token ) = @_;
    
    # Check for undef and empty token
    if ( !$token || $token eq '' ) {
        # Logging
        _log2db({
            logcode => 'CSRFFAIL',
            logmsg  => 'CSRF token was undef or empty. User: ' . session('logged_in_user_id'),
        });
        error 'CSRF token was undef or empty. User: ' . session('logged_in_user_id');
        # Log out the user
        session->destroy;
        return 0;
    }
    
    if ( $token eq session('csrftoken') ) {
        return 1;
    } else {
        # Logging
        _log2db({
            logcode => 'CSRFFAIL',
            logmsg  => 'CSRF tokens did not match. User: ' . session('logged_in_user_id'),
        });
        error 'CSRF tokens did not match. User: ' . session('logged_in_user_id') . ". Token from form: $token. Token from session: " . session('csrftoken');
        # Log out the user
        session->destroy;
        return 0;
    }

}

sub _encrypt_password {
    my $password = shift;
    my $csh = Crypt::SaltedHash->new( 'algorithm' => 'SHA-512' );
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
