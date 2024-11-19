#!/bin/bash

###################################################################
### Age putative inserts based on hits to inserts in other taxa ###
###################################################################

## Make sure all inserts from all host species (as separate fasta files), including the target species considered in this script, are in one folder ##
# Only inlude ancestral inserts inferred from steps 3.2 and 3.3.

# Set variables
inserts_dir=inserts
target_inserts=B-germanica-v1_aligned-segments_filtered2_no-repeats.fasta
ancestral_inserts=ancestral-inserts/B-germanica-v1_ancestral_insert-seq-names.fasta
output_basename=B-germanica-v1_ancestral_insert-ages
threads=2
# BLAST binaries path if needed
#export PATH=/Users/kyleewart/.sequenceserver/ncbi-blast-2.2.30+/bin:$PATH

### BLAST putative inserts against database of putative inserts for all host genomes, excluding the target genome ###

# Make database, excluding the target species.
ls ${inserts_dir}/*.fasta | grep -v "${target_inserts}" | xargs cat > concatenated_inserts.fasta
makeblastdb -in concatenated_inserts.fasta -dbtype nucl

# Do BLAST
blastn -query ${ancestral_inserts} \
	-db concatenated_inserts.fasta \
	-out ${output_basename}_inserts-hits_temp.csv \
	-outfmt "10 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore qcovs" \
	-num_threads ${threads}

# Only keep hits that are >70% seq identity and >70% query coverage
awk -F"," '($3 > 70 && $13 > 70)' ${output_basename}_inserts-hits_temp.csv > ${output_basename}_inserts-hits_temp2.csv


# Process the filtered data to extract unique subject_id prefixes and append them to each unique query_id
awk -F"," '
{
    query_id = $1
    subject_id = $2

    # Extract the prefix from subject_id (everything before the first "_")
    split(subject_id, parts, "_")
    prefix = parts[1]

    # Collect unique prefixes for each query_id
    if (!seen[query_id, prefix]++) {
        if (prefix_list[query_id] == "") {
            prefix_list[query_id] = prefix
        } else {
            prefix_list[query_id] = prefix_list[query_id] "," prefix
        }
    }
}

# Step 2: Output unique query_ids and their corresponding prefixes
END {
    print "query_id\tsubject_id_prefixes"
    for (query_id in prefix_list) {
        print query_id "\t" prefix_list[query_id]
    }
}' ${output_basename}_inserts-hits_temp2.csv > ${output_basename}_inserts-hits_temp3.tsv

# If there are no hits for a particular query id, add the name, and add a row of NAs.
# Extract the query IDs from your original FASTA file
grep ">" ${ancestral_inserts} | sed 's/>//' > query_ids.txt
# Extract the query IDs from the filtered BLAST output
awk -F"\t" '{print $1}' ${output_basename}_inserts-hits_temp3.tsv | sort | uniq > hits_ids.txt
# Find the query IDs with no hits
comm -23 <(sort query_ids.txt) <(sort hits_ids.txt) > no_hits_ids.txt
# Create rows of NAs for these hits
awk 'BEGIN {OFS="\t"} {print $1, "NA"}' no_hits_ids.txt > no_hits.tsv

# Combine both files
cat ${output_basename}_inserts-hits_temp3.tsv no_hits.tsv > ${output_basename}_inserts_taxa-hits.tsv
# Clean up
rm no_hits.tsv no_hits_ids.txt hits_ids.txt query_ids.txt ${output_basename}_inserts-hits_temp.csv ${output_basename}_inserts-hits_temp2.csv ${output_basename}_inserts-hits_temp3.tsv concatenated_inserts.fast*
