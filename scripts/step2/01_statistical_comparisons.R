#!/usr/bin/env Rscript
# ============================================================================
# STEP 2.1: Statistical Comparisons - ALS vs Control
# ============================================================================
# Purpose: Perform statistical comparisons between ALS and Control groups
# 
# Tests performed:
# - t-test (parametric)
# - Wilcoxon rank-sum test (non-parametric)
# - FDR correction (Benjamini-Hochberg)
# 
# Snakemake parameters:
#   input: Path to VAF-filtered data from Step 1.5
#   output: Statistical comparison results table
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(readr)
  library(stringr)
  library(tidyr)
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
} else if (file.exists("scripts/utils/group_comparison.R")) {
  source("scripts/utils/group_comparison.R", local = TRUE)
} else {
  warning("group_comparison.R not found, creating basic extract_sample_groups function")
  # Basic fallback function
  extract_sample_groups <- function(data, als_pattern = "ALS", control_pattern = "control|Control|CTRL") {
    metadata_cols <- c("miRNA_name", "miRNA name", "pos.mut", "pos:mut")
    sample_cols <- names(data)[!names(data) %in% metadata_cols]
    groups_df <- tibble(sample_id = sample_cols) %>%
      mutate(
        group = case_when(
          str_detect(sample_id, regex(als_pattern, ignore_case = TRUE)) ~ "ALS",
          str_detect(sample_id, regex(control_pattern, ignore_case = TRUE)) ~ "Control",
          TRUE ~ NA_character_
        )
      ) %>%
      filter(!is.na(group))
    return(groups_df)
  }
  
  split_data_by_groups <- function(data, groups_df) {
    als_samples <- groups_df %>% filter(group == "ALS") %>% pull(sample_id)
    control_samples <- groups_df %>% filter(group == "Control") %>% pull(sample_id)
    metadata_cols <- c("miRNA_name", "miRNA name", "pos.mut", "pos:mut")
    metadata_cols <- metadata_cols[metadata_cols %in% names(data)]
    als_data <- data %>% select(all_of(c(metadata_cols, als_samples)))
    control_data <- data %>% select(all_of(c(metadata_cols, control_samples)))
    return(list(
      als_data = als_data,
      control_data = control_data,
      als_samples = als_samples,
      control_samples = control_samples
    ))
  }
}

# Initialize logging
log_file <- if (length(snakemake@log) > 0) snakemake@log[[1]] else {
  file.path(dirname(snakemake@output[[1]]), "statistical_comparisons.log")
}
initialize_logging(log_file, context = "Step 2.1 - Statistical Comparisons")

log_section("STEP 2.1: Statistical Comparisons - ALS vs Control")

# ============================================================================
# GET SNAKEMAKE PARAMETERS
# ============================================================================

# Try to use VAF filtered data first, fallback to processed clean
input_file <- if (!is.null(snakemake@input[["vaf_filtered_data"]]) && file.exists(snakemake@input[["vaf_filtered_data"]])) {
  snakemake@input[["vaf_filtered_data"]]
} else if (!is.null(snakemake@input[["fallback_data"]]) && file.exists(snakemake@input[["fallback_data"]])) {
  snakemake@input[["fallback_data"]]
} else if (!is.null(snakemake@input[["data"]])) {
  snakemake@input[["data"]]
} else {
  stop("Could not find input data file. Tried vaf_filtered_data and fallback_data.")
}

output_table <- snakemake@output[["table"]]

# Get config parameters
config <- snakemake@config
alpha <- if (!is.null(config$analysis$alpha)) config$analysis$alpha else 0.05
fdr_method <- if (!is.null(config$analysis$fdr_method)) config$analysis$fdr_method else "BH"

log_info(paste("Input file:", input_file))
log_info(paste("Output table:", output_table))
log_info(paste("Significance threshold (alpha):", alpha))
log_info(paste("FDR method:", fdr_method))

