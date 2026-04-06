###################################################################
### PARSING THE BLATTABACTERIUM VS OTHER BACTERIA BLAST RESULTS ###
###################################################################

## What is being filtered:
# Inserts that don't BLAST back to the Blattabacterium database hits.
# Inserts that are much more similar to other bacterial species than to Blattabacterium (difference is set by a threshold)

# Load libraries
library(dplyr)

## Input files
# Blattabacterium blast hits
blatta <- "Cr_punctulatus_filtered_v3_BLASTing-Blatta.csv"
# Other bacteria blast hits
bacteria <- "Cr_punctulatus_filtered_v3_BLASTing-bacteria.csv"


## Thresholds
# The Blattabacterium hit has to be 'thr'% higher than the bacteria hit
# Discard insert if bacteria hit is >'thr'% higher than the Blattabacterum hit
thr <- 2

### Read in files
# Define the column headers
headers <- c("query_id", "subject_id", "%_identity", "alignment_length", "mismatches", "gap_opens", 
             "q_start", "q_end", "s_start", "s_end", "evalue", "bit_score", "query_coverage")

# Read in the Blattabacterium BLAST results
blatta_blast <- read.csv(blatta, header = FALSE)
colnames(blatta_blast) <- headers
colnames(blatta_blast) <- paste("Blatta-BLAST", colnames(blatta_blast), sep = "_")

# Read in the other bacterial BLAST results
bac_blast <- read.csv(bacteria, header = FALSE)
colnames(bac_blast) <- headers
colnames(bac_blast) <- paste("bac-BLAST", colnames(bac_blast), sep = "_")


### Combine the results
# Merge the dataframes based on query id
combined_res <- merge(blatta_blast, bac_blast, by.x = "Blatta-BLAST_query_id", by.y = "bac-BLAST_query_id", all = TRUE)
# Keep the relevant columns and look at differences between ids
# Note, if one of the values are NA, that NA will be treated as 0. If both are NA the difference will be NA
combined_res2 <- combined_res %>%
  rename(`query_id` = `Blatta-BLAST_query_id`) %>%
  select(`query_id`, `Blatta-BLAST_subject_id`, `bac-BLAST_subject_id`, 
         `Blatta-BLAST_%_identity`, `bac-BLAST_%_identity`) %>%
  mutate(bacID_minus_BlattaID = `bac-BLAST_%_identity` - `Blatta-BLAST_%_identity`)


# Filtering to:
# 1. Remove rows where 'Blatta-BLAST_%_identity' is 'NA' and bac-BLAST_%_identity is not an NA.
# 2. Remove rows where 'bacID_minus_BlattaID' is > 'thr'
# Note, keeping isntances where both are NA, or when 'bac-BLAST_%_identity' is 'NA' and 'Blatta-BLAST_%_identity' is not an NA.
combined_res3 <- combined_res2 %>%
  filter(
    is.na(bacID_minus_BlattaID) | bacID_minus_BlattaID <= thr,
    !(is.na(`Blatta-BLAST_%_identity`) & !is.na(`bac-BLAST_%_identity`))
  )

write.table(combined_res3$query_id, "inserts-names_to-keep.txt", quote = F, row.names = F, col.names = F)

# In bash, convert these IDs to bed format using the following:
#sed 's/\(.*\):/\1####/' inserts-names_to-keep.txt > temp1.txt
#sed 's/\(.*\)-/\1####/' temp1.txt > temp2.txt
#awk -F '####' '{print $1 "\t" $2 "\t" $3}' temp2.txt > filtered_inserts.bed
#rm temp1.txt temp2.txt inserts-names_to-keep.txt
