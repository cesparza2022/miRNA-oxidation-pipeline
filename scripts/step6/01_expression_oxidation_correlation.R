#!/usr/bin/env Rscript
# ============================================================================
# STEP 6.1: Expression vs Oxidation Correlation Analysis
# ============================================================================
# Purpose: Analyze correlation between miRNA expression levels (RPM) and 
#          oxidative damage (G>T mutations in seed region)
#
# This step uses SIGNIFICANT G>T mutations in seed region (same criteria as Steps 3-5):
# - G>T mutations only (str_detect(pos.mut, ":GT$"))
# - In seed region (positions 2-8)
# - Statistically significant (FDR < alpha)
# - Higher in ALS (log2FC > threshold)
#
# Snakemake parameters:
#   input: Statistical comparisons, VAF-filtered data, and raw expression data
#   output: Correlation tables and summary statistics
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(readr)
  library(stringr)
})

# Load common functions
source(snakemake@params[["functions"]], local = TRUE)

# Initialize logging
log_file <- if (length(snakemake@log) > 0) snakemake@log[[1]] else {
  file.path(dirname(snakemake@output[[1]]), "correlation_analysis.log")
}
initialize_logging(log_file, context = "Step 6.1 - Expression-Oxidation Correlation")

log_section("STEP 6.1: Expression vs Oxidation Correlation Analysis")

# ============================================================================
# GET SNAKEMAKE PARAMETERS
# ============================================================================

input_statistical <- snakemake@input[["comparisons"]]
input_vaf_filtered <- snakemake@input[["filtered_data"]]
input_expression <- snakemake@input[["expression_data"]]
output_correlation <- snakemake@output[["correlation_table"]]
output_expression_summary <- snakemake@output[["expression_summary"]]

config <- snakemake@config
alpha <- if (!is.null(config$analysis$alpha)) config$analysis$alpha else 0.05
log2fc_threshold <- if (!is.null(config$analysis$log2fc_threshold_step3)) config$analysis$log2fc_threshold_step3 else 1.0
seed_start <- if (!is.null(config$analysis$seed_region$start)) config$analysis$seed_region$start else 2
seed_end <- if (!is.null(config$analysis$seed_region$end)) config$analysis$seed_region$end else 8

log_info(paste("Input statistical:", input_statistical))
log_info(paste("Input VAF filtered:", input_vaf_filtered))
log_info(paste("Input expression data:", input_expression))
log_info(paste("Significance threshold (FDR):", alpha))
log_info(paste("Log2FC threshold (minimum):", log2fc_threshold))
log_info(paste("Seed region: positions", seed_start, "-", seed_end))

ensure_output_dir(dirname(output_correlation))
ensure_output_dir(dirname(output_expression_summary))

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
  
  log_success(paste("Loaded:", nrow(result), "SNVs from statistical results"))
  result
}, error = function(e) {
  handle_error(e, context = "Step 6.1 - Data Loading", exit_code = 1, log_file = log_file)
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
  
  log_success(paste("Loaded:", nrow(result), "SNVs from VAF filtered data"))
  result
}, error = function(e) {
  handle_error(e, context = "Step 6.1 - Data Loading", exit_code = 1, log_file = log_file)
})

# Normalize column names
if ("miRNA name" %in% names(vaf_data)) {
  vaf_data <- vaf_data %>% rename(miRNA_name = `miRNA name`)
}
if ("pos:mut" %in% names(vaf_data)) {
  vaf_data <- vaf_data %>% rename(pos.mut = `pos:mut`)
}

# CRITICAL: Filter to only SNV count columns BEFORE any dplyr operations
# This avoids the "variable names are limited to 10000 bytes" error
source("scripts/utils/data_loading_helpers.R", local = TRUE)
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
    vaf_data <- as.data.frame(vaf_data[, -total_indices, drop = FALSE])
    log_info(paste("Fallback: Excluded", length(total_cols), "total count columns"))
  }
}

