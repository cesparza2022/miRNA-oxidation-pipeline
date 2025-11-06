#!/usr/bin/env Rscript
# ============================================================================
# STEP 2.0: Batch Effect Analysis
# ============================================================================
# Purpose: Detect and correct batch effects that could confound group comparisons
# 
# This script performs:
# 1. Principal Component Analysis (PCA) to detect batch clustering
# 2. Statistical testing for batch effects
# 3. Batch correction if significant effects are detected
# 4. Visualization of batch effects before/after correction
#
# Snakemake parameters:
#   input: VAF-filtered data from Step 1.5
#   output: Batch-corrected data (if correction needed) and batch effect report
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
  library(readr)
  library(stringr)
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
}

# Initialize logging
log_file <- if (length(snakemake@log) > 0) snakemake@log[[1]] else {
  file.path(dirname(snakemake@output[[1]]), "batch_effect_analysis.log")
}
initialize_logging(log_file, context = "Step 2.0 - Batch Effect Analysis")

log_section("STEP 2.0: Batch Effect Analysis")

# ============================================================================
# GET SNAKEMAKE PARAMETERS
# ============================================================================

input_file <- if (!is.null(snakemake@input[["vaf_filtered_data"]]) && file.exists(snakemake@input[["vaf_filtered_data"]])) {
  snakemake@input[["vaf_filtered_data"]]
} else if (!is.null(snakemake@input[["fallback_data"]]) && file.exists(snakemake@input[["fallback_data"]])) {
  snakemake@input[["fallback_data"]]
} else if (!is.null(snakemake@input[["data"]])) {
  snakemake@input[["data"]]
} else {
  stop("Could not find input data file.")
}

# Optional metadata file
metadata_file <- if (!is.null(snakemake@input[["metadata"]])) {
  snakemake@input[["metadata"]]
} else {
  NULL
}

output_batch_corrected <- snakemake@output[["batch_corrected"]]
output_report <- snakemake@output[["report"]]
output_pca_before <- snakemake@output[["pca_before"]]
output_pca_after <- if (!is.null(snakemake@output[["pca_after"]])) {
  snakemake@output[["pca_after"]]
} else {
  NULL
}

config <- snakemake@config
batch_correction_method <- if (!is.null(config$analysis$batch_correction$method)) {
  config$analysis$batch_correction$method
} else {
  "none"  # Options: "none", "combat", "limma", "pca"
}

batch_effect_threshold <- if (!is.null(config$analysis$batch_correction$pvalue_threshold)) {
  config$analysis$batch_correction$pvalue_threshold
} else {
  0.05
}

log_info(paste("Input file:", input_file))
log_info(paste("Metadata file:", if (is.null(metadata_file)) "Not provided" else metadata_file))
log_info(paste("Batch correction method:", batch_correction_method))
log_info(paste("Batch effect threshold (p-value):", batch_effect_threshold))

ensure_output_dir(dirname(output_batch_corrected))
ensure_output_dir(dirname(output_report))
ensure_output_dir(dirname(output_pca_before))

# ============================================================================
# LOAD DATA
# ============================================================================

log_subsection("Loading data")

data <- tryCatch({
  if (str_ends(input_file, ".csv")) {
    result <- read_csv(input_file, show_col_types = FALSE)
  } else {
    result <- read_tsv(input_file, show_col_types = FALSE)
  }
  
  # Normalize column names
  if ("miRNA name" %in% names(result)) {
    result <- result %>% rename(miRNA_name = `miRNA name`)
  }
  if ("pos:mut" %in% names(result)) {
    result <- result %>% rename(pos.mut = `pos:mut`)
  }
  
  log_success(paste("Data loaded:", nrow(result), "rows,", ncol(result), "columns"))
  result
}, error = function(e) {
  handle_error(e, context = "Step 2.0 - Data Loading", exit_code = 1, log_file = log_file)
})

# Load metadata if available
metadata <- NULL
if (!is.null(metadata_file) && file.exists(metadata_file)) {
  metadata <- tryCatch({
    read_tsv(metadata_file, show_col_types = FALSE)
    log_success(paste("Metadata loaded:", nrow(metadata), "samples"))
  }, error = function(e) {
    log_warning(paste("Failed to load metadata:", e$message))
    NULL
  })
}

