library(dplyr)
library(forcats)

library(ggplot2)
library(ggthemes)
library(scales)

# Load raw data as "mlr" ---------------------------
source("download_faas_mlr.R")

# Prepare data ---------------------------
df <- mlr %>%
  filter(selection == "relevant") %>%
  filter(literature_type == "academic") %>%
  mutate(venue_ranking = factor(venue_ranking, levels = rev(c("A*", "A", "B", "C", "W", "Unranked")))) %>%
  mutate(venue_ranking = fct_recode(venue_ranking, "Workshop" = "W"))

df_freq <- df %>%
  group_by(venue_ranking) %>%
  summarise(freq = n(), .groups = 'drop') %>%
  mutate(rel_freq = freq / sum(freq) * 100) %>%
  mutate(x = paste("Academic Studies\n(N=", sum(freq), ")", sep = ""))

# Save to csv ---------------------------
write.csv(df_freq, "rankings.csv", row.names = FALSE)

# Plot graph ---------------------------
ggplot(df_freq, aes(fill=venue_ranking, y=rel_freq, x=x)) + 
  geom_bar(position="fill", stat="identity", width = 0.6) +
  scale_y_continuous(labels = percent_format()) +
  geom_text(aes(label=round(freq, 0)), position=position_fill(vjust = 0.5), colour="white") +
  coord_flip() +
  labs(fill = "Venue Ranking") +
  guides(fill = guide_legend(reverse = TRUE)) +
  theme_economist() +
  scale_fill_economist() +
  theme(axis.title.x = element_blank(),
        axis.title.y = element_blank(),
        axis.text.y = element_text(angle = 90, hjust = 0.5),
        legend.box.margin=margin(0, 0,-10, 0)
        )
ggsave('rankings.pdf', width = 6.5, height = 2, device = cairo_pdf())
# ggsave('rankings.eps', width = 6.5, height = 2)
dev.off()
