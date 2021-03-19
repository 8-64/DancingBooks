#!/usr/bin/perl
package main v0.2.0;

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
    ${^RM} = 'Dancer' if (exists $argh{dance}); # Can be Dancer2
    if (scalar caller(2)) { # 0-th level of the stack trace is caused by BEGIN
        ${^RM} = 'Test';    # Testing by default, but need to go deeper to see if it's run through plackup
        for (my ($depth, @caller) = 3; @caller = caller($depth); $depth++) {
            if ($caller[0] =~ /^Plack::/) {
                ${^RM} = 'plackup';
                last;
            }
        }
    }
}

use Dancer2; no warnings 'experimental';
use Dancer2::Plugin::DBIC;
use Plack::Builder;

use MyAPI;
use if DEV, MyCMD => ();
use MyModel;
use MyOpenAPI;
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

    mount '/openAPI' => MyOpenAPI->to_app;
    mount '/api'     => MyAPI->to_app;
    mount '/'        => MyWWW->to_app;
};

given (${^RM}) {
    # Bare Dancer2 launch
    when ('Dancer') { dance }
    when (/Plack/i) {
        @ARGV = (
            '--server'  => Settings::Server,
            '--port'    => Settings::PORT,
            '--workers' => Settings::Workers,
            '-E'        => Settings::E,
            @ARGV
        );

        continue;
    }
    # Launch through Plack runner
    when ('Plack') {
        require Plack::Runner;
        my $runner = Plack::Runner->new;
        $runner->parse_options(@ARGV);
        $runner->run($app);
    }
    # Provide plackup with settings, but still allow for them to be overridden
    when ('plackup') {
        my $file = $0.'.restarting';
        if (-e $file) {
            unlink $file or die("Can't delete [$file] - [$!]");
            return $app;
        } else {
            open (my $FLAG, '+>>', $file) or die ("Can't create [$file] - [$!]");
            close $FLAG;
            exec 'plackup', $0, @ARGV;
            exit 1; # normally shouldn't reach this point
        }
    }
    # Testing
    when ('Test') { return $app }
    default       { warn "Unknown runmode [$_]!"; dance }
}

__END__
