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

#script_copyright_message() {
#    echoitalic ""
#    THISYEAR=$(date +'%Y')
#    echoitalic "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
#    echoitalic "+ The MIT License (MIT)                                                                                 +"
#    echoitalic "+ Copyright (c) 2020-${THISYEAR} Abdulrahman Alasiri                                                        +"
#    echoitalic "+                                                                                                       +"
#    echoitalic "+ Permission is hereby granted, free of charge, to any person obtaining a copy of this software and     +"
#    echoitalic "+ associated documentation files (the \"Software\"), to deal in the Software without restriction,         +"
#    echoitalic "+ including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, +"
#    echoitalic "+ and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, +"
#    echoitalic "+ subject to the following conditions:                                                                  +"
#    echoitalic "+                                                                                                       +"
#    echoitalic "+ The above copyright notice and this permission notice shall be included in all copies or substantial  +"
#    echoitalic "+ portions of the Software.                                                                             +"
#    echoitalic "+                                                                                                       +"
#    echoitalic "+ THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT     +"
#    echoitalic "+ NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND                +"
#    echoitalic "+ NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES  +"
#    echoitalic "+ OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN   +"
#    echoitalic "+ CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                            +"
#    echoitalic "+                                                                                                       +"
#    echoitalic "+ Reference: http://opensource.org.                                                                     +"
#    echoitalic "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
#}

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
    #exit 1
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

    if [ ! -d ${ROOTDIR}/${PROJECTNAME}_Files_for_VCF_LoF ]; then
        echo "The project directory doesn't exist; Mr. Bourne will make it for you."
        mkdir -v ${ROOTDIR}/${PROJECTNAME}_Files_for_VCF_LoF
    else
	
        echo "The project directory '${ROOTDIR}/${PROJECTNAME}' already exists."
    fi

    for chr in ${CHROMOSOMES}
    do

	if [ ${FILE_FORMAT} == "IMPUTE2" ]; then
	    PROJECTDIR=${ROOTDIR}/${PROJECTNAME}_Files_for_VCF_LoF # where you want stuff to be save inside the rootdir
	    echo "${PROJECTNAME}"
	    VCFDIR=${PROJECTDIR}/vcf_chr"$chr"
	    echo "${VCFDIR}"
	elif [ ${FILE_FORMAT} == "VCF" ]; then
	    if [ ! -d ${ROOTDIR}/${PROJECTNAME}_Files_for_VCF_LoF/vcf_chr"$chr" ]; then
		mkdir -v ${ROOTDIR}/${PROJECTNAME}_Files_for_VCF_LoF/vcf_chr"$chr"
	    elif [ "$(ls -A ${ROOTDIR}/${PROJECTNAME}_Files_for_VCF_LoF/vcf_chr"$chr")" ]; then
		rm ${ROOTDIR}/${PROJECTNAME}_Files_for_VCF_LoF/vcf_chr"$chr"/*
	    else
		echoerrorflash "                        *** ERROR *** "
		echoerrorflash "There is an issue to create or empity this file: ${ROOTDIR}/${PROJECTNAME}_Files_for_VCF_LoF/vcf_chr"$chr". "
		echoerrorflash "                *** END OF ERROR MESSAGE *** "
		exit 1
            fi
	    
	    PROJECTDIR=${ROOTDIR}/${PROJECTNAME}_Files_for_VCF_LoF/vcf_chr"$chr"
	    cp ${ROOTDIR}/*chr"$chr"*.vcf.gz ${PROJECTDIR}
	    echo "${PROJECTNAME}"
	    VCFDIR=${PROJECTDIR}
	    echo "${VCFDIR}"
	else
            echoerrorflash "                        *** ERROR *** "
            echoerrorflash "Something went wrong. You must have to set the FILE_FORMAT in LoF_config to either IMPUTE2 or VCF. "
            echoerrorflash "                *** END OF ERROR MESSAGE *** "
            exit 1
	fi
	
    ### VEP ANALYSIS options
	
	if [ ${ASSEMBLY} == "GRCh37" ]; then
	    echo "Annotation of LoF variants using VEP along with LOFTEE plugin. Data type is ${DATA_TYPE} with ${ASSEMBLY} assembly."
            count=1	    
	    for c in ${VCFDIR}/*.vcf.gz
#	    for c in ${PROJECTDIR}/vcf_chr"$chr"/*.phased.vcf.gz #@# need change if input VCF
#	    for c in ${PROJECTDIR}/*.phased.vcf.gz

	    do
		if [ ! -e ${c%.gz}.vep.vcf.gz ]; then
                    echo $c
                    echo ${c%.gz}.vep.vcf
                    echo ${c%.vcf.gz}_${count}.sh
		    
		    echo "${VEP} --input_file $c --output_file ${c%.gz}.vep.vcf --vcf --offline --phased --assembly GRCh37 -plugin LoF,loftee_path:${LOFTEE},human_ancestor_fa:${HUMAN_ANCESTOR_FA},conservation_file:${CONSERVATION_FILE} --dir_plugins ${LOFTEE} --cache --dir_cache ${CACHEDIR} -port 3337 --force_overwrite" > ${c%.vcf.gz}_${count}.sh

		    echo "gzip $c " >> ${c%.vcf.gz}_${count}.sh
		    echo "gzip ${c%.gz}.vep.vcf " >> ${c%.vcf.gz}_${count}.sh
		    if [ ${FILE_FORMAT} == "IMPUTE2" ]; then #@# why ? YES I got it, because we have to wait for converting impute data to VCF
			qsub -S /bin/sh -N VEP_${PROJECTNAME}_chr"$chr"_$count -hold_jid allele_probs_to_vcf_${PROJECTNAME}_chr* -e VEP_${PROJECTNAME}_chr"$chr"_$count.error -o VEP_${PROJECTNAME}_chr"$chr"_$count.log -l h_rt=1:00:00 -wd ${VCFDIR} ${c%.vcf.gz}_${count}.sh
		    elif [ ${FILE_FORMAT} == "VCF" ]; then 
			qsub -S /bin/sh -N VEP_${PROJECTNAME}_chr"$chr"_$count -e VEP_${PROJECTNAME}_chr"$chr"_$count.error -o VEP_${PROJECTNAME}_chr"$chr"_$count.log -l h_rt=1:00:00 -wd ${VCFDIR} ${c%.vcf.gz}_${count}.sh
		    else
			echoerrorflash "                        *** ERROR *** "
			echoerrorflash "Something went wrong. You must have to set the FILE_FORMAT in LoF_config to either IMPUTE2 or VCF. "
			echoerrorflash "                *** END OF ERROR MESSAGE *** "
			exit 1
                    fi
		    
		    sleep 5
		    ((count++))
		fi # if vep.vcf.gz already there

	    done # for c 
	       
	
	elif [ ${ASSEMBLY} == "GRCh38" ]; then
	    echo "Annotation of LoF variants using VEP along with LOFTEE plugin. Data type is ${DATA_TYPE} with ${ASSEMBLY} assembly."
            count=1
            for c in ${VCFDIR}/*.vcf.gz
            do
                if [ ! -e ${c%.gz}.vep.vcf.gz ]; then
                    echo $c
                    echo ${c%.gz}.vep.vcf
                    echo ${c%.vcf.gz}_${count}.sh
		    
                    echo "${VEP} --input_file $c --output_file ${c%.gz}.vep.vcf --vcf --offline --phased --assembly GRCh38 -plugin LoF,loftee_path:${LOFTEE},human_ancestor_fa:${HUMAN_ANCESTOR_FA},conservation_file:${CONSERVATION_FILE},gerp_bigwig:${GERP_BIGWIG} --dir_plugins ${LOFTEE} --cache --dir_cache ${CACHEDIR} --force_overwrite" > ${c%.vcf.gz}_${count}.sh
		    echo "gzip $c " >> ${c%.vcf.gz}_${count}.sh
                    echo "gzip ${c%.gz}.vep.vcf " >> ${c%.vcf.gz}_${count}.sh
                    qsub -S /bin/sh -N VEP_${PROJECTNAME}_chr"$chr"_$count -e VEP_${PROJECTNAME}_chr"$chr"_$count.error -o VEP_${PROJECTNAME}_chr"$chr"_$count.log -l h_rt=1:00:00 -wd ${VCFDIR} ${c%.vcf.gz}_${count}.sh
                    sleep 5
                    ((count++))
                fi # if vep.vcf.gz already there
            done # for c
	else
	    echoerrorflash "                        *** ERROR *** "
	    echoerrorflash "Something went wrong. You must have to set the Assembly version in LoF_config to either GRCh37 or GRCh38. "
	fi # assembly
    done # chr

    OUTPUTDIR=${ROOTDIR}/${PROJECTNAME}_LoF_output
    if [ ! -d ${OUTPUTDIR} ]; then
        echo "The OUTPUT directory doesn't exist; Mr. Bourne will make it for you."
        mkdir -v ${OUTPUTDIR}
    elif [ "$(ls -A "${OUTPUTDIR}")" ]; then 
	rm ${OUTPUTDIR}/*
	echo "The OUTPUT directory '${ROOTDIR}/${PROJECTNAME}_LoF_output' already exists and cleaned."
    else
        echo "The OUTPUT directory '${ROOTDIR}/${PROJECTNAME}_LoF_output' already exists."
    fi

#    for chr in $(seq 19 21)
#    do
#	vcf_files=`ls -1 ${VCFDIR}/*vcf.gz 2>/dev/null | wc -l`
#	vep_vcf_files=`ls -1 ${VCFDIR}/*vep.vcf.gz 2>/dev/null | wc -l`
#	importantnote "Converting IMPUTE2 files to VCF files"
#	while [ ${vcf_files} -ne ${vep_vcf_files} ]; do
#           importantnote "LoF annotation using VEP along with LOFTEE"
#            sleep 40
#           echo "${prob_files}"
#            vcf_files=`ls -1 ${PROJECTDIR}/vcf_chr21/*vcf.gz 2>/dev/null | wc -l`
#           echo "${vcf_files}"
#        done
#    done

### STEP 2 ###

    if [ ${ASSEMBLY} == "GRCh37" ]; then
            echo "Genes list with high-confidence loss-of-function mutations."
	    
#======================================#
#### Genes containing LoF variants #####

#======================================#
	    echo "mv ${ROOTDIR}/${PROJECTNAME}_Files_for_VCF_LoF/vcf_chr*/*vep.vcf.gz ${OUTPUTDIR}" > ${OUTPUTDIR}/run_vep_to_lof_gene.sh
	    
	    if [ ${FILE_FORMAT} == "IMPUTE2" ]; then
		cp ${loftk}/vep_vcf_to_gene_lofs.pl ${OUTPUTDIR}
		echo "sleep 15" >> ${OUTPUTDIR}/run_vep_to_lof_gene.sh
		echo "${PERL} vep_vcf_to_gene_lofs.pl -v -o ${PROJECTNAME}_gene.lof" >> ${OUTPUTDIR}/run_vep_to_lof_gene.sh
	    elif [ ${FILE_FORMAT} == "VCF" ]; then 
		cp ${loftk}/vep_vcf_to_gene_lofs_vcf.pl ${OUTPUTDIR}
		echo "sleep 15" >> ${OUTPUTDIR}/run_vep_to_lof_gene.sh
		echo "${PERL} vep_vcf_to_gene_lofs_vcf.pl -v -o ${PROJECTNAME}_gene.lof" >> ${OUTPUTDIR}/run_vep_to_lof_gene.sh
	    else
                echoerrorflash "                        *** ERROR *** "
                echoerrorflash "Something went wrong. You must have to set the FILE_FORMAT in LoF_config to either IMPUTE2 or VCF. "
                echoerrorflash "                *** END OF ERROR MESSAGE *** "
                exit 1
            fi

	    echo "${PERL} ${loftk}/gene_lofs_to_gene_lof_counts.pl ${OUTPUTDIR}/${PROJECTNAME}_gene.lof ${OUTPUTDIR}/${PROJECTNAME}_gene.counts" >> ${OUTPUTDIR}/run_vep_to_lof_gene.sh
	    echo "${PERL} ${loftk}/gene_lofs_to_lof_snps.pl ${OUTPUTDIR}/${PROJECTNAME}_gene.lof ${OUTPUTDIR}/${PROJECTNAME}_gene.lof.snps" >> ${OUTPUTDIR}/run_vep_to_lof_gene.sh
	    
	    qsub -S /bin/sh -N LoF_gene_${PROJECTNAME} -hold_jid VEP_${PROJECTNAME}_chr* -e LoF_gene_${PROJECTNAME}.error -o LoF_gene_${PROJECTNAME}.log -l h_rt=1:00:00 -wd ${OUTPUTDIR} ${OUTPUTDIR}/run_vep_to_lof_gene.sh

