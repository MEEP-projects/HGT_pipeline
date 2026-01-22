#!/bin/bash

# Check whether the result file path was provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <result_file>"
    exit 1
fi

# Set input parameters
result_file=$1      # Path to the result file
output_file="flanking_reads_ratio_summary.txt"  # Output file

# Clear the output file
> "$output_file"

# Initialize counters and lists of BAM file names
count_greater_than_50_left=0
count_greater_than_50_right=0
greater_than_50_files_left=()
greater_than_50_files_right=()
current_bam_file=""

# Read the result file and calculate ratios
while IFS= read -r line; do
    if [[ $line == *"Processing BAM file:"* ]]; then
        current_bam_file=$(echo "$line" | awk -F': ' '{print $2}' | awk -F'/' '{print $NF}')
    elif [[ $line == *"Total reads:"* ]]; then
        total_reads=$(echo "$line" | grep -oE "[0-9]+")
    elif [[ $line == *"Reads aligned in left flanking region:"* ]]; then
        align_flanking_left=$(echo "$line" | grep -oE "[0-9]+")
    elif [[ $line == *"Reads not aligned in left flanking region:"* ]]; then
        unalign_flanking_left=$(echo "$line" | grep -oE "[0-9]+")
    elif [[ $line == *"Reads aligned in right flanking region:"* ]]; then
        align_flanking_right=$(echo "$line" | grep -oE "[0-9]+")
    elif [[ $line == *"Reads not aligned in right flanking region:"* ]]; then
        unalign_flanking_right=$(echo "$line" | grep -oE "[0-9]+")
    elif [[ $line == ----------------------------------- ]]; then
        # Calculate ratios
        ratio_left=0
        ratio_right=0

        if [[ $align_flanking_left -gt 0 ]]; then
            ratio_left=$(echo "scale=4; $unalign_flanking_left / $align_flanking_left" | bc)
        fi
        if [[ $align_flanking_right -gt 0 ]]; then
            ratio_right=$(echo "scale=4; $unalign_flanking_right / $align_flanking_right" | bc)
        fi

        # Count cases where the ratio is greater than 50%
        if (( $(echo "$ratio_left > 0.5" | bc -l) )); then
            count_greater_than_50_left=$((count_greater_than_50_left + 1))
            greater_than_50_files_left+=("$current_bam_file")
        fi
        if (( $(echo "$ratio_right > 0.5" | bc -l) )); then
            count_greater_than_50_right=$((count_greater_than_50_right + 1))
            greater_than_50_files_right+=("$current_bam_file")
        fi
    fi
done < "$result_file"

# Output results
echo "Number of BAM files with left ratio > 50%: $count_greater_than_50_left" > "$output_file"
echo "BAM files with left ratio > 50%: ${greater_than_50_files_left[@]}" >> "$output_file"
echo "Number of BAM files with right ratio > 50%: $count_greater_than_50_right" >> "$output_file"
echo "BAM files with right ratio > 50%: ${greater_than_50_files_right[@]}" >> "$output_file"

echo "Statistics complete, results saved to $output_file"
