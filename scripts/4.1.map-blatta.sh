#!/bin/bash

#TODO: Update directory structure
#Execute in  "../data/Blattabacterium/map-to-blatta" for now

REFERENCE="GCF_038284835.1_ASM3828483v1_genomic.fna"
OUTPUT_DIR="../map-to-blatta"

# Loop through all .fna files and echo their names
for FASTA in $(ls ../fasta_files/*.fasta); do
    BASENAME=$(basename "${FASTA}" .fasta)
    
    # Map the .fasta file to the reference using bwamem2
    bwa-mem2 mem ${REFERENCE} ${FASTA} > "${OUTPUT_DIR}/${BASENAME}.sam"
    
    # Convert the SAM file to BAM format using samtools
    samtools view -Sb "${OUTPUT_DIR}/${BASENAME}.sam" > "${OUTPUT_DIR}/${BASENAME}.bam"
    
    # Clean up sam files to save memory
    rm "${OUTPUT_DIR}/${BASENAME}.sam"
done