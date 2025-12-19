#!/bin/bash

# Input arguments
fasta_file="$1"
regions_file="$2"
output_file="$3"

# Iterate through each line in the regions file
while IFS=$'\t' read -r seq_id start end; do
    # Adjust start for zero-based indexing
    start=$((start - 1))

    # Use awk to modify only the specified region in the sequence
    awk -v id="$seq_id" -v start="$start" -v end="$end" '
        BEGIN {FS="\n"; RS=">"; ORS=""}
        $1 == id {
            header = $1
            seq = $2
            prefix = substr(seq, 1, start)
            replace = ""
            for (i = 1; i <= (end - start + 1); i++) {
                replace = replace "N"
            }
            suffix = substr(seq, end + 1)
            print ">" header "\n" prefix replace suffix "\n"
        }
        $1 != id {
            print ">" $0
        }
    ' "$output_file" > temp_output && mv temp_output "$output_file"

done < "$regions_file"

# Remove extra ">" at the beginning of the file if it exists
sed -i '' '1s/^>//' "$output_file" 2>/dev/null || sed -i '1s/^>//' "$output_file"

echo "Replacements complete. Output saved to $output_file."