ensure_output_dir(dirname(output_table))

# ============================================================================
# LOAD DATA
# ============================================================================

log_subsection("Loading data")

data <- tryCatch({
  # Try reading as CSV first (processed data)
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
  handle_error(e, context = "Step 2.1 - Data Loading", exit_code = 1, log_file = log_file)
})

# ============================================================================
# IDENTIFY SAMPLE GROUPS
# ============================================================================

log_subsection("Identifying sample groups")

groups_df <- tryCatch({
  extract_sample_groups(data)
}, error = function(e) {
  handle_error(e, context = "Step 2.1 - Group Identification", exit_code = 1, log_file = log_file)
})

# Split data by groups
grouped_data <- split_data_by_groups(data, groups_df)
als_samples <- grouped_data$als_samples
control_samples <- grouped_data$control_samples

log_info(paste("ALS samples:", length(als_samples)))
log_info(paste("Control samples:", length(control_samples)))

# ============================================================================
# PREPARE DATA FOR COMPARISONS
# ============================================================================

log_subsection("Preparing data for statistical comparisons")

# Convert to long format
metadata_cols <- c("miRNA_name", "pos.mut")
data_long <- data %>%
  pivot_longer(
    cols = -all_of(metadata_cols),
    names_to = "Sample",
    values_to = "Count"
  ) %>%
  left_join(groups_df, by = c("Sample" = "sample_id")) %>%
  filter(!is.na(group), group %in% c("ALS", "Control")) %>%
  rename(Group = group) %>%
  mutate(
    SNV_id = paste(miRNA_name, pos.mut, sep = "|")
  )

log_info(paste("SNVs for comparison:", n_distinct(data_long$SNV_id)))

# ============================================================================
# STATISTICAL TESTS
# ============================================================================

log_subsection("Performing statistical tests")

# Aggregate counts per SNV per sample (sum across positions if multiple)
snv_by_sample <- data_long %>%
  group_by(SNV_id, Sample, Group) %>%
  summarise(
    Total_Count = sum(Count, na.rm = TRUE),
    .groups = "drop"
  )

# Perform statistical comparisons per SNV
log_info("Running t-tests and Wilcoxon tests...")

comparison_results <- snv_by_sample %>%
  group_by(SNV_id) %>%
  summarise(
    # Mean and SD for each group
    ALS_mean = mean(Total_Count[Group == "ALS"], na.rm = TRUE),
    ALS_sd = sd(Total_Count[Group == "ALS"], na.rm = TRUE),
    ALS_n = sum(!is.na(Total_Count[Group == "ALS"])),
    Control_mean = mean(Total_Count[Group == "Control"], na.rm = TRUE),
    Control_sd = sd(Total_Count[Group == "Control"], na.rm = TRUE),
    Control_n = sum(!is.na(Total_Count[Group == "Control"])),
    
    # Fold change (ALS / Control)
    fold_change = ifelse(Control_mean > 0, ALS_mean / Control_mean, NA_real_),
    log2_fold_change = ifelse(Control_mean > 0, log2(ALS_mean / Control_mean), NA_real_),
    
    # Statistical tests
    # t-test
    t_test_pvalue = tryCatch({
      test_result <- t.test(
        Total_Count[Group == "ALS"],
        Total_Count[Group == "Control"],
        alternative = "two.sided"
      )
      test_result$p.value
    }, error = function(e) NA_real_),
    
    # Wilcoxon rank-sum test
    wilcoxon_pvalue = tryCatch({
      test_result <- wilcox.test(
        Total_Count[Group == "ALS"],
        Total_Count[Group == "Control"],
        alternative = "two.sided"
      )
      test_result$p.value
    }, error = function(e) NA_real_),
    
    .groups = "drop"
  )

# ============================================================================
# FDR CORRECTION
# ============================================================================

log_subsection("Applying FDR correction")

