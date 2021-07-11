#!/usr/bin/env perl

use warnings;
use strict;
use autodie;
use feature qw/ say /;
use Carp;

#gene_lof_counts_to_dyad_lofs
#Copyright Brian Sebastian Cole, PhD 2016

#Given a two-column file relating donor ID to recipient ID and a gene_lof_counts file, generate a new output file containing encodings for recipient-specific gene LoF.
main();

sub read_donor_recipient_pairings_file {
  #Given a two-column TSV with recipient ID in the first column and donor ID in the second, construct a hash keyed by recipient and valued by donor.
  my $donor_recipient_pairings_file = shift;
  open my $in , "<" , $donor_recipient_pairings_file;
  my %donor_recipient_pairings; #Keyed by recipient, valued by donor. This allows multiorgan donation.
  my ( @recipients_without_donors , ); #Keep track of the recipients with no donor IDs for reporting.
  my $line_count = 0;
  while ( <$in> ) {
    $line_count++;
    chomp; #Doesn't remove any \r characters (carriage-return) from Windows.
    s/\r//; #That should allow Windows-saved TSV files to work.
    next if /^#/; #Skip any header or comment lines.
    my @fields = split /\t/; #Recipient ID is first column, donor is second.
    if ( scalar @fields == 2 ) {
      $donor_recipient_pairings{ $fields[0] } = $fields[1];
    }
    elsif ( scalar @fields == 1 ) {
      push @recipients_without_donors , $fields[0];
    }
    else { #Wrong number of fields!
      carp "Wrong number of fields at line $line_count. Expected 2 fields but got " . scalar @fields . " fields. Skipping line.\n";
    }
  }
  print "Finished collecting donor-recipient pairings from $donor_recipient_pairings_file.  ";
  my $total_donor_recipient_pairings = keys %donor_recipient_pairings; #Scalar context, stores number of keys.
  print "From the $line_count lines in the file, extracted $total_donor_recipient_pairings recipient-donor pairs.\n";
  if ( @recipients_without_donors ) {
    print "Also encountered " . scalar @recipients_without_donors . " recipients without donors - skipping these.\n";
  }
  return \%donor_recipient_pairings;
}

sub get_samples_from_gene_lofs_file {
  #Given a gene lofs file, return a reference to an array of samples in the order they are encountered in the header line.
  my $gene_lofs_file = shift;
  open my $in , "<" , $gene_lofs_file;
  my ( @samples , );
  while ( <$in> ) {
    chomp;
    if ( /^gene_ID/ ) { #Header line.  Collect the sample ids.
      my @samples = split /\t/;
      shift @samples for 1 .. 4; #Discard the first four fields, which aren't sample IDs.
      return \@samples;
    }
  }
  carp "Failed to extract sample IDs from $gene_lofs_file.\n";
}

sub read_gene_lof_counts_file {
  #Given a gene lof counts file and a reference to an array of sample IDs, construct a hash keyed by tab-delmited gene ID and gene symbol and valued by a hash keyed individual IDs, each of which is valued by a LoF count.
  #Return a reference to the LoF data structure.
  my ( $gene_lofs_file , $samples ) = @_;
  open my $in , "<" , $gene_lofs_file;
  my ( %lofs , );
  while ( <$in> ) {
    chomp;
    next if ( /^gene_ID/ ); #Header line. Skip.
    my @fields = split /\t/;
    my ( $gene_ID , $gene_symbol , $single_copy_lof_frequency , $two_copy_lof_frequency ) = ( shift @fields , shift @fields , shift @fields , shift @fields );
    my $key = join "\t" , ( $gene_ID , $gene_symbol );
    unless ( scalar @fields == scalar @$samples ) {
      croak "Number of fields in gene LoF counts file doesn't equal the number of samples: have " . scalar @$samples . " samples but " . scalar @fields . " fields.\n";
    }
    for ( 0 .. $#fields ) {
      $lofs{ $key }{ $samples->[$_] } = $fields[$_];
    }
  }
  return \%lofs;
}

sub get_dyad_lof_encoding {
  #When passed a scalar LoF count for the recipient and the same for the donor, return a LoF encoding.
  my ( $recipient_lof_count , $donor_lof_count ) = @_;
  if ( $recipient_lof_count == 2 and $donor_lof_count < 2 ) {
    return 1;
  }
  else {
    return 0;
  }
}

sub write_dyad_lofs_file {
  #Given a lofs hash reference, a D-R pairings hash ref, and an output file to write to,
  # Write the dyad LoFs ouptut.
  my ( $lofs , $donor_recipient_pairings , $dyad_lofs_file ) = @_;
  open my $out , ">" , $dyad_lofs_file;
  say {$out} join "\t" , ( 'gene_ID' , 'gene_symbol' , keys %$donor_recipient_pairings ); #Print the header.
  for my $gene ( keys %$lofs ) {
    print {$out} $gene;
    while ( my ( $recipient , $donor ) = each %$donor_recipient_pairings ) {
      if ( exists $lofs->{$gene}{$recipient} and exists $lofs->{$gene}{$donor} ) {
	print {$out} "\t" , get_dyad_lof_encoding( $lofs->{$gene}{$recipient} , $lofs->{$gene}{$donor} );
      }
      else {
	print {$out} "\t" , "NA"; #Can't do recipient-specific LoF count - no data.
      }
    }
    print {$out} "\n";
  }
}


sub main {
  my $usage = "./gene_lofs_to_dyad_lofs donor_reicpient_pairings.tsv gene_lofs dyad_lofs\nGiven a two-column file relating recipient ID in the first column and donor ID in the second column and gene_lofs file, generate a new output file containing encodings for recipient-specific gene LoF.\n";
  die $usage unless @ARGV == 3;
  my ( $donor_recipient_pairings_file , $gene_lofs_file , $dyad_lofs_file ) = @ARGV;
  my $donor_recipient_pairings = read_donor_recipient_pairings_file( $donor_recipient_pairings_file );
  my $samples = get_samples_from_gene_lofs_file( $gene_lofs_file );
  my $lofs = read_gene_lof_counts_file( $gene_lofs_file , $samples );
  write_dyad_lofs_file( $lofs , $donor_recipient_pairings , $dyad_lofs_file );
}
