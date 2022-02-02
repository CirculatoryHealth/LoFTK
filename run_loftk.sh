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
	echoerror "- Argument #1 is path_to/filename of the configuration file."
	echoerror ""
	echoerror "An example command would be: run_loftk.sh [arg1]"
	echoerror "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
 	echo ""
	script_copyright_message
	exit 1
}

echobold "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echobold "+                                       LOFTK (Loss-of-Function ToolKit)                                +"
echobold "+                                                                                                       +"
echobold "+                                                                                                       +"
echobold "+ * Written by  : Abdulrahman Alasiri                                                                   +"
echobold "+ * E-mail      : a.i.alasiri@umcutrecht.nl                                                             +"
echobold "+ * Last update : 2022-01-31                                                                            +"
echobold "+ * Version     : 1.0.3                                                                                 +"
echobold "+                                                                                                       +"
echobold "+ * Description : This script will set some directories, and execute LoF analysis                       +"
echobold "+                 according to your specifications and using  your genotypes or sequencing data.        +"
echobold "+                                                                                                       +"
echobold "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "Today's date and time: "$(date)
TODAY=$(date +"%Y%m%d")
echo ""

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
    ANALYSISTYPE=${ANALYSIS}
    ROOTDIR=${ROOTDIR} # the root directory, e.g. /hpc/dhl_ec/aalasiri/lof/Imputation/ukb_5K/Imputation
    PROJECTNAME=${PROJECTNAME} # e.g. "ukb_5K"
    LOFTK=${LOFTOOLKIT}

    ### Insert VEP and LOFTEE to LoF_annotation.sh
    cp ${LOFTK}/src/LoF_annotation_raw.sh ${LOFTK}/LoF_annotation.sh

    if [ ${ASSEMBLY} == "GRCh37" ]; then
	sed -i -e "/#@#@VEPLOFTEEPONTER37/r ${LOFTK}/bin/VEP_LOFTEE_GRCh37.config" ${LOFTK}/LoF_annotation.sh
    elif [ ${ASSEMBLY} == "GRCh38" ]; then
	sed -i -e "/#@#@VEPLOFTEEPONTER38/r ${LOFTK}/bin/VEP_LOFTEE_GRCh38.config" ${LOFTK}/LoF_annotation.sh
    fi

    ### START running LoFTK
    if [[ ${DATA_TYPE} == "genotype" ]] && [[ ${FILE_FORMAT} == "IMPUTE2" ]]; then
	echo "LoFTK will analyze the ${DATA_TYPE} data that exist in ${FILE_FORMAT} files."
	${LOFTK}/allele_to_vcf.sh ${CONFIGURATIONFILE}
	${LOFTK}/LoF_annotation.sh ${CONFIGURATIONFILE}

    elif [[ ${DATA_TYPE} == "genotype" ]] && [[ ${FILE_FORMAT} == "VCF" ]]; then
	echo "LoFTK will analyze the ${DATA_TYPE} data that exist in ${FILE_FORMAT} files."
	${LOFTK}/LoF_annotation.sh ${CONFIGURATIONFILE}

    elif [[ ${DATA_TYPE} == "exome" || ${DATA_TYPE} == "genome" ]] && [[ ${FILE_FORMAT} == "VCF" ]]; then
        echo "LoFTK will analyze the ${DATA_TYPE} data that exist in ${FILE_FORMAT} files."
	${LOFTK}/LoF_annotation.sh ${CONFIGURATIONFILE}

    else
	echo "We only perfomr analysis of genotyped data in IMPUTE2 and VCF input files, or sequencing [exome/genome] data in VCF only"
	echo ""
	echo "Please check DATA_TYPE and FILE_FORMAT in LoF.config file."
    fi

fi
script_copyright_message