# Filter valid p-values
valid_t <- !is.na(comparison_results$t_test_pvalue)
valid_wilcox <- !is.na(comparison_results$wilcoxon_pvalue)

# Apply FDR correction
comparison_results <- comparison_results %>%
  mutate(
    t_test_fdr = ifelse(valid_t, 
                       p.adjust(t_test_pvalue, method = fdr_method),
                       NA_real_),
    wilcoxon_fdr = ifelse(valid_wilcox,
                         p.adjust(wilcoxon_pvalue, method = fdr_method),
                         NA_real_),
    
    # Significance flags
    t_test_significant = !is.na(t_test_fdr) & t_test_fdr < alpha,
    wilcoxon_significant = !is.na(wilcoxon_fdr) & wilcoxon_fdr < alpha,
    
    # Combined significance (either test significant)
    significant = case_when(
      is.na(t_test_significant) & is.na(wilcoxon_significant) ~ FALSE,
      is.na(t_test_significant) ~ wilcoxon_significant,
      is.na(wilcoxon_significant) ~ t_test_significant,
      TRUE ~ (t_test_significant | wilcoxon_significant)
    )
  )

# Separate miRNA_name and pos.mut
comparison_results <- comparison_results %>%
  separate(SNV_id, into = c("miRNA_name", "pos.mut"), sep = "\\|", remove = FALSE)

# Summary statistics
n_significant_t <- sum(comparison_results$t_test_significant, na.rm = TRUE)
n_significant_wilcox <- sum(comparison_results$wilcoxon_significant, na.rm = TRUE)
n_significant_combined <- sum(comparison_results$significant, na.rm = TRUE)

log_info(paste("Significant SNVs (t-test, FDR <", alpha, "):", n_significant_t))
log_info(paste("Significant SNVs (Wilcoxon, FDR <", alpha, "):", n_significant_wilcox))
log_info(paste("Significant SNVs (either test):", n_significant_combined))

# ============================================================================
# EXPORT RESULTS
# ============================================================================

log_subsection("Exporting results")

write_csv(comparison_results, output_table)
log_success(paste("Results exported:", output_table))

# Top significant SNVs
log_subsection("Top 10 Most Significant SNVs")

top_significant <- comparison_results %>%
  mutate(sort_pvalue = ifelse(!is.na(wilcoxon_fdr), wilcoxon_fdr, t_test_fdr)) %>%
  arrange(sort_pvalue) %>%
  head(10) %>%
  select(miRNA_name, pos.mut, ALS_mean, Control_mean, log2_fold_change, 
         wilcoxon_fdr, t_test_fdr, significant)

print(top_significant)

log_success("Statistical comparisons completed successfully")
log_info(paste("Execution completed at", get_timestamp()))


# STEP 2.1: Statistical Comparisons - ALS vs Control
# ============================================================================
# Purpose: Perform statistical comparisons between ALS and Control groups
# 
# Tests performed:
# - t-test (parametric)
# - Wilcoxon rank-sum test (non-parametric)
# - FDR correction (Benjamini-Hochberg)
# 
# Snakemake parameters:
#   input: Path to VAF-filtered data from Step 1.5
#   output: Statistical comparison results table
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(readr)
  library(stringr)
  library(tidyr)
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
} else if (file.exists("scripts/utils/group_comparison.R")) {
  source("scripts/utils/group_comparison.R", local = TRUE)
} else {
  warning("group_comparison.R not found, creating basic extract_sample_groups function")
  # Basic fallback function
  extract_sample_groups <- function(data, als_pattern = "ALS", control_pattern = "control|Control|CTRL") {
    metadata_cols <- c("miRNA_name", "miRNA name", "pos.mut", "pos:mut")
    sample_cols <- names(data)[!names(data) %in% metadata_cols]
    groups_df <- tibble(sample_id = sample_cols) %>%
      mutate(
        group = case_when(
          str_detect(sample_id, regex(als_pattern, ignore_case = TRUE)) ~ "ALS",
          str_detect(sample_id, regex(control_pattern, ignore_case = TRUE)) ~ "Control",
          TRUE ~ NA_character_
        )
      ) %>%
      filter(!is.na(group))
    return(groups_df)
  }
  
  split_data_by_groups <- function(data, groups_df) {
    als_samples <- groups_df %>% filter(group == "ALS") %>% pull(sample_id)
    control_samples <- groups_df %>% filter(group == "Control") %>% pull(sample_id)
    metadata_cols <- c("miRNA_name", "miRNA name", "pos.mut", "pos:mut")
    metadata_cols <- metadata_cols[metadata_cols %in% names(data)]
    als_data <- data %>% select(all_of(c(metadata_cols, als_samples)))
    control_data <- data %>% select(all_of(c(metadata_cols, control_samples)))
    return(list(
      als_data = als_data,
      control_data = control_data,
      als_samples = als_samples,
      control_samples = control_samples
    ))
  }
}

