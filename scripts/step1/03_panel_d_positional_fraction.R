#!/usr/bin/env Rscript
# ============================================================================
# PANEL D: Positional Fraction of Mutations (Snakemake version)
# ============================================================================
# Purpose: Proportion of ALL SNVs occurring at each position (relative to total)

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
  library(readr)
  library(stringr)
  library(scales)
})

source(snakemake@params[["functions"]], local = TRUE)

cat("\n═══════════════════════════════════════════════════════════════════\n")
cat("  PANEL D: Positional Fraction of Mutations\n")
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

# COUNT SNVs by position (NOT sum counts) - ALL mutations
pos_counts <- processed_data %>%
  count(position, name = "snv_count") %>%
  arrange(position)

total_mut <- sum(pos_counts$snv_count)

pos_frac <- pos_counts %>%
  mutate(
    fraction = snv_count / total_mut * 100,
    position_label = factor(position, levels = 1:22),
    region = ifelse(position >= 2 & position <= 8, "Seed", "Non-Seed")
  )

write_csv(pos_frac %>% mutate(position_label = as.character(position_label)) %>%
            select(position, snv_count, fraction, position_label, region), 
          output_table)

cat("   📊 Total SNVs:", format(total_mut, big.mark=","), 
    "| Fractions sum to:", round(sum(pos_frac$fraction), 2), "%\n\n")

panel_d <- ggplot(pos_frac, aes(x = position_label, y = fraction)) +
  geom_col(aes(fill = region), alpha = 0.8, width = 0.7) +
  scale_fill_manual(values = c("Seed" = "#FFD700", "Non-Seed" = "grey60"), name = "Region") +
  geom_text(aes(label = sprintf("%.1f%%", fraction)), 
            vjust = -0.3, size = 3.5, fontface = "bold") +
  labs(
    title = "D. Positional Fraction of Mutations",
    subtitle = sprintf("What percentage of ALL mutations occur at each position? (Total: %s SNVs)", 
                       format(total_mut, big.mark=",")),
    x = "Position in miRNA",
    y = "Percentage of total mutations (%)"
  ) +
  theme_professional +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave(output_figure, panel_d, width = 10, height = 8, dpi = 300, bg = "white")

cat("✅ PANEL D COMPLETE\n\n")