#=====================#
#### LoF variants #####
#=====================#
	    echo "sleep 15" > ${OUTPUTDIR}/run_vep_to_lof_snp.sh
	    if [ ${FILE_FORMAT} == "IMPUTE2" ]; then
		cp ${loftk}/vep_vcf_to_snp_lofs.pl ${OUTPUTDIR}
		echo "${PERL} vep_vcf_to_snp_lofs.pl -v -o ${PROJECTNAME}_snp.lof" >> ${OUTPUTDIR}/run_vep_to_lof_snp.sh
	    elif [ ${FILE_FORMAT} == "VCF" ]; then
                cp ${loftk}/vep_vcf_to_snp_lofs_vcf.pl ${OUTPUTDIR}
		echo "${PERL} vep_vcf_to_snp_lofs_vcf.pl -v -o ${PROJECTNAME}_snp.lof" >> ${OUTPUTDIR}/run_vep_to_lof_snp.sh
            else
                echoerrorflash "                        *** ERROR *** "
                echoerrorflash "Something went wrong. You must have to set the FILE_FORMAT in LoF_config to either IMPUTE2 or VCF. "
                echoerrorflash "                *** END OF ERROR MESSAGE *** "
                exit 1
            fi
	    
	    echo "${PERL} ${loftk}/snp_lofs_to_snp_lof_counts.pl ${OUTPUTDIR}/${PROJECTNAME}_snp.lof ${OUTPUTDIR}/${PROJECTNAME}_snp.counts" >> ${OUTPUTDIR}/run_vep_to_lof_snp.sh
	    qsub -S /bin/sh -N LoF_snp_${PROJECTNAME} -hold_jid VEP_${PROJECTNAME}_chr* -e LoF_snp_${PROJECTNAME}.error -o LoF_snp_${PROJECTNAME}.log -l h_rt=1:00:00 -wd ${OUTPUTDIR} ${OUTPUTDIR}/run_vep_to_lof_snp.sh
	    

    elif [ ${ASSEMBLY} == "GRCh38" ]; then
            echo "Genes list with high-confidence loss-of-function mutations."
	    
