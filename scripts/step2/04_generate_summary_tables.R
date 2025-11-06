#!/usr/bin/env Rscript
# ============================================================================
# STEP 2.4: Generate Summary Tables (Interpretative)
# ============================================================================
# Purpose: Generate interpretative summary tables from statistical results
# 
# Creates 3 summary tables:
# 1. S2_significant_mutations.csv - Only significant mutations (p_adj < 0.05)
# 2. S2_top_effect_sizes.csv - Top 50 mutations by effect size
# 3. S2_seed_region_significant.csv - Significant mutations in seed region (pos 2-7)
# 
# Supports any group names (not hardcoded to ALS/Control)
# 
# Snakemake parameters:
#   input: Path to statistical_comparisons.csv and effect_sizes.csv
#   output: 3 summary tables
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
  file.path(dirname(snakemake@output[[1]]), "generate_summary_tables.log")
}
initialize_logging(log_file, context = "Step 2.4 - Generate Summary Tables")

log_section("STEP 2.4: Generate Summary Tables (Interpretative)")

# ============================================================================
# HELPER FUNCTION: Detect Group Mean Columns
# ============================================================================

detect_group_mean_columns <- function(data) {
  # Look for columns ending with _mean
  mean_cols <- names(data)[str_detect(names(data), "_mean$")]
  
  if (length(mean_cols) == 0) {
    # Fallback: try ALS_mean, Control_mean
    if ("ALS_mean" %in% names(data) && "Control_mean" %in% names(data)) {
      return(list(group1_mean = "ALS_mean", group2_mean = "Control_mean"))
    }
    return(list(group1_mean = NULL, group2_mean = NULL))
  }
  
  # Extract group names from column names (remove _mean suffix)
  group_names <- str_replace(mean_cols, "_mean$", "")
  
  # Filter out backward-compatible columns if dynamic names exist
  if (length(group_names) > 2) {
    # Remove ALS and Control if other groups exist
    dynamic_names <- group_names[!group_names %in% c("ALS", "Control")]
    if (length(dynamic_names) >= 2) {
      group_names <- sort(dynamic_names)[1:2]
    }
  }
  
  if (length(group_names) < 2) {
    # Fallback to ALS/Control if only one detected
    if ("ALS_mean" %in% names(data) && "Control_mean" %in% names(data)) {
      return(list(group1_mean = "ALS_mean", group2_mean = "Control_mean"))
    }
    # If still only one, return what we have
    if (length(group_names) == 1) {
      # Try to find a second group
      if ("ALS_mean" %in% names(data)) {
        return(list(group1_mean = "ALS_mean", group2_mean = paste0(group_names[1], "_mean")))
      }
      if ("Control_mean" %in% names(data)) {
        return(list(group1_mean = paste0(group_names[1], "_mean"), group2_mean = "Control_mean"))
      }
    }
    return(list(group1_mean = NULL, group2_mean = NULL))
  }
  
  # Sort for consistency
  group_names <- sort(group_names)[1:2]
  
  return(list(
    group1_mean = paste0(group_names[1], "_mean"),
    group2_mean = paste0(group_names[2], "_mean")
  ))
}

# ============================================================================
# GET SNAKEMAKE PARAMETERS
# ============================================================================

input_comparisons <- snakemake@input[["comparisons"]]
input_effect_sizes <- snakemake@input[["effect_sizes"]]

output_significant <- snakemake@output[["significant_mutations"]]
output_top_effects <- snakemake@output[["top_effect_sizes"]]
output_seed_significant <- snakemake@output[["seed_significant"]]

# Significance threshold (from config or default)
config <- snakemake@config
alpha <- if (!is.null(config$analysis$alpha)) {
  config$analysis$alpha
} else {
  0.05
}

log_info(paste("Input comparisons:", input_comparisons))
log_info(paste("Input effect sizes:", input_effect_sizes))
log_info(paste("Significance threshold (alpha):", alpha))

# Ensure output directories exist
ensure_output_dir(dirname(output_significant))
ensure_output_dir(dirname(output_top_effects))
ensure_output_dir(dirname(output_seed_significant))

# ============================================================================
# LOAD DATA
# ============================================================================

log_subsection("Loading statistical results")

