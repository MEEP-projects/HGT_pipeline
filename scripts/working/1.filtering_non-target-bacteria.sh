#!/bin/bash

#########################
### Bacteria database ###
#########################

# Downloaded from GTDB (https://gtdb.ecogenomic.org/downloads)
# Using the GCF (RefSeq) version
#find GCF -type f -name "*.gz" -not -name "._*" -print0 | xargs -0 gzcat > all_genomes.fna

# Removed duplicate ID’s with:
#seqkit rmdup GenBank_unfiltered.fasta > GenBank_filtered.fasta
# Didn't remove any; there are 2009663 sequences
# And removed Blattabacterium sequences with:
#seqtk seq -A all_GCF.fasta | grep '^>' | sed 's/^>//' > all_ids.txt
#grep -i 'Blattabacterium' all_ids.txt > to_remove.txt
#grep -v -F -f to_remove.txt all_ids.txt > to_keep.txt
#seqtk subseq all_GCF.fasta to_keep.txt > all_GCF_no-blattabacterium.fasta
# 57 sequences removed

# Made a BLAST database for the filtered bacteria genome database
#makeblastdb -in all_GCF_no-blattabacterium.fasta -dbtype nucl
#makeblastdb -in all_GCF_no-blattabacterium.fasta -dbtype nucl
#############################################
## Identifying non-target bacteria regions ##
#############################################

## Set variables
# bed file with putative HGT regions
bed_basename=Panesthia-lata_filtered4
# Target genome
genome=M1_flye-assembly_run2_polished-it2.fasta
# Number of threads to use for BLAST
threads=2
# Blattabacterium BLAST database
blatta_db=Blattabacterium-db.fasta
# Bacteria BLAST database (using GTDB database; https://gtdb.ecogenomic.org/downloads)
bacteria_db=all_GCF_no-blattabacterium.fasta
# BLAST binaries path if needed
#export PATH=/System/Volumes/Data/Users/kyleewart/anaconda3/envs/snippy_env/bin:$PATH


# Index the genome
# Check if the index file exists
if [ ! -f "${genome}.fai" ]; then
    echo "Index file not found. Indexing the genome..."
    samtools faidx ${genome}
else
    echo "Index file already exists. Skipping indexing."
fi

# Extract putative HGT regions
bedtools getfasta -fi ${genome} -bed ${bed_basename}.bed > ${bed_basename}.fasta

## BLAST each of the inserts against Blattabacterium genome database
blastn -query ${bed_basename}.fasta \
	-db ${blatta_db} \
	-out ${bed_basename}_BLASTing-Blatta-temp1.csv \
	-outfmt "10 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore qcovs" \
	-num_threads ${threads}
## OUTPUT COLUMNS
#	#	query id	subject id	% identity	alignment length	mismatches	gap opens	q. start	q. end	s. start	s. end	evalue	bit score	query coverage (%)

## Parse output
# Sort the BLAST hits by query ID, e-value, % identity, and alignment length
sort -t, -k1,1 -k11,11g -k3,3gr -k4,4nr ${bed_basename}_BLASTing-Blatta-temp1.csv > ${bed_basename}_BLASTing-Blatta-temp2.csv
# Make sure this is sorting correctly

# Extract top hit for each insert
awk -F',' '!seen[$1]++' ${bed_basename}_BLASTing-Blatta-temp2.csv > ${bed_basename}_BLASTing-Blatta-temp3.csv

# Extract the query IDs from your original FASTA file
grep ">" ${bed_basename}.fasta | sed 's/>//' > query_ids.txt

# Extract the query IDs from the filtered BLAST output
awk -F, '{print $1}' ${bed_basename}_BLASTing-Blatta-temp3.csv | sort | uniq > hits_ids.txt

# Find the query IDs with no hit
comm -23 <(sort query_ids.txt) <(sort hits_ids.txt) > no_hits_ids.txt

# Create rows of NAs for these hits
awk 'BEGIN {OFS=","} {print $1, "NA", "NA", "NA", "NA", "NA", "NA", "NA", "NA", "NA", "NA", "NA", "NA"}' no_hits_ids.txt > no_hits.csv

# Combine the second hits and the no hits into a final output
cat ${bed_basename}_BLASTing-Blatta-temp3.csv no_hits.csv > ${bed_basename}_BLASTing-Blatta.csv

# Clean up files
rm ${bed_basename}_BLASTing-Blatta-temp1.csv ${bed_basename}_BLASTing-Blatta-temp2.csv ${bed_basename}_BLASTing-Blatta-temp3.csv query_ids.txt hits_ids.txt no_hits_ids.txt no_hits.csv


## BLAST each of the inserts against bacteria genome database
blastn -query ${bed_basename}.fasta \
	-db ${bacteria_db} \
	-out ${bed_basename}_BLASTing-bacteria-temp1.csv \
	-outfmt "10 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore qcovs" \
	-num_threads ${threads}

## Parse output
# Sort the BLAST hits by query ID, e-value, % identity, and alignment length
sort -t, -k1,1 -k11,11g -k3,3gr -k4,4nr ${bed_basename}_BLASTing-bacteria-temp1.csv > ${bed_basename}_BLASTing-bacteria-temp2.csv
# Make sure this is sorting correctly

# Extract top hit for each insert
awk -F',' '!seen[$1]++' ${bed_basename}_BLASTing-bacteria-temp2.csv > ${bed_basename}_BLASTing-bacteria-temp3.csv

# Extract the query IDs from your original FASTA file
grep ">" ${bed_basename}.fasta | sed 's/>//' > query_ids.txt

# Extract the query IDs from the filtered BLAST output
awk -F, '{print $1}' ${bed_basename}_BLASTing-bacteria-temp3.csv | sort | uniq > hits_ids.txt

# Find the query IDs with no hit
comm -23 <(sort query_ids.txt) <(sort hits_ids.txt) > no_hits_ids.txt

# Create rows of NAs for these hits
awk 'BEGIN {OFS=","} {print $1, "NA", "NA", "NA", "NA", "NA", "NA", "NA", "NA", "NA", "NA", "NA", "NA"}' no_hits_ids.txt > no_hits.csv

# Combine the second hits and the no hits into a final output
cat ${bed_basename}_BLASTing-bacteria-temp3.csv no_hits.csv > ${bed_basename}_BLASTing-bacteria.csv

# Clean up files
rm ${bed_basename}_BLASTing-bacteria-temp1.csv ${bed_basename}_BLASTing-bacteria-temp2.csv ${bed_basename}_BLASTing-bacteria-temp3.csv query_ids.txt hits_ids.txt no_hits_ids.txt no_hits.csv ${bed_basename}.fasta

