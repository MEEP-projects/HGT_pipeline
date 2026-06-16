#!/bin/bash

input_file=$1 #insert with low entropy sequences substituted by N.fasta
output_file=$2 #list of low entropy sequences > 50% contig length, remove list

if [[ -z $input_file || -z $output_file ]]; then
    echo "Usage: $0 input.fasta output.txt"
    exit 1
fi

> "$output_file"

awk -v outfile="$output_file" '
    BEGIN { RS = ">" }
    NR > 1 {
        # Find the sequence after the first newline or space
        record = $0
        # Find the position of the first newline
        nl = index(record, "\n")
        if (nl > 0) {
            header = substr(record, 1, nl-1)
            sequence = substr(record, nl+1)
        } else {
            # If no newline, header and sequence may be on the same line
            # Try to split by space or pipe
            split(record, parts, " | ")
            header = parts[1]
            # The remaining part is the sequence
            sequence = record
            sub(/^[^|]+\| [^ ]+ /, "", sequence)
        }
        
        gsub(/[ \t\r\n]/, "", sequence)
        total_len = length(sequence)
        
        if (total_len > 0) {
            # Find the longest run of Ns
            longest_n = 0
            temp = sequence
            while (match(temp, /N+/)) {
                if (RLENGTH > longest_n) longest_n = RLENGTH
                temp = substr(temp, RSTART + RLENGTH)
            }
            
            if (longest_n >= total_len * 0.5) {
                print header > outfile
            }
        }
    }
' "$input_file"

echo "Done! Output saved to $output_file"