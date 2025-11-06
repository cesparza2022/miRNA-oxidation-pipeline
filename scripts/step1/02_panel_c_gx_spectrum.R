#!/usr/bin/env Rscript
# ============================================================================
# PANEL C: G>X Mutation Spectrum by Position (Snakemake version)
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
  library(readr)
  library(stringr)
  library(scales)
})

source(snakemake@params[["functions"]], local = TRUE)

cat("\n═══════════════════════════════════════════════════════════════════\n")
cat("  PANEL C: G>X Mutation Spectrum by Position\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

input_raw <- snakemake@input[["raw_data"]]
output_figure <- snakemake@output[["figure"]]
output_table <- snakemake@output[["table"]]

ensure_output_dir(dirname(output_figure))
ensure_output_dir(dirname(output_table))

# ============================================================================
# VALIDATE INPUT
# ============================================================================

if (exists("validate_raw_data")) {
  validate_raw_data(input_raw)
} else if (exists("validate_input")) {
  validate_input(input_raw, 
                expected_format = "tsv",
                required_columns = c("pos:mut"))
}

# ============================================================================
# LOAD AND PROCESS DATA
# ============================================================================

processed_data <- load_and_process_raw_data(input_raw)

COLOR_GC <- "#2E86AB"
COLOR_GA <- "#7D3C98"

gx_spectrum_data <- processed_data %>%
  filter(str_detect(mutation_type, "^G>")) %>%
  count(position, mutation_type) %>%
  group_by(position) %>%
  mutate(
    percentage = n / sum(n) * 100,
    total_gx_at_pos = sum(n)
  ) %>%
  ungroup() %>%
  mutate(
    position_label = factor(position, levels = 1:22),
    mutation_type = factor(mutation_type, levels = c("G>C", "G>A", "G>T"))
  )

gt_percentage_overall <- sum(gx_spectrum_data$n[gx_spectrum_data$mutation_type == "G>T"]) / sum(gx_spectrum_data$n) * 100

write_csv(gx_spectrum_data %>% mutate(position_label = as.character(position_label)), output_table)

seed_min <- 2; seed_max <- 8

p <- ggplot(gx_spectrum_data, aes(x = position_label, y = percentage, fill = mutation_type)) +
  annotate("rect", xmin = seed_min - 0.5, xmax = seed_max + 0.5, 
           ymin = -Inf, ymax = Inf, fill = "#e3f2fd", alpha = 0.5) +
  geom_col(position = "stack", color = "white", linewidth = 0.3) +
  scale_fill_manual(values = c("G>C" = COLOR_GC, "G>A" = COLOR_GA, "G>T" = COLOR_GT), 
                    name = "Mutation Type") +
  scale_y_continuous(limits = c(0, 100), expand = expansion(mult = c(0, 0.02))) +
  labs(
    title = "C. G>X Mutation Spectrum by Position",
    subtitle = sprintf("G>T represents %.1f%% of all G>X mutations", gt_percentage_overall),
    x = "Position in miRNA", 
    y = "Percentage of G>X mutations (%)",
    caption = "Combined analysis (ALS + Control, no VAF filtering)"
  ) +
  theme_professional +
  theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "right")

ggsave(output_figure, p, width = 12, height = 6, dpi = 300, bg = "white")

cat("✅ PANEL C COMPLETE\n\n")