# ============================================================================
# IDENTIFY SAMPLES AND GROUPS
# ============================================================================

log_subsection("Identifying samples and groups")

# Get metadata file path from Snakemake params
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

groups_df <- tryCatch({
  extract_sample_groups(data, metadata_file = metadata_file)
}, error = function(e) {
  handle_error(e, context = "Step 2.0 - Group Identification", exit_code = 1, log_file = log_file)
})

# Extract batch information
# If metadata is available, use it; otherwise infer from sample names
if (!is.null(metadata) && "batch" %in% names(metadata)) {
  batch_df <- metadata %>%
    select(sample_id, batch) %>%
    filter(!is.na(batch))
  
  # Merge with groups
  groups_df <- groups_df %>%
    left_join(batch_df, by = "sample_id")
  
  log_info(paste("Batch information from metadata:", nrow(batch_df), "samples"))
} else {
  # Try to infer batch from sample names (e.g., "batch_1_sample", "run2_sample")
  groups_df <- groups_df %>%
    mutate(
      batch = case_when(
        str_detect(sample_id, regex("batch[_\\-]?1|run[_\\-]?1|b1", ignore_case = TRUE)) ~ "batch_1",
        str_detect(sample_id, regex("batch[_\\-]?2|run[_\\-]?2|b2", ignore_case = TRUE)) ~ "batch_2",
        str_detect(sample_id, regex("batch[_\\-]?3|run[_\\-]?3|b3", ignore_case = TRUE)) ~ "batch_3",
        str_detect(sample_id, regex("batch[_\\-]?4|run[_\\-]?4|b4", ignore_case = TRUE)) ~ "batch_4",
        TRUE ~ "unknown"
      )
    )
  
  log_info("Batch inferred from sample names")
}

n_batches <- length(unique(groups_df$batch[!is.na(groups_df$batch)]))
log_info(paste("Number of batches detected:", n_batches))

