#####################
### Load packages ###
#####################

library(dplyr)
library(data.table)
library(ggplot2)
library(stringr)

################################
## Marker length distribution ##
################################

# Read the annotated marker file (skip comment line if present)
markers <- fread("7.1.audited_annotated_combined.tsv", sep = "\t", header = TRUE)

# Ensure expected columns are present
colnames(markers) <- c("index", "chromosome", "start", "end", "feature_type", 
                       "details", "reads", "genome")

# Calculate marker length
markers[, length := end - start]

# Add a classification column
markers[, region_type := ifelse(feature_type == "intergenic", "intergenic", "genic")]

##########################
### Density comparison ###
##########################

# Create separate datasets
markers_all <- markers %>% mutate(region_type = "all")
markers_combined <- rbind(markers_all, markers)


### VERSION 1 PLOT ###

# Plot combined density lines
ggplot(markers_combined, aes(x = length, color = region_type)) +
  geom_density(size = 1.2, adjust = 1.2, alpha = 1.5) +
  scale_color_manual(
    values = c("all" = "grey40", "intergenic" = "steelblue", "genic" = "darkorange"),
    name = "Region Type"
  ) +
  scale_x_continuous(
    limits = c(50, 1000),
    breaks = seq(50, 1000, by = 100),
    expand = c(0, 0)
  ) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
  geom_hline(yintercept = 0, color = "black") +
  geom_vline(xintercept = 0, color = "black") +
  labs(
    x = "Marker Length (bp)",
    y = "Density",
    title = "Marker Length Distribution (All, Intergenic, and Genic)"
  ) +
  theme_classic(base_size = 18) +
  theme(
    panel.grid = element_blank(),
    plot.title = element_text(size = 22, hjust = 0.5, face = "bold"),
    axis.title.x = element_text(size = 20, vjust = -0.2),
    axis.title.y = element_text(size = 20, vjust = 1.5),
    axis.text = element_text(size = 16),
    axis.line = element_line(colour = "black", linewidth = 1),
    legend.position = "top",
    legend.title = element_text(size = 18),
    legend.text = element_text(size = 16)
  )

### VERSION 2 PLOT ###
cols <- c(
  all = alpha("grey40", 0.6),
  intergenic = alpha("steelblue", 0.6),
  genic = alpha("darkorange", 0.6)
)

# sizes so "all" is slightly thicker
sizes <- c(all = 1.9, intergenic = 1.2, genic = 1.2)

ggplot(markers_combined, aes(x = length, color = region_type, size = region_type)) +
  geom_density(adjust = 1.2, show.legend = TRUE) +
  scale_color_manual(values = cols, name = "Region Type") +
  scale_size_manual(values = sizes, guide = "none") + # hide size legend if you want
  scale_x_continuous(limits = c(50, 1000), breaks = seq(50, 1000, 100), expand = c(0,0)) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
  geom_hline(yintercept = 0, color = "black") +
  labs(x = "Marker Length (bp)",
       y = "Density",
       title = "Marker Length Distribution (All, Intergenic, Genic)") +
  theme_classic(base_size = 18) +
  theme(legend.position = "top",
        plot.title = element_text(hjust = 0.5, face = "bold"))


##########################
### Summary statistics ###
##########################

# Count of markers over 1000 bp
markers[length > 1000, .N]

# Total marker length
markers[, sum(length)]

# Total marker length per genome
markers[, .(total_length = sum(length)), by = genome]


# If needed, subset specific genomes
subset_genomes <- c("Blattella-germanica-v1_annotated.tsv")
markers_subset <- markers[genome %in% subset_genomes]
