#!/bin/zsh
# pipeline.sh: Fastq to variant calls using your existing command

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <fastq1> [fastq2]"
  exit 1
fi

# Input fastq files
fastq1=$1
fastq2=$2

# Path to the reference genome
reference1="../genomes/Hsapiens/hg19/bwa/hg19.fa"
reference2="../genomes/Hsapiens/hg19/seq/hg19.fa"


# Get a sample name based on fastq file
sample=$(basename "$fastq1" | sed -e 's/\.fastq$//' -e 's/\.fq$//' -e 's/\.fastq\.gz$//' -e 's/\.fq\.gz$//')

# Step 1: Align fastq reads using BWA
bwa mem "$reference1" "$fastq1" "$fastq2" > "${sample}.sam"

# Step 2: Convert SAM to BAM, sort, and index
samtools view -Sb "${sample}.sam" > "${sample}.bam"
samtools sort "${sample}.bam" -o "${sample}-sorted.bam"
samtools index "${sample}-sorted.bam"

# Step 3: Run variant calling commands on the sorted BAM file to get quality metrics
f="${sample}-sorted.bam"; echo "Processing file: $f" && bcftools mpileup -f "$reference2" "$f" | bcftools call -mv -Ov -o "${f%.bam}.vcf" && \
total=$(grep -vc "^#" "${f%.bam}.vcf") && echo "Total Variants: $total" && \
avg=$(grep -v "^#" "${f%.bam}.vcf" | awk '{sum+=$6; count++} END {if (count > 0) print sum/count; else print "N/A"}') && echo "Average QUAL: $avg" && \
grep -v "^#" "${f%.bam}.vcf" | awk '{if(length($4)==length($5)) snp++; else indel++} END {print "SNPs:", snp, "Indels:", indel}'