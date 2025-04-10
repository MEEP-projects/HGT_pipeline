**HGT analysis pipeline**
-------------

Description of the different steps and scripts used. The scripts outlined below are in the 'scripts' folder. The key output files are in the 'data' folder.

***1. Aligning putative Blattabacterium inserts***

Blattabacterium genomes are chopped up and aligned to the Blaberidae cockroach genome.

*Scripts:*  
`1.1.chopping_genome.sh`  

***Step 1.1:*** Chop up the Blattabacterium genome in 150 nucleotide chunks to prepare for the alignment. The script is run specifying the input and output name, as well as the length of the 'chunks' you want chopped up:  
`bash 1.1.chopping_genome.sh Blattabacterium-genome.fasta Blattabacterium-genome_chopped.fasta 150`  
*threshold=150*  
*alternate threshold=100*  

After running the script on each genome, combine the various chopped up genomes with 'cat.'

***Step 1.2:*** Align the chopped up Blattabacterium to the reference host genome using bwa mem, implementing default parameters:  
`bwa index reference-genome.fasta`  
`bwa mem reference-genome.fasta Blattabacterium-genome_chopped.fasta > alignment.sam`  

If needed, you can extract the longest contigs before the alignment using the script 'extract-longest-contigs.sh'. Here's how you would extract the top 3 longest contigs.  
`bash extract-longest-contigs.sh assembly-input.fasta output.fasta 3`  


***2. Characterising HGT inserts***

Filtering and annotating the putative HGT inserts.

*Scripts:*  
`2.1.extracting-bed.sh`  
`2.2.identifying-contaminants.R`  
`2.3.identifying-duplicates.sh`  
`2.4.filtering-duplicates.sh`  
`2.5.annotating-bed.sh`  
`2.6.raw-read_assessment.sh`  

***Step 2.1:*** The alignment is converted into a BED file, representing the putative HGT regions. Overlapping Blattabacterium chunk alignments and near neighbouring alignments are merged into a single putative HGT region. Regions shorter than a specified length are filtered out. The pipeline is run with the following:  
`bash 2.1.extracting-bed.sh`  

The following key parameters need to be set within the bash script:  
- *merging_gap=150* --> this is the acceptable gap (in bp) between neighbouring aligned reads that will be merged into a single putative HGT insert (*alternate threshold = 50 bp*)
- *min_length=50* --> this is the minimum putative HGT insert length (in bp) to retain in the BED file (*alternate threshold = 30 bp*)

***Step 2.2:*** Some of the inserts might be contaminant genuine Blattabacterium DNA. These potential contaminants are identified by comparing the length of the insert to the length of the contig which it sits on. If the proportion of the insert length vs contig length exceeds a certain threshold it is possibly a Blattabacterium contig, and hence removed. This pipeline can be run using the following R code:  
`2.2.identifying-contaminants.R` 

Once the putative contaminated contigs have been identified based on the length threshold, the following shell script can be used to quickly remove them and produce a new filtered file:
`remove_contaminants.sh`

Files filtered in this step are given the suffix *filtered1.bed*

***Step 2.3:*** The most common assembly error is false duplication, hence some duplicate inserts may be artefacts. To identify duplicates, each insert is extracted with some flanking region. It is then BLASTed against all other inserts within the genome, and the top hit is extracted (excluding the hit to itself). This BLAST search can be run for each genomes using the following:  
`bash 2.3.identifying-duplicates.sh`  

The following key parameter needs to be set within the bash script:  
- *flank=300* --> flanking length on either end of putative insert

Very high hits are considered false duplicates, and should be removed from the inserts file so that the number of inserts in the genome is not overestimated. This can be done by running:  
`bash 2.4.filtering-duplicates.sh`  

The following key parameters needs to be set within the bash script:  
- *identity=90* --> removing hits above 90% identity
- *qcov=90* --> removing hits above 90% query coverage

This output of the above will create another bed file with the suffix '*_dup-filtered.bed*'. It will also state how many inserts were removed. This filtered bed file will be used in subsequent steps.  

***Important note:*** *There may be groups of false duplicates (i.e. >2 regions that are very close to one another). The pipeline above only considers pairs of false duplicates - if there is a group, it will not remove them all. Hence, this pipeline should be repeated, until 0 inserts are removed; i.e. the output of script '2.4.filtering-duplicates.sh' should be input for '2.3.identifying-duplicates.sh', and the pipeline can then be followed as above. It might take 2-3 iterations to remove all false duplications (depending on the assembly quality). It's important to properly label your bed file after this filtering (you may be left with numerous bed files with growing '_dup-filtered.bed' suffixes.*  

Files filtered in this step are given the suffix *filtered2.bed*

***Step 2.4:*** Some HGT inserts might be the result of a real duplication event, and some might have ‘jumped’ around the genome with a transposon. These are real inserts, but do not represent unique HGT events (i.e. one event occurred, then the insert was duplicated). These real duplications will have relatively high sequence similarity. Hence, to filter the genomes of duplicates, *Step 2.3* should be repeated, but changing the identify/coverage thresholds for script '2.3.identifying-duplicates.sh':  
- *identity=70* --> removing hits above 70% identity
- *qcov=70* --> removing hits above 70% query coverage

After running the pipeline with the updated identity and query coverage thresholds (and iterating through it a number of times where required) you will generate a bed file with no duplicates. Hence, while the output of *Step 2.3* will indicate the number of HGT inserts in the genome, and the output of *Step 2.4* will indicate the number of unique HGT insert events in the genome.  

