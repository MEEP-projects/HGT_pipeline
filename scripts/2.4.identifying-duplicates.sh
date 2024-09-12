#!/bin/bash

##########################################
## Characterising duplicate HGT inserts ##
##########################################

## Set variables
# bed file with putative HGT regions
bed_basename=P-crib_Blatta-chunk-alignment_aligned-segments
# Target genome
genome=Panesthia-cribrata_genome-assembly.fa
# Flanking length (on either end of putative insert)
flank=300
# Number of threads to use for BLAST
threads=2
# BLAST binaries path if needed
export PATH=/Users/kyleewart/.sequenceserver/ncbi-blast-2.2.30+/bin:$PATH

# Index the genome
# Check if the index file exists
if [ ! -f "${genome}.fai" ]; then
    echo "Index file not found. Indexing the genome..."
    samtools faidx ${genome}
else
    echo "Index file already exists. Skipping indexing."
fi


## Create new bed file with flanking regions, then extract putative HGT regions with the flanking region
bedtools slop -i ${bed_basename}.bed -g ${genome}.fai -b ${flank} > ${bed_basename}_slop.bed
bedtools getfasta -fi ${genome} -bed ${bed_basename}_slop.bed > ${bed_basename}_flanked.fasta


## BLAST each of the inserts against all of the inserts to investigate whether any are very similar
makeblastdb -in ${bed_basename}_flanked.fasta -dbtype nucl
blastn -query ${bed_basename}_flanked.fasta \
	-db ${bed_basename}_flanked.fasta \
	-out ${bed_basename}_duplicate-BLASTing_temp.csv \
	-outfmt "10 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore qcovs" \
	-num_threads ${threads}
## OUTPUT COLUMNS
#	#	query id	subject id	% identity	alignment length	mismatches	gap opens	q. start	q. end	s. start	s. end	evalue	bit score	query coverage (%)

## Parse output
# Sort the BLAST hits by query ID, e-value, % identity, and alignment length
sort -t, -k1,1 -k11,11g -k3,3gr -k4,4nr ${bed_basename}_duplicate-BLASTing_temp.csv > sorted_hits.csv

# Extract the top hit per region where the query ID does not match the subject ID (i.e. where it doesn't BLAST to itself)
awk -F, '{
    if (!($1 in top_hit) && $1 != $2) {
        top_hit[$1]=$0;
    }
} END {
    for (i in top_hit) print top_hit[i]
}' sorted_hits.csv > filtered_hits.csv

# Extract the query IDs from your original FASTA file
grep ">" ${bed_basename}_flanked.fasta | sed 's/>//' > query_ids.txt

# Extract the query IDs from the filtered BLAST output
awk -F, '{print $1}' filtered_hits.csv | sort | uniq > hits_ids.txt

# Find the query IDs with no second hit
comm -23 <(sort query_ids.txt) <(sort hits_ids.txt) > no_hits_ids.txt

# Create rows of NAs for these hits
awk 'BEGIN {OFS=","} {print $1, "NA", "NA", "NA", "NA", "NA", "NA", "NA", "NA", "NA", "NA", "NA", "NA"}' no_hits_ids.txt > no_hits.csv

# Combine the second hits and the no hits into a final output
cat filtered_hits.csv no_hits.csv > ${bed_basename}_duplicate-BLASTing_filtered.csv

# Clean up files
rm ${bed_basename}_slop.bed ${bed_basename}_flanked.fasta* ${bed_basename}_duplicate-BLASTing_temp.csv sorted_hits.csv filtered_hits.csv query_ids.txt hits_ids.txt no_hits_ids.txt no_hits.csv

## For high-ish hits, only keep one of the inserts?
# What query coverage to filter on?






