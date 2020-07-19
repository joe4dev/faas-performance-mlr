library(dplyr)

# Load raw data as "mlr" ---------------------------
source("download_faas_mlr.R")

# Prepare data ---------------------------
df <- mlr %>%
  filter(selection == "relevant") %>%
  filter(literature_type == "academic")

df_freq <- df %>%
  group_by(venue) %>%
  summarise(freq = n(), .groups = 'drop') %>%
  mutate(rel_freq = freq / sum(freq) * 100) %>%
  arrange(desc(freq))

# Save to csv ---------------------------
write.csv(df_freq, "venues.csv", row.names = FALSE)
