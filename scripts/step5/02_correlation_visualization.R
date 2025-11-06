#!/usr/bin/env Rscript
# ============================================================================
# STEP 5: Expression vs Oxidation Correlation Visualization
# ============================================================================
# Purpose: Generate comprehensive figures showing correlation between expression
#          and oxidation patterns. Part of Step 5 which runs after Step 2.
#
# This script generates 2 separate figures:
# 1. Panel A: Expression vs Oxidation Scatter Plot with correlation
# 2. Panel B: Oxidation by Expression Category Comparison (Boxplot/Barplot)
#
# Snakemake parameters:
#   input: Correlation and expression summary tables from Step 5.1
#   output: 2 separate figure files
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
  library(readr)
  library(stringr)
  library(scales)
  library(ggrepel)
})

# Load common functions and theme
source(snakemake@params[["functions"]], local = TRUE)
# Theme is loaded via functions_common.R

# Initialize logging
log_file <- if (length(snakemake@log) > 0) snakemake@log[[1]] else {
  file.path(dirname(snakemake@output[[1]]), "correlation_visualization.log")
}
initialize_logging(log_file, context = "Step 5.2 - Correlation Visualization")

log_section("STEP 5: Expression vs Oxidation Correlation Visualization")

# ============================================================================
# GET SNAKEMAKE PARAMETERS
# ============================================================================

input_correlation <- snakemake@input[["correlation_table"]]
input_expression_summary <- snakemake@input[["expression_summary"]]

output_figure_a <- snakemake@output[["figure_a"]]
output_figure_b <- snakemake@output[["figure_b"]]

config <- snakemake@config
seed_start <- if (!is.null(config$analysis$seed_region$start)) config$analysis$seed_region$start else 2
seed_end <- if (!is.null(config$analysis$seed_region$end)) config$analysis$seed_region$end else 8
color_gt <- if (!is.null(config$analysis$colors$gt)) config$analysis$colors$gt else "#D62728"

fig_width <- if (!is.null(config$analysis$figure$width)) config$analysis$figure$width else 12
fig_height <- if (!is.null(config$analysis$figure$height)) config$analysis$figure$height else 10
fig_dpi <- if (!is.null(config$analysis$figure$dpi)) config$analysis$figure$dpi else 300

log_info(paste("Output figures:", output_figure_a, output_figure_b))
ensure_output_dir(dirname(output_figure_a))

# ============================================================================
# LOAD DATA
# ============================================================================

log_subsection("Loading correlation data")

# Validate file existence before reading
if (!file.exists(input_correlation)) {
  handle_error(
    paste("Correlation table file not found:", input_correlation),
    context = "Step 5.2 - Data Loading",
    exit_code = 1,
    log_file = log_file
  )
}
if (!file.exists(input_expression_summary)) {
  handle_error(
    paste("Expression summary file not found:", input_expression_summary),
    context = "Step 5.2 - Data Loading",
    exit_code = 1,
    log_file = log_file
  )
}

correlation_data <- tryCatch({
  result <- read_csv(input_correlation, show_col_types = FALSE)
  log_success(paste("Loaded correlation data:", nrow(result), "miRNAs"))
  result
}, error = function(e) {
  handle_error(e, context = "Step 5.2 - Loading correlation data", exit_code = 1, log_file = log_file)
})

expression_summary <- tryCatch({
  result <- read_csv(input_expression_summary, show_col_types = FALSE)
  log_success(paste("Loaded expression summary:", nrow(result), "categories"))
  result
}, error = function(e) {
  handle_error(e, context = "Step 5.2 - Loading expression summary", exit_code = 1, log_file = log_file)
})

# Calculate correlation for annotation
# Check if we have enough data for correlation (need at least 2 observations)
if (nrow(correlation_data) < 2 || sum(!is.na(correlation_data$estimated_rpm) & !is.na(correlation_data$total_gt_counts)) < 2) {
  log_warning(paste("Insufficient data for correlation analysis (n =", nrow(correlation_data), "). Need at least 2 observations."))
  cor_pearson <- NA_real_
  p_value <- NA_real_
} else {
  correlation_result <- tryCatch({
    cor.test(correlation_data$estimated_rpm, correlation_data$total_gt_counts, method = "pearson")
  }, error = function(e) {
    log_warning(paste("Correlation test failed:", e$message))
    NULL
  })
  
  if (is.null(correlation_result)) {
    cor_pearson <- NA_real_
    p_value <- NA_real_
  } else {
    cor_pearson <- round(correlation_result$estimate, 4)
    p_value <- correlation_result$p.value
  }
}

