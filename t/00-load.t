#!/usr/bin/env perl
use Test2::V0 -target => 'Test2::Pod';

ok CLASS(), 'Test2::Pod';
ok !!(eval { require Pod::Simple; 1 }), 'Pod::Simple is loaded';


diag( "Testing Test2::Pod $Test2::Pod::VERSION, Perl $], $^X" );
diag( "Using Pod::Simple $Pod::Simple::VERSION" );

done_testing;