# Load expression data (raw miRNA counts)
# Try to load from primary location, fallback to alt
expression_data <- NULL
if (file.exists(input_expression)) {
  expression_data <- tryCatch({
    result <- readr::read_tsv(input_expression, show_col_types = FALSE)
    
    # Validate expression data is not empty
    if (nrow(result) == 0) {
      log_warning("Expression data file is empty (0 rows), will use fallback")
      result <- NULL
    } else if (ncol(result) == 0) {
      log_warning("Expression data file has no columns, will use fallback")
      result <- NULL
    } else {
      log_success(paste("Loaded expression data from:", input_expression))
    }
    
    result
  }, error = function(e) {
    log_warning(paste("Failed to load primary expression file:", e$message))
    NULL
  })
}

if (is.null(expression_data) && !is.null(config$paths$data$raw_alt) && file.exists(config$paths$data$raw_alt)) {
  expression_data <- tryCatch({
    result <- readr::read_tsv(config$paths$data$raw_alt, show_col_types = FALSE)
    
    # Validate expression data is not empty
    if (nrow(result) == 0) {
      log_warning("Alternative expression data file is empty (0 rows), will use fallback")
      result <- NULL
    } else if (ncol(result) == 0) {
      log_warning("Alternative expression data file has no columns, will use fallback")
      result <- NULL
    } else {
      log_success(paste("Loaded expression data from alternative location:", config$paths$data$raw_alt))
      result
    }
  }, error = function(e) {
    log_warning(paste("Failed to load alternative expression file:", e$message))
    NULL
  })
}

