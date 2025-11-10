# Now that blattabacterium inserts are downloaded, we align
# to the reference genomes to example location of origin.

# Requires bwa, samtools, bedtools
    
import os
import pandas as pd
import subprocess

# input
insert_dir = "/Users/kyleewart/Downloads/HGT_working/7.v2"
insert_fastas = [f for f in os.listdir(insert_dir) if f.endswith(".fasta")]
references = ["/Users/kyleewart/Downloads/HGT_working/Blattabacterium_refs/" + f for f in os.listdir("/Users/kyleewart/Downloads/HGT_working/Blattabacterium_refs") if f.endswith(".fasta")]
df = pd.read_csv("/Users/kyleewart/Downloads/HGT_working/blatta_refs_hosts.csv")

# output
output_dir = "/Users/kyleewart/Downloads/HGT_working/out"
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

# Align
for i, fasta in enumerate(insert_fastas):
    cmd = f"""
        bwa mem /Users/kyleewart/Downloads/HGT_working/Blattabacterium_refs/{matched_refs[i]}.fasta {insert_dir}/{fasta} | 
        samtools view -b -F 256 | samtools sort |
        bedtools genomecov -ibam stdin -bga > {output_dir}/{species_tags[i]}_cov.txt
    """
    subprocess.run(cmd, shell=True)
