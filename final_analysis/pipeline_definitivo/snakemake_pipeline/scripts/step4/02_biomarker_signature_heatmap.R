#!/usr/bin/env Rscript
# ============================================================================
# STEP 4.2: Biomarker Signature Heatmap
# ============================================================================
# Purpose: Create comprehensive heatmap showing biomarker signatures
# 
# This figure shows:
# 1. Heatmap of top biomarkers across samples
# 2. Sample clustering (ALS vs Control)
# 3. Biomarker performance metrics
# 4. Combined signature visualization
#
# Snakemake parameters:
#   input: ROC results and VAF-filtered data
#   output: Comprehensive biomarker heatmap
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
  library(readr)
  library(pheatmap)
  library(RColorBrewer)
})

# Load common functions
source(snakemake@params[["functions"]], local = TRUE)

# Initialize logging
log_file <- if (length(snakemake@log) > 0) snakemake@log[[1]] else {
  file.path(dirname(snakemake@output[[1]]), "biomarker_signature_heatmap.log")
}
initialize_logging(log_file, context = "Step 4.2 - Biomarker Signature Heatmap")

log_section("STEP 4.2: Biomarker Signature Heatmap")

# ============================================================================
# GET SNAKEMAKE PARAMETERS
# ============================================================================

input_roc <- snakemake@input[["roc_table"]]
input_vaf_filtered <- snakemake@input[["vaf_filtered"]]
output_heatmap <- snakemake@output[["heatmap"]]

config <- snakemake@config
color_gt <- if (!is.null(config$analysis$colors$gt)) config$analysis$colors$gt else "#D62728"
color_control <- if (!is.null(config$analysis$colors$control)) config$analysis$colors$control else "grey60"

log_info(paste("Input ROC:", input_roc))
log_info(paste("Input VAF filtered:", input_vaf_filtered))
ensure_output_dir(dirname(output_heatmap))

# ============================================================================
# LOAD DATA
# ============================================================================

log_subsection("Loading data")

roc_table <- read_csv(input_roc, show_col_types = FALSE)
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

# Select top 15 biomarkers (or all if AUC < 0.7)
# Since AUCs are low, we'll use top performers regardless of threshold
top_biomarkers <- roc_table %>%
  arrange(desc(AUC)) %>%
  head(min(15, nrow(roc_table)))

log_info(paste("Top biomarkers selected:", nrow(top_biomarkers)))
if (nrow(top_biomarkers) > 0) {
  log_info(paste("AUC range:", round(min(top_biomarkers$AUC), 3), "-", round(max(top_biomarkers$AUC), 3)))
}

# ============================================================================
# PREPARE HEATMAP DATA
# ============================================================================

log_subsection("Preparing heatmap data")

# Extract data for top biomarkers
heatmap_matrix_list <- list()

for (i in 1:nrow(top_biomarkers)) {
  snv_id <- top_biomarkers$SNV_id[i]
  mirna <- top_biomarkers$miRNA_name[i]
  pos_mut <- top_biomarkers$pos.mut[i]
  
  snv_data <- vaf_data %>%
    filter(miRNA_name == mirna & pos.mut == pos_mut) %>%
    select(all_of(sample_cols))
  
  if (nrow(snv_data) > 0) {
    # Extract values for this SNV across all samples
    values <- as.numeric(snv_data[1, sample_cols, drop = TRUE])
    if (length(values) == length(sample_cols)) {
      names(values) <- sample_cols
      heatmap_matrix_list[[paste0(mirna, "_", pos_mut)]] <- values
    }
  }
}

