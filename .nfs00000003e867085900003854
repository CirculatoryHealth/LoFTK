#! /bin/bash
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
    ROOTDIR=${ROOTDIR} # the root directory, e.g. /hpc/dhl_ec/aalasiri/lof/Imputation/ukb_5K/Imputation
    PROJECTNAME=${PROJECTNAME} # e.g. "ukb_5K"
    loftk=${LOFTOOLKIT}

    if [[ ${DATA_TYPE} == "genotype" ]] && [[ ${FILE_FORMAT} == "IMPUTE2" ]]; then 
	echo "LoFTK will analyze the ${DATA_TYPE} data that exist in ${FILE_FORMAT} files." 
	${loftk}/allele_to_vcf.sh ${CONFIGURATIONFILE}
	${loftk}/LoF_annotation.sh ${CONFIGURATIONFILE}
    elif [[ ${DATA_TYPE} == "genotype" ]] && [[ ${FILE_FORMAT} == "VCF" ]]; then  
	echo "LoFTK will analyze the ${DATA_TYPE} data that exist in ${FILE_FORMAT} files."
	${loftk}/LoF_annotation.sh ${CONFIGURATIONFILE}
    elif [[ ${DATA_TYPE} == "exome" ]] && [[ ${FILE_FORMAT} == "VCF" ]]; then
        echo "LoFTK will analyze the ${DATA_TYPE} data that exist in ${FILE_FORMAT} files."
	${loftk}/LoF_annotation.sh ${CONFIGURATIONFILE}
    else 
	echo "We only perfomr analysis of genotype and exome data in IMPUTE2 and VCF input files."
	echo ""
	echo "Please check DATA_TYPE and FILE_FORMAT in LoF.config file."
    fi

fi
