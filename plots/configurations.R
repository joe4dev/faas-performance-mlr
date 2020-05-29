library(dplyr)
library(tidyr)
library(forcats)

library(ggplot2)
library(ggthemes)

# Load raw data as "mlr" ---------------------------
source("download_faas_mlr.R")

# Plot helper function ---------------------------
c_df <- function(mlr,
                 col = "p3_external_services",
                 facet = "(c) External Service Integration",
                 groups = c("Cloud AI API", "Database", "Cache", "Cloud Cache"),
                 mappings = c("None" = "none")) {
  # Prepare data ---------------------------
  df <- mlr %>%
    filter(selection == "relevant") %>%
    select(id, literature_type, col) %>%
    separate_rows(col, sep = ", ")
  df_type <- mlr %>%
    filter(selection == "relevant") %>%
    group_by(literature_type) %>%
    summarise(freq = n())
  academic_count <- df_type %>% filter(literature_type == "academic") %>% pull(freq)
  grey_count <- df_type %>% filter(literature_type == "grey") %>% pull(freq)

  df_freq <- df %>%
    group_by(literature_type, get(col)) %>%
    mutate(new_col = replace(get(col), get(col) %in% groups, "Others")) %>%
    ungroup() %>%
    group_by(literature_type, new_col) %>%
    summarise(freq = n()) %>%
    mutate(rel_freq = freq / sum(freq) * 100) %>%
    ungroup() %>%
    complete(literature_type, new_col, fill = list(freq = 0, rel_freq = 0)) %>%
    mutate(new_col = fct_recode(new_col,
      !!!mappings
    )) %>%
    mutate(rel_freq = case_when(
      literature_type == "academic" ~ freq / academic_count * 100,
      literature_type == "grey" ~ freq / grey_count * 100
    ))

  totals <- df_freq %>%
    ungroup %>%
    group_by(new_col) %>%
    summarize(total = sum(freq), rel_total = mean(rel_freq))

  df2 <- merge(df_freq, totals) %>%
    mutate(new_col = fct_reorder(new_col, rel_total)) %>%
    arrange(rel_total) %>%
    mutate(facet = facet)
  return(df2)

  # Plot barplot ---------------------------
  # p <- ggplot(df2, aes(x=new_col, y=rel_freq, label=rel_freq, fill=literature_type)) +
  #   geom_bar(position=position_dodge(width = -0.9), stat="identity") +
  #   geom_text(aes(label=round(rel_freq, 0)), position=position_dodge(width = -0.9), hjust = -0.5) +
  #   labs(x = col.label, y = "Share of Studies (%)", fill = "Literature Type") +
  #   coord_flip() +
  #   theme_economist() +
  #   scale_fill_economist() +
  #   theme(
  #     # Fix overlap of x axis title
  #     axis.title.x = element_text(size = 13, margin = margin(t = 8)),
  #     axis.title.y = element_text(size = 13, margin = margin(r = 8)),
  #     # Add space between facet title and graph
  #     strip.text.x = element_text(size = 13, margin = margin(b = 4), face = "bold"),
  #     # Make obvious/repetitive x axis labels smaller
  #     axis.text.x = element_text(size = 10)
  #   )
  # return(p)
}

df_runtimes <- c_df(mlr,
                    col = "p3_runtimes",
                    facet = "(a) Language Runtimes",
                    groups = c("bucklescript", "clojure", "php", "purescript", "rust", "C", "C++", "clojurescript", "haskell", "kotlin", "swift", "fsharp", "scala"),
                    mappings = c("Unknown" = "no", "Python" = "python", "Node.js" = "nodejs", "Java" = "java", "Go" = "go", "C#" = "csharp", "Ruby" = "ruby"))
df_triggers <- c_df(mlr,
                    col = "p3_workload_trigger",
                    facet = "(b) Function Triggers",
                    groups = c(),
                    mappings = c("Unknown" = "no", "HTTP" = "http", "SDK" = "code", "Storage" = "storage", "Workflow" = "workflow", "Stream" = "stream", "Pub/Sub" = "pub/sub", "Timer" = "timer", "CLI" = "cli", "Queue" = "queue", "Database" = "database"))
df_services <- c_df(mlr,
                    col = "p3_external_services",
                    facet = "(c) External Services",
                    groups = c("Cloud AI API", "Database", "Cache", "Cloud Cache"),
                    mappings = c("None" = "none"))

grid <- rbind(df_runtimes, df_triggers, df_services)
grid2 <- grid %>%
  mutate(literature_type = fct_recode(literature_type,
                                      "Academic" = "academic",
                                      "Grey" = "grey"
  ))
  # mutate(facet = factor(facet, levels = c("(a) Language Runtimes", "(b) Function Triggers", "(c) External Services")))

# Save to csv ---------------------------
write.csv(grid2, "configurations.csv", row.names = FALSE)

# If same rounded label should correspond same length: y = round(rel_freq, 0)
ggplot(grid2, aes(x=new_col, y=rel_freq, label=rel_freq, fill=literature_type)) +
  geom_bar(position=position_dodge(width = -0.9), stat="identity") +
  geom_text(aes(label=paste(round(rel_freq, 0), "%", sep = "")), position=position_dodge(width = -0.9), hjust = -0.2) +
  labs(x = "Platform Configurations", y = "Share of Studies (%)", fill = "Literature Type") +
  coord_flip(clip = "off") +
  facet_grid(rows = vars(facet), scales = "free_y", space = "free_y") +
  theme_economist() +
  scale_fill_economist() +
  theme(
    # Fix overlap of x axis title
    axis.title.x = element_text(size = 13, margin = margin(t = 8)),
    # axis.title.y = element_text(size = 13, margin = margin(r = 8)),
    axis.title.y = element_blank(),
    # Add space between facet title and graph
    strip.text.x = element_text(size = 13, margin = margin(b = 4), face = "bold"),
    # Make obvious/repetitive x axis labels smaller
    axis.text.x = element_text(size = 10),
    # Add space between facet title and graph
    strip.text.y = element_text(margin = margin(l = 4))
  )

ggsave("configurations.pdf", width = 6.5, height = 16.5, device = cairo_pdf())
dev.off()
