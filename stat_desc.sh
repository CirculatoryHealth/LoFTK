#!/bin/bash
set -e


### Creating display functions
### Setting colouring
NONE='\033[00m'
OPAQUE='\033[2m'
FLASHING='\033[5m'
BOLD='\033[1m'
ITALIC='\033[3m'
UNDERLINE='\033[4m'
STRIKETHROUGH='\033[9m'

RED='\033[01;31m'
GREEN='\033[01;32m'
YELLOW='\033[01;33m'
PURPLE='\033[01;35m'
CYAN='\033[01;36m'
WHITE='\033[01;37m'

function echobold { #'echobold' is the function name
    echo -e "${BOLD}${1}${NONE}" # this is whatever the function needs to execute, note ${1} is the text for echo
}
function echoitalic {
    echo -e "${ITALIC}${1}${NONE}"
}
function echonooption {
    echo -e "${OPAQUE}${RED}${1}${NONE}"
}
function echoerrorflash {
    echo -e "${RED}${BOLD}${FLASHING}${1}${NONE}"
}
function echoerror {
    echo -e "${RED}${1}${NONE}"
}
# errors no option
function echoerrornooption {
    echo -e "${YELLOW}${1}${NONE}"
}
function echoerrorflashnooption {
    echo -e "${YELLOW}${BOLD}${FLASHING}${1}${NONE}"
}
function importantnote {
    echo -e "${CYAN}${1}${NONE}"
}

script_copyright_message() {
	echo ""
	THISYEAR=$(date +'%Y')
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "+ CC-BY-SA-4.0 License                                                                                  +"
  echo "+ Copyright (c) 2021-${THISYEAR} Abdulrahman Alasiri                                                    +"
  echo "+                                                                                                       +"
  echo "+ Copyright (c) 2020 University Medical Center Utrecht                                                  +"
  echo "+                                                                                                       +"
  echo "+ Creative Commons Attribution Share Alike 4.0 International                                            +"
	echo "+                                                                                                       +"                                                                     +"
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
}

script_arguments_error() {
	echoerror "$1" # Additional message
	echoerror "- Argument #1 is path_to/filename of the configuration file."
	echoerror ""
	echoerror "An example command would be: run_loftk.sh [arg1]""
	echoerror "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
 	echo ""
	script_copyright_message
	exit 1
}

