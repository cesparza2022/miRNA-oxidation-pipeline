#!/usr/bin/env Rscript
# ============================================================================
# STEP 4.1: Biomarker ROC Analysis
# ============================================================================
# Purpose: Evaluate diagnostic potential of miRNA oxidation patterns
# 
# This script performs:
# 1. ROC curve analysis for individual miRNAs
# 2. AUC calculation and ranking
# 3. Multi-miRNA signature identification
# 4. Combined ROC analysis
#
# Snakemake parameters:
#   input: Statistical comparison results and VAF-filtered data
#   output: ROC analysis tables and figures
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
  library(readr)
  library(pROC)
  library(patchwork)
  library(scales)
})

# Load common functions FIRST (needed for initialize_logging)
source(snakemake@params[["functions"]], local = TRUE)
# Theme is loaded via functions_common.R

# Initialize logging (now that functions_common.R is loaded)
log_file <- if (length(snakemake@log) > 0) snakemake@log[[1]] else {
  file.path(dirname(snakemake@output[[1]]), "biomarker_roc_analysis.log")
}
initialize_logging(log_file, context = "Step 4.1 - Biomarker ROC Analysis")

# Load data loading helpers (use path relative to project root)
data_helpers_path <- "scripts/utils/data_loading_helpers.R"
if (file.exists(data_helpers_path)) {
  source(data_helpers_path, local = TRUE)
  log_info(paste("Data loading helpers loaded from:", data_helpers_path))
  log_info(paste("Function exists:", exists("identify_snv_count_columns")))
} else {
  warning("data_loading_helpers.R not found, using fallback column detection")
  log_warning("data_loading_helpers.R not found, using fallback column detection")
}

# Load group comparison utilities for dynamic group detection
group_functions_path <- if (!is.null(snakemake@params[["group_functions"]])) {
  snakemake@params[["group_functions"]]
} else {
  "scripts/utils/group_comparison.R"
}

if (file.exists(group_functions_path)) {
  source(group_functions_path, local = TRUE)
}

log_section("STEP 4.1: Biomarker ROC Analysis")

# ============================================================================
# GET SNAKEMAKE PARAMETERS
# ============================================================================

input_statistical <- snakemake@input[["statistical_results"]]
input_vaf_filtered <- snakemake@input[["vaf_filtered"]]
output_roc_table <- snakemake@output[["roc_table"]]
output_signatures <- snakemake@output[["signatures"]]
output_roc_figure <- snakemake@output[["roc_figure"]]

config <- snakemake@config
alpha <- if (!is.null(config$analysis$alpha)) config$analysis$alpha else 0.05
log2fc_threshold <- if (!is.null(config$analysis$log2fc_threshold_step3)) config$analysis$log2fc_threshold_step3 else 1.0
seed_start <- if (!is.null(config$analysis$seed_region$start)) config$analysis$seed_region$start else 2
seed_end <- if (!is.null(config$analysis$seed_region$end)) config$analysis$seed_region$end else 8
# Use standardized colors from colors.R (loaded via functions_common.R)
# Allow override from config if specified, otherwise use COLOR_GT, COLOR_CONTROL
color_gt <- if (!is.null(config$analysis$colors$gt)) config$analysis$colors$gt else COLOR_GT
color_control <- if (!is.null(config$analysis$colors$control)) config$analysis$colors$control else COLOR_CONTROL
fig_width <- if (!is.null(config$analysis$figure$width)) config$analysis$figure$width else 12
fig_height <- if (!is.null(config$analysis$figure$height)) config$analysis$figure$height else 10
fig_dpi <- if (!is.null(config$analysis$figure$dpi)) config$analysis$figure$dpi else 300

log_info(paste("Significance threshold (FDR):", alpha))
log_info(paste("Log2FC threshold (minimum):", log2fc_threshold))
log_info(paste("Seed region: positions", seed_start, "-", seed_end))

log_info(paste("Input statistical:", input_statistical))
log_info(paste("Input VAF filtered:", input_vaf_filtered))
ensure_output_dir(dirname(output_roc_table))

# ============================================================================
# LOAD DATA
# ============================================================================

log_subsection("Loading data")

