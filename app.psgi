#!/usr/bin/perl

# Handler for the case when "plackup" is run without any arguments

my $self = $0;
$self =~ s/psgi\Z/pl/i;

exec 'plackup', $self, @ARGV;
exit 1;
