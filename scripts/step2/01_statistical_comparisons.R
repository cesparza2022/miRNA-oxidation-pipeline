#!/usr/bin/env Rscript
# ============================================================================
# STEP 2.1: Statistical Comparisons - ALS vs Control
# ============================================================================
# Purpose: Perform statistical comparisons between ALS and Control groups
# 
# Tests performed:
# - t-test (parametric) - with assumption validation
# - Wilcoxon rank-sum test (non-parametric)
# - FDR correction (Benjamini-Hochberg)
# 
# NEW: Integrates statistical assumptions validation and batch-corrected data
# 
# Snakemake parameters:
#   input: Path to batch-corrected data (preferred) or VAF-filtered data
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

# Load statistical assumptions validation functions
assumptions_path <- if (!is.null(snakemake@params[["assumptions_functions"]])) {
  snakemake@params[["assumptions_functions"]]
} else {
  "scripts/utils/statistical_assumptions.R"
}

if (file.exists(assumptions_path)) {
  source(assumptions_path, local = TRUE)
  log_info("Statistical assumptions validation functions loaded")
  use_assumption_checks <- TRUE
} else {
  log_warning("statistical_assumptions.R not found. Assumption checks will be skipped.")
  use_assumption_checks <- FALSE
}

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

# Try to use batch-corrected data first, then VAF filtered, then fallback
input_file <- if (!is.null(snakemake@input[["batch_corrected"]]) && file.exists(snakemake@input[["batch_corrected"]])) {
  log_info("Using batch-corrected data")
  snakemake@input[["batch_corrected"]]
} else if (!is.null(snakemake@input[["vaf_filtered_data"]]) && file.exists(snakemake@input[["vaf_filtered_data"]])) {
  log_info("Using VAF-filtered data (batch correction not available)")
  snakemake@input[["vaf_filtered_data"]]
} else if (!is.null(snakemake@input[["fallback_data"]]) && file.exists(snakemake@input[["fallback_data"]])) {
  log_info("Using fallback data (processed clean)")
  snakemake@input[["fallback_data"]]
} else if (!is.null(snakemake@input[["data"]])) {
  snakemake@input[["data"]]
} else {
  stop("Could not find input data file. Tried batch_corrected, vaf_filtered_data, and fallback_data.")
}

output_table <- snakemake@output[["table"]]
output_assumptions_report <- if (!is.null(snakemake@output[["assumptions_report"]])) {
  snakemake@output[["assumptions_report"]]
} else {
  NULL
}

# Get config parameters
config <- snakemake@config
alpha <- if (!is.null(config$analysis$alpha)) config$analysis$alpha else 0.05
fdr_method <- if (!is.null(config$analysis$fdr_method)) config$analysis$fdr_method else "BH"

# Get assumption checking settings
check_assumptions <- if (!is.null(config$analysis$assumptions$check_normality)) {
  config$analysis$assumptions$check_normality
} else {
  TRUE  # Default to checking
}

auto_select_test <- if (!is.null(config$analysis$assumptions$auto_select_test)) {
  config$analysis$assumptions$auto_select_test
} else {
  TRUE  # Default to auto-selection
}

log_info(paste("Input file:", input_file))
log_info(paste("Output table:", output_table))
log_info(paste("Significance threshold (alpha):", alpha))
log_info(paste("FDR method:", fdr_method))
log_info(paste("Check assumptions:", check_assumptions))
log_info(paste("Auto-select test:", auto_select_test))

ensure_output_dir(dirname(output_table))
if (!is.null(output_assumptions_report)) {
  ensure_output_dir(dirname(output_assumptions_report))
}

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
  handle_error(e, context = "Step 2.1 - Group Identification", exit_code = 1, log_file = log_file)
})

# Split data by groups
grouped_data <- split_data_by_groups(data, groups_df)

# Get dynamic group names
unique_groups <- sort(unique(groups_df$group))
if (length(unique_groups) != 2) {
  stop("Currently only 2-group comparisons are supported. Found ", length(unique_groups), " groups: ", paste(unique_groups, collapse = ", "))
}

group1_name <- unique_groups[1]
group2_name <- unique_groups[2]

# Get samples for each group (using backward-compatible names)
group1_samples <- grouped_data[[paste0(group1_name, "_samples")]]
group2_samples <- grouped_data[[paste0(group2_name, "_samples")]]

# Also get backward-compatible names for logging
als_samples <- grouped_data$als_samples  # Will be group1
control_samples <- grouped_data$control_samples  # Will be group2

log_info(paste(group1_name, "samples:", length(group1_samples)))
log_info(paste(group2_name, "samples:", length(group2_samples)))

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
  filter(!is.na(group), group %in% unique_groups) %>%
  rename(Group = group) %>%
  mutate(
    SNV_id = paste(miRNA_name, pos.mut, sep = "|")
  )

log_info(paste("SNVs for comparison:", n_distinct(data_long$SNV_id)))

# ============================================================================
# STATISTICAL ASSUMPTIONS VALIDATION (on representative sample)
# ============================================================================

test_recommendation <- "both"  # Default: run both tests
assumption_summary <- NULL

