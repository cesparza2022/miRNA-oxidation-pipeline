#!/usr/bin/env Rscript
# ============================================================================
# STEP 2.3: Effect Size Analysis - Dynamic Group Comparison
# ============================================================================
# Purpose: Calculate and visualize effect sizes (Cohen's d, etc.)
# 
# Supports any group names (not hardcoded to ALS/Control)
# 
# Snakemake parameters:
#   input: Statistical comparison results from Step 2.1
#   output: Effect size table and figure
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
  library(readr)
  library(scales)
  library(stringr)
})

# Load common functions
source(snakemake@params[["functions"]], local = TRUE)

# Initialize logging
log_file <- if (length(snakemake@log) > 0) snakemake@log[[1]] else {
  file.path(dirname(snakemake@output[[1]]), "effect_size.log")
}
initialize_logging(log_file, context = "Step 2.3 - Effect Size Analysis")

log_section("STEP 2.3: Effect Size Analysis - Dynamic Group Comparison")

# ============================================================================
# HELPER FUNCTION: Detect Group Names from Comparison Table
# ============================================================================

detect_group_names_from_table <- function(comparison_table) {
  # Look for columns ending with _mean
  mean_cols <- names(comparison_table)[str_detect(names(comparison_table), "_mean$")]
  
  if (length(mean_cols) == 0) {
    # Fallback: try to find ALS_mean, Control_mean
    if ("ALS_mean" %in% names(comparison_table) && "Control_mean" %in% names(comparison_table)) {
      return(list(group1 = "ALS", group2 = "Control"))
    }
    stop("Could not detect group names from comparison table columns")
  }
  
  # Extract group names from column names (remove _mean suffix)
  group_names <- str_replace(mean_cols, "_mean$", "")
  
  # Filter out backward-compatible columns if dynamic names exist
  if (length(group_names) > 2) {
    # Remove ALS and Control if other groups exist
    group_names <- group_names[!group_names %in% c("ALS", "Control")]
  }
  
  if (length(group_names) < 2) {
    # Fallback to ALS/Control if only one detected
    if ("ALS_mean" %in% names(comparison_table) && "Control_mean" %in% names(comparison_table)) {
      return(list(group1 = "ALS", group2 = "Control"))
    }
    stop("Could not detect 2 groups from comparison table")
  }
  
  # Sort for consistency
  group_names <- sort(group_names)[1:2]
  
  return(list(group1 = group_names[1], group2 = group_names[2]))
}

# ============================================================================
# GET SNAKEMAKE PARAMETERS
# ============================================================================

input_table <- snakemake@input[["comparisons"]]
output_table <- snakemake@output[["table"]]
output_figure <- snakemake@output[["figure"]]

log_info(paste("Input table:", input_table))
log_info(paste("Output table:", output_table))
log_info(paste("Output figure:", output_figure))

ensure_output_dir(dirname(output_table))
ensure_output_dir(dirname(output_figure))

# ============================================================================
# LOAD STATISTICAL RESULTS
# ============================================================================

log_subsection("Loading statistical comparison results")

comparison_results <- tryCatch({
  result <- read_csv(input_table, show_col_types = FALSE)
  log_success(paste("Results loaded:", nrow(result), "SNVs"))
  result
}, error = function(e) {
  handle_error(e, context = "Step 2.3 - Data Loading", exit_code = 1, log_file = log_file)
})

# Detect group names from table columns
group_info <- detect_group_names_from_table(comparison_results)
group1_name <- group_info$group1
group2_name <- group_info$group2

log_info(paste("Detected groups:", group1_name, "vs", group2_name))

# Get dynamic column names
group1_mean_col <- paste0(group1_name, "_mean")
group1_sd_col <- paste0(group1_name, "_sd")
group1_n_col <- paste0(group1_name, "_n")
group2_mean_col <- paste0(group2_name, "_mean")
group2_sd_col <- paste0(group2_name, "_sd")
group2_n_col <- paste0(group2_name, "_n")

# Fallback to ALS/Control if dynamic columns not found
if (!group1_mean_col %in% names(comparison_results)) {
  group1_mean_col <- "ALS_mean"
  group1_sd_col <- "ALS_sd"
  group1_n_col <- "ALS_n"
  group2_mean_col <- "Control_mean"
  group2_sd_col <- "Control_sd"
  group2_n_col <- "Control_n"
}

# ============================================================================
# CALCULATE EFFECT SIZES
# ============================================================================

log_subsection("Calculating effect sizes")

