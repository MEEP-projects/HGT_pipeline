#!/bin/bash

#########################
### Bacteria database ###
#########################

# Downloaded from GTDB (https://gtdb.ecogenomic.org/downloads)
# Also removed duplicate ID’s with:
#seqkit rmdup GenBank_unfiltered.fasta > GenBank_filtered.fasta
# And removed Blattabacterium sequences with:
#seqkit grep -p "Blattabacterium" your_large_file.fasta | seqkit seq -n > blattabacterium_ids.txt
#seqkit grep -v -f blattabacterium_ids.txt your_large_file.fasta > filtered_output.fasta

#############################################
## Identifying non-target bacteria regions ##
#############################################

## Set variables
# bed file with putative HGT regions
bed_basename=P-tryoni-tryoni_Z005_filtered2_no-repeats_inserts
# Target genome
genome=P-tryoni-tryoni_Z005_genome-assembly.fa
# Number of threads to use for BLAST
threads=10
# Blattabacterium BLAST database
blatta_db=blattabacterium.fasta
# Bacteria BLAST database (using GTDB database; https://gtdb.ecogenomic.org/downloads)
bacteria_db=bacteria.fasta
# BLAST binaries path if needed
#export PATH=/System/Volumes/Data/Users/kyleewart/anaconda3/envs/snippy_env/bin:$PATH
# If not done already, make BLAST database for the Blattabacterium and bacteria genome fasta databases
#makeblastdb -in ${blatta_db} -dbtype nucl
#makeblastdb -in ${bacteria_db} -dbtype nucl


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
rm ${bed_basename}_BLASTing-bacteria-temp1.csv ${bed_basename}_BLASTing-bacteria-temp2.csv ${bed_basename}_BLASTing-bacteria-temp3.csv query_ids.txt hits_ids.txt no_hits_ids.txt no_hits.csv

