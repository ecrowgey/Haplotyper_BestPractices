# Haplotyper_BestPractices
Running bwa and GATK best practices 

The script inputs the name of a fastq file (minus the .fq) and writes a torque submission script for running bwa and GATK bp.  

#bwa notes
manual: http://bio-bwa.sourceforge.net/
recommend -aM flag for inDel detection
@RG input is based on user and recommended as some downstream tools will not work without it

#picard tools and GATK are required for marking duplicate reads and re-alignment steps
https://www.broadinstitute.org/gatk/
http://sourceforge.net/projects/picard/

#the next script after this one is running variant calling - Haplotyper
