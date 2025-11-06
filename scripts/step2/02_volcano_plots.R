#!/usr/bin/env Rscript
# ============================================================================
# STEP 2.2: Volcano Plots - Dynamic Group Comparison
# ============================================================================
# Purpose: Generate volcano plots showing significance vs fold change
# 
# Supports any group names (not hardcoded to ALS/Control)
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
  library(stringr)
})

# Load common functions
source(snakemake@params[["functions"]], local = TRUE)

# Initialize logging
log_file <- if (length(snakemake@log) > 0) snakemake@log[[1]] else {
  file.path(dirname(snakemake@output[[1]]), "volcano_plot.log")
}
initialize_logging(log_file, context = "Step 2.2 - Volcano Plots")

log_section("STEP 2.2: Volcano Plots - Dynamic Group Comparison")

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
output_figure <- snakemake@output[["figure"]]

# Get config parameters
config <- snakemake@config
alpha <- if (!is.null(config$analysis$alpha)) config$analysis$alpha else 0.05
log2fc_threshold <- if (!is.null(config$analysis$log2fc_threshold_step2)) config$analysis$log2fc_threshold_step2 else 0.58
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

# Detect group names from table columns
group_info <- detect_group_names_from_table(comparison_results)
group1_name <- group_info$group1
group2_name <- group_info$group2

log_info(paste("Detected groups:", group1_name, "vs", group2_name))

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
    
    # Significance categories (dynamic labels)
    significant = !is.na(pvalue) & pvalue < alpha,
    high_fc = !is.na(log2FC) & abs(log2FC) > log2fc_threshold,
    category = case_when(
      significant & high_fc & log2FC > 0 ~ paste0("Upregulated (", group1_name, " > ", group2_name, ")"),
      significant & high_fc & log2FC < 0 ~ paste0("Downregulated (", group1_name, " < ", group2_name, ")"),
      significant ~ "Significant (low FC)",
      high_fc ~ "High FC (not sig)",
      TRUE ~ "Not significant"
    ),
    
    # Labels for top significant points
    label = ifelse(significant & high_fc, 
                  paste(miRNA_name, pos.mut, sep = "|"),
                  NA_character_)
  )

# Generate dynamic category names
upregulated_label <- paste0("Upregulated (", group1_name, " > ", group2_name, ")")
downregulated_label <- paste0("Downregulated (", group1_name, " < ", group2_name, ")")

# Summary
n_significant <- sum(volcano_data$significant, na.rm = TRUE)
n_upregulated <- sum(volcano_data$category == upregulated_label, na.rm = TRUE)
n_downregulated <- sum(volcano_data$category == downregulated_label, na.rm = TRUE)

log_info(paste("Total significant SNVs (FDR <", alpha, "):", n_significant))
log_info(paste(upregulated_label, ":", n_upregulated))
log_info(paste(downregulated_label, ":", n_downregulated))

# ============================================================================
# GENERATE VOLCANO PLOT
# ============================================================================

log_subsection("Generating volcano plot")

# Color scheme (dynamic labels)
category_colors <- c(
  upregulated_label = color_gt,
  downregulated_label = "#2E86AB",  # Blue
  "Significant (low FC)" = "#F77F00",  # Orange
  "High FC (not sig)" = "grey70",
  "Not significant" = "grey90"
)
names(category_colors)[1] <- upregulated_label
names(category_colors)[2] <- downregulated_label

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
  
  # Labels (dynamic group names)
  labs(
    title = paste0("Volcano Plot: ", group1_name, " vs ", group2_name, " Comparison"),
    subtitle = paste("G>T mutations | FDR <", alpha, "| log2FC >", log2fc_threshold),
    x = paste0("Log2 Fold Change (", group1_name, " / ", group2_name, ")"),
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
