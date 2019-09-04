#!/usr/bin/env perl
use Test2::Pod;
use Test2::V0;

my $self = $INC{'Test2/Pod.pm'};
pod_file_ok($self, "My own pod is OK");

done_testing;