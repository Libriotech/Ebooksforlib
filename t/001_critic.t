use Test::Perl::Critic;

my @dirs = qw( bin lib );

all_critic_ok( @dirs );
