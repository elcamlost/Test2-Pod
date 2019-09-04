#!/usr/bin/env perl
use Test2::V0;
use Test2::API qw/intercept/;
use Test2::Tools::Tester qw/facets/;

use Test2::Pod;

my $file = 't/cut-outside-block.pod';
my $events = intercept {
    pod_file_ok($file);
};

my $assert_facets = facets assert => $events;
is @$assert_facets, 1;
ok !$assert_facets->[0]->pass,  0;
is $assert_facets->[0]->details, "POD test for $file";

my $info = facets info => $events;
is $info->[0]->details, "$file (5): =cut found outside a pod block.  Skipping to next block.";

done_testing;