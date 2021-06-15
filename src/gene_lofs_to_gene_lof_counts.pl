#!/usr/bin/env perl

use warnings;
use strict;
use autodie;

#gene_lofs_to_gene_lof_counts
#Copyright Brian S. Cole, PhD 2015, 2016, Abdulrahman Alasiri, 2020
#Given a *.gene_lofs file with the phased LoF strings reported by vep_vcf_to_gene_lofs, replace the LoF strings with LoF count.

sub lof_string_to_lof_count {
  my $lof_string = shift;
  my $lof_count = 0;
  my ( $first_phase , $second_phase ) = split /\|/ , $lof_string;
  $lof_count++ unless $first_phase  eq '.';
  $lof_count++ unless $second_phase eq '.';
  return $lof_count;
}

my $usage = "./gene_lofs_to_gene_lof_counts gene_lofs gene_lof_counts\n";
die $usage unless @ARGV == 2;
my ( $gene_lofs_file , $gene_lof_counts_file ) = @ARGV;

open my $in  , "<" , $gene_lofs_file;
open my $out , ">" , $gene_lof_counts_file;

my $header = <$in>;
print {$out} $header; #Pass along the single header line.

while ( <$in> ) {
  chomp;
  my @fields = split /\t/;
  my ( $gene_ID , $gene_symbol , $single_copy_LoF_frequency, $two_copy_LoF_frequency , $heterozygous_carriers , $homozygous_carriers , $compound_heterozygous_carriers ) = ( shift @fields , shift @fields , shift @fields , shift @fields , shift @fields, shift @fields , shift @fields ); #Explicitly assign these first fields, which don't have LoF strings.
  print {$out} join "\t" , ( $gene_ID , $gene_symbol , $single_copy_LoF_frequency , $two_copy_LoF_frequency , $heterozygous_carriers , $homozygous_carriers , $compound_heterozygous_carriers );
  for ( @fields ) {
    print {$out} "\t" , lof_string_to_lof_count( $_ );
  }
  print {$out} "\n";
}
