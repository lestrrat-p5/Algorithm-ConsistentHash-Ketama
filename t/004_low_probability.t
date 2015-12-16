use warnings;
use strict;
use Test::More tests => 2;  
use Algorithm::ConsistentHash::Ketama;

my $ketama = Algorithm::ConsistentHash::Ketama->new(); 
$ketama->add_bucket( "node_1", 50 );
$ketama->add_bucket( "node_2", 10000-50 );
my $count;
for(1..1*10000)
{
	my $key = $ketama->hash('tt'.$_);
	$count->{$key}++;
}

ok ( $count->{'node_1'}>10);
ok ( $count->{'node_2'}>10);
