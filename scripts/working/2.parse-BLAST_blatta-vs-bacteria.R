###################################################################
### PARSING THE BLATTABACTERIUM VS OTHER BACTERIA BLAST RESULTS ###
###################################################################

# Load libraries
library(dplyr)

## Input files
# Blattabacterium blast hits
blatta <- "P-tryoni-tryoni_Z005_filtered2_no-repeats_inserts_BLASTing-Blatta.csv"
# Other bacteria blast hits
bacteria <- "P-tryoni-tryoni_Z005_filtered2_no-repeats_inserts_BLASTing-bacteria.csv"

## Thresholds
# The Blattabacterium hit has to be 'thr' higher than the bacteria hit
thr <- 3

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
  mutate(`identity_diff` = ifelse(is.na(`Blatta-BLAST_%_identity`) & is.na(`bac-BLAST_%_identity`), NA, 
                                  coalesce(`Blatta-BLAST_%_identity`, 0) - coalesce(`bac-BLAST_%_identity`, 0)))

# Filtering to:
# 1. Remove rows where 'Blatta-BLAST_%_identity' is 'NA' or '0'
# 2. Remove rows where 'identity_diff' is <'thr'
combined_res3 <- combined_res2 %>%
  filter(!is.na(`Blatta-BLAST_%_identity`) & `Blatta-BLAST_%_identity` != 0) %>%
  filter(identity_diff >= thr)

# Filtered inserts
filtered <- combined_res3$query_id
# Replace the last ':' and '-' with a tab
filtered2 <- sub(":(?=[^:]*$)", "\t", filtered, perl = TRUE) # Replace last colon with tab
filtered2 <- sub(":(?=[^-]*$)", "\t", filtered2, perl = TRUE)  # Replace last dash with tab

write.table(combined_res3$query_id, "inserts-names_to-keep.txt", quote = F, row.names = F, col.names = F)

# In bash, convert these IDs to bed format using the following:
#sed 's/\(.*\):/\1####/' inserts-names_to-keep.txt > temp1.txt
#sed 's/\(.*\)-/\1####/' temp1.txt > temp2.txt
#awk -F '####' '{print $1 "\t" $2 "\t" $3}' temp2.txt > filtered_inserts.bed
#rm temp1.txt temp2.txt
