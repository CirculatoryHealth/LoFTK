#!/usr/bin/env perl

use warnings;
use strict;
use autodie;
use feature qw/ switch say /;
use Getopt::Long;
use Carp;
use IO::File;

my $USAGE = << "And be among her cloudy trophies hung.";

merge_gene_lof_counts: a tool to merge gene_lof_counts files from multiple studies for mega-anaysis.
Copyright 2016 Brian Sebastian Cole, PhD.

./merge_gene_lof_counts -i first_gene_lof_counts,second_gene_lof_counts -o merged_gene_lof_counts

Options:
-i  --input_files        Comma-separated list of input file names to merge. Requred.
-o  --output_file        Output file to write merged data to. Required. I'm not going to make up an output name for you, that's presumptuous.
-u  --union              Compute union instead of intersection. Default: disabled.
-w  --wing_value         Value to supply for genes in the union but not the intersection when --union is enabled. Default: 0
-c  --clobber            Flag to overwrite ("clobber") the output file if it exists. Default: disabled.
-h  --help               Print this message and exit.

Examples:
1) Just compute the intersection, clobbering the existing output file:
./merge_gene_lof_counts -i first_gene_lof_counts,second_gene_lof_counts --clobber

2) Compute the union, setting wing values (not in the intersection) to "NA":
./merge_gene_lof_counts -i first_gene_lof_counts,second_gene_lof_counts,third_gene_lof_counts -u -w NA

And be among her cloudy trophies hung.

main(); #Run program.

sub open_input_files {
  #Given a comma-separated string of input files, return opened filehandles for reading.
  #Croak if there are one or fewer file names provided.
  #Additionally validate the existence of each of the files, croak if any are not files.
  my $input_files_string = shift; #Reference to a string.
  my @input_file_names = split /,/ , $input_files_string; #Split the comma-separated string into individual file names.
  scalar @input_file_names < 2 and croak "Need more than one input file to process: received the string $$input_files_string which had " , scalar @input_file_names , " files.\n";
  map { croak "Invalid file provided: $_\n" unless -f } @input_file_names; #Croak unless all input files exist.
  return map IO::File->new( $_ ) , @input_file_names; #Open each input file.
}

sub array_count {
  #Given a referenc to an array and a scalar number to count, count the number of occurrences of that scalar with the array and return the count as a scalar.
  my ( $array_reference , $to_count ) = @_;
  my $count = 0;
  map { $_ == $to_count and $count++ } @$array_reference;
  return $count;
}

sub parse_dyad_lofs_line {
  #Given a reference to a string containing a raw data line from a dyad_lofs file, return a key-value pair where the key is a tab-joined ENSEMBL gene ID (ENSG#) and the HGNC gene symbol,
  #  and the value is a reference to a hash containing single-copy LoF count, two-copy LoF count, the total number of samples, and the actual LoF counts as a tab-delimited string.
  my $dyad_lofs_line_reference = shift;
  chomp $$dyad_lofs_line_reference;
  my @fields = split /\t/ , $$dyad_lofs_line_reference;
  carp "Failed to split a line into fields.  Line was this: $$dyad_lofs_line_reference\n" unless scalar @fields >= 3; #Need at least three fields.
  my $gene_ID     = shift @fields;
  my $gene_symbol = shift @fields;
  my $single_f    = shift @fields; #An existing, precomputed single-copy LoF frequncy which will not be used - frequencies will be recomputed after merging.
  my $double_f    = shift @fields; #The same, but a two-copy LoF frequency.
  my $key         = join "\t" , ( $gene_ID , $gene_symbol ); #Key is the first two fields.
  my $value       = { single_copy_lof_count => array_count( \@fields , 1 ) ,
		      two_copy_lof_count    => array_count( \@fields , 2 ) ,
		      total_samples         => scalar @fields              ,
		      genotypes             => join "\t" , @fields         ,
		    };
  return ( $key , $value );
}

sub get_samples_string_from_header_line {
  #Given a reference to a raw header line, chomp it, extract the samples, and return a tab-delimited string of the samples.
  my $line_ref = shift;
  chomp $$line_ref;
  my @fields = split /\t/ , $$line_ref;
  my ( $gene_ID , $gene_symbol , $single_f , $double_f ) = ( shift @fields , shift @fields , shift @fields , shift @fields );
  return join "\t" , @fields;
}

