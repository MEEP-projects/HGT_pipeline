from collections import defaultdict

# The script reads each BED file and stores the first occurrence of each read.
# It finds reads that are common between the two files.
# It writes the common reads along with their regions from both files into an output TSV file.

# File names from both genomes
bed_file1 = "P-crib_Blatta-chunk-alignment_aligned-segments.bed"
bed_file2 = "N-hanni_Blatta-chunk-alignment_aligned-segments.bed"
output_file = "P-crib_N-hanni_common-reads_output.tsv"

# Function to parse the BED file and store the first occurrence of each read
def parse_bed_file(bed_file):
    read_dict = defaultdict(list)
    with open(bed_file, 'r') as f:
        for line in f:
            fields = line.strip().split('\t')
            contig = fields[0]
            start = fields[1]
            end = fields[2]
            reads = fields[3].split(',')
            for read in reads:
                if read not in read_dict:
                    read_dict[read] = [contig, start, end]
    return read_dict

# Load the reads from both BED files
reads_file1 = parse_bed_file(bed_file1)
reads_file2 = parse_bed_file(bed_file2)

# Find common reads
common_reads = set(reads_file1.keys()) & set(reads_file2.keys())

# Write the common reads and their regions to an output file
with open(output_file, 'w') as out:
    out.write("Read_ID\tFile1_Contig\tFile1_Start\tFile1_End\tFile2_Contig\tFile2_Start\tFile2_End\n")
    for read in common_reads:
        file1_region = reads_file1[read]
        file2_region = reads_file2[read]
        out.write(f"{read}\t{file1_region[0]}\t{file1_region[1]}\t{file1_region[2]}\t{file2_region[0]}\t{file2_region[1]}\t{file2_region[2]}\n")

print(f"Common reads have been written to {output_file}")
