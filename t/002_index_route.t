#!/usr/bin/perl

use Test::More tests => 2;
use Modern::Perl;
use lib 'lib';

# the order is important
use Ebooksforlib;
use Dancer::Test;

route_exists [GET => '/'], 'a route handler is defined for /';
response_status_is ['GET' => '/'], 200, 'response status is 200 for /';