Files filtered in this step are given the suffix *filtered3.bed*

***Step 2.5:*** Some of the regions identified as putative HGT inserts may actually be artefacts of BLAST alignment between independently arising, highly repetitive regions of the bacterial and cockroach genomes. To remove these, the sequences of the putative inserts are extracted from the cockroach genomes by running **script**, where the inserts are identified using the bed files produced in Step 2.4.

Low-entropy regions are then found (and masked) using the sdust algorithm in the minimap package. These are replaced with Ns using **script**. Any individual "HGT" contigs with a contiguous string of Ns >= 50% of their length are removed with **script**.

Files filtered in this step are given the suffix *filtered4.bed*

***Step 2.6:*** Annotating the filtered bed file using the genome assembly annotation; i.e. noting whether each putative HGT region sits within and gene, and if so, what part of the gene. This script will output multiple lines if it hits to multiple features (e.g. gene and exon) and if it overlaps features (e.g. it it spans an intergenic region and a gene this will be displayed on multiple lines with the relevant coordinates). This can be run with:  
`bash 2.5.annotating-bed.sh`  

***Step 2.7:*** When observing the raw sequence read alignments against the putative HGT inserts, some reads span the insert regions and elongate upstream/downstream for hundreds or thousands of nucleotides. While other reads are truncated and aligned to only the insert region, and typically have several nucleotide differences to the reads that elongate upstream/downstream. The former scenario are likely cockroach reads containing the insert region, while the latter scenario are likely Blattabacterium reads (some Blattabacterium are likely included in the sequenced DNA). This pipeline counts the reads for the two scenarios for each insert as additional evidence that there are long reads supporting the former scenario.  
***Zhuzhi is still working on this***


***Dating HGT inserts*** 

Inferring whether the filtered putative HGT inserts are ancestral, and inferring a minimum age of the HGT insertion event.  

*Scripts:*  
`3.1.extracting-inserts.sh`  
`3.2.BLAST-inserts_blatta-vs-host.sh`  
`3.3.parse-BLAST_blatta-vs-host.R`  
`3.4.annotating-divergences.sh`  

***Step 3.1:*** The filtered inserts from are extracted from the genomes (as a fasta file), and the species/genome name is added as a prefix to each insert sequence. This can be run using:  
`bash 3.1.extracting-inserts.sh`  

***Step 3.2:*** Each insert is BLASTed against the particular Blattabacterium strain belong to the species the insert derived (e.g. if the insert is from the Panesthia cribrata genome, the inserts should be BLASTed agains the specific Panesthia cribrata Blattabaactrium symbiont). Only the top hit is kept. Each insert is also BLASTed against all inserts in all other cockroach/termite taxa (excluding itself). Only the top hit is kept. This can be run using:  
`bash 3.2.BLAST-inserts_blatta-vs-host.sh`  

The following key parameter needs to be set within the bash script:  
- *inserts_dir=inserts* --> the name of the directory that contains extracted inserts (obtained from *Step 3.1*) from all cockroach/termite species (as fasta files)
- *target_inserts=P-crib_Blatta-chunk-alignment_aligned-segments.fasta* --> the name of the insert file (within the *insert_dir* folder) that is being BLASTed.
- *target_blattabacterium=CP142614.1.fasta* --> the Blattabacterium genome specific to the taxa being BLASTed.

This script will output to BLAST files - one for the Blattabacterium blast, and one for the inser database BLAST. 

***Step 3.3:*** The two BLAST output files from *Step 3.2* are compared to infer the age of the inserts. If the % identity is higher for the Blattabacterium BLAST compared to the cockroach/termite inser BLAST, then it is likely a recent insert. If the % identity is higher for the insert BLAST compared to the Blattabacterium BLAST, then the insert is likely ancestral. If the BLAST results are similar, we do not have confidence to infer the age of the insert. This pipeline can be run using the following R code:  
`3.3.parse-BLAST_blatta-vs-host.R`  

***Step 3.4:*** Of the inserts that were inferred to be ancestral in *Step 3.3*, the combination of species the insert is found in can be used to infer the minimum age of the insert. For example, if the insert is found in Panesthia cribrata, Geoscapheus dilatatus and Neogeoscapheus hanni, the insert is at least as old as the ancestral node for these three species. First, the ancestral sequences identified in the previous step can be extracted using **seqkt**:  
`seqtk subseq insert-sequences.fasta ancestral_insert-sequence-names.txt > ancestral_insertsequences.fasta`  

These putative ancestral inserts can then be BLASTed against the other inserts, and then data is parsed, using the following:  
`bash 3.4.inserts_min-age.sh`  
***This script requires testing***  

Similar to *Step 3.3*, the following key parameter needs to be set within the bash script:  
- *inserts_dir=inserts* --> the name of the directory that contains extracted ancestral inserts. These insert fasta files can be obtained by using using a bed file of ancestral inserts, as inferred in *Step 3.3*, and utilising the script in *Step 3.1*.  
- *target_inserts=P-crib_ancestral-inserts.fasta* --> the name of the insert file (within the *insert_dir* folder) that is being BLASTed. This should contain the putative ancestral inserts as inferred in *Step 3.3*.  

The output of this script is a a column of insert IDs for the query species, and a column with all of the species the insert hits to (BLAST hits have to be >70 identity and >70% query coverage). If there are no hits, the second column will contain an 'NA'.