# Initialize logging
log_file <- if (length(snakemake@log) > 0) snakemake@log[[1]] else {
  file.path(dirname(snakemake@output[[1]]), "statistical_comparisons.log")
}
initialize_logging(log_file, context = "Step 2.1 - Statistical Comparisons")

log_section("STEP 2.1: Statistical Comparisons - ALS vs Control")

# ============================================================================
# GET SNAKEMAKE PARAMETERS
# ============================================================================

# Try to use VAF filtered data first, fallback to processed clean
input_file <- if (!is.null(snakemake@input[["vaf_filtered_data"]]) && file.exists(snakemake@input[["vaf_filtered_data"]])) {
  snakemake@input[["vaf_filtered_data"]]
} else if (!is.null(snakemake@input[["fallback_data"]]) && file.exists(snakemake@input[["fallback_data"]])) {
  snakemake@input[["fallback_data"]]
} else if (!is.null(snakemake@input[["data"]])) {
  snakemake@input[["data"]]
} else {
  stop("Could not find input data file. Tried vaf_filtered_data and fallback_data.")
}

output_table <- snakemake@output[["table"]]

# Get config parameters
config <- snakemake@config
alpha <- if (!is.null(config$analysis$alpha)) config$analysis$alpha else 0.05
fdr_method <- if (!is.null(config$analysis$fdr_method)) config$analysis$fdr_method else "BH"

log_info(paste("Input file:", input_file))
log_info(paste("Output table:", output_table))
log_info(paste("Significance threshold (alpha):", alpha))
log_info(paste("FDR method:", fdr_method))

ensure_output_dir(dirname(output_table))

# ============================================================================
# LOAD DATA
# ============================================================================

log_subsection("Loading data")

data <- tryCatch({
  # Try reading as CSV first (processed data)
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
  handle_error(e, context = "Step 2.1 - Data Loading", exit_code = 1, log_file = log_file)
})

# ============================================================================
# IDENTIFY SAMPLE GROUPS
# ============================================================================

log_subsection("Identifying sample groups")

groups_df <- tryCatch({
  extract_sample_groups(data)
}, error = function(e) {
  handle_error(e, context = "Step 2.1 - Group Identification", exit_code = 1, log_file = log_file)
})

# Split data by groups
grouped_data <- split_data_by_groups(data, groups_df)
als_samples <- grouped_data$als_samples
control_samples <- grouped_data$control_samples

log_info(paste("ALS samples:", length(als_samples)))
log_info(paste("Control samples:", length(control_samples)))

# ============================================================================
# PREPARE DATA FOR COMPARISONS
# ============================================================================

log_subsection("Preparing data for statistical comparisons")

# Convert to long format
metadata_cols <- c("miRNA_name", "pos.mut")
data_long <- data %>%
  pivot_longer(
    cols = -all_of(metadata_cols),
    names_to = "Sample",
    values_to = "Count"
  ) %>%
  left_join(groups_df, by = c("Sample" = "sample_id")) %>%
  filter(!is.na(group), group %in% c("ALS", "Control")) %>%
  rename(Group = group) %>%
  mutate(
    SNV_id = paste(miRNA_name, pos.mut, sep = "|")
  )

