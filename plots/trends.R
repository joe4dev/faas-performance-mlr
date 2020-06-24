library(tidyr)
library(dplyr)
library(forcats)
library(parsedate)
library(lubridate)

library(ggplot2)
library(ggthemes)

# Load raw data as "mlr" ---------------------------
source("download_faas_mlr.R")

# Prepare data ---------------------------
df <- mlr %>%
  filter(selection == "relevant") %>%
  mutate(date_published_parsed = parse_date(date_published)) %>%
  arrange(date_published_parsed) %>%
  mutate(num_pubs = 1) %>%
  mutate(cum_pubs = cumsum(num_pubs)) %>%
  mutate(year_published = year(date_published_parsed)) %>%
  mutate(venue_type = factor(venue_type, levels = c("Journal", "Conference", "Workshop", "DocSym", "Preprint", "Thesis", "Blog")))

df_freq <- df %>%
  group_by(year_published, literature_type, venue_type) %>%
  summarise(freq = n()) %>%
  # Remove 3 Blogs without publication date/year
  filter(!is.na(year_published)) %>%
  # Remove 2020 (misleading as partial year)
  filter(year_published != 2020) %>%
  ungroup %>%
  mutate(literature_type = fct_recode(literature_type,
    "Academic" = "academic",
    "Grey" = "grey"
  ))

totals <- df_freq %>%
  group_by(year_published, literature_type) %>%
  summarize(total = sum(freq))
grid <- merge(df_freq, totals)

# Save to csv ---------------------------
write.csv(totals, "trends.csv", row.names = FALSE)

# Plot graph ---------------------------

# Barplot
ggplot(grid, aes(x=literature_type, y=freq, fill = venue_type, label=freq)) + 
  geom_bar(position="stack", stat="identity", width = 0.9) +
  geom_text(aes(label=freq), position=position_stack(vjust = 0.5), size=3, colour="white") +
  geom_text(aes(literature_type, total, label = total, fill = NULL), vjust=-0.4) +
  facet_grid(~ year_published) +
  labs(x = 'Literature Type', y = 'Published Studies', fill = "Venue Type") +
  theme_economist() +
  scale_fill_economist() +
  theme(
    # Fix overlap of x axis title
    axis.title.x = element_text(size = 13, margin = margin(t = 8)),
    axis.title.y = element_text(size = 13, margin = margin(r = 8)),
    # Add space between facet title and graph
    strip.text.x = element_text(size = 13, margin = margin(b = 4), face = "bold"),
    # Make obvious/repetitive x axis labels smaller
    axis.text.x = element_text(size = 10)
  )
ggsave('trends.pdf', width = 6.5, height = 6.8, device = cairo_pdf())
# ggsave('trends.eps', width = 6.5, height = 6.8)
dev.off()

# Cumulative lineplot
# ggplot(df, aes(x=date_published_parsed, y=cum_pubs)) +
#   geom_line() +
#   # scale_x_continuous(labels = parse_date(date_published)) +
#   theme(axis.text.x = element_text(angle=90, hjust = 1)) + xlab("Date")