if (use_assumption_checks && check_assumptions) {
  log_subsection("Validating statistical assumptions (representative sample)")
  
  # Sample representative SNVs for assumption checking (to avoid excessive computation)
  # Use top 50 by variance (most variable = most informative for assumptions)
  sample_snvs <- data_long %>%
    group_by(SNV_id) %>%
    summarise(
      variance = var(Count, na.rm = TRUE),
      n_obs = n(),
      .groups = "drop"
    ) %>%
    filter(!is.na(variance), n_obs >= 4) %>%
    arrange(desc(variance)) %>%
    head(50) %>%
    pull(SNV_id)
  
  if (length(sample_snvs) > 0) {
    log_info(paste("Checking assumptions on", length(sample_snvs), "representative SNVs"))
    
    # Aggregate data for assumption checking
    sample_data <- data_long %>%
      filter(SNV_id %in% sample_snvs) %>%
      group_by(SNV_id, Sample, Group) %>%
      summarise(Total_Count = sum(Count, na.rm = TRUE), .groups = "drop")
    
    # Check assumptions on pooled data (combine all SNVs)
    pooled_data <- sample_data$Total_Count
    pooled_groups <- sample_data$Group
    
    assumption_results <- tryCatch({
      select_appropriate_test(pooled_data, pooled_groups, alpha = alpha)
    }, error = function(e) {
      log_warning(paste("Assumption checking failed:", e$message))
      NULL
    })
    
    if (!is.null(assumption_results)) {
      assumption_summary <- assumption_results$summary
      test_recommendation <- if (assumption_results$parametric) {
        "parametric"  # Use t-test
      } else {
        "non-parametric"  # Use Wilcoxon
      }
      
      log_info(paste("Assumption check complete. Recommended test:", test_recommendation))
      
      # Print assumption results
      if (exists("print_assumption_results")) {
        print_assumption_results(assumption_results)
      }
      
      # Save assumption report
      if (!is.null(output_assumptions_report)) {
        report_text <- capture.output({
          if (exists("print_assumption_results")) {
            print_assumption_results(assumption_results)
          } else {
            cat("Statistical Assumptions Check\n")
            cat("============================\n\n")
            cat("Normality:", assumption_summary$normality_passed, "\n")
            cat("Variance homogeneity:", assumption_summary$variance_homogeneity_passed, "\n")
            cat("Recommended test:", assumption_summary$recommended_test, "\n")
          }
        })
        writeLines(report_text, output_assumptions_report)
        log_success(paste("Assumption report saved:", output_assumptions_report))
      }
    } else {
      log_warning("Assumption checking failed. Using default: both tests")
    }
  } else {
    log_warning("Insufficient data for assumption checking. Using default: both tests")
  }
} else {
  log_info("Assumption checking disabled or functions not available. Using default: both tests")
}

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
log_info(paste("Running statistical tests (recommendation:", test_recommendation, ")..."))

# Generate dynamic column names
group1_mean_col <- paste0(group1_name, "_mean")
group1_sd_col <- paste0(group1_name, "_sd")
group1_n_col <- paste0(group1_name, "_n")
group2_mean_col <- paste0(group2_name, "_mean")
group2_sd_col <- paste0(group2_name, "_sd")
group2_n_col <- paste0(group2_name, "_n")

comparison_results <- snv_by_sample %>%
  group_by(SNV_id) %>%
  summarise(
    # Mean and SD for each group (dynamic names)
    !!group1_mean_col := mean(Total_Count[Group == group1_name], na.rm = TRUE),
    !!group1_sd_col := sd(Total_Count[Group == group1_name], na.rm = TRUE),
    !!group1_n_col := sum(!is.na(Total_Count[Group == group1_name])),
    !!group2_mean_col := mean(Total_Count[Group == group2_name], na.rm = TRUE),
    !!group2_sd_col := sd(Total_Count[Group == group2_name], na.rm = TRUE),
    !!group2_n_col := sum(!is.na(Total_Count[Group == group2_name])),
    
    # Fold change (group1 / group2)
    fold_change = ifelse(
      mean(Total_Count[Group == group2_name], na.rm = TRUE) > 0,
      mean(Total_Count[Group == group1_name], na.rm = TRUE) / mean(Total_Count[Group == group2_name], na.rm = TRUE),
      NA_real_
    ),
    log2_fold_change = ifelse(
      mean(Total_Count[Group == group2_name], na.rm = TRUE) > 0,
      log2(mean(Total_Count[Group == group1_name], na.rm = TRUE) / mean(Total_Count[Group == group2_name], na.rm = TRUE)),
      NA_real_
    ),
    
    # Statistical tests
    # t-test (if recommended or default)
    t_test_pvalue = if (test_recommendation %in% c("both", "parametric")) {
      tryCatch({
        test_result <- t.test(
          Total_Count[Group == group1_name],
          Total_Count[Group == group2_name],
          alternative = "two.sided"
        )
        test_result$p.value
      }, error = function(e) NA_real_)
    } else {
      NA_real_
    },
    
    # Wilcoxon rank-sum test (always calculate as it's robust)
    wilcoxon_pvalue = tryCatch({
      test_result <- wilcox.test(
        Total_Count[Group == group1_name],
        Total_Count[Group == group2_name],
        alternative = "two.sided"
      )
      test_result$p.value
    }, error = function(e) NA_real_),
    
    .groups = "drop"
  )

# For backward compatibility, also add ALS_mean/Control_mean if needed
# (These map to group1/group2 for compatibility with downstream scripts)
comparison_results <- comparison_results %>%
  mutate(
    ALS_mean = !!sym(group1_mean_col),
    ALS_sd = !!sym(group1_sd_col),
    ALS_n = !!sym(group1_n_col),
    Control_mean = !!sym(group2_mean_col),
    Control_sd = !!sym(group2_sd_col),
    Control_n = !!sym(group2_n_col)
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
