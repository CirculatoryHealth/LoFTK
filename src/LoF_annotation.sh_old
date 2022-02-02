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
	echoerror "An example command would be: run_loftk.sh [arg1]"
	echoerror "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
 	echo ""
	script_copyright_message
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

    ### --- SLURM SETTINGS --- ###
     ## LoF annotation (VEP, LOFTEE).
    QUEUE_ANNOTATION=${QUEUE_ANNOTATION_CONFIG}
    VMEM_ANNOTATION=${VMEM_ANNOTATION_CONFIG}
    ## Calculation of LoF genes.
    QUEUE_LOF_GENE=${QUEUE_LOF_GENE_CONFIG}
    VMEM_LOF_GENE=${VMEM_LOF_GENE_CONFIG}
    ## Calculation of LoF variants.
    QUEUE_LOF_SNP=${QUEUE_LOF_SNP_CONFIG}
    VMEM_LOF_SNP=${VMEM_LOF_SNP_CONFIG}
    ## Statisctical Description
    QUEUE_STAT_DESC=${QUEUE_STAT_DESC_CONFIG}
    VMEM_STAT_DESC=${VMEM_STAT_DESC_CONFIG}

    ### MAIL SETTINGS
    EMAIL=${YOUREMAIL}
    MAILTYPE=${MAILSETTINGS}

    ### PROJECT SPECIFIC
    ROOTDIR=${ROOTDIR} # the root directory, e.g. /hpc/dhl_ec/aalasiri/projects/test_lof
    PROJECTNAME=${PROJECTNAME} # e.g. "ukb"
    ENSEMBL=${ENSEMBL}
    LOFTK=${LOFTOOLKIT}
    USERNAME=$(whoami)
    PROB2VCF="probs_to_vcf_${PROJECTNAME}"
    VEP_ANNOTATION="VEP_${PROJECTNAME}_"
    TRANSPOSE=${LOFTK}/bin/transpose.pl

    ### Set up directory for VCF files
    if [ ! -d ${ROOTDIR}/${PROJECTNAME}_Files_for_VCF_LoF ]; then
        echo "The project directory doesn't exist; Mr. Bourne will make it for you."
        mkdir -v ${ROOTDIR}/${PROJECTNAME}_Files_for_VCF_LoF
    else

        echo "The project directory '${ROOTDIR}/${PROJECTNAME}' already exists."
    fi

    ### Annotation of LoF
    for chr in ${CHROMOSOMES}
    do
	echobold "chr ${chr}"
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
		echoerrorflash "This directory was empity from the beginning: ${ROOTDIR}/${PROJECTNAME}_Files_for_VCF_LoF/vcf_chr"$chr". "
            fi

	    PROJECTDIR=${ROOTDIR}/${PROJECTNAME}_Files_for_VCF_LoF/vcf_chr"$chr"
	    GET_VCF=$(ls ${ROOTDIR}/*.vcf.gz | head -1)
	    VCF_NAME=$(echo "${GET_VCF/chr[0-9][0-9]/chr${chr}}")
	    cp ${VCF_NAME} ${PROJECTDIR}

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
	    do
		if [ ! -e ${c%%.gz}.vep.vcf.gz ]; then
                    echo $c
                    echo ${c%%.gz}.vep.vcf
                    echo ${c%%.vcf.gz}_${count}.sh

		    echo "#!/bin/bash" > ${c%%.vcf.gz}_${count}.sh
		    echo "${VEP} --input_file $c --output_file ${c%.gz}.vep.vcf.gz --vcf --compress_output gzip --offline --phased --assembly GRCh37 --protein --canonical -plugin LoF,loftee_path:${LOFTEE},human_ancestor_fa:${HUMAN_ANCESTOR_FA},conservation_file:${CONSERVATION_FILE} --dir_plugins ${LOFTEE} --cache --dir_cache ${CACHEDIR} -port 3337 --force_overwrite" >> ${c%%.vcf.gz}_${count}.sh

		    echo "rm $c " >> ${c%.vcf.gz}_${count}.sh
#		    echo "gzip ${c%.gz}.vep.vcf " >> ${c%%.vcf.gz}_${count}.sh
		    if [ ${FILE_FORMAT} == "IMPUTE2" ]; then #@# why ? YES I got it, because we have to wait for converting impute data to VCF

			sbatch --job-name=VEP_${PROJECTNAME}_chr"$chr"_$count -e VEP_${PROJECTNAME}_chr"$chr"_$count.error -o VEP_${PROJECTNAME}_chr"$chr"_$count.log -t ${QUEUE_ANNOTATION} --mem=${VMEM_ANNOTATION} --mail-user=${EMAIL} --mail-type=${MAILTYPE} -D ${VCFDIR} ${c%%.vcf.gz}_${count}.sh


		    elif [ ${FILE_FORMAT} == "VCF" ]; then
			sbatch --job-name=VEP_${PROJECTNAME}_chr"$chr"_$count -e VEP_${PROJECTNAME}_chr"$chr"_$count.error -o VEP_${PROJECTNAME}_chr"$chr"_$count.log -t ${QUEUE_ANNOTATION} --mem=${VMEM_ANNOTATION} --mail-user=${EMAIL} --mail-type=${MAILTYPE} -D ${VCFDIR} ${c%%.vcf.gz}_${count}.sh

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

		    echo "#!/bin/bash" > ${c%%.vcf.gz}_${count}.sh
                    echo "${VEP} --input_file $c --output_file ${c%.gz}.vep.vcf.gz --vcf --compress_output gzip --offline --phased --assembly GRCh38 --protein --canonical -plugin LoF,loftee_path:${LOFTEE},human_ancestor_fa:${HUMAN_ANCESTOR_FA},conservation_file:${CONSERVATION_FILE},gerp_bigwig:${GERP_BIGWIG} --dir_plugins ${LOFTEE} --cache --dir_cache ${CACHEDIR} --force_overwrite" >> ${c%.vcf.gz}_${count}.sh

		    echo "rm $c " >> ${c%.vcf.gz}_${count}.sh
#                    echo "gzip ${c%.gz}.vep.vcf " >> ${c%.vcf.gz}_${count}.sh

		    sbatch --job-name=VEP_${PROJECTNAME}_chr"$chr"_$count -e VEP_${PROJECTNAME}_chr"$chr"_$count.error -o VEP_${PROJECTNAME}_chr"$chr"_$count.log -t ${QUEUE_ANNOTATION} --mem=${VMEM_ANNOTATION} --mail-user=${EMAIL} -c 6 --mail-type=${MAILTYPE} -D ${VCFDIR} ${c%%.vcf.gz}_${count}.sh

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

### STEP 2 ###

    if [ ${ASSEMBLY} == "GRCh37" ]; then
            echo "Collect genes with high-confidence loss-of-function variants."

#======================================#
#### Genes containing LoF variants #####

#======================================#
	    echo "#!/bin/bash" > ${OUTPUTDIR}/run_vep_to_lof_gene.sh
	    echo "mv ${ROOTDIR}/${PROJECTNAME}_Files_for_VCF_LoF/vcf_chr*/*vep.vcf.gz ${OUTPUTDIR}" >> ${OUTPUTDIR}/run_vep_to_lof_gene.sh

	    if [ ${FILE_FORMAT} == "IMPUTE2" ]; then
		cp ${LOFTK}/src/vep_vcf_to_gene_lofs.pl ${OUTPUTDIR}
		echo "sleep 15" >> ${OUTPUTDIR}/run_vep_to_lof_gene.sh
		echo "${PERL} vep_vcf_to_gene_lofs.pl -v -o ${PROJECTNAME}_gene.lof" >> ${OUTPUTDIR}/run_vep_to_lof_gene.sh
	    elif [ ${FILE_FORMAT} == "VCF" ]; then
		cp ${LOFTK}/src/vep_vcf_to_gene_lofs_vcf.pl ${OUTPUTDIR}
		echo "sleep 15" >> ${OUTPUTDIR}/run_vep_to_lof_gene.sh
		echo "${PERL} vep_vcf_to_gene_lofs_vcf.pl -v -o ${PROJECTNAME}_gene.lof" >> ${OUTPUTDIR}/run_vep_to_lof_gene.sh
	    else
                echoerrorflash "                        *** ERROR *** "
                echoerrorflash "Something went wrong. You must have to set the FILE_FORMAT in LoF_config to either IMPUTE2 or VCF. "
                echoerrorflash "                *** END OF ERROR MESSAGE *** "
                exit 1
            fi

	    echo "${PERL} ${LOFTK}/src/gene_lofs_to_gene_lof_counts.pl ${OUTPUTDIR}/${PROJECTNAME}_gene.lof ${OUTPUTDIR}/${PROJECTNAME}_gene.counts" >> ${OUTPUTDIR}/run_vep_to_lof_gene.sh
	    echo "${PERL} ${LOFTK}/src/gene_lofs_to_lof_snps.pl ${OUTPUTDIR}/${PROJECTNAME}_gene.lof ${OUTPUTDIR}/${PROJECTNAME}_gene.lof.snps" >> ${OUTPUTDIR}/run_vep_to_lof_gene.sh

	    VEPDEPENDACY=$(sacct --format="JobID,JobName%30,State" | awk -v vepann=${VEP_ANNOTATION} '$2 ~ vepann {print $0}' | awk '$3 == "RUNNING" || $3 == "PENDING" {print $1}' | ${TRANSPOSE} | sed 's/\t/,/g')
            echo "Job ID for LoF_gene_${PROJECTNAME}: ${VEPDEPENDACY}"

	    sbatch --job-name=LoF_gene_${PROJECTNAME} --dependency=afterok:${VEPDEPENDACY} -e LoF_gene_${PROJECTNAME}.error -o LoF_gene_${PROJECTNAME}.log -t ${QUEUE_LOF_GENE} --mem=${VMEM_LOF_GENE} --mail-user=${EMAIL} --mail-type=${MAILTYPE} -D ${OUTPUTDIR} ${OUTPUTDIR}/run_vep_to_lof_gene.sh


#=====================#
#### LoF variants #####
#=====================#
	    echo "#!/bin/bash" > ${OUTPUTDIR}/run_vep_to_lof_snp.sh
	    echo "sleep 50" >> ${OUTPUTDIR}/run_vep_to_lof_snp.sh
	    if [ ${FILE_FORMAT} == "IMPUTE2" ]; then
		cp ${LOFTK}/src/vep_vcf_to_snp_lofs.pl ${OUTPUTDIR}
		echo "${PERL} vep_vcf_to_snp_lofs.pl -v -o ${PROJECTNAME}_snp.lof" >> ${OUTPUTDIR}/run_vep_to_lof_snp.sh
	    elif [ ${FILE_FORMAT} == "VCF" ]; then
                cp ${LOFTK}/src/vep_vcf_to_snp_lofs_vcf.pl ${OUTPUTDIR}
		echo "${PERL} vep_vcf_to_snp_lofs_vcf.pl -v -o ${PROJECTNAME}_snp.lof" >> ${OUTPUTDIR}/run_vep_to_lof_snp.sh
            else
                echoerrorflash "                        *** ERROR *** "
                echoerrorflash "Something went wrong. You must have to set the FILE_FORMAT in LoF_config to either IMPUTE2 or VCF. "
                echoerrorflash "                *** END OF ERROR MESSAGE *** "
                exit 1
            fi

	    echo "${PERL} ${LOFTK}/src/snp_lofs_to_snp_lof_counts.pl ${OUTPUTDIR}/${PROJECTNAME}_snp.lof ${OUTPUTDIR}/${PROJECTNAME}_snp.counts" >> ${OUTPUTDIR}/run_vep_to_lof_snp.sh

            VEPDEPENDACY=$(sacct --format="JobID,JobName%30,State" | awk -v vepann=${VEP_ANNOTATION} '$2 ~ vepann {print $0}' | awk '$3 == "RUNNING" || $3 == "PENDING" {print $1}' | ${TRANSPOSE} | sed 's/\t/,/g')
	    echo "Job ID for LoF_snp_${PROJECTNAME}: ${VEPDEPENDACY}"

	    sbatch --job-name=LoF_snp_${PROJECTNAME} --dependency=afterok:${VEPDEPENDACY} -e LoF_snp_${PROJECTNAME}.error -o LoF_snp_${PROJECTNAME}.log -t ${QUEUE_LOF_SNP} --mem=${VMEM_LOF_SNP} --mail-user=${EMAIL} --mail-type=${MAILTYPE} -D ${OUTPUTDIR} ${OUTPUTDIR}/run_vep_to_lof_snp.sh

    elif [ ${ASSEMBLY} == "GRCh38" ]; then
            echo "Collect genes with high-confidence loss-of-function variants."

#======================================#
#### Genes containing LoF variants #####
#======================================#
	    echo "Collect high-confidence loss-of-function variants."
	    echo "#!/bin/bash" > ${OUTPUTDIR}/run_vep_to_lof_gene.sh
	    echo "mv ${ROOTDIR}/${PROJECTNAME}_Files_for_VCF_LoF/vcf_chr*/*vep.vcf.gz ${OUTPUTDIR}" >> ${OUTPUTDIR}/run_vep_to_lof_gene.sh
	    echo "sleep 15" >> ${OUTPUTDIR}/run_vep_to_lof_gene.sh

	    if [ ${FILE_FORMAT} == "IMPUTE2" ]; then
		cp ${LOFTK}/src/vep_vcf_to_gene_lofs.pl ${OUTPUTDIR}

                echo "${PERL} vep_vcf_to_gene_lofs.pl -v -o ${PROJECTNAME}_gene.lof" >> ${OUTPUTDIR}/run_vep_to_lof_gene.sh
            elif [ ${FILE_FORMAT} == "VCF" ]; then
		cp ${LOFTK}/src/vep_vcf_to_gene_lofs_vcf.pl ${OUTPUTDIR}
                echo "${PERL} vep_vcf_to_gene_lofs_vcf.pl -v -o ${PROJECTNAME}_gene.lof" >> ${OUTPUTDIR}/run_vep_to_lof_gene.sh
            else
                echoerrorflash "                        *** ERROR *** "
                echoerrorflash "Something went wrong. You must have to set the FILE_FORMAT in LoF_config to either IMPUTE2 or VCF. "
                echoerrorflash "                *** END OF ERROR MESSAGE *** "
                exit 1
            fi

            echo "${PERL} ${LOFTK}/src/gene_lofs_to_gene_lof_counts.pl ${OUTPUTDIR}/${PROJECTNAME}_gene.lof ${OUTPUTDIR}/${PROJECTNAME}_gene.counts" >> ${OUTPUTDIR}/run_vep_to_lof_gene.sh
            echo "${PERL} ${LOFTK}/src/gene_lofs_to_lof_snps.pl ${OUTPUTDIR}/${PROJECTNAME}_gene.lof ${OUTPUTDIR}/${PROJECTNAME}_gene.lof.snps" >> ${OUTPUTDIR}/run_vep_to_lof_gene.sh

	    VEPDEPENDACY=$(sacct --format="JobID,JobName%30,State" | awk -v vepann=${VEP_ANNOTATION} '$2 ~ vepann {print $0}' | awk '$3 == "RUNNING" || $3 == "PENDING" {print $1}' | ${TRANSPOSE} | sed 's/\t/,/g')
            echo "Job ID for LoF_gene_${PROJECTNAME}: ${VEPDEPENDACY}"

	    sbatch --job-name=LoF_gene_${PROJECTNAME} --dependency=afterok:${VEPDEPENDACY} -e LoF_gene_${PROJECTNAME}.error -o LoF_gene_${PROJECTNAME}.log -t ${QUEUE_LOF_GENE} --mem=${VMEM_LOF_GENE} --mail-user=${EMAIL} --mail-type=${MAILTYPE} -D ${OUTPUTDIR} ${OUTPUTDIR}/run_vep_to_lof_gene.sh

#=====================#
#### LoF variants #####
#=====================#
	    echo "Collect high-confidence loss-of-function variants."
	    echo "#!/bin/bash" > ${OUTPUTDIR}/run_vep_to_lof_snp.sh
	    echo "sleep 50" >> ${OUTPUTDIR}/run_vep_to_lof_snp.sh

	    if [ ${FILE_FORMAT} == "IMPUTE2" ]; then
		cp ${LOFTK}/src/vep_vcf_to_snp_lofs.pl ${OUTPUTDIR}
                echo "${PERL} vep_vcf_to_snp_lofs.pl -v -o ${PROJECTNAME}_snp.lof" >> ${OUTPUTDIR}/run_vep_to_lof_snp.sh
            elif [ ${FILE_FORMAT} == "VCF" ]; then
		cp ${LOFTK}/src/vep_vcf_to_snp_lofs_vcf.pl ${OUTPUTDIR}
                echo "${PERL} vep_vcf_to_snp_lofs_vcf.pl -v -o ${PROJECTNAME}_snp.lof" >> ${OUTPUTDIR}/run_vep_to_lof_snp.sh
            else
                echoerrorflash "                        *** ERROR *** "
                echoerrorflash "Something went wrong. You must have to set the FILE_FORMAT in LoF_config to either IMPUTE2 or VCF. "
                echoerrorflash "                *** END OF ERROR MESSAGE *** "
                exit 1
            fi

	    echo "${PERL} ${LOFTK}/src/snp_lofs_to_snp_lof_counts.pl ${OUTPUTDIR}/${PROJECTNAME}_snp.lof ${OUTPUTDIR}/${PROJECTNAME}_snp.counts" >> ${OUTPUTDIR}/run_vep_to_lof_snp.sh

	    VEPDEPENDACY=$(sacct --format="JobID,JobName%30,State" | awk -v vepann=${VEP_ANNOTATION} '$2 ~ vepann {print $0}' | awk '$3 == "RUNNING" || $3 == "PENDING" {print $1}' | ${TRANSPOSE} | sed 's/\t/,/g')
            echo "Job ID for LoF_snp_${PROJECTNAME}: ${VEPDEPENDACY}"

	    sbatch --job-name=LoF_snp_${PROJECTNAME} --dependency=afterok:${VEPDEPENDACY} -e LoF_snp_${PROJECTNAME}.error -o LoF_snp_${PROJECTNAME}.log -t ${QUEUE_LOF_SNP} --mem=${VMEM_LOF_SNP} --mail-user=${EMAIL} --mail-type=${MAILTYPE} -D ${OUTPUTDIR} ${OUTPUTDIR}/run_vep_to_lof_snp.sh

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

    LOF_GENE_ANNOTATION="LoF_gene_${PROJECTNAME}"
    LOF_SNP_ANNOTATION="LoF_snp_${PROJECTNAME}"
    echo "#!/bin/bash" > ${OUTPUTDIR}/stat_desc_${PROJECTNAME}.sh
    DIR_CONFG=$(realpath "$CONFIGURATIONFILE")
    echo "${LOFTK}/stat_desc.sh ${DIR_CONFG}" >> ${OUTPUTDIR}/stat_desc_${PROJECTNAME}.sh

    LOFDEPENDACY=$(squeue -u ${USERNAME} -n LoF_gene_${PROJECTNAME},LoF_snp_${PROJECTNAME} | tail -n +2 | awk '{print $1}' | ${TRANSPOSE} | sed 's/\t/,/g')

    echo "Job ID for STAT_DESC_${PROJECTNAME}: ${LOFDEPENDACY}"

    sbatch --job-name=STAT_DESC_${PROJECTNAME} --dependency=afterok:${LOFDEPENDACY} -e STAT_DESC_${PROJECTNAME}.error -o STAT_DESC_${PROJECTNAME}.log -t ${QUEUE_STAT_DESC} --mem=${VMEM_STAT_DESC} --mail-user=${EMAIL} --mail-type=${MAILTYPE} -D ${OUTPUTDIR} ${OUTPUTDIR}/stat_desc_${PROJECTNAME}.sh

fi   # For [$# -lt 1]
