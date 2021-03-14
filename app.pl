#!/usr/bin/perl

use v5.23;
use feature ':all';
use warnings;
use utf8;

# Paths, libs and configs
# "DANCER_*" env variables should be set before using Dancer2
use FindBin '$RealBin';
my $root_dir;
BEGIN {
    $root_dir = ($RealBin =~ s:[^\w](bin|t|lib.+)\z::r);
    do "$root_dir/conf/settings.pl";
}
use lib "$root_dir/lib";
use MyENV (
    DANCER_CONFDIR => "$root_dir/conf",
    DANCER_PORT    => Settings::PORT
);

# Command-line options
my %argh;
BEGIN {
    %argh = map { s/^-+//; lc $_, 1 } @ARGV;
    # Global run mode
    ${^RM} = 'Plack'; # Plack by default
    ${^RM} = 'Test'   if (scalar caller(2)); # 0-th level of the stack trace is caused by BEGIN block, but if there is more, then application is run by something else from the outside
    ${^RM} = 'Dancer' if (exists $argh{dance}); # Can be Dancer2
}

use Dancer2; no warnings 'experimental';

use Plack::Builder;
use Dancer2::Plugin::DBIC;

use MyAPI;
use if DEV, MyCMD => ();
use MyModel;
use MySchema;
use MyStorageModel;
use MyWWW;

# Command-line options processing
if (delete $argh{recreate}) {
    unless (delete $argh{yes}) {
        say "Re-creating the database, all data will be lost. Proceed?";
        exit 0 if (lc(getc) ne 'y');
    }

    my $schema = schema;
    $schema->deploy( { add_drop_table => 1 } );
    exit 0 unless (scalar keys %argh);
}

# Load the test data set
if (delete $argh{load}) {
    my $data_dir = "$root_dir/data";

    MyStorageModel::LoadFromCSV($data_dir, schema);

    exit 0 unless (scalar keys %argh);
}

my $app = builder {
    # Some shortcuts to help with development
    if (DEV) {
        mount '/cmd' => MyCMD->to_app;
    }

    mount '/api' => MyAPI->to_app;
    mount '/'    => MyWWW->to_app;
};

# Bare Dancer2 launch
if (${^RM} eq 'Dancer') { dance; exit 0 }

# Launch through Plack runner
if (${^RM} eq 'Plack') {
    @ARGV = (
        '--server'  => Settings::Server,
        '--port'    => Settings::PORT,
        '--workers' => Settings::Workers,
        '-E'        => Settings::E,
        @ARGV
    );

    require Plack::Runner;
    my $runner = Plack::Runner->new;
    $runner->parse_options(@ARGV);
    $runner->run($app);
    exit 0;
}

return $app;
