#!/bin/bash

# Loop over all fasta files

for fastafile in *_extracted-inserts.fasta; do

  base="${fastafile%_extracted-inserts.fasta}"

  # Check if the FASTA file exists
  if [[ -f "$fastafile" ]]; then

    # Run sdust
    minimap/sdust "$fastafile" > "${base}_sdust.txt"
    echo "Produced: ${base}_sdust.txt"
  else
    echo "Missing FASTA file for: $fastafile"
  fi
done