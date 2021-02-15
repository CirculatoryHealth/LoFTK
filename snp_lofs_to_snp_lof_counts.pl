#!/usr/bin/env perl

use warnings;
use strict;
use autodie;

#gene_lofs_to_gene_lof_counts
#Copyright Abdulrahman Alasiri, 2020
#Given a *.snp_lofs file with the phased LoF strings reported by vep_vcf_to_snp_lofs, replace the LoF strings with LoF count.

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
  my ( $SNP_ID , $Consequence , $gene_ID , $gene_symbol , $heterozygous_LoF_frequency , $homozygous_LoF_frequency , $heterozygous_LoF_carriers , $homozygous_LoF_carriers ) = ( shift @fields , shift @fields , shift @fields , shift @fields , shift @fields , shift @fields , shift @fields , shift @fields ); #Explicitly assign these first fields, which don't have LoF strings.
  print {$out} join "\t" , ( $SNP_ID , $Consequence , $gene_ID , $gene_symbol , $heterozygous_LoF_frequency , $homozygous_LoF_frequency , $heterozygous_LoF_carriers , $homozygous_LoF_carriers );
  for ( @fields ) {
    print {$out} "\t" , lof_string_to_lof_count( $_ );
  }
  print {$out} "\n";
}