statistical_results <- tryCatch({
  result <- readr::read_csv(input_statistical, show_col_types = FALSE)
  
  # Validate data is not empty
  if (nrow(result) == 0) {
    stop("Statistical results table is empty (0 rows)")
  }
  if (ncol(result) == 0) {
    stop("Statistical results table has no columns")
  }
  
  result
}, error = function(e) {
  handle_error(e, context = "Step 7.1 - Loading statistical results", exit_code = 1, log_file = log_file)
})

vaf_data <- tryCatch({
  result <- readr::read_csv(input_vaf_filtered, show_col_types = FALSE)
  
  # Validate data is not empty
  if (nrow(result) == 0) {
    stop("VAF filtered data is empty (0 rows)")
  }
  if (ncol(result) == 0) {
    stop("VAF filtered data has no columns")
  }
  
  result
}, error = function(e) {
  handle_error(e, context = "Step 7.1 - Loading VAF data", exit_code = 1, log_file = log_file)
})

# Normalize column names (handle different formats)
if ("miRNA name" %in% names(vaf_data)) {
  vaf_data <- vaf_data %>% rename(miRNA_name = `miRNA name`)
}
if ("pos:mut" %in% names(vaf_data)) {
  vaf_data <- vaf_data %>% rename(pos.mut = `pos:mut`)
}

# CRITICAL: Use only SNV count columns (exclude total count columns)
# Step 1.5 outputs 830 columns (415 SNV + 415 totals), but we only need SNV columns
log_info(paste("Checking for identify_snv_count_columns function. Exists:", exists("identify_snv_count_columns")))
log_info(paste("Initial vaf_data columns:", ncol(vaf_data)))

if (exists("identify_snv_count_columns")) {
  snv_cols <- identify_snv_count_columns(vaf_data)
  log_info(paste("Identified", length(snv_cols), "SNV count columns"))
  metadata_cols <- c("miRNA_name", "pos.mut")
  metadata_cols <- intersect(metadata_cols, names(vaf_data))
  # Use column indices to avoid variable name limit
  keep_cols <- c(metadata_cols, snv_cols)
  keep_indices <- which(names(vaf_data) %in% keep_cols)
  vaf_data <- as.data.frame(vaf_data[, keep_indices, drop = FALSE])
  log_info(paste("Filtered to", length(snv_cols), "SNV count columns (excluded total count columns)"))
  log_info(paste("Final vaf_data columns:", ncol(vaf_data)))
} else {
  log_warning("identify_snv_count_columns function not found, using fallback")
  # Fallback: try to exclude total columns manually
  total_pattern <- "\\(PM\\+1MM\\+2MM\\)$"
  all_cols <- names(vaf_data)
  metadata_cols <- c("miRNA_name", "miRNA name", "pos.mut", "pos:mut")
  metadata_cols <- intersect(metadata_cols, names(vaf_data))
  sample_cols <- setdiff(all_cols, metadata_cols)
  total_cols <- sample_cols[grepl(total_pattern, sample_cols)]
  if (length(total_cols) > 0) {
    # Use column indices to avoid variable name limit
    total_indices <- which(names(vaf_data) %in% total_cols)
    vaf_data <- vaf_data[, -total_indices, drop = FALSE]
    log_info(paste("Fallback: Excluded", length(total_cols), "total count columns"))
  }
}

# Extract sample groups (now using only SNV columns)
sample_cols <- setdiff(names(vaf_data), c("miRNA_name", "pos.mut", "miRNA name", "pos:mut"))

# Get metadata file path from Snakemake params if available
metadata_file <- if (!is.null(snakemake@params[["metadata_file"]])) {
  metadata_path <- snakemake@params[["metadata_file"]]
  if (metadata_path != "" && file.exists(metadata_path)) {
    log_info(paste("Using metadata file:", metadata_path))
    metadata_path
  } else {
    NULL
  }
} else {
  NULL
}

# Use flexible group extraction
sample_groups <- tryCatch({
  extract_sample_groups(vaf_data, metadata_file = metadata_file)
}, error = function(e) {
  handle_error(e, context = "Step 4.1 - Group Identification", exit_code = 1, log_file = log_file)
})

