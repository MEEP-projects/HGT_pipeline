#!/bin/bash

# If needed, you can extract the longest contigs before the alignment using the script 'extract-longest-contigs.sh'. Here's how you would extract the top 3 longest contigs.  
# Usage: e.g. extracting the 3 longest contigs:
#bash extract-longest-contigs.sh assembly-input.fasta output.fasta 3

input_fasta=$1
output_fasta=$2
top_n=$3

# Ensure the input file is indexed
if [ ! -f "${input_fasta}.fai" ]; then
    samtools faidx $input_fasta
fi

# Find the top N longest contigs
awk '/^>/ {
    if (seqlen) 
        print seqlen, substr(header, 2); 
    header=$0; 
    seqlen=0; 
    next
} 
{
    seqlen+=length($0)
} 
END {
    print seqlen, substr(header, 2)
}' $input_fasta | \
sort -nr | head -n $top_n | awk '{print $2}' > top_contigs.txt

# Extract the top N longest contigs
samtools faidx $input_fasta $(cat top_contigs.txt) > $output_fasta

# Clean up
rm top_contigs.txt

echo "Top $top_n longest contigs have been extracted to $output_fasta."
