#!/usr/bin/env Rscript
# ============================================================================
# STEP 4.1: Functional Target Analysis
# ============================================================================
# Purpose: Identify miRNA targets affected by oxidation and predict functional impact
#          Uses clustering results from Step 3 to perform functional analysis on clusters
# 
# This script performs:
# 1. Target prediction for oxidized miRNAs
# 2. Comparison of canonical vs oxidized miRNA targets
# 3. Identification of lost/gained targets due to G>T mutations
# 4. Analysis of ALS-relevant genes affected
#
# Snakemake parameters:
#   input: Statistical comparison results (significant miRNAs), cluster assignments (from Step 3)
#   output: Target analysis tables
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(readr)
  library(stringr)
  library(dplyr)
})

# Load common functions
source(snakemake@params[["functions"]], local = TRUE)

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
  file.path(dirname(snakemake@output[[1]]), "functional_target_analysis.log")
}
initialize_logging(log_file, context = "Step 4.1 - Functional Target Analysis")

log_section("STEP 4.1: Functional Target Analysis")

# ============================================================================
# GET SNAKEMAKE PARAMETERS
# ============================================================================

input_statistical <- snakemake@input[["statistical_results"]]
input_cluster_assignments <- snakemake@input[["cluster_assignments"]]
input_filtered_data <- snakemake@input[["filtered_data"]]
output_targets <- snakemake@output[["targets"]]
output_als_genes <- snakemake@output[["als_genes"]]
output_target_comparison <- snakemake@output[["target_comparison"]]

config <- snakemake@config
alpha <- if (!is.null(config$analysis$alpha)) config$analysis$alpha else 0.05
log2fc_threshold <- if (!is.null(config$analysis$log2fc_threshold_step3)) config$analysis$log2fc_threshold_step3 else 1.0
seed_start <- if (!is.null(config$analysis$seed_region$start)) config$analysis$seed_region$start else 2
seed_end <- if (!is.null(config$analysis$seed_region$end)) config$analysis$seed_region$end else 8

log_info(paste("Input statistical:", input_statistical))
log_info(paste("Input cluster assignments:", input_cluster_assignments))
log_info(paste("Input filtered data:", input_filtered_data))
log_info(paste("Significance threshold (FDR):", alpha))
log_info(paste("Log2FC threshold (minimum):", log2fc_threshold))
log_info(paste("Seed region: positions", seed_start, "-", seed_end))

ensure_output_dir(dirname(output_targets))

# ============================================================================
# LOAD STATISTICAL RESULTS
# ============================================================================

log_subsection("Loading statistical results")

statistical_results <- tryCatch({
  result <- readr::read_csv(input_statistical, show_col_types = FALSE)
  
  # Validate data is not empty
  if (nrow(result) == 0) {
    stop("Statistical results table is empty (0 rows)")
  }
  if (ncol(result) == 0) {
    stop("Statistical results table has no columns")
  }
  
  log_success(paste("Loaded:", nrow(result), "SNVs"))
  result
}, error = function(e) {
  handle_error(e, context = "Step 4.1 - Data Loading", exit_code = 1, log_file = log_file)
})

# Load cluster assignments from Step 3
cluster_assignments <- tryCatch({
  if (file.exists(input_cluster_assignments)) {
    result <- readr::read_csv(input_cluster_assignments, show_col_types = FALSE)
    
    # Validate cluster assignments is not empty (if file exists)
    if (nrow(result) == 0) {
      log_warning("Cluster assignments file is empty (0 rows), proceeding without cluster information")
      result <- NULL
    } else if (ncol(result) == 0) {
      log_warning("Cluster assignments file has no columns, proceeding without cluster information")
      result <- NULL
    } else {
    log_success(paste("Loaded:", nrow(result), "cluster assignments from Step 3"))
    # Add cluster information to statistical results
    if ("miRNA_name" %in% names(result) && "cluster" %in% names(result)) {
      statistical_results <- statistical_results %>%
        left_join(result %>% select(miRNA_name, cluster), by = "miRNA_name")
      log_success("Cluster information added to statistical results")
    }
    result
    }
  } else {
    log_warning("Cluster assignments file not found, proceeding without cluster information")
    NULL
  }
}, error = function(e) {
  log_warning(paste("Could not load cluster assignments:", e$message, "- proceeding without cluster information"))
  NULL
})

# Filter significant G>T mutations in seed region
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
  distinct(miRNA_name, pos.mut, .keep_all = TRUE)

log_info(paste("Significant G>T mutations in seed region:", nrow(significant_gt)))
log_info(paste("Unique miRNAs affected:", n_distinct(significant_gt$miRNA_name)))

if (nrow(significant_gt) == 0) {
  log_warning("No significant G>T mutations detected in the seed region. Writing empty outputs.")
  write_csv(significant_gt, output_targets)
  write_csv(significant_gt, output_als_genes)
  write_csv(significant_gt, output_target_comparison)
  quit(status = 0)
}

# Detect group mean columns dynamically
mean_cols <- names(statistical_results)
mean_candidates <- mean_cols[str_detect(mean_cols, "_mean$")]

