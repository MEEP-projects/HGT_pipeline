# Plot accumulation of insert start positions along Blattabacterium genomes
# Input format: contig | position | count | read_names

library(tidyverse)

# -----------------------------
# 1. Load input files
# -----------------------------
files <- list.files(
  path = "/Users/kyleewart/Downloads/HGT_working/version2/out2",  # adjust as needed
  pattern = "_start_counts\\.bed$",
  full.names = TRUE
)

# Read and label files
df_list <- lapply(files, read_tsv, col_names = FALSE)
names(df_list) <- gsub(".*/|_start_counts\\.bed$", "", files)

# -----------------------------
# 2. Standardize column names
# -----------------------------
df <- lapply(df_list, function(l) {
  colnames(l) <- c("contig", "position", "count", "reads")
  l
}) %>%
  bind_rows(.id = "species")

# -----------------------------
# 3. Compute cumulative counts
# -----------------------------
df_mod <- df %>%
  group_by(species, contig) %>%
  arrange(position) %>%
  mutate(cumcount = cumsum(count)) %>%
  ungroup()

# -----------------------------
# 4. Cumulative genome inserts v1 (plot per genome)
# -----------------------------

## First, remove genomes that already have representation (use the genome per species with the highest number of inserts)
# Removing: Blattella-germanica-v2, Periplaneta-americana-v2, Periplaneta-americana-v3, Periplaneta-americana-v4
df_mod2 <- df_mod %>%
  filter(!species %in% c(
    "B-germanica-v2",
    "P-americana-v2",
    "P-americana-v3",
    "P-americana-v4"
  ))

ggplot(df_mod2) +
  geom_ribbon(
    aes(x = position, ymin = 0, ymax = cumcount),
    alpha = 0.3, fill = "dodgerblue", color = "black"
  ) +
  labs(
    x = "Genome position (bp)",
    y = "Cumulative inserts",
    title = "Cumulative insert start positions"
  ) +
  facet_wrap(~species, scales = "free_x") +
  theme_minimal(base_size = 14)

ggsave(
  filename = "/Users/kyleewart/Downloads/HGT_working/version2/insert_cumulative_plot_v1.png",
  width = 10, height = 8, bg = "white"
)

# -----------------------------
# 5. Combined cumulative plot v2 (1 plot for all genomes)
# -----------------------------
ggplot(df_mod2, aes(x = position, y = cumcount, color = species)) +
  geom_line(size = 1) +
  labs(
    x = "Genome position (bp)",
    y = "Cumulative inserts",
    color = "Species",
    title = "Cumulative inserts across Blattabacterium genomes"
  ) +
  theme_minimal(base_size = 14) +
  theme(panel.grid.minor = element_blank())

ggsave(
  filename = "/Users/kyleewart/Downloads/HGT_working/version2/insert_cumulative_plot_v2.png",
  width = 10, height = 8, bg = "white"
)

# -----------------------------
# 6. Non-cumulative plot
# -----------------------------
ggplot(df_mod2) +
  geom_ribbon(
    aes(x = position, ymin = 0, ymax = count),
    alpha = 0.3, fill = "dodgerblue", color = alpha("dodgerblue", 0.3)
  ) +
  labs(
    x = "Genome position (bp)",
    y = "Number of reads starting at position",
    title = "Insert start density along genome"
  ) +
  facet_wrap(~species, scales = "free_x") +
  theme_minimal(base_size = 14)

ggsave(
  filename = "/Users/kyleewart/Downloads/HGT_working/version2/insert_plot_v1.png",
  width = 10, height = 8, bg = "white"
)
