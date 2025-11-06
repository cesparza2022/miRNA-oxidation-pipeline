#!/usr/bin/env Rscript
# ============================================================================
# STEP 2.5: Position-Specific Analysis
# ============================================================================
# Purpose: Analyze G>T mutations at each individual position (1-24)
#          Compare ALS vs Control at each position with statistical testing
# 
# Outputs:
# - Position-specific statistics table
# - Position-specific comparison visualization (bar chart with significance)
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(readr)
  library(stringr)
  library(tidyr)
})

# Load common functions
source(snakemake@params[["functions"]], local = TRUE)

# Load group comparison utilities
group_functions_path <- if (!is.null(snakemake@params[["group_functions"]])) {
  snakemake@params[["group_functions"]]
} else {
  "scripts/utils/group_comparison.R"
}

if (file.exists(group_functions_path)) {
  source(group_functions_path, local = TRUE)
} else if (file.exists("scripts/utils/group_comparison.R")) {
  source("scripts/utils/group_comparison.R", local = TRUE)
}

# Initialize logging
log_file <- if (length(snakemake@log) > 0) snakemake@log[[1]] else {
  file.path(dirname(snakemake@output[[1]]), "position_specific_analysis.log")
}
initialize_logging(log_file, context = "Step 2.5 - Position-Specific Analysis")

log_section("STEP 2.5: Position-Specific Analysis")

# ============================================================================
# GET SNAKEMAKE PARAMETERS
# ============================================================================

input_file <- if (!is.null(snakemake@input[["data"]])) {
  snakemake@input[["data"]]
} else if (!is.null(snakemake@input[["vaf_filtered_data"]])) {
  snakemake@input[["vaf_filtered_data"]]
} else {
  stop("Input data file not specified")
}

output_table <- snakemake@output[["table"]]
output_figure <- snakemake@output[["figure"]]

# Get metadata file path
metadata_file <- if (!is.null(snakemake@params[["metadata_file"]])) {
  metadata_path <- snakemake@params[["metadata_file"]]
  if (metadata_path != "" && file.exists(metadata_path)) {
    metadata_path
  } else {
    NULL
  }
} else {
  NULL
}

# Get config parameters
config <- snakemake@config
alpha <- if (!is.null(config$analysis$alpha)) config$analysis$alpha else 0.05
fdr_method <- if (!is.null(config$analysis$fdr_method)) config$analysis$fdr_method else "BH"

# Seed region definition
seed_start <- if (!is.null(config$analysis$seed_region$start)) config$analysis$seed_region$start else 2
seed_end <- if (!is.null(config$analysis$seed_region$end)) config$analysis$seed_region$end else 8

# Position range (typically 1-24 for miRNAs)
position_range <- if (!is.null(config$analysis$position_range)) {
  config$analysis$position_range
} else {
  c(1, 24)  # Default: positions 1-24
}

log_info(paste("Input file:", input_file))
log_info(paste("Output table:", output_table))
log_info(paste("Output figure:", output_figure))
log_info(paste("Significance threshold (alpha):", alpha))
log_info(paste("Seed region: positions", seed_start, "-", seed_end))
log_info(paste("Position range: positions", position_range[1], "-", position_range[2]))

ensure_output_dir(dirname(output_table))
ensure_output_dir(dirname(output_figure))

# ============================================================================
# LOAD DATA
# ============================================================================

log_subsection("Loading data")

vaf_data <- tryCatch({
  result <- read_csv(input_file, show_col_types = FALSE)
  log_success(paste("Loaded:", nrow(result), "rows,", ncol(result), "columns"))
  result
}, error = function(e) {
  handle_error(e, context = "Step 2.5 - Data Loading", exit_code = 1, log_file = log_file)
})

# Normalize column names
if ("miRNA name" %in% names(vaf_data)) {
  vaf_data <- vaf_data %>% rename(miRNA_name = `miRNA name`)
}
if ("pos:mut" %in% names(vaf_data)) {
  vaf_data <- vaf_data %>% rename(pos.mut = `pos:mut`)
}

# Extract position and mutation type
vaf_data <- vaf_data %>%
  mutate(
    position = as.numeric(str_extract(pos.mut, "^\\d+")),
    mutation_type = str_extract(pos.mut, "[ACGT][ACGT]$"),
    is_gt = str_detect(pos.mut, ":GT$"),
    in_seed = position >= seed_start & position <= seed_end
  )

