LOFTK (Loss-of-Function ToolKit)
============

**LoFToolKit** is a pipeline written in the BASH and Perl languages to identify loss-of function (LoF) variants using VEP and LOFTEE efficiently. It will aid in annotating LoF variants, select high confidence (HC) variants, state the homozygous and heterozygous LoF variants, and calculate statistics. 

All scripts are annotated for debugging purposes - and future reference. The scripts will work within the context of a certain Linux environment (in this case a CentOS7 system on a SUN Grid Engine background). As such we have tested LOFToolKit on CentOS7.

--------------

## This version submit all jobs to the SLURM cluster.

#### Requirements
- Ensembl Variant Effect Predictor (VEP)
- Perl >= 5.10.1
- Bash
- LOFTEE
- Ancestral sequence (human_ancestor.fa[.gz|.rz])
- Samtools (must be on path)
- PhyloCSF database (phylocsf.sql) for conservation filters

#### Usage
The only script the user should use is the run_loftk.sh script in conjunction with a configuration file LoF.config.

Rmember to set all options in the LoF.config file before the run.

By typing...

```
bash run_loftk.sh $(pwd)/LoF.config
```


