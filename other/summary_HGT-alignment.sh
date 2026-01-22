#!/bin/bash

# Check whether enough command-line arguments were provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <bam_folder> <max_clipping>"
    exit 1
fi

# Set input parameters
bam_folder=$1        # The first argument is the folder containing BAM files
max_clipping=$2      # The second argument is the maximum allowed length of S (soft clipping)
output_file="flanking_reads_stats.txt"  # Output file
flank_length=1000    # Length of the flanking region

# Clear the output file
> "$output_file"

# Record the max_clipping parameter and input folder in the output file
echo "BAM folder: $bam_folder" >> "$output_file"
echo "Max clipping: $max_clipping" >> "$output_file"
echo "Flanking length: $flank_length" >> "$output_file"

# Iterate over all BAM files in the folder
for bam_file in "$bam_folder"/*.bam; do
  # Record the current BAM file name in the output file
  echo "Processing BAM file: $bam_file" >> "$output_file"

  # Use samtools to read the BAM file and analyze alignments
  samtools view "$bam_file" | awk -v flanking_bp="$flank_length" -v max_clipping="$max_clipping" -v output_file="$output_file" '
  BEGIN {
      total_reads = 0;              # Total number of reads
      align_flanking_left = 0;      # Reads that align in the left flanking region
      unalign_flanking_left = 0;    # Reads that do not align in the left flanking region
      align_flanking_right = 0;     # Reads that align in the right flanking region
      unalign_flanking_right = 0;   # Reads that do not align in the right flanking region
      no_coverage_left = 0;         # Reads with no coverage in the left flanking region
      no_coverage_right = 0;        # Reads with no coverage in the right flanking region
  }

  {
      total_reads++;  # Increment total read count for each line processed

      # Parse BAM fields
      start = $4;                     # Alignment start position
      cigar = $6;                     # CIGAR string
      read_length = length($10);      # Total read sequence length

      # Extract reference sequence name and its length
      ref_name = $3;
      ref_length=$(samtools view -H "$bam_file" | grep "^@SQ" | grep -w "$ref_name" | cut -f3 | sed 's/LN://');  

      # Check if the read is in the left flanking region of the reference
      if (start <= flanking_bp) {
          if (match(cigar, /^[0-9]+[SH]/)) {
              # Soft-clipped reads at the left end, and clipping length does not exceed max_clipping
              split(cigar, fields, /[A-Z]/);  # Split the CIGAR string
              soft_clip_len = fields[1];      # Extract soft clipping length
              
              # Check whether there is a matched (aligned) portion
              if (soft_clip_len <= max_clipping) {
                  align_flanking_left++;
              } else {
                  unalign_flanking_left++;
              }
          } else if (match(cigar, /^([0-9]+H)?[0-9]+S[0-9]+H$/)) {
              # If the read is completely soft/hard clipped, it does not cover the flanking region
              no_coverage_left++;
          }
      }

      # Check if the read is in the right flanking region of the reference
      if ((start + read_length) >= (ref_length - flanking_bp)) {
          if (match(cigar, /[0-9]+[SH]$/)) {
              # Soft-clipped reads at the right end, and clipping length does not exceed max_clipping
              n = split(cigar, fields, /[A-Z]/);  # Split the CIGAR string
              soft_clip_len = fields[n];          # Extract soft clipping length

              # Check whether there is a matched (aligned) portion
              if (soft_clip_len <= max_clipping) {
                  align_flanking_right++;
              } else {
                  unalign_flanking_right++;
              }
          } else if (match(cigar, /^([0-9]+H)?[0-9]+S[0-9]+H$/)) {
              # If the read is completely soft/hard clipped, it does not cover the flanking region
              no_coverage_right++;
          }
      }
  }

  END {
      print "Total reads: " total_reads >> output_file;
      print "Reads aligned in left flanking region: " align_flanking_left >> output_file;
      print "Reads not aligned in left flanking region: " unalign_flanking_left >> output_file;
      print "Reads with no coverage in left flanking region: " no_coverage_left >> output_file;
      print "Reads aligned in right flanking region: " align_flanking_right >> output_file;
      print "Reads not aligned in right flanking region: " unalign_flanking_right >> output_file;
      print "Reads with no coverage in right flanking region: " no_coverage_right >> output_file;
      print "-----------------------------------" >> output_file;
  }
  '
done

echo "Statistics complete, results saved to $output_file"