comparisons <- tryCatch({
  result <- read_csv(input_comparisons, show_col_types = FALSE)
  log_success(paste("Comparisons loaded:", nrow(result), "mutations"))
  result
}, error = function(e) {
  handle_error(e, context = "Loading comparisons", exit_code = 1, log_file = log_file)
})

effect_sizes <- tryCatch({
  result <- read_csv(input_effect_sizes, show_col_types = FALSE)
  log_success(paste("Effect sizes loaded:", nrow(result), "mutations"))
  result
}, error = function(e) {
  handle_error(e, context = "Loading effect sizes", exit_code = 1, log_file = log_file)
})

# ============================================================================
# MERGE DATA
# ============================================================================

log_subsection("Merging statistical and effect size data")

# Ensure we can merge on SNV_id or miRNA_name + pos.mut
if ("SNV_id" %in% names(comparisons) && "SNV_id" %in% names(effect_sizes)) {
  merged_data <- comparisons %>%
    left_join(effect_sizes, by = "SNV_id", suffix = c("", "_effect"))
} else if (all(c("miRNA_name", "pos.mut") %in% names(comparisons)) && 
           all(c("miRNA_name", "pos.mut") %in% names(effect_sizes))) {
  merged_data <- comparisons %>%
    left_join(effect_sizes, by = c("miRNA_name", "pos.mut"), suffix = c("", "_effect"))
} else {
  # Try to create SNV_id
  if (!"SNV_id" %in% names(comparisons)) {
    comparisons <- comparisons %>%
      mutate(SNV_id = paste(!!sym(names(comparisons)[grepl("miRNA|mirna", names(comparisons), ignore.case = TRUE)][1]),
                           !!sym(names(comparisons)[grepl("pos", names(comparisons), ignore.case = TRUE)][1]), sep = "|"))
  }
  if (!"SNV_id" %in% names(effect_sizes)) {
    effect_sizes <- effect_sizes %>%
      mutate(SNV_id = paste(!!sym(names(effect_sizes)[grepl("miRNA|mirna", names(effect_sizes), ignore.case = TRUE)][1]),
                           !!sym(names(effect_sizes)[grepl("pos", names(effect_sizes), ignore.case = TRUE)][1]), sep = "|"))
  }
  merged_data <- comparisons %>%
    left_join(effect_sizes, by = "SNV_id", suffix = c("", "_effect"))
}

# Extract position for seed region analysis
merged_data <- merged_data %>%
  mutate(
    position = as.numeric(str_extract(
      !!sym(names(merged_data)[grepl("pos", names(merged_data), ignore.case = TRUE)][1]),
      "^\\d+"
    )),
    mutation_type = str_extract(
      !!sym(names(merged_data)[grepl("pos", names(merged_data), ignore.case = TRUE)][1]),
      "[A-Z]+>[A-Z]+$"
    ),
    is_seed_region = position >= 2 & position <= 7,
    is_gt_mutation = str_detect(mutation_type, "G>T", negate = FALSE)
  )

log_success(paste("Data merged:", nrow(merged_data), "mutations"))

# Detect group mean columns
group_cols <- detect_group_mean_columns(merged_data)
log_info(paste("Detected group mean columns:", group_cols$group1_mean, "and", group_cols$group2_mean))

# Build column selection list for group means (with fallback)
group_mean_cols <- c()
if (!is.null(group_cols$group1_mean) && group_cols$group1_mean %in% names(merged_data)) {
  group_mean_cols <- c(group_mean_cols, group_cols$group1_mean)
}
if (!is.null(group_cols$group2_mean) && group_cols$group2_mean %in% names(merged_data)) {
  group_mean_cols <- c(group_mean_cols, group_cols$group2_mean)
}
# Always include ALS_mean and Control_mean as fallback (for backward compatibility)
if ("ALS_mean" %in% names(merged_data) && !"ALS_mean" %in% group_mean_cols) {
  group_mean_cols <- c(group_mean_cols, "ALS_mean")
}
if ("Control_mean" %in% names(merged_data) && !"Control_mean" %in% group_mean_cols) {
  group_mean_cols <- c(group_mean_cols, "Control_mean")
}

# ============================================================================
# TABLE 1: SIGNIFICANT MUTATIONS (p_adj < alpha)
# ============================================================================

log_subsection("Generating significant mutations table")

