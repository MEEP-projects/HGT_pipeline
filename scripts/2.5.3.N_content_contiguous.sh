#!/bin/bash

input_file=$1
output_file=$2

# Check if input file and output file are provided
if [[ -z $input_file || -z $output_file ]]; then
    echo "Usage: $0 input.fasta output.txt"
    exit 1
fi

# Clear the output file if it exists
> "$output_file"

# Loop through the sequences in the FASTA file
awk -v outfile="$output_file" '
    BEGIN { RS = ">" }    
    NR > 1 {              
        header = $1;      
        sequence = "";    
        for (i=2; i<=NF; i++) sequence = sequence $i 
        total_length = length(sequence);
        threshold_length = 0.5 * total_length;        # 50% of total length

        # Find the longest unbroken sequence of Ns
        match(sequence, /(N{1,})/);
        longest_n_run = RLENGTH;

        # Check if longest run of Ns is at least 50% of total length
        if (total_length > 0 && longest_n_run >= threshold_length) {
            print header > outfile;   # Write header to output file
        }
    }
' "$input_file"

echo "Headers of sequences with >=50% unbroken N run have been saved to $output_file."