log_info(paste("SNVs for comparison:", n_distinct(data_long$SNV_id)))

# ============================================================================
# STATISTICAL TESTS
# ============================================================================

log_subsection("Performing statistical tests")

# Aggregate counts per SNV per sample (sum across positions if multiple)
snv_by_sample <- data_long %>%
  group_by(SNV_id, Sample, Group) %>%
  summarise(
    Total_Count = sum(Count, na.rm = TRUE),
    .groups = "drop"
  )

# Perform statistical comparisons per SNV
log_info("Running t-tests and Wilcoxon tests...")

comparison_results <- snv_by_sample %>%
  group_by(SNV_id) %>%
  summarise(
    # Mean and SD for each group
    ALS_mean = mean(Total_Count[Group == "ALS"], na.rm = TRUE),
    ALS_sd = sd(Total_Count[Group == "ALS"], na.rm = TRUE),
    ALS_n = sum(!is.na(Total_Count[Group == "ALS"])),
    Control_mean = mean(Total_Count[Group == "Control"], na.rm = TRUE),
    Control_sd = sd(Total_Count[Group == "Control"], na.rm = TRUE),
    Control_n = sum(!is.na(Total_Count[Group == "Control"])),
    
    # Fold change (ALS / Control)
    fold_change = ifelse(Control_mean > 0, ALS_mean / Control_mean, NA_real_),
    log2_fold_change = ifelse(Control_mean > 0, log2(ALS_mean / Control_mean), NA_real_),
    
    # Statistical tests
    # t-test
    t_test_pvalue = tryCatch({
      test_result <- t.test(
        Total_Count[Group == "ALS"],
        Total_Count[Group == "Control"],
        alternative = "two.sided"
      )
      test_result$p.value
    }, error = function(e) NA_real_),
    
    # Wilcoxon rank-sum test
    wilcoxon_pvalue = tryCatch({
      test_result <- wilcox.test(
        Total_Count[Group == "ALS"],
        Total_Count[Group == "Control"],
        alternative = "two.sided"
      )
      test_result$p.value
    }, error = function(e) NA_real_),
    
    .groups = "drop"
  )

# ============================================================================
# FDR CORRECTION
# ============================================================================

log_subsection("Applying FDR correction")

# Filter valid p-values
valid_t <- !is.na(comparison_results$t_test_pvalue)
valid_wilcox <- !is.na(comparison_results$wilcoxon_pvalue)

# Apply FDR correction
comparison_results <- comparison_results %>%
  mutate(
    t_test_fdr = ifelse(valid_t, 
                       p.adjust(t_test_pvalue, method = fdr_method),
                       NA_real_),
    wilcoxon_fdr = ifelse(valid_wilcox,
                         p.adjust(wilcoxon_pvalue, method = fdr_method),
                         NA_real_),
    
    # Significance flags
    t_test_significant = !is.na(t_test_fdr) & t_test_fdr < alpha,
    wilcoxon_significant = !is.na(wilcoxon_fdr) & wilcoxon_fdr < alpha,
    
    # Combined significance (either test significant)
    significant = case_when(
      is.na(t_test_significant) & is.na(wilcoxon_significant) ~ FALSE,
      is.na(t_test_significant) ~ wilcoxon_significant,
      is.na(wilcoxon_significant) ~ t_test_significant,
      TRUE ~ (t_test_significant | wilcoxon_significant)
    )
  )

# Separate miRNA_name and pos.mut
comparison_results <- comparison_results %>%
  separate(SNV_id, into = c("miRNA_name", "pos.mut"), sep = "\\|", remove = FALSE)

