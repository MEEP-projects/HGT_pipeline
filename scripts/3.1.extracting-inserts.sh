#!/bin/bash

# Set variables


### Extract putative HGT regions ###

# bed file with putative HGT regions
bed_basename=P-crib_Blatta-chunk-alignment_aligned-segments
# Target genome
genome=Panesthia-cribrata_genome-assembly.fa
# Prefix to be appended at the start of the sequence ID (to help interpret the BLAST results later)
prefix=N-hanni

# Extracting regions from genome
bedtools getfasta -fi ${genome} -bed ${bed_basename}.bed | sed "s/^>/>${prefix}_/" > ${bed_basename}.fasta
