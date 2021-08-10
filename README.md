<h1 align="center">
  <a href="https://github.com/CirculatoryHealth/LoFTK">
    <img src="/docs/images/LoFTK_logo2.png" alt="Logo" width="300" height="150">
  </a>
</h1>


LOFTK (Loss-of-Function ToolKit)
============


[![DOI](10.1101/2021.08.09.455694)](https://doi.org/10.1101/2021.08.09.455694)
[![License](https://img.shields.io/badge/license-CC--BY--SA--4.0-orange)](https://choosealicense.com/licenses/cc-by-sa-4.0)
[![Version](https://img.shields.io/badge/Version-1.0.0-blue)](https://github.com/CirculatoryHealth/LoFTK)

#### This readme
> This readme accompanies the paper _"LOFTK: a framework for fully automated calculation of predicted Loss-of-Function variants."_ by [Alasiri A. *et al*. **bioRxiv 2021**]().

--------------

## Background

Predicted Loss-of-Function (LoF) variants in human genes are important due to their impact on clinical phenotypes and frequent occurrence in the genomes of healthy individuals. Current approaches predict high-confidence LoF variants without identifying the specific genes or the number of copies they affect. Here we present an open source tool, the **Loss-of-Function ToolKit (LoFTK)**, which allows efficient and automated prediction of LoF variants from both genotyped and sequenced genomes, identifying genes that are inactive in one or two copies, and providing summary statistics for downstream analyses.

**LoFTK** is a pipeline written in the `BASH` and `Perl` languages to identify loss-of function (LoF) variants using [`VEP`](https://github.com/Ensembl/ensembl-vep) and [`LOFTEE`](https://github.com/konradjk/loftee) efficiently. It will aid in annotating LoF variants, select high confidence (HC) variants, state the homozygous and heterozygous LoF variants, and calculate statistics.


**The Loss-of-Function ToolKit Workflow: finding knockouts using genotyped and sequenced genomes.**
![The Loss-of-Function ToolKit Workflow: finding knockouts using genotyped and sequenced genomes.](docs/images/workflow.png)


--------------

## Installation and Requirements

### Install LoFTK
LoFTK has been developed to work under the environment of two cluster managers; Simple Linux Utility for Resource Management (SLURM) and Sun Grid Engine (SGE). Each cluster manager (SLURM/SGE) has LoFTK verison for installation. Look at [Instillation and Requirements](https://github.com/CirculatoryHealth/LoFTK/wiki/Instillation-and-Requirements) in the [wiki](https://github.com/CirculatoryHealth/LoFTK/wiki).


### Requirements
All scripts are annotated for debugging purposes - and future reference. The scripts will work within the context of a certain Linux environment - in this case we have tested **LoFTK** on CentOS7 with a SLURM Grid Engine background.

- `Perl >= 5.10.1`
- `Bash`
- [Ensembl Variant Effect Predictor (VEP)](https://github.com/Ensembl/ensembl-vep)
- [`LOFTEE`](https://github.com/konradjk/loftee) for GRCh37
  - Ancestral sequence [`(human_ancestor.fa[.gz|.rz])`](https://github.com/konradjk/loftee#:~:text=slow%29.%20Default%3A%20fast.-,human_ancestor_fa,-Location%20of%20human_ancestor)
  - PhyloCSF database [`(phylocsf.sql)`](https://github.com/konradjk/loftee#:~:text=checked%20and%20filtered.-,conservation_file,-The%20required%20SQL) for conservation filters
- [`LOFTEE`](https://github.com/konradjk/loftee/tree/grch38) for GRCh38
  - GERP scores bigwig [`(gerp_bigwig)`](https://github.com/konradjk/loftee/tree/grch38#:~:text=contain%20this%20path.-,gerp_bigwig,-Location%20of%20GERP)
  - Ancestral sequence [`(human_ancestor_fa)`](https://github.com/konradjk/loftee/tree/grch38#:~:text=download%20for%20GRCh38.-,human_ancestor_fa,-Location%20of%20human_ancestor)
  - PhyloCSF database [`(loftee.sql.gz)`](https://github.com/konradjk/loftee/tree/grch38#:~:text=checked%20and%20filtered.-,conservation_file,-Location%20of%20file)
- [`samtools`](https://github.com/samtools/samtools) ([must be on path](https://github.com/CirculatoryHealth/LoFTK/wiki/Instillation-and-Requirements#samtools-must-be-on-path))

--------------

## Usage
The only script the user should use is the `run_loftk.sh` script in conjunction with a configuration file `LoF.config`. It is required to set up the configuration file `LoF.config` before run any analysis, follow the [instruction](https://github.com/CirculatoryHealth/LoFTK/wiki/Configuration) in the [wiki](https://github.com/CirculatoryHealth/LoFTK/wiki).

You can run **LoFTK** using the following command:

```
bash run_loftk.sh $(pwd)/LoF.config
```

Remember to set all options in the `LoF.config` file before the run and always use the _full path_ to the configuration file, e.g. use `$(pwd)`.

### Description of files

File                              | Description                      | Usage         
--------------------------------- | -------------------------------- | --------------
README.md                         | Description of project           | Human editable
LICENSE                           | User permissions                 | Read only
LoF.config                        | Configuration file               | Human editable
run_loftk.sh                      | Main LoFTK script                | Read only
LoF_annotation.sh                 | Annotation of LoF variants/genes | Read only
allele_to_vcf.sh                  | Converting IMPUT2 format to VCF  | Read only
descriptive_stat.sh               | Descriptive analysis             | Read only

--------------

## Post LoFTK

### Merge the counts files of multiple cohorts
This scripts allows you to merge the counts files of different cohorts. By default it only includes genes that were present in both files but you can use the `union` function to include genes that are present in at least 1 cohort. This means that for the other cohorts, the gene LoF counts will be set to 0 for every individual (which is tricky if the gene was not tested), or to a self-specified value

```bash
perl merge_gene_lof_counts.pl -i cohortX.counts,cohortY.counts,cohortZ.counts -o merged_cohorts.counts -c
```
Run the the following to know how to use options:
```bash
perl merge_gene_lof_counts.pl --help
```

### Mismatched genes between samples
This script can be used to determine ‘mismatched’ genes between samples; these are genes that are active in one or two copies in one sample and completely inactive (two-copy loss) in the other sample. This feature helps study interactions between human genomes, for instance during pregnancy (maternal vs fetal genome) and after stem cell or solid organ transplantation (donor vs recipient genome).

- You must create a file `pairs_file.txt` with two columns (tab-separated), where both columns have list of individual IDs and each line has paired subjects.
- The first column must contain individual IDs for which you want to examine the mismatch of knocked out genes with the 1 or 2 active copies in the other pair.
- Output file contains encodings for individuals (from 1st column in `pairs_file.txt`), where `1` for mismatch `0` for not mismatch.
    - `1`: mismatch where sample in the 2nd column has active gene.
    - `0`: not mismatch where paired samples either having both a knocked out gene or none of them carry LoF gene.


**Run the below command:**

```bash
perl gene_lof_counts_to_dyad_lofs.pl pairs_file.txt input_file.counts output_file.dyads
```





--------------

## Inputs
**LoFTK** permits two common file formats as an input:
  1. **Variant Call Format (VCF)**  
  You can find VCF specification [here](https://samtools.github.io/hts-specs/VCFv4.2.pdf).

  2. **IMPUTE2 output format**  
  Four files with the following extensions are needed as an input; `.haps.gz`, `.allele_probs.gz`, `.info` and `.sample`

:warning: The input data have to be phased to annotate compound heterozygous LoF variants, which result in LoF genes with two copies losses.

For more details and [examples](data/) about [**input files**](https://github.com/CirculatoryHealth/LoFTK/wiki/Input-files) are explained in the [wiki](https://github.com/CirculatoryHealth/LoFTK/wiki).

--------------

## Outputs
**LoFTK** will generate four files as an output at the end of the analysis. The [LoFTK outputs](https://github.com/CirculatoryHealth/LoFTK/wiki/LoFTK-outputs) in the [wiki](https://github.com/CirculatoryHealth/LoFTK/wiki) contains more explanation.

  1. [[project_name]_snp.counts](https://github.com/CirculatoryHealth/LoFTK/wiki/LoFTK-outputs): LoF variants and individuals.
  2. [[project_name]_gene.counts](https://github.com/CirculatoryHealth/LoFTK/wiki/LoFTK-outputs): LoF genes and individuals.
  3. [[project_name]_gene.lof.snps](https://github.com/CirculatoryHealth/LoFTK/wiki/LoFTK-outputs): list of LoF variants allele frequencies.
  4. [[project_name]_output.info](https://github.com/CirculatoryHealth/LoFTK/wiki/LoFTK-outputs): report descriptive statistics on LoF variants and genes.


--------------

#### Changes log
_Version:_      v1.0.0</br>
_Last update:_  2021-06-08</br>

* v1.0.0 Initial version.

### Contact

If you have any suggestions for improvement, discover bugs, etc. please create an [issues](https://github.com/CirculatoryHealth/LoFTK/issues). For all other questions, please refer to the last author:

Jessica van Setten, PhD | j.vansetten [at] umcutrecht.nl

--------------

#### CC-BY-SA-4.0 License

<table>
<tr>
<td>

##### Copyright (c) 2020 University Medical Center Utrecht

Creative Commons Attribution-ShareAlike 4.0 International Public License

By exercising the Licensed Rights (defined in the [LICENSE](LICENSE)), you accept and agree to be bound by the terms and conditions of this Creative Commons Attribution-ShareAlike 4.0 International Public License ("Public License"). To the extent this Public License may be interpreted as a contract, you are granted the Licensed Rights in consideration of your acceptance of these terms and conditions, and the Licensor grants you such rights in consideration of benefits the Licensor receives from making the Licensed Material available under these terms and conditions.

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Reference: https://choosealicense.com/licenses/cc-by-sa-4.0/#.

</td>
</tr>
</table>
