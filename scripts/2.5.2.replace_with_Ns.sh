#!/bin/bash

# Input arguments
fasta_file="$1"
regions_file="$2"
output_file="$3"

# Check input parameters
if [[ -z "$fasta_file" || -z "$regions_file" || -z "$output_file" ]]; then
    echo "Usage: $0 <fasta_file> <regions_file> <output_file>"
    exit 1
fi

# Check input files
[[ ! -f "$fasta_file" ]] && { echo "Error: $fasta_file does not exist"; exit 1; }
[[ ! -f "$regions_file" ]] && { echo "Error: $regions_file does not exist"; exit 1; }

echo "Reading regions file..."

# Detect regions file coordinate format (check for zero coordinates)
is_zero_based=$(awk '{if($2==0 || $3==0) {print 1; exit}}' "$regions_file")
if [[ "$is_zero_based" == "1" ]]; then
    echo "Detected 0-based coordinates, will convert automatically"
else
    echo "Using 1-based coordinates"
fi

# Process all regions in one pass
awk -v out="$output_file" -v zero_based="$is_zero_based" '
    BEGIN {
        # Read regions file, store in array
        while (getline < "'$regions_file'") {
            split($0, a, "\t")
            seq_id = a[1]
            start = a[2]
            end = a[3]
            
            # If 0-based coordinates, convert to 1-based (for internal processing)
            if (zero_based == "1") {
                start = start + 1
                # end remains unchanged (BED format end is half-open)
                # Note: if end is half-open, this needs verification
            }
            
            # Store region information, separated by commas
            if (seq_id in regions) {
                regions[seq_id] = regions[seq_id] "," start "," end
            } else {
                regions[seq_id] = start "," end
            }
        }
    }
    
    /^>/ {
        # Process previous sequence
        if (seq != "") {
            # Extract pure sequence ID (part before "|", remove leading ">")
            split(seq_header, header_parts, " | ")
            pure_id = header_parts[1]
            sub(/^>/, "", pure_id)
            
            # Check if there are regions to mask
            if (pure_id in regions) {
                split(regions[pure_id], coords, ",")
                # Mask each region
                for (i=1; i<length(coords); i+=2) {
                    start_1based = coords[i]
                    end_1based = coords[i+1]
                    
                    # Convert to 0-based index (awk substr starts at 1)
                    s = start_1based
                    e = end_1based
                    
                    # Boundary check
                    if (s >= 1 && e <= length(seq) && s <= e) {
                        prefix = substr(seq, 1, s-1)
                        replace = ""
                        for (j=1; j<=(e-s+1); j++) {
                            replace = replace "N"
                        }
                        suffix = substr(seq, e+1)
                        seq = prefix replace suffix
                    } else {
                        print "Warning: Coordinates out of range " pure_id ":" start_1based "-" end_1based " (sequence length: " length(seq) ")" > "/dev/stderr"
                    }
                }
            }
            # Output sequence (preserve full header)
            print seq_header > out
            print seq > out
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
            
            if (pure_id in regions) {
                split(regions[pure_id], coords, ",")
                for (i=1; i<length(coords); i+=2) {
                    start_1based = coords[i]
                    end_1based = coords[i+1]
                    s = start_1based
                    e = end_1based
                    if (s >= 1 && e <= length(seq) && s <= e) {
                        prefix = substr(seq, 1, s-1)
                        replace = ""
                        for (j=1; j<=(e-s+1); j++) {
                            replace = replace "N"
                        }
                        suffix = substr(seq, e+1)
                        seq = prefix replace suffix
                    }
                }
            }
            print seq_header > out
            print seq > out
        }
    }
' "$fasta_file"

echo "Done! Output file: $output_file"