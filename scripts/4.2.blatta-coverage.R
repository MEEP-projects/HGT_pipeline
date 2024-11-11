# This script assumes bwa has already been run to
# align inserts to the reference genome. See script 4.1
# TODO: working in map-to-batta and need to move / edit workflow

# Load necessary libraries
library(GenomicAlignments)
library(GenomicRanges)
library(Rsamtools)
library(tidyverse)

# Get paths to all .sam files in 'map-to-blatta' directory
bam_files <- list.files(pattern = "\\.bam$", full.names = TRUE)

# Extract species names from file names
species_names <- gsub(
    basename(bam_files),
    pattern = "_.+[.]bam", replacement = ""
)
# Define list to store results. Later becomes data frame
coverage_list <- list()

# Loop through each .sam file and calculate coverage
for (i in seq_along(bam_files)) {
    # Read the SAM file
    param <- ScanBamParam(what = scanBamWhat())
    aln <- readGAlignments(bam_files[i], param = param)

    # Find position
    start <- start(aln)
    end <- end(aln)
    read_span <- data.frame(start, end)

    # Order and rank for stack value in plot
    read_span <- read_span[order(read_span$start, read_span$end), ]
    
    stack <- c(1)
    for (j in seq_along(read_span$start)[-1]) {
        if (read_span$start[j] > read_span$end[j - 1]) {
            stack <- c(stack, 1)
        } else {
            stack <- c(stack, stack[j - 1] + 1)
        }
    }

    read_span <- cbind(read_span, stack)
    
    # Convert coverage to a data frame for plotting
    coverage_list[[i]] <- read_span
}

names(coverage_list) <- species_names

coverage_list %>%
    bind_rows(.id = "id") %>%
    ggplot() +
    geom_segment(
        lwd = 2,
        aes(x = start, xend = end, y = stack, yend = stack)
    ) +
    facet_wrap(~id, scales = "free_y") +
    theme_bw()


# Save the plot
ggsave("blatta-coverage.pdf")
