/*
    Portions of this code are from libketama, which is licensed
    under GPLv2. Namely, the following functions are based on libketama:
        PerlKetama_md5_digest,
        PerlKetama_create_continuum, 
        PerlKetama_hash_string,
        PerlKetama_hash

    All the rest are by Daisuke Maki.
    Portions of the code made by Daisuke Maki are licensed under
    Artistic License v2 (which includes the Perl portion).

    You should also note that MD5 code is based on another person's code,
    too. However, that file does not carry a GPL license
*/
/*
    For all libketama based code (as noted by above)
    Copyright (C) 2007 by                                          
       Christian Muehlhaeuser <chris@last.fm>
       Richard Jones <rj@last.fm>

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; version 2 only.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/

#include "Ketama.h"
#include "KetamaMD5.h"

static void
PerlKetama_md5_digest( char* in, unsigned char md5pword[16] )
{
    md5_state_t md5state;

    md5_init( &md5state );
    md5_append( &md5state, (unsigned char *) in, strlen( in ) );
    md5_finish( &md5state, md5pword );
}


static PerlKetama *
PerlKetama_create(SV *class_sv)
{
    PerlKetama *ketama;

    PERL_UNUSED_VAR(class_sv);

    Newxz( ketama, 1, PerlKetama );
    ketama->numbuckets = 0;
    ketama->numpoints = 0;
    return ketama;
}

static void
PerlKetama_clear_continuum(PerlKetama *ketama)
{
    if (ketama->numpoints > 0) {
        Safefree(ketama->continuum);
        ketama->numpoints = 0;
    }
}

static void
PerlKetama_destroy(PerlKetama *ketama)
{
    PerlKetama_clear_continuum(ketama);

    if (ketama->numbuckets > 0) {
        unsigned int i;
        for(i = 0; i < ketama->numbuckets; i++) {
            Safefree(ketama->buckets[i].label);
        }
        Safefree(ketama->buckets);
    }
    Safefree(ketama);
}

static void
PerlKetama_add_bucket(PerlKetama *p, char *server, int weight)
{
    int len;
    p->numbuckets++;
    p->totalweight += weight;

    Renew( p->buckets, p->numbuckets, PerlKetama_Bucket );

    len = strlen(server);
    Newxz( p->buckets[p->numbuckets - 1].label, len, char );
    Copy(server, p->buckets[p->numbuckets - 1].label, len, char);
    p->buckets[p->numbuckets - 1].weight = weight;

    PerlKetama_clear_continuum( p );
}

static void
PerlKetama_remove_bucket(PerlKetama *p, char *server)
{
    unsigned int i;

    for( i = 0; i < p->numbuckets; i++ ) {
        if ( strEQ(p->buckets[i].label, server) ) {
            for( i += 1; i < p->numbuckets; i++) {
                StructCopy(&(p->buckets[i]), &(p->buckets[i - 1]), PerlKetama_Bucket);
            }
            p->numbuckets--;
            Renew(p->buckets, p->numbuckets, PerlKetama_Bucket);
        }
    }

    PerlKetama_clear_continuum( p );
}

static int
PerlKetama_buckets(PerlKetama *p)
{
    unsigned int i;
    SV *sv;
    dSP;
    PerlKetama_Bucket s;
    SP -= 1; /* must offset for object */

    for(i = 0; i < p->numbuckets; i++) {
        {
            s = p->buckets[i];
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            mXPUSHp( "Algorithm::ConsistentHash::Ketama::Bucket", 41 );
            mXPUSHp( "label", 5 );
            mXPUSHp( s.label, strlen(s.label) );
            mXPUSHp( "weight", 6 );
            mXPUSHi( s.weight );
            PUTBACK;

            call_method("new", G_SCALAR);

            SPAGAIN;
    
            sv = POPs;
            SvREFCNT_inc(sv);

            PUTBACK;
            FREETMPS;
            LEAVE;
        }
        XPUSHs( sv );
    }
    return p->numbuckets;
}

static int
PerlKetama_continuum_compare( PerlKetama_Continuum_Point *a, PerlKetama_Continuum_Point *b )
{
    if (a->point < b->point) return -1;
    if (a->point > b->point) return 1;
    return 0;
}

