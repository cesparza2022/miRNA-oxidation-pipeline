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

# Load common functions and theme
source(snakemake@params[["functions"]], local = TRUE)
# Theme is loaded via functions_common.R

# Initialize logging
log_file <- if (length(snakemake@log) > 0) snakemake@log[[1]] else {
  file.path(dirname(snakemake@output[[1]]), "biomarker_roc_analysis.log")
}
initialize_logging(log_file, context = "Step 4.1 - Biomarker ROC Analysis")

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

# Extract sample groups
sample_cols <- setdiff(names(vaf_data), c("miRNA_name", "pos.mut", "miRNA name", "pos:mut"))
sample_groups <- tibble(sample_id = sample_cols) %>%
  mutate(
    group = case_when(
      str_detect(sample_id, regex("ALS", ignore_case = TRUE)) ~ "ALS",
      str_detect(sample_id, regex("control|Control|CTRL", ignore_case = TRUE)) ~ "Control",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(group))

als_samples <- sample_groups %>% filter(group == "ALS") %>% pull(sample_id)
control_samples <- sample_groups %>% filter(group == "Control") %>% pull(sample_id)

log_info(paste("ALS samples:", length(als_samples)))
log_info(paste("Control samples:", length(control_samples)))

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
    log2_fold_change > log2fc_threshold  # Higher in ALS (configurable threshold)
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

for (i in 1:min(nrow(significant_gt), 30)) {  # Top 30 for computational efficiency
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
  
  # Calculate ROC
  tryCatch({
    roc_obj <- roc(response = roc_data$group, 
                  predictor = roc_data$value,
                  levels = c("Control", "ALS"),
                  direction = "<")
    
    auc_value <- as.numeric(auc(roc_obj))
    
    roc_results[[i]] <- tibble(
      SNV_id = snv_id,
      miRNA_name = mirna,
      pos.mut = pos_mut,
      AUC = auc_value,
      n_samples = nrow(roc_data),
      n_ALS = sum(roc_data$group == "ALS"),
      n_Control = sum(roc_data$group == "Control")
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

# Select top performers
top_biomarkers <- roc_table %>%
  filter(Biomarker_Quality %in% c("Excellent", "Good")) %>%
  head(10)

if (nrow(top_biomarkers) > 0) {
  # Create combined signature (average of top biomarkers)
  signature_data <- tibble(sample_id = sample_cols)
  
  for (i in 1:nrow(top_biomarkers)) {
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
  signature_data <- signature_data %>%
    mutate(
      combined_signature = rowMeans(select(., starts_with("biomarker")), na.rm = TRUE)
    ) %>%
    left_join(sample_groups, by = "sample_id") %>%
    filter(!is.na(group), !is.na(combined_signature))
  
  # ROC for combined signature
  if (nrow(signature_data) >= 10) {
    tryCatch({
      combined_roc <- roc(response = signature_data$group,
                          predictor = signature_data$combined_signature,
                          levels = c("Control", "ALS"),
                          direction = "<")
      combined_auc <- as.numeric(auc(combined_roc))
      
      signatures <- top_biomarkers %>%
        mutate(Signature_Type = "Individual") %>%
        bind_rows(
          tibble(
            SNV_id = "COMBINED_SIGNATURE",
            miRNA_name = paste(top_biomarkers$miRNA_name, collapse = ";"),
            pos.mut = "Combined",
            AUC = combined_auc,
            n_samples = nrow(signature_data),
            n_ALS = sum(signature_data$group == "ALS"),
            n_Control = sum(signature_data$group == "Control"),
            Biomarker_Quality = case_when(
              combined_auc >= 0.9 ~ "Excellent",
              combined_auc >= 0.8 ~ "Good",
              combined_auc >= 0.7 ~ "Fair",
              TRUE ~ "Poor"
            ),
            Signature_Type = "Combined"
          )
        )
      
      write_csv(signatures, output_signatures)
      log_success(paste("Combined signature AUC:", round(combined_auc, 3)))
    }, error = function(e) {
      log_warning(paste("Combined signature ROC failed:", e$message))
      write_csv(top_biomarkers %>% mutate(Signature_Type = "Individual"), output_signatures)
    })
  } else {
    write_csv(top_biomarkers %>% mutate(Signature_Type = "Individual"), output_signatures)
  }
} else {
  # Fallback if no good biomarkers
  write_csv(roc_table %>% mutate(Signature_Type = "Individual"), output_signatures)
}

# ============================================================================
# GENERATE ROC CURVES FIGURE
# ============================================================================

log_subsection("Generating ROC curves figure")

# Calculate ROC curves for top 5 individual + combined
top_5 <- roc_table %>% head(5)
roc_curves <- list()

# Individual ROC curves
for (i in 1:nrow(top_5)) {
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
    tryCatch({
      roc_obj <- roc(response = roc_data$group,
                    predictor = roc_data$value,
                    levels = c("Control", "ALS"),
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
    title = "ROC Curves: Diagnostic Potential of miRNA Oxidation Patterns",
    subtitle = paste("Top", nrow(top_5), "individual biomarkers + combined signature | G>T mutations in seed region"),
    x = "1 - Specificity (False Positive Rate)",
    y = "Sensitivity (True Positive Rate)",
    caption = paste("Analysis based on", length(als_samples), "ALS and", length(control_samples), "Control samples")
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
log_success("Step 4.1 completed successfully")

