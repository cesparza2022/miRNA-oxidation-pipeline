#!/usr/bin/env Rscript
# ============================================================================
# STEP 4: miRNA Family Analysis (Biological Grouping)
# ============================================================================
# Purpose: Identify miRNA families and summarize oxidation patterns by family
#          This step runs early in the pipeline (after Step 2) to compare
#          data-driven clusters with known biological families.
#
# Execution order: Step 1 → Step 1.5 → Step 2 → Step 3 → Step 4 (parallel with 5,6)
#
# Snakemake parameters:
#   input: Statistical comparison results from Step 2, VAF-filtered data
#   output: Family summary and comparison tables
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(readr)
  library(stringr)
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
  file.path(dirname(snakemake@output[[1]]), "family_identification.log")
}
initialize_logging(log_file, context = "Step 4.1 - Family Identification")

log_section("STEP 4: miRNA Family Analysis (Biological Grouping)")

# ============================================================================
# GET SNAKEMAKE PARAMETERS
# ============================================================================

input_statistical <- snakemake@input[["comparisons"]]
input_vaf_filtered <- snakemake@input[["filtered_data"]]
output_family_summary <- snakemake@output[["family_summary"]]
output_family_comparison <- snakemake@output[["family_comparison"]]

config <- snakemake@config
alpha <- if (!is.null(config$analysis$alpha)) config$analysis$alpha else 0.05
seed_start <- if (!is.null(config$analysis$seed_region$start)) config$analysis$seed_region$start else 2
seed_end <- if (!is.null(config$analysis$seed_region$end)) config$analysis$seed_region$end else 8

log_info(paste("Input statistical:", input_statistical))
log_info(paste("Input VAF filtered:", input_vaf_filtered))
log_info(paste("Seed region: positions", seed_start, "-", seed_end))

ensure_output_dir(dirname(output_family_summary))
ensure_output_dir(dirname(output_family_comparison))

# ============================================================================
# FUNCTION: Extract miRNA Family
# ============================================================================

extract_mirna_family <- function(mirna_name) {
  # Extract family from miRNA name
  # Examples:
  #   hsa-miR-196a-5p → miR-196
  #   hsa-let-7d-5p → let-7
  #   hsa-miR-1-3p → miR-1
  
  if (str_detect(mirna_name, "let-\\d+")) {
    return("let-7")
  } else if (str_detect(mirna_name, "miR-(\\d+)")) {
    family_num <- str_extract(mirna_name, "miR-(\\d+)") %>% str_remove("miR-")
    return(paste0("miR-", family_num))
  } else {
    return("Other")
  }
}

# ============================================================================
# LOAD DATA
# ============================================================================

log_subsection("Loading data")

statistical_results <- tryCatch({
  result <- read_csv(input_statistical, show_col_types = FALSE)
  log_success(paste("Loaded:", nrow(result), "SNVs from statistical results"))
  result
}, error = function(e) {
  handle_error(e, context = "Step 4.1 - Data Loading", exit_code = 1, log_file = log_file)
})

vaf_data <- tryCatch({
  result <- read_csv(input_vaf_filtered, show_col_types = FALSE)
  log_success(paste("Loaded:", nrow(result), "SNVs from VAF filtered data"))
  result
}, error = function(e) {
  handle_error(e, context = "Step 4.1 - Data Loading", exit_code = 1, log_file = log_file)
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
  handle_error(e, context = "Step 4.1 - Group Identification", exit_code = 1, log_file = log_file)
})

