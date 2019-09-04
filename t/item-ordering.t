#!/usr/bin/env perl
use Test2::V0;
use Test2::API qw/intercept/;
use Test2::Tools::Tester qw/facets/;

use Test2::Pod;

my $file = 't/item-ordering.pod';
my $events = intercept {
    pod_file_ok($file);
};
my $assert_facets = facets assert => $events;
is @$assert_facets, 1;
ok !$assert_facets->[0]->pass;
is $assert_facets->[0]->details, "POD test for $file";

my @diag = ( Pod::Simple->VERSION == 3.24 ? (
    "$file (17): Expected text matching /\\s+[^\\*\\d]/ after '=item'",
    "$file (21): Expected text matching /\\s+[^\\*\\d]/ after '=item'",
    "$file (32): You can't have =items (as at line 36) unless the first thing after the =over is an =item",
) : Pod::Simple->VERSION >= 3.27 ? (
    "$file (17): Expected text after =item, not a number",
    "$file (21): Expected text after =item, not a number",
    "$file (32): You can't have =items (as at line 36) unless the first thing after the =over is an =item",
    "$file (32): =over without closing =back",
) : Pod::Simple->VERSION >= 3.25 ? (
    "$file (17): Expected text after =item, not a number",
    "$file (21): Expected text after =item, not a number",
    "$file (32): You can't have =items (as at line 36) unless the first thing after the =over is an =item",
) : (
    "$file (32): You can't have =items (as at line 36) unless the first thing after the =over is an =item",
));
my $info_assets = facets info => $events;
is [map {$_->details} @$info_assets], \@diag, 'file is bad';

done_testing;