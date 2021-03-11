#!/usr/bin/perl

use v5.23;
use feature ':all';
use warnings; no warnings 'experimental';
use utf8;

use FindBin qw[$RealBin];
my $root_dir;
BEGIN {
    $root_dir = ($RealBin =~ s:[^\w](bin|t|lib.+)\z::r);
}
use lib "$root_dir/lib";

use Test::More;
use Test::Pod;

# All module names from the root of lib dir
my @modules = sort map { s/\.pm\Z//; substr($_, rindex($_, '/') + 1) } glob("$root_dir/lib/*.pm");

plan tests => scalar(@modules) * 4;

foreach my $module (@modules) {
    use_ok($module);

    my $file = "$module.pm";
    $file =~ s[::][/]g;
    Test::Pod::pod_file_ok($INC{$file});

    is(ref(\eval $module->VERSION()), 'VSTRING', "[$module] has a version set");

    like(qx[$^X -I${root_dir}/lib -MO=Lint ${root_dir}/lib/${file} 2>&1], qr/syntax\s+ok/ims, "[$module] syntaxis check");
}

done_testing();