# Summary statistics
n_significant_t <- sum(comparison_results$t_test_significant, na.rm = TRUE)
n_significant_wilcox <- sum(comparison_results$wilcoxon_significant, na.rm = TRUE)
n_significant_combined <- sum(comparison_results$significant, na.rm = TRUE)

log_info(paste("Significant SNVs (t-test, FDR <", alpha, "):", n_significant_t))
log_info(paste("Significant SNVs (Wilcoxon, FDR <", alpha, "):", n_significant_wilcox))
log_info(paste("Significant SNVs (either test):", n_significant_combined))

# ============================================================================
# EXPORT RESULTS
# ============================================================================

log_subsection("Exporting results")

write_csv(comparison_results, output_table)
log_success(paste("Results exported:", output_table))

# Top significant SNVs
log_subsection("Top 10 Most Significant SNVs")

top_significant <- comparison_results %>%
  mutate(sort_pvalue = ifelse(!is.na(wilcoxon_fdr), wilcoxon_fdr, t_test_fdr)) %>%
  arrange(sort_pvalue) %>%
  head(10) %>%
  select(miRNA_name, pos.mut, ALS_mean, Control_mean, log2_fold_change, 
         wilcoxon_fdr, t_test_fdr, significant)

print(top_significant)

log_success("Statistical comparisons completed successfully")
log_info(paste("Execution completed at", get_timestamp()))


# STEP 2.1: Statistical Comparisons - ALS vs Control
# ============================================================================
# Purpose: Perform statistical comparisons between ALS and Control groups
# 
# Tests performed:
# - t-test (parametric)
# - Wilcoxon rank-sum test (non-parametric)
# - FDR correction (Benjamini-Hochberg)
# 
# Snakemake parameters:
#   input: Path to VAF-filtered data from Step 1.5
#   output: Statistical comparison results table
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(readr)
  library(stringr)
  library(tidyr)
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
} else if (file.exists("scripts/utils/group_comparison.R")) {
  source("scripts/utils/group_comparison.R", local = TRUE)
} else {
  warning("group_comparison.R not found, creating basic extract_sample_groups function")
  # Basic fallback function
  extract_sample_groups <- function(data, als_pattern = "ALS", control_pattern = "control|Control|CTRL") {
    metadata_cols <- c("miRNA_name", "miRNA name", "pos.mut", "pos:mut")
    sample_cols <- names(data)[!names(data) %in% metadata_cols]
    groups_df <- tibble(sample_id = sample_cols) %>%
      mutate(
        group = case_when(
          str_detect(sample_id, regex(als_pattern, ignore_case = TRUE)) ~ "ALS",
          str_detect(sample_id, regex(control_pattern, ignore_case = TRUE)) ~ "Control",
          TRUE ~ NA_character_
        )
      ) %>%
      filter(!is.na(group))
    return(groups_df)
  }
  
  split_data_by_groups <- function(data, groups_df) {
    als_samples <- groups_df %>% filter(group == "ALS") %>% pull(sample_id)
    control_samples <- groups_df %>% filter(group == "Control") %>% pull(sample_id)
    metadata_cols <- c("miRNA_name", "miRNA name", "pos.mut", "pos:mut")
    metadata_cols <- metadata_cols[metadata_cols %in% names(data)]
    als_data <- data %>% select(all_of(c(metadata_cols, als_samples)))
    control_data <- data %>% select(all_of(c(metadata_cols, control_samples)))
    return(list(
      als_data = als_data,
      control_data = control_data,
      als_samples = als_samples,
      control_samples = control_samples
    ))
  }
}

# Initialize logging
log_file <- if (length(snakemake@log) > 0) snakemake@log[[1]] else {
  file.path(dirname(snakemake@output[[1]]), "statistical_comparisons.log")
}
initialize_logging(log_file, context = "Step 2.1 - Statistical Comparisons")

log_section("STEP 2.1: Statistical Comparisons - ALS vs Control")

