#!/usr/bin/env Rscript
# ============================================================================
# STEP 2.2: Volcano Plots - ALS vs Control
# ============================================================================
# Purpose: Generate volcano plots showing significance vs fold change
# 
# Snakemake parameters:
#   input: Statistical comparison results from Step 2.1
#   output: Volcano plot figure
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
  file.path(dirname(snakemake@output[[1]]), "volcano_plot.log")
}
initialize_logging(log_file, context = "Step 2.2 - Volcano Plots")

log_section("STEP 2.2: Volcano Plots - ALS vs Control")

# ============================================================================
# GET SNAKEMAKE PARAMETERS
# ============================================================================

input_table <- snakemake@input[["comparisons"]]
output_figure <- snakemake@output[["figure"]]

# Get config parameters
config <- snakemake@config
alpha <- if (!is.null(config$analysis$alpha)) config$analysis$alpha else 0.05
log2fc_threshold <- if (!is.null(config$analysis$log2fc_threshold_step2)) config$analysis$log2fc_threshold_step2 else 0.58  # 1.5x fold change (exploratory)
color_gt <- if (!is.null(config$analysis$colors$gt)) config$analysis$colors$gt else "#D62728"

log_info(paste("Input table:", input_table))
log_info(paste("Output figure:", output_figure))
log_info(paste("Significance threshold (FDR):", alpha))
log_info(paste("Fold change threshold (log2FC):", log2fc_threshold))

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
  handle_error(e, context = "Step 2.2 - Data Loading", exit_code = 1, log_file = log_file)
})

# ============================================================================
# PREPARE DATA FOR VOLCANO PLOT
# ============================================================================

log_subsection("Preparing volcano plot data")

# Use Wilcoxon FDR if available, otherwise t-test FDR
volcano_data <- comparison_results %>%
  mutate(
    # Select p-value (prefer Wilcoxon)
    pvalue = ifelse(!is.na(wilcoxon_fdr), wilcoxon_fdr, t_test_fdr),
    neg_log10_p = -log10(pvalue),
    
    # Fold change
    log2FC = log2_fold_change,
    
    # Significance categories
    significant = !is.na(pvalue) & pvalue < alpha,
    high_fc = !is.na(log2FC) & abs(log2FC) > log2fc_threshold,
    category = case_when(
      significant & high_fc & log2FC > 0 ~ "Upregulated (ALS > Control)",
      significant & high_fc & log2FC < 0 ~ "Downregulated (ALS < Control)",
      significant ~ "Significant (low FC)",
      high_fc ~ "High FC (not sig)",
      TRUE ~ "Not significant"
    ),
    
    # Labels for top significant points
    label = ifelse(significant & high_fc, 
                  paste(miRNA_name, pos.mut, sep = "|"),
                  NA_character_)
  )

# Summary
n_significant <- sum(volcano_data$significant, na.rm = TRUE)
n_upregulated <- sum(volcano_data$category == "Upregulated (ALS > Control)", na.rm = TRUE)
n_downregulated <- sum(volcano_data$category == "Downregulated (ALS < Control)", na.rm = TRUE)

log_info(paste("Total significant SNVs (FDR <", alpha, "):", n_significant))
log_info(paste("Upregulated (ALS > Control):", n_upregulated))
log_info(paste("Downregulated (ALS < Control):", n_downregulated))

# ============================================================================
# GENERATE VOLCANO PLOT
# ============================================================================

log_subsection("Generating volcano plot")

# Color scheme
category_colors <- c(
  "Upregulated (ALS > Control)" = color_gt,
  "Downregulated (ALS < Control)" = "#2E86AB",  # Blue
  "Significant (low FC)" = "#F77F00",  # Orange
  "High FC (not sig)" = "grey70",
  "Not significant" = "grey90"
)

