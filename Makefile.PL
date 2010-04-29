use inc::Module::Install;

name 'Algorithm-ConsistentHash-Ketama';
all_from 'lib/Algorithm/ConsistentHash/Ketama.pm';

if (! cc_available()) {
    warn "no compiler available";
    exit 1;
}

test_requires 'Test::More';
test_requires 'Test::Requires';
use_ppport;
cc_warnings;
cc_src_paths 'xs';

WriteAll;