# Cohen's d = (mean1 - mean2) / pooled_sd
# pooled_sd = sqrt(((n1-1)*sd1^2 + (n2-1)*sd2^2) / (n1+n2-2))
effect_size_data <- comparison_results %>%
  mutate(
    # Pooled standard deviation (using dynamic column names)
    pooled_sd = sqrt(((!!sym(group1_n_col) - 1) * (!!sym(group1_sd_col))^2 + 
                      (!!sym(group2_n_col) - 1) * (!!sym(group2_sd_col))^2) / 
                     (!!sym(group1_n_col) + !!sym(group2_n_col) - 2)),
    
    # Cohen's d
    cohens_d = ifelse(pooled_sd > 0,
                     ((!!sym(group1_mean_col)) - (!!sym(group2_mean_col))) / pooled_sd,
                     NA_real_),
    
    # Effect size interpretation
    effect_size_category = case_when(
      abs(cohens_d) >= 0.8 ~ "Large",
      abs(cohens_d) >= 0.5 ~ "Medium",
      abs(cohens_d) >= 0.2 ~ "Small",
      TRUE ~ "Negligible"
    ),
    
    # Confidence intervals for Cohen's d (approximate)
    # SE_cohens_d ≈ sqrt((n1 + n2) / (n1 * n2) + d^2 / (2 * (n1 + n2)))
    se_cohens_d = sqrt((!!sym(group1_n_col) + !!sym(group2_n_col)) / 
                       ((!!sym(group1_n_col)) * (!!sym(group2_n_col))) + 
                       cohens_d^2 / (2 * (!!sym(group1_n_col) + !!sym(group2_n_col)))),
    cohens_d_ci_lower = cohens_d - 1.96 * se_cohens_d,
    cohens_d_ci_upper = cohens_d + 1.96 * se_cohens_d
  )

# Summary statistics
effect_summary <- effect_size_data %>%
  filter(!is.na(cohens_d)) %>%
  summarise(
    mean_effect = mean(cohens_d, na.rm = TRUE),
    median_effect = median(cohens_d, na.rm = TRUE),
    n_large = sum(abs(cohens_d) >= 0.8),
    n_medium = sum(abs(cohens_d) >= 0.5 & abs(cohens_d) < 0.8),
    n_small = sum(abs(cohens_d) >= 0.2 & abs(cohens_d) < 0.5),
    n_negligible = sum(abs(cohens_d) < 0.2)
  )

log_info(paste("Mean Cohen's d:", round(effect_summary$mean_effect, 3)))
log_info(paste("Median Cohen's d:", round(effect_summary$median_effect, 3)))
log_info(paste("Large effect size (|d| >= 0.8):", effect_summary$n_large))
log_info(paste("Medium effect size (0.5 <= |d| < 0.8):", effect_summary$n_medium))
log_info(paste("Small effect size (0.2 <= |d| < 0.5):", effect_summary$n_small))

# ============================================================================
# EXPORT EFFECT SIZE TABLE
# ============================================================================

log_subsection("Exporting effect size table")

effect_size_export <- effect_size_data %>%
  select(miRNA_name, pos.mut, 
         all_of(c(group1_mean_col, group2_mean_col)),  # Dynamic names
         ALS_mean, Control_mean,  # Backward compatible
         log2_fold_change,
         cohens_d, effect_size_category, cohens_d_ci_lower, cohens_d_ci_upper,
         t_test_fdr, wilcoxon_fdr, significant)

write_csv(effect_size_export, output_table)
log_success(paste("Effect size table exported:", output_table))

# ============================================================================
# GENERATE EFFECT SIZE VISUALIZATION
# ============================================================================

log_subsection("Generating effect size visualization")

# Create histogram of effect sizes
effect_plot <- effect_size_data %>%
  filter(!is.na(cohens_d)) %>%
  ggplot(aes(x = cohens_d, fill = effect_size_category)) +
  geom_histogram(bins = 50, alpha = 0.8, color = "white", linewidth = 0.3) +
  
  # Reference lines
  geom_vline(xintercept = c(-0.8, -0.5, -0.2, 0, 0.2, 0.5, 0.8),
             linetype = "dashed", color = "grey60", linewidth = 0.3) +
  
  # Color scale
  scale_fill_manual(
    values = c(
      "Large" = "#D62728",
      "Medium" = "#FF7F0E",
      "Small" = "#FFBB78",
      "Negligible" = "grey80"
    ),
    name = "Effect Size"
  ) +
  
  # Labels (dynamic group names)
  labs(
    title = paste0("Effect Size Distribution: ", group1_name, " vs ", group2_name),
    subtitle = "Cohen's d for G>T mutations",
    x = "Cohen's d (Effect Size)",
    y = "Number of SNVs",
    caption = paste("Total SNVs:", nrow(effect_size_data), 
                   "| Large:", effect_summary$n_large,
                   "| Medium:", effect_summary$n_medium)
  ) +
  
  # Theme
  theme_professional +
  theme(
    legend.position = "right",
    plot.title = element_text(size = 14, face = "bold")
  )

# Save figure
config <- snakemake@config
fig_width <- if (!is.null(config$analysis$figure$width)) config$analysis$figure$width else 12
fig_height <- if (!is.null(config$analysis$figure$height)) config$analysis$figure$height else 8
fig_dpi <- if (!is.null(config$analysis$figure$dpi)) config$analysis$figure$dpi else 300

ggsave(
  output_figure,
  effect_plot,
  width = fig_width,
  height = fig_height,
  dpi = fig_dpi,
  bg = "white"
)

log_success(paste("Effect size figure saved:", output_figure))

log_success("Effect size analysis completed successfully")
log_info(paste("Execution completed at", get_timestamp()))
