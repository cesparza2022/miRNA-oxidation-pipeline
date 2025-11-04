#!/usr/bin/env Rscript
# ============================================================================
# STEP 2.3: Effect Size Analysis - ALS vs Control
# ============================================================================
# Purpose: Calculate and visualize effect sizes (Cohen's d, etc.)
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
})

# Load common functions
source(snakemake@params[["functions"]], local = TRUE)

# Initialize logging
log_file <- if (length(snakemake@log) > 0) snakemake@log[[1]] else {
  file.path(dirname(snakemake@output[[1]]), "effect_size.log")
}
initialize_logging(log_file, context = "Step 2.3 - Effect Size Analysis")

log_section("STEP 2.3: Effect Size Analysis - ALS vs Control")

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

# ============================================================================
# CALCULATE EFFECT SIZES
# ============================================================================

log_subsection("Calculating effect sizes")

# Cohen's d = (mean1 - mean2) / pooled_sd
# pooled_sd = sqrt(((n1-1)*sd1^2 + (n2-1)*sd2^2) / (n1+n2-2))
effect_size_data <- comparison_results %>%
  mutate(
    # Pooled standard deviation
    pooled_sd = sqrt(((ALS_n - 1) * ALS_sd^2 + (Control_n - 1) * Control_sd^2) / 
                     (ALS_n + Control_n - 2)),
    
    # Cohen's d
    cohens_d = ifelse(pooled_sd > 0,
                     (ALS_mean - Control_mean) / pooled_sd,
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
    se_cohens_d = sqrt((ALS_n + Control_n) / (ALS_n * Control_n) + 
                       cohens_d^2 / (2 * (ALS_n + Control_n))),
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
  select(miRNA_name, pos.mut, ALS_mean, Control_mean, log2_fold_change,
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
  
  # Labels
  labs(
    title = "Effect Size Distribution: ALS vs Control",
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
ggsave(
  output_figure,
  effect_plot,
  width = 12,
  height = 8,
  dpi = 300,
  bg = "white"
)

log_success(paste("Effect size figure saved:", output_figure))

log_success("Effect size analysis completed successfully")
log_info(paste("Execution completed at", get_timestamp()))

# ============================================================================
# STEP 2.3: Effect Size Analysis - ALS vs Control
# ============================================================================
# Purpose: Calculate and visualize effect sizes (Cohen's d, etc.)
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
})

# Load common functions
source(snakemake@params[["functions"]], local = TRUE)

# Initialize logging
log_file <- if (length(snakemake@log) > 0) snakemake@log[[1]] else {
  file.path(dirname(snakemake@output[[1]]), "effect_size.log")
}
initialize_logging(log_file, context = "Step 2.3 - Effect Size Analysis")

log_section("STEP 2.3: Effect Size Analysis - ALS vs Control")

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

# ============================================================================
# CALCULATE EFFECT SIZES
# ============================================================================

log_subsection("Calculating effect sizes")

# Cohen's d = (mean1 - mean2) / pooled_sd
# pooled_sd = sqrt(((n1-1)*sd1^2 + (n2-1)*sd2^2) / (n1+n2-2))
effect_size_data <- comparison_results %>%
  mutate(
    # Pooled standard deviation
    pooled_sd = sqrt(((ALS_n - 1) * ALS_sd^2 + (Control_n - 1) * Control_sd^2) / 
                     (ALS_n + Control_n - 2)),
    
    # Cohen's d
    cohens_d = ifelse(pooled_sd > 0,
                     (ALS_mean - Control_mean) / pooled_sd,
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
    se_cohens_d = sqrt((ALS_n + Control_n) / (ALS_n * Control_n) + 
                       cohens_d^2 / (2 * (ALS_n + Control_n))),
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
  select(miRNA_name, pos.mut, ALS_mean, Control_mean, log2_fold_change,
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
  
  # Labels
  labs(
    title = "Effect Size Distribution: ALS vs Control",
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
ggsave(
  output_figure,
  effect_plot,
  width = 12,
  height = 8,
  dpi = 300,
  bg = "white"
)

log_success(paste("Effect size figure saved:", output_figure))

log_success("Effect size analysis completed successfully")
log_info(paste("Execution completed at", get_timestamp()))

# ============================================================================
# STEP 2.3: Effect Size Analysis - ALS vs Control
# ============================================================================
# Purpose: Calculate and visualize effect sizes (Cohen's d, etc.)
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
})

# Load common functions
source(snakemake@params[["functions"]], local = TRUE)

# Initialize logging
log_file <- if (length(snakemake@log) > 0) snakemake@log[[1]] else {
  file.path(dirname(snakemake@output[[1]]), "effect_size.log")
}
initialize_logging(log_file, context = "Step 2.3 - Effect Size Analysis")

log_section("STEP 2.3: Effect Size Analysis - ALS vs Control")

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

# ============================================================================
# CALCULATE EFFECT SIZES
# ============================================================================

log_subsection("Calculating effect sizes")

# Cohen's d = (mean1 - mean2) / pooled_sd
# pooled_sd = sqrt(((n1-1)*sd1^2 + (n2-1)*sd2^2) / (n1+n2-2))
effect_size_data <- comparison_results %>%
  mutate(
    # Pooled standard deviation
    pooled_sd = sqrt(((ALS_n - 1) * ALS_sd^2 + (Control_n - 1) * Control_sd^2) / 
                     (ALS_n + Control_n - 2)),
    
    # Cohen's d
    cohens_d = ifelse(pooled_sd > 0,
                     (ALS_mean - Control_mean) / pooled_sd,
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
    se_cohens_d = sqrt((ALS_n + Control_n) / (ALS_n * Control_n) + 
                       cohens_d^2 / (2 * (ALS_n + Control_n))),
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
  select(miRNA_name, pos.mut, ALS_mean, Control_mean, log2_fold_change,
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
  
  # Labels
  labs(
    title = "Effect Size Distribution: ALS vs Control",
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
ggsave(
  output_figure,
  effect_plot,
  width = 12,
  height = 8,
  dpi = 300,
  bg = "white"
)

log_success(paste("Effect size figure saved:", output_figure))

log_success("Effect size analysis completed successfully")
log_info(paste("Execution completed at", get_timestamp()))

