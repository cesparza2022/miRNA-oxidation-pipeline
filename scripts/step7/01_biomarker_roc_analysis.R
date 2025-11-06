#!/usr/bin/env Rscript
# ============================================================================
# STEP 7: Biomarker ROC Analysis (Final Integration)
# ============================================================================
# Purpose: Evaluate diagnostic potential of miRNA oxidation patterns
#          This step runs LAST, after Step 6, primarily using statistical results from Step 2
#          and VAF-filtered data. Note: Currently uses Steps 1.5, 2, and depends on Step 6.
#          Future versions may integrate clustering, families, and expression data.
#
# Execution order: Step 1 → Step 1.5 → Step 2 → Step 3 → [4,5,6 parallel] → Step 7 (LAST, after Step 6)
#
# This script performs:
# 1. ROC curve analysis for individual miRNAs
# 2. AUC calculation and ranking
# 3. Multi-miRNA signature identification
# 4. Combined ROC analysis (integrates all insights)
#
# Snakemake parameters:
#   input: Statistical comparisons from Step 2, VAF-filtered data from Step 1.5
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

# Load common functions and theme
source(snakemake@params[["functions"]], local = TRUE)
# Theme is loaded via functions_common.R

# Load group comparison utilities for dynamic group detection
group_functions_path <- if (!is.null(snakemake@params[["group_functions"]])) {
  snakemake@params[["group_functions"]]
} else {
  "scripts/utils/group_comparison.R"
}

if (file.exists(group_functions_path)) {
  source(group_functions_path, local = TRUE)
}

# Initialize logging
log_file <- if (length(snakemake@log) > 0) snakemake@log[[1]] else {
  file.path(dirname(snakemake@output[[1]]), "biomarker_roc_analysis.log")
}
initialize_logging(log_file, context = "Step 7.1 - Biomarker ROC Analysis")

log_section("STEP 7: Biomarker ROC Analysis (Final Integration)")

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
# For biomarker analysis, we want all mutations that are higher in ALS (log2FC > 0)
# Not just those with very high fold change (log2FC > 1.0)
log2fc_threshold <- if (!is.null(config$analysis$log2fc_threshold_step7)) config$analysis$log2fc_threshold_step7 else 0.0
seed_start <- if (!is.null(config$analysis$seed_region$start)) config$analysis$seed_region$start else 2
seed_end <- if (!is.null(config$analysis$seed_region$end)) config$analysis$seed_region$end else 8
color_gt <- if (!is.null(config$analysis$colors$gt)) config$analysis$colors$gt else "#D62728"
color_control <- if (!is.null(config$analysis$colors$control)) config$analysis$colors$control else "grey60"

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

statistical_results <- read_csv(input_statistical, show_col_types = FALSE)
vaf_data <- read_csv(input_vaf_filtered, show_col_types = FALSE)

# Normalize column names (handle different formats)
if ("miRNA name" %in% names(vaf_data)) {
  vaf_data <- vaf_data %>% rename(miRNA_name = `miRNA name`)
}
if ("pos:mut" %in% names(vaf_data)) {
  vaf_data <- vaf_data %>% rename(pos.mut = `pos:mut`)
}

# Extract sample groups (dynamic - supports metadata file or pattern matching)
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
  handle_error(e, context = "Step 7.1 - Group Identification", exit_code = 1, log_file = log_file)
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
    str_detect(pos.mut, ":GT$"),
    !is.na(t_test_fdr) | !is.na(wilcoxon_fdr),
    (t_test_fdr < alpha | wilcoxon_fdr < alpha),
    !is.na(log2_fold_change),
    log2_fold_change > log2fc_threshold  # Higher in ALS (default: 0.0, meaning any positive fold change)
  ) %>%
  mutate(
    position = as.numeric(str_extract(pos.mut, "^\\d+")),
    in_seed = position >= seed_start & position <= seed_end
  ) %>%
  filter(in_seed == TRUE) %>%
  distinct(miRNA_name, pos.mut, .keep_all = TRUE) %>%
  arrange(desc(log2_fold_change)) %>%
  head(50)  # Top 50 for ROC analysis

log_info(paste("Significant G>T mutations for ROC analysis:", nrow(significant_gt)))

# ============================================================================
# ROC ANALYSIS FOR INDIVIDUAL miRNAs
# ============================================================================

log_subsection("Performing ROC analysis for individual miRNAs")

roc_results <- list()

