#########################
### Combine bed files ###
#########################

### First, run the following bash script
## run inside the directory with your .bed files
#> combined.txt
#for f in *.bed; do
#   name="$(basename "$f" .bed)"
#   awk -v n="$name" 'BEGIN{OFS="\t"} $0 ~ /^#/ || $0 ~ /^track/ {next} {print $0, n}' "$f" >> combined.txt
#done
#mv combined.txt 7.1.audited_combined.bed


#####################
### Read packages ###
#####################

library(dplyr)
library(readr)
library(stringr)
library(data.table)
library(ggplot2)

################################
## Marker length distribution ##
################################

# Read marker BED file
markers <- fread("7.1.audited_combined.bed", header = FALSE)
colnames(markers) <- c("chromosome", "start", "end", "genome")

# Add unique ID for each marker
markers[, marker_id := paste0(genome, ":", chromosome, ":", start, "-", end)]

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

# Density graph
# Change 'adjust' to modify the resolution
ggplot(markers, aes(x = length)) +
  geom_density(fill = "darkorange", alpha = 0.6, adjust = 1.2) +
  # axis scaling
  scale_x_continuous(
    limits = c(50, 1000),
    breaks = seq(50, 1000, by = 100),
    expand = c(0, 0)
  ) +
  scale_y_continuous(
    expand = expansion(mult = c(0, 0.05))
  ) +
  # axes lines
  geom_hline(yintercept = 0, color = "black") +
  geom_vline(xintercept = 0, color = "black") +
  # labels
  labs(
    x = "Marker Length (bp)",
    y = "Density",
    title = "Marker Length Distribution"
  ) +
  # clean theme + bigger text
  theme_classic(base_size = 18) +  # base size bumps everything up a bit
  theme(
    panel.grid = element_blank(),
    panel.background = element_blank(),
    plot.title = element_text(size = 22, hjust = 0.5, face = "bold"),
    axis.title.x = element_text(size = 20, vjust = -0.2),
    axis.title.y = element_text(size = 20, vjust = 1.5),
    axis.text = element_text(size = 16),
    axis.line = element_line(colour = "black", linewidth = 1)
  )


# Number of inserts above the cutoff:
markers[length > 1000, .N]


# Total insert length
markers[, sum(length)]

# Insert length per genome
markers[, .(total_length = sum(length)), by = genome]

# If needed, subsetting the genome"
subset_genomes <- c("Blattella-germanica-v1_filtered_7.v1", 
                    "Periplaneta-americana-v4_filtered_7.v1")

markers_subset <- markers[genome %in% subset_genomes]
