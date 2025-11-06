#!/usr/bin/env Rscript
# ============================================================================
# STEP 3: Clustering Analysis (Structure Discovery)
# ============================================================================
# Purpose: Identify clusters of miRNAs with similar oxidation patterns
#          This step runs early in the pipeline (after Step 2) to discover
#          data structure before functional interpretation.
#
# Execution order: Step 1 → Step 1.5 → Step 2 → Step 3 (FIRST, before 4,5,6)
#
# Snakemake parameters:
#   input: Statistical comparisons and VAF-filtered data from Step 2
#   output: Cluster assignments and summary tables
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(readr)
  library(stringr)
  library(stats)  # For dist, hclust
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
  file.path(dirname(snakemake@output[[1]]), "clustering_analysis.log")
}
initialize_logging(log_file, context = "Step 3.1 - Clustering Analysis")

log_section("STEP 3: Clustering Analysis (Structure Discovery)")

# ============================================================================
# GET SNAKEMAKE PARAMETERS
# ============================================================================

input_statistical <- snakemake@input[["comparisons"]]
input_vaf_filtered <- snakemake@input[["filtered_data"]]
output_cluster_assignments <- snakemake@output[["cluster_assignments"]]
output_cluster_summary <- snakemake@output[["cluster_summary"]]

config <- snakemake@config
alpha <- if (!is.null(config$analysis$alpha)) config$analysis$alpha else 0.05
seed_start <- if (!is.null(config$analysis$seed_region$start)) config$analysis$seed_region$start else 2
seed_end <- if (!is.null(config$analysis$seed_region$end)) config$analysis$seed_region$end else 8

log_info(paste("Input statistical:", input_statistical))
log_info(paste("Input VAF filtered:", input_vaf_filtered))
log_info(paste("Seed region: positions", seed_start, "-", seed_end))

ensure_output_dir(dirname(output_cluster_assignments))
ensure_output_dir(dirname(output_cluster_summary))

# ============================================================================
# LOAD DATA
# ============================================================================

log_subsection("Loading data")

statistical_results <- tryCatch({
  result <- read_csv(input_statistical, show_col_types = FALSE)
  log_success(paste("Loaded:", nrow(result), "SNVs from statistical results"))
  result
}, error = function(e) {
  handle_error(e, context = "Step 3.1 - Data Loading", exit_code = 1, log_file = log_file)
})

vaf_data <- tryCatch({
  result <- read_csv(input_vaf_filtered, show_col_types = FALSE)
  log_success(paste("Loaded:", nrow(result), "SNVs from VAF filtered data"))
  result
}, error = function(e) {
  handle_error(e, context = "Step 3.1 - Data Loading", exit_code = 1, log_file = log_file)
})

# Normalize column names
if ("miRNA name" %in% names(vaf_data)) {
  vaf_data <- vaf_data %>% rename(miRNA_name = `miRNA name`)
}
if ("pos:mut" %in% names(vaf_data)) {
  vaf_data <- vaf_data %>% rename(pos.mut = `pos:mut`)
}

# Extract sample groups
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
  handle_error(e, context = "Step 3.1 - Group Identification", exit_code = 1, log_file = log_file)
})

# Get dynamic group names
unique_groups <- sort(unique(sample_groups$group))
if (length(unique_groups) < 2) {
  stop("Need at least 2 groups for clustering. Found:", paste(unique_groups, collapse = ", "))
}

group1_name <- unique_groups[1]
group2_name <- unique_groups[2]

group1_samples <- sample_groups %>% filter(group == group1_name) %>% pull(sample_id)
group2_samples <- sample_groups %>% filter(group == group2_name) %>% pull(sample_id)

log_info(paste("Group 1 (", group1_name, ") samples:", length(group1_samples)))
log_info(paste("Group 2 (", group2_name, ") samples:", length(group2_samples)))

# For backward compatibility
if (group1_name == "ALS" || str_detect(group1_name, regex("als|disease", ignore_case = TRUE))) {
  als_samples <- group1_samples
  control_samples <- group2_samples
} else if (group2_name == "ALS" || str_detect(group2_name, regex("als|disease", ignore_case = TRUE))) {
  als_samples <- group2_samples
  control_samples <- group1_samples
} else {
  als_samples <- group1_samples
  control_samples <- group2_samples
}

# ============================================================================
# PREPARE DATA FOR CLUSTERING
# ============================================================================

log_subsection("Preparing data for clustering")

# Filter significant G>T mutations in seed region
significant_gt <- statistical_results %>%
  filter(
    str_detect(pos.mut, ":GT$"),
    !is.na(t_test_fdr) | !is.na(wilcoxon_fdr),
    (t_test_fdr < alpha | wilcoxon_fdr < alpha),
    !is.na(log2_fold_change)
  ) %>%
  mutate(
    position = as.numeric(str_extract(pos.mut, "^\\d+")),
    in_seed = position >= seed_start & position <= seed_end
  ) %>%
  filter(in_seed == TRUE) %>%
  distinct(miRNA_name, pos.mut, .keep_all = TRUE)

log_info(paste("Significant G>T mutations for clustering:", nrow(significant_gt)))