for (i in seq_len(min(nrow(significant_gt), 30))) {  # Top 30 for computational efficiency
  snv_id <- significant_gt$SNV_id[i]
  mirna <- significant_gt$miRNA_name[i]
  pos_mut <- significant_gt$pos.mut[i]
  
  # Get data for this SNV (match by miRNA_name and pos.mut)
  snv_data <- vaf_data %>%
    filter(miRNA_name == mirna & pos.mut == pos_mut) %>%
    select(all_of(sample_cols))
  
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
  
  # Determine ROC direction: if disease group has higher values, use ">"
  # Check mean values to determine direction
  mean_group1 <- mean(roc_data$value[roc_data$group == group1_name], na.rm = TRUE)
  mean_group2 <- mean(roc_data$value[roc_data$group == group2_name], na.rm = TRUE)
  roc_direction <- ifelse(mean_group1 > mean_group2, ">", "<")
  
  tryCatch({
    roc_obj <- roc(response = roc_data$group_factor, 
                  predictor = roc_data$value,
                  levels = c(group2_name, group1_name),  # Control-like first, then Disease-like
                  direction = roc_direction)  # Dynamic: ">" if disease has higher values
    
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
      n_ALS = if (group1_name == "ALS" || str_detect(group1_name, regex("als|disease", ignore_case = TRUE))) {
        sum(roc_data$group == group1_name)
      } else {
        sum(roc_data$group == group2_name)
      },
      n_Control = if (group2_name == "Control" || str_detect(group2_name, regex("control|ctrl", ignore_case = TRUE))) {
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
    snv_data <- vaf_data %>%
      filter(miRNA_name == mirna & pos.mut == pos_mut) %>%
      select(all_of(sample_cols))
    
    if (nrow(snv_data) > 0) {
      signature_data <- signature_data %>%
        mutate(!!paste0("biomarker_", i) := as.numeric(snv_data[1, sample_cols]))
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
      # Determine ROC direction dynamically for combined signature
      mean_group1_combined <- mean(signature_data$Combined_Score[signature_data$group == group1_name], na.rm = TRUE)
      mean_group2_combined <- mean(signature_data$Combined_Score[signature_data$group == group2_name], na.rm = TRUE)
      roc_direction_combined <- ifelse(mean_group1_combined > mean_group2_combined, ">", "<")
      
      tryCatch({
        combined_roc <- roc(response = signature_data$group,
                            predictor = signature_data$Combined_Score,
                            levels = c(group2_name, group1_name),  # Control-like first, then Disease-like
                            direction = roc_direction_combined)  # Dynamic direction
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
          n_ALS = if (group1_name == "ALS" || str_detect(group1_name, regex("als|disease", ignore_case = TRUE))) {
            sum(signature_data$group == group1_name)
          } else {
            sum(signature_data$group == group2_name)
          },
          n_Control = if (group2_name == "Control" || str_detect(group2_name, regex("control|ctrl", ignore_case = TRUE))) {
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

# Individual ROC curves
for (i in seq_len(nrow(top_5))) {
  snv_id <- top_5$SNV_id[i]
  mirna <- top_5$miRNA_name[i]
  pos_mut <- top_5$pos.mut[i]
  snv_data <- vaf_data %>%
    filter(miRNA_name == mirna & pos.mut == pos_mut) %>%
    select(all_of(sample_cols))
  
  if (nrow(snv_data) == 0) next
  
  roc_data <- tibble(
    sample_id = sample_cols,
    value = as.numeric(snv_data[1, sample_cols])
  ) %>%
    left_join(sample_groups, by = "sample_id") %>%
    filter(!is.na(group), !is.na(value))
  
  if (nrow(roc_data) >= 10) {
    # Determine ROC direction dynamically
  mean_group1 <- mean(roc_data$value[roc_data$group == group1_name], na.rm = TRUE)
  mean_group2 <- mean(roc_data$value[roc_data$group == group2_name], na.rm = TRUE)
  roc_direction <- ifelse(mean_group1 > mean_group2, ">", "<")
  
  tryCatch({
      roc_obj <- roc(response = roc_data$group,
                    predictor = roc_data$value,
                    levels = c(group2_name, group1_name),  # Control-like first, then Disease-like
                    direction = roc_direction)  # Dynamic direction
      
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
    is_combined = Label %>% str_detect("Combined"),
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
    title = "Diagnostic Potential of G>T Oxidation Patterns in ALS",
    subtitle = paste("ROC analysis: Top", nrow(top_5), "individual miRNA oxidation biomarkers + combined signature |",
                     "Seed region (positions", seed_start, "-", seed_end, ") |",
                     "AUC > 0.5 indicates better than random classification"),
    x = "1 - Specificity (False Positive Rate)",
    y = "Sensitivity (True Positive Rate)",
    caption = paste("Analysis based on", length(group1_samples), group1_name, "and", length(group2_samples), group2_name, "samples |",
                   "Dashed line: Random classifier (AUC = 0.5)")
  ) +
  theme_professional +
  theme(
    legend.position = "right",
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 11, color = "grey50")
  )

# Save figure
ggsave(output_roc_figure, roc_plot, 
       width = 12, height = 10, dpi = 300, bg = "white")

log_success(paste("ROC figure saved:", output_roc_figure))
log_success("Step 7.1 completed successfully")