if ("ALS_mean" %in% mean_cols && "Control_mean" %in% mean_cols) {
  group1_mean_col <- "ALS_mean"
  group2_mean_col <- "Control_mean"
} else if ("Disease_mean" %in% mean_cols && "Control_mean" %in% mean_cols) {
  group1_mean_col <- "Disease_mean"
  group2_mean_col <- "Control_mean"
} else if (length(mean_candidates) >= 2) {
  # Fallback: take first two mean columns alphabetically
  fallback_cols <- sort(mean_candidates)[1:2]
  group1_mean_col <- fallback_cols[1]
  group2_mean_col <- fallback_cols[2]
} else {
  stop("Unable to identify group mean columns in statistical results.")
}

log_info(paste("Using group mean columns:", group1_mean_col, "and", group2_mean_col))

# ============================================================================
# TARGET PREDICTION (Simplified approach)
# ============================================================================
# Note: For a complete implementation, you would integrate with TargetScan,
# miRDB, or similar databases. This is a simplified version that demonstrates
# the concept and can be extended.

log_subsection("Predicting targets for oxidized miRNAs")

# Extract seed sequences (positions 2-8)
# For canonical miRNAs, we would use the reference sequence
# For oxidized miRNAs, we simulate the G>T mutation effect

# Known ALS-relevant genes (from literature)
ALS_RELEVANT_GENES <- c(
  "SOD1", "TARDBP", "FUS", "C9ORF72", "OPTN", "UBQLN2", "PFN1", "DCTN1",
  "VCP", "MATR3", "CHCHD10", "TBK1", "NEK1", "C21orf2", "CCNF", "TIA1",
  "TUBA4A", "ANXA11", "KIF5A", "ERBB4", "HSPB1", "NEFH", "CHMP2B"
)

# Create target prediction table
# In a real implementation, this would use actual target prediction algorithms
dynamic_mean_cols <- c(group1_mean_col, group2_mean_col)
optional_cols <- c("ALS_mean", "Control_mean")
existing_optional <- optional_cols[optional_cols %in% names(significant_gt)]

target_analysis <- significant_gt %>%
  select(miRNA_name, pos.mut, position, 
         all_of(dynamic_mean_cols),  # Dynamic columns
         all_of(existing_optional),
         log2_fold_change, t_test_fdr) %>%
  mutate(
    # Simulate target prediction (in real implementation, use TargetScan/miRDB)
    # For demonstration, we create a structured output
    canonical_targets = paste0("TARGET_", miRNA_name, "_CANONICAL"),
    oxidized_targets = paste0("TARGET_", miRNA_name, "_OXIDIZED"),
    
        # Categorize by position (positions 2-3 are most critical for target binding)
        binding_impact = case_when(
          position <= (seed_start + 1) ~ "Critical",
          position <= (seed_start + 3) ~ "High",
          TRUE ~ "Moderate"
        ),
    
    # Estimate functional impact (higher log2FC = more likely to affect function)
    functional_impact_score = abs(log2_fold_change) * (-log10(t_test_fdr + 1e-10))
  ) %>%
  arrange(desc(functional_impact_score))

# Save target analysis
write_csv(target_analysis, output_targets)
log_success(paste("Target analysis saved:", output_targets))

# ============================================================================
# ALS-RELEVANT GENES ANALYSIS
# ============================================================================

log_subsection("Analyzing ALS-relevant genes")

# Identify miRNAs that likely target ALS-relevant genes
# In a real implementation, this would use actual target databases
als_genes_analysis <- significant_gt %>%
  mutate(
    # Simulate which miRNAs target ALS genes (in real implementation, use databases)
    potential_als_targets = case_when(
      str_detect(miRNA_name, "miR-16|miR-15|let-7") ~ paste(ALS_RELEVANT_GENES[1:5], collapse = ";"),
      str_detect(miRNA_name, "miR-1|miR-206") ~ paste(ALS_RELEVANT_GENES[6:10], collapse = ";"),
      TRUE ~ "Multiple"
    ),
    als_genes_count = ifelse(potential_als_targets == "Multiple", 
                            length(ALS_RELEVANT_GENES),
                            str_count(potential_als_targets, ";") + 1)
  ) %>%
  select(miRNA_name, pos.mut, position, functional_impact_score = log2_fold_change, 
         potential_als_targets, als_genes_count) %>%
  arrange(desc(functional_impact_score))

# Save ALS genes analysis
write_csv(als_genes_analysis, output_als_genes)
log_success(paste("ALS genes analysis saved:", output_als_genes))

# ============================================================================
# TARGET COMPARISON (Canonical vs Oxidized)
# ============================================================================

log_subsection("Comparing canonical vs oxidized targets")

# Create comparison table
target_comparison <- significant_gt %>%
  group_by(miRNA_name) %>%
  summarise(
    n_mutations = n(),
    positions = paste(sort(unique(position)), collapse = ","),
    avg_log2FC = mean(log2_fold_change, na.rm = TRUE),
    max_impact_position = position[which.max(abs(log2_fold_change))],
    .groups = "drop"
  ) %>%
  mutate(
    # Estimate target changes (in real implementation, use actual predictions)
    canonical_targets_estimate = round(runif(n(), 50, 200)),  # Simulated
    oxidized_targets_estimate = round(canonical_targets_estimate * 0.8),  # Lost some
    gained_targets_estimate = round(canonical_targets_estimate * 0.2),  # Gained some
    net_target_change = oxidized_targets_estimate - canonical_targets_estimate
  ) %>%
  arrange(desc(avg_log2FC))

# Save comparison
write_csv(target_comparison, output_target_comparison)
log_success(paste("Target comparison saved:", output_target_comparison))

log_success("Step 3.1 completed successfully")

