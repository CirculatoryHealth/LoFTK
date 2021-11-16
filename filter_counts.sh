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
        echo "+ Copyright (c) 2021-${THISYEAR} Abdulrahman Alasiri                                                           +"
        echo "+                                                                                                       +"
        echo "+ Copyright (c) 2020 University Medical Center Utrecht                                                  +"
        echo "+                                                                                                       +"
        echo "+ Creative Commons Attribution Share Alike 4.0 International                                            +"
        echo "+                                                                                                       +"
        echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
}
script_arguments_error() {
        echoerror "$1" # Additional message
        echoerror "- Argument #1 is path_to/[snp/gene].counts file."
        echoerror ""
	echoerror "- Argument #2 is path_to/sample_IDs file that to keep in new file."
        echoerror ""
        echoerror "- Argument #3 is to clarify input counts file either for snps or genes LoF counts file."
        echoerror ""
	echoerror "- Argument #4 is path_to/OUTPUT.counts file."
        echoerror ""
        echoerror "An example command would be: filter_counts.sh [arg1] [arg2] [arg3] [arg4]."
	echoerror "                             filter_counts.sh [\$(pwd)/File_gene.counts] [sample_IDs_keep_list.txt] [genes] [\$(pwd)/OUTPUT_gene.counts]."
        echoerror "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
        echo ""
        script_copyright_message
        exit 1
}

echobold "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echobold "+                                       LoFTK (Loss-of-Function ToolKit)                                +"
echobold "+                                            Filtering counts file                                      +"
echobold "+                                                                                                       +"
echobold "+ * Written by  : Abdulrahman Alasiri                                                                   +"
echobold "+ * E-mail      : a.i.alasiri@umcutrecht.nl                                                             +"
echobold "+ * Last update : 2021-08-18                                                                            +"
echobold "+ * Version     : 1.0.1                                                                                 +"
echobold "+                                                                                                       +"
echobold "+ * Description : This script will filter samples in [snp/gene].counts file, and generates new counts   +"
echobold "+                 file according to your interested sample IDs list.                                    +"
echobold "+                                                                                                       +"
echobold "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "Today's date and time: "$(date)
TODAY=$(date +"%Y%m%d")
echo ""

### START of if-else statement for the number of command-line arguments passed ###
if [[ $# -lt 3 ]]; then
    echoerrorflash "                                     *** Oh no! Computer says no! ***"
    echo ""
    script_arguments_error "You must supply at least [3] argument when running a counts file filteration!"
    echo ""

else
    ### REQUIRED | GENERALS
    COUNTS_FILE="$1"
    SAMPLE_LIST="$2"
    COUNTS_TYPE="$3"
    OUTPUT="$4"

    ### TOOLS
    scriptdir=`dirname "$BASH_SOURCE"`
    GENE_FILT=${scriptdir}/bin/filter_gene_counts.pl
    SNP_FILT=${scriptdir}/bin/filter_snp_counts.pl

    ## GENE.COUNTS
    echo ""
    echoerrorflash ""
    if [[ ${COUNTS_TYPE} == "genes" ]]; then
        ${GENE_FILT} ${SAMPLE_LIST} ${COUNTS_FILE} > ${OUTPUT}.gene.temp
        SAMPE_SIZE=$(head -1 ${OUTPUT}.gene.temp | cut -f3- | wc -w)

        ## Claculate 1-copy & 2-copy frequencies and combine all data
        echo ""
        echoerrorflash "Claculation of 1-copy and 2-copy LoF genes frequency"
        paste <(cut -f1-2 ${OUTPUT}.gene.temp) <(tail -n +2 ${OUTPUT}.gene.temp | cut -f3- | sed 's/[^1]//g' | awk -v sz=$SAMPE_SIZE '{ print length/sz }' | sed "1i1_copy_LoF_frequency") <(tail -n +2 ${OUTPUT}.gene.temp | cut -f3- | sed 's/[^2]//g' | awk -v sz=$SAMPE_SIZE '{ print length/sz }' | sed "1i2_copy_LoF_frequency") <(cut -f3- ${OUTPUT}.gene.temp) | awk '$3 != 0 || $4 != 0 {print $0}'  > ${OUTPUT}
        rm ${OUTPUT}.gene.temp
        echobold "DONE!"

    ## SNP.COUNTS
    elif [[ ${COUNTS_TYPE} == "snps" ]]; then
        echo ""
        echoerrorflash "Filteration will be applied on snp.counts file"
        ${SNP_FILT} ${SAMPLE_LIST} ${COUNTS_FILE} > ${OUTPUT}.snp.temp
        SAMPE_SIZE=$(head -1 ${OUTPUT}.snp.temp | cut -f6- | wc -w)

        ## Claculate heterozygotes & homozygotes frequencies and combine all data
        echo ""
        echoerrorflash "Claculation of heterozygotes & homozygotes LoF genes frequency"
        paste <(cut -f1-5 ${OUTPUT}.snp.temp) <(tail -n +2 ${OUTPUT}.snp.temp | cut -f6- | sed 's/[^1]//g' | awk -v sz=$SAMPE_SIZE '{ print length/sz }' | sed "1iheterozygous_LoF_frequency") <(tail -n +2 ${OUTPUT}.snp.temp | cut -f6- | sed 's/[^2]//g' | awk -v sz=$SAMPE_SIZE '{ print length/sz }' | sed "1ihomozygous_LoF_frequency") <(cut -f6- ${OUTPUT}.snp.temp) | awk '$6 != 0 || $7 != 0 {print $0}' > ${OUTPUT}
        rm ${OUTPUT}.snp.temp
        echo ""
        echobold "DONE!"

    else
        echoerrorflash "                                     *** Oh no! Computer says no! ***"
        echo ""
        script_arguments_error "Please provide either [genes or snps] in the 3rd arguments! "
        echo ""

    fi


fi
