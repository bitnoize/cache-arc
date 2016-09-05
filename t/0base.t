use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok("Cache::ARC");
};

my $cache = Cache::ARC->new(
    size => 3,
);

ok ! defined $cache->get('a');

is $cache->set(a => 1), 1;
is $cache->get('a'), 1;

is $cache->set(b => 2), 2;
is $cache->get('a'), 1;
is $cache->get('b'), 2;

is $cache->set(c => 3), 3;
is $cache->get('a'), 1;
is $cache->get('b'), 2;
is $cache->get('c'), 3;

is $cache->set(b => 4), 4;
is $cache->get('a'), 1;
is $cache->get('b'), 4;
is $cache->get('c'), 3;

$cache->clear;
ok ! defined $cache->get('a');
ok ! defined $cache->get('b');
ok ! defined $cache->get('c');

done_testing;
