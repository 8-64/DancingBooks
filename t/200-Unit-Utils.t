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

use MyUtil;

ok(MyUtil::CountryToEmoji('US') eq '&#x1f1fa;&#x1f1f8;', 'Country code translated into emoji as expected');

done_testing();
