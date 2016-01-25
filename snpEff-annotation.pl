#!/usr/bin/perl -w
use strict;
#this script writes a torque submission for annotating VCF with snpEff

my $name = $ARGV[0];
my $output = "snpEff$name\.sh";
open(OUT, ">$output") or die "cannot open the output file\n";

print OUT "\#PBS -N snpEff$name\n";
print OUT "\#PBS -V\n";
print OUT "\#PBS -l walltime=25:00:00\n";

print OUT "java -jar /usr/local/snpEff/snpEff.jar eff GRCh37.75 -v -i vcf -o gatk -c snpEff.config \\\n";
print OUT "haplotyper-all.vcf \\\n";
print OUT "> haplotyper-all-annotated.vcf \n\n";

print OUT "java -jar /usr/local/GATK-3.1.1/GenomeAnalysisTK.jar -T VariantAnnotator -R ucsc.hg19.fasta \\\n";
print OUT "-A SnpEff --variant haplotyper-all.vcf \\\n";
print OUT "--dbsnp dbsnp_137.hg19.vcf --snpEffFile haplotyper-all-annotated.vcf \\\n";
print OUT "-o haplotyper-all-annotated-snpEff.vcf\n";
