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

# Load configuration
config <- snakemake@config
fig_width <- if (!is.null(config$analysis$figure$width)) config$analysis$figure$width else 12
fig_height <- if (!is.null(config$analysis$figure$height)) config$analysis$figure$height else 10
fig_dpi <- if (!is.null(config$analysis$figure$dpi)) config$analysis$figure$dpi else 300

cat("\n═══════════════════════════════════════════════════════════════════\n")
cat("  PANEL C: G>X Mutation Spectrum by Position\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

input_data <- snakemake@input[["data"]]
output_figure <- snakemake@output[["figure"]]
output_table <- snakemake@output[["table"]]

ensure_output_dir(dirname(output_figure))
ensure_output_dir(dirname(output_table))

# ============================================================================
# VALIDATE INPUT
# ============================================================================

if (exists("validate_processed_clean")) {
  validate_processed_clean(input_data)
} else if (exists("validate_input")) {
  validate_input(input_data, 
                expected_format = "csv",
                required_columns = c("miRNA_name", "pos.mut"))
}

# ============================================================================
# LOAD AND PROCESS DATA
# ============================================================================

# Load processed_clean data (same as other panels for consistency)
data <- tryCatch({
  result <- load_processed_data(input_data)
  
  # Validate data is not empty
  if (nrow(result) == 0) {
    stop("Input dataset is empty (0 rows) after loading")
  }
  if (ncol(result) <= 2) {  # Only metadata columns
    stop("Input dataset has no sample columns after loading")
  }
  
  result
}, error = function(e) {
  stop(paste("Failed to load data:", e$message))
})

# Extract position and mutation_type from pos.mut (format: "18:TC")
processed_data <- data %>%
  mutate(
    position = as.numeric(str_extract(pos.mut, "^\\d+")),
    mutation_type_raw = str_extract(pos.mut, "(?<=:)[A-Z]+"),
    mutation_type = str_replace_all(mutation_type_raw, c(
      "TC" = "T>C", "AG" = "A>G", "GA" = "G>A", "CT" = "C>T",
      "TA" = "T>A", "GT" = "G>T", "TG" = "T>G", "AT" = "A>T",
      "CA" = "C>A", "CG" = "C>G", "GC" = "G>C", "AC" = "A>C"
    ))
  ) %>%
  filter(!is.na(position), position >= 1, position <= 22, !is.na(mutation_type))

# Validate processed data is not empty
if (nrow(processed_data) == 0) {
  stop("No valid mutations found after processing. Check position and mutation_type extraction.")
}

# COLOR_GC and COLOR_GA are defined in colors.R (sourced above)

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
           ymin = -Inf, ymax = Inf, fill = COLOR_SEED_HIGHLIGHT, alpha = 0.5) +
  geom_col(position = "stack", color = "white", linewidth = 0.3) +
  scale_fill_manual(values = c("G>C" = COLOR_GC, "G>A" = COLOR_GA, "G>T" = COLOR_GT), 
                    name = "Mutation Type") +
  scale_y_continuous(limits = c(0, 100), expand = expansion(mult = c(0, 0.02))) +
  labs(
    title = "C. G>X Mutation Spectrum by Position",
    subtitle = sprintf("G>T represents %.1f%% of all G>X mutations", gt_percentage_overall),
    x = "Position in miRNA", 
    y = "Percentage of G>X mutations (%)",
    caption = "Shows percentage of G>X SNVs (unique events) at each position, not read counts.\nCombined analysis (ALS + Control, no VAF filtering)"  # ✅ CORREGIDO: Clarificar que cuenta SNVs, no suma reads
  ) +
  theme_professional +
  theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "right")

ggsave(output_figure, p, width = fig_width, height = fig_height, dpi = fig_dpi, bg = "white")

cat("✅ PANEL C COMPLETE\n\n")