# Get dynamic group names
unique_groups <- sort(unique(sample_groups$group))
if (length(unique_groups) < 2) {
  stop("Need at least 2 groups for ROC analysis. Found:", paste(unique_groups, collapse = ", "))
}

group1_name <- unique_groups[1]  # Typically "Disease" or "ALS"
group2_name <- unique_groups[2]  # Typically "Control"

group1_samples <- sample_groups %>% filter(group == group1_name) %>% pull(sample_id)
group2_samples <- sample_groups %>% filter(group == group2_name) %>% pull(sample_id)

log_info(paste("Group 1 (", group1_name, ") samples:", length(group1_samples)))
log_info(paste("Group 2 (", group2_name, ") samples:", length(group2_samples)))

# For backward compatibility, also create als_samples and control_samples if they match
if (group1_name == "ALS" || str_detect(group1_name, regex("als|disease", ignore_case = TRUE))) {
  als_samples <- group1_samples
  control_samples <- group2_samples
} else if (group2_name == "ALS" || str_detect(group2_name, regex("als|disease", ignore_case = TRUE))) {
  als_samples <- group2_samples
  control_samples <- group1_samples
} else {
  # Use first group as "disease-like" and second as "control-like" for ROC
  als_samples <- group1_samples  # Disease-like
  control_samples <- group2_samples  # Control-like
}

# ============================================================================
# PREPARE DATA FOR ROC ANALYSIS
# ============================================================================

log_subsection("Preparing data for ROC analysis")

# Filter significant G>T mutations in seed region (same criteria as Step 3)
significant_gt <- statistical_results %>%
  filter(
    stringr::str_detect(pos.mut, ":GT$"),
    !is.na(t_test_fdr) | !is.na(wilcoxon_fdr),
    (t_test_fdr < alpha | wilcoxon_fdr < alpha),
    !is.na(log2_fold_change),
    log2_fold_change > log2fc_threshold  # Higher in ALS (configurable threshold)
  ) %>%
  mutate(
    position = as.numeric(stringr::str_extract(pos.mut, "^\\d+")),
    in_seed = position >= seed_start & position <= seed_end
  ) %>%
  filter(in_seed == TRUE) %>%
  distinct(miRNA_name, pos.mut, .keep_all = TRUE) %>%
  arrange(desc(log2_fold_change)) %>%
  head(50)  # Top 50 for ROC analysis

log_info(paste("Significant G>T mutations for ROC analysis:", nrow(significant_gt)))

# Check if data is empty
if (nrow(significant_gt) == 0) {
  log_warning("No significant G>T mutations found. Creating empty output files.")
  
  # Create empty output files
  empty_roc <- tibble(
    SNV_id = character(),
    miRNA_name = character(),
    pos.mut = character(),
    auc = numeric(),
    ci_lower = numeric(),
    ci_upper = numeric(),
    p_value = numeric(),
    sensitivity = numeric(),
    specificity = numeric()
  )
  
  empty_signatures <- tibble(
    signature_name = character(),
    n_miRNAs = integer(),
    auc = numeric(),
    ci_lower = numeric(),
    ci_upper = numeric(),
    p_value = numeric()
  )
  
  write_csv(empty_roc, output_roc_table)
  write_csv(empty_signatures, output_signatures)
  
  # Create empty placeholder figure
  p_empty <- ggplot() +
    annotate("text", x = 0.5, y = 0.5, label = "No significant G>T mutations\nfound for ROC analysis", 
             size = 6, hjust = 0.5, vjust = 0.5) +
    theme_void() +
    theme(plot.margin = margin(20, 20, 20, 20))
  
  ggsave(output_roc_figure, p_empty, width = fig_width, height = fig_height, dpi = fig_dpi, bg = "white")
  
  log_success("Step 7.1 completed (empty outputs created).")
  quit(save = "no", status = 0)
}

# ============================================================================
# ROC ANALYSIS FOR INDIVIDUAL miRNAs
# ============================================================================

log_subsection("Performing ROC analysis for individual miRNAs")

roc_results <- list()

# Validate we have significant G>T mutations
if (nrow(significant_gt) == 0) {
  stop("No significant G>T mutations found for ROC analysis. Check statistical results and filtering criteria.")
}

