# GC content for inserts (8.v1) and corresponding reference genomes

import os
import pandas as pd
from Bio import SeqIO, SeqUtils

# Read insert sequences and calculate GC content
insert_dir = "data/inserts_BED/8.v1/insert-sequences"
insert_fastas = [f for f in os.listdir(insert_dir) if f.endswith(".fasta")]
references = ["data/Blattabacterium/refs/" + f for f in os.listdir("data/Blattabacterium/refs") if f.endswith(".fasta")]

df = pd.read_csv("data/Blattabacterium/blatta_refs_hosts.csv")

# Match inserts to references
species_tags = []
for fasta in insert_fastas:
    tag = fasta.split("_")[0].split("-")
    species_tags.append("-".join([tag[0][0]] + tag[1:]))
    
matched_refs = []
for tag in species_tags:
    ref_row = df[df['reference-tag'].apply(lambda x: x in tag)]
    matched_refs.append(ref_row['accession'].values[0])
    
# Calculate GC content for inserts
insert_gc = []
ref_gc = []
host = []
for idx, fasta in enumerate(insert_fastas):
    ref = SeqIO.read(os.path.join("data/Blattabacterium/refs", matched_refs[idx] + ".fasta"), "fasta")
    reference_gc = SeqUtils.gc_fraction(ref.seq)

    for seq_record in SeqIO.parse(os.path.join(insert_dir, fasta), "fasta"):
        insert_gc.append(SeqUtils.gc_fraction(seq_record.seq))
        ref_gc.append(reference_gc)
        host.append(species_tags[idx])
        
# Create DataFrame with results. Each row is an insert
results = pd.DataFrame({
    'insert_gc': insert_gc,
    'reference_gc': ref_gc,
    'host': host
})

os.makedirs("data/Blattabacterium/gc_content", exist_ok=True)
results.to_csv("data/Blattabacterium/gc_content/gc_content.csv", index=False) 