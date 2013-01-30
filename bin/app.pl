#!/usr/bin/env perl
use Dancer;
use Ebooksforlib;

BEGIN {
    use FindBin;

    while ( my $libdir = glob("${FindBin::Bin}/../vendor/*/lib") ) {
        unshift @INC, $libdir;
    }
}

dance;
