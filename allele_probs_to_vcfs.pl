#!/usr/bin/env perl

use warnings;
use strict;
#use autodie;
use feature qw/ say state /;
use Time::localtime;
use File::Basename;
use Getopt::Long;
use Carp;
use IO::File;
use IO::Zlib;
use List::Util qw/ max /;

#Global declarations:
my $RAISON_DETRE = 'When invoked from a directory containing phased allele probability files and INFO files (output from IMPUTE2), generates separate VCF files containing the phased variants.';
my $VERSION      = 0.03;
my $PROGRAM_NAME = 'allele_probs_to_vcfs';
my $COPYRIGHT    = 2015;
my $AUTHOR       = 'Brian Sebastian Cole, PhD';
my $INVOCATION   = './' . $PROGRAM_NAME . ' [options]';
my $VCF_VERSION  = 'VCFv4.1';
my $LOCALTIME    = localtime(); #Instantiate localtime object.
my $FILEDATE     = join "" , ( $LOCALTIME->year() + 1900 , $LOCALTIME->mon() , $LOCALTIME->mday() ); #Create VCF fileDate string, e.g. '20150906'.
my $EXAMPLE      = "allele_probs_to_vcf --gz -maf_cutoff 0.001 --info_cutoff 0.5 --prob_cutoff 0.1 --verbose\n";

my $usage = <<"Shazam!";
$PROGRAM_NAME version $VERSION, copyright $COPYRIGHT $AUTHOR.
$RAISON_DETRE

Usage:
$INVOCATION

Example invocation:
$EXAMPLE

Options:
-h  --help           Print this message and exit.
-g  --gz             GZIP compress the output (minimally buffered stream). Default: off.
-i  --info_cutoff    Info score cutoff. Default: 0.4
-p  --prob_cutoff    Probability cutoff. Default: 0.05 (round 0.05 down to 0 and 0.95 up to 1)
-m  --maf_cutoff     Minor allele frequency cutoff. Default: 0
-v  --verbose        Set verbose operation. Default: off.
-s  --suffix         Suffix to use for allele_probs files. Default: allele_probs.gz

Shazam!

my $vcf_header = <<"Booya!";
##fileformat=$VCF_VERSION
##fileDate=$FILEDATE
##source=$PROGRAM_NAME
##phasing=SHAPEIT_IMPUTE2
##INFO=<ID=MAF,Number=1,Type=Float,Description="exp_freq_A1">
##INFO=<ID=INFO_SCORE,Number=1,Type=Float,Description="info">
##INFO=<ID=CERTAINTY,Number=1,Type=Float,Description="certainty">
##INFO=<ID=TYPE,Number=1,Type=Integer,Description="type">
##INFO=<ID=INFO_TYPE0,Number=1,Type=Float,Description="info_type0">
##INFO=<ID=CONCORD_TYPE0,Number=1,Type=Float,Description="concord_type0">
##INFO=<ID=R2_TYPE0,Number=1,Type=Float,Description="r2_type0">
##FILTER=<ID=poor_info_score,Description="Insufficient info score">
##FILTER=<ID=rare_variant,Description="Variant is rarer than provided MAF cutoff">
##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">
##FORMAT=<ID=P1,Number=1,Type=Float,Description="Probability that the first phased allele is not REF">
##FORMAT=<ID=P2,Number=1,Type=Float,Description="Probability that the second phased allele is not REF">
Booya!

&main(); #Run program. Subroutines defined below.

sub get_allele_probabilities_files {
  #my $input_files = get_allele_probs_files()
  #my $input_files = get_allele_probs_files('glob_expression')
  #Returns an array reference of file names matching the default glob or the supplied expression.
  my $suffix = shift;
  my $glob_expression = '*' . $suffix;
  my @matching_files = glob( $glob_expression );
  @matching_files ? return \@matching_files : croak "Error collecting allele probability files using the expresion $glob_expression: no files matched. Double check to make sure files matching that pattern exist in this directory. Dying.\n";
}

sub get_file_basename {
  #my $file_basename = get_file_basename( $file_name , $suffix )
  #Returns the basename of the file with no suffix.
  my ( $file_name , $suffix ) = @_;
  my @suffix_list = ( $suffix , );
  ( my $file_basename = basename( $file_name , @suffix_list ) ) =~ s/allele_probs//;
  return $file_basename;

}

