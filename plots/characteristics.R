# Data preparation
library(tidyr)
library(dplyr)
library(forcats)

# Plotting
library(ggplot2)
library(ggthemes)
# library(viridis)
# library(hrbrthemes)
# extrafont::loadfonts()
# If you get an error like "font family 'Arial Narrow' not found in PostScript font database",
# you might need to re-import your fonts and restart R
# extrafont::font_import()

# Load raw data as "mlr" ---------------------------
source("download_faas_mlr.R")

# Filter and clean data ---------------------------
df_cleaned <- mlr %>%
  filter(selection == "relevant") %>%
  # introduce characteristics total column (c_total)
  mutate(c_total = "yes") %>%
  # introduce platforms total column (p_total)
  mutate(p_total = "yes") %>%
  # Generates warning "attributes are not identical across measure variables; they will be dropped" => ignore loosing levels, etc
  gather("characteristic", "c_value", app_bench:infra, c_total) %>%
  mutate(c_value_clean = case_when(
    grepl("yes.*", c_value) ~ 1,
    grepl("no.*", c_value) ~ 0
  )) %>%
  # Generates warning "attributes are not identical across measure variables; they will be dropped" => ignore loosing levels, etc
  gather("platform", "p_value", aws:self_hosted_openwhisk, p_total) %>%
  mutate(p_value_clean = case_when(
    grepl("yes.*", p_value) ~ 1,
    grepl("no.*", p_value) ~ 0
  )) %>%
  select(id, citekey, characteristic, c_value_clean, platform, p_value_clean, literature_type)

# Adjust selectively ---------------------------
# Adjust for studies that perform certain experiments for a subset of platforms
df_adjusted <- df_cleaned %>%
  # akkus:18 ibm was only used for app_bench (including concurrency scenario)
  mutate(p_value_clean = replace(p_value_clean, (citekey == "akkus:18" & platform == "ibm") & !(characteristic %in% c("app_bench", "overhead", "c_total")), 0)) %>%
  # lopez:18 does not test concurrency for ibm
  mutate(p_value_clean = replace(p_value_clean, (citekey == "lopez:18" & platform == "ibm") & (characteristic == "overhead"), 0))

# Calculate frequency table ---------------------------
# Calculates the frequency of all combinations for characteristic vs platform including totals for both
df_frequency <- df_adjusted %>%
  filter((c_value_clean == 1 & p_value_clean == 1)) %>%
  group_by(characteristic, platform, literature_type) %>%
  summarise(freq = n()) %>%
  ungroup %>%
  # fix missing entries in plot because no grey literature studies does infra
  add_row(characteristic = "infra", literature_type = "grey", platform = "aws", freq = 0) %>%
  spread(platform, freq, fill = 0)

# Reorder and sort ---------------------------
df <- df_frequency %>%
  ungroup(characteristic) %>%
  mutate(characteristic = factor(characteristic, levels = c("c_total", "micro_bench", "app_bench", "cpu", "fileio", "network", "other_micro", "overhead", "concurrency", "lifetime", "infra"))) %>%
  arrange(literature_type, characteristic) %>%
  select(literature_type, characteristic, p_total, everything())

# Save to csv ---------------------------
write.csv(df, "characteristics.csv", row.names = FALSE)

# Prepare plotting ---------------------------
# Calculate relative percentages per overall total for academic and grey
academic_count <- df %>% filter(characteristic == "c_total" & literature_type == "academic") %>% pull(p_total)
grey_count <- df %>% filter(characteristic == "c_total" & literature_type == "grey") %>% pull(p_total)
# Add relative percentages and pivot_wide (i.e., gather) platform columns
df2 <- df %>%
  mutate(literature_type_count = case_when(
    literature_type == "academic" ~ academic_count,
    literature_type == "grey" ~ grey_count
  )) %>%
  gather("platform", "count", p_total:self_hosted_openwhisk) %>%
  filter(platform != "self_hosted_openwhisk")

# Prepare facets ---------------------------
df3 <- df2 %>%
  filter(characteristic %in% c("c_total", "micro_bench", "app_bench")) %>%
  mutate(facet = "(a) Benchmark Types")