if (is.null(expression_data)) {
  log_warning("Expression data not available. Will calculate from VAF data using sample counts.")
  # Calculate approximate expression from VAF data as fallback
  sample_cols <- setdiff(names(vaf_data), c("miRNA_name", "pos.mut", "miRNA name", "pos:mut"))
  
  # Estimate expression as sum of all mutations per miRNA (rough approximation)
  # Use column indices to avoid variable name limit
  sample_col_indices <- which(names(vaf_data) %in% sample_cols)
  vaf_matrix <- as.matrix(vaf_data[, sample_col_indices, drop = FALSE])
  
  expression_data <- vaf_data %>%
    mutate(
      total_reads = rowSums(vaf_matrix, na.rm = TRUE)
    ) %>%
    group_by(miRNA_name) %>%
    summarise(
      estimated_total_reads = sum(total_reads, na.rm = TRUE),
      n_samples = length(sample_cols),
      estimated_rpm = estimated_total_reads / n_samples,  # Rough RPM estimate
      .groups = "drop"
    ) %>%
    rename(`miRNA name` = miRNA_name)
  
  log_info("Using estimated expression from VAF data (sum of all mutation counts)")
} else {
  # Extract sample columns (those with "Magen-" prefix, excluding total columns)
  sample_cols_raw <- names(expression_data)[grep("Magen-", names(expression_data))]
  sample_cols_raw <- sample_cols_raw[!grepl("\\(PM\\+1MM\\+2MM\\)", sample_cols_raw)]
  total_cols <- names(expression_data)[grep("\\(PM\\+1MM\\+2MM\\)", names(expression_data))]
  
  # Normalize miRNA name column - use base R to avoid variable name limit
  if ("miRNA name" %in% names(expression_data)) {
    # Already correct
    mirna_col_name <- "miRNA name"
  } else if ("miRNA_name" %in% names(expression_data)) {
    names(expression_data)[names(expression_data) == "miRNA_name"] <- "miRNA name"
    mirna_col_name <- "miRNA name"
  } else if (any(grepl("miRNA|mirna", names(expression_data), ignore.case = TRUE))) {
    mirna_col <- names(expression_data)[grepl("miRNA|mirna", names(expression_data), ignore.case = TRUE)][1]
    names(expression_data)[names(expression_data) == mirna_col] <- "miRNA name"
    mirna_col_name <- "miRNA name"
  } else {
    stop("Could not find miRNA name column in expression data")
  }
  
  # Calculate RPM per miRNA
  # Use base R to avoid variable name limit - filter columns first
  # mirna_col_name is already set above
  
  if (length(total_cols) > 0) {
    # Filter to only miRNA name and total columns before processing
    keep_cols <- c(mirna_col_name, total_cols)
    keep_indices <- which(names(expression_data) %in% keep_cols)
    expr_filtered <- as.data.frame(expression_data[, keep_indices, drop = FALSE])
    
    # Verify total_cols exist in filtered data
    total_cols_in_filtered <- intersect(total_cols, names(expr_filtered))
    if (length(total_cols_in_filtered) == 0) {
      # Fallback: no total columns, use sample columns instead
      log_warning("No total columns found, falling back to sample columns")
      # Recalculate with sample columns
      keep_cols <- c(mirna_col_name, sample_cols_raw)
      keep_indices <- which(names(expression_data) %in% keep_cols)
      expr_filtered <- as.data.frame(expression_data[, keep_indices, drop = FALSE])
      sample_matrix <- as.matrix(expr_filtered[, sample_cols_raw, drop = FALSE])
      expr_filtered$total_reads <- rowSums(sample_matrix, na.rm = TRUE)
    } else {
      # Calculate using base R with total columns
      total_matrix <- as.matrix(expr_filtered[, total_cols_in_filtered, drop = FALSE])
      expr_filtered$total_reads <- rowSums(total_matrix, na.rm = TRUE)
    }
    
    # Aggregate using base R
    # Rename miRNA column to avoid spaces in formula
    mirna_col_index <- which(names(expr_filtered) == mirna_col_name)
    names(expr_filtered)[mirna_col_index] <- "miRNA_name_temp"
    
    # Use formula interface for aggregate
    expression_data <- aggregate(
      total_reads ~ miRNA_name_temp,
      data = expr_filtered,
      FUN = sum,
      na.rm = TRUE
    )
    names(expression_data)[1] <- "miRNA name"
    expression_data$n_samples <- length(sample_cols_raw)
    expression_data$estimated_rpm <- expression_data$total_reads / expression_data$n_samples
    expression_data <- expression_data[, c("miRNA name", "total_reads", "n_samples", "estimated_rpm")]
    
    if (length(total_cols_in_filtered) > 0) {
      log_info("Calculated RPM from total read columns")
    } else {
      log_info("Calculated RPM from sample columns (no total columns found)")
    }
  } else {
    # Fallback: use sample columns directly
    keep_cols <- c(mirna_col_name, sample_cols_raw)
    keep_indices <- which(names(expression_data) %in% keep_cols)
    expr_filtered <- as.data.frame(expression_data[, keep_indices, drop = FALSE])
    
    # Calculate using base R
    sample_matrix <- as.matrix(expr_filtered[, sample_cols_raw, drop = FALSE])
    expr_filtered$total_reads <- rowSums(sample_matrix, na.rm = TRUE)
    
    # Aggregate using base R
    # Rename miRNA column to avoid spaces in formula
    mirna_col_index <- which(names(expr_filtered) == mirna_col_name)
    names(expr_filtered)[mirna_col_index] <- "miRNA_name_temp"
    
    # Use formula interface for aggregate
    expression_data <- aggregate(
      total_reads ~ miRNA_name_temp,
      data = expr_filtered,
      FUN = sum,
      na.rm = TRUE
    )
    names(expression_data)[1] <- "miRNA name"
    expression_data$n_samples <- length(sample_cols_raw)
    expression_data$estimated_rpm <- expression_data$total_reads / expression_data$n_samples
    expression_data <- expression_data[, c("miRNA name", "total_reads", "n_samples", "estimated_rpm")]
    
    log_info("Calculated RPM from sample columns (no total columns found)")
  }
}

# ============================================================================
# FILTER SIGNIFICANT G>T MUTATIONS IN SEED REGION
# ============================================================================

log_subsection("Filtering significant G>T mutations in seed region")

# Normalize column names for statistical results
if ("miRNA name" %in% names(statistical_results)) {
  statistical_results <- statistical_results %>% rename(miRNA_name = `miRNA name`)
}
if ("pos:mut" %in% names(statistical_results)) {
  statistical_results <- statistical_results %>% rename(pos.mut = `pos:mut`)
}

# Filter significant G>T mutations in seed region (same criteria as Steps 3-5)
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
  log_warning("No significant G>T mutations in seed region found. Skipping Step 6.1.")
  write_csv(tibble(), output_correlation)
  write_csv(tibble(), output_expression_summary)
  log_success("Step 6.1 completed (skipped due to no data).")
  quit(save = "no", status = 0)
}