# ============================================================================
# PANEL A: Expression vs Oxidation Scatter Plot
# ============================================================================

log_subsection("Creating Panel A: Expression vs Oxidation Scatter (separate figure)")

# Get top miRNAs for labeling
top_oxidation <- correlation_data %>%
  arrange(desc(total_gt_counts)) %>%
  head(10)

top_expression <- correlation_data %>%
  arrange(desc(estimated_rpm)) %>%
  head(5)

# Create expression categories for coloring
correlation_data <- correlation_data %>%
  mutate(
    expression_category = case_when(
      estimated_rpm >= quantile(estimated_rpm, 0.8, na.rm = TRUE) ~ "High",
      estimated_rpm >= quantile(estimated_rpm, 0.6, na.rm = TRUE) ~ "Medium-High",
      estimated_rpm >= quantile(estimated_rpm, 0.4, na.rm = TRUE) ~ "Medium",
      estimated_rpm >= quantile(estimated_rpm, 0.2, na.rm = TRUE) ~ "Low-Medium",
      TRUE ~ "Low"
    )
  )

# Get statistics for caption
n_miRNAs <- nrow(correlation_data)
rpm_range <- paste(round(min(correlation_data$estimated_rpm, na.rm = TRUE), 1), 
                   "-", round(max(correlation_data$estimated_rpm, na.rm = TRUE), 1))
oxidation_range <- paste(round(min(correlation_data$total_gt_counts, na.rm = TRUE), 0),
                         "-", round(max(correlation_data$total_gt_counts, na.rm = TRUE), 0))

# Check if we have enough data to plot
if (nrow(correlation_data) < 2 || all(is.na(correlation_data$estimated_rpm)) || all(is.na(correlation_data$total_gt_counts))) {
  log_warning("Insufficient data for scatter plot. Creating empty plot with message.")
  panel_a <- ggplot() + 
    annotate("text", x = 0.5, y = 0.5, 
             label = paste("Insufficient data for correlation\n(n =", nrow(correlation_data), "miRNAs)"), 
             size = 5) +
    theme_void() +
    labs(title = "miRNA Expression vs Oxidative Damage")
} else {
  panel_a <- ggplot(correlation_data, aes(x = estimated_rpm, y = total_gt_counts)) +
    geom_point(aes(color = expression_category), alpha = 0.6, size = 2) +
    {if (!is.na(cor_pearson) && !is.na(p_value)) {
      geom_smooth(method = "lm", se = TRUE, color = color_gt, linewidth = 1.2, alpha = 0.3)
    }} +
    scale_x_log10(labels = scales::trans_format("log10", scales::math_format(10^.x))) +
    scale_y_log10(labels = scales::trans_format("log10", scales::math_format(10^.x))) +
    scale_color_brewer(palette = "RdYlBu", direction = -1, name = "Expression\nCategory") +
    labs(
      title = "miRNA Expression vs Oxidative Damage",
      subtitle = if (!is.na(cor_pearson) && !is.na(p_value)) {
        paste("Correlation between RPM and SIGNIFICANT G>T mutations in seed region (", seed_start, "-", seed_end, ") |",
              "Pearson r =", cor_pearson, ", p =", format(p_value, scientific = TRUE, digits = 2))
      } else {
        paste("Insufficient data for correlation (n =", nrow(correlation_data), ")")
      },
      x = "Expression Level (RPM, log10 scale)",
      y = "G>T Oxidation Counts (log10 scale)",
      caption = paste("n =", n_miRNAs, "miRNAs | RPM range:", rpm_range, "| Oxidation range:", oxidation_range)
    ) +
    theme_professional +
    theme(
      legend.position = "right",
      plot.title = element_text(size = 12, face = "bold", hjust = 0),
      plot.subtitle = element_text(size = 9, color = "grey50", hjust = 0)
    )
}

