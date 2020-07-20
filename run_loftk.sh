#! /bin/bash

for i in XXXXX  ### Cohort 
do 
    echo $i
    IN=/hpc/dhl_ec/aalasiri/lof/Imputation/$i/Imputation     ### path to imputation files (output from IMPUTE2)
    INPUT=/hpc/dhl_ec/aalasiri/lof/Imputation/$i/Imputation/Files_for_VCF_LoF
    mkdir $INPUT
    OUTPUT=/hpc/dhl_ec/aalasiri/lof/loftk_updated/$i
    mkdir $OUTPUT
    loftk=/hpc/dhl_ec/aalasiri/lof/loftk_updated

#   for chr in $(seq 21 22)
#   do 
#	echo $chr

#=========================================#
#### Preparation of imputation files  #####
#=========================================#
#	mkdir $INPUT/vcf_chr"$chr"
#	rm $INPUT/vcf_chr"$chr"/*
#	cp allele_probs_to_vcfs.pl $INPUT/vcf_chr"$chr"
#	cp run_allele_probs.sh $INPUT/vcf_chr"$chr"
#	cp $IN/"$i"_GoNL_1KG_chr"$chr"\:*info $INPUT/vcf_chr"$chr"/   #?#
#	cp $IN/"$i"_GoNL_1KG_chr"$chr"\:*sample* $INPUT/vcf_chr"$chr"/ #?#

### The full Mb span of the chromosome                                                                                           
#	start=$( awk ' $1=="'$chr'" { print $2 } ' $loftk/chromosome_windows.txt )
#	stop=$( awk ' $1=="'$chr'" { print $3 } ' $loftk/chromosome_windows.txt )

#	while [ $start -le $stop ]
#	do

### Set the upper and lower bound for this particular interval                                                                                                 
#	    lower=$start
#	    upper=$((start + 5))
#	    echo $i $chr $lower $upper

#	    echo "scan allele probs file"
#	    zcat $IN/"$i"_GoNL_1KG_chr"$chr":"$lower"-"$upper"Mb_allele_probs.gz | awk '$1~/---/' > $INPUT/vcf_chr"$chr"/"$i"_GoNL_1KG_chr"$chr":"$lower"-"$upper"Mb_allele_probs
#	    echo "scan haps file"
#	    zcat $IN/"$i"_GoNL_1KG_chr"$chr":"$lower"-"$upper"Mb_haps.gz | awk '$1!~/---/' >> $INPUT/vcf_chr"$chr"/"$i"_GoNL_1KG_chr"$chr":"$lower"-"$upper"Mb_allele_probs
#	    echo "sort on position"
#	    sort -gk3 $INPUT/vcf_chr"$chr"/"$i"_GoNL_1KG_chr"$chr":"$lower"-"$upper"Mb_allele_probs  > $INPUT/vcf_chr"$chr"/"$i"_GoNL_1KG_chr"$chr":"$lower"-"$upper"Mb_allele_probs.sorted
#	    mv $INPUT/vcf_chr"$chr"/"$i"_GoNL_1KG_chr"$chr":"$lower"-"$upper"Mb_allele_probs.sorted $INPUT/vcf_chr"$chr"/"$i"_GoNL_1KG_chr"$chr":"$lower"-"$upper"Mb_allele_probs
#	    echo "gzip final file"
#	    gzip $INPUT/vcf_chr"$chr"/"$i"_GoNL_1KG_chr"$chr":"$lower"-"$upper"Mb_allele_probs

#	    (( start += 5 ))
#	done
### This does not work with csh, manually!
#	find $INPUT/vcf_chr*/ -name '*_GoNL_1KG_chr*Mb_allele_probs.gz' -size -65c -delete

