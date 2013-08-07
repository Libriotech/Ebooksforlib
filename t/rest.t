#!/usr/bin/perl

use Test::More;
use Modern::Perl;
use lib 'lib';
 
use Ebooksforlib;
use Dancer::Test;

route_doesnt_exist( [ GET => '/rest' ], "/rest is not handled" );
route_doesnt_exist( [ GET => '/rest/' ], "/rest/ is not handled" );

note( '/rest/libraries' );
route_exists          ( [ GET => '/rest/libraries' ], "/rest/libraries is handled" );
response_status_is    ( [ GET => '/rest/libraries' ], 200, "response ok" );
response_content_like ( [ GET => '/rest/libraries' ], qr/realm.*storevik/, "contains realm = storevik" );
response_content_like ( [ GET => '/rest/libraries' ], qr/realm.*lillevik/, "contains realm = lillevik" );

note( '/rest/whoami' );
route_exists          ( [ GET => '/rest/whoami' ], "/rest/whoami is handled" );
response_status_is    ( [ GET => '/rest/whoami' ], 200, "response ok" );
response_content_like ( [ GET => '/rest/whoami' ], qr/User is not logged in/, "contains User is not logged in" );

note( '/rest/listbooks' );
route_exists          ( [ GET => '/rest/listbooks' ], "/rest/listbooks is handled" );
response_status_is    ( [ GET => '/rest/listbooks' ], 200, "response ok" );
response_content_like ( [ GET => '/rest/listbooks' ], qr/Missing parameter: uid/, "contains Missing parameter: uid" );
response_status_is    ( [ GET => '/rest/listbooks?uid=2' ], 200, "response ok" );
response_content_like ( [ GET => '/rest/listbooks?uid=2' ], qr/Missing parameter: hash/, "contains Missing parameter: hash" );
response_status_is    ( [ GET => '/rest/listbooks?uid=2&hash=abc' ], 200, "response ok" );
response_content_like ( [ GET => '/rest/listbooks?uid=2&hash=abc' ], qr/Missing parameter: pkey/, "contains Missing parameter: pkey" );
response_status_is    ( [ GET => '/rest/listbooks?uid=2&hash=abc&pkey=xyz' ], 200, "response ok" );
response_content_like ( [ GET => '/rest/listbooks?uid=2&hash=abc&pkey=xyz' ], qr/Credentials do not match/, "contains Credentials do not match" );

note( '/rest/getbook' );
route_exists          ( [ GET => '/rest/getbook' ], "/rest/getbook is handled" );
response_status_is    ( [ GET => '/rest/getbook' ], 200, "response ok" );
response_content_like ( [ GET => '/rest/getbook' ], qr/Missing parameter: uid/, "contains Missing parameter: uid" );
response_status_is    ( [ GET => '/rest/getbook?uid=2' ], 200, "response ok" );
response_content_like ( [ GET => '/rest/getbook?uid=2' ], qr/Missing parameter: hash/, "contains Missing parameter: hash" );
response_status_is    ( [ GET => '/rest/getbook?uid=2&hash=abc' ], 200, "response ok" );
response_content_like ( [ GET => '/rest/getbook?uid=2&hash=abc' ], qr/Missing parameter: pkey/, "contains Missing parameter: pkey" );
response_status_is    ( [ GET => '/rest/getbook?uid=2&hash=abc&pkey=xyz' ], 200, "response ok" );
response_content_like ( [ GET => '/rest/getbook?uid=2&hash=abc&pkey=xyz' ], qr/Credentials do not match/, "contains Credentials do not match" );

note( '/rest/removebook' );
route_exists          ( [ GET => '/rest/removebook' ], "/rest/removebook is handled" );
response_status_is    ( [ GET => '/rest/removebook' ], 200, "response ok" );
response_content_like ( [ GET => '/rest/removebook' ], qr/Missing parameter: uid/, "contains Missing parameter: uid" );
response_status_is    ( [ GET => '/rest/removebook?uid=2' ], 200, "response ok" );
response_content_like ( [ GET => '/rest/removebook?uid=2' ], qr/Missing parameter: bookid/, "contains Missing parameter: bookid" );
response_status_is    ( [ GET => '/rest/removebook?uid=2&bookid=5' ], 200, "response ok" );
response_content_like ( [ GET => '/rest/removebook?uid=2&bookid=5' ], qr/Missing parameter: pkey/, "contains Missing parameter: pkey" );
response_status_is    ( [ GET => '/rest/removebook?uid=2&bookid=5&pkey=xyz' ], 200, "response ok" );
note( 'At this stage we have not borrowed anything, so we should expect to get "Book not found"' );
response_content_like ( [ GET => '/rest/removebook?uid=2&bookid=5&pkey=xyz' ], qr/Book not found/, "contains Book not found" );

TODO: {
    route_exists          ( [ GET => '/rest/updatebooklist' ], "/rest/updatebooklist is handled" );
}

note( 'Log in' );
my $response = dancer_response( POST => '/log/in', { params => { username => 'henrik', password => 'pass', realm => 'local' } } );
note( $response->{status} );
note( $response->{content} );
response_content_like ( [ GET => '/rest/whoami' ], qr/User is not logged in/, "contains User is not logged in" );

note( '/rest/ping' );
route_exists          ( [ GET => '/rest/ping' ], "/rest/ping is handled" );

done_testing();