sub get_info_file {
  #my $info_file = get_info_file( $allele_probs_file_name )
  #Returns a scalar file name of the info file corresponding to the supplied allele probabilities file name.
  my ( $allele_probs_file_name , $suffix ) = @_;
  my $allele_probs_file_basename  = get_file_basename( $allele_probs_file_name , $suffix );
  my $info_file_basename = $allele_probs_file_basename . 'info';
  my $info_file_name     = $allele_probs_file_basename . 'info.gz';
  if ( -f $info_file_name ) {
    return $info_file_name;
  }
  elsif ( -f $info_file_basename ) {
    return $info_file_basename;
  }
  else {
    croak "Failed to find an info file for $allele_probs_file_name. Looked for $info_file_name and then for $info_file_basename but found neither. Double check to make sure info files exist in this directory. Dying.\n";
  }
}

sub get_sample_file {
  #my $sample_file = get_sample_file()
  #Returns a scalar file name of the sample file.
  my @potential_sample_files = glob('*_samples');
  if ( @potential_sample_files == 1 ) { #There is only one file that matches /_samples/ so use this file.
    return shift @potential_sample_files;
  }
  elsif ( @potential_sample_files == 0 ) { #No sample files found!
    croak "Fatal error: failed to find a sample file (*_samples) in the current working directory. Cannot generate dosage file. Dying.\n";
  }
  else { #More than one sample file found.
    carp "Warning: more than one sample file found in the current working directory, found " , scalar @potential_sample_files , " *_samples files.\nUsing the first one: $potential_sample_files[0], hope that's okay...\n";
    return shift @potential_sample_files;
  }
}

sub get_sample_ids {
  #my $ids = get_sample_ids()
  #Finds the sample file in the current working directory, extracts the sample IDS, and returns a reference to an array containing them in the order in which they were encountered.
  my $sample_fh = IO::File->new( get_sample_file() , 'r' ); #Try to open the sample file (*_samples).
  <$sample_fh> for 0 .. 1; #Discard the first two lines of the samples file.
  my @ids;
  while ( defined( my $sample_line = $sample_fh->getline() ) ) {
    my @sample_fields = split /\s+/ , $sample_line;
    push @ids , $sample_fields[1];
  }
  @ids ? return \@ids : croak "Failed to extract sample IDs - got zero IDs from the sample file. Dying.\n";
}

sub get_chromosome_from_file_name {
  #my $chromosome = get_chromosome_from_file_name( $file_name )
  #Extracts the chromosome of the entries held within the provided file.
  my $file_name = shift;
  $file_name =~ /(?<chromosome>chr\d+)/ ? return $+{chromosome} : carp "Failed to extract chromosome from the file named $file_name. Returning '.' to denote missingness.\n";
}

sub open_info_filehandle {
  #my $info_filehandle = open_info_filehandle( $allele_probs_file_name );
  #Tries to find the info file corresponding to the provided allele probabilities file, determine whether it is GZIP compressed or not, and returns a readable IO object.
  my ( $allele_probs_file_name , $suffix ) = @_;
  my $info_file_name = get_info_file( $allele_probs_file_name , $suffix );
  my $info_filehandle;
  if ( $info_file_name =~ /.gz$/ ) { #Instantiate IO::Zlib object.
    $info_filehandle = IO::Zlib->new( $info_file_name , 'r' );
  }
  else { #Instantiate IO::File object.
    $info_filehandle = IO::File->new( $info_file_name , 'r' );
  }
  return $info_filehandle;
}

sub get_genotype {
  #my $genotype = get_genotype( $first_probability , $second_probability , $params )
  #Given a pair of REF allele probabilities and a reference to the global options hash (containing the prob_cutoff value), return a fully formatted VCF genotype string.
  my ( $first_probability , $second_probability , $params ) = @_;
  my $high_cutoff = 1 - $params->{prob_cutoff}; #At or above this value, round up to 1.
  my $genotype_string;
  if ( $first_probability <= $params->{prob_cutoff} ) {
    $genotype_string = '0|'; #Round down to REF allele.
  }
  elsif ( $first_probability >= $high_cutoff ) {
    $genotype_string = '1|'; #Round up to ALT allele.
  }
  else {
    $genotype_string = '.|'; #Mask as missing.
  }

  if ( $second_probability eq '-' ) { #Missing value for males on X chromosome.
    $genotype_string .= '.';
  }
  elsif ( $second_probability <= $params->{prob_cutoff} ) {
    $genotype_string .= '0';
  }
  elsif ( $second_probability >= $high_cutoff ) {
    $genotype_string .= '1';
  }
  else {
    $genotype_string .= '.';
  }
  #Finally, add the probabilities.
  return join ':' , ( $genotype_string , $first_probability , $second_probability );
}