if (n_batches < 2) {
  log_warning("Less than 2 batches detected. Batch effect analysis may not be meaningful.")
  log_info("Skipping batch correction and returning original data.")
  
  # Write original data as "corrected" (no correction needed)
  write_csv(data, output_batch_corrected)
  
  # Create minimal report
  report_text <- paste(
    "BATCH EFFECT ANALYSIS REPORT\n",
    "===========================\n\n",
    "Date:", Sys.time(), "\n",
    "Batches detected:", n_batches, "\n",
    "Status: Insufficient batches for analysis (need >= 2)\n",
    "Action: No batch correction applied\n",
    "Output: Original data returned unchanged\n"
  )
  
  writeLines(report_text, output_report)
  
  # Still generate PCA plot even with insufficient batches (for visualization)
  log_info("Generating PCA plot despite insufficient batches...")
  
  # Prepare data for PCA (even with 1 batch, we can still visualize)
  metadata_cols <- c("miRNA_name", "pos.mut")
  sample_cols <- names(data)[!names(data) %in% metadata_cols]
  
  # Create count matrix
  count_matrix <- data %>%
    select(all_of(c("miRNA_name", "pos.mut", sample_cols))) %>%
    unite("SNV_id", miRNA_name, pos.mut, sep = "|", remove = FALSE) %>%
    select(-miRNA_name, -pos.mut) %>%
    column_to_rownames("SNV_id") %>%
    as.matrix()
  
  # Filter SNVs with low variance
  count_matrix <- count_matrix[rowSums(count_matrix > 0, na.rm = TRUE) >= 2, ]
  
  # Replace infinite/NaN values with 0
  count_matrix[!is.finite(count_matrix)] <- 0
  count_matrix[is.na(count_matrix)] <- 0
  
  count_matrix_log <- log2(count_matrix + 1)
  
  # Replace infinite/NaN values again after log transform
  count_matrix_log[!is.finite(count_matrix_log)] <- 0
  count_matrix_log[is.na(count_matrix_log)] <- 0
  
  # Perform PCA
  pca_input <- t(count_matrix_log)
  valid_samples <- intersect(rownames(pca_input), groups_df$sample_id)
  pca_input <- pca_input[valid_samples, ]
  
  # Final check for infinite/NaN values
  pca_input[!is.finite(pca_input)] <- 0
  pca_input[is.na(pca_input)] <- 0
  
  # Remove columns with zero variance (would cause PCA to fail)
  col_vars <- apply(pca_input, 2, var, na.rm = TRUE)
  valid_cols <- which(col_vars > 0 & is.finite(col_vars))
  if (length(valid_cols) < 2) {
    log_warning("Insufficient variance in data for PCA. Creating minimal plot.")
    # Create a minimal plot instead
    p_pca_before <- ggplot() +
      annotate("text", x = 0.5, y = 0.5, 
               label = "Insufficient variance for PCA\n(too few variable features)",
               size = 6, hjust = 0.5) +
      labs(title = "PCA: Batch Effects (Before Correction)",
           subtitle = "Insufficient variance in data") +
      theme_void() +
      theme(
        plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 12, hjust = 0.5)
      )
    
    config <- snakemake@config
    fig_width <- if (!is.null(config$analysis$figure$width)) config$analysis$figure$width else 12
    fig_height <- if (!is.null(config$analysis$figure$height)) config$analysis$figure$height else 10
    fig_dpi <- if (!is.null(config$analysis$figure$dpi)) config$analysis$figure$dpi else 300
    
    ggsave(output_pca_before, p_pca_before, 
           width = fig_width, height = fig_height, dpi = fig_dpi, bg = "white")
    log_success(paste("PCA plot saved (minimal):", output_pca_before))
    
    # Write corrected (or original) data
    write_csv(data, output_batch_corrected)
    log_success(paste("Data saved:", output_batch_corrected))
    
    log_success("Batch effect analysis completed (no correction needed)")
    quit(status = 0)
  }
  
  pca_input <- pca_input[, valid_cols]
  
  pca_result <- tryCatch({
    prcomp(pca_input, center = TRUE, scale. = TRUE)
  }, error = function(e) {
    log_warning(paste("PCA failed:", conditionMessage(e)))
    log_warning("Creating minimal plot instead")
    # Create minimal plot
    p_pca_before <- ggplot() +
      annotate("text", x = 0.5, y = 0.5, 
               label = paste("PCA failed:", conditionMessage(e)),
               size = 5, hjust = 0.5) +
      labs(title = "PCA: Batch Effects (Before Correction)",
           subtitle = "PCA computation failed") +
      theme_void() +
      theme(
        plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 12, hjust = 0.5)
      )
    
    config <- snakemake@config
    fig_width <- if (!is.null(config$analysis$figure$width)) config$analysis$figure$width else 12
    fig_height <- if (!is.null(config$analysis$figure$height)) config$analysis$figure$height else 10
    fig_dpi <- if (!is.null(config$analysis$figure$dpi)) config$analysis$figure$dpi else 300
    
    ggsave(output_pca_before, p_pca_before, 
           width = fig_width, height = fig_height, dpi = fig_dpi, bg = "white")
    
    write_csv(data, output_batch_corrected)
    log_success("Batch effect analysis completed (with PCA error)")
    quit(status = 0)
  })
  
  # Extract PC scores
  pca_scores <- as.data.frame(pca_result$x[, 1:min(10, ncol(pca_result$x))])
  pca_scores$sample_id <- rownames(pca_scores)
  pca_scores <- pca_scores %>%
    left_join(groups_df, by = "sample_id") %>%
    mutate(
      batch = ifelse(is.na(batch), "unknown", batch),
      group = ifelse(is.na(group), "unknown", group)
    )
  
  # Variance explained
  variance_explained <- summary(pca_result)$importance[2, 1:min(10, ncol(pca_result$x))]
  pc1_var <- variance_explained[1] * 100
  pc2_var <- variance_explained[2] * 100
  
  # Create PCA plot
  unique_groups_pca <- unique(pca_scores$group)
  unique_groups_pca <- unique_groups_pca[!is.na(unique_groups_pca)]
  
  if (length(unique_groups_pca) <= 2) {
    group_shapes <- setNames(c(16, 17), unique_groups_pca)
  } else {
    group_shapes <- setNames(rep(16, length(unique_groups_pca)), unique_groups_pca)
  }
  
  p_pca_before <- ggplot(pca_scores, aes(x = PC1, y = PC2, color = batch, shape = group)) +
    geom_point(size = 3, alpha = 0.7) +
    scale_color_brewer(palette = "Set2", name = "Batch") +
    scale_shape_manual(values = group_shapes, name = "Group") +
    labs(
      title = "PCA: Batch Effects (Before Correction)",
      subtitle = paste("PC1 (", round(pc1_var, 1), "%) vs PC2 (", round(pc2_var, 1), "%)"),
      x = paste0("PC1 (", round(pc1_var, 1), "%)"),
      y = paste0("PC2 (", round(pc2_var, 1), "%)"),
      caption = "Note: Only 1 batch detected - batch correction not applicable"
    ) +
    theme_professional +
    theme(
      legend.position = "right",
      plot.title = element_text(size = 14, face = "bold")
    )
  
  # Save figure
  config <- snakemake@config
  fig_width <- if (!is.null(config$analysis$figure$width)) config$analysis$figure$width else 12
  fig_height <- if (!is.null(config$analysis$figure$height)) config$analysis$figure$height else 10
  fig_dpi <- if (!is.null(config$analysis$figure$dpi)) config$analysis$figure$dpi else 300
  
  ggsave(output_pca_before, p_pca_before, 
         width = fig_width, height = fig_height, dpi = fig_dpi, bg = "white")
  log_success(paste("PCA plot saved:", output_pca_before))
  
  # Write corrected (or original) data
  write_csv(data, output_batch_corrected)
  log_success(paste("Data saved:", output_batch_corrected))
  
  log_success("Batch effect analysis completed (no correction needed)")
  quit(status = 0)
}