#======================================#
#### Genes containing LoF variants #####
#======================================#

	    echo "mv ${ROOTDIR}/${PROJECTNAME}_Files_for_VCF_LoF/vcf_chr*/*vep.vcf.gz ${OUTPUTDIR}" > ${OUTPUTDIR}/run_vep_to_lof_gene.sh
	    echo "sleep 15" >> ${OUTPUTDIR}/run_vep_to_lof_gene.sh

	    if [ ${FILE_FORMAT} == "IMPUTE2" ]; then
		cp ${loftk}/vep_vcf_to_gene_lofs.pl ${OUTPUTDIR}

                echo "${PERL} vep_vcf_to_gene_lofs.pl -v -o ${PROJECTNAME}_gene.lof" >> ${OUTPUTDIR}/run_vep_to_lof_gene.sh
            elif [ ${FILE_FORMAT} == "VCF" ]; then
		cp ${loftk}/vep_vcf_to_gene_lofs_vcf.pl ${OUTPUTDIR}
                echo "${PERL} vep_vcf_to_gene_lofs_vcf.pl -v -o ${PROJECTNAME}_gene.lof" >> ${OUTPUTDIR}/run_vep_to_lof_gene.sh
            else
                echoerrorflash "                        *** ERROR *** "
                echoerrorflash "Something went wrong. You must have to set the FILE_FORMAT in LoF_config to either IMPUTE2 or VCF. "
                echoerrorflash "                *** END OF ERROR MESSAGE *** "
                exit 1
            fi
	       
            echo "${PERL} ${loftk}/gene_lofs_to_gene_lof_counts.pl ${OUTPUTDIR}/${PROJECTNAME}_gene.lof ${OUTPUTDIR}/${PROJECTNAME}_gene.counts" >> ${OUTPUTDIR}/run_vep_to_lof_gene.sh
            echo "${PERL} ${loftk}/gene_lofs_to_lof_snps.pl ${OUTPUTDIR}/${PROJECTNAME}_gene.lof ${OUTPUTDIR}/${PROJECTNAME}_gene.lof.snps" >> ${OUTPUTDIR}/run_vep_to_lof_gene.sh
	    
            qsub -S /bin/sh -N LoF_gene_${PROJECTNAME} -hold_jid VEP_${PROJECTNAME}_chr* -e LoF_gene_${PROJECTNAME}.error -o LoF_gene_${PROJECTNAME}.log -l h_rt=1:00:00 -wd ${OUTPUTDIR} ${OUTPUTDIR}/run_vep_to_lof_gene.sh

