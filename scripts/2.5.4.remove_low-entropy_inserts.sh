#!/bin/bash

# Input arguments
fasta_file="$1"
remove_list="$2"
output_file="$3"

# Check input parameters
if [[ -z "$fasta_file" || -z "$remove_list" || -z "$output_file" ]]; then
    echo "Usage: $0 <fasta_file> <remove_list> <output_file>"
    exit 1
fi

# Check input files
[[ ! -f "$fasta_file" ]] && { echo "Error: $fasta_file does not exist"; exit 1; }
[[ ! -f "$remove_list" ]] && { echo "Error: $remove_list does not exist"; exit 1; }

echo "Reading remove list..."

# Create an associative array of sequences to remove
awk -v out="$output_file" '
    BEGIN {
        # Read remove list
        while (getline < "'$remove_list'") {
            remove[$1] = 1
        }
    }
    
    /^>/ {
        # Process previous sequence
        if (seq != "") {
            # Extract sequence ID (part before " | " or space, remove ">")
            split(seq_header, header_parts, " | ")
            pure_id = header_parts[1]
            sub(/^>/, "", pure_id)
            
            # Output if not in remove list
            if (!(pure_id in remove)) {
                print seq_header > out
                print seq > out
            }
        }
        
        # Start new sequence
        seq_header = $0
        seq = ""
        next
    }
    
    {
        seq = seq $0
    }
    
    END {
        # Process last sequence
        if (seq != "") {
            split(seq_header, header_parts, " | ")
            pure_id = header_parts[1]
            sub(/^>/, "", pure_id)
            
            if (!(pure_id in remove)) {
                print seq_header > out
                print seq > out
            }
        }
    }
' "$fasta_file"

echo "Done! Output file: $output_file"