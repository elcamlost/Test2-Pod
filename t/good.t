#!/usr/bin/env perl
use Test2::V0;
use Test2::API qw/intercept/;
use Test2::Tools::Tester qw/facets/;

use Test2::Pod;

my $filename = 't/pod/good.pod';
my $events   = intercept {
    pod_file_ok( $filename, 'Blargo!' );
    pod_file_ok($filename);
};

my $assert_facets = facets assert => $events;
is @$assert_facets, 2;
ok $assert_facets->[0]->pass,    0;
is $assert_facets->[0]->details, 'Blargo!';
ok $assert_facets->[1]->pass,    0;
is $assert_facets->[1]->details, "POD test for $filename", 'Handles good.pod OK, and builds default name OK';

done_testing;
