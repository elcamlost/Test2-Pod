#!/usr/bin/env perl
use Test2::V0;
use Test2::API qw/intercept/;
use Test2::Tools::Tester qw/facets/;

use Test2::Pod;

my $name = 'Test name: Something not likely to accidentally occur!';
my $file = 't/unknown-directive.pod';
my $events = intercept {
    pod_file_ok($file, 'Test name: Something not likely to accidentally occur!');
};

my $assert_facets = facets assert => $events;
is @$assert_facets, 1;
ok !$assert_facets->[0]->pass;
is $assert_facets->[0]->details, 'Test name: Something not likely to accidentally occur!';

my $info_facets = facets info => $events;
is @$info_facets, 2;
is $info_facets->[0]->details, "$file (9): Unknown directive: =over4";
is $info_facets->[1]->details, "$file (13): Unknown directive: =under";

done_testing;