# Get dynamic group names
unique_groups <- sort(unique(sample_groups$group))
if (length(unique_groups) < 2) {
  stop("Need at least 2 groups for family analysis. Found:", paste(unique_groups, collapse = ", "))
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
# IDENTIFY FAMILIES
# ============================================================================

log_subsection("Identifying miRNA families")

# Add family information to statistical results
statistical_results <- statistical_results %>%
  mutate(
    family = map_chr(miRNA_name, extract_mirna_family),
    position = as.numeric(str_extract(pos.mut, "^\\d+")),
    in_seed = position >= seed_start & position <= seed_end
  )

# Add family information to VAF data
vaf_data <- vaf_data %>%
  mutate(
    family = map_chr(miRNA_name, extract_mirna_family),
    position = as.numeric(str_extract(pos.mut, "^\\d+")),
    in_seed = position >= seed_start & position <= seed_end
  )

log_info(paste("Unique families identified:", n_distinct(statistical_results$family)))
log_info(paste("Top 10 families by SNV count:", 
               paste(head(names(sort(table(statistical_results$family), decreasing = TRUE)), 10), 
                     collapse = ", ")))

# ============================================================================
# FAMILY SUMMARY TABLE
# ============================================================================

log_subsection("Creating family summary table")

# Detect group mean columns dynamically
group1_mean_col <- paste0(group1_name, "_mean")
group2_mean_col <- paste0(group2_name, "_mean")
# Fallback to ALS/Control if dynamic columns not found
if (!group1_mean_col %in% names(statistical_results)) {
  group1_mean_col <- "ALS_mean"
}
if (!group2_mean_col %in% names(statistical_results)) {
  group2_mean_col <- "Control_mean"
}

family_summary <- statistical_results %>%
  filter(in_seed == TRUE) %>%  # Focus on seed region
  group_by(family) %>%
  summarise(
    n_miRNAs = n_distinct(miRNA_name),
    n_mutations = n(),
    n_seed_mutations = sum(in_seed, na.rm = TRUE),
    avg_log2FC = mean(log2_fold_change, na.rm = TRUE),
    median_log2FC = median(log2_fold_change, na.rm = TRUE),
    n_significant = sum((t_test_fdr < alpha | wilcoxon_fdr < alpha) & !is.na(log2_fold_change), na.rm = TRUE),
    avg_group1_mean = mean(!!sym(group1_mean_col), na.rm = TRUE),
    avg_group2_mean = mean(!!sym(group2_mean_col), na.rm = TRUE),
    # Backward compatibility columns
    avg_ALS_mean = if ("ALS_mean" %in% names(statistical_results)) mean(ALS_mean, na.rm = TRUE) else NA_real_,
    avg_Control_mean = if ("Control_mean" %in% names(statistical_results)) mean(Control_mean, na.rm = TRUE) else NA_real_,
    .groups = "drop"
  ) %>%
  mutate(
    avg_oxidation_diff = avg_group1_mean - avg_group2_mean,
    # Backward compatibility (use vectorized ifelse for row-wise operations)
    avg_oxidation_diff_legacy = ifelse(
      !is.na(avg_ALS_mean) & !is.na(avg_Control_mean),
      avg_ALS_mean - avg_Control_mean,
      avg_oxidation_diff
    ),
    pct_significant = (n_significant / n_mutations) * 100
  ) %>%
  arrange(desc(n_significant), desc(n_mutations))

write_csv(family_summary, output_family_summary)
log_success(paste("Family summary saved:", output_family_summary))

# ============================================================================
# FAMILY COMPARISON TABLE (ALS vs Control)
# ============================================================================

log_subsection(paste("Creating family comparison table (", group1_name, " vs ", group2_name, ")"))

# Calculate per-family statistics for ALS vs Control
family_comparison <- vaf_data %>%
  filter(in_seed == TRUE) %>%  # Focus on seed region
  mutate(
    # Calculate per-sample VAF values (using dynamic group names)
    group1_mean_vaf = rowMeans(select(., all_of(group1_samples)), na.rm = TRUE),
    group2_mean_vaf = rowMeans(select(., all_of(group2_samples)), na.rm = TRUE),
    # Backward compatibility
    als_mean_vaf = rowMeans(select(., all_of(als_samples)), na.rm = TRUE),
    control_mean_vaf = rowMeans(select(., all_of(control_samples)), na.rm = TRUE)
  ) %>%
  group_by(family) %>%
  summarise(
    n_miRNAs = n_distinct(miRNA_name),
    n_mutations = n(),
    group1_mean_vaf = mean(group1_mean_vaf, na.rm = TRUE),
    group2_mean_vaf = mean(group2_mean_vaf, na.rm = TRUE),
    group1_median_vaf = median(group1_mean_vaf, na.rm = TRUE),
    group2_median_vaf = median(group2_mean_vaf, na.rm = TRUE),
    # Backward compatibility
    als_mean_vaf = mean(als_mean_vaf, na.rm = TRUE),
    control_mean_vaf = mean(control_mean_vaf, na.rm = TRUE),
    als_median_vaf = median(als_mean_vaf, na.rm = TRUE),
    control_median_vaf = median(control_mean_vaf, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    vaf_difference = group1_mean_vaf - group2_mean_vaf,
    fold_change = ifelse(group2_mean_vaf > 0, group1_mean_vaf / group2_mean_vaf, NA_real_),
    # Backward compatibility
    vaf_difference_legacy = als_mean_vaf - control_mean_vaf,
    log2_fold_change = log2(fold_change)
  ) %>%
  arrange(desc(abs(vaf_difference)))

# Join with family summary for additional context
family_comparison <- family_comparison %>%
  left_join(
    family_summary %>% select(family, n_significant, avg_log2FC),
    by = "family"
  ) %>%
  arrange(desc(n_significant), desc(abs(vaf_difference)))

write_csv(family_comparison, output_family_comparison)
log_success(paste("Family comparison saved:", output_family_comparison))

log_success("Step 4.1 completed successfully")