# Combine into matrix
if (length(heatmap_matrix_list) > 0) {
  # Convert list to data frame (each element is a vector of values across samples)
  # bind_cols expects columns, so we need to transpose the structure
  heatmap_df <- as_tibble(heatmap_matrix_list) %>%
    mutate(sample_id = sample_cols) %>%
    left_join(sample_groups, by = "sample_id") %>%
    arrange(group)  # Sort by group
  
  # Remove samples with too many NAs (if any biomarker columns exist)
  biomarker_cols <- setdiff(names(heatmap_df), c("sample_id", "group"))
  if (length(biomarker_cols) > 0) {
    heatmap_df <- heatmap_df %>%
      filter(rowSums(is.na(select(., all_of(biomarker_cols)))) / length(biomarker_cols) < 0.5)
  }
  
  # Prepare matrix (transpose for pheatmap: rows = biomarkers, cols = samples)
  if (length(biomarker_cols) > 0 && nrow(heatmap_df) > 0) {
    heatmap_matrix <- heatmap_df %>%
      select(all_of(biomarker_cols)) %>%
      t() %>%
      as.matrix()
    
    colnames(heatmap_matrix) <- heatmap_df$sample_id
  
    # Normalize by row (z-score)
    heatmap_matrix_norm <- t(scale(t(heatmap_matrix)))
    heatmap_matrix_norm[is.na(heatmap_matrix_norm)] <- 0  # Replace NA with 0 after scaling
    
    # Create annotation for samples
    sample_annotation <- heatmap_df %>%
      select(sample_id, Group = group) %>%
      column_to_rownames("sample_id")
    
    # Create annotation for biomarkers (AUC values)
    biomarker_labels <- rownames(heatmap_matrix_norm)
    biomarker_annotation <- top_biomarkers %>%
      head(length(biomarker_labels)) %>%
      mutate(
        Biomarker = paste0(miRNA_name, "_", pos.mut),
        AUC_category = case_when(
          AUC >= 0.9 ~ "Excellent",
          AUC >= 0.8 ~ "Good",
          AUC >= 0.7 ~ "Fair",
          TRUE ~ "Poor"
        )
      ) %>%
      filter(Biomarker %in% biomarker_labels) %>%
      select(Biomarker, AUC, AUC_category) %>%
      column_to_rownames("Biomarker")
    
    # Ensure row names match
    if (nrow(biomarker_annotation) > 0 && nrow(heatmap_matrix_norm) > 0) {
      # Match and reorder
      matching_rows <- intersect(rownames(heatmap_matrix_norm), rownames(biomarker_annotation))
      if (length(matching_rows) > 0) {
        heatmap_matrix_norm <- heatmap_matrix_norm[matching_rows, , drop = FALSE]
        biomarker_annotation <- biomarker_annotation[matching_rows, , drop = FALSE]
      }
  
  # Color schemes
  group_colors <- c("ALS" = color_gt, "Control" = color_control)
  auc_colors <- colorRampPalette(c("white", color_gt))(100)
  
    # ============================================================================
    # GENERATE HEATMAP
    # ============================================================================
    
    log_subsection("Generating comprehensive heatmap")
    
    if (nrow(heatmap_matrix_norm) > 0 && ncol(heatmap_matrix_norm) > 0 && nrow(biomarker_annotation) > 0) {
      png(output_heatmap, width = 16, height = 12, units = "in", res = 300)
      
      # Calculate gap position (between Control and ALS groups)
      n_control <- sum(sample_annotation$Group == "Control")
      gap_pos <- if (n_control > 0 && n_control < nrow(sample_annotation)) n_control else NULL
      
      pheatmap(
        heatmap_matrix_norm,
        color = colorRampPalette(c("#2E86AB", "white", color_gt))(100),
        cluster_rows = TRUE,
        cluster_cols = TRUE,
        show_colnames = FALSE,
        show_rownames = TRUE,
        annotation_col = sample_annotation,
        annotation_row = biomarker_annotation %>% select(AUC_category),
        annotation_colors = list(
          Group = group_colors,
          AUC_category = c("Excellent" = "#D62728", "Good" = "#FF7F0E", "Fair" = "#2CA02C", "Poor" = "grey70")
        ),
        main = "Biomarker Signature Heatmap\nTop Performing miRNA Oxidation Patterns",
        fontsize = 10,
        fontsize_row = 9,
        fontsize_col = 6,
        angle_col = 90,
        border_color = "grey60",
        gaps_col = gap_pos,  # Gap between groups
        legend = TRUE,
        legend_breaks = c(min(heatmap_matrix_norm, na.rm = TRUE), 
                         0, 
                         max(heatmap_matrix_norm, na.rm = TRUE)),
        legend_labels = c("Low", "0 (mean)", "High"),
        display_numbers = FALSE,
        treeheight_row = 50,
        treeheight_col = 50
      )
      
      dev.off()
      
      log_success(paste("Heatmap saved:", output_heatmap))
    } else {
      log_warning("Insufficient data for heatmap generation")
      png(output_heatmap, width = 10, height = 8, units = "in", res = 300)
      plot.new()
      text(0.5, 0.5, "Insufficient biomarkers for heatmap", cex = 1.5)
      dev.off()
    }
  } else {
    log_warning("No biomarkers found for heatmap")
    # Create empty placeholder
    png(output_heatmap, width = 10, height = 8, units = "in", res = 300)
    plot.new()
    text(0.5, 0.5, "No biomarkers found", cex = 1.5)
    dev.off()
  }

log_success("Step 4.2 completed successfully")

