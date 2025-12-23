#!/bin/bash

# Set variables


### Extract putative HGT regions ###

# Loop over all fasta files

for fastafile in *.fasta; do

	#genome
	genome="${fastafile}"
	
	#extract a basename
	basename="${fastafile%.fasta}"
	
	#bed file
	bed_file-"${basename}_filtered3.bed"

	# Extracting regions from genome
	bedtools slop \
    	-i ${bed_file} -g ${genome}.fai -b 300 | \
    	bedtools getfasta \
    	-fi ${genome} -bed - | \
    	sed "s/^>/>${prefix}_/" > ${basename}_contigs-flanked.fasta	 
	 
	else
   		echo "Missing genome file for: $fastafile"
  fi
done