if [[ $# -lt 1 ]]; then
    echoerrorflash "                                     *** Oh no! Computer says no! ***"
    echo ""
    script_arguments_error "You must supply at least [1] argument when running a LoF analysis!"

else
    TRANSPOSE=${LOFTK}/bin/transpose.pl

    ### LOADING CONFIGURATION FILE
    # Loading the configuration file (please refer to the LoFToolKit-Manual for specifications of this file).
    source "$1" # Depends on arg1.

    ### REQUIRED | GENERALS
    CONFIGURATIONFILE="$1" # Depends on arg1 -- but also on where it resides!!!

    ### PROJECT SPECIFIC
    ROOTDIR=${ROOTDIR} # the root directory, e.g. /hpc/dhl_ec/aalasiri/projects/test_lof
    PROJECTNAME=${PROJECTNAME} # e.g. "ukb"
    LOFTK=${LOFTOOLKIT}
    OUTPUTDIR=${ROOTDIR}/${PROJECTNAME}_LoF_output

    echo "HELLO"
    echo "$CONFIGURATIONFILE"
    echo "$ROOTDIR"
### STEP 3 ###
#============================================================================#
#### Calculate statistics samples,SNPs, transcripts and genes per cohort #####
#============================================================================#
    gene_count="${OUTPUTDIR}/${PROJECTNAME}_gene.counts"
    snp_count="${OUTPUTDIR}/${PROJECTNAME}_snp.counts"
    lof_gene="${OUTPUTDIR}/${PROJECTNAME}_gene.counts"
    lof_snp="${OUTPUTDIR}/${PROJECTNAME}_snp.counts"

    SAMPLE_SIZE=$(head -1 ${lof_gene}  | cut -f8- | wc -w)

## LoF genes
    gene_onetwo=`cut -f 8- ${lof_gene} | tail -n +2 | awk '$0~/1/ || $0~/2/' | wc -l`
    gene_one=`cut -f 8- ${lof_gene} | tail -n +2 | awk '$0~/1/' | wc -l `
    gene_two=`cut -f 8- ${lof_gene} | tail -n +2 | awk '$0~/2/' | wc -l `
    genehomomin=`${PERL} ${TRANSPOSE} ${lof_gene} | tail -n +8 | cut -f 2- | sed 's/[^2]//g' | awk '{ print length }' | sort -g | head -1`
    genehomomax=`${PERL} ${TRANSPOSE} ${lof_gene} | tail -n +8 | cut -f 2- | sed 's/[^2]//g' | awk '{ print length }' | sort -gr | head -1`
    genehetmin=`${PERL} ${TRANSPOSE} ${lof_gene} | tail -n +8 | cut -f 2- | sed 's/[^1]//g' | awk '{ print length }' | sort -g | head -1`
    genehetmax=`${PERL} ${TRANSPOSE} ${lof_gene} | tail -n +8 | cut -f 2- | sed 's/[^1]//g' | awk '{ print length }' | sort -gr | head -1`
    gene_median=`${PERL} ${TRANSPOSE} ${lof_gene} | tail -n +8 | cut -f 2- | sed 's/[^12]//g' | awk '{print length }' | sort -g | awk '{count[NR] = $1;} END {if (NR % 2) {print count[(NR + 1) / 2];}else {print (count[(NR / 2)] + count[(NR / 2) + 1]) / 2.0;}}'`
    het_gene_median=`${PERL} ${TRANSPOSE} ${lof_gene} | tail -n +8 | cut -f 2- | sed 's/[^1]//g' | awk '{print length }' | sort -g | awk '{count[NR] = $1;} END {if (NR % 2) {print count[(NR + 1) / 2];}else {print (count[(NR / 2)] + count[(NR / 2) + 1]) / 2.0;}}'`
    hom_gene_median=`${PERL} ${TRANSPOSE} ${lof_gene} | tail -n +8 | cut -f 2- | sed 's/[^2]//g' | awk '{print length }' | sort -g | awk '{count[NR] = $1;} END {if (NR % 2) {print count[(NR + 1) / 2];}else {print (count[(NR / 2)] + count[(NR / 2) + 1]) / 2.0;}}'`

    echo "Cohort ${PROJECTNAME} \(n=${SAMPLE_SIZE}\)" > ${OUTPUTDIR}/${PROJECTNAME}_output.info
    echo "" >> ${OUTPUTDIR}/${PROJECTNAME}_output.info
    echo "LoF genes contain LoF variants" >> ${OUTPUTDIR}/${PROJECTNAME}_output.info
    echo "$gene_one genes contain heterozygous LoF, $gene_two genes contain homozygous LoF, $gene_onetwo as a total of genes contain LoF variant" >> ${OUTPUTDIR}/${PROJECTNAME}_output.info
    echo "$genehetmin - $genehetmax genes with heterozygous LoF variants per sample" >> ${OUTPUTDIR}/${PROJECTNAME}_output.info
    echo "$genehomomin - $genehomomax genes with homozygous LoF variants per sample" >> ${OUTPUTDIR}/${PROJECTNAME}_output.info
    echo "Median of LoF genes per sample is ${gene_median}" >> ${OUTPUTDIR}/${PROJECTNAME}_output.info
    echo "Median of 1-copy LoF genes per sample is ${het_gene_median}" >> ${OUTPUTDIR}/${PROJECTNAME}_output.info
    echo "Median of 2-copy LoF genes per sample is ${hom_gene_median}" >> ${OUTPUTDIR}/${PROJECTNAME}_output.info

## LoF variants
    if [[ ${gene_onetwo} -eq 0 ]]; then
	snp_onetwo=0
	snp_one=0
	snp_two=0
	snphomomin=0
	snphomomax=0
	snphetmin=0
	snphetmax=0
	snp_median=0
  het_snp_median=0
  het_snp_median=0

    else

	snp_onetwo=`cut -f 10- ${lof_snp} | tail -n +2 | awk '$0~/1/ || $0~/2/' | wc -l`
	snp_one=`cut -f 10- ${lof_snp} | tail -n +2 | awk '$0~/1/' | wc -l `
	snp_two=`cut -f 10- ${lof_snp} | tail -n +2 | awk '$0~/2/' | wc -l `
	snphomomin=`${PERL} ${TRANSPOSE} ${lof_snp} | tail -n +10 | cut -f 2- | sed 's/[^2]//g' | awk '{ print length }' | sort -g | head -1`
	snphomomax=`${PERL} ${TRANSPOSE} ${lof_snp} | tail -n +10 | cut -f 2- | sed 's/[^2]//g' | awk '{ print length }' | sort -gr | head -1`
	snphetmin=`${PERL} ${TRANSPOSE} ${lof_snp} | tail -n +10 | cut -f 2- | sed 's/[^1]//g' | awk '{ print length }' | sort -g | head -1`
	snphetmax=`${PERL} ${TRANSPOSE} ${lof_snp} | tail -n +10 | cut -f 2- | sed 's/[^1]//g' | awk '{ print length }' | sort -gr | head -1`
	snp_median=`${PERL} ${TRANSPOSE} ${lof_snp} | tail -n +10 | cut -f 2- | sed 's/[^12]//g' | awk '{print length }' | sort -g | awk '{count[NR] = $1;} END {if (NR % 2) {print count[(NR + 1) / 2];}else {print (count[(NR / 2)] + count[(NR / 2) + 1]) / 2.0;}}'`
	het_snp_median=`${PERL} ${TRANSPOSE} ${lof_snp} | tail -n +10 | cut -f 2- | sed 's/[^1]//g' | awk '{print length }' | sort -g | awk '{count[NR] = $1;} END {if (NR % 2) {print count[(NR + 1) / 2];}else {print (count[(NR / 2)] + count[(NR / 2) + 1]) / 2.0;}}'`
	homo_snp_median=`${PERL} ${TRANSPOSE} ${lof_snp} | tail -n +10 | cut -f 2- | sed 's/[^2]//g' | awk '{print length }' | sort -g | awk '{count[NR] = $1;} END {if (NR % 2) {print count[(NR + 1) / 2];}else {print (count[(NR / 2)] + count[(NR / 2) + 1]) / 2.0;}}'`

    fi

    echo "" >> ${OUTPUTDIR}/${PROJECTNAME}_output.info
    echo "LoF variants" >> ${OUTPUTDIR}/${PROJECTNAME}_output.info
    echo "$snp_one heterozygous LoF, $snp_two homozygous LoF, $snp_onetwo total of LoF variant" >> ${OUTPUTDIR}/${PROJECTNAME}_output.info
    echo "$snphetmin - $snphetmax heterozygous LoF variants per sample" >> ${OUTPUTDIR}/${PROJECTNAME}_output.info
    echo "$snphomomin - $snphomomax homozygous LoF variants per sample" >> ${OUTPUTDIR}/${PROJECTNAME}_output.info
    echo "Median of LoF variants per sample is ${snp_median}" >> ${OUTPUTDIR}/${PROJECTNAME}_output.info
    echo "Median of het. LoF variants per sample is ${het_snp_median}" >> ${OUTPUTDIR}/${PROJECTNAME}_output.info
    echo "Median of homo. LoF variants per sample is ${homo_snp_median}" >> ${OUTPUTDIR}/${PROJECTNAME}_output.info

fi