#!/bin/bash

#####################################
## Filtering duplicate HGT inserts ##
#####################################

## Set variables
# bed file with putative HGT regions
bed_basename=P-crib_Blatta-chunk-alignment_aligned-segments
# Duplicate BLAST results from previous step
dup_BLAST_res=P-crib_Blatta-chunk-alignment_aligned-segments_duplicate-BLASTing_res.csv
# identity % threshold
identity=90
# query coverage threshold
qcov=90

# Pull out instances where identity % and query coverage are both above the thresholds. Only keeping one of a set of reads (e.g. if 5 sequences are all have high hits to one another, 4 of these will be included in 'ids_to_remove.txt).
# Steps:
# 1. Filters the rows where % identity uery coverage are above the specified thresholds, excluding NA values.
# 2. extracts only the query id and subject id columns
# 3. Sorts to help identify groups of closely related reads, then an array seen[] is used to track which IDs have been encountered. For each pair, it checks if either the query id or subject id has already been seen. If not, it marks them as seen, prints the second ID (subject) to remove. This effectively keeps one ID from each group of related reads and lists the rest for removal.
awk -F ',' -v id="$identity" -v qc="$qcov" '$3 > id && $13 > qc && $3 != "NA" && $13 != "NA"' ${dup_BLAST_res} | \
	awk -F ',' '{print $1 "," $2}' | \
	sort | awk -F ',' '!seen[$1]++ && !seen[$2]++ {print $2}' > ids_to_remove.txt


# Remove these sequences from the original bed file.
#grep -v -F -f ids_to_remove2.txt ${bed_basename}.bed > ${bed_basename}_dup-filtered.bed


# Create a temporary file with a regex pattern
awk -F '[ :]' '{print $1 ":" $2}' ids_to_remove.txt | sed 's/$/|/' | tr -d '\n' | sed 's/|$//' > ids_regex.txt

# Filter bed
awk -F '\t' -v ids_regex="$(cat ids_regex.txt)" '
BEGIN { split(ids_regex, ids, "|") }
{
    match_found = 0
    for (i in ids) {
        if ($1 ~ ids[i]) {
            match_found = 1
            break
        }
    }
    if (!match_found) print $0
}' ${bed_basename}.bed > ${bed_basename}_dup-filtered.bed


# Count the lines (IDs) in ids_to_remove.txt
count=$(wc -l < ids_to_remove.txt)

# Clean up 
rm ids_to_remove.txt  ids_to_remove2.txt

# Print the count of removed IDs
echo "$count inserts have been removed."
