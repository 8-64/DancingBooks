#!/usr/bin/perl

use v5.23;
use feature ':all';
use warnings;
use utf8;

use Data::Dumper 'Dumper';
use Date::Manip 'ParseDate';
use Text::CSV;

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

use Dancer2; no warnings 'experimental';

use Plack::Builder;
use Dancer2::Plugin::DBIC;

use MyAPI;
use MyWWW;
use MySchema;

# Some command-line options processing
if (defined $ARGV[0]) {
    if ($ARGV[0] =~ /recreate/i) {
        say "Re-creating the database, all data will be lost. Proceed?";
        exit 0 if (lc(getc) ne 'y');

        my $schema = schema;
        $schema->deploy( { add_drop_table => 1 } );
        exit 0;
    }

    if ($ARGV[0] =~ /load/i or DEV) {
        my $csv = Text::CSV->new;
        my $schema = schema;

        my $data_dir = "$root_dir/data";
        opendir(my $DATADIR, $data_dir) or die ("Can't open the data dir [$data_dir] - [$!]");
        while (my $item = readdir $DATADIR) {
            next if $item !~ /\.csv\z/;

            my $table = substr($item, 0, rindex($item, '.'));

            open (my $CSV, '<:encoding(utf-8)', "$data_dir/$item") or die ("Can't open file[$data_dir/$item] - [$!]");
            my $columns = $csv->getline($CSV);
            my (@entry, @extra_processing);
            foreach (@$columns) {
                my $extras = [];
                push (@$extras, \&toInt)  if /id\z/i;
                push (@$extras, \&toDate) if /date/i;
                push (@extra_processing, $extras);
            }

            while (my $row = $csv->getline($CSV)) {
                my @fields;
                while (my ($i, $cell) = each @$row) {
                    foreach ($extra_processing[$i]->@*) {
                        $cell = $_->($cell);
                    }
                    push (@fields, $columns->[$i], $cell);
                }

                $schema->resultset($table)->create({ @fields });
            }

            close $CSV;
        }
        closedir $DATADIR;
    }
}

# Utility subs, there will be more. TODO: move to the separate module
sub toInt ($arg) { int $arg }
sub toDate ($arg) { ParseDate($arg) }

builder {
    mount '/api' => MyAPI->to_app;
    mount '/'    => MyWWW->to_app;
};

# Some shortcuts to help with development
if (DEV) {
    get '/exit'    => sub { exit 0 };
    get '/showsql' => sub { DumpToPreformatted( \scalar schema()->deployment_statements ) };
}

dance;

sub DumpToPreformatted ($what) {
    "<pre>\n"
    . Dumper($what) .
    '</pre>'
}