# Filter G>T mutations only
gt_data <- vaf_data %>%
  filter(is_gt == TRUE) %>%
  filter(!is.na(position), position >= position_range[1], position <= position_range[2])

log_info(paste("G>T mutations:", nrow(gt_data)))
log_info(paste("Unique positions:", n_distinct(gt_data$position)))
log_info(paste("Unique miRNAs:", n_distinct(gt_data$miRNA_name)))

# ============================================================================
# EXTRACT SAMPLE GROUPS
# ============================================================================

log_subsection("Extracting sample groups")

sample_groups <- tryCatch({
  extract_sample_groups(gt_data, metadata_file = metadata_file)
}, error = function(e) {
  handle_error(e, context = "Step 2.5 - Group Identification", exit_code = 1, log_file = log_file)
})

unique_groups <- sort(unique(sample_groups$group))
if (length(unique_groups) < 2) {
  stop("Need at least 2 groups for position-specific analysis. Found:", paste(unique_groups, collapse = ", "))
}

group1_name <- unique_groups[1]
group2_name <- unique_groups[2]

group1_samples <- sample_groups %>% filter(group == group1_name) %>% pull(sample_id)
group2_samples <- sample_groups %>% filter(group == group2_name) %>% pull(sample_id)

log_info(paste("Group 1 (", group1_name, ") samples:", length(group1_samples)))
log_info(paste("Group 2 (", group2_name, ") samples:", length(group2_samples)))

# ============================================================================
# CALCULATE POSITIONAL FRACTION FOR EACH POSITION
# ============================================================================

log_subsection("Calculating positional fractions")

# Get sample columns (VAF columns)
metadata_cols <- c("miRNA_name", "pos.mut", "position", "mutation_type", "is_gt", "in_seed")
sample_cols <- names(gt_data)[!names(gt_data) %in% metadata_cols]

# Filter to valid sample columns that exist in groups
group1_cols <- intersect(group1_samples, sample_cols)
group2_cols <- intersect(group2_samples, sample_cols)

log_info(paste("Group 1 columns found:", length(group1_cols)))
log_info(paste("Group 2 columns found:", length(group2_cols)))

# Pivot to long format for analysis
gt_long <- gt_data %>%
  select(all_of(c(metadata_cols, group1_cols, group2_cols))) %>%
  pivot_longer(
    cols = all_of(c(group1_cols, group2_cols)),
    names_to = "sample_id",
    values_to = "vaf"
  ) %>%
  left_join(sample_groups, by = "sample_id") %>%
  filter(!is.na(vaf), !is.na(group)) %>%
  mutate(
    group = factor(group, levels = c(group1_name, group2_name))
  )

# Calculate positional fraction for each position and group
# Positional fraction = (sum of all VAFs at position) / (number of samples with data at that position)
positional_fraction <- gt_long %>%
  group_by(position, group) %>%
  summarise(
    n_mutations = n(),
    n_samples = n_distinct(sample_id),
    n_miRNAs = n_distinct(miRNA_name),
    mean_vaf = mean(vaf, na.rm = TRUE),
    median_vaf = median(vaf, na.rm = TRUE),
    sd_vaf = sd(vaf, na.rm = TRUE),
    total_vaf = sum(vaf, na.rm = TRUE),
    # Positional fraction = mean VAF at this position (standard approach)
    # This represents the average VAF contribution at each position
    positional_fraction = mean_vaf,
    .groups = "drop"
  ) %>%
  arrange(position, group)

log_info(paste("Positions analyzed:", n_distinct(positional_fraction$position)))

# ============================================================================
# STATISTICAL TESTING AT EACH POSITION
# ============================================================================

log_subsection("Performing statistical tests at each position")

