#!/usr/bin/perl -w
use strict;

#written by erin crowgey
#this script writes a submission script to torque for running bwa
################################################################################
my $name = $ARGV[0]; #the name of the fastq file minus the .fq 
my $output = "$name\.sh";
open(OUT, ">$output") or die "cannot open the output file\n";

################################################################################
print OUT "\#PBS -N $name\n";
print OUT "\#PBS -V\n";
print OUT "\#PBS -l walltime=100:00:00\n";
print OUT "\#PBS -l nodes=1:ppn=12\n\n";


my $ind_fastq = "fastqFiles"; #fastq directory
my $INDIR ="bwaFiles"; #bwa directory
my $OUTDIR="bwaFiles"; #can keep the same or change from indir 
my $PICARDDIR= "/usr/local/picard-tools-1.67"; #picard location
my $GATKDIR= "/usr/local/GATK-3.4-0"; #GATK location
my $SNPEFFDIR= "/usr/local/snpEff"; 
my $GATKBUNDLEDIR= "/home/ecrowgey/GATKbundle"; #download GATK bundle
my $REF="/home/ecrowgey/GATKbundle/ucsc.hg19.fasta"; #reference used for genome alignment


#################################################################################
#Run bwa mem
print OUT "export PATH=\${PATH}:/usr/local/bwa-0.7.4\n";
print OUT "bwa mem -aM -t 6 -R \"\@RG\\tID:$name\\tPL:illumina\\tLB:$name\\tDT:2012-04-24T06:00:00-0500\\tSM:$name\\tCN:BCM\" \\\n$REF $ind_fastq/$name\_1.fastq $ind_fastq/$name\_2.fastq > $OUTDIR/$name\_bwa_mem.sam\n"; 
###############################################################################
print OUT "\n";
################################################################################
#sort bam
print OUT "java -Xmx10g -jar /usr/local/picard-tools-1.67/SortSam.jar TMP_DIR=/home/ecrowgey \\\nI=$INDIR/$name\_bwa_mem.sam \\\nO=$OUTDIR/$name\_bwa_mem_sorted.bam SO=coordinate\n";
print OUT "\n";
###############################################################################
my $input_one = $name."_bwa_mem_sorted.bam";
my $output_one = $name."_bwa_mem_sorted_mdup1.bam";
my $output_two = $name."_bwa_mem_sorted_mdup1.metrics";

################################################################################
#mark duplicates 1
print OUT "java -jar -Xms5g -Xmx5g $PICARDDIR/MarkDuplicates.jar \\\nI=$OUTDIR/$input_one \\\nO=$OUTDIR/$output_one \\\nM=$OUTDIR/$output_two CREATE_INDEX=true\n";
print OUT "\n";
#################################################################################
my $output_three = $name."_bwa_mem_sorted_mdup1_realigner.intervals";
my $output_four = $name."_bwa_mem_sorted_mdup1_realigned.bam";

#################################################################################
##re-alignment
print OUT "java -jar -Xms5g -Xmx5g $GATKDIR/GenomeAnalysisTK.jar -T RealignerTargetCreator \\\n-R $REF \\\n-I $OUTDIR/$output_one \\\n-known $GATKBUNDLEDIR/Mills_and_1000G_gold_standard.indels.hg19.vcf \\\n-known $GATKBUNDLEDIR/1000G_phase1.indels.hg19.vcf \\\n-o $OUTDIR/$output_three\n"; 
print OUT "\n";
print OUT "java -jar -Xms5g -Xmx5g $GATKDIR/GenomeAnalysisTK.jar -T IndelRealigner \\\n-R $REF \\\n-I $OUTDIR/$output_one \\\n-known $GATKBUNDLEDIR/Mills_and_1000G_gold_standard.indels.hg19.vcf \\\n-known $GATKBUNDLEDIR/1000G_phase1.indels.hg19.vcf \\\n-targetIntervals $OUTDIR/$output_three \\\n-o $OUTDIR/$output_four \\\n--filter_bases_not_stored\n";
print OUT "\n";
#################################################################################   
## mark duplicates 2
my $output_five = $name."_bwa_mem_sorted_mdup1_realigned_mdup2.bam";
my $output_six = $name."_bwa_mem_sorted_mdup1_realigned_mdup2.metrics";
print OUT "java -jar $PICARDDIR/MarkDuplicates.jar I=$OUTDIR/$output_four \\\nO=$OUTDIR/$output_five \\\nM=$OUTDIR/$output_six CREATE_INDEX=true\n";
#
print OUT "\n";
#################################################################################
## base recalibration
my $output_seven = $name."_bwa_mem_sorted_mdup1_realigned_mdup2_recal.grp";
my $output_eight = $name."_bwa_mem_sorted_mdup1_realigned_mdup2_post_recal.grp";
my $output_nine = $name."_bwa_mem_sorted_mdup1_realigned_mdup2_recal.bam --filter_bases_not_stored";
print OUT "java -jar -Xms5g -Xmx5g $GATKDIR/GenomeAnalysisTK.jar -T BaseRecalibrator \\\n-R $REF -I $OUTDIR/$output_five \\\n-knownSites $GATKBUNDLEDIR/Mills_and_1000G_gold_standard.indels.hg19.vcf \\\n-knownSites $GATKBUNDLEDIR/1000G_phase1.indels.hg19.vcf -knownSites $GATKBUNDLEDIR/dbsnp_137.hg19.vcf  \\\n-o $OUTDIR/$output_seven\n";
print OUT "\n";

print OUT "java -jar -Xms5g -Xmx5g $GATKDIR/GenomeAnalysisTK.jar -T BaseRecalibrator \\\n-R $REF \\\n-I $OUTDIR/$output_five \\\n-knownSites $GATKBUNDLEDIR/Mills_and_1000G_gold_standard.indels.hg19.vcf \\\n-knownSites $GATKBUNDLEDIR/1000G_phase1.indels.hg19.vcf \\\n-knownSites $GATKBUNDLEDIR/dbsnp_137.hg19.vcf \\\n-BQSR $OUTDIR/$output_seven \\\n-o $OUTDIR/$output_eight\n";
print OUT "\n";

print OUT "java -jar -Xms5g -Xmx5g $GATKDIR/GenomeAnalysisTK.jar -T PrintReads \\\n-R $REF \\\n-I $OUTDIR/$output_five \\\n-BQSR $OUTDIR/$output_eight \\\n-o $OUTDIR/$output_nine\n";
print OUT "\n";
