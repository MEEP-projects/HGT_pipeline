#!/bin/bash

# Set variables
raw_seq=raw_Z14_trimmed.fasta
reference_genome=Z014_genome.fasta
sample=Z14-2
threads=16
working_dir=/data/Zhuzhi/step2.6/Z014

cd ${working_dir}

# Performing the alignment with minimap2
minimap2 -ax map-ont -L -t ${threads} ${reference_genome} ${raw_seq} > ${sample}_aln.sam

# Filter and sort alignment file
samtools view -Sb ${sample}_aln.sam \
	| samtools sort -n -@${threads} - \
	| samtools fixmate -m - - \
	| samtools sort -@${threads} - \
	| samtools markdup -r - ${sample}_aln-sorted.bam

# Clean original alignment
rm ${sample}_aln.sam

