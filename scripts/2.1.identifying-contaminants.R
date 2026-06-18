library(dplyr)

# Read bed file (insert)
insert <- read.table("M-lithgowae_Z004_aligned-segments.bed", header = F, sep = "\t")
# Convert bed file to data frame
insert <- as.data.frame(insert)
# Add header
colnames(insert) <- c("contigname", "start", "end", "chunk_names")
# Remove column of chunk names
insert <- subset(insert, select = -c(chunk_names))
# Calculate insert length
insert$insertlength <- insert$end - insert$start

# Read in contig lengths file
contig <- read.table("M-lithgowae_Z004_contig-lengths.txt", header = F, sep = "\t")
# Add headers
colnames(contig) <- c("contigname", "contig_length")


# Merge the dataframes by 'contigname', keeping only rows where there is a match
fin <- insert %>%
  left_join(contig, by = "contigname")

# Calculate insert length / contig length
fin$proportion <- fin$insertlength / fin$contig_length

# Plot
prop <- (sort(fin$proportion))*100
plot(prop)

# Keep only rows where the proportion is less than or equal to 20%
filtered_inserts <- subset(fin, proportion <= 0.20)

write.table(filtered_inserts,
            file = "filtered_inserts.txt",
            sep = "\t",
            quote = FALSE,
            row.names = FALSE)