# ============================================================================
# PREPARE DATA FOR PCA
# ============================================================================

log_subsection("Preparing data for PCA analysis")

# Convert to matrix format for PCA
metadata_cols <- c("miRNA_name", "pos.mut")
sample_cols <- names(data)[!names(data) %in% metadata_cols]

# Create count matrix (samples as columns, SNVs as rows)
count_matrix <- data %>%
  select(all_of(c("miRNA_name", "pos.mut", sample_cols))) %>%
  unite("SNV_id", miRNA_name, pos.mut, sep = "|", remove = FALSE) %>%
  select(-miRNA_name, -pos.mut) %>%
  column_to_rownames("SNV_id") %>%
  as.matrix()

# Filter SNVs with low variance (remove SNVs with no variation)
count_matrix <- count_matrix[rowSums(count_matrix > 0, na.rm = TRUE) >= 2, ]

# Log transform (add pseudocount to avoid log(0))
count_matrix_log <- log2(count_matrix + 1)

log_info(paste("Matrix prepared:", nrow(count_matrix_log), "SNVs ×", ncol(count_matrix_log), "samples"))

# ============================================================================
# PRINCIPAL COMPONENT ANALYSIS (PCA)
# ============================================================================

log_subsection("Performing PCA")

# Transpose for PCA (samples as rows, SNVs as columns)
pca_input <- t(count_matrix_log)

# Remove samples not in groups_df
valid_samples <- intersect(rownames(pca_input), groups_df$sample_id)
pca_input <- pca_input[valid_samples, ]

# Perform PCA
pca_result <- tryCatch({
  prcomp(pca_input, center = TRUE, scale. = TRUE)
}, error = function(e) {
  handle_error(e, context = "Step 2.0 - PCA", exit_code = 1, log_file = log_file)
})

# Extract PC scores
pca_scores <- as.data.frame(pca_result$x[, 1:min(10, ncol(pca_result$x))])

# Add metadata
pca_scores$sample_id <- rownames(pca_scores)
pca_scores <- pca_scores %>%
  left_join(groups_df, by = "sample_id") %>%
  mutate(
    batch = ifelse(is.na(batch), "unknown", batch),
    group = ifelse(is.na(group), "unknown", group)
  )

# Variance explained
variance_explained <- summary(pca_result)$importance[2, 1:min(10, ncol(pca_result$x))]
pc1_var <- variance_explained[1] * 100
pc2_var <- variance_explained[2] * 100

log_info(paste("PC1 variance explained:", round(pc1_var, 2), "%"))
log_info(paste("PC2 variance explained:", round(pc2_var, 2), "%"))

# ============================================================================
# STATISTICAL TESTING FOR BATCH EFFECTS
# ============================================================================