position_stats <- gt_long %>%
  group_by(position) %>%
  summarise(
    # Sample sizes
    n_group1 = sum(group == group1_name),
    n_group2 = sum(group == group2_name),
    
    # Means
    mean_group1 = mean(vaf[group == group1_name], na.rm = TRUE),
    mean_group2 = mean(vaf[group == group2_name], na.rm = TRUE),
    
    # SDs
    sd_group1 = sd(vaf[group == group1_name], na.rm = TRUE),
    sd_group2 = sd(vaf[group == group2_name], na.rm = TRUE),
    
    # Statistical tests
    t_test_pvalue = tryCatch({
      test_result <- t.test(vaf[group == group1_name], vaf[group == group2_name])
      test_result$p.value
    }, error = function(e) NA_real_),
    
    wilcoxon_pvalue = tryCatch({
      test_result <- wilcox.test(vaf[group == group1_name], vaf[group == group2_name])
      test_result$p.value
    }, error = function(e) NA_real_),
    
    # Effect size
    fold_change = ifelse(mean_group2 > 0, mean_group1 / mean_group2, NA_real_),
    log2_fold_change = ifelse(!is.na(fold_change) && fold_change > 0, log2(fold_change), NA_real_),
    
    .groups = "drop"
  ) %>%
  mutate(
    # Use appropriate test (Wilcoxon if data not normal, t-test otherwise)
    pvalue = ifelse(!is.na(wilcoxon_pvalue), wilcoxon_pvalue, t_test_pvalue),
    # FDR correction
    pvalue_fdr = p.adjust(pvalue, method = fdr_method),
    # Significance
    significant = !is.na(pvalue_fdr) & pvalue_fdr < alpha,
    # Direction
    higher_in_group1 = !is.na(log2_fold_change) & log2_fold_change > 0,
    in_seed = position >= seed_start & position <= seed_end
  )

# Merge with positional fraction data
position_summary <- position_stats %>%
  left_join(
    positional_fraction %>%
      select(position, group, positional_fraction, mean_vaf, n_mutations, n_samples, n_miRNAs) %>%
      pivot_wider(
        names_from = group,
        values_from = c(positional_fraction, mean_vaf, n_mutations, n_samples, n_miRNAs),
        names_sep = "_"
      ),
    by = "position"
  ) %>%
  arrange(position)

log_info(paste("Significant positions (p_adj <", alpha, "):", sum(position_summary$significant, na.rm = TRUE)))
log_info(paste("  - Higher in", group1_name, ":", sum(position_summary$significant & position_summary$higher_in_group1, na.rm = TRUE)))
log_info(paste("  - Higher in", group2_name, ":", sum(position_summary$significant & !position_summary$higher_in_group1, na.rm = TRUE)))

# ============================================================================
# ADAPTIVE THRESHOLD DETECTION
# ============================================================================

log_subsection("Checking adaptive thresholds")

n_significant <- sum(position_summary$significant, na.rm = TRUE)
if (n_significant < 3) {
  log_warning(paste("LOW SIGNAL DETECTED: Only", n_significant, "significant positions found. Results may not be robust."))
}

# Check if any positions in seed region are significant
seed_significant <- sum(position_summary$significant & position_summary$in_seed, na.rm = TRUE)
if (seed_significant == 0 && any(position_summary$in_seed, na.rm = TRUE)) {
  log_warning("No significant differences found in seed region (positions 2-8). This may indicate weak signal.")
}

# ============================================================================
# SAVE RESULTS TABLE
# ============================================================================

log_subsection("Saving results table")

# Prepare output table with clear column names
output_data <- position_summary %>%
  select(
    position,
    in_seed,
    # Group 1 statistics
    positional_fraction = paste0("positional_fraction_", group1_name),
    mean_vaf_group1 = paste0("mean_vaf_", group1_name),
    n_mutations_group1 = paste0("n_mutations_", group1_name),
    n_samples_group1 = paste0("n_samples_", group1_name),
    # Group 2 statistics
    positional_fraction_control = paste0("positional_fraction_", group2_name),
    mean_vaf_group2 = paste0("mean_vaf_", group2_name),
    n_mutations_group2 = paste0("n_mutations_", group2_name),
    n_samples_group2 = paste0("n_samples_", group2_name),
    # Statistics
    fold_change,
    log2_fold_change,
    t_test_pvalue,
    wilcoxon_pvalue,
    pvalue_fdr,
    significant,
    higher_in_group1
  ) %>%
  rename(
    !!paste0("positional_fraction_", group1_name) := positional_fraction,
    !!paste0("positional_fraction_", group2_name) := positional_fraction_control
  )

write_csv(output_data, output_table)
log_success(paste("Saved position-specific statistics to:", output_table))

# ============================================================================
# CREATE VISUALIZATION
# ============================================================================

log_subsection("Creating visualization")

