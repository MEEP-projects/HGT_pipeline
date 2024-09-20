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


***2. Characterising inserts***

Filtering and annotating the putative HGT inserts.

*Scripts:*  
`2.1.extracting-bed.sh`  
`2.2.identifying-contaminants.R`  
`2.3.identifying-duplicates.sh`  
`2.4.filtering-duplicates.sh`  
`2.5.annotating-bed.sh`  
`2.6.raw-read_assessment.sh`  

*Step 2.1:* The alignment is converted into a BED file, representing the putative HGT regions. Overlapping Blattabacterium chunk alignments and near neighbouring alignments are merged into a single putative HGT region. Regions shorter than a specified length are filtered out. The pipeline is run with the following:
`bash 2.1.extracting-bed.sh`  
The following key parameters need to be set within the bash script:  
- *merging_gap=150* --> this is the acceptable gap between neighbouring aligned reads that will be merged into a single putative HGT insert
- *min_length=50* --> this is the minimum putative HGT insert length to retain in the BED file

*Step 2.2:* Some of the inserts might be contaminant genuine Blattabacterium DNA. These potential contaminants are identified by comparing the length of the insert to the length of the contig which it sits on. If the proportion of the insert length vs contig length exceeds a certain threshold it is possibly a Blattabacterium contig, and hence removed. This is achieved using a pipeline in R:  
***Jil and Oscar are still working on this***

*Step 2.3:* The most common assembly error is false duplication, hence some duplicate inserts may be artefacts. To identify duplicates, each insert is extracted with some flanking region. It is then BLASTed against all other inserts within the genome, and the top hit is extracted (excluding the hit to itself). This BLAST search can be run for each genomes using the following:  
`bash 2.3.identifying-duplicates.sh`  
The following key parameter needs to be set within the bash script:  
- *flank=300* --> flanking length on either end of putative insert

Very high hits are considered false duplicates, and should be removed from the inserts file so that the number of inserts in the genome is not overestimated. This can be done by running:  
`bash 2.4.filtering-duplicates.sh`  
The following key parameters needs to be set within the bash script:  
- *identity=90* --> filtering out hits above 90% identity
- *qcov=90* --> filtering out hits above 90% query coverage

This output of the above will create another bed file with the suffic *_dup-filtered.bed*. It will also state how many inserts were removed. This filtered bed file will be used in subsequent steps.  

***Important note:*** *There may be groups of false duplicates (i.e. >2 regions that are very close to one another). The pipeline above only considers pairs of false duplicates - if there is a group, it will not remove them all. Hence, this pipeline should be repeated, until 0 inserts are removed; i.e. the output of script '2.4.filtering-duplicates.sh' should be input for '2.3.identifying-duplicates.sh', and the pipeline can then be followed as above. It might take 2-3 iterations to remove all false duplications (depending on the assembly quality). It's important to properly label your bed file after this filtering (you may be left with numerous bed files with growing '_dup-filtered.bed' suffixes.*  

*Step 2.4:* Some HGT inserts might be the result of a real duplication event, and some might have ‘jumped’ around the genome with a transposon. These are real inserts, but do not represent unique HGT events (i.e. one event occurred, then the insert was duplicated). These real duplications will have relatively high sequence similarity. Hence, to filter the genomes of duplicates, *Step 2.3* should be repeated, but changing the identify/coverage thresholds for script '2.3.identifying-duplicates.sh':  
- *identity=70* --> filtering out hits above 90% identity
- *qcov=70* --> filtering out hits above 90% query coverage

After running the pipeline with the updated identity and query coverage thresholds (and iterating through it a number of times where required) you will generate a bed file with no duplicates. Hence, while the output of *Step 2.3* will indicate the number of HGT inserts in the genome, and the output of *Step 2.3* will indicate the number of unique HGT insert events in the genome.  

*Step 2.5:* Annotating the filtered bed file using the genome assembly annotation; i.e. noting whether each putative HGT region sits within and gene, and if so, what part of the gene. This script will output multiple lines if it hits to multiple features (e.g. gene and exon) and if it overlaps features (e.g. it it spans an intergenic region and a gene this will be displayed on multiple lines with the relevant coordinates). This can be run with:  
`bash 2.5.annotating-bed.sh`  

*Step 2.5:* When observing the raw sequence read alignments against the putative HGT inserts, some reads span the insert regions and elongate upstream/downstream for hundreds or thousands of nucleotides. While other reads are truncated and aligned to only the insert region, and typically have several nucleotide differences to the reads that elongate upstream/downstream. the former scenario are likely cockroach reads containing the insert region, while the latter scenario are likely Blattabacterium reads (some Blattabacterium are likely included in the sequenced DNA). This pipeline counts the reads for the two scenarios for each insert as additional evidence that there are long reads supporting the former scenario.  
***Zhuzhi is still working on this***



