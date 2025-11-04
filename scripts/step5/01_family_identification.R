#!/usr/bin/env Rscript
# ============================================================================
# STEP 5.1: miRNA Family Identification and Analysis
# ============================================================================
# Purpose: Identify miRNA families and summarize oxidation patterns by family
#
# Snakemake parameters:
#   input: Statistical comparison results and VAF-filtered data
#   output: Family summary and comparison tables
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
  file.path(dirname(snakemake@output[[1]]), "family_identification.log")
}
initialize_logging(log_file, context = "Step 5.1 - Family Identification")

log_section("STEP 5.1: miRNA Family Identification and Analysis")

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
  handle_error(e, context = "Step 5.1 - Data Loading", exit_code = 1, log_file = log_file)
})

vaf_data <- tryCatch({
  result <- read_csv(input_vaf_filtered, show_col_types = FALSE)
  log_success(paste("Loaded:", nrow(result), "SNVs from VAF filtered data"))
  result
}, error = function(e) {
  handle_error(e, context = "Step 5.1 - Data Loading", exit_code = 1, log_file = log_file)
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
    avg_ALS_mean = mean(ALS_mean, na.rm = TRUE),
    avg_Control_mean = mean(Control_mean, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    avg_oxidation_diff = avg_ALS_mean - avg_Control_mean,
    pct_significant = (n_significant / n_mutations) * 100
  ) %>%
  arrange(desc(n_significant), desc(n_mutations))

write_csv(family_summary, output_family_summary)
log_success(paste("Family summary saved:", output_family_summary))

# ============================================================================
# FAMILY COMPARISON TABLE (ALS vs Control)
# ============================================================================

log_subsection("Creating family comparison table (ALS vs Control)")

# Calculate per-family statistics for ALS vs Control
family_comparison <- vaf_data %>%
  filter(in_seed == TRUE) %>%  # Focus on seed region
  mutate(
    # Calculate per-sample VAF values
    als_mean_vaf = rowMeans(select(., all_of(als_samples)), na.rm = TRUE),
    control_mean_vaf = rowMeans(select(., all_of(control_samples)), na.rm = TRUE)
  ) %>%
  group_by(family) %>%
  summarise(
    n_miRNAs = n_distinct(miRNA_name),
    n_mutations = n(),
    als_mean_vaf = mean(als_mean_vaf, na.rm = TRUE),
    control_mean_vaf = mean(control_mean_vaf, na.rm = TRUE),
    als_median_vaf = median(als_mean_vaf, na.rm = TRUE),
    control_median_vaf = median(control_mean_vaf, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    vaf_difference = als_mean_vaf - control_mean_vaf,
    fold_change = ifelse(control_mean_vaf > 0, als_mean_vaf / control_mean_vaf, NA_real_),
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

log_success("Step 5.1 completed successfully")

