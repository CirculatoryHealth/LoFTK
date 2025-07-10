#!/usr/bin/env perl

use warnings;
use strict;
use autodie;
use feature qw/ say /;
use Carp;
use Getopt::Long;
use IO::File;
use IO::Zlib;

my $PROGRAM_NAME       = 'vep_vcf_to_SNP_lofs';
my $INVOCATION         = './' . $PROGRAM_NAME . ' -o output.lof';
my $AUTHOR             = 'Brian Sebastian Cole, PhD & Abdulrahman Alasiri';
my $VERSION            = 1.00;
my $RAISON_DETRE       = "When invoked in a directory containing *.vep.vcf files, iterate through all files and write a single VCF-style output file where the rows are variants and the genotype entries are phased lists of high-confidence loss-of-function mutations.";
my @INFO_FIELDS        = qw/ MAF INFO_SCORE CERTAINTY TYPE INFO_TYPE0 CONCORD_TYPE0 R2_TYPE0 CSQ /; #Specific to this flavor of VEP VCF.
my $INFO_FIELD_DELIMITER = ';';
my $MISSING_LOF_VALUE  = '.'; #Value to put in for individuals who have no LoF-annotated variants in a transcript.

my $USAGE = <<"Quid hodie cogitare debeo?";
$PROGRAM_NAME version $VERSION
Copyright 2015, $AUTHOR

$RAISON_DETRE

Usage:
$INVOCATION [options]

Options:

-h  --help             Print this message and exit.
-v  --verbose          Set verbose operation. Default: False.
-o  --output_file      Output file to write to. Required.

Quid hodie cogitare debeo?

&main();

sub get_vep_vcf_files {
  #my $vep_vcf_files = get_vep_vcf_files()
  #Return a reference to an array of all files matching "*.vep.vcf" in the current working directory.
  my @vep_vcf_files = glob('*.vep.vcf.gz');
  @vep_vcf_files ? return \@vep_vcf_files : croak "Fatal error: failed to find any files matching *.vep.vcf.gz in the current directory.\n";
}

sub parse_consequence {
  #my $consequence = parse_consequence( $individual_VEP_CSQ , $CSQ_fields )
  #When given a single LOFTEE+VEP CSQ substring (which are comma-separated within the CSQ= attribute), and
  # a reference to an array of the CSQ fields in the order in which they occur in the current file being parsed,
  # return a parsed hash reference.
  my ( $individual_VEP_CSQ , $CSQ_fields ) = @_;
  my %consequence;
  @consequence{ @$CSQ_fields } = split /\|/ , $individual_VEP_CSQ; #Leaning toothpick syndrome there.
  return \%consequence;
}

sub parse_consequences {
  #my $consequences = parse_consequences( $raw_CSQ_attribute , $CSQ_fields )
  #Given a scalar CSQ attribute (e.g. "CSQ=allele|type|gene|...,allele|type|gene|...") and a reference to an array containing the CSQ fields,
  # return a reference to an array of parsed consequences.
  my ( $raw_CSQ_attribute , $CSQ_fields ) = @_;
  $raw_CSQ_attribute =~ s/^CSQ=//; #Remove the attribute itself.
  my @consequences = map parse_consequence( $_ , $CSQ_fields ) , split /,/ , $raw_CSQ_attribute;
  return \@consequences;
}

sub parse_info_field {
  #my $parsed_info_field = parse_info_field( $info_field , $CSQ_fields )
  #Given a scalar info field from LOFTEE+VEP, return a reference to a parsed hash.
  my ( $info_field , $CSQ_fields ) = ( @_ );
  my %parsed_info_field;
  @parsed_info_field{ @INFO_FIELDS } = split /$INFO_FIELD_DELIMITER/ , $info_field;

  $parsed_info_field{ 'MAF' }           =~ s/^MAF=//; #Remove the leading info attribute names.
  $parsed_info_field{ 'INFO_SCORE' }    =~ s/^INFO_SCORE=//;
  $parsed_info_field{ 'CERTAINTY' }     =~ s/^CERTAINTY=//;
  $parsed_info_field{ 'TYPE' }          =~ s/^TYPE=//;
  $parsed_info_field{ 'INFO_TYPE0' }    =~ s/^INFO_TYPE0=//;
  $parsed_info_field{ 'CONCORD_TYPE0' } =~ s/^CONCORD_TYPE0=//;
  $parsed_info_field{ 'R2_TYPE0' }      =~ s/^R2_TYPE0=//;
  $parsed_info_field{ 'CSQ' } = parse_consequences( $parsed_info_field{ 'CSQ' } , $CSQ_fields ); #Fix the CSQ field.

  return \%parsed_info_field;
}

