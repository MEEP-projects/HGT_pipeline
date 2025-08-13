# -------- SETTINGS --------
# Change this to the folder containing your FASTA files
fasta_dir = "/Volumes/LaCie/USyd_working/GC/Genomes"

# Output files
per_seq_csv = "gc_content_per_sequence.csv"
per_file_csv = "gc_content_per_file.csv"
# --------------------------

import os
import pandas as pd
from Bio import SeqIO

def safe_read_fasta(path):
    """Try reading a FASTA, ignore invalid bytes."""
    with open(path, "r", encoding="utf-8", errors="replace") as handle:
        return list(SeqIO.parse(handle, "fasta"))

# Store results
seq_results = []
file_results = []

for fasta_file in [f for f in os.listdir(fasta_dir) if f.endswith(".fasta")]:
    fasta_path = os.path.join(fasta_dir, fasta_file)
    sequences = safe_read_fasta(fasta_path)
    
    # Skip empty files
    if not sequences:
        print(f"Warning: {fasta_file} has no sequences, skipping.")
        continue
    
    # Per-sequence GC
    for seq_record in sequences:
        seq = str(seq_record.seq).upper()
        gc_count = seq.count("G") + seq.count("C")
        atgc_count = seq.count("A") + seq.count("T") + seq.count("G") + seq.count("C")
        gc_fraction = (gc_count / atgc_count * 100) if atgc_count > 0 else 0
        seq_results.append({
            "file": fasta_file,
            "sequence_id": seq_record.id,
            "gc_percent": gc_fraction
        })
    
    # Per-file GC across all sequences combined
    combined_seq = "".join([str(s.seq).upper() for s in sequences])
    gc_count = combined_seq.count("G") + combined_seq.count("C")
    atgc_count = combined_seq.count("A") + combined_seq.count("T") + combined_seq.count("G") + combined_seq.count("C")
    gc_fraction_file = (gc_count / atgc_count * 100) if atgc_count > 0 else 0
    file_results.append({
        "file": fasta_file,
        "gc_percent": gc_fraction_file,
        "num_sequences": len(sequences)
    })

# Save results
pd.DataFrame(seq_results).to_csv(per_seq_csv, index=False)
pd.DataFrame(file_results).to_csv(per_file_csv, index=False)

print(f"Done! Results saved to {per_seq_csv} and {per_file_csv}.")
