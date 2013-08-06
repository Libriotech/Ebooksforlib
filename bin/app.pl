#!/usr/bin/perl

use Dancer;
use Ebooksforlib;
use Modern::Perl;

BEGIN {
    use FindBin;

    while ( my $libdir = glob("${FindBin::Bin}/../vendor/*/lib") ) {
        unshift @INC, $libdir;
    }
}

dance;
