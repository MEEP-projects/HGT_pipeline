**HGT analysis pipeline**
-------------

Description of the different steps and scripts used. The scripts outlined below are in the 'scripts' folder. The key output files are in the 'data' folder.

***1. Aligning putative Blattabacterium inserts***

Blattabacterium genomes are chopped up and aligned to the Blaberidae cockroach genome.

*Scripts:*
`1.1.chopping_genome.sh`  

*Step 1.1:* Chop up the Blattabacterium genome in 150 nucleotide chunks to prepare for the alignment. The script is run specifying the input and output name, as well as the length of the 'chunks' you want chopped up:  
`bash 1.1.chopping_genome.sh Blattabacterium-genome.fasta Blattabacterium-genome_chopped.fasta 150`  
After running the script on each genome, combine the various chopped up genomes with 'cat.'

*Step 1.2:* Align the chopped up Blattabacterium to the reference host genome using bwa mem, implementing default parameters:  
`bwa index reference-genome.fasta`  
`bwa mem reference-genome.fasta Blattabacterium-genome_chopped.fasta > alignment.sam`  

If needed, you can extract the longest contigs before the alignment using the script 'extract-longest-contigs.sh'. Here's how you would extract the top 3 longest contigs.
`bash extract-longest-contigs.sh assembly-input.fasta output.fasta 3`  


***2. Creating a BED file***

*Scripts:*
`2.1.extracting-bed.sh`  
`2.2.annotating-bed.sh`  

*Step 2.1:* The alignment is converted into a BED file, representing the putative HGT regions. Overlapping Blattabacterium chunk alignments and near neighbouring alignments are merged into a single putative HGT region. Regions shorter than a specified length are filtered out. The following parameters are used in this script:  

# merging_gap=150 --> this is the acceptable gap between neighbouring aligned reads that will be merged into a single putative HGT insert
# min_length=75 --> this is the minimum putative HGT length to retain in the BED file

*Step 2.2:* Annotating the BED file using the genome assembly annotation; i.e. noting whether each putative HGT region sits within and gene, and if so, what part of the gene. This script will output multiple lines if it hits to multiple features (e.g. gene and exon) and if it overlaps features (e.g. it it spans an intergenic region and a gene this will be displayed on multiple lines with the relevant coordinates).

## To Do ##
Append sequence IDs that contribute to this region, separated with a semi-colon. this is to see what reads are found in more than one species - i.e. this is to figure out if they are conserved - will need to eventually pull out these regions.
There is a script called 'extracting_put-HGT_reads_TO-TEST.sh' that might be able to do this. It's a modified version of '2.1.extracting-bed.sh'.
