#!/usr/bin/env perl

use warnings;
use strict;
use Carp;
use IO::File;
use feature qw/ say /;

my $RAISON_DETRE = << "La belle dame sans merci...";

gene_lofs_to_lof_snps version 1.0.0 , copyright 2020 Brian Sebastian Cole, PhD and Abdulrahman Alasiri.
Given a file containing rows representing genes and cells containing LoF strings,
  generate a new output file containing LoF SNPs and their allele frequency.

Usage: ./genelofs_to_lof_snps gene_lofs lof_snps

La belle dame sans merci...

main();

sub parse_lof_string  {
  #Given a reference to a LoF string containing phased, comma-separated strings of SNP-LoF combinations,
  #  return two references to hashes: the first containing the unique rsIDs encountered in the first phase,
  #  and the second containing the unique rsIDs encountered in the second phase.
  my ( $lof_string , ) = shift;
  my ( $first_phase , $second_phase ) = split /\|/ , $lof_string;
  my ( %first_phase_lof_strings , %second_phase_lof_strings ); #Convert arrays to hashes for uniqueness.
  map { $first_phase_lof_strings{ $_ }  = 1 } grep { not /^\.$/ } split /,/ , $first_phase;
  map { $second_phase_lof_strings{ $_ } = 1 } grep { not /^\.$/ } split /,/ , $second_phase;
  return ( \%first_phase_lof_strings , \%second_phase_lof_strings );
}

sub parse_line {
  #Given a reference to a gene_lofs line, return a dictionary of unique rsIDs encountered and their frequency.
  #  Define the frequency as the number of unique chromosomes in which that SNP occurs divided by the total number of chromosomes.
  #  (Note that this would be inaccurate for nonautosomal genetic variants or nondiploid organisms, as well as aneuploid diploids.)
  my $line_ref  = shift;
  chomp $$line_ref;
  my @fields = split /\t/ , $$line_ref;

  #The first four fields don't contain phased LoF strings.
  my $ENSEMBL_ID = shift @fields;
  my $HGNC_ID    = shift @fields;
  my $single_f   = shift @fields;
  my $double_f   = shift @fields;
  my $het_carr = shift @fields;
  my $hom_carr = shift @fields;
  my $c_het_carr = shift @fields;


  #The rest of the fields contain phased LoF strings. Collect them into hashes of counts.
  my %snp_counts; #Key by lof_string, value by count.

  for ( @fields ) {
    my ( $first_phase_lof_strings , $second_phase_lof_strings ) = parse_lof_string( $_ );
    map { $snp_counts{ $_ }++ } keys %$first_phase_lof_strings;
    map { $snp_counts{ $_ }++ } keys %$second_phase_lof_strings;
  }

  #Finally, compute the frequency of each SNP from the counts.
  my %snp_frequency;
  my $sample_count = @fields; #Scalar context: count the number of samples.
  map { $snp_frequency{ $_ } = $snp_counts{ $_ } / ( 2 * $sample_count ) } keys %snp_counts;
  return \%snp_frequency;
}

sub main {
  #Collect the gene_lofs file, open it, and skip the header.
  #Then, iterate through each line, collecting a SNP frequency hash ref for the current line.
  #Combine the SNP frequency hash for the current line into a file-level hash ref.
  #Write output, sorted by descending SNP frequency.

  die $RAISON_DETRE unless @ARGV == 2;

  my ( $gene_lofs_file , $output_file ) = @ARGV[0..1]; #Need to explicitly pull the first command line arguments.
  my $gene_lofs = IO::File->new( $gene_lofs_file );
  my $output    = IO::File->new( $output_file , 'w' );
  my $header = $gene_lofs->getline(); #Don't need the header.

  my %lof_snps; #Hold the SNPs extracted from each line of the file.

  while ( defined ( my $line = $gene_lofs->getline() ) ) {
    my $current_lof_snps = parse_line( \$line );
    map { $lof_snps{ $_ } = $current_lof_snps->{ $_ } } keys $current_lof_snps; #Update.
  }

  $output->say( join "\t" , ( "SNP" , "frequency" ) );
  for my $snp ( sort { $lof_snps{ $b } <=> $lof_snps{ $a } } keys %lof_snps ) {
    $output->say( join "\t" , ( $snp , $lof_snps{$snp} ) );
  }
}
