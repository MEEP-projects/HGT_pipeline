#!/bin/bash
# Set variables
annotation=Panesthia-cribrata_fgenesh-annotation.gff3
HGT_regions_basename=test
# Path to bedtools if needed
#export PATH=/data:$PATH

# Clean annotation file
awk '$1 !~ /^#/ && $1 != "" && NF >= 9 {print}' ${annotation} > ${annotation}_cleaned.gff3

# Convert GFF3 to BED
awk '$3 != "region" {print $1, $4-1, $5, $3, ".", $7, $9}' OFS="\t" ${annotation}_cleaned.gff3 > annotations.bed

# Sort BED files
bedtools sort -i ${HGT_regions_basename}.bed > ${HGT_regions_basename}_sorted.bed
bedtools sort -i annotations.bed > annotations_sorted.bed

# Find overlaps
bedtools intersect -a ${HGT_regions_basename}_sorted.bed -b annotations_sorted.bed -wa -wb > overlaps.txt

# Find non-overlapping regions
bedtools subtract -a ${HGT_regions_basename}_sorted.bed -b annotations_sorted.bed > non_overlapping.txt

# Annotate overlaps
awk 'BEGIN {OFS="\t"} 
{
    key = $1":"$2"-"$3;
    feature[key] = feature[key] ? feature[key]","$8 : $8;
    details[key] = details[key] ? details[key]","$9 : $9;
    reads[key] = reads[key] ? reads[key]","$4 : $4;
} 
END {
    for (k in feature) {
        gsub(/,\.$/, "", feature[k]);
        gsub(/,\.$/, "", details[k]);
        print k, feature[k], details[k], reads[k];
    }
}' overlaps.txt | awk 'BEGIN {OFS="\t"} 
{
    split($1, coords, "[:-]");
    print coords[1], coords[2], coords[3], $2, $3, $4;
}' > ${HGT_regions_basename}_annotated_overlaps.tsv

# Annotate non-overlapping regions
awk 'BEGIN {OFS="\t"}
{
    print $1, $2, $3, "intergenic", ".", $4;
}' non_overlapping.txt > ${HGT_regions_basename}_annotated_non_overlaps.tsv

# Combine annotations
{
    echo -e "Chromosome\tStart\tEnd\tFeature_Type\tDetails\tReads"
    cat ${HGT_regions_basename}_annotated_overlaps.tsv ${HGT_regions_basename}_annotated_non_overlaps.tsv | sort -k1,1 -k2,2n
} > ${HGT_regions_basename}_annotated.tsv

# Clean up
rm annotations.bed annotations_sorted.bed non_overlapping.txt overlaps.txt ${annotation}_cleaned.gff3 ${HGT_regions_basename}_sorted.bed ${HGT_regions_basename}_annotated_overlaps.tsv ${HGT_regions_basename}_annotated_non_overlaps.tsv
