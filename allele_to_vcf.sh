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

script_arguments_error() {
    echoerror "Number of arguments found "$#"."
    echoerror ""
    echoerror "$1" # additional error message
    echoerror ""
    echoerror "========================================================================================================="
    echoerror "                                              OPTION LIST"
    echoerror ""
    echoerror " * Argument #1  configuration-file: LoF.config."
    echoerror ""
    echoerror " An example command would be: "
    echoerror "./run_loftk.sh [arg1]"    echoerror ""
    echoerror "========================================================================================================="
    # The wrong arguments are passed, so we'll exit the script now!
    #script_copyright_message
    exit 1
}

### START of if-else statement for the number of command-line arguments passed ###
if [[ $# -lt 1 ]]; then 
    echoerrorflash "                                     *** Oh no! Computer says no! ***"
    echo ""
    script_arguments_error "You must supply at least [1] argument when running a LoF analysis!"

else
    ### LOADING CONFIGURATION FILE
    # Loading the configuration file (please refer to the LoFToolKit-Manual for specifications of this file). 
    source "$1" # Depends on arg1.
    
    ### REQUIRED | GENERALS
    CONFIGURATIONFILE="$1" # Depends on arg1 -- but also on where it resides!!!
    
    ### MAIL SETTINGS
    #EMAIL=${YOUREMAIL}
    #MAILTYPE=${MAILSETTINGS}
    
    ### PROJECT SPECIFIC 
    ROOTDIR=${ROOTDIR} # the root directory, e.g. /hpc/dhl_ec/aalasiri/projects/test_lof
    PROJECTNAME=${PROJECTNAME} # e.g. "ukb"
    loftk=${LOFTOOLKIT}

    ### PROJECT SPECIFIC 
    ROOTDIR=${ROOTDIR} # the root directory, e.g. /hpc/dhl_ec/svanderlaan/projects/test_lof
    PROJECTNAME=${PROJECTNAME} # e.g. "WES_ukb_5K"
    haps=`ls -1 ${ROOTDIR}/*haps.gz 2>/dev/null | wc -l`
    allele_probs=`ls -1 ${ROOTDIR}/*allele_probs.gz 2>/dev/null | wc -l`
    info=`ls -1 ${ROOTDIR}/*info 2>/dev/null | wc -l`
    sample=`ls -1 ${ROOTDIR}/*sample 2>/dev/null | wc -l`

    ### Check if the directory has IMPUTE2 files [ haps.gz / allele_probs.gz / info / sample ]
    if [[ $haps == 0 || $allele_probs == 0 || $info == 0 || $sample == 0 ]]; then
    echoerrorflash "                                     *** Oh no! Computer says no! ***"
    echo ""
    script_arguments_error "When running a *** LoF analysis *** using IMPUTE2 files, you must supply 'haps.gz', 'allele_probs.gz', 'info' and 'sample' as INPUT_FILE_FORMAT!"

    elif [ ! -d ${ROOTDIR}/${PROJECTNAME}_Files_for_VCF_LoF ]; then
	echo "The project directory doesn't exist; Mr. Bourne will make it for you."
	mkdir -v ${ROOTDIR}/${PROJECTNAME}_Files_for_VCF_LoF
    else
	echo "The project directory '${ROOTDIR}/${PROJECTNAME}' already exists."
    fi
    PROJECTDIR=${ROOTDIR}/${PROJECTNAME}_Files_for_VCF_LoF # where you want stuff to be save inside the rootdir
    echo ${PROJECTNAME}

#=========================================#
#### Preparation of imputation files  #####
#=========================================#
    for chr in ${CHROMOSOMES}
    do
        echo "chr "$chr""
	if [ ! -d ${PROJECTDIR}/vcf_chr"$chr" ]; then
	    echo "The ${PROJECTDIR}/vcf_chr"$chr" directory doesn't exist; Mr. Bourne will make it for you."
	    mkdir -v ${PROJECTDIR}/vcf_chr"$chr"
	elif [ "$(ls -A ${PROJECTDIR}/vcf_chr"$chr")" ]; then
	    echo "The ${PROJECTDIR}/vcf_chr"$chr" directory already exists; Mr. Bourne will make it empity for you."
	    rm ${PROJECTDIR}/vcf_chr"$chr"/*
	else 
	    echo "The ${PROJECTDIR}/vcf_chr"$chr" directory already exists and empity."
	fi
        cp ${ROOTDIR}/*_GoNL_1KG_chr"$chr"\:*info ${PROJECTDIR}/vcf_chr"$chr"
	cp ${ROOTDIR}/*_GoNL_1KG_chr"$chr"\:*sample* ${PROJECTDIR}/vcf_chr"$chr"

### The full Mb span of the chromosome
        start=$( awk ' $1=="'$chr'" { print $2 } ' $loftk/chromosome_windows.txt )
        stop=$( awk ' $1=="'$chr'" { print $3 } ' $loftk/chromosome_windows.txt )
        while [ $start -le $stop ]
        do

### Set the upper and lower bound for this particular interval                                                      \

            lower=$start
            upper=$((start + 5))
            echo $i $chr $lower $upper

            echo "scan allele probs file"
            zcat ${ROOTDIR}/*_GoNL_1KG_chr"$chr":"$lower"-"$upper"Mb_allele_probs.gz | awk '$1~/---/' > ${PROJECTDIR}/vcf_chr"$chr"/${PROJECTNAME}_GoNL_1KG_chr"$chr":"$lower"-"$upper"Mb_allele_probs
            echo "scan haps file"
            zcat ${ROOTDIR}/*_GoNL_1KG_chr"$chr":"$lower"-"$upper"Mb_haps.gz | awk '$1!~/---/' >> ${PROJECTDIR}/vcf_chr"$chr"/${PROJECTNAME}_GoNL_1KG_chr"$chr":"$lower"-"$upper"Mb_allele_probs
            echo "sort on position"
            sort -gk3 ${PROJECTDIR}/vcf_chr"$chr"/${PROJECTNAME}_GoNL_1KG_chr"$chr":"$lower"-"$upper"Mb_allele_probs  > ${PROJECTDIR}/vcf_chr"$chr"/${PROJECTNAME}_GoNL_1KG_chr"$chr":"$lower"-"$upper"Mb_allele_probs.sorted
            mv ${PROJECTDIR}/vcf_chr"$chr"/${PROJECTNAME}_GoNL_1KG_chr"$chr":"$lower"-"$upper"Mb_allele_probs.sorted ${PROJECTDIR}/vcf_chr"$chr"/${PROJECTNAME}_GoNL_1KG_chr"$chr":"$lower"-"$upper"Mb_allele_probs
            echo "gzip final file"
            gzip ${PROJECTDIR}/vcf_chr"$chr"/${PROJECTNAME}_GoNL_1KG_chr"$chr":"$lower"-"$upper"Mb_allele_probs 

            (( start += 5 ))
        done
### This does not work with csh, manually!
        find ${PROJECTDIR}/vcf_chr*/ -name "*_GoNL_1KG_chr*Mb_allele_probs.gz" -size -70c -delete

#=========================================#
#### Preparation of imputation files  #####
#=========================================#
### Run allele_probs_to_vcf in all folders
        cp ${loftk}/allele_probs_to_vcfs.pl ${PROJECTDIR}/vcf_chr"$chr"/
	echo "#!/bin/bash" > ${PROJECTDIR}/vcf_chr"$chr"/run_allele_probs_to_vcf_${PROJECTNAME}_chr"$chr".sh

        echo "perl allele_probs_to_vcfs.pl -v" >> ${PROJECTDIR}/vcf_chr"$chr"/run_allele_probs_to_vcf_${PROJECTNAME}_chr"$chr".sh
        echo "gzip *.vcf" >> ${PROJECTDIR}/vcf_chr"$chr"/run_allele_probs_to_vcf_${PROJECTNAME}_chr"$chr".sh

	sbatch --job-name=allele_probs_to_vcf_${PROJECTNAME}_chr"$chr" -e allele_probs_to_vcf_${PROJECTNAME}_chr"$chr".errors -o allele_probs_to_vcf_${PROJECTNAME}_chr"$chr".log -t 02:00:00 -D ${PROJECTDIR}/vcf_chr"$chr" ${PROJECTDIR}/vcf_chr"$chr"/run_allele_probs_to_vcf_${PROJECTNAME}_chr"$chr".sh

        sleep 1
	
    done
    
    for chr in ${CHROMOSOMES}
    do
	prob_files=`ls -1 ${PROJECTDIR}/vcf_chr"$chr"/*allele_probs.gz 2>/dev/null | wc -l`
	vcf_files=`ls -1 ${PROJECTDIR}/vcf_chr"$chr"/*vcf.gz 2>/dev/null | wc -l`
	importantnote "Converting IMPUTE2 files to VCF files"
	while [ ${prob_files} -ne ${vcf_files} ]; do
	    importantnote "Converting IMPUTE2 files to VCF files"
	    sleep 40
	    echo "${prob_files}"
	    vcf_files=`ls -1 ${PROJECTDIR}/vcf_chr21/*vcf.gz 2>/dev/null | wc -l`
	    echo "${vcf_files}"
	done
    done


fi
