library(tidyr)
library(dplyr)
library(forcats)

library(ggplot2)
library(gridExtra)
library(ggthemes)
library(tibble)
library(cowplot)

# Load raw data as "mlr" ---------------------------
source("download_faas_mlr.R")

# Extract legend helper function ---------------------------
# https://github.com/hadley/ggplot2/wiki/Share-a-legend-between-two-ggplot2-graphs
g_legend<-function(a.gplot) {
  tmp <- ggplot_gtable(ggplot_build(a.gplot))
  leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box")
  legend <- tmp$grobs[[leg]]
  return(legend)
}

# Plot helper function ---------------------------
p_plot <- function(mlr,
                   col = "p1_repeated_experiments",
                   col.label = "P1: Repeated Experiments",
                   legend = FALSE) {
  # Reshape data ---------------------------
  relevant <- mlr %>%
    filter(selection == "relevant") %>%
    mutate(p_clean = case_when(
      grepl("yes.*", get(col)) ~ "yes",
      grepl("partial.*", get(col)) ~ "partial",
      grepl("no.*", get(col)) ~ "no"
    )) %>%
    group_by(literature_type, p_clean) %>%
    summarise(freq = n(), .groups = 'drop') %>%
    mutate(rel_freq = freq / sum(freq) * 100) %>%
    ungroup() %>%
    complete(literature_type, p_clean, fill = list(freq = 0, rel_freq = 0)) %>%
    mutate(literature_type = factor(literature_type, levels = c("academic", "grey"))) %>%
    mutate(p_clean = factor(p_clean, levels = c("yes", "partial", "no"))) %>%
    mutate(literature_type = fct_recode(literature_type,
                                        "Academic" = "academic",
                                        "Grey" = "grey"
    )) %>%
    mutate(p_clean = fct_recode(p_clean,
                                "Yes" = "yes",
                                "Partial" = "partial",
                                "No" = "no"
    ))

  # Plot data ---------------------------
  gg <- ggplot(relevant, aes(x=p_clean))
  px <- ggplot(relevant, aes(x=p_clean, y=rel_freq, group=literature_type)) +
    geom_bar(aes(fill=literature_type), position = "dodge", stat = "identity", width = 0.8, show.legend = legend) +
    geom_text(
      aes(label=round(rel_freq, digits = 0)),
      position=position_dodge(width=0.8),
      vjust=-0.4
    ) +
    coord_cartesian(clip = "off") +
    scale_x_discrete(limits = c("Yes", "Partial", "No")) +
    scale_y_continuous(limits = c(0,100), expand = c(0, 0, 0, 0)) +
    labs(x = "", y = "%", fill = "Literature Type", title = col.label) +
    theme_economist() +
    scale_fill_economist() +
    theme(
      plot.title = element_text(hjust = 0.5, size = 11, margin = margin(b = 10)),
      axis.title.y = element_text(size = 13, margin = margin(r = 2)),
      legend.position = "bottom",
      )
  return (px)
}

p1 <- p_plot(mlr, col = "p1_repeated_experiments", col.label = "P1: Repeated Experiments")
p2 <- p_plot(mlr, col = "p2_workload_and_configuration_coverage", col.label = "P2: Workload and Config. Coverage")
p3 <- p_plot(mlr, col = "p3_experimental_setup_description", col.label = "P3: Experimental Setup Description")
p4 <- p_plot(mlr, col = "p4_open_access_artifact", col.label = "P4: Open Access Artifact")
p5 <- p_plot(mlr, col = "p5_probabilistic_result_description", col.label = "P5: Probabilistic Result Description")
p6 <- p_plot(mlr, col = "p6_statistical_evaluation", col.label = "P6: Statistical Evaluation")
p7 <- p_plot(mlr, col = "p7_measurement_units", col.label = "P7: Measurement Units")
p8 <- p_plot(mlr, col = "p8_cost", col.label = "P8: Cost")

p_all <- grid.arrange(p1, p2, p3, p4, p5, p6, p7, p8, nrow = 4)
legend <- g_legend(p_plot(mlr, legend = TRUE))
p_with_legend <- grid.arrange(legend, p_all, nrow = 2, heights=c(1, 16))
bgcolors <- deframe(ggthemes::ggthemes_data[["economist"]][["bg"]])
background <- bgcolors["blue-gray"]
g2 <- cowplot::ggdraw(p_with_legend) + 
  theme(plot.background = element_rect(fill=background, color = NA))
ggsave('reproducibility.pdf', width = 6.5, height = 9.3, device = cairo_pdf(), plot = g2)
# ggsave('reproducibility.eps', width = 6.5, height = 9.3, plot = g2)