sub read_dyad_lofs_file {
  #Given an opened filehandle to a dyad_lofs file, return a string of the samples and a hash keyed by a tab-separated string of gene_ID and gene_symbol
  #  and valued by a reference to a hash that contains genotypes as well as frequency of single-copy and two-copy LoF.
  my $filehandle = shift;
  my ( %genotypes , );
  my $header_line = $filehandle->getline();
  my $samples_string = get_samples_string_from_header_line( \$header_line );
  while ( defined( my $raw_line = $filehandle->getline() ) ) {
    my ( $key , $value ) = parse_dyad_lofs_line( \$raw_line );
    $genotypes{ $key } = $value; #Update the hash.
  }
  return ( \$samples_string , \%genotypes ); #Return both as references.
}

sub get_intersection_of_hash_keys {
  #Given an arbitrary number of references to hashes, return an array reference containing the intersection of the keys.
  my @hash_references = @_; #Explicitly rename the argument list.
  croak "Need more than one hash reference to get the intersection of hash keys from.\n" unless scalar @hash_references > 1;
  my @intersection_of_hash_keys;
  my $first_hash_reference = shift @hash_references; #Start with the first hash, then check each key in each of the remaining hashes.
  KEY: for my $key ( keys %$first_hash_reference ) {
    HASH: for my $hash_reference ( @hash_references ) {
      next KEY unless exists $hash_reference->{ $key };
    }
    push @intersection_of_hash_keys , $key; #Exists in all other hash references.
  }
  return \@intersection_of_hash_keys;
}

sub get_union_of_hash_keys {
  #Given an arbitrary number of references to hashes, return an array reference containing the intersection of the keys.
  my @hash_references = @_;
  croak "Need more than one hash reference to get the union of hash keys from.\n" unless scalar @hash_references > 1;
  my %union_of_hash_keys;
  for my $hash_reference ( @hash_references ) {
    for my $key ( keys %$hash_reference ) {
      $union_of_hash_keys{ $key } = 1;
    }
  }
  my @union_of_hash_keys = keys %union_of_hash_keys;
  return \@union_of_hash_keys;
}

sub get_sample_size {
  #Return the count of "\t" plus 1.
  my $sample_string_reference = shift;
  my $tab_hits = () = $$sample_string_reference =~ /\t/g; #Match all tabs in list context, then coerce to scalar to capture count.
  return $tab_hits + 1;
}

sub repeat_string {
  my ( $string , $times , $spacer ) = @_;
  my $repeated_string = $string;
  for ( 2 .. $times ) { #Start iteration at 2 because there is already one instance of the string, and the iteration is inclusive of the $times variable (unlike in Python's range objects).
    $repeated_string .= $spacer . $string;
  }
  return $repeated_string;
}

sub divide {
  my ( $numerator , $denominator ) = @_;
  if ( $denominator == 0 ) {
    carp "Illegal division by zero. This shouldn't happen. Returning a garbage division result of 0.";
    return 'NA';
  }
  else { #The denominator isn't zero.
    if ( $numerator == 0 ) {
      return 0; #In computing frequency, we'll call this case 0.
    }
    else {
      return $numerator / $denominator;
    }
  }
}