volcano_plot <- ggplot(volcano_data, aes(x = log2FC, y = neg_log10_p)) +
  # Background grid
  geom_hline(yintercept = -log10(alpha), linetype = "dashed", color = "grey50", linewidth = 0.5) +
  geom_vline(xintercept = c(-log2fc_threshold, log2fc_threshold), 
             linetype = "dashed", color = "grey50", linewidth = 0.5) +
  
  # Points
  geom_point(aes(color = category, fill = category), 
             alpha = 0.7, size = 1.5, shape = 21) +
  
  # Color scale
  scale_color_manual(values = category_colors, name = "Category") +
  scale_fill_manual(values = category_colors, name = "Category") +
  
  # Labels
  labs(
    title = "Volcano Plot: ALS vs Control Comparison",
    subtitle = paste("G>T mutations | FDR <", alpha, "| log2FC >", log2fc_threshold),
    x = "Log2 Fold Change (ALS / Control)",
    y = "-Log10 FDR-adjusted p-value",
    caption = paste("Significant:", n_significant, "| Up:", n_upregulated, "| Down:", n_downregulated)
  ) +
  
  # Theme
  theme_professional +
  theme(
    legend.position = "right",
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 11, color = "grey50")
  )

# Save figure
ggsave(
  output_figure,
  volcano_plot,
  width = 12,
  height = 9,
  dpi = 300,
  bg = "white"
)

log_success(paste("Volcano plot saved:", output_figure))

log_success("Volcano plot generation completed successfully")
log_info(paste("Execution completed at", get_timestamp()))

# ============================================================================
# STEP 2.2: Volcano Plots - ALS vs Control
# ============================================================================
# Purpose: Generate volcano plots showing significance vs fold change
# 
# Snakemake parameters:
#   input: Statistical comparison results from Step 2.1
#   output: Volcano plot figure
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
  file.path(dirname(snakemake@output[[1]]), "volcano_plot.log")
}
initialize_logging(log_file, context = "Step 2.2 - Volcano Plots")

log_section("STEP 2.2: Volcano Plots - ALS vs Control")

# ============================================================================
# GET SNAKEMAKE PARAMETERS
# ============================================================================

input_table <- snakemake@input[["comparisons"]]
output_figure <- snakemake@output[["figure"]]

# Get config parameters
config <- snakemake@config
alpha <- if (!is.null(config$analysis$alpha)) config$analysis$alpha else 0.05
log2fc_threshold <- if (!is.null(config$analysis$log2fc_threshold_step2)) config$analysis$log2fc_threshold_step2 else 0.58  # 1.5x fold change (exploratory)
color_gt <- if (!is.null(config$analysis$colors$gt)) config$analysis$colors$gt else "#D62728"

log_info(paste("Input table:", input_table))
log_info(paste("Output figure:", output_figure))
log_info(paste("Significance threshold (FDR):", alpha))
log_info(paste("Fold change threshold (log2FC):", log2fc_threshold))

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
  handle_error(e, context = "Step 2.2 - Data Loading", exit_code = 1, log_file = log_file)
})

# ============================================================================
# PREPARE DATA FOR VOLCANO PLOT
# ============================================================================

log_subsection("Preparing volcano plot data")

# Use Wilcoxon FDR if available, otherwise t-test FDR
volcano_data <- comparison_results %>%
  mutate(
    # Select p-value (prefer Wilcoxon)
    pvalue = ifelse(!is.na(wilcoxon_fdr), wilcoxon_fdr, t_test_fdr),
    neg_log10_p = -log10(pvalue),
    
    # Fold change
    log2FC = log2_fold_change,
    
    # Significance categories
    significant = !is.na(pvalue) & pvalue < alpha,
    high_fc = !is.na(log2FC) & abs(log2FC) > log2fc_threshold,
    category = case_when(
      significant & high_fc & log2FC > 0 ~ "Upregulated (ALS > Control)",
      significant & high_fc & log2FC < 0 ~ "Downregulated (ALS < Control)",
      significant ~ "Significant (low FC)",
      high_fc ~ "High FC (not sig)",
      TRUE ~ "Not significant"
    ),
    
    # Labels for top significant points
    label = ifelse(significant & high_fc, 
                  paste(miRNA_name, pos.mut, sep = "|"),
                  NA_character_)
  )

