#!/usr/bin/perl

use Test::More;
use Modern::Perl;
use lib 'lib';

BEGIN { use_ok( 'Ebooksforlib' ); }
BEGIN { use_ok( 'Ebooksforlib::Util' ); }
BEGIN { use_ok( 'Ebooksforlib::Schema' ); }

BEGIN { use_ok( 'Ebooksforlib::Schema::Result::BookCreator' ); }
BEGIN { use_ok( 'Ebooksforlib::Schema::Result::Book' ); }
BEGIN { use_ok( 'Ebooksforlib::Schema::Result::Comment' ); }
BEGIN { use_ok( 'Ebooksforlib::Schema::Result::Creator' ); }
BEGIN { use_ok( 'Ebooksforlib::Schema::Result::File' ); }
BEGIN { use_ok( 'Ebooksforlib::Schema::Result::Item' ); }
BEGIN { use_ok( 'Ebooksforlib::Schema::Result::Library' ); }
BEGIN { use_ok( 'Ebooksforlib::Schema::Result::ListBook' ); }
BEGIN { use_ok( 'Ebooksforlib::Schema::Result::List' ); }
BEGIN { use_ok( 'Ebooksforlib::Schema::Result::Loan' ); }
BEGIN { use_ok( 'Ebooksforlib::Schema::Result::OldLoan' ); }
BEGIN { use_ok( 'Ebooksforlib::Schema::Result::Provider' ); }
BEGIN { use_ok( 'Ebooksforlib::Schema::Result::Rating' ); }
BEGIN { use_ok( 'Ebooksforlib::Schema::Result::Role' ); }
BEGIN { use_ok( 'Ebooksforlib::Schema::Result::UserLibrary' ); }
BEGIN { use_ok( 'Ebooksforlib::Schema::Result::User' ); }
BEGIN { use_ok( 'Ebooksforlib::Schema::Result::UserRole' ); }

done_testing();
