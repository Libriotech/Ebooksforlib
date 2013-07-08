#!/usr/bin/perl

use Test::More;
use Modern::Perl;
use lib 'lib';
 
use Ebooksforlib;
use Dancer::Test;
 
route_exists                  ( [ GET => '/' ], "front page is handled" );
response_status_is            ( [ GET => '/' ], 302, "front page redirects" );
response_redirect_location_is ( [ GET => '/' ], 'http://localhost/library/set/2?return_url=/', 'redirect to language chooser' );
response_redirect_location_is ( [ GET => '/library/set/2?return_url=/' ], 'http://localhost/', 'redirect to front page' );
response_status_is            ( [ GET => '/' ], 200, "front page is 200 ok" );
response_content_like         ( [ GET => '/' ], qr/Lillevik/, "front page contains Lillevik" );
response_content_like         ( [ GET => '/' ], qr/Du er ikke logget inn/, "front page contains Du er ikke logget inn" );

done_testing();