# Prepare data for plotting
plot_data <- positional_fraction %>%
  left_join(
    position_summary %>% select(position, pvalue_fdr, significant),
    by = "position"
  ) %>%
  mutate(
    # Add significance markers
    significance_marker = ifelse(significant, "*", ""),
    # Ensure group factor
    group = factor(group, levels = c(group1_name, group2_name))
  )

# Get colors from config
color_group1 <- if (group1_name == "ALS" || str_detect(group1_name, regex("als|disease", ignore_case = TRUE))) {
  if (!is.null(config$analysis$colors$als)) config$analysis$colors$als else "#D62728"
} else {
  if (!is.null(config$analysis$colors$gt)) config$analysis$colors$gt else "#D62728"
}

color_group2 <- if (group2_name == "Control" || str_detect(group2_name, regex("control|ctrl", ignore_case = TRUE))) {
  if (!is.null(config$analysis$colors$control)) config$analysis$colors$control else "grey60"
} else {
  "grey60"
}

group_colors <- setNames(c(color_group1, color_group2), c(group1_name, group2_name))

# Create the plot (matching the provided figure style)
p <- ggplot(plot_data, aes(x = position, y = positional_fraction, fill = group)) +
  # Seed region background (light gray)
  annotate("rect",
           xmin = seed_start - 0.5, xmax = seed_end + 0.5,
           ymin = -Inf, ymax = Inf,
           alpha = 0.15, fill = "lightgray") +
  annotate("text",
           x = (seed_start + seed_end) / 2, 
           y = max(plot_data$positional_fraction, na.rm = TRUE) * 0.98,
           label = paste("Región seed sombreada (pos", seed_start, "-", seed_end, ")"),
           size = 3.5, color = "gray30", hjust = 0.5, vjust = 0) +
  # Bars
  geom_bar(stat = "identity", position = "dodge", width = 0.7, alpha = 0.85) +
  # Significance markers (asterisks above bars)
  geom_text(aes(label = significance_marker, 
                y = positional_fraction + max(plot_data$positional_fraction, na.rm = TRUE) * 0.01),
            position = position_dodge(width = 0.7),
            vjust = 0, size = 5, color = "black", fontface = "bold") +
  # Colors (matching provided figure)
  scale_fill_manual(values = group_colors, name = "Grupo") +
  # Axes
  scale_x_continuous(breaks = seq(position_range[1], position_range[2], by = 1),
                     expand = expansion(mult = c(0.01, 0.01))) +
  scale_y_continuous(breaks = seq(0, ceiling(max(plot_data$positional_fraction, na.rm = TRUE) * 10) / 10, by = 0.025),
                     expand = expansion(mult = c(0, 0.12)),
                     labels = scales::number_format(accuracy = 0.001)) +
  # Labels (matching provided figure style)
  labs(
    title = paste("Distribución de mutaciones G>T por posición:", group2_name, "vs", group1_name),
    subtitle = paste("Fracción posicional de G>T | Región seed (pos", seed_start, "-", seed_end, ") destacada |",
                     "* = p_adj <", alpha),
    x = "Posición en miRNA",
    y = "Fracción posicional",
    caption = paste("Posiciones significativas:", sum(position_summary$significant, na.rm = TRUE),
                    "|", group1_name, "mayor:", sum(position_summary$significant & position_summary$higher_in_group1, na.rm = TRUE),
                    "|", group2_name, "mayor:", sum(position_summary$significant & !position_summary$higher_in_group1, na.rm = TRUE))
  ) +
  theme_professional +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5),
    axis.text.x = element_text(angle = 0, hjust = 0.5, size = 9),
    axis.text.y = element_text(size = 9),
    axis.title = element_text(size = 11),
    legend.position = "right",
    plot.caption = element_text(size = 9, hjust = 0.5)
  )

# Save figure
ggsave(output_figure, plot = p, width = 14, height = 8, dpi = 300)
log_success(paste("Saved figure to:", output_figure))

# ============================================================================
# SUMMARY
# ============================================================================

log_section("STEP 2.5 COMPLETE")

log_info("Summary:")
log_info(paste("  - Positions analyzed:", nrow(position_summary)))
log_info(paste("  - Significant positions:", n_significant))
log_info(paste("  - Significant in seed region:", seed_significant))
log_info(paste("  - Output table:", output_table))
log_info(paste("  - Output figure:", output_figure))

if (n_significant < 3) {
  log_warning("⚠️  LOW SIGNAL: Consider checking data quality or adjusting thresholds")
}

log_success("Step 2.5 completed successfully!")

