package Algorithm::ConsistentHash::Ketama;
use strict;
use Algorithm::ConsistentHash::Ketama::Bucket;
use XSLoader;
our $VERSION;

BEGIN {
    $VERSION = '0.00007';
    XSLoader::load( __PACKAGE__, $VERSION );
}

sub new {
    my $class = shift;
    my $self  = $class->xs_create();
    return $self;
}

1;

__END__

=head1 NAME

Algorithm::ConsistentHash::Ketama - Ketama Consistent Hashing for Perl (XS)

=head1 SYNOPSIS

    use Algorithm::ConsistentHash::Ketama;

    my $ketama = Algorithm::ConsistentHash::Ketama->new();

    $ketama->add_bucket( $key1, $weight1 );
    $ketama->add_bucket( $key2, $weight2 );
    $ketama->add_bucket( $key3, $weight3 );
    $ketama->add_bucket( $key4, $weight4 );

    my $key = $ketama->hash( $thing );

=head1 DESCRIPTION

WARNING: Alpha quality code -- and I wrote it for the heck of it, so no
guarantees as of yet. Patches, tests welcome.

This module implements just the libketama algorithm. You can specify a list of
"buckets", and then you can get the corresponding bucket name back when you
hash a string.

=head1 METHODS

=head2 new

Creates a new instance of Algorithm::ConsistentHash::Ketama

=head2 clone

Clones the current object.

=head2 add_bucket( $key, $weight )

Adds a bucket to the list. C<$key> is the name of the bucket, and C<$weight>
denotes the weight of the C<$key>.

=head2 hash( $string )

Returns the corresponding bucket name (which you gave when you did add_bucket).

=head2 remove_bucket( $key )

Removes the given bucket from the list

=head2 buckets()

Returns a list of Algorithm::ConsistentHash::Ketama::Bucket objects

=head1 LICENSE AND COPYRIGHT

Portions of this distribution are derived from libketama, which is:

    Copyright (C) 2007 by                                          
       Christian Muehlhaeuser C<< <chris@last.fm> >>
       Richard Jones C<< <rj@last.fm> >>

Affected portions are licensed under GPL v2.

The rest of the code which is written by Daisuke Maki are available under
Artistic License v2, and is:

    Copyright (C) 2010  Daisuke Maki C<< <daisuke@endeworks.jp> >>

Please see the file xs/Ketama.xs for more detail.

=cut