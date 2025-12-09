

library(data.table)
library(ggplot2)

################################
## Marker length distribution ##
################################

# Read marker BED file
markers <- fread("7.1_all-inserts_tagged.bed", header = FALSE)
colnames(markers) <- c("chromosome", "start", "end")

# Add unique ID for each marker
markers[, marker_id := paste0(chromosome, ":", start, "-", end)]

# Calculate marker lengths
markers[, length := end - start]

# Minimum and maximum marker length
mean(markers$length)
median(markers$length)
min(markers$length)
max(markers$length)

# Plot length distribution
ggplot(markers, aes(x = length)) +
  geom_histogram(bins = 50, fill = "darkorange", color = "black") +
  theme_minimal() +
  labs(x = "Marker Length (bp)", y = "Number of Markers", title = "Marker Length Distribution")


###########################################
## Distance distribution between markers ##
###########################################

# Clean chromosome names to be safe
markers[, chromosome := trimws(chromosome)]

# Ensure they are treated as character strings
markers[, chromosome := as.character(chromosome)]

# Ensure data is sorted per chromosome and start position
setorder(markers, chromosome, start)

# Calculate inter-marker distances
markers[, prev_end := shift(end), by = chromosome]
markers[, inter_marker_distance := start - prev_end]

# Optional: Remove the first marker of each chromosome (which has NA distance)
inter_marker_gaps <- markers[!is.na(inter_marker_distance)]

# View results
head(inter_marker_gaps[, .(chromosome, prev_end, start, inter_marker_distance)])

ggplot(inter_marker_gaps, aes(x = inter_marker_distance)) +
  geom_histogram(bins = 50, fill = "purple", color = "black") +
  theme_minimal() +
  labs(x = "Distance Between Markers (bp)", y = "Count", title = "Inter-marker Distance Distribution")

inter_marker_gaps_filtered <- inter_marker_gaps[inter_marker_distance > 2500 & inter_marker_distance < 1500000]
ggplot(inter_marker_gaps_filtered, aes(x = inter_marker_distance)) +
  geom_histogram(bins = 50, fill = "purple", color = "black") +
  theme_minimal() +
  labs(x = "Distance Between Markers (bp)", y = "Count", title = "Inter-marker Distance Distribution")