# Determine which p-value column to use
p_col <- if ("p_adjusted" %in% names(merged_data)) {
  "p_adjusted"
} else if ("t_test_fdr" %in% names(merged_data)) {
  "t_test_fdr"
} else if ("wilcoxon_fdr" %in% names(merged_data)) {
  "wilcoxon_fdr"
} else {
  "p_value"  # Fallback
}

significant_mutations <- merged_data %>%
  filter(!!sym(p_col) < alpha) %>%
  mutate(
    sort_value = ifelse(
      "cohens_d" %in% names(.) & !is.na(cohens_d), 
      abs(cohens_d),
      ifelse(
        "fold_change" %in% names(.) & !is.na(fold_change),
        abs(fold_change),
        ifelse(
          "log2_fold_change" %in% names(.) & !is.na(log2_fold_change),
          abs(log2_fold_change),
          0
        )
      )
    )
  ) %>%
  arrange(desc(sort_value)) %>%
  select(
    any_of(c("SNV_id", names(merged_data)[grepl("SNV", names(merged_data), ignore.case = TRUE)])),
    any_of(c("miRNA_name", names(merged_data)[grepl("miRNA", names(merged_data), ignore.case = TRUE)])),
    position,
    mutation_type,
    any_of(group_mean_cols),  # Dynamic group columns
    any_of(c("fold_change", names(merged_data)[grepl("fold_change", names(merged_data), ignore.case = TRUE)])),
    any_of(c("log2_fold_change", names(merged_data)[grepl("log2_fold", names(merged_data), ignore.case = TRUE)])),
    any_of(c("p_value", "t_test_pvalue", names(merged_data)[grepl("^p_value|pvalue", names(merged_data), ignore.case = TRUE)])),
    any_of(c("p_adjusted", "t_test_fdr", "wilcoxon_fdr", names(merged_data)[grepl("fdr|adjusted", names(merged_data), ignore.case = TRUE)])),
    any_of(c("cohens_d", names(merged_data)[grepl("cohens", names(merged_data), ignore.case = TRUE)])),
    any_of(c("effect_size_category", names(merged_data)[grepl("effect_size", names(merged_data), ignore.case = TRUE)])),
    is_seed_region,
    is_gt_mutation,
    any_of(c("significant", names(merged_data)[grepl("significant", names(merged_data), ignore.case = TRUE)]))
  )

log_info(paste("Significant mutations found:", nrow(significant_mutations)))

# Save
write_csv(significant_mutations, output_significant)
log_success(paste("Table saved:", output_significant))

# ============================================================================
# TABLE 2: TOP 50 EFFECT SIZES
# ============================================================================

log_subsection("Generating top effect sizes table")

# Determine effect size column
effect_col <- if ("cohens_d" %in% names(merged_data)) {
  "cohens_d"
} else if ("fold_change" %in% names(merged_data)) {
  "fold_change"
} else {
  "log2_fold_change"
}

top_effect_sizes <- merged_data %>%
  arrange(desc(abs(!!sym(effect_col)))) %>%
  head(50) %>%
  mutate(rank = row_number()) %>%
  mutate(
    interpretation = case_when(
      "cohens_d" %in% names(.) & !is.na(cohens_d) & abs(cohens_d) >= 0.8 ~ "Large effect",
      "cohens_d" %in% names(.) & !is.na(cohens_d) & abs(cohens_d) >= 0.5 ~ "Medium effect",
      "cohens_d" %in% names(.) & !is.na(cohens_d) & abs(cohens_d) >= 0.2 ~ "Small effect",
      TRUE ~ "Negligible effect"
    )
  ) %>%
  select(
    rank,
    any_of(c("SNV_id", names(merged_data)[grepl("SNV", names(merged_data), ignore.case = TRUE)])),
    any_of(c("miRNA_name", names(merged_data)[grepl("miRNA", names(merged_data), ignore.case = TRUE)])),
    position,
    mutation_type,
    any_of(group_mean_cols),  # Dynamic group columns
    any_of(c("fold_change", names(merged_data)[grepl("fold_change", names(merged_data), ignore.case = TRUE)])),
    any_of(c("log2_fold_change", names(merged_data)[grepl("log2_fold", names(merged_data), ignore.case = TRUE)])),
    any_of(c("cohens_d", names(merged_data)[grepl("cohens", names(merged_data), ignore.case = TRUE)])),
    any_of(c("effect_size_category", names(merged_data)[grepl("effect_size", names(merged_data), ignore.case = TRUE)])),
    any_of(c("p_adjusted", "t_test_fdr", "wilcoxon_fdr", names(merged_data)[grepl("fdr|adjusted", names(merged_data), ignore.case = TRUE)])),
    any_of(c("significant", names(merged_data)[grepl("significant", names(merged_data), ignore.case = TRUE)])),
    interpretation
  )