# ============================================================================
# CALCULATE OXIDATION METRICS (G>T in seed region)
# ============================================================================

log_subsection("Calculating oxidation metrics for significant G>T in seed region")

# Extract sample columns from VAF data
sample_cols <- setdiff(names(vaf_data), c("miRNA_name", "pos.mut", "miRNA name", "pos:mut"))

# Filter VAF data to only include significant G>T mutations in seed region
# Use base R subsetting instead of joins to avoid variable name limit
significant_gt_keys <- significant_gt %>%
  select(miRNA_name, pos.mut) %>%
  distinct()

# Create keys for matching (avoid dplyr operations on large data frames)
vaf_keys <- paste(vaf_data$miRNA_name, vaf_data$pos.mut, sep = "|||")
gt_keys <- paste(significant_gt_keys$miRNA_name, significant_gt_keys$pos.mut, sep = "|||")

# Filter using base R subsetting
matching_indices <- which(vaf_keys %in% gt_keys)
if (length(matching_indices) > 0) {
  oxidation_rows <- vaf_data[matching_indices, , drop = FALSE]
  
  # Calculate position and filter seed region using base R
  oxidation_rows$position <- as.numeric(gsub(":.*$", "", oxidation_rows$pos.mut))
  oxidation_rows$in_seed <- oxidation_rows$position >= seed_start & oxidation_rows$position <= seed_end
  oxidation_rows <- oxidation_rows[oxidation_rows$in_seed, , drop = FALSE]
  
  # Convert to tibble only after filtering
  oxidation_rows <- as_tibble(oxidation_rows)
  oxidation_rows$position <- NULL
  oxidation_rows$in_seed <- NULL
} else {
  oxidation_rows <- tibble()
}

if (nrow(oxidation_rows) == 0) {
  log_warning("No matching VAF rows for significant G>T seed mutations. Skipping Step 6.1.")
  write_csv(tibble(), output_correlation)
  write_csv(tibble(), output_expression_summary)
  log_success("Step 6.1 completed (skipped due to no data).")
  quit(save = "no", status = 0)
}

# Use column indices instead of select() to avoid variable name limit
sample_col_indices <- which(names(oxidation_rows) %in% sample_cols)
oxidation_matrix <- as.matrix(oxidation_rows[, sample_col_indices, drop = FALSE])

row_sums <- rowSums(oxidation_matrix, na.rm = TRUE)
row_means <- rowMeans(oxidation_matrix, na.rm = TRUE)
row_max <- apply(oxidation_matrix, 1, max, na.rm = TRUE)

