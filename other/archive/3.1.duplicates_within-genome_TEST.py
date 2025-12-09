from collections import defaultdict

# File paths
input_bed = "P-crib_Blatta-chunk-alignment_aligned-segments.bed"
output_file = "P-crib_Blatta-chunk-alignment_aligned-segments_duplicate-regions.txt"

# Dictionary to track reads and the regions they appear in
read_regions = defaultdict(list)

# Read through the BED file and record each read with its region
with open(input_bed, "r") as infile:
    for line in infile:
        parts = line.strip().split("\t")
        region = f"{parts[0]}:{parts[1]}-{parts[2]}"
        reads = parts[3].split(",")
        
        for read in reads:
            read_regions[read].append(region)

# Filter reads that appear in more than one region and output them
with open(output_file, "w") as outfile:
    for read, regions in read_regions.items():
        if len(regions) > 1:
            regions_str = "; ".join(regions)
            outfile.write(f"{read}\t{regions_str}\n")

print("Script complete. Check the output file for results.")