# ============================================================================
# GET SNAKEMAKE PARAMETERS
# ============================================================================

# Try to use VAF filtered data first, fallback to processed clean
input_file <- if (!is.null(snakemake@input[["vaf_filtered_data"]]) && file.exists(snakemake@input[["vaf_filtered_data"]])) {
  snakemake@input[["vaf_filtered_data"]]
} else if (!is.null(snakemake@input[["fallback_data"]]) && file.exists(snakemake@input[["fallback_data"]])) {
  snakemake@input[["fallback_data"]]
} else if (!is.null(snakemake@input[["data"]])) {
  snakemake@input[["data"]]
} else {
  stop("Could not find input data file. Tried vaf_filtered_data and fallback_data.")
}

output_table <- snakemake@output[["table"]]

# Get config parameters
config <- snakemake@config
alpha <- if (!is.null(config$analysis$alpha)) config$analysis$alpha else 0.05
fdr_method <- if (!is.null(config$analysis$fdr_method)) config$analysis$fdr_method else "BH"

log_info(paste("Input file:", input_file))
log_info(paste("Output table:", output_table))
log_info(paste("Significance threshold (alpha):", alpha))
log_info(paste("FDR method:", fdr_method))

ensure_output_dir(dirname(output_table))

# ============================================================================
# LOAD DATA
# ============================================================================

log_subsection("Loading data")

data <- tryCatch({
  # Try reading as CSV first (processed data)
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
  handle_error(e, context = "Step 2.1 - Data Loading", exit_code = 1, log_file = log_file)
})

# ============================================================================
# IDENTIFY SAMPLE GROUPS
# ============================================================================

log_subsection("Identifying sample groups")

groups_df <- tryCatch({
  extract_sample_groups(data)
}, error = function(e) {
  handle_error(e, context = "Step 2.1 - Group Identification", exit_code = 1, log_file = log_file)
})

# Split data by groups
grouped_data <- split_data_by_groups(data, groups_df)
als_samples <- grouped_data$als_samples
control_samples <- grouped_data$control_samples

log_info(paste("ALS samples:", length(als_samples)))
log_info(paste("Control samples:", length(control_samples)))

# ============================================================================
# PREPARE DATA FOR COMPARISONS
# ============================================================================

log_subsection("Preparing data for statistical comparisons")

# Convert to long format
metadata_cols <- c("miRNA_name", "pos.mut")
data_long <- data %>%
  pivot_longer(
    cols = -all_of(metadata_cols),
    names_to = "Sample",
    values_to = "Count"
  ) %>%
  left_join(groups_df, by = c("Sample" = "sample_id")) %>%
  filter(!is.na(group), group %in% c("ALS", "Control")) %>%
  rename(Group = group) %>%
  mutate(
    SNV_id = paste(miRNA_name, pos.mut, sep = "|")
  )

log_info(paste("SNVs for comparison:", n_distinct(data_long$SNV_id)))

# ============================================================================
# STATISTICAL TESTS
# ============================================================================

log_subsection("Performing statistical tests")

# Aggregate counts per SNV per sample (sum across positions if multiple)
snv_by_sample <- data_long %>%
  group_by(SNV_id, Sample, Group) %>%
  summarise(
    Total_Count = sum(Count, na.rm = TRUE),
    .groups = "drop"
  )

# Perform statistical comparisons per SNV
log_info("Running t-tests and Wilcoxon tests...")

