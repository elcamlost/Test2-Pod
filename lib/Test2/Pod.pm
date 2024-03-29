package Test2::Pod;
use strict;
use warnings;

=head1 NAME

Test2::Pod - Check for POD errors in files with L<Test2::Suite>

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

C<Test2::Pod> lets you check the validity of a POD file, and report
its results in standard C<Test::Simple> fashion.

    use Test2::Pod;
    pod_file_ok( $file, "Valid POD file" );

Module authors can include the following in a F<t/pod.t> file and
have C<Test2::Pod> automatically find and check all POD files in a
module distribution:

    use Test2::V0;
    use Test2::Require::Module 'Test2::Pod';

    use Test2::Pod;
    all_pod_files_ok();

You can also specify a list of files to check, using the
C<all_pod_files()> function supplied:

    use Test2::V0;
    use Test2::Require::Module 'Test2::Pod';

    my @poddirs = qw( blib script );
    all_pod_files_ok( all_pod_files( @poddirs ) );

Or even (if you're running under L<Apache::Test>):

    use Test2::V0;
    use Test2::Require::Module 'Test2::Pod';

    use Test2::Pod;
    my @poddirs = qw( blib script );
    use File::Spec::Functions qw( catdir updir );
    all_pod_files_ok(
        all_pod_files( map { catdir updir, $_ } @poddirs )
    );

=head1 DESCRIPTION

Check POD files for errors or warnings in a test file, using
C<Pod::Simple> to do the heavy lifting.

=cut

use Test2::API qw/context context_do/;
use Pod::Simple;

our %ignore_dirs = (
    '.bzr' => 'Bazaar',
    '.git' => 'Git',
    '.hg'  => 'Mercurial',
    '.pc'  => 'quilt',
    '.svn' => 'Subversion',
    CVS    => 'CVS',
    RCS    => 'RCS',
    SCCS   => 'SCCS',
    _darcs => 'darcs',
    _sgbak => 'Vault/Fortress',
);

our @EXPORT = qw/pod_file_ok all_pod_files all_pod_files_ok/;
use base 'Exporter';

sub _additional_test_pod_specific_checks {
    my ($ok) = @_;
    return $ok;
}

=head1 FUNCTIONS

=head2 pod_file_ok( FILENAME[, TESTNAME ] )

C<pod_file_ok()> will okay the test if the POD parses correctly.  Certain
conditions are not reported yet, such as a file with no pod in it at all.

When it fails, C<pod_file_ok()> will show any pod checking errors as
diagnostics.

The optional second argument TESTNAME is the name of the test.  If it
is omitted, C<pod_file_ok()> chooses a default test name "POD test
for FILENAME".

=cut

sub pod_file_ok {
    my $file = shift;
    my $name = @_ ? shift : "POD test for $file";
    my $ctx = context;

    if ( !-f $file ) {
        $ctx->fail_and_release($name, "$file does not exist");
        return;
    }

    my $checker = Pod::Simple->new;
    my $ok;
    context_do {
        $checker->output_string(\my $trash); # Ignore any output
        $checker->parse_file($file);

        $ok = !$checker->any_errata_seen;
        $ok = _additional_test_pod_specific_checks($ok, ($checker->{errata}||={}), $file);

        $name .= ' (no pod)' if !$checker->content_seen;
        if ($ok) {
            $ctx->pass($name);
        }
        else {
            my $lines = $checker->{errata};
            my @diag;
            for my $line ( sort { $a<=>$b } keys %$lines ) {
                my $errors = $lines->{$line};
                push @diag, "$file ($line): $_" for @$errors;
            }
            $ctx->fail($name, @diag);
        }
        $ctx->release;
    };
    return $ok;
} # pod_file_ok

=head2 all_pod_files_ok( [@entries] )

Checks all the files under C<@entries> for valid POD. It runs
L<all_pod_files()> on directories and assumes everything else to be a file to
be tested. It calls the C<plan()> function for you (one test for each file),
so you can't have already called C<plan>.

If C<@entries> is empty or not passed, the function finds all POD files in
files in the F<blib> directory if it exists, or the F<lib> directory if not.
A POD file matches the conditions specified below in L</all_pod_files>.

If you're testing a module, just make a F<t/pod.t>:

    use Test2::V0;
    use Test2::Require::Module 'Test2::Pod';

    use Test2::Pod;
    all_pod_files_ok();

Returns true if all pod files are ok, or false if any fail.

=cut

sub all_pod_files_ok {
    my @args = @_ ? @_ : _starting_points();
    my @files = map { -d $_ ? all_pod_files($_) : $_ } @args;
    my $ctx = context;

    unless (@files) {
        $ctx->plan(0, SKIP => "No files found in (@args)\n");
        $ctx->release;
        return 1;
    }

    $ctx->plan(scalar @files);

    my $ok = 1;
    foreach my $file (@files) {
        pod_file_ok($file) or undef $ok;
    }
    $ctx->release;
    return $ok;
}

=head2 all_pod_files( [@dirs] )
X<all_pod_files>

Returns a list of all the POD files in I<@dirs> and in directories below. If
no directories are passed, it defaults to F<blib> if F<blib> exists, or else
F<lib> if not. Skips any files in F<CVS>, F<.svn>, F<.git> and similar
directories. See C<%Test2::Pod::ignore_dirs> for a list of them.

A POD file is:

=over 4

=item * Any file that ends in F<.pl>, F<.PL>, F<.pm>, F<.pod>, F<.psgi> or F<.t>.

=item * Any file that has a first line with a shebang and "perl" on it.

=item * Any file that ends in F<.bat> and has a first line with "--*-Perl-*--" on it.

=back

The order of the files returned is machine-dependent.  If you want them
sorted, you'll have to sort them yourself.

=cut

sub all_pod_files {
    my @pod;
    require File::Find;
    File::Find::find({
        preprocess => sub { grep {
            !exists $ignore_dirs{$_}
            || !-d File::Spec->catfile($File::Find::dir, $_)
        } @_ },
        wanted   => sub { -f $_ && _is_perl($_) && push @pod, $File::Find::name },
        no_chdir => 1,
    }, @_ ? @_ : _starting_points());
    return @pod;
}

sub _starting_points {
    return 'blib' if -e 'blib';
    return 'lib';
}

sub _is_perl {
    my $file = shift;

    # accept as a Perl file everything that ends with a well known Perl suffix ...
    return 1 if $file =~ /[.](?:PL|p(?:[lm]|od|sgi)|t)$/;

    open my $fh, '<', $file or return;
    my $first = <$fh>;
    close $fh;
    return unless $first;

    # ... or that has a she-bang as first line ...
    return 1 if $first =~ /^#!.*perl/;

    # ... or that is a .bat ad has a Perl comment line first
    return 1 if $file =~ /[.]bat$/i && $first =~ /--[*]-Perl-[*]--/;

    return;
}

=head1 SUPPORT

This module is managed in an open L<GitHub
repository|https://github.com/elcamlost/Test2-Pod/>. Feel free to fork and
contribute, or to clone L<git://github.com/elcamlost/Test2-Pod.git> and send
patches!

Found a bug? Please L<post|https://github.com/elcamlost/Test2-Pod/issues>.

=head1 AUTHORS

=over

=item David E. Wheeler <david@justatheory.com>

Current maintainer of Test::Pod.

=item Andy Lester C<< <andy at petdance.com> >>

Maintainer emeritus.

=item brian d foy

Original author.

=back

=head1 ACKNOWLEDGEMENTS

Thanks brian d foy for the original code, and to these folks for contributions:

=over

=item * Andy Lester

=item * David E. Wheeler

=item * Paul Miller

=item * Peter Edwards

=item * Luca Ferrari

=item * Ilya Rassadin

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2010, Andy Lester; 2010-2015 David E. Wheeler. Some Rights
Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