sub parse_vcf_line {
  #my $parsed_vcf_line = parse_vcf_line( $raw_vcf_line , $CSQ_fields )
  #Given a reference to a raw VCF line and a reference to an array containing the CSQ fields, return a reference to a hash of fields.
  my ( $raw_vcf_line , $CSQ_fields ) = @_;
  chomp $raw_vcf_line;
  my @vcf_fields = split /\t/ , $raw_vcf_line;
  return { chrom     => shift @vcf_fields ,
	   pos       => shift @vcf_fields ,
	   id        => shift @vcf_fields ,
	   ref       => shift @vcf_fields ,
	   alt       => shift @vcf_fields ,
	   qual      => shift @vcf_fields ,
	   filter    => shift @vcf_fields ,
	   info      => parse_info_field( shift @vcf_fields , $CSQ_fields ) ,
	   format    => shift @vcf_fields ,
	   genotypes => \@vcf_fields      , #Reference to the rest of the fields.
	 };
}

sub get_sample_names_and_CSQ_fields {
  #my ( $sample_names , $CSQ_fields ) = get_sample_names_and_CSQ_fields( $vcf_file_name )
  #Returns a reference to an array containing the sample names, taken from the VCF header line, and a reference to an array containing the CSQ fields.
  my $vcf_file_name = shift;
  my $vcf_file_object = IO::Zlib->new( $vcf_file_name, 'r' );
  my $header;
  my @CSQ_fields;
  while ( defined ( my $line = $vcf_file_object->getline() ) ) {
    chomp $line;
    if ( $line =~ /^##/ ) { #Metadata line.
      next unless $line =~ /ID=CSQ/;
      $line =~ s/.*Format: //; #Greedily erase everything up to the format string.
      $line =~ s/">$//; #Trim the ending.
      @CSQ_fields = split /\|/ , $line;
      next;
    }
    elsif ( $line =~ /^#CHROM/ ) { #Header line. This line contains the sample IDs that are needed.
      $header = $line;
      next;
    }
    elsif ( $line =~ /^chr/ ) { #Read past the header and metadata.
      last;
    }
  }
  my @header_fields = split /\t/ , $header;
  shift @header_fields for 0 .. 8; #Skip the CHROM POS ID REF ALT QUAL FILTER INFO FORMAT entries.
  croak "Error grabbing header line and/or CSQ fields from $vcf_file_name.\n" unless ( $header and @CSQ_fields );
  return ( \@header_fields , \@CSQ_fields ); #What remains are the sample IDs.
}

sub parse_genotype {
  #my $parsed_genotype = parse_genotype( $vcf_genotype_entry )
  #Given a VCF genotype entry, returns a reference to a 2-element array containing just the genotype values: 0, 1, or '.' (for missing).
  my $genotype_string = shift;
  $genotype_string =~ s/:.*$//; #Strip away anything that isn't the genotype part.
  my @parsed_genotype = split /[\|]/ , $genotype_string; #Phased genotypes.
  push @parsed_genotype, '.' if @parsed_genotype == 1;
  return \@parsed_genotype;
}

