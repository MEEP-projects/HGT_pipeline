#!/bin/bash

# Script input parameters
bed_file="$1"      # BED file of insertion regions
bam_file="$2"      # Input BAM file
flank_length="$3"  # Length of flanking region
output_dir="$4"    # Output directory

# Example usage:
# bash extract_align.sh insertions.bed alignment.bam 500 output

# Ensure the output directory exists
mkdir -p "${output_dir}"

# Read each line of the BED file
while read -r line; do
    # Parse each field in the BED file
    chrom=$(echo "$line" | cut -f 1)   # Chromosome/contig name
    start=$(echo "$line" | cut -f 2)   # Start position of insertion region
    end=$(echo "$line" | cut -f 3)     # End position of insertion region
    region_name=$(echo "$chrom:${start}-${end}")  # Region name for file naming

    # Compute region range including flanking
    new_start=$((start - flank_length)) # Flanking region before the insertion
    new_end=$((end + flank_length))     # Flanking region after the insertion

    # Ensure coordinates are not less than 0
    if [ "$new_start" -lt 0 ]; then
        new_start=0
    fi

    # Extract reads in this region
    output_bam="${output_dir}/${region_name}.bam"
    echo "Extracting region ${chrom}:${new_start}-${new_end} to ${output_bam}"

    # Use samtools and bedtools to extract reads for the specified region
    samtools view -b "${bam_file}" "${chrom}:${new_start}-${new_end}" > "${output_bam}"

    # Index the extracted BAM file
    samtools index "${output_bam}"

done < "${bed_file}"

echo "Extraction of all insertion regions and their flanking reads completed. Results saved to ${output_dir}"
