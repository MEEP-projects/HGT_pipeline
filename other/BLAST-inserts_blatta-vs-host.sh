#!/bin/bash

############################################################################################################
### BLAST putative inserts against the species-specific Blattabacterium genome and inserts in other taxa ###
############################################################################################################

## Make sure all inserts from all host species (as separate fasta files), including the target species considered in this script, are in one folder ##

# Set variables
inserts_dir=inserts
target_inserts=P-crib_Blatta-chunk-alignment_aligned-segments.fasta
target_blattabacterium=CP142614.1.fasta
output_basename=P-crib_BLAST_blatta-vs-hosts
threads=2
# BLAST binaries path if needed
export PATH=/Users/kyleewart/.sequenceserver/ncbi-blast-2.2.30+/bin:$PATH

## BLASTing against Blattabacterium
makeblastdb -in ${target_blattabacterium} -dbtype nucl
# Run BLAST
blastn -query ${inserts_dir}/${target_inserts} \
	-db ${target_blattabacterium} \
	-out ${output_basename}_blatta-hits_temp.csv \
	-outfmt "10 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore qcovs" \
	-num_threads ${threads}
## OUTPUT COLUMNS
#	#	query id	subject id	% identity	alignment length	mismatches	gap opens	q. start	q. end	s. start	s. end	evalue	bit score	query coverage


## Need the top hit per region
# If there are multiple hits, take the one with the lowest e-value
awk -F, '{if (!($1 in a) || $11 < a[$1]) {a[$1]=$11; b[$1]=$0}} END {for (i in b) print b[i]}' ${output_basename}_blatta-hits_temp.csv > filtered_hits.csv

# If there are not hits, add the contig name, and add a row of NAs.
# Extract the query IDs from your original FASTA file
grep ">" ${inserts_dir}/${target_inserts} | sed 's/>//' > query_ids.txt
# Extract the query IDs from the filtered BLAST output
awk -F, '{print $1}' filtered_hits.csv | sort | uniq > hits_ids.txt
# Find the query IDs with no hits
comm -23 <(sort query_ids.txt) <(sort hits_ids.txt) > no_hits_ids.txt
# Create rows of NAs for these hits
awk 'BEGIN {OFS=","} {print $1, "NA", "NA", "NA", "NA", "NA", "NA", "NA", "NA", "NA", "NA", "NA", "NA"}' no_hits_ids.txt > no_hits.csv

# Combine both files
cat filtered_hits.csv no_hits.csv > ${output_basename}_blatta-hits.csv
# Clean up
rm filtered_hits.csv no_hits.csv no_hits_ids.txt hits_ids.txt query_ids.txt ${output_basename}_blatta-hits_temp.csv ${target_blattabacterium}.*



### BLAST putative inserts against database of putative inserts for all host genomes, excluding the target genome ###

# Make database, excluding the target species.
ls ${inserts_dir}/*.fasta | grep -v "${target_inserts}" | xargs cat > concatenated_inserts.fasta
makeblastdb -in concatenated_inserts.fasta -dbtype nucl

# Do BLAST
blastn -query ${inserts_dir}/${target_inserts} \
	-db concatenated_inserts.fasta \
	-out ${output_basename}_inserts-hits_temp.csv \
	-outfmt "10 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore qcovs" \
	-num_threads ${threads}

## Need the top hit per region
# If there are multiple hits, take the one with the lowest e-value
awk -F, '{if (!($1 in a) || $11 < a[$1]) {a[$1]=$11; b[$1]=$0}} END {for (i in b) print b[i]}' ${output_basename}_inserts-hits_temp.csv > filtered_hits.csv

# If there are not hits, add the contig name, and add a row of NAs.
# Extract the query IDs from your original FASTA file
grep ">" ${inserts_dir}/${target_inserts} | sed 's/>//' > query_ids.txt
# Extract the query IDs from the filtered BLAST output
awk -F, '{print $1}' filtered_hits.csv | sort | uniq > hits_ids.txt
# Find the query IDs with no hits
comm -23 <(sort query_ids.txt) <(sort hits_ids.txt) > no_hits_ids.txt
# Create rows of NAs for these hits
awk 'BEGIN {OFS=","} {print $1, "NA", "NA", "NA", "NA", "NA", "NA", "NA", "NA", "NA", "NA", "NA", "NA"}' no_hits_ids.txt > no_hits.csv

# Combine both files
cat filtered_hits.csv no_hits.csv > ${output_basename}_inserts-hits.csv
# Clean up
rm filtered_hits.csv no_hits.csv no_hits_ids.txt hits_ids.txt query_ids.txt ${output_basename}_inserts-hits_temp.csv concatenated_inserts.fast*