oxidation_data <- oxidation_rows %>%
  mutate(
    total_row_counts = row_sums,
    mean_row_vaf = row_means,
    max_row_vaf = row_max
  ) %>%
  group_by(miRNA_name) %>%
  summarise(
    n_seed_gt_mutations = n(),
    total_gt_counts = sum(total_row_counts, na.rm = TRUE),
    mean_gt_vaf = mean(mean_row_vaf, na.rm = TRUE),
    max_gt_vaf = max(max_row_vaf, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(total_gt_counts))

log_info(paste("miRNAs with significant G>T in seed region:", nrow(oxidation_data)))

# ============================================================================
# COMBINE EXPRESSION AND OXIDATION DATA
# ============================================================================

log_subsection("Combining expression and oxidation data")

# Normalize miRNA name for joining - use base R to avoid variable name limit
expression_data$miRNA_name <- expression_data[["miRNA name"]]

# Use base R merge and subsetting to avoid variable name limit
# Extract only needed columns before merge
expr_subset <- data.frame(
  miRNA_name = expression_data$miRNA_name,
  estimated_rpm = expression_data$estimated_rpm,
  stringsAsFactors = FALSE
)

# Merge using base R
correlation_data <- merge(expr_subset, oxidation_data, by = "miRNA_name", all = FALSE)

# Filter and transform using base R
correlation_data <- correlation_data[
  correlation_data$total_gt_counts > 0 & correlation_data$estimated_rpm > 0,
  , drop = FALSE
]

correlation_data$log10_rpm <- log10(correlation_data$estimated_rpm + 1)
correlation_data$log10_oxidation <- log10(correlation_data$total_gt_counts + 1)

# Convert to tibble only at the end
correlation_data <- as_tibble(correlation_data)

log_info(paste("miRNAs with both expression and oxidation data:", nrow(correlation_data)))

# ============================================================================
# CORRELATION ANALYSIS
# ============================================================================

log_subsection("Performing correlation analysis")

# Pearson correlation
correlation_result <- tryCatch({
  cor.test(correlation_data$estimated_rpm, correlation_data$total_gt_counts, method = "pearson")
}, error = function(e) {
  log_warning(paste("Pearson correlation failed:", e$message))
  # Fallback: use log-transformed values
  cor.test(correlation_data$log10_rpm, correlation_data$log10_oxidation, method = "pearson")
})

# Spearman correlation (rank-based, more robust)
correlation_spearman <- tryCatch({
  cor.test(correlation_data$estimated_rpm, correlation_data$total_gt_counts, method = "spearman")
}, error = function(e) {
  log_warning(paste("Spearman correlation failed:", e$message))
  NULL
})

# Create correlation summary
correlation_summary <- tibble(
  method = "Pearson",
  correlation_coefficient = as.numeric(correlation_result$estimate),
  p_value = correlation_result$p.value,
  n_miRNAs = nrow(correlation_data),
  significance = case_when(
    correlation_result$p.value < 0.001 ~ "Highly significant (p < 0.001)",
    correlation_result$p.value < 0.01 ~ "Very significant (p < 0.01)",
    correlation_result$p.value < 0.05 ~ "Significant (p < 0.05)",
    TRUE ~ "Not significant"
  )
)

if (!is.null(correlation_spearman)) {
  correlation_summary <- bind_rows(
    correlation_summary,
    tibble(
      method = "Spearman",
      correlation_coefficient = as.numeric(correlation_spearman$estimate),
      p_value = correlation_spearman$p.value,
      n_miRNAs = nrow(correlation_data),
      significance = case_when(
        correlation_spearman$p.value < 0.001 ~ "Highly significant (p < 0.001)",
        correlation_spearman$p.value < 0.01 ~ "Very significant (p < 0.01)",
        correlation_spearman$p.value < 0.05 ~ "Significant (p < 0.05)",
        TRUE ~ "Not significant"
      )
    )
  )
}

log_info(paste("Pearson correlation (r):", round(correlation_result$estimate, 4)))
log_info(paste("P-value:", format(correlation_result$p.value, scientific = TRUE)))
if (!is.null(correlation_spearman)) {
  log_info(paste("Spearman correlation (rho):", round(correlation_spearman$estimate, 4)))
}

# ============================================================================
# CREATE CORRELATION TABLE
# ============================================================================

correlation_table <- correlation_data %>%
  select(
    miRNA_name,
    estimated_rpm,
    log10_rpm,
    total_gt_counts,
    mean_gt_vaf,
    max_gt_vaf,
    n_seed_gt_mutations
  ) %>%
  arrange(desc(total_gt_counts))

write_csv(correlation_table, output_correlation)
log_success(paste("Correlation table saved:", output_correlation))

# ============================================================================
# EXPRESSION CATEGORY ANALYSIS
# ============================================================================

log_subsection("Analyzing by expression categories")

# Categorize miRNAs by expression level
expression_summary <- correlation_data %>%
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
  ) %>%
  group_by(expression_category) %>%
  summarise(
    n_miRNAs = n(),
    mean_rpm = mean(estimated_rpm, na.rm = TRUE),
    median_rpm = median(estimated_rpm, na.rm = TRUE),
    mean_oxidation = mean(total_gt_counts, na.rm = TRUE),
    median_oxidation = median(total_gt_counts, na.rm = TRUE),
    mean_vaf = mean(mean_gt_vaf, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(mean_rpm))

write_csv(expression_summary, output_expression_summary)
log_success(paste("Expression summary saved:", output_expression_summary))

log_info(paste("Top expression category:", expression_summary$expression_category[1], 
              "with", expression_summary$n_miRNAs[1], "miRNAs"))

log_success("Step 6.1 completed successfully")

