#!/bin/bash

genome=$1
output=${2:-contig_lengths.txt}

[ ! -f "$genome" ] && { echo "file missing"; exit 1; }
    echo "running with awk"
    awk '
    /^>/ {
        if (name) print name"\t"len
        name=substr($0,2); sub(/ .*/,"",name)
        len=0
        next
    }
    {
        len += length($0)
    }
    END {
        if (name) print name"\t"len
    }' "$genome" > "$output"

echo "Number of Contigs: $(wc -l < $output)"
echo "Total lenth: $(awk '{sum+=$2} END {print sum}' $output) bp"