sub allele_probabilities_file_to_vcf {
  #allele_probabilities_file_to_vcf( $allele_probs_file_name , $sample_ids , $vcf_header , $options )
  #Given a scalar allele probabilfities file name, a reference to an array of sample IDs, a VCF header string, and cutoffs to use in filtering and output, convert the allele probabilities and associated variant information to VCF format, applying the filters during the process.
  my ( $allele_probs_file_name , $sample_ids , $vcf_header , $params ) = @_;
  my $allele_probs_filehandle = IO::Zlib->new( $allele_probs_file_name , 'r' );
  my $output_file_name = get_file_basename( $allele_probs_file_name , $params->{suffix} ) . '.phased.vcf'; #Output file name for the current chunk.
  my $output_filehandle;
  if ( $params->{gz} ) {
      $output_filehandle = IO::Zlib->new( $output_file_name , 'w' );
  }
  else {
      $output_filehandle = IO::File->new( $output_file_name , 'w' );
  }

  #Print metadata header:
  $output_filehandle->print( $vcf_header );
  #Print header line containing the sample names:
  $output_filehandle->print( join "\t" , ( '#CHROM' , 'POS' , 'ID' , 'REF' , 'ALT' , 'QUAL' , 'FILTER' , 'INFO' , 'FORMAT' , @$sample_ids ) );
  $output_filehandle->print( "\n" );

  my $info_filehandle = open_info_filehandle( $allele_probs_file_name , $params->{suffix} );
  my $info_header     = $info_filehandle->getline(); #The header line from the info file.

  my ( $CHROM , $POS , $ID , $REF , $ALT , $QUAL , $FILTER , $INFO , $FORMAT ); #Declare VCF output fields that precede genotypes.
  $CHROM  = get_chromosome_from_file_name( $allele_probs_file_name ); #The chromosome must be extracted from the file name.
  $FORMAT = 'GT:PAA:PAa:Paa'; #The format for the genotype columns.
  $QUAL   = '.'; #Don't set a PHRED quality score, instead stash imputation numbers in INFO field.

  while ( defined( my $info_line         = $info_filehandle->getline() ) and
	  defined( my $allele_probs_line = $allele_probs_filehandle->getline() ) ) {
    my $output_line; #Buld up output string.
    chomp( $info_line , $allele_probs_line );

    #First, process the info file for the current variant.
    my ( $snp_id , $rs_id , $position , $a0 , $a1 , $exp_freq_a1 , $info , $certainty , $type , $info_type0 , $concord_type0 , $r2_type0 ) = split /\s+/ , $info_line;
    $POS  = $position;
    $ID   = $rs_id;
    $INFO = 'MAF=' . $exp_freq_a1 . ';INFO_SCORE=' . $info . ';CERTAINTY=' . $certainty . ';TYPE=' . $type . ';INFO_TYPE0=' . $info_type0 . ';CONCORD_TYPE0=' . $concord_type0 . ';R2_TYPE0=' . $r2_type0;
    my @failed_filters; #Build up a semicolon-separated list of the filters that have failed.
    if ( $exp_freq_a1 < $params->{maf_cutoff} ) {
      push @failed_filters , 'rare_variant';
    }
    if ( $info < $params->{info_cutoff} ) {
      push @failed_filters , 'poor_info_score';
    }
    if ( @failed_filters ) {
      $FILTER = join ";" , @failed_filters;
    }
    else {
      $FILTER = 'PASS';
    }

    #Next, process the allele probabilites file for the current variant. Get the REF and ALT alelles to start out.
    my @allele_probabilities_fields = split /\s+/ , $allele_probs_line;
    my ( $allele_snp_id , $allele_rs_id , $allele_position ) = ( shift @allele_probabilities_fields , shift @allele_probabilities_fields , shift @allele_probabilities_fields );
    ( $REF , $ALT ) = ( shift @allele_probabilities_fields , shift @allele_probabilities_fields );
    $output_line = join "\t" , ( $CHROM , $POS , $ID , $REF , $ALT , $QUAL , $FILTER , $INFO , $FORMAT ); #Build up mandatory output fields.

    #Finally, generate the genotype entries for each individual and print the VCF output.
    my $GENOTYPE;
    while ( @allele_probabilities_fields >= 2 ) {
      my ( $first_probability , $second_probability ) = ( shift @allele_probabilities_fields , shift @allele_probabilities_fields );
      $GENOTYPE = get_genotype( $first_probability , $second_probability , $params );
      $output_line .= "\t" . $GENOTYPE;
    }
    $output_filehandle->print( $output_line , "\n" );
    $output_filehandle->flush(); #Write data at each line from the perlio API buffer.
  }
}