sub update_SNP_lofs {
  #update_transcript_lofs( $vep_vcf_file , $transcripts );
  #Given a VEP VCF file name containing LoF annotations and a data structure to store individuals' LoFs in, update the structure with the data from that file.
  my ( $vep_vcf_file , $SNPs ) = @_;
  my ( $current_sample_names , $CSQ_fields ) = get_sample_names_and_CSQ_fields( $vep_vcf_file );
  my $vcf_input = IO::Zlib->new( $vep_vcf_file, 'r' ); #Instantiate file object. Short name here, but it saves typing.
  while ( defined ( my $line = $vcf_input->getline() ) ) {
    next if $line =~ /^#/; #Skip header and metadata lines.
    next if $line =~ /intergenic_variant/; #About half of all lines are intergenic variants. Don't even parse these lines.

    chomp $line;
    my $parsed_line = parse_vcf_line( $line , $CSQ_fields );

    next unless $parsed_line->{filter} eq 'PASS'; #Skip lines without PASS filter (which fails for low info_score variants).

    #Iterate over the transcripts that are affected by the variant.
    for my $transcript ( @{ $parsed_line->{info}->{CSQ} } ) { #Transcript is a reference to the parsed "individual consequence."

      next unless $transcript->{BIOTYPE}; #Skip intergenic variants, which have no BIOTYPE.
      next unless $transcript->{BIOTYPE} eq "protein_coding"; #Skip transcripts or other features that are not protein-coding according to ENSEMBL.

      if ( $transcript->{LoF} and $transcript->{LoF} eq "HC" ) { #High-confidence loss-of-function variant.
  my $SNP_ID = join "\t" , ( $parsed_line->{id} , $transcript->{Allele} , $transcript->{Consequence} , $transcript->{Gene} , $transcript->{SYMBOL} ); #E.g. "ENSG000123\tHLA-DRA\tENST01234"
	my $LoF_string    = $parsed_line->{id} . '_' . $transcript->{Consequence}; #E.g. 'rs1234_stop_gained'.

	my $individual_index = 0; #The index of the individual (human) whose genotype is under consideration.
	for my $raw_genotype ( @{ $parsed_line->{genotypes} } ) {
	  my $individual_genotype = parse_genotype( $raw_genotype );
	  if ( $individual_genotype->[0] eq '1' ) { #LoF allele in the first phase.
	    if ( $SNPs->{$SNP_ID}->[$individual_index]->[0] ) { #There is already at least one LoF mutation at that transcript for this individual.
	      $SNPs->{$SNP_ID}->[$individual_index]->[0] .= ',' . $LoF_string; #Append a comma-separated list of the LoF mutations.
	    }
	    else {
	      $SNPs->{$SNP_ID}->[$individual_index]->[0] = $LoF_string; #Create a new entry.
	    }
	  }
	  if ( $individual_genotype->[1] eq '1' ) { #LoF allele in the second phase.
	    if ( $SNPs->{$SNP_ID}->[$individual_index]->[1] ) { #There is already at least one LoF mutation at that transcript for this individual.
	      $SNPs->{$SNP_ID}->[$individual_index]->[1] .= ',' . $LoF_string; #Append a comma-separated list of the LoF mutations.
	    }
	    else {
	      $SNPs->{$SNP_ID}->[$individual_index]->[1] = $LoF_string; #Create a new entry.
	    }
	  }
	  $individual_index++; #On to the next individual.
	}
      } #Otherwise the "LoF" call is not "HC". It could be "LC", missing or something unexpected.
      elsif ( $transcript->{LoF} and $transcript->{LoF} ne "LC" ) {
	carp "Unexpected 'LoF' value from LOFTEE encountered: expected either 'HC', 'LC', or a missing value, but saw $transcript->{LoF}.\n";
      }
    } #On to the next transcript.
  } #On to the next variant (VCF line).
} #Nothing to return: $transcripts data structure was updated in place.

sub get_CAF {
  #my ( $single_copy_LoF_fraction , $two_copy_LoF_fraction )  = get_CAF( $transcripts , $transcript , $sample_names )
  #When given a reference to the transcripts data structure and a particular transcript to extract, and a reference to an array of sample names,
  # return a reference to a 2-element array of single-copy LoF frequency and two-copy LoF frequency (called "CAF" by some).
  my ( $SNPs , $SNP , $sample_names ) = ( @_ );
  my $total_samples = scalar @$sample_names; #Number of individuals.
  croak "Failed to extract sample count - can't compute LoF frequency.\n" unless $total_samples > 0;
  my ( $total_single_copy_LoF , $total_two_copy_LoF ) = ( 0 , 0 );
  for my $sample_index ( 0 .. $total_samples - 1 ) { #Iterate across individuals.
    if ( $SNPs->{$SNP}[$sample_index][0] and $SNPs->{$SNP}[$sample_index][0] ne $MISSING_LOF_VALUE ) { #First phase has at least one LoF variant.
      if ( $SNPs->{$SNP}[$sample_index][1] and $SNPs->{$SNP}[$sample_index][1] ne $MISSING_LOF_VALUE ) { #Second phase has LoF.
       $total_two_copy_LoF++;
      }
      else {
        $total_single_copy_LoF++; #First phase only: single copy LoF.
      }
    }
    else { #First phase has no LoF variants and was uninstantiated.
  #	  if ( $SNPs->{$SNP}->[$sample_index]->[1] ) {
      if ( $SNPs->{$SNP}[$sample_index][1] and $SNPs->{$SNP}[$sample_index][1] ne $MISSING_LOF_VALUE ) {
        $total_single_copy_LoF++;
      }
    }
  }
  #Now compute LoF fractions.
  my ( $single_copy_LoF_fraction , $two_copy_LoF_fraction , $single_copy_LoF_fraction_carrier , $two_copy_LoF_fraction_carrier );
  unless ( $total_single_copy_LoF == 0 ) {
    $single_copy_LoF_fraction = $total_single_copy_LoF / $total_samples;
    $single_copy_LoF_fraction_carrier = $total_single_copy_LoF ;
  }
  else {
    $single_copy_LoF_fraction = 0;
    $single_copy_LoF_fraction_carrier = 0;
  }
  unless ( $total_two_copy_LoF == 0 ) {
    $two_copy_LoF_fraction = $total_two_copy_LoF / $total_samples;
    $two_copy_LoF_fraction_carrier = $total_two_copy_LoF;
  }
  else {
    $two_copy_LoF_fraction = 0;
    $two_copy_LoF_fraction_carrier = 0;
  }
  return ( $single_copy_LoF_fraction , $two_copy_LoF_fraction , $single_copy_LoF_fraction_carrier , $two_copy_LoF_fraction_carrier ); #Return two-element array reference.
  }

