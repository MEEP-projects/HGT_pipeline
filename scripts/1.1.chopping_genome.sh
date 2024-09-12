#!/bin/bash

# Usage: ./1.1.chopping_genome.sh input.fasta output.fasta 150

input_fasta=$1
output_fasta=$2
seq_length=$3

awk -v len=$seq_length '
/^>/ {
    if (seqlen > 0) { 
        while (seqlen > len) {
            print ">" id"_"count substr(header, index(header," ")); 
            print substr(seq, 1, len);
            seq = substr(seq, len + 1);
            seqlen -= len;
            count += 1;
        }
        if (seqlen > 0) {
            print ">" id"_"count substr(header, index(header," ")); 
            print seq;
        }
    }
    header = $0;
    id = substr($0, 2, index($0, " ") - 2);  # Extract the FASTA ID
    seq = "";
    seqlen = 0;
    count = 1;
    next
} 
{
    seq = seq $0; 
    seqlen += length($0)
} 
END {
    if (seqlen > 0) {
        while (seqlen > len) {
            print ">" id"_"count substr(header, index(header," ")); 
            print substr(seq, 1, len);
            seq = substr(seq, len + 1);
            seqlen -= len;
            count += 1;
        }
        if (seqlen > 0) {
            print ">" id"_"count substr(header, index(header," ")); 
            print seq;
        }
    }
}' $input_fasta > $output_fasta
