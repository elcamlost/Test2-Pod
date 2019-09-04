#!/usr/bin/env perl
use Test2::V0;
use Test2::API qw/intercept/;
use Test2::Tools::Tester qw/facets/;

use Test2::Pod;

my $file = 't/non-existent.pod';
my $events = intercept {
    pod_file_ok($file, 'I hope the file is there');
    pod_file_ok($file);
};

my $assert_facets = facets assert => $events;
is @$assert_facets, 2;
ok !$assert_facets->[0]->pass;
is $assert_facets->[0]->details, 'I hope the file is there';
ok !$assert_facets->[1]->pass;

my $info_facets = facets info => $events;
is @$info_facets, 2;
is $info_facets->[0]->details, "$file does not exist";
is $info_facets->[1]->details, "$file does not exist";

done_testing;