#=========================================#
#### Preparation of imputation files  #####
#=========================================#
### Run allele_probs_to_vcf in all folders
#	cp allele_probs_to_vcfs.pl $INPUT/vcf_chr"$chr"/
#	echo "perl allele_probs_to_vcfs.pl -v" > $INPUT/vcf_chr"$chr"/run.$i.$chr.run.allele_probs_to_vcf.sh
#	echo "gzip *.vcf" >> $INPUT/vcf_chr"$chr"/run.$i.$chr.run.allele_probs_to_vcf.sh
#	qsub -o output -e error -l h_rt=1:00:00 -wd $INPUT/vcf_chr"$chr"/ -S /bin/sh $INPUT/vcf_chr"$chr"/run.$i.$chr.run.allele_probs_to_vcf.sh
#	sleep 1

#================================================================#
#### Annotation of LoF variants using VEP and LOFTEE plugin  #####
#================================================================#
#	count=1
#	for c in $INPUT/vcf_chr"$chr"/$i*.phased.vcf.gz
#	do
#	    if [ ! -e ${c%.gz}.vep.vcf.gz ]; then
#		echo $c
#		echo ${c%.gz}.vep.vcf
#		echo run.$i.$chr.$count.sh

#		echo "./ensembl-vep/vep --input_file $c --output_file ${c%.gz}.vep.vcf --vcf --offline --phased --assembly GRCh37 --plugin LoF,loftee_path:./loftee,human_ancestor_fa:./human_ancestor_fa/GRCh37/human_ancestor.fa.gz,conservation_file:./conservation_file/GRCh37/phylocsf_gerp.sql --dir_plugins ./loftee --cache --dir_cache ./ensembl-vep --port 3337 --force_overwrite" > $INPUT/vcf_chr"$chr"/run.$i.$chr.$count.sh
#		echo " gzip $c " >> $INPUT/vcf_chr"$chr"/run.$i.$chr.$count.sh
#		echo " gzip ${c%.gz}.vep.vcf " >> $INPUT/vcf_chr"$chr"/run.$i.$chr.$count.sh
#		/opt/sge/bin/lx-amd64/qsub -o output.$i.$chr.$count -e error.$i.$chr.$count -cwd -l h_rt=01:00:00 -S /bin/bash $INPUT/vcf_chr"$chr"/run.$i.$chr.$count.sh

#		sleep 5
#		((count++))
#	    fi
#	done 
#    done # chr
#======================================#
#### Genes containing LoF variants #####
#======================================#
### Genes list with high-confidence loss-of-function mutations (.vep.vcf --> gene.lof)
#    mv $INPUT/vcf_chr*/*vep.vcf.gz $OUTPUT

#    cp vep_vcf_to_gene_lofs.pl $OUTPUT
#    echo "perl vep_vcf_to_gene_lofs.pl -v -o $i.gene.lof" > $OUTPUT/run_vep_to_lof.gene.sh
#    echo "echo "Complete: collecting high-confidence loss-of-function mutations in $i.gene.lof"" >> $OUTPUT/run_vep_to_lof.gene.sh
#    echo "perl $loftk/gene_lofs_to_gene_lof_counts.pl $OUTPUT/$i.gene.lof $OUTPUT/$i.gene.counts" >> $OUTPUT/run_vep_to_lof.gene.sh # Replace the LoF strings with LoF counts (gene.lof --> gene.counts)
#    echo "echo "Complete: counting high-confidence loss-of-function mutations in $i.gene.counts"" >> $OUTPUT/run_vep_to_lof.gene.sh
#    echo "perl $loftk/gene_lofs_to_lof_snps.pl $OUTPUT/$i.gene.lof $OUTPUT/$i.gene.lof.snps" >> $OUTPUT/run_vep_to_lof.gene.sh # Extract LoF SNPs and their allele frequency (gene.lof --> gene.snps)
#    echo "echo "Complete: allele frequency of high-confidence loss-of-function mutations in $i.gene.lof.snps"" >> $OUTPUT/run_vep_to_lof.gene.sh
#    echo "echo """ >> $OUTPUT/run_vep_to_lof.gene.sh
#    qsub -o output.LoF.gene -e error.LoF.gene -l h_rt=02:00:00 -wd $OUTPUT -S /bin/sh $OUTPUT/run_vep_to_lof.gene.sh