df4 <- df2 %>%
  filter(characteristic %in% c("cpu", "network", "fileio", "other_micro")) %>%
  mutate(facet = "(b) Micro-Benchmarks")
df5 <- df2 %>%
  filter(characteristic %in% c("overhead", "lifetime", "concurrency", "infra")) %>%
  mutate(facet = "(c) General Characteristics")
df6 <- df2 %>%
  filter(characteristic %in% c("c_total")) %>%
  mutate(facet = "Total")

grid <- rbind(df3, df4, df5)

# Add totals columns combining academic and grey
c_totals <- grid %>%
  filter(platform == "p_total") %>%
  group_by(characteristic) %>%
  summarize(c_total = sum(count))
p_totals <- grid %>%
  filter(characteristic == "c_total") %>%
  group_by(platform) %>%
  summarize(p_total = sum(count))
grid2 <- grid %>%
  merge(c_totals) %>%
  merge(p_totals)

grid3 <- grid2 %>%
  mutate(characteristic = fct_recode(characteristic,
                                     "Total per Platform"    = "c_total",
                                     "Microbenchmark"      = "micro_bench",
                                     "Applicationbenchmark" = "app_bench",
                                     "CPU" = "cpu",
                                     "Network" = "network",
                                     "File I/O" = "fileio",
                                     "Others" = "other_micro",
                                     "Platform Overhead" = "overhead",
                                     "Workload Concurrency" = "concurrency",
                                     "Infrastructure Inspection" = "infra",
                                     # figiela:18 instance lifetime
                                     # lloyd:18 instance retention
                                     "Instance Lifetime" = "lifetime"
  )) %>%
  mutate(platform = fct_recode(platform,
                               "Total per Characteristic"    = "p_total",
                               "AWS"      = "aws",
                               "Azure" = "azure",
                               "Google" = "google",
                               "IBM" = "ibm",
                               "CloudFlare" = "cloudflare",
                               "Self-Hosted" = "self_hosted"
                               # "Self-Hosted OpenWhisk" = "self_hosted_openwhisk"
  )) %>%
  mutate(platform = fct_reorder(platform, p_total)) %>%
  mutate(characteristic = fct_reorder(characteristic, c_total)) %>%
  mutate(facet = factor(facet, levels = c("Total", "(a) Benchmark Types", "(b) Micro-Benchmarks", "(c) General Characteristics"))) %>%
  mutate(literature_type = fct_recode(literature_type,
                                      "Academic" = "academic",
                                      "Grey" = "grey"
                                      ))
  # Omit 0 values but leads to positioning issues with dodge
  # filter(count != 0)

# Plot combo characteristics ---------------------------
combo <- ggplot(grid3, aes(x = platform, y = characteristic, group = literature_type)) +
  # ggtitle('Benchmark Types per Platform') +
  labs(x = 'FaaS Platforms', y = 'Performance Characteristics', fill = "Literature Type") +
  geom_point(aes(size = count, fill = literature_type), alpha=1, shape=21, color="black", show.legend = TRUE, position = position_dodge(width = 1)) +
  guides(size=FALSE, fill = guide_legend(override.aes = list(size=10))) +
  scale_size_area(max_size = 22) +
  geom_text(aes(label=count), position = position_dodge(width = 1), show.legend = FALSE, colour="white") + # fontface="bold"
  geom_text(aes(label=paste(round((count / literature_type_count * 100), digits = 0), "%", sep = "")), position = position_dodge(width = 1), vjust = 4.3, show.legend = FALSE) +
  geom_vline(xintercept=seq(1.5, length(unique(df3$platform))-0.5, 1), lwd=1, colour="grey", alpha = 0.7) +
  theme_economist() +
  scale_fill_economist() +
  facet_grid(rows = vars(facet), scales = "free_y") +
  theme(
    # Fix overlap of x axis title
    axis.title.x = element_text(size = 13, margin = margin(t = 8)),
    axis.title.y = element_text(size = 13, margin = margin()),
    # Add space between facet title and graph
    strip.text.y = element_text(margin = margin(l = 4))
  )
ggsave('characteristics.pdf', width = 13, height = 15, device = cairo_pdf(), plot = combo)
dev.off()