#define MAX_SS_BUF 8192
static void
PerlKetama_create_continuum( PerlKetama *ketama )
{
    unsigned int i, k, h;
    char ss[MAX_SS_BUF];
    unsigned char digest[16];
    unsigned int continuum_idx = 0;
    PerlKetama_Continuum_Point continuum[ ketama->numbuckets * 160 ];

    for ( i = 0; i < ketama->numbuckets; i++ ) {
        PerlKetama_Bucket *b = ketama->buckets + i;
        float pct = b->weight / (float) ketama->totalweight;
        unsigned int k_limit = floorf(pct * 40.0 * ketama->numbuckets);

        for ( k = 0; k < k_limit; k++ ) {
            /* 40 hashes, 4 numbers per hash = 160 points per bucket */
            if (snprintf(ss, MAX_SS_BUF, "%s-%d", b->label, k) >= MAX_SS_BUF) {
                croak("snprintf() overflow detected for key '%s-%d'. Please use shorter labels", b->label, k);
            }
            PerlKetama_md5_digest(ss, digest);

            for( h = 0; h < 4; h++ ) {
                continuum[ continuum_idx ].point = ( digest[3 + h * 4] << 24 )
                                           | ( digest[2 + h * 4] << 16 )
                                           | ( digest[1 + h * 4] <<  8 )
                                           | ( digest[h * 4] )
                ;
                continuum[ continuum_idx ].bucket = b;
                continuum_idx++;
            }
        }
    }

    qsort( (void *) &continuum, continuum_idx, sizeof(PerlKetama_Continuum_Point), (compfn) PerlKetama_continuum_compare );

    if (ketama->numpoints > 0) {
        Safefree(ketama->continuum);
    }

    ketama->numpoints = continuum_idx;
    Newxz(ketama->continuum, continuum_idx, PerlKetama_Continuum_Point);
    for (i = 0; i < continuum_idx; i++) {
        ketama->continuum[i].bucket = continuum[i].bucket;
        ketama->continuum[i].point = continuum[i].point; 
    }
}

unsigned int
PerlKetama_hash_string( char* in )
{
    unsigned char digest[16];
    unsigned int ret;

    PerlKetama_md5_digest( in, digest );
    ret = ( digest[3] << 24 )
        | ( digest[2] << 16 )
        | ( digest[1] <<  8 )
        |   digest[0];

    return ret;
}

#define PERL_KETAMA_TRACE_LEVEL 0
#if (PERL_KETAMA_TRACE_LEVEL > 0)
#define PERL_KETAMA_TRACE(x) warn(x)
#else
#define PERL_KETAMA_TRACE(x)
#endif
char *
PerlKetama_hash( PerlKetama *ketama, char *thing )
{
    unsigned int h;
    int highp;
    int maxp  = 0,
        lowp  = 0,
        midp  = 0
    ;
    unsigned int midval, midval1;

    if (ketama->numpoints == 0 && ketama->numbuckets > 0) {
        PERL_KETAMA_TRACE("Generating continuum");
        PerlKetama_create_continuum(ketama);
    }

    if (ketama->numpoints == 0) {
        PERL_KETAMA_TRACE("no continuum available");
        return NULL;
    }

    highp = ketama->numpoints;
    maxp  = highp;

    h = PerlKetama_hash_string(thing);
    while ( 1 ) {
        midp = (int)( ( lowp+highp ) / 2 );
        if ( midp == maxp ) {
            if ( midp == ketama->numpoints ) {
                midp = 1;
            }

            return ketama->continuum[midp - 1].bucket->label;
        }
        midval = ketama->continuum[midp].point;
        midval1 = midp == 0 ? 0 : ketama->continuum[midp - 1].point;

        if ( h <= midval && h > midval1 ) {
            return ketama->continuum[midp].bucket->label;
        }

        if ( midval < h )
            lowp = midp + 1;
        else
            highp = midp - 1;

        if ( lowp > highp ) {
            return ketama->continuum[0].bucket->label;
        }
    }

    
}

MODULE = Algorithm::ConsistentHash::Ketama   PACKAGE = Algorithm::ConsistentHash::Ketama  PREFIX=PerlKetama_

PROTOTYPES: DISABLE

PerlKetama *
PerlKetama_create(class_sv)
        SV *class_sv;

void
PerlKetama_destroy(ketama)
        PerlKetama *ketama;
    ALIAS:
        DESTROY = 1

void
PerlKetama_add_bucket(ketama, label, weight)
        PerlKetama *ketama;
        char *label;
        int weight;

void
PerlKetama_remove_bucket(ketama, label)
        PerlKetama *ketama;
        char *label;

void
PerlKetama_buckets(ketama)
        PerlKetama *ketama;
    PPCODE:
        XSRETURN( PerlKetama_buckets(ketama) );

void
PerlKetama_create_continuum(ketama)
        PerlKetama* ketama;

char *
PerlKetama_hash(ketama, thing)
        PerlKetama* ketama;
        char *thing;

