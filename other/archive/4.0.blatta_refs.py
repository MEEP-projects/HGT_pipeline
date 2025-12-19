# Download blatta references. Used in step 4.1 and 4.2

# Requires efectch

import subprocess
import time
import pandas as pd
import os

refs_to_hosts = "data/Blattabacterium/blatta_refs_hosts.csv"
output_dir = "data/Blattabacterium/refs"

os.makedirs(output_dir, exist_ok=True)

# read and download references
df = pd.read_csv(refs_to_hosts)
accessions = df["accession"].unique().tolist()

# Donload references
for acc in accessions:
    output_file = f"{output_dir}/{acc}.fasta"
    cmd = f"efetch -db nucleotide -id {acc} -format fasta > {output_file}"
    
    with open(output_file, "w") as f:
        subprocess.run(cmd, shell=True)
        
    time.sleep(1)  # Sleep to avoid rate limiting
    