## there are duplicated LoFVs due to different consequences per variants (CSQ:Consequence, eg. stop_gained ... etc)

#=====================#
#### LoF variants #####
#=====================#
#    cp vep_vcf_to_snp_lofs.pl $OUTPUT 
#    echo "perl vep_vcf_to_snp_lofs.pl -v -o $i.snp.lof" > $OUTPUT/run_vep_to_lof.snp.sh # List of high-confidence loss-of-function mutations (.vep.vcf --> snp.lof)
#    echo "$loftk/snp_lofs_to_snp_lof_counts.pl $OUTPUT/$i.snp.lof $OUTPUT/$i.snp.counts" >> $OUTPUT/run_vep_to_lof.snp.sh # Replace the LoF strings with LoF counts (snp.lof --> snp.counts)
#    qsub -o output.LoF.snp -e error.LoF.snp -l h_rt=02:00:00 -wd $OUTPUT -S /bin/sh $OUTPUT/run_vep_to_lof.snp.sh
## some snps duplicated because they exist in multiple genes   XXXX get exact SNPs without duplication 


#============================================================================#
#### Calculate statistics samples,SNPs, transcripts and genes per cohort #####  
#============================================================================#
    g="gene"
#    g="snp"
#foreach g (gene snp)
    onetwo=`cut -f 5- $OUTPUT/$i.$g.counts | tail -n +2 | awk '$0~/1/ || $0~/2/' | wc -l`
    one=`cut -f 5- $OUTPUT/$i.$g.counts | tail -n +2 | awk '$0~/1/' | wc -l `
    two=`cut -f 5- $OUTPUT/$i.$g.counts | tail -n +2 | awk '$0~/2/' | wc -l `
    genehomomin=`cat $OUTPUT/$i.$g.counts | bash $loftk/transpose.sh | tail -n +5 | cut -f 2- | sed 's/[^2]//g' | awk '{ print length }' | sort -g | head -1`
    genehomomax=`cat $OUTPUT/$i.$g.counts | bash $loftk/transpose.sh | tail -n +5 | cut -f 2- | sed 's/[^2]//g' | awk '{ print length }' | sort -gr | head -1`
    genehetmin=`cat $OUTPUT/$i.$g.counts | bash $loftk/transpose.sh | tail -n +5 | cut -f 2- | sed 's/[^1]//g' | awk '{ print length }' | sort -g | head -1`
    genehetmax=`cat $OUTPUT/$i.$g.counts | bash $loftk/transpose.sh | tail -n +5 | cut -f 2- | sed 's/[^1]//g' | awk '{ print length }' | sort -gr | head -1`

    echo "Cohort $i"
    echo "$g"s
    echo "$one "$g"s heterozygous LoF, $two "$g"s homozygous LoF, $onetwo "$g"s total with LoF"
    echo "$genehetmin - $genehetmax "$g"s with heterozygous LoF per sample"
    echo "$genehomomin - $genehomomax "$g"s with homozygous LoF per sample" 

done # cohort
 
echo "======================================================================="
echo "     _____ _   _ ____ "
echo "    | ____| \ | |  _ \ "
echo "    |  _| |  \| | | | | "
echo "    | |___| |\  | |_| | "
echo "    |_____|_| \_|____/ "
echo "======================================================================="


#cat $i | bash transpose.sh | tail -n +5 | cut -f 2- | sed 's/[^2]//g' | awk '{ print length }' > $i.homozygousLoFcounts_per_sample.txt
#cat $i | bash transpose.sh | tail -n +5 | cut -f 2- | sed 's/[^1]//g' | awk '{ print length }' > $i.heterozygousLoFcounts_per_sample.txt
