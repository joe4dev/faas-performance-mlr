library(dplyr)
library(tidyr)

# Load raw data as "mlr" ---------------------------
source("download_faas_mlr.R")

col <- "p3_runtimes"

# Prepare data ---------------------------
df <- mlr %>%
  filter(selection == "relevant") %>%
  select(id, literature_type, col) %>%
  separate_rows(col, sep = ", ")
df_type <- mlr %>%
  filter(selection == "relevant") %>%
  group_by(literature_type) %>%
  summarise(freq = n(), .groups = 'drop')
academic_count <- df_type %>% filter(literature_type == "academic") %>% pull(freq)
grey_count <- df_type %>% filter(literature_type == "grey") %>% pull(freq)

# Calculate statistics on runtime count ---------------------------

# Determine how many language runtimes studies typically target
df_freq <- df %>%
  group_by(literature_type, id) %>%
  summarise(runtimes_count = n(), .groups = 'drop') %>%
  ungroup() %>%
  group_by(literature_type, runtimes_count) %>%
  summarise(runtime_freq = n(), .groups = 'drop') %>%
  mutate(runtime_rel_freq = case_when(
    literature_type == "academic" ~ runtime_freq / academic_count * 100,
    literature_type == "grey" ~ runtime_freq / grey_count * 100
  ))

# Save to csv ---------------------------
write.csv(df_freq, "runtime_stats.csv", row.names = FALSE)