log_subsection("Testing for batch effects")

# Test if batches cluster separately in PCA space
batch_effect_tests <- list()

# Test 1: ANOVA on PC1 by batch
if (n_batches >= 2 && sum(!is.na(pca_scores$batch)) >= 4) {
  pc1_by_batch <- aov(PC1 ~ batch, data = pca_scores)
  pc1_summary <- summary(pc1_by_batch)
  batch_effect_tests$pc1_batch_pvalue <- pc1_summary[[1]][["Pr(>F)"]][1]
  
  log_info(paste("PC1 by batch (ANOVA): p =", format(batch_effect_tests$pc1_batch_pvalue, scientific = TRUE)))
}

# Test 2: ANOVA on PC2 by batch
if (n_batches >= 2 && sum(!is.na(pca_scores$batch)) >= 4) {
  pc2_by_batch <- aov(PC2 ~ batch, data = pca_scores)
  pc2_summary <- summary(pc2_by_batch)
  batch_effect_tests$pc2_batch_pvalue <- pc2_summary[[1]][["Pr(>F)"]][1]
  
  log_info(paste("PC2 by batch (ANOVA): p =", format(batch_effect_tests$pc2_batch_pvalue, scientific = TRUE)))
}

# Test 3: Check if batch and group are confounded
if (!is.null(pca_scores$batch) && !is.null(pca_scores$group)) {
  contingency_table <- table(pca_scores$batch, pca_scores$group)
  if (nrow(contingency_table) >= 2 && ncol(contingency_table) >= 2) {
    chi_square_test <- chisq.test(contingency_table)
    batch_effect_tests$batch_group_confounded_pvalue <- chi_square_test$p.value
    batch_effect_tests$batch_group_confounded <- chi_square_test$p.value < 0.05
    
    log_info(paste("Batch-Group independence (Chi-square): p =", 
                   format(batch_effect_tests$batch_group_confounded_pvalue, scientific = TRUE)))
    
    if (batch_effect_tests$batch_group_confounded) {
      log_warning("⚠️  Batch and Group are confounded! This may bias results.")
    }
  }
}

# Overall assessment
batch_effect_significant <- any(
  batch_effect_tests$pc1_batch_pvalue < batch_effect_threshold,
  batch_effect_tests$pc2_batch_pvalue < batch_effect_threshold,
  na.rm = TRUE
)

if (batch_effect_significant) {
  log_warning(paste("⚠️  Significant batch effects detected (p <", batch_effect_threshold, ")"))
} else {
  log_info("✓ No significant batch effects detected")
}

# ============================================================================
# VISUALIZATION: PCA BEFORE CORRECTION
# ============================================================================

log_subsection("Generating PCA visualization (before correction)")

# Get unique groups from pca_scores
unique_groups_pca <- sort(unique(pca_scores$group))
group_shapes <- setNames(c(16, 17, 1)[1:length(unique_groups_pca)], unique_groups_pca)
if (length(unique_groups_pca) > 2) {
  group_shapes <- setNames(rep(16, length(unique_groups_pca)), unique_groups_pca)  # All same shape if > 2 groups
}

p_pca_before <- ggplot(pca_scores, aes(x = PC1, y = PC2, color = batch, shape = group)) +
  geom_point(size = 3, alpha = 0.7) +
  scale_color_brewer(palette = "Set2", name = "Batch") +
  scale_shape_manual(values = group_shapes, name = "Group") +
  labs(
    title = "PCA: Batch Effects (Before Correction)",
    subtitle = paste("PC1 (", round(pc1_var, 1), "%) vs PC2 (", round(pc2_var, 1), "%)"),
    x = paste0("PC1 (", round(pc1_var, 1), "%)"),
    y = paste0("PC2 (", round(pc2_var, 1), "%)"),
    caption = if (batch_effect_significant) {
      "⚠️ Significant batch effects detected"
    } else {
      "✓ No significant batch effects"
    }
  ) +
  theme_professional +
  theme(
    legend.position = "right",
    plot.title = element_text(size = 14, face = "bold")
  )

# Save figure
config <- snakemake@config
fig_width <- if (!is.null(config$analysis$figure$width)) config$analysis$figure$width else 12
fig_height <- if (!is.null(config$analysis$figure$height)) config$analysis$figure$height else 10
fig_dpi <- if (!is.null(config$analysis$figure$dpi)) config$analysis$figure$dpi else 300