#=====================#
#### LoF variants #####
#=====================#
	    echo "sleep 15" > ${OUTPUTDIR}/run_vep_to_lof_snp.sh
            
	    if [ ${FILE_FORMAT} == "IMPUTE2" ]; then
		cp ${loftk}/vep_vcf_to_snp_lofs.pl ${OUTPUTDIR}
                echo "${PERL} vep_vcf_to_snp_lofs.pl -v -o ${PROJECTNAME}_snp.lof" >> ${OUTPUTDIR}/run_vep_to_lof_snp.sh
            elif [ ${FILE_FORMAT} == "VCF" ]; then
		cp ${loftk}/vep_vcf_to_snp_lofs_vcf.pl ${OUTPUTDIR}
                echo "${PERL} vep_vcf_to_snp_lofs_vcf.pl -v -o ${PROJECTNAME}_snp.lof" >> ${OUTPUTDIR}/run_vep_to_lof_snp.sh
            else
                echoerrorflash "                        *** ERROR *** "
                echoerrorflash "Something went wrong. You must have to set the FILE_FORMAT in LoF_config to either IMPUTE2 or VCF. "
                echoerrorflash "                *** END OF ERROR MESSAGE *** "
                exit 1
            fi

	    echo "${PERL} ${loftk}/snp_lofs_to_snp_lof_counts.pl ${OUTPUTDIR}/${PROJECTNAME}_snp.lof ${OUTPUTDIR}/${PROJECTNAME}_snp.counts" >> ${OUTPUTDIR}/run_vep_to_lof_snp.sh
	    qsub -S /bin/sh -N LoF_snp_${PROJECTNAME} -hold_jid VEP_${PROJECTNAME}_chr* -e LoF_snp_${PROJECTNAME}.error -o LoF_snp_${PROJECTNAME}.log -l h_rt=1:00:00 -wd ${OUTPUTDIR} ${OUTPUTDIR}/run_vep_to_lof_snp.sh
    

    else
	echoerrorflash "                        *** ERROR *** "
        echoerrorflash "Something went wrong. You must have to set ASSEMBLY in LoF.config. "
        echoerrorflash "                *** END OF ERROR MESSAGE *** "
        exit 1
    fi # end of STEP 2
    
    
