use strict;
use Test::More;
use threads;
use_ok "Algorithm::ConsistentHash::Ketama";

my $x = Algorithm::ConsistentHash::Ketama->new; 
threads->create(sub{ ok(1) })->join;

ok(1);
done_testing();