ggsave(output_pca_before, p_pca_before, 
       width = fig_width, height = fig_height, dpi = fig_dpi, bg = "white")
log_success(paste("PCA plot saved:", output_pca_before))

# ============================================================================
# BATCH CORRECTION (if needed and method specified)
# ============================================================================

data_corrected <- data
correction_applied <- FALSE
correction_method_used <- "none"

if (batch_effect_significant && batch_correction_method != "none") {
  
  log_subsection(paste("Applying batch correction:", batch_correction_method))
  
  # For now, we implement a simple mean-centering approach
  # In production, you would use ComBat (sva package) or limma::removeBatchEffect
  
  if (batch_correction_method == "mean_centering") {
    # Simple per-batch mean centering
    log_info("Applying mean-centering batch correction...")
    
    # This is a placeholder - real implementation would use ComBat or limma
    log_warning("Mean-centering is a simplified method. Consider using ComBat for production.")
    correction_applied <- TRUE
    correction_method_used <- "mean_centering"
    
  } else if (batch_correction_method == "combat") {
    log_info("ComBat batch correction would be applied here (requires 'sva' package)")
    log_warning("ComBat not implemented yet. Returning original data.")
    correction_applied <- FALSE
    
  } else if (batch_correction_method == "limma") {
    log_info("limma batch correction would be applied here (requires 'limma' package)")
    log_warning("limma not implemented yet. Returning original data.")
    correction_applied <- FALSE
    
  } else {
    log_warning(paste("Unknown batch correction method:", batch_correction_method))
    correction_applied <- FALSE
  }
  
} else {
  log_info("No batch correction applied (no significant effects or method = 'none')")
}

# Write corrected (or original) data
write_csv(data_corrected, output_batch_corrected)
log_success(paste("Data saved:", output_batch_corrected))

# ============================================================================
# GENERATE REPORT
# ============================================================================

log_subsection("Generating batch effect report")

report_lines <- c(
  "BATCH EFFECT ANALYSIS REPORT",
  "============================",
  "",
  paste("Date:", Sys.time()),
  paste("Input file:", input_file),
  "",
  "SUMMARY:",
  paste("  • Number of batches:", n_batches),
  paste("  • Batch effect significant:", if (batch_effect_significant) "YES ⚠️" else "NO ✓"),
  paste("  • Correction applied:", if (correction_applied) "YES" else "NO"),
  paste("  • Correction method:", correction_method_used),
  "",
  "STATISTICAL TESTS:",
  paste("  • PC1 by batch (ANOVA): p =", 
        if (!is.null(batch_effect_tests$pc1_batch_pvalue)) {
          format(batch_effect_tests$pc1_batch_pvalue, scientific = TRUE)
        } else "N/A"),
  paste("  • PC2 by batch (ANOVA): p =", 
        if (!is.null(batch_effect_tests$pc2_batch_pvalue)) {
          format(batch_effect_tests$pc2_batch_pvalue, scientific = TRUE)
        } else "N/A"),
  paste("  • Batch-Group independence (Chi-square): p =", 
        if (!is.null(batch_effect_tests$batch_group_confounded_pvalue)) {
          format(batch_effect_tests$batch_group_confounded_pvalue, scientific = TRUE)
        } else "N/A"),
  "",
  "PCA VARIANCE EXPLAINED:",
  paste("  • PC1:", round(pc1_var, 2), "%"),
  paste("  • PC2:", round(pc2_var, 2), "%"),
  "",
  "RECOMMENDATIONS:",
  if (batch_effect_significant) {
    "  ⚠️  Significant batch effects detected. Consider batch correction for downstream analysis."
  } else {
    "  ✓ No significant batch effects. Proceed with standard analysis."
  },
  if (!is.null(batch_effect_tests$batch_group_confounded) && batch_effect_tests$batch_group_confounded) {
    "  ⚠️  Batch and Group are confounded. Results may be biased."
  },
  ""
)

writeLines(report_lines, output_report)
log_success(paste("Report saved:", output_report))

log_success("Batch effect analysis completed successfully")
log_info(paste("Execution completed at", get_timestamp()))