for (i in seq_len(min(nrow(significant_gt), 30))) {  # Top 30 for computational efficiency
  snv_id <- significant_gt$SNV_id[i]
  mirna <- significant_gt$miRNA_name[i]
  pos_mut <- significant_gt$pos.mut[i]
  
  # Get data for this SNV (match by miRNA_name and pos.mut)
  # Use column indices instead of select() to avoid variable name limit
  snv_row <- vaf_data %>%
    filter(miRNA_name == mirna & pos.mut == pos_mut)
  
  if (nrow(snv_row) == 0) next
  
  sample_col_indices <- which(names(snv_row) %in% sample_cols)
  snv_data <- as.data.frame(snv_row[, sample_col_indices, drop = FALSE])
  
  if (nrow(snv_data) == 0) next
  
  # Prepare ROC data
  roc_data <- tibble(
    sample_id = sample_cols,
    value = as.numeric(snv_data[1, sample_cols])
  ) %>%
    left_join(sample_groups, by = "sample_id") %>%
    filter(!is.na(group), !is.na(value))
  
  if (nrow(roc_data) < 10) next  # Need minimum samples
  
  # Calculate ROC (use dynamic group names)
  # For ROC: response should be disease (positive) vs control (negative)
  # Ensure group2_name is control-like and group1_name is disease-like
  roc_data$group_factor <- factor(roc_data$group, levels = c(group2_name, group1_name))
  
  tryCatch({
    roc_obj <- roc(response = roc_data$group_factor, 
                  predictor = roc_data$value,
                  levels = c(group2_name, group1_name),  # Control-like first, then Disease-like
                  direction = "<")
    
    auc_value <- as.numeric(auc(roc_obj))
    
    roc_results[[i]] <- tibble(
      SNV_id = snv_id,
      miRNA_name = mirna,
      pos.mut = pos_mut,
      AUC = auc_value,
      n_samples = nrow(roc_data),
      n_group1 = sum(roc_data$group == group1_name),
      n_group2 = sum(roc_data$group == group2_name),
      # Backward compatibility columns
      n_ALS = if (group1_name == "ALS" || stringr::str_detect(group1_name, stringr::regex("als|disease", ignore_case = TRUE))) {
        sum(roc_data$group == group1_name)
      } else {
        sum(roc_data$group == group2_name)
      },
      n_Control = if (group2_name == "Control" || stringr::str_detect(group2_name, stringr::regex("control|ctrl", ignore_case = TRUE))) {
        sum(roc_data$group == group2_name)
      } else {
        sum(roc_data$group == group1_name)
      }
    )
  }, error = function(e) {
    log_warning(paste("ROC failed for", snv_id, ":", e$message))
  })
}

roc_table <- bind_rows(roc_results) %>%
  arrange(desc(AUC)) %>%
  mutate(
    Biomarker_Quality = case_when(
      AUC >= 0.9 ~ "Excellent",
      AUC >= 0.8 ~ "Good",
      AUC >= 0.7 ~ "Fair",
      TRUE ~ "Poor"
    )
  )

write_csv(roc_table, output_roc_table)
log_success(paste("ROC table saved:", output_roc_table))
log_info(paste("Top AUC:", round(max(roc_table$AUC, na.rm = TRUE), 3)))

# ============================================================================
# MULTI-MIRNA SIGNATURE
# ============================================================================

log_subsection("Identifying multi-miRNA signatures")

# Select top performers (use top 10 regardless of AUC, since we want to create signatures)
top_biomarkers <- roc_table %>%
  head(10)

