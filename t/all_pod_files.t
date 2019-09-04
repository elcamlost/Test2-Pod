#!/usr/bin/env perl
use Test2::V0;
use Test2::Pod;
use File::Spec;

is([all_pod_files( "lib", "t/pod" )], bag {
    item (File::Spec->catfile(qw/lib Test2 Pod.pm/));
    item (File::Spec->catfile(qw/t pod good-pod-script/));
    item (File::Spec->catfile(qw/t pod good-pod-script.bat/));
    item (File::Spec->catfile(qw/t pod good.pod/));
    item (File::Spec->catfile(qw/t pod no_pod.pod/));
    end;
}, 'Got all the distro files');

done_testing;