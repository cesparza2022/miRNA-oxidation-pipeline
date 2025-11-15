#!/usr/bin/env Rscript
# ============================================================================
# PANEL E: G-Content Landscape - Bubble Plot (Snakemake version)
# ============================================================================
# 3 metrics in one plot:
# - Y-axis: Total copies of miRNAs with G at that position
# - Bubble size: Number of unique miRNAs with G at that position
# - Bubble color: Sum of SNV G>T counts at that SPECIFIC position

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

# Initialize logging
log_file <- if (length(snakemake@log) > 0) snakemake@log[[1]] else {
  file.path(dirname(snakemake@output[[1]]), "..", "logs", "panel_e.log")
}
initialize_logging(log_file, context = "Panel E")

log_section("PANEL E: G-Content Landscape - Bubble Plot")

input_file <- snakemake@input[["data"]]
output_figure <- snakemake@output[["figure"]]
output_table <- snakemake@output[["table"]]

log_info(paste("Input file:", input_file))
log_info(paste("Output figure:", output_figure))
log_info(paste("Output table:", output_table))

ensure_output_dir(dirname(output_figure))
ensure_output_dir(dirname(output_table))

# ============================================================================
# VALIDATE INPUT
# ============================================================================

if (exists("validate_processed_clean")) {
  validate_processed_clean(input_file)
} else if (exists("validate_input")) {
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
  handle_error(e, context = "Panel E - Data Loading", exit_code = 1, log_file = log_file)
})

sample_cols <- setdiff(names(data), c("miRNA_name", "pos.mut"))

# Validate we have sample columns
if (length(sample_cols) == 0) {
  stop("No sample columns found in dataset. Check column names.")
}

log_subsection("Calculating metrics")

log_info("Metric 1: Total copies of miRNAs with G at each position (CORRECTED: only counts from that specific position)")

# ✅ CORREGIDO: Sumar solo los reads de esa posición específica, no todos los reads del miRNA
total_copies_by_position <- data %>%
  filter(str_detect(pos.mut, "^\\d+:G[TCAG]")) %>%
  mutate(Position = as.numeric(str_extract(pos.mut, "^\\d+"))) %>%
  rowwise() %>%
  mutate(position_specific_counts = sum(c_across(all_of(sample_cols)), na.rm = TRUE)) %>%
  ungroup() %>%
  group_by(Position) %>%
  summarise(
    total_G_copies = sum(position_specific_counts, na.rm = TRUE),  # ✅ Solo reads de esa posición
    .groups = 'drop'
  )

log_info("Metric 2: Sum of G>T SNVs at specific positions")

gt_counts_specific <- data %>%
  filter(str_detect(pos.mut, "^\\d+:GT$")) %>%
  mutate(Position = as.numeric(str_extract(pos.mut, "^\\d+"))) %>%
  group_by(Position) %>%
  summarise(
    GT_counts_at_position = sum(across(all_of(sample_cols)), na.rm = TRUE),
    .groups = 'drop'
  )

log_info("Metric 3: Number of unique miRNAs with G")

unique_mirnas_by_pos <- data %>%
  filter(str_detect(pos.mut, "^\\d+:G[TCAG]")) %>%
  mutate(Position = as.numeric(str_extract(pos.mut, "^\\d+"))) %>%
  group_by(Position) %>%
  summarise(
    n_unique_miRNAs = n_distinct(miRNA_name),
    .groups = 'drop'
  )

panel_e_final <- total_copies_by_position %>%
  left_join(gt_counts_specific, by = "Position") %>%
  left_join(unique_mirnas_by_pos, by = "Position") %>%
  replace_na(list(GT_counts_at_position = 0, n_unique_miRNAs = 0)) %>%
  mutate(
    is_seed = Position >= 2 & Position <= 8
  )

write_csv(panel_e_final, output_table)
log_success(paste("Table exported:", output_table))

# COLOR_SEED_BACKGROUND is defined in colors.R (sourced above)

panel_e <- ggplot(panel_e_final, aes(x = Position, y = total_G_copies)) +
  annotate("rect", 
           xmin = 1.5, xmax = 8.5,  
           ymin = 0, ymax = Inf,
           fill = COLOR_SEED_BACKGROUND, alpha = 0.35) +
  annotate("text", x = 5, y = min(panel_e_final$total_G_copies) * 0.5,
           label = "SEED REGION\n(positions 2-8)", 
           size = 4.5, fontface = "bold", color = "gray40") +
  geom_point(aes(size = n_unique_miRNAs, 
                 fill = GT_counts_at_position),
             shape = 21, color = "black", alpha = 0.85, stroke = 1.8) +
  geom_text(aes(label = n_unique_miRNAs), 
            size = 3, fontface = "bold", color = "white") +
  scale_x_continuous(breaks = 1:23, minor_breaks = NULL) +
  scale_y_continuous(
    labels = comma,
    trans = "log10",
    breaks = c(0.1, 1, 10, 100, 1000)
  ) +
  scale_size_continuous(
    name = "Number of\nUnique miRNAs\nwith G",
    range = c(3, 20),
    breaks = c(25, 50, 100, 150)
  ) +
  scale_fill_gradient(
    low = COLORS_SEQUENTIAL_LOW_PINK,
    high = COLORS_SEQUENTIAL_HIGH_DARK,
    name = "G>T SNV Counts\nat Position",
    labels = comma,
    trans = "log10"
  ) +
  labs(
    title = "E. G-Content Landscape: Substrate, Diversity, and Oxidation Burden",
    subtitle = "Y-axis: Total read counts for G mutations at position | Bubble size: Unique miRNAs | Bubble color: G>T mutation counts",
    x = "Position in miRNA (1-23)",
    y = "Total read counts for G mutations at position (log scale)",
    caption = "Each bubble represents a position. Y-position = total read counts for G mutations at that SPECIFIC position (not all reads from miRNAs with G).\nBubble size = miRNA diversity (how many different miRNAs have G at that position). Bubble color intensity = G>T oxidation burden (darker red = more G>T).\nSeed region (2-8) highlighted in yellow. Log scale for better visualization of wide value ranges."
  ) +
  theme_professional +
  theme(
    legend.position = "right"
  )

log_subsection("Generating figure")
ggsave(output_figure, panel_e, width = fig_width, height = fig_height, dpi = fig_dpi, bg = "white")
log_success(paste("Figure saved:", output_figure))

log_success("Panel E completed successfully")
log_info(paste("Execution completed at", get_timestamp()))

