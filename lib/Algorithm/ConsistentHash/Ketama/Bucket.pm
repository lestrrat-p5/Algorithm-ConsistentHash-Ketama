package Algorithm::ConsistentHash::Ketama::Bucket;
use strict;

sub new {
    my ($class, %args) = @_;
    my $self = bless {%args}, $class;
    return $self;
}

sub label { $_[0]->{label} }
sub weight { $_[0]->{weight} }

1;