# Summary
n_significant <- sum(volcano_data$significant, na.rm = TRUE)
n_upregulated <- sum(volcano_data$category == "Upregulated (ALS > Control)", na.rm = TRUE)
n_downregulated <- sum(volcano_data$category == "Downregulated (ALS < Control)", na.rm = TRUE)

log_info(paste("Total significant SNVs (FDR <", alpha, "):", n_significant))
log_info(paste("Upregulated (ALS > Control):", n_upregulated))
log_info(paste("Downregulated (ALS < Control):", n_downregulated))

# ============================================================================
# GENERATE VOLCANO PLOT
# ============================================================================

log_subsection("Generating volcano plot")

# Color scheme
category_colors <- c(
  "Upregulated (ALS > Control)" = color_gt,
  "Downregulated (ALS < Control)" = "#2E86AB",  # Blue
  "Significant (low FC)" = "#F77F00",  # Orange
  "High FC (not sig)" = "grey70",
  "Not significant" = "grey90"
)

volcano_plot <- ggplot(volcano_data, aes(x = log2FC, y = neg_log10_p)) +
  # Background grid
  geom_hline(yintercept = -log10(alpha), linetype = "dashed", color = "grey50", linewidth = 0.5) +
  geom_vline(xintercept = c(-log2fc_threshold, log2fc_threshold), 
             linetype = "dashed", color = "grey50", linewidth = 0.5) +
  
  # Points
  geom_point(aes(color = category, fill = category), 
             alpha = 0.7, size = 1.5, shape = 21) +
  
  # Color scale
  scale_color_manual(values = category_colors, name = "Category") +
  scale_fill_manual(values = category_colors, name = "Category") +
  
  # Labels
  labs(
    title = "Volcano Plot: ALS vs Control Comparison",
    subtitle = paste("G>T mutations | FDR <", alpha, "| log2FC >", log2fc_threshold),
    x = "Log2 Fold Change (ALS / Control)",
    y = "-Log10 FDR-adjusted p-value",
    caption = paste("Significant:", n_significant, "| Up:", n_upregulated, "| Down:", n_downregulated)
  ) +
  
  # Theme
  theme_professional +
  theme(
    legend.position = "right",
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 11, color = "grey50")
  )

# Save figure
ggsave(
  output_figure,
  volcano_plot,
  width = 12,
  height = 9,
  dpi = 300,
  bg = "white"
)

log_success(paste("Volcano plot saved:", output_figure))

log_success("Volcano plot generation completed successfully")
log_info(paste("Execution completed at", get_timestamp()))

# ============================================================================
# STEP 2.2: Volcano Plots - ALS vs Control
# ============================================================================
# Purpose: Generate volcano plots showing significance vs fold change
# 
# Snakemake parameters:
#   input: Statistical comparison results from Step 2.1
#   output: Volcano plot figure
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
  file.path(dirname(snakemake@output[[1]]), "volcano_plot.log")
}
initialize_logging(log_file, context = "Step 2.2 - Volcano Plots")

log_section("STEP 2.2: Volcano Plots - ALS vs Control")

# ============================================================================
# GET SNAKEMAKE PARAMETERS
# ============================================================================

input_table <- snakemake@input[["comparisons"]]
output_figure <- snakemake@output[["figure"]]

# Get config parameters
config <- snakemake@config
alpha <- if (!is.null(config$analysis$alpha)) config$analysis$alpha else 0.05
log2fc_threshold <- if (!is.null(config$analysis$log2fc_threshold_step2)) config$analysis$log2fc_threshold_step2 else 0.58  # 1.5x fold change (exploratory)
color_gt <- if (!is.null(config$analysis$colors$gt)) config$analysis$colors$gt else "#D62728"

