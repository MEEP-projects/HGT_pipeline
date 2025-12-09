# Now that blattabacterium inserts are downloaded, we align
# to the reference genomes to example location of origin.

# Requires bwa, samtools, bedtools

import os
import pandas as pd
import subprocess

# input
insert_dir = "/Users/kyleewart/Downloads/HGT_working/version2/sequences"
insert_fastas = [f for f in os.listdir(insert_dir) if f.endswith(".fasta")]
references = [
    "/Users/kyleewart/Downloads/HGT_working/version2/Blattabacterium_refs/" + f
    for f in os.listdir("/Users/kyleewart/Downloads/HGT_working/Blattabacterium_refs")
    if f.endswith(".fasta")
]
df = pd.read_csv("/Users/kyleewart/Downloads/HGT_working/version2/blatta_refs_hosts.csv")

## Example top lines of a 'blatta_refs_hosts.csv' file:
#sample-name,accession,sample-tag,reference-tag
#Blattella germanica,CP001487.1,B-germanica,B-germanica
#Diploptera punctata,CP049785.1,D-punctata,D-punctata
#Geoscapheus dilatatus,GCA_038272405.1,G-dilatatus,G-dilatatus

# output
output_dir = "/Users/kyleewart/Downloads/HGT_working/version2/out2"
os.makedirs(output_dir, exist_ok=True)

# index references
for ref in references:
    cmd = f"bwa index {ref}"
    subprocess.run(cmd, shell=True)

# Match inserts to references
species_tags = []
for fasta in insert_fastas:
    tag = fasta.split("_")[0].split("-")
    species_tags.append("-".join([tag[0][0]] + tag[1:]))

matched_refs = []
for tag in species_tags:
    ref_row = df[df['reference-tag'].apply(lambda x: x in tag)]
    matched_refs.append(ref_row['accession'].values[0])

# Align and count read start positions
for i, fasta in enumerate(insert_fastas):
    ref = f"/Users/kyleewart/Downloads/HGT_working/version2/Blattabacterium_refs/{matched_refs[i]}.fasta"
    bam_prefix = f"{output_dir}/{species_tags[i]}"

    # Align and create BAM (primary alignments only)
    cmd_align = f"""
        bwa mem {ref} {insert_dir}/{fasta} | \
        samtools view -b -F 0x904 | \
        samtools sort -o {bam_prefix}.bam
    """
    subprocess.run(cmd_align, shell=True)

    # Index BAM
    subprocess.run(f"samtools index {bam_prefix}.bam", shell=True)

    # Count read start positions (primary alignments only)
    cmd_starts = f"""
    	samtools view -F 0x904 {bam_prefix}.bam | \
    	awk '{{print $3"\\t"$4"\\t"$1}}' | \
    	sort -k1,1 -k2,2n | \
    	awk 'BEGIN{{OFS="\\t"}} {{
    		key=$1"\\t"$2
    		reads[key]=(reads[key] ? reads[key]","$3 : $3)
    		counts[key]++
    	}} END {{
    	for (k in counts) print k"\\t"counts[k]"\\t"reads[k]
    	}}' | sort -k1,1 -k2,2n > {bam_prefix}_start_counts.bed
    """

    subprocess.run(cmd_starts, shell=True)

# Output format
# Column 1: contig name
# Column 2: start coordinate (1-based)
# Column 3: number of reads starting at that position
# Column 4: name of insert/s that start at this position