log_success(paste("Top 50 effect sizes selected"))

# Save
write_csv(top_effect_sizes, output_top_effects)
log_success(paste("Table saved:", output_top_effects))

# ============================================================================
# TABLE 3: SEED REGION SIGNIFICANT MUTATIONS
# ============================================================================

log_subsection("Generating seed region significant mutations table")

seed_significant <- merged_data %>%
  filter(
    is_seed_region,
    !!sym(p_col) < alpha
  ) %>%
  mutate(
    sort_value = ifelse(
      "cohens_d" %in% names(.) & !is.na(cohens_d), 
      abs(cohens_d),
      ifelse(
        "fold_change" %in% names(.) & !is.na(fold_change),
        abs(fold_change),
        ifelse(
          "log2_fold_change" %in% names(.) & !is.na(log2_fold_change),
          abs(log2_fold_change),
          0
        )
      )
    )
  ) %>%
  arrange(desc(sort_value)) %>%
  select(
    any_of(c("SNV_id", names(merged_data)[grepl("SNV", names(merged_data), ignore.case = TRUE)])),
    any_of(c("miRNA_name", names(merged_data)[grepl("miRNA", names(merged_data), ignore.case = TRUE)])),
    position,
    mutation_type,
    any_of(group_mean_cols),  # Dynamic group columns
    any_of(c("fold_change", names(merged_data)[grepl("fold_change", names(merged_data), ignore.case = TRUE)])),
    any_of(c("log2_fold_change", names(merged_data)[grepl("log2_fold", names(merged_data), ignore.case = TRUE)])),
    any_of(c("p_value", "t_test_pvalue", names(merged_data)[grepl("^p_value|pvalue", names(merged_data), ignore.case = TRUE)])),
    any_of(c("p_adjusted", "t_test_fdr", "wilcoxon_fdr", names(merged_data)[grepl("fdr|adjusted", names(merged_data), ignore.case = TRUE)])),
    any_of(c("cohens_d", names(merged_data)[grepl("cohens", names(merged_data), ignore.case = TRUE)])),
    any_of(c("effect_size_category", names(merged_data)[grepl("effect_size", names(merged_data), ignore.case = TRUE)])),
    is_gt_mutation,
    any_of(c("significant", names(merged_data)[grepl("significant", names(merged_data), ignore.case = TRUE)]))
  )

log_info(paste("Seed region significant mutations:", nrow(seed_significant)))
log_info(paste("  - G>T mutations:", sum(seed_significant$is_gt_mutation, na.rm = TRUE)))
log_info(paste("  - Other mutations:", sum(!seed_significant$is_gt_mutation, na.rm = TRUE)))

# Save
write_csv(seed_significant, output_seed_significant)
log_success(paste("Table saved:", output_seed_significant))

# ============================================================================
# SUMMARY STATISTICS
# ============================================================================

log_subsection("Summary Statistics")

log_info("═══════════════════════════════════════════════════════════")
log_info("SUMMARY OF SIGNIFICANT MUTATIONS")
log_info("═══════════════════════════════════════════════════════════")
log_info(paste("Total significant mutations (p <", alpha, "):", nrow(significant_mutations)))
log_info(paste("  - In seed region (pos 2-7):", nrow(seed_significant)))
log_info(paste("  - G>T mutations:", sum(significant_mutations$is_gt_mutation, na.rm = TRUE)))
log_info(paste("  - Other mutations:", sum(!significant_mutations$is_gt_mutation, na.rm = TRUE)))
log_info(paste("Top effect size (abs):", round(max(abs(merged_data[[effect_col]]), na.rm = TRUE), 3)))
log_info("═══════════════════════════════════════════════════════════")

log_success("All summary tables generated successfully")
log_info(paste("Execution completed at", get_timestamp()))