sub main {
  #Collect and validate options.
  #Read in all the input files.
  #Compute either the union or the intersection as specified in the options.
  #Write the output file.

  #Collect and validate options.
  my ( $input_files , ); #Required options.
  my ( $output_file , $wing_value , ) = ( 'merged_dyad_lofs' , 0 , ); #Options with defaults.
  my ( $union , $clobber , $help , ); #Flag options.

  GetOptions( "input_files=s" => \$input_files , #Required.
	      "output_file=s" => \$output_file , #Required.
	      "wing_value=s"  => \$wing_value  , #Should be a scalar.
	      "union"         => \$union       , #Boolean.
	      "clobber"       => \$clobber     , #Boolean.
	      "help"          => \$help        , #Boolean.
	    );

  $help and print $USAGE and exit;
  die "Need input files.\n$USAGE"                 unless $input_files;
  die "Need an output file to write to.\n$USAGE"  unless $output_file;
  die "Need a wing value for union mode.\n$USAGE" if ( $union and not $wing_value );
  die "Not clobbering $output_file.\n$USAGE"      if ( -f $output_file and not $clobber );

  #Read in all the input files.
  my @contents; #Array of references (one for each input file) containing two references: the first to a string of samples, the second to a hash of genotypes.
  map { push @contents , [ read_dyad_lofs_file( $_ ) ] } open_input_files( $input_files );

  #Write header for the output.
  my $output = IO::File->new( $output_file , 'w' );
  my $header = join "\t" , ( "gene_ID" , "gene_symbol" , "single_copy_LoF_frequency" , "two_copy_LoF_frequency" , ); #Start the header.
  for ( @contents ) {
    $header .= "\t" . ${ $_->[0] };
  }
  $output->say( $header );

  #First, simplify the merge operation by populating an array of the datasets.
  my ( @list_of_genotypes_hash_refs , @list_of_samples_strings );
  for ( @contents ) { #Iterate over parsed input files.
    push @list_of_genotypes_hash_refs , $_->[1]; #The genotypes hash ref.
    push @list_of_samples_strings     , $_->[0]; #The samples string ref.
  }
  my @study_sizes = map { get_sample_size( $_ ) } @list_of_samples_strings;

  if ( $union ) { #Use the union of hash keys.
    my $union_of_hash_keys = get_union_of_hash_keys( @list_of_genotypes_hash_refs ); #Use the second reference, the hashref of genotypes.
    for my $hash_key ( @$union_of_hash_keys ) { #Iterate over the union of hash keys.
      my $output_string; #Collect the merged genotypes.
      my ( $total_samples , $total_merged_single_copy_lofs , $total_merged_two_copy_lofs ) = ( 0 , 0 , 0 );
      for my $study_index ( 0 .. $#contents ) { #Iterate over the individual files ("studies").
	my ( $study , $study_size ) = ( ${ contents[ $study_index ] }[1] , $study_sizes[ $study_index ] );
	$total_samples += $study_size;
	if ( exists $study->{ $hash_key } ) { #Study has this gene. Study is already dereferenced above.
	  if ( $output_string ) { #Output string already exists, so append to it.
	    $output_string .= "\t" . $study->{ $hash_key }{ genotypes };
	  }
	  else { #Output string doesn't exist, so assign to it.
	    $output_string  = $study->{ $hash_key }{ genotypes };
	  }
	  $total_merged_single_copy_lofs += $study->{ $hash_key }{ single_copy_lof_count };
	  $total_merged_two_copy_lofs    += $study->{ $hash_key }{ two_copy_lof_count };
	}
	else { #Study didn't have this gene. Fill in the wing_values.
	  my $wing_values_string = repeat_string( $wing_value , $study_size , "\t" ); #Generate wing_values string for the current study size.
	  if ( $output_string ) { #Output string already exists, so append to it.
	    $output_string .= "\t" . $wing_values_string;
	  }
	  else {
	    $output_string = $wing_values_string;
	  }
	}
      }
      #Recompute the single- and two-copy LoF frequencies for the merged data.
      my ( $single_copy_lof_frequency , $two_copy_lof_frequency ) = ( divide( $total_merged_single_copy_lofs , $total_samples ) , divide ( $total_merged_two_copy_lofs , $total_samples ) );
      $output->say( join "\t" , ( $hash_key , $single_copy_lof_frequency , $two_copy_lof_frequency , $output_string ) );
    }
  }
  else { #Use the intersection of hash keys.
    my $intersection_of_hash_keys = get_intersection_of_hash_keys( @list_of_genotypes_hash_refs );
    for my $hash_key ( @$intersection_of_hash_keys ) { #Iterate over the intersection of genes.
      my $output_string; #Collect the merged genotypes.
      my ( $total_samples , $total_merged_single_copy_lofs , $total_merged_two_copy_lofs ) = ( 0 , 0 , 0 );
      for my $study_index ( 0 .. $#contents ) { #Iterate over the individual studies' contents.
	my ( $study , $study_size ) = ( ${ contents[ $study_index ] }[1] , $study_sizes[ $study_index ] );
	$total_samples += $study_size;
	$output_string .= "\t" if $output_string;
	$output_string .= $study->{ $hash_key }{ genotypes };
	$total_merged_single_copy_lofs += $study->{ $hash_key }{ single_copy_lof_count };
	$total_merged_two_copy_lofs    += $study->{ $hash_key }{ two_copy_lof_count };
      }
      my ( $single_copy_lof_frequency , $two_copy_lof_frequency ) = ( divide( $total_merged_single_copy_lofs , $total_samples ) , divide ( $total_merged_two_copy_lofs , $total_samples ) );
      $output->say( join "\t" , ( $hash_key , $single_copy_lof_frequency , $two_copy_lof_frequency , $output_string ) );
    }
  }
}