sub write_output_file {
  #write_output_file( $transcripts , $sample_names , $output_file )
  #Given the transcripts data structure, a reference to an array of sample IDs, and an output file to write to, generate the output.
  #The LoF output is held in $transcripts->{transcript_id}->[index_of_sample]->[phase], where phase is 0 or 1.
  #If that variable doesn't exist, set it to the missing value $MISSING_LOF_VALUE.
  my ( $SNPs , $sample_names , $output_file ) = @_;
  my $output = IO::File->new( $output_file , 'w' );
  $output->print( join "\t" , ( 'SNP_ID' , 'Allele' , 'Consequence' , 'gene_ID' , 'gene_symbol' , 'heterozygous_LoF_frequency' ,'homozygous_LoF_frequency' , 'heterozygous_LoF_carriers' , 'homozygous_LoF_carriers' , @$sample_names ) ); #Print output header.
  $output->print( "\n" );

  for my $SNP ( keys %$SNPs ) {
    $output->print( join "\t" , ( $SNP , get_CAF( $SNPs , $SNP , $sample_names ) ) ); #Print the single-copy LoF fraction and the two-copy LoF fraction.

    for my $sample_index ( 0 .. $#$sample_names ) { #Iterate across samples.
      my ( $first_phase_output , $second_phase_output ) = ( $SNPs->{$SNP}->[$sample_index]->[0] , $SNPs->{$SNP}->[$sample_index]->[1] );
      $first_phase_output  //= $MISSING_LOF_VALUE; #Set the default LoF output value.
      $second_phase_output //= $MISSING_LOF_VALUE;

      my $sample_output = join '|' , ( $first_phase_output , $second_phase_output );
      $output->print( "\t$sample_output" );
    }
    $output->print( "\n" );
  }
}

sub main {
  #1. Collect list of *.vep.vcf files to iterate over.
  #2. Open output filehandle.
  #3. Collect VCF header from first *.vep.vcf file, modify, and print to output.
  #4. Iterate through each *.vep.vcf file, skipping headers, and incrementing data structure of transcripts->individuals->LoFs.
  #5. For each transcript, for each individual, print VCF-style output.

  my ( $help , $verbose , ); #Set flag options with False defaults.
  my ( $output_file , );     #Required options.
  die "Failed to collect options.\n" unless
    GetOptions( "help"          => \$help        ,
		"verbose"       => \$verbose     ,
		"output_file=s" => \$output_file ,
	      );

  $help and die $USAGE;

  unless ( $output_file ) {
    die "Need an output file to write to.\n\n$USAGE";
  }

  my $vep_vcf_files = get_vep_vcf_files(); #Automatically croaks if no files.
  my ( $sample_names , $CSQ_fields ) = get_sample_names_and_CSQ_fields( $vep_vcf_files->[0] ); #Collect the names of the samples and the CSQ fields to use.

  my $SNPs = {}; #Data structure to hold transcripts, then individuals, then phases, then LoF variants in.
  for my $vep_vcf_file ( @$vep_vcf_files ) {
    $verbose and say "Beginning to process $vep_vcf_file.";
    update_SNP_lofs( $vep_vcf_file , $SNPs );
    $verbose and say "Finished processing $vep_vcf_file.";
  }
  $verbose and say "Completed processing all VEP VCF input files. Writing output.";
  write_output_file( $SNPs , $sample_names , $output_file );
  $verbose and say "Program complete. Generated $output_file.";
}