log_info(paste("Input table:", input_table))
log_info(paste("Output figure:", output_figure))
log_info(paste("Significance threshold (FDR):", alpha))
log_info(paste("Fold change threshold (log2FC):", log2fc_threshold))

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
  handle_error(e, context = "Step 2.2 - Data Loading", exit_code = 1, log_file = log_file)
})

# ============================================================================
# PREPARE DATA FOR VOLCANO PLOT
# ============================================================================

log_subsection("Preparing volcano plot data")

# Use Wilcoxon FDR if available, otherwise t-test FDR
volcano_data <- comparison_results %>%
  mutate(
    # Select p-value (prefer Wilcoxon)
    pvalue = ifelse(!is.na(wilcoxon_fdr), wilcoxon_fdr, t_test_fdr),
    neg_log10_p = -log10(pvalue),
    
    # Fold change
    log2FC = log2_fold_change,
    
    # Significance categories
    significant = !is.na(pvalue) & pvalue < alpha,
    high_fc = !is.na(log2FC) & abs(log2FC) > log2fc_threshold,
    category = case_when(
      significant & high_fc & log2FC > 0 ~ "Upregulated (ALS > Control)",
      significant & high_fc & log2FC < 0 ~ "Downregulated (ALS < Control)",
      significant ~ "Significant (low FC)",
      high_fc ~ "High FC (not sig)",
      TRUE ~ "Not significant"
    ),
    
    # Labels for top significant points
    label = ifelse(significant & high_fc, 
                  paste(miRNA_name, pos.mut, sep = "|"),
                  NA_character_)
  )

# Summary
n_significant <- sum(volcano_data$significant, na.rm = TRUE)
n_upregulated <- sum(volcano_data$category == "Upregulated (ALS > Control)", na.rm = TRUE)
n_downregulated <- sum(volcano_data$category == "Downregulated (ALS < Control)", na.rm = TRUE)

log_info(paste("Total significant SNVs (FDR <", alpha, "):", n_significant))
log_info(paste("Upregulated (ALS > Control):", n_upregulated))
log_info(paste("Downregulated (ALS < Control):", n_downregulated))

# ============================================================================
# GENERATE VOLCANO PLOT
# ============================================================================

log_subsection("Generating volcano plot")

# Color scheme
category_colors <- c(
  "Upregulated (ALS > Control)" = color_gt,
  "Downregulated (ALS < Control)" = "#2E86AB",  # Blue
  "Significant (low FC)" = "#F77F00",  # Orange
  "High FC (not sig)" = "grey70",
  "Not significant" = "grey90"
)

volcano_plot <- ggplot(volcano_data, aes(x = log2FC, y = neg_log10_p)) +
  # Background grid
  geom_hline(yintercept = -log10(alpha), linetype = "dashed", color = "grey50", linewidth = 0.5) +
  geom_vline(xintercept = c(-log2fc_threshold, log2fc_threshold), 
             linetype = "dashed", color = "grey50", linewidth = 0.5) +
  
  # Points
  geom_point(aes(color = category, fill = category), 
             alpha = 0.7, size = 1.5, shape = 21) +
  
  # Color scale
  scale_color_manual(values = category_colors, name = "Category") +
  scale_fill_manual(values = category_colors, name = "Category") +
  
  # Labels
  labs(
    title = "Volcano Plot: ALS vs Control Comparison",
    subtitle = paste("G>T mutations | FDR <", alpha, "| log2FC >", log2fc_threshold),
    x = "Log2 Fold Change (ALS / Control)",
    y = "-Log10 FDR-adjusted p-value",
    caption = paste("Significant:", n_significant, "| Up:", n_upregulated, "| Down:", n_downregulated)
  ) +
  
  # Theme
  theme_professional +
  theme(
    legend.position = "right",
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 11, color = "grey50")
  )

# Save figure
ggsave(
  output_figure,
  volcano_plot,
  width = 12,
  height = 9,
  dpi = 300,
  bg = "white"
)

log_success(paste("Volcano plot saved:", output_figure))

log_success("Volcano plot generation completed successfully")
log_info(paste("Execution completed at", get_timestamp()))