# Create matrix: rows = miRNAs, columns = samples (or positions)
# Option 1: Cluster by sample patterns (miRNA x Sample matrix)
# Option 2: Cluster by position patterns (miRNA x Position matrix)

# We'll do both, but focus on sample-based clustering for main analysis
clustering_data <- vaf_data %>%
  filter(
    str_detect(pos.mut, ":GT$"),
    miRNA_name %in% significant_gt$miRNA_name
  ) %>%
  mutate(
    position = as.numeric(str_extract(pos.mut, "^\\d+")),
    in_seed = position >= seed_start & position <= seed_end
  ) %>%
  filter(in_seed == TRUE) %>%
  select(miRNA_name, all_of(sample_cols)) %>%
  group_by(miRNA_name) %>%
  summarise(
    across(all_of(sample_cols), ~ mean(.x, na.rm = TRUE)),
    .groups = "drop"
  ) %>%
  column_to_rownames(var = "miRNA_name") %>%
  as.matrix()

# Remove miRNAs with all zeros or all NAs
clustering_data <- clustering_data[rowSums(!is.na(clustering_data)) > 0 & rowSums(clustering_data, na.rm = TRUE) > 0, ]

log_info(paste("miRNAs for clustering:", nrow(clustering_data)))
log_info(paste("Samples for clustering:", ncol(clustering_data)))

# ============================================================================
# PERFORM CLUSTERING
# ============================================================================

log_subsection("Performing hierarchical clustering")

# Calculate distance matrix (Euclidean distance on normalized data)
# Normalize by row (z-score) for better clustering
clustering_data_norm <- t(scale(t(clustering_data)))
clustering_data_norm[is.na(clustering_data_norm)] <- 0

# Calculate distance
dist_matrix <- dist(clustering_data_norm, method = "euclidean")

# Hierarchical clustering
hc <- hclust(dist_matrix, method = "ward.D2")

# Determine optimal number of clusters (using elbow method or fixed k)
# For now, use k = 5-8 clusters based on typical miRNA analysis
optimal_k <- 6  # Can be adjusted based on data

cluster_assignments <- cutree(hc, k = optimal_k)

# Create cluster assignments table
cluster_assignments_df <- tibble(
  miRNA_name = names(cluster_assignments),
  cluster = as.numeric(cluster_assignments)
) %>%
  arrange(cluster, miRNA_name)

write_csv(cluster_assignments_df, output_cluster_assignments)
log_success(paste("Cluster assignments saved:", output_cluster_assignments))

# ============================================================================
# CLUSTER SUMMARY
# ============================================================================

log_subsection("Creating cluster summary")

# Detect group mean columns dynamically (before summarise)
group1_mean_col <- paste0(group1_name, "_mean")
group2_mean_col <- paste0(group2_name, "_mean")
if (!group1_mean_col %in% names(significant_gt)) group1_mean_col <- "ALS_mean"
if (!group2_mean_col %in% names(significant_gt)) group2_mean_col <- "Control_mean"

cluster_summary <- cluster_assignments_df %>%
  left_join(
    significant_gt %>%
      group_by(miRNA_name) %>%
      summarise(
        n_mutations = n(),
        avg_log2FC = mean(log2_fold_change, na.rm = TRUE),
        avg_group1_mean = mean(!!sym(group1_mean_col), na.rm = TRUE),
        avg_group2_mean = mean(!!sym(group2_mean_col), na.rm = TRUE),
        # Backward compatibility
        avg_ALS_mean = if ("ALS_mean" %in% names(significant_gt)) mean(ALS_mean, na.rm = TRUE) else NA_real_,
        avg_Control_mean = if ("Control_mean" %in% names(significant_gt)) mean(Control_mean, na.rm = TRUE) else NA_real_,
        .groups = "drop"
      ),
    by = "miRNA_name"
  ) %>%
  group_by(cluster) %>%
  summarise(
    n_miRNAs = n(),
    avg_n_mutations = mean(n_mutations, na.rm = TRUE),
    avg_log2FC = mean(avg_log2FC, na.rm = TRUE),
    avg_group1_mean = mean(avg_group1_mean, na.rm = TRUE),
    avg_group2_mean = mean(avg_group2_mean, na.rm = TRUE),
    avg_oxidation_diff = mean(avg_group1_mean - avg_group2_mean, na.rm = TRUE),
    # Backward compatibility
    avg_ALS_mean = mean(avg_ALS_mean, na.rm = TRUE),
    avg_Control_mean = mean(avg_Control_mean, na.rm = TRUE),
    avg_oxidation_diff_legacy = if (!all(is.na(avg_ALS_mean)) && !all(is.na(avg_Control_mean))) {
      mean(avg_ALS_mean - avg_Control_mean, na.rm = TRUE)
    } else {
      avg_oxidation_diff
    },
    .groups = "drop"
  ) %>%
  arrange(desc(avg_oxidation_diff))

write_csv(cluster_summary, output_cluster_summary)
log_success(paste("Cluster summary saved:", output_cluster_summary))

log_info(paste("Number of clusters:", optimal_k))
log_info(paste("Cluster sizes:", paste(cluster_summary$n_miRNAs, collapse = ", ")))

log_success("Step 3.1 completed successfully")

