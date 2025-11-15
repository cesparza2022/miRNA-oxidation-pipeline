#!/usr/bin/env Rscript
# ============================================================================
# PANEL B: G>T Count by Position (Snakemake version)
# ============================================================================
# Purpose: Show absolute count of G>T mutations across all positions (1-23)
# 
# Snakemake parameters:
#   input: Path to processed data CSV
#   output_figure: Path to output figure PNG
#   output_table: Path to output table CSV
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
  library(readr)
  library(stringr)
  library(scales)
})

# Load common functions
source(snakemake@params[["functions"]], local = TRUE)

# Initialize logging
log_file <- if (length(snakemake@log) > 0) snakemake@log[[1]] else {
  file.path(dirname(snakemake@output[[1]]), "..", "logs", "panel_b.log")
}
initialize_logging(log_file, context = "Panel B")

log_section("PANEL B: G>T Count by Position")

# ============================================================================
# GET SNAKEMAKE PARAMETERS
# ============================================================================

input_file <- snakemake@input[["data"]]
output_figure <- snakemake@output[["figure"]]
output_table <- snakemake@output[["table"]]

log_info(paste("Input file:", input_file))
log_info(paste("Output figure:", output_figure))
log_info(paste("Output table:", output_table))

# Ensure output directories exist
ensure_output_dir(dirname(output_figure))
ensure_output_dir(dirname(output_table))

# ============================================================================
# VALIDATE INPUT
# ============================================================================

# Validate input (handles both column name formats: with dots and with spaces)
if (exists("validate_processed_clean")) {
  validate_processed_clean(input_file)
} else if (exists("validate_input")) {
  # Try both possible column name formats
  validate_input(input_file, 
                expected_format = "csv",
                required_columns = c("miRNA name", "pos:mut"))
}

# ============================================================================
# LOAD DATA
# ============================================================================

log_subsection("Loading data")
data <- tryCatch({
  result <- load_processed_data(input_file)
  
  # Additional validation after loading
  if (nrow(result) == 0) {
    stop("Input dataset is empty (0 rows) after loading")
  }
  if (ncol(result) <= 2) {  # Only metadata columns
    stop("Input dataset has no sample columns after loading")
  }
  
  log_success(paste("Data loaded:", nrow(result), "rows,", ncol(result), "columns"))
  result
}, error = function(e) {
  handle_error(e, context = "Panel B - Data Loading", exit_code = 1, log_file = log_file)
})

sample_cols <- setdiff(names(data), c("miRNA_name", "pos.mut"))

# Validate we have sample columns
if (length(sample_cols) == 0) {
  stop("No sample columns found in dataset. Check column names.")
}

# ============================================================================
# PROCESS DATA: Extract G>T mutations by position
# ============================================================================

log_subsection("Processing G>T mutations")

# Filter G>T mutations only
gt_data <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  mutate(
    position = as.numeric(str_extract(pos.mut, "^\\d+"))
  ) %>%
  filter(!is.na(position), position >= 1, position <= 23)

# Validate G>T data is not empty
if (nrow(gt_data) == 0) {
  stop("No G>T mutations found in dataset. Check data filtering and mutation type extraction.")
}

log_info(paste("G>T mutations found:", format(nrow(gt_data), big.mark = ","), "SNVs"))

# Calculate total counts per position (sum across all samples)
position_counts <- gt_data %>%
  rowwise() %>%
  mutate(
    total_count = sum(c_across(all_of(sample_cols)), na.rm = TRUE)
  ) %>%
  ungroup() %>%
  group_by(position) %>%
  summarise(
    total_GT_count = sum(total_count, na.rm = TRUE),  # Suma de reads (usado en figura)
    # n_SNVs y n_miRNAs se calculan pero no se usan en la figura - eliminados para evitar confusión
    .groups = "drop"
  ) %>%
  arrange(position)

log_info(paste("Positions analyzed:", nrow(position_counts)))
log_info(paste("Total G>T counts:", format(sum(position_counts$total_GT_count), big.mark = ",")))

# ============================================================================
# EXPORT TABLE
# ============================================================================

write_csv(position_counts, output_table)
log_success(paste("Table exported:", output_table))

# ============================================================================
# GENERATE FIGURE
# ============================================================================

log_subsection("Generating figure")

# Seed region annotation
seed_min <- 2
seed_max <- 8

# Create bar plot
fig_panelB <- ggplot(position_counts, aes(x = position, y = total_GT_count)) +
  # Seed region background
  annotate("rect", xmin = seed_min - 0.5, xmax = seed_max + 0.5, 
           ymin = -Inf, ymax = Inf, 
           fill = COLOR_SEED_HIGHLIGHT, alpha = 0.5) +
  annotate("text", x = (seed_min + seed_max) / 2, 
           y = max(position_counts$total_GT_count) * 0.95, 
           label = "SEED", color = "gray40", size = 4, fontface = "bold") +
  
  # Bars
  geom_bar(stat = "identity", fill = COLOR_GT, alpha = 0.85, width = 0.7) +
  
  # Scales
  scale_x_continuous(breaks = seq(1, 23, by = 2)) +
  scale_y_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.1))) +
  
  # Labels
  labs(
    title = "G>T Read Counts by Position",
    subtitle = "Total read counts supporting G>T mutations across miRNA positions | Shaded region = seed (2-8)",
    x = "Position in miRNA",
    y = "Total G>T Read Counts",
    caption = "Shows sum of sequencing reads (not number of unique SNVs). Combined analysis (ALS + Control, no VAF filtering)"
  ) +
  theme_professional

# Save figure
ggsave(
  output_figure,
  fig_panelB,
  width = 14,
  height = 8,
  dpi = 300,
  bg = "white"
)

log_success(paste("Figure saved:", output_figure))

# ============================================================================
# SUMMARY
# ============================================================================

log_subsection("Summary Statistics")

log_info("TOP 5 POSITIONS (highest G>T count):")
top5 <- position_counts %>% 
  arrange(desc(total_GT_count)) %>% 
  head(5)
print(top5)

log_info("SEED vs NON-SEED:")
seed_stats <- position_counts %>%
  mutate(region = ifelse(position >= seed_min & position <= seed_max, "Seed", "Non-seed")) %>%
  group_by(region) %>%
  summarise(
    total_count = sum(total_GT_count),
    n_positions = n(),
    .groups = "drop"
  )
print(seed_stats)

log_success("Panel B completed successfully")
log_info(paste("Execution completed at", get_timestamp()))

