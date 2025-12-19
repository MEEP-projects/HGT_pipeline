#!/bin/bash

for fasta in *_contigs-flanked.fasta; do
    out="${fasta%.fasta}.filtered.fasta"
    echo "Writing filtered sequences to $out"

    awk '
        BEGIN { RS=">"; FS="\n" }

        NR>1 {
            header = $1
            seq = ""
            for (i = 2; i <= NF; i++) seq = seq $i

            # Sequences <650 bp: keep by default
            if (length(seq) < 650) {
                keep = 1
            } else {
                # Extract first / last 300 bp
                first300 = substr(seq, 1, 300)
                last300  = substr(seq, length(seq) - 299, 300)

                # Count Ns (NOT contiguous, total count)
                n_first = gsub(/N/, "", first300)
                n_last  = gsub(/N/, "", last300)

                # Reject if either end has >=150 Ns
                keep = (n_first < 150 && n_last < 150)
            }

            if (keep) {
                printf(">%s\n", header)
                # Wrap sequence at 60 chars
                for (i = 1; i <= length(seq); i += 60)
                    print substr(seq, i, 60)
            }
        }
    ' "$fasta" > "$out"

done
