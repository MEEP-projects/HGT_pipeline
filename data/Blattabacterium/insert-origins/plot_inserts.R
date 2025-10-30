# Plots of insertions in Blattabacterium genomes

library(tidyverse)

files <- list.files(
  path = "data/Blattabacterium/insert-origins/out_7.2-inserts",
  pattern = "*.txt",
  full.names = TRUE
)

df_list <- lapply(files, read_tsv)
names(df_list) <- gsub("data/Blattabacterium/insert-origins/out_7.2-inserts/", "", files)
names(df_list) <- gsub("_cov.txt", "", names(df_list))

df_list <- df_list[sapply(df_list, nrow) > 0]

df <- lapply(df_list, function(l) {
  colnames(l) <- c("genbank", "start", "end", "cov")
  return(l)
}) %>%
  bind_rows(.id = "species")

# Assume genome length is 2GB (add exact bounds later)
df_mod <- df %>%
  pivot_longer(
    cols = c(start, end),
    names_to = "pos_type",
    values_to = "position"
  ) %>%
  # Extend positions to genome bounds
  group_by(species) %>%
  group_modify(~ {
    bind_rows(
      tibble(position = c(0, 2e9), cov = c(0, 0)),
      .x
    )
  }) %>%
  arrange(species, position) %>%
  mutate(cumcov = cumsum(cov)) %>%
  ungroup() %>%
  select(species, position, cumcov)



  ggplot(df_mod) +
  geom_ribbon(
    aes(x = position, ymin = 0, ymax = cumcov),
    alpha = 0.3, fill = "dodgerblue", col = "black"
  ) +
  labs(x = "Genome Position (bp)", y = "Cumulative inserts") +
  scale_x_log10(
    breaks = 10^(0:9),
    labels = scales::trans_format("log10", scales::math_format(10^.x))
  ) +
  facet_wrap(~species) +
  theme_minimal() +
  theme(
    panel.grid.minor = element_blank(),
    axis.text = element_text(size = 12),
    strip.text = element_text(size = 14),
    axis.title = element_text(size = 14)
  )
ggsave(
  filename = "data/Blattabacterium/insert-origins/insert_cumulative_plot.png",
  width = 10, height = 8, bg = "white"
)
