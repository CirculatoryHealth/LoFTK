#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;
use autodie;
use List::MoreUtils qw(indexes);

my $usage = "$0 ids counts";
my $ids = shift or die $usage;
my $counts = shift or die $usage;

open my $iin, '<', $ids;
my %h = map { chomp; s/^\s+|\s+$//; $_ => 1 } <$iin>;
close $iin;

open my $vin, '<', $counts;
my @indexes;

while (my $line = <$vin>) {
    chomp $line;
    next if $line =~ /^##/;
	my @f = split /\s+/, $line;

    if ($f[0] eq 'SNP_ID') {
        for my $k (keys %h) {
	    push @indexes, indexes { $_ =~ /$k/ } @f;
	}
    }

    if (@indexes) {
        say join "\t", @f[0..4,@indexes];
    }
    else {
	say "No genotypes from $ids found in $counts.";
	last;
    }
}
close $vin;
