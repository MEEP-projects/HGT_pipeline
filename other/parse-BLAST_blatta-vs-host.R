#####################################################################
### PARSING THE BLATTABACTERIUM AND PUTATIVE INSERT BLAST RESULTS ###
#####################################################################

library(dplyr)

### Read in files
# Define the column headers
headers <- c("query_id", "subject_id", "%_identity", "alignment_length", "mismatches", "gap_opens", 
             "q_start", "q_end", "s_start", "s_end", "evalue", "bit_score", "query_coverage")


# Read in the Blattabacterium BLAST results
blatta_blast <- read.csv("BLAST-results/P-americana_BLAST_blatta-vs-hosts_blatta-hits.csv", header = FALSE)
colnames(blatta_blast) <- headers

# Read in the HGT inserts BLAST results
insert_blast <- read.csv("BLAST-results/P-americana_BLAST_blatta-vs-hosts_inserts-hits.csv", header = FALSE)
colnames(insert_blast) <- headers


### Filter out hits with low query length
# Count query coverage below threshold, exluding BLASTs with no hits (i.e. NA)
sum(na.omit(blatta_blast$query_coverage) < 70)
# Proportion of query coverage below threshold
mean(blatta_blast$query_coverage < 70, na.rm = TRUE)

# For any rows with a query coverage <0.7, set all columns to NA
blatta_blast <- blatta_blast %>%
  mutate(across(c("%_identity", "alignment_length", "mismatches", "gap_opens", "q_start", "q_end", 
                  "s_start", "s_end", "evalue", "bit_score", "query_coverage"), 
                ~ if_else(query_coverage < 70, NA_real_, .)))
colnames(blatta_blast) <- paste("Blatta-db-BLAST", colnames(blatta_blast), sep = "_")

# Doing for insert database BLAST results
insert_blast <- insert_blast %>%
  mutate(across(c("%_identity", "alignment_length", "mismatches", "gap_opens", "q_start", "q_end", 
                  "s_start", "s_end", "evalue", "bit_score", "query_coverage"), 
                ~ if_else(query_coverage < 70, NA_real_, .)))
colnames(insert_blast) <- paste("insert-db-BLAST", colnames(insert_blast), sep = "_")


### Combine the results
# Merge the dataframes based on query id
combined_res <- merge(blatta_blast, insert_blast, by.x = "Blatta-db-BLAST_query_id", by.y = "insert-db-BLAST_query_id", all = TRUE)
# Keep the relevant columns and look at differences between ids
# Note, if one of the values are NA, that NA will be treated as 0. If both are NA the difference will be NA
combined_res <- combined_res %>%
  rename(`query_id` = `Blatta-db-BLAST_query_id`) %>%
  select(`query_id`, `Blatta-db-BLAST_subject_id`, `insert-db-BLAST_subject_id`, 
         `Blatta-db-BLAST_%_identity`, `insert-db-BLAST_%_identity`) %>%
  mutate(`identity_diff` = ifelse(is.na(`Blatta-db-BLAST_%_identity`) & is.na(`insert-db-BLAST_%_identity`), NA, 
                                  coalesce(`Blatta-db-BLAST_%_identity`, 0) - coalesce(`insert-db-BLAST_%_identity`, 0)))

### Plot
diff <- sort(na.omit(combined_res$identity_diff))

# Plot the ordered data
plot(diff, 
     main = "Ordered plot of identity differences (top Blattabacterium hit - insert hit from other genome)", 
     xlab = "Putative inserts",
     ylab = "%ID to Blattabacterium - %ID to other host inserts",
        col = "blue")

## Change thresholds below depending on the graph
# Number of ancestral inserts
sum(diff < -50)
# Number of recent inserts
sum(diff > 50)
# number of inserts we can't age
sum(diff < 50 & diff > -50)
# Extracting putatively ancestral inserts
ancestral <- combined_res %>%
  filter(identity_diff < -50) %>%
  pull(query_id)
write.table(ancestral, "ancestral_insert-seq-names.txt", quote = F, row.names = F, col.names = F)
write.csv(combined_res, "combined-BLAST-results.csv", quote = F)

# Use this file to extract the ancestral inserts from the oriignal insert fasta file:
#seqtk subseq insert-sequences.fasta ancestral_insert-sequence-names.txt > ancestral_insertsequences.fasta