if (nrow(top_biomarkers) > 0) {
  # Create combined signature (average of top biomarkers)
  signature_data <- tibble(sample_id = sample_cols)
  
  for (i in seq_len(nrow(top_biomarkers))) {
    snv_id <- top_biomarkers$SNV_id[i]
    mirna <- top_biomarkers$miRNA_name[i]
    pos_mut <- top_biomarkers$pos.mut[i]
    # Use column indices instead of select() to avoid variable name limit
    snv_row <- vaf_data %>%
      filter(miRNA_name == mirna & pos.mut == pos_mut)
    
    if (nrow(snv_row) == 0) next
    
    sample_col_indices <- which(names(snv_row) %in% sample_cols)
    snv_data <- as.data.frame(snv_row[, sample_col_indices, drop = FALSE])
    
    if (nrow(snv_data) > 0 && ncol(snv_data) > 0) {
      # Extract values using column indices
      snv_values <- as.numeric(snv_data[1, , drop = TRUE])
      signature_data <- signature_data %>%
        mutate(!!paste0("biomarker_", i) := snv_values)
    }
  }
  
  # Calculate combined signature (average of normalized values)
  biomarker_cols <- names(signature_data)[names(signature_data) != "sample_id"]
  if (length(biomarker_cols) > 0) {
    signature_data <- signature_data %>%
      mutate(
        Combined_Score = rowMeans(select(., all_of(biomarker_cols)), na.rm = TRUE)
      ) %>%
      select(sample_id, Combined_Score) %>%
      left_join(sample_groups, by = "sample_id") %>%
      filter(!is.na(group), !is.na(Combined_Score))
    
    # ROC for combined signature
    if (nrow(signature_data) >= 10 && n_distinct(signature_data$group) == 2) {
      tryCatch({
        combined_roc <- roc(response = signature_data$group,
                            predictor = signature_data$Combined_Score,
                            levels = c(group2_name, group1_name),  # Control-like first, then Disease-like
                            direction = "<")
        combined_auc <- as.numeric(auc(combined_roc))
        
        # Save per-sample signature data (this is what we want)
        signature_output <- signature_data %>%
          select(sample_id, Combined_Score, group)
        
        write_csv(signature_output, output_signatures)
        log_success(paste("Combined signature (per-sample) saved:", output_signatures))
        log_info(paste("  ✅ ROC for Combined Signature: AUC = ", round(combined_auc, 3)))
        
        # Also add combined signature entry to ROC table
        combined_entry <- tibble(
          SNV_id = "COMBINED_SIGNATURE",
          miRNA_name = paste(top_biomarkers$miRNA_name, collapse = ";"),
          pos.mut = "Combined",
          AUC = combined_auc,
          n_samples = nrow(signature_data),
          n_group1 = sum(signature_data$group == group1_name),
          n_group2 = sum(signature_data$group == group2_name),
          # Backward compatibility
          n_ALS = if (group1_name == "ALS" || stringr::str_detect(group1_name, stringr::regex("als|disease", ignore_case = TRUE))) {
            sum(signature_data$group == group1_name)
          } else {
            sum(signature_data$group == group2_name)
          },
          n_Control = if (group2_name == "Control" || stringr::str_detect(group2_name, stringr::regex("control|ctrl", ignore_case = TRUE))) {
            sum(signature_data$group == group2_name)
          } else {
            sum(signature_data$group == group1_name)
          },
          Biomarker_Quality = case_when(
            combined_auc >= 0.9 ~ "Excellent",
            combined_auc >= 0.8 ~ "Good",
            combined_auc >= 0.7 ~ "Fair",
            TRUE ~ "Poor"
          )
        )
        
        roc_table <- bind_rows(roc_table, combined_entry) %>% arrange(desc(AUC))
        write_csv(roc_table, output_roc_table)
        log_info("Updated ROC table with combined signature")
      }, error = function(e) {
        log_warning(paste("Combined signature ROC failed:", e$message))
        # Still save signature data even if ROC fails
        signature_output <- signature_data %>%
          select(sample_id, Combined_Score, group)
        write_csv(signature_output, output_signatures)
        log_success(paste("Signature data saved (ROC calculation failed):", output_signatures))
      })
    } else {
      log_warning("Insufficient data for combined signature ROC. Saving signature data anyway.")
      signature_output <- signature_data %>%
        select(sample_id, Combined_Score, group)
      write_csv(signature_output, output_signatures)
      log_success(paste("Signature data saved:", output_signatures))
    }
  } else {
    log_warning("No biomarker data available for signature creation.")
    write_csv(tibble(sample_id = character(), Combined_Score = numeric(), group = character()), 
              output_signatures)
  }
} else {
  # Fallback if no biomarkers
  log_warning("No biomarkers available for signature creation.")
  write_csv(tibble(sample_id = character(), Combined_Score = numeric(), group = character()), 
            output_signatures)
}

