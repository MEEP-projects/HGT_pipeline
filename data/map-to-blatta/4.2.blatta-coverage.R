# This script assumes bwa has already been run to
# align inserts to the reference genome. See script 4.1
# TODO: working in map-to-batta and need to move / edit workflow

# Load necessary libraries
library(GenomicAlignments)
library(GenomicRanges)
library(Rsamtools)
library(tidyverse)
library(ape)

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


### Insert length
# Get paths to all .sam files in 'map-to-blatta' directory
fasta_files <- list.files(
    pattern = "[.]fasta$",
    full.names = TRUE,
    path = "data/fasta_files"
)

aln <- lapply(fasta_files, function(x) ape::read.dna(x, format = "fasta", as.character = TRUE))

species_names <- gsub(
    basename(fasta_files),
    pattern = "_.+[.]fasta", replacement = ""
)

# Get sequence length and gc content
names(aln) <- species_names

# Function takes aln list above and returns data frame
# of sequence length and gc content for each sequence
get_seq_info <- function(aln_list) {
    seq_info_list <- lapply(aln_list, function(aln) {
        seq_lengths <- sapply(aln, length)
        gc_content <- sapply(aln, function(seq) {
            sum(seq == "g" | seq == "c") / length(seq)
        })
        data.frame(length = seq_lengths, gc_content = gc_content)
    })
    return(seq_info_list)
}

seq_info_list <- get_seq_info(aln)
names(seq_info_list) <- species_names

# Plot length
seq_info_list %>%
    bind_rows(.id = "id") %>%
    ggplot() +
    geom_histogram(aes(x = length)) +
    facet_wrap(~id, scales = "free")
ggsave("blatta-insert-length.pdf")

## Plot GC%

# Add GC value of blatta whole genome
blatta_gc <- ape::GC.content(
    read.dna(
        "data/map-to-blatta/GCF_038284835.1_ASM3828483v1_genomic.fna",
        format = "fasta"
    )
)
seq_info_list %>%
    bind_rows(.id = "id") %>%
    ggplot() +
    geom_histogram(aes(x = gc_content)) +
    geom_vline(xintercept = blatta_gc) +
    facet_wrap(~id, scales = "free")
ggsave("blatta-gc-content.pdf")
