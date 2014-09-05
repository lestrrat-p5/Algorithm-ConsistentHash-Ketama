use strict;
use Test::More;

use Algorithm::ConsistentHash::Ketama;

my $ketama = Algorithm::ConsistentHash::Ketama->new();
$ketama->add_bucket( "r01", 100 );
$ketama->add_bucket( "r02", 100 );
my $key = $ketama->hash( pack "H*", "161c6d14dae73a874ac0aa0017fb8340" );
ok $key;

done_testing;