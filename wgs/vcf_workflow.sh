#!/bin/zsh

# Define reference genome
REFERENCE="../genomes/Hsapiens/hg19/seq/hg19.fa"

# Loop through all SAM files matching pattern "mt_B*.sam"
for f in mt_B*.sam; do
    echo "Processing: $f"

    # Extract the filename prefix (remove .sam extension)
    base_name="${f%.sam}"

    # Convert SAM to BAM
    samtools view -Sb "$f" > "${base_name}.bam"

    # Sort BAM file
    samtools sort "${base_name}.bam" -o "${base_name}-sorted.bam"

    # Index BAM file
    samtools index "${base_name}-sorted.bam"

    # Run variant calling
    bcftools mpileup -f "$REFERENCE" "${base_name}-sorted.bam" | bcftools call -mv -Ov -o "${base_name}-sorted.vcf"

    # Count total number of variants
    total_variants=$(grep -vc "^#" "${base_name}-sorted.vcf")

    # Compute average QUAL score
    avg_qual=$(grep -v "^#" "${base_name}-sorted.vcf" | awk '{sum+=$6; count++} END { if (count > 0) print sum/count; else print "N/A"}')

    # Count SNPs and Indels
    read snps indels <<< $(grep -v "^#" "${base_name}-sorted.vcf" | awk '{if(length($4) == length($5)) snp++; else indel++} END {print snp, indel}')

    # Print results
    echo -e "$base_name\tVariants: $total_variants\tAvg QUAL: $avg_qual\tSNPs: $snps\tIndels: $indels"

done