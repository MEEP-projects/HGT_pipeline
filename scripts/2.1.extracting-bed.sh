#!/bin/bash

#########################################################################################################
### Create a BED file of putative HGT from aligned reads, including overlaps and near neighbour reads ###
#########################################################################################################

# This is the alignment file generated using bwa (with the Blattabacterium chunks as the input reads)
alignment_basename=Z014_put-inserts_alignment_v2
# The acceptable gap between neighbouring aligned reads that will be merged into a single putative HGT insert
merging_gap=200
# Minimum putative HGT length to retain in the BED file
min_length=50
# Threads used
threads=24
# Path to bedtools
export PATH=/data:$PATH


# Convert BAM to SAM
samtools view -Sb ${alignment_basename}.sam > ${alignment_basename}.bam

# Convert BAM to BED
bedtools bamtobed -i ${alignment_basename}.bam > temp1.bed

# Sort bedfile
sort -k1,1 -k2,2n temp1.bed > temp2.bed

# Merge overlapping regions and those with a gap of less than the specified length
bedtools merge -i temp2.bed -d ${merging_gap} -c 4 -o distinct > temp3.bed

# Remove regions in the BED that are shorter than the specified length
awk -v filter="$min_length" '{if (($3 - $2) >= filter) print $0}' temp3.bed > ${alignment_basename}_aligned-segments.bed

# Remove temporary files
rm ${alignment_basename}.bam temp1.bed temp2.bed temp3.bed

# If you need to view the original alignment (e.g. in IGV) the SAM file should be converted to a BAM file and sorted and indexed.
#samtools view -@${threads} -b -F 4 ${alignment_basename}.sam | samtools sort -@${threads} -o ${alignment_basename}.bam
#samtools index ${alignment_basename}.bam