sub main {
  #1. Collect arguments, setting defaults.
  #2. Collect allele probability files to use.
  #3. Collect sample IDs from *_samples file.
  #4. Iterate over allele probability files, collecting the probabilities for each variant.
  #5. Simultaneously iterate over *_info files to collect SNP-level information.
  #6. Apply filters for info, probability, and MAF, setting the FILTER value as needed (either PASS or the name of filters that failed.)
  #7. Using the allele probablities, generate genotypes and probabilities for each individual.

  #Set default options in a hash reference:
  my $options = { info_cutoff => 0.4               , #Cutoff for the info score, below which the FILTER column is no longer set to PASS.
		  prob_cutoff => 0.05              , #Probability cutoff for rounding down to the 0 allele.
		  maf_cutoff  => 0                 , #Minor allele frequency cutoff below which the FILTER column is no longer set to PASS.
		  gz          => ''                , #Flag for GZIP-compressing the output file.
		  help        => ''                , #Flag for generating help message.
		  verbose     => ''                , #Flag for verbose operation.
		  suffix      => 'allele_probs.gz' ,
		};

  GetOptions( "info_cutoff=f" => \$options->{info_cutoff} , #Floating point number.
	      "prob_cutoff=f" => \$options->{prob_cutoff} ,
	      "maf_cutoff=f"  => \$options->{maf_cutoff}  ,
	      "gz"            => \$options->{gz}          , #Flag.
	      "help"          => \$options->{help}        ,
	      "verbose"       => \$options->{verbose}     ,
	      "suffix=s"      => \$options->{suffix}      ,
	    );

  $options->{help} and die $usage;

  #Validate probability cutoff is a number within the range [0,0.5)
  unless ( $options->{prob_cutoff} >= 0 and $options->{prob_cutoff} < 0.5 ) {
    die "Invalid probabilty cutoff ($options->{prob_cutoff}) provided: must be greater than or equal to 0 and less than 0.5.\n$usage";
  }
  #Validate info cutoff is within range [0,1]
  unless ( $options->{info_cutoff} >= 0 and $options->{info_cutoff} <= 1 ) {
    die "Invalid info sore cutoff ($options->{info_cutoff}) provided: must be greater than or equal to 0 and less than or equal to 1.0.\n$usage";
  }
  #Validate MAF cutoff is within range [0,1]
  unless ( $options->{maf_cutoff} >= 0 and $options->{maf_cutoff} <= 1 ) {
    die "Invalid minor allele frequency cutoff ($options->{maf_cutoff}) provided: must be greater than or equal to 0 and less than or equal to 1.0.\n$usage";
  }

  if ( $options->{verbose} ) {
    print "Finished collecting arguments. Using probability cutoff of $options->{prob_cutoff}, minor allele frequency cutoff of $options->{maf_cutoff}, and info score cutoff of $options->{info_cutoff}. Writing output";
    $options->{gz} ? say " using GZIP compression." : say ".";
  }

  my $allele_probabilities_files = get_allele_probabilities_files( $options->{suffix} ); #Array reference of allele_probs files to iterate over.
  $options->{verbose} and say "Finished collecting input files. " . scalar @$allele_probabilities_files . " total files collected.";

  my $sample_ids = get_sample_ids(); #Collect the sample IDs as an array reference.
  $options->{verbose} and say "Finished collecting sample IDs.";

  for my $allele_probabilities_file ( @$allele_probabilities_files ) {
    $options->{verbose} and say "Beginning to process $allele_probabilities_file.";
    allele_probabilities_file_to_vcf( $allele_probabilities_file , $sample_ids , $vcf_header , $options );
    $options->{verbose} and say "Finished processing $allele_probabilities_file.";
  }

  $options->{verbose} and say "Run complete.";
}