### STEP 3 ###
#============================================================================#
#### Calculate statistics samples,SNPs, transcripts and genes per cohort #####
#============================================================================#
    gene_count="${OUTPUTDIR}/${PROJECTNAME}_gene.counts"
    snp_count="${OUTPUTDIR}/${PROJECTNAME}_snp.counts"
    while [[ ! -r "${gene_count}" ]] ; do
	sleep 30 
    done
    
    lof_gene="${OUTPUTDIR}/${PROJECTNAME}_gene.counts"
    lof_snp="${OUTPUTDIR}/${PROJECTNAME}_snp.counts"
    
    ##
    onetwo=`cut -f 5- ${lof_gene} | tail -n +2 | awk '$0~/1/ || $0~/2/' | wc -l`
    one=`cut -f 5- ${lof_gene} | tail -n +2 | awk '$0~/1/' | wc -l `
    two=`cut -f 5- ${lof_gene} | tail -n +2 | awk '$0~/2/' | wc -l `
    genehomomin=`cat ${lof_gene} | bash $loftk/transpose.sh | tail -n +5 | cut -d' ' -f 2- | sed 's/[^2]//g' | awk '{ print length }' | sort -g | head -1`
    genehomomax=`cat ${lof_gene} | bash $loftk/transpose.sh | tail -n +5 | cut -d' ' -f 2- | sed 's/[^2]//g' | awk '{ print length }' | sort -gr | head -1`
    genehetmin=`cat ${lof_gene} | bash $loftk/transpose.sh | tail -n +5 | cut -d' ' -f 2- | sed 's/[^1]//g' | awk '{ print length }' | sort -g | head -1`
    genehetmax=`cat ${lof_gene} | bash $loftk/transpose.sh | tail -n +5 | cut -d' ' -f 2- | sed 's/[^1]//g' | awk '{ print length }' | sort -gr | head -1`

    echo "Cohort ${PROJECTNAME}" > ${OUTPUTDIR}/${PROJECTNAME}_output.info
    echo "" >> ${OUTPUTDIR}/${PROJECTNAME}_output.info
    echo "LoF genes contain LoF variants" >> ${OUTPUTDIR}/${PROJECTNAME}_output.info
    echo "$one genes contain heterozygous LoF, $two genes contain homozygous LoF, $onetwo as a total of genes contain LoF variant" >> ${OUTPUTDIR}/${PROJECTNAME}_output.info
    echo "$genehetmin - $genehetmax genes with heterozygous LoF variants per sample" >> ${OUTPUTDIR}/${PROJECTNAME}_output.info
    echo "$genehomomin - $genehomomax genes with homozygous LoF variants per sample" >> ${OUTPUTDIR}/${PROJECTNAME}_output.info

    ## LoF variants
    while [[ ! -r "${snp_count}" ]] ; do
        sleep 30
    done

    onetwo=`cut -f 5- ${lof_snp} | tail -n +2 | awk '$0~/1/ || $0~/2/' | wc -l`
    one=`cut -f 5- ${lof_snp} | tail -n +2 | awk '$0~/1/' | wc -l `
    two=`cut -f 5- ${lof_snp} | tail -n +2 | awk '$0~/2/' | wc -l `
    genehomomin=`cat ${lof_snp} | bash $loftk/transpose.sh | tail -n +5 | cut -d' ' -f 2- | sed 's/[^2]//g' | awk '{ print length }' | sort -g | head -1`
    genehomomax=`cat ${lof_snp} | bash $loftk/transpose.sh | tail -n +5 | cut -d' ' -f 2- | sed 's/[^2]//g' | awk '{ print length }' | sort -gr | head -1`
    genehetmin=`cat ${lof_snp} | bash $loftk/transpose.sh | tail -n +5 | cut -d' ' -f 2- | sed 's/[^1]//g' | awk '{ print length }' | sort -g | head -1`
    genehetmax=`cat ${lof_snp} | bash $loftk/transpose.sh | tail -n +5 | cut -d' ' -f 2- | sed 's/[^1]//g' | awk '{ print length }' | sort -gr | head -1`

    echo "" >> ${OUTPUTDIR}/${PROJECTNAME}_output.info
    echo "LoF variants" >> ${OUTPUTDIR}/${PROJECTNAME}_output.info
    echo "$one heterozygous LoF, $two homozygous LoF, $onetwo total of LoF variant" >> ${OUTPUTDIR}/${PROJECTNAME}_output.info
    echo "$genehetmin - $genehetmax heterozygous LoF variants per sample" >> ${OUTPUTDIR}/${PROJECTNAME}_output.info
    echo "$genehomomin - $genehomomax homozygous LoF variants per sample" >> ${OUTPUTDIR}/${PROJECTNAME}_output.info
    

fi   # For [$# -lt 1]
