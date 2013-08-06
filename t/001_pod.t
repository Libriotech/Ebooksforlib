use Test::More;
use Test::Pod;
use Modern::Perl;

my @poddirs = qw( bin lib );
all_pod_files_ok( all_pod_files( @poddirs ) );

done_testing();
