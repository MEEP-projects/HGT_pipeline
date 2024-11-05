# This script assumes bwa has already been run to
# align inserts to the reference genome

# Load necessary libraries
library(GenomicAlignments)
library(GenomicRanges)
library(Rsamtools)
library(ggplot2)

# Define input and output files
sam_file <- "/path/to/your/input.sam"
output_file <- "/path/to/your/output_coverage.png"

# Read the SAM file
param <- ScanBamParam(what = scanBamWhat())
alignments <- readGAlignments(sam_file, param = param)

# Calculate coverage
coverage <- coverage(alignments)

# Convert coverage to a data frame for plotting
coverage_df <- as.data.frame(coverage)

# Plot coverage
ggplot(coverage_df, aes(x = seqnames, y = score)) +
    geom_line() +
    labs(title = "Coverage of Inserts Over Reference Genome",
             x = "Position",
             y = "Coverage") +
    theme_minimal()

# Save the plot
ggsave(output_file)