# ============================================================================
# GENERATE ROC CURVES FIGURE
# ============================================================================

log_subsection("Generating ROC curves figure")

# Calculate ROC curves for top 5 individual + combined
top_5 <- roc_table %>% head(5)
roc_curves <- list()

# Validate we have data for ROC curves
if (nrow(top_5) == 0) {
  stop("No ROC data available for curve generation. Check ROC table.")
}

# Individual ROC curves
for (i in seq_len(nrow(top_5))) {
  snv_id <- top_5$SNV_id[i]
  mirna <- top_5$miRNA_name[i]
  pos_mut <- top_5$pos.mut[i]
  # Use column indices instead of select() to avoid variable name limit
  snv_row <- vaf_data %>%
    filter(miRNA_name == mirna & pos.mut == pos_mut)
  
  if (nrow(snv_row) == 0) next
  
  sample_col_indices <- which(names(snv_row) %in% sample_cols)
  snv_data <- as.data.frame(snv_row[, sample_col_indices, drop = FALSE])
  
  if (nrow(snv_data) == 0) next
  
  roc_data <- tibble(
    sample_id = sample_cols,
    value = as.numeric(snv_data[1, sample_cols])
  ) %>%
    left_join(sample_groups, by = "sample_id") %>%
    filter(!is.na(group), !is.na(value))
  
  if (nrow(roc_data) >= 10) {
    tryCatch({
      roc_obj <- roc(response = roc_data$group,
                    predictor = roc_data$value,
                    levels = c(group2_name, group1_name),  # Control-like first, then Disease-like
                    direction = "<")
      
      roc_df <- tibble(
        Sensitivity = roc_obj$sensitivities,
        Specificity = 1 - roc_obj$specificities,
        Label = paste0(top_5$miRNA_name[i], " (AUC=", round(top_5$AUC[i], 3), ")")
      )
      
      roc_curves[[i]] <- roc_df
    }, error = function(e) {
      log_warning(paste("ROC curve failed for", snv_id))
    })
  }
}

# Combined signature ROC
if (exists("combined_roc") && exists("combined_auc")) {
  combined_roc_df <- tibble(
    Sensitivity = combined_roc$sensitivities,
    Specificity = 1 - combined_roc$specificities,
    Label = paste0("Combined Signature (AUC=", round(combined_auc, 3), ")")
  )
  roc_curves[["combined"]] <- combined_roc_df
}

# Combine all ROC curves
all_roc <- bind_rows(roc_curves, .id = "index") %>%
  mutate(
    is_combined = Label %>% stringr::str_detect("Combined"),
    Label = factor(Label, levels = unique(Label))
  )

# Color palette
n_curves <- length(unique(all_roc$Label))
colors <- if (n_curves > 1) {
  c(RColorBrewer::brewer.pal(min(n_curves - 1, 9), "Set1"), color_gt)
} else {
  color_gt
}

# Generate ROC plot
roc_plot <- ggplot(all_roc, aes(x = Specificity, y = Sensitivity, color = Label)) +
  geom_abline(intercept = 1, slope = 1, linetype = "dashed", color = "grey50", linewidth = 0.5) +
  geom_line(linewidth = 1.2, alpha = 0.8) +
  scale_color_manual(values = colors, name = "Biomarker") +
  scale_x_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
  scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
  labs(
    title = "ROC Curves: Diagnostic Potential of miRNA Oxidation Patterns",
    subtitle = paste("Top", nrow(top_5), "individual biomarkers + combined signature | G>T mutations in seed region"),
    x = "1 - Specificity (False Positive Rate)",
    y = "Sensitivity (True Positive Rate)",
    caption = paste("Analysis based on", length(group1_samples), group1_name, "and", length(group2_samples), group2_name, "samples")
  ) +
  theme_professional +
  theme(
    legend.position = "right",
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 11, color = "grey50")
  )

# Save figure
ggsave(output_roc_figure, roc_plot, 
       width = fig_width, height = fig_height, dpi = fig_dpi, bg = "white")

log_success(paste("ROC figure saved:", output_roc_figure))
log_success("Step 4.1 completed successfully")

