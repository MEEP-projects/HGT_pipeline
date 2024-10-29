Step 2.6 Pipeline
1.	Align (on HPC, edit input file name in the script): minimap2_alignment-steps.pbs
2.	Extract insertion:  
bash /path/to/extract_align.sh /path/to/output/of/bed /path/to/output/of/step1.bam flanking_lenth output_dir 
example:
bash extract_align.sh insertions.bed alignment.bam 0 output
3.	Summary the result, to get a list showing how many reads align to each insertion, and the number of reads that have the aligned length less than the insertion length + the allowance (set when input)
bash lenth.sh /path/to/output/of/step2/folder allowance
4.	Filter bad samples (threshold can be changed, it’s 50 now): awk -F',' '{ gsub(/ /, "", $4); if ($4 ~ /^[0-9]+\.[0-9]+%$/) { sub("%", "", $4); if ($4 + 0 >= 50) { print $0; getline; print } } }' /path/to/output/of/step3.txt > bad_insertions.txt

Don’t forget to ensure the input and output names are changed for each genome or save them in different folders. 

Results: 
Summary.txt: list total reads, short reads and proportion of short reads in total. The contig name is on the second line of numbers because of a coding problem. 
bad_insertions.txt: list insertions have too many short reads (more than threshold, set to 50% now)