# Add labels for top miRNAs (only if we have a real plot with data)
if (nrow(top_oxidation) > 0 && nrow(correlation_data) >= 2 && !all(is.na(correlation_data$estimated_rpm)) && !all(is.na(correlation_data$total_gt_counts))) {
  panel_a <- panel_a +
    geom_text_repel(
      data = top_oxidation %>% head(5),
      aes(x = estimated_rpm, y = total_gt_counts, label = miRNA_name),
      size = 3,
      max.overlaps = 10,
      box.padding = 0.5,
      segment.color = "grey50"
    )
}

ggsave(output_figure_a, panel_a,
       width = fig_width, height = fig_height, dpi = fig_dpi,
       bg = "white")
log_success(paste("Panel A saved:", output_figure_a))

# ============================================================================
# PANEL B: Expression Groups Comparison
# ============================================================================

log_subsection("Creating Panel B: Expression Groups Comparison (separate figure)")

# Prepare data for grouped comparison (only if we have enough data)
if (nrow(correlation_data) < 2 || all(is.na(correlation_data$estimated_rpm)) || all(is.na(correlation_data$total_gt_counts))) {
  log_warning("Insufficient data for Panel B. Creating empty plot with message.")
  panel_b <- ggplot() + 
    annotate("text", x = 0.5, y = 0.5, 
             label = paste("Insufficient data for expression groups comparison\n(n =", nrow(correlation_data), "miRNAs)"), 
             size = 5) +
    theme_void() +
    labs(title = "Oxidation by Expression Category")
} else {
  expression_comparison <- correlation_data %>%
    mutate(
      expression_category = case_when(
        estimated_rpm >= quantile(estimated_rpm, 0.8, na.rm = TRUE) ~ "High (top 20%)",
        estimated_rpm >= quantile(estimated_rpm, 0.6, na.rm = TRUE) ~ "Medium-High (60-80%)",
        estimated_rpm >= quantile(estimated_rpm, 0.4, na.rm = TRUE) ~ "Medium (40-60%)",
        estimated_rpm >= quantile(estimated_rpm, 0.2, na.rm = TRUE) ~ "Low-Medium (20-40%)",
        TRUE ~ "Low (bottom 20%)"
      ),
      expression_category = factor(expression_category,
                                  levels = c("High (top 20%)", "Medium-High (60-80%)",
                                            "Medium (40-60%)", "Low-Medium (20-40%)",
                                            "Low (bottom 20%)"))
    )

# Get statistics for caption
high_oxidation <- expression_comparison %>% 
  filter(expression_category == "High (top 20%)") %>% 
  summarise(mean_ox = mean(total_gt_counts, na.rm = TRUE)) %>% pull(mean_ox)
low_oxidation <- expression_comparison %>% 
  filter(expression_category == "Low (bottom 20%)") %>% 
  summarise(mean_ox = mean(total_gt_counts, na.rm = TRUE)) %>% pull(mean_ox)
fold_diff <- round(high_oxidation / low_oxidation, 2)

panel_b <- ggplot(expression_comparison, aes(x = expression_category, y = total_gt_counts, fill = expression_category)) +
  geom_boxplot(alpha = 0.7, width = 0.6, outlier.size = 1) +
  geom_jitter(width = 0.2, alpha = 0.3, size = 0.8) +
  scale_y_log10(labels = scales::trans_format("log10", scales::math_format(10^.x))) +
  scale_fill_brewer(palette = "RdYlBu", direction = -1, guide = "none") +
  labs(
    title = "Oxidative Damage by Expression Category",
    subtitle = paste("SIGNIFICANT G>T mutations in seed region (", seed_start, "-", seed_end, ") grouped by expression level |",
                     "High expression miRNAs show", fold_diff, "x more oxidation than low expression"),
    x = "Expression Category",
    y = "G>T Oxidation Counts (log10 scale)",
    caption = paste("High (top 20%):", sum(expression_comparison$expression_category == "High (top 20%)"), "miRNAs |",
                   "Low (bottom 20%):", sum(expression_comparison$expression_category == "Low (bottom 20%)"), "miRNAs")
  ) +
    theme_professional +
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1),
      plot.title = element_text(size = 12, face = "bold", hjust = 0),
      plot.subtitle = element_text(size = 9, color = "grey50", hjust = 0)
    )
}

ggsave(output_figure_b, panel_b,
       width = fig_width, height = fig_height, dpi = fig_dpi,
       bg = "white")
log_success(paste("Panel B saved:", output_figure_b))

log_success("Step 5.2 completed successfully - All 2 figures generated separately")

