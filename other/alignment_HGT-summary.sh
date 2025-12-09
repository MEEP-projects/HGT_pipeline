#!/bin/bash

# Get input parameters
bam_folder="$1"  # Path to the BAM folder
allowance="$2"   # Allowed range

# Create the results file
output_file="length_statistics.txt"
echo "Total Reads,Length Below Threshold,Insertions Greater than Allowance,Percentage Below Threshold" > "$output_file"

# Initialise counter for BAM files with >50% ratio
over_threshold_count=0

# Loop through BAM files
for bam_file in "$bam_folder"/*.bam; do
    echo "Processing BAM file: $bam_file"
    
    # Extract contig_ID and reference start/end from file name
    filename=$(basename "$bam_file")
    IFS=':' read -r contig_id range <<< "$filename"  # Use ':' as separator
    IFS='-' read -r start end <<< "${range%.bam}"    # Remove .bam then split on '-'
    
    # Calculate reference length
    reference_length=$((end - start + 1))
    echo "Start: $start, End: $end, Reference Length: $reference_length"
    
    # Initialise counters
    total_reads=0
    below_threshold=0

    # Extract CIGAR fields and calculate
    samtools view "$bam_file" | while read -r line; do
        # Ensure line format is correct with enough fields
        if [[ -n "$line" ]]; then
            cigar=$(echo "$line" | awk '{print $6}')  # Extract CIGAR field
            if [[ -n "$cigar" ]]; then                # Ensure CIGAR is not empty
                ((total_reads++))  # Increment counter

                # Sum lengths of M and D operations
                m_length=$(echo "$cigar" | grep -o '[0-9]*M' | awk '{sum += $1} END {print sum}')
                d_length=$(echo "$cigar" | grep -o '[0-9]*D' | awk '{sum += $1} END {print sum}')

                # Actual aligned length
                actual_length=$((m_length + d_length))
                
                # Threshold is the reference length
                threshold="$reference_length"

                # Check if aligned length is below threshold
                if [ "$actual_length" -le "$threshold" ]; then
                    ((below_threshold++))
                fi
                
                # Calculate percentage of reads below the threshold
                if [ $total_reads -gt 0 ]; then
                    percentage_below_threshold=$(echo "scale=2; ($below_threshold / $total_reads) * 100" | bc)
                else
                    percentage_below_threshold=0
                fi
            fi
        fi
    # Output statistics
    echo "$total_reads,$below_threshold,$insertions_greater_than_allowance,$percentage_below_threshold%" >> "$output_file"
    echo "Processed $filename: Total Reads: $total_reads, Below Threshold: $below_threshold, Insertions Greater than Allowance: $insertions_greater_than_allowance, Percentage Below Threshold: $percentage_below_threshold%"

    done
    
    echo "$filename" >> "$output_file"

    # Check if percentage exceeds 50%
    if (( $(echo "$percentage_below_threshold > 50" | bc -l) )); then
        ((over_threshold_count++))
    fi
done

# Extract lines containing 'contig' and the previous line
grep 'contig' -B 1 "$output_file" > summary.txt

# Output number of BAMs with >50% short reads
echo "Total BAM files with more than 50% reads below threshold: $over_threshold_count" >> "$output_file"
echo "Summary: $over_threshold_count BAM files have more than 50% reads below threshold."

echo "Statistics written to $output_file and summary written to summary.txt"
