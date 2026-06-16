#!/bin/bash

############################################################################################
### Extract sequences from genome based on BED coordinates ###
############################################################################################

# ==================== Configuration parameters ====================
genome_file="/Users/zzha8134/Desktop/Genome/Workshop/Trail/P.t.te_Z11.fasta"
bed_file="alignment_aligned-segments_dup-filtered-v1.bed"
output_fasta="test_Z11_v1.fasta"
# ================================================================

echo "Extracting sequences from the genome based on BED coordinates..."

# Check input files
if [[ ! -f "$genome_file" ]]; then
    echo "Error: Genome file does not exist: $genome_file"
    exit 1
fi

if [[ ! -f "$bed_file" ]]; then
    echo "Error: BED file does not exist: $bed_file"
    exit 1
fi

# Use bedtools (recommended, more efficient)
if command -v bedtools &> /dev/null; then
    echo "Extracting sequences using bedtools..."
    bedtools getfasta -fi "$genome_file" -bed "$bed_file" -name -fo "$output_fasta"
    
    if [[ $? -eq 0 ]]; then
        seq_count=$(grep -c "^>" "$output_fasta")
        echo "Successfully extracted $seq_count sequences to $output_fasta"
    else
        echo "bedtools extraction failed"
        exit 1
    fi

# Fallback: use awk (suitable for small genomes)
else
    echo "bedtools not found, using awk method..."
    
    awk '
    # Read genome
    NR==FNR {
        if ($0 ~ /^>/) {
            if (seq != "") genome[id] = seq
            id = substr($0, 2)
            sub(/ .*$/, "", id)
            seq = ""
        } else {
            seq = seq $0
        }
        next
    }
    
    # Save the last sequence
    END {
        if (seq != "") genome[id] = seq
    }
    
    # Process BED file
    {
        contig = $1
        start = $2 + 1
        end = $3
        names = (NF >= 4) ? $4 : sprintf("%s:%d-%d", $1, $2, $3)
        
        if (contig in genome) {
            seq_len = length(genome[contig])
            if (start <= seq_len && end <= seq_len && start <= end) {
                print ">" contig ":" $2 "-" $3 " | " names
                print substr(genome[contig], start, end - start + 1)
            } else {
                print "Warning: Invalid coordinates " contig ":" start "-" end > "/dev/stderr"
            }
        } else {
            print "Warning: Contig not found " contig > "/dev/stderr"
        }
    }
    ' "$genome_file" "$bed_file" > "$output_fasta"
    
    seq_count=$(grep -c "^>" "$output_fasta")
    echo "Extracted $seq_count sequences to $output_fasta"
fi

# Validate output
if [[ ! -s "$output_fasta" ]]; then
    echo "Warning: Output file is empty. Please check whether the BED coordinates match the genome."
fi