comparison_results <- snv_by_sample %>%
  group_by(SNV_id) %>%
  summarise(
    # Mean and SD for each group
    ALS_mean = mean(Total_Count[Group == "ALS"], na.rm = TRUE),
    ALS_sd = sd(Total_Count[Group == "ALS"], na.rm = TRUE),
    ALS_n = sum(!is.na(Total_Count[Group == "ALS"])),
    Control_mean = mean(Total_Count[Group == "Control"], na.rm = TRUE),
    Control_sd = sd(Total_Count[Group == "Control"], na.rm = TRUE),
    Control_n = sum(!is.na(Total_Count[Group == "Control"])),
    
    # Fold change (ALS / Control)
    fold_change = ifelse(Control_mean > 0, ALS_mean / Control_mean, NA_real_),
    log2_fold_change = ifelse(Control_mean > 0, log2(ALS_mean / Control_mean), NA_real_),
    
    # Statistical tests
    # t-test
    t_test_pvalue = tryCatch({
      test_result <- t.test(
        Total_Count[Group == "ALS"],
        Total_Count[Group == "Control"],
        alternative = "two.sided"
      )
      test_result$p.value
    }, error = function(e) NA_real_),
    
    # Wilcoxon rank-sum test
    wilcoxon_pvalue = tryCatch({
      test_result <- wilcox.test(
        Total_Count[Group == "ALS"],
        Total_Count[Group == "Control"],
        alternative = "two.sided"
      )
      test_result$p.value
    }, error = function(e) NA_real_),
    
    .groups = "drop"
  )

# ============================================================================
# FDR CORRECTION
# ============================================================================

log_subsection("Applying FDR correction")

# Filter valid p-values
valid_t <- !is.na(comparison_results$t_test_pvalue)
valid_wilcox <- !is.na(comparison_results$wilcoxon_pvalue)

# Apply FDR correction
comparison_results <- comparison_results %>%
  mutate(
    t_test_fdr = ifelse(valid_t, 
                       p.adjust(t_test_pvalue, method = fdr_method),
                       NA_real_),
    wilcoxon_fdr = ifelse(valid_wilcox,
                         p.adjust(wilcoxon_pvalue, method = fdr_method),
                         NA_real_),
    
    # Significance flags
    t_test_significant = !is.na(t_test_fdr) & t_test_fdr < alpha,
    wilcoxon_significant = !is.na(wilcoxon_fdr) & wilcoxon_fdr < alpha,
    
    # Combined significance (either test significant)
    significant = case_when(
      is.na(t_test_significant) & is.na(wilcoxon_significant) ~ FALSE,
      is.na(t_test_significant) ~ wilcoxon_significant,
      is.na(wilcoxon_significant) ~ t_test_significant,
      TRUE ~ (t_test_significant | wilcoxon_significant)
    )
  )

# Separate miRNA_name and pos.mut
comparison_results <- comparison_results %>%
  separate(SNV_id, into = c("miRNA_name", "pos.mut"), sep = "\\|", remove = FALSE)

# Summary statistics
n_significant_t <- sum(comparison_results$t_test_significant, na.rm = TRUE)
n_significant_wilcox <- sum(comparison_results$wilcoxon_significant, na.rm = TRUE)
n_significant_combined <- sum(comparison_results$significant, na.rm = TRUE)

log_info(paste("Significant SNVs (t-test, FDR <", alpha, "):", n_significant_t))
log_info(paste("Significant SNVs (Wilcoxon, FDR <", alpha, "):", n_significant_wilcox))
log_info(paste("Significant SNVs (either test):", n_significant_combined))

# ============================================================================
# EXPORT RESULTS
# ============================================================================

log_subsection("Exporting results")

write_csv(comparison_results, output_table)
log_success(paste("Results exported:", output_table))

# Top significant SNVs
log_subsection("Top 10 Most Significant SNVs")

top_significant <- comparison_results %>%
  mutate(sort_pvalue = ifelse(!is.na(wilcoxon_fdr), wilcoxon_fdr, t_test_fdr)) %>%
  arrange(sort_pvalue) %>%
  head(10) %>%
  select(miRNA_name, pos.mut, ALS_mean, Control_mean, log2_fold_change, 
         wilcoxon_fdr, t_test_fdr, significant)

print(top_significant)

log_success("Statistical comparisons completed successfully")
log_info(paste("Execution completed at", get_timestamp()))

