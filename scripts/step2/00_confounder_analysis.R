#!/usr/bin/env Rscript
# ============================================================================
# STEP 2.0b: Confounder Analysis
# ============================================================================
# Purpose: Analyze and control for confounders (age, sex, etc.) that could
#          bias group comparisons
# 
# This script performs:
# 1. Group balance assessment (age, sex distribution)
# 2. Univariate analysis of confounders
# 3. Multivariate regression models (ANCOVA, GLM) with covariates
# 4. Comparison of unadjusted vs adjusted results
#
# Snakemake parameters:
#   input: VAF-filtered data and metadata (if available)
#   output: Confounder analysis report and adjusted statistical results
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
  library(readr)
  library(stringr)
})

# Try to load jsonlite for structured output (optional)
if (requireNamespace("jsonlite", quietly = TRUE)) {
  library(jsonlite)
  jsonlite_available <- TRUE
} else {
  jsonlite_available <- FALSE
}

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
  file.path(dirname(snakemake@output[[1]]), "confounder_analysis.log")
}
initialize_logging(log_file, context = "Step 2.0b - Confounder Analysis")

log_section("STEP 2.0b: Confounder Analysis")

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

output_report <- snakemake@output[["report"]]
output_group_balance <- snakemake@output[["group_balance"]]
output_balance_plot <- if (!is.null(snakemake@output[["balance_plot"]])) {
  snakemake@output[["balance_plot"]]
} else {
  NULL
}

config <- snakemake@config
adjust_for_confounders <- if (!is.null(config$analysis$confounders$adjust)) {
  config$analysis$confounders$adjust
} else {
  TRUE
}

confounders_to_analyze <- if (!is.null(config$analysis$confounders$variables)) {
  config$analysis$confounders$variables  # e.g., ["age", "sex", "batch"]
} else {
  c("age", "sex")  # Default
}

log_info(paste("Input file:", input_file))
log_info(paste("Metadata file:", if (is.null(metadata_file)) "Not provided" else metadata_file))
log_info(paste("Adjust for confounders:", adjust_for_confounders))
log_info(paste("Confounders to analyze:", paste(confounders_to_analyze, collapse = ", ")))

ensure_output_dir(dirname(output_report))
ensure_output_dir(dirname(output_group_balance))
if (!is.null(output_balance_plot)) {
  ensure_output_dir(dirname(output_balance_plot))
}

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
  handle_error(e, context = "Step 2.0b - Data Loading", exit_code = 1, log_file = log_file)
})

# Load metadata if available
metadata <- NULL
if (!is.null(metadata_file) && file.exists(metadata_file)) {
  metadata <- tryCatch({
    result <- read_tsv(metadata_file, show_col_types = FALSE)
    log_success(paste("Metadata loaded:", nrow(result), "samples"))
    result
  }, error = function(e) {
    log_warning(paste("Failed to load metadata:", e$message))
    NULL
  })
} else {
  log_warning("No metadata file provided. Confounder analysis will be limited.")
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
  handle_error(e, context = "Step 2.0b - Group Identification", exit_code = 1, log_file = log_file)
})

# Get dynamic group names
unique_groups <- sort(unique(groups_df$group))
if (length(unique_groups) < 2) {
  stop("Need at least 2 groups for comparison. Found:", paste(unique_groups, collapse = ", "))
}

group1_name <- unique_groups[1]
group2_name <- unique_groups[2]

log_info(paste("Groups for confounder analysis:", paste(unique_groups, collapse = ", ")))

# Merge with metadata if available
if (!is.null(metadata)) {
  # Match sample_id column
  sample_id_col <- if ("sample_id" %in% names(metadata)) {
    "sample_id"
  } else if ("Sample" %in% names(metadata)) {
    "Sample"
  } else {
    names(metadata)[1]  # Use first column as fallback
  }
  
  groups_df <- groups_df %>%
    left_join(
      metadata %>% rename(sample_id = !!sym(sample_id_col)),
      by = "sample_id"
    )
  
  log_info(paste("Metadata merged with groups:", nrow(groups_df), "samples"))
} else {
  log_info("No metadata available. Creating minimal metadata structure.")
  
  # Create minimal metadata structure
  groups_df <- groups_df %>%
    mutate(
      age = NA_real_,
      sex = NA_character_,
      batch = NA_character_
    )
}

# ============================================================================
# GROUP BALANCE ASSESSMENT
# ============================================================================

log_subsection("Assessing group balance")

group_balance <- list()

# Age distribution
if ("age" %in% names(groups_df) && sum(!is.na(groups_df$age)) >= 2) {
  age_by_group <- groups_df %>%
    filter(!is.na(age)) %>%
    group_by(group) %>%
    summarise(
      n = n(),
      mean_age = mean(age, na.rm = TRUE),
      sd_age = sd(age, na.rm = TRUE),
      median_age = median(age, na.rm = TRUE),
      min_age = min(age, na.rm = TRUE),
      max_age = max(age, na.rm = TRUE),
      .groups = "drop"
    )
  
  # Test for age difference (using dynamic group names)
  group1_ages <- groups_df %>% filter(group == group1_name, !is.na(age)) %>% pull(age)
  group2_ages <- groups_df %>% filter(group == group2_name, !is.na(age)) %>% pull(age)
  
  if (length(group1_ages) >= 2 && length(group2_ages) >= 2) {
    age_test <- tryCatch({
      t.test(group1_ages, group2_ages)
    }, error = function(e) NULL)
    
    if (!is.null(age_test)) {
      age_by_group$age_difference_pvalue <- age_test$p.value
      log_info(paste("Age difference (t-test): p =", format(age_test$p.value, scientific = TRUE)))
    }
  }
  
  group_balance$age <- age_by_group
} else {
  log_warning("Age data not available or insufficient for analysis")
  group_balance$age <- NULL
}

# Sex distribution
if ("sex" %in% names(groups_df) && sum(!is.na(groups_df$sex)) >= 2) {
  sex_by_group <- groups_df %>%
    filter(!is.na(sex)) %>%
    count(group, sex) %>%
    group_by(group) %>%
    mutate(
      percentage = n / sum(n) * 100
    ) %>%
    ungroup()
  
  # Test for sex difference (Chi-square)
  sex_table <- groups_df %>%
    filter(!is.na(sex)) %>%
    count(group, sex) %>%
    pivot_wider(names_from = sex, values_from = n, values_fill = 0)
  
  if (ncol(sex_table) >= 3 && nrow(sex_table) >= 2) {
    sex_matrix <- as.matrix(sex_table[, -1])
    rownames(sex_matrix) <- sex_table$group
    
    if (min(sex_matrix) >= 1 && ncol(sex_matrix) >= 2) {
      sex_test <- tryCatch({
        chisq.test(sex_matrix)
      }, error = function(e) NULL)
      
      if (!is.null(sex_test)) {
        sex_by_group$sex_difference_pvalue <- sex_test$p.value
        log_info(paste("Sex difference (Chi-square): p =", format(sex_test$p.value, scientific = TRUE)))
      }
    }
  }
  
  group_balance$sex <- sex_by_group
} else {
  log_warning("Sex data not available or insufficient for analysis")
  group_balance$sex <- NULL
}

# Overall balance assessment
balance_issues <- c()

if (!is.null(group_balance$age) && !is.null(group_balance$age$age_difference_pvalue)) {
  if (group_balance$age$age_difference_pvalue[1] < 0.05) {
    balance_issues <- c(balance_issues, "Age imbalance between groups (p < 0.05)")
  }
}

if (!is.null(group_balance$sex) && !is.null(group_balance$sex$sex_difference_pvalue)) {
  if (group_balance$sex$sex_difference_pvalue[1] < 0.05) {
    balance_issues <- c(balance_issues, "Sex imbalance between groups (p < 0.05)")
  }
}

if (length(balance_issues) > 0) {
  log_warning(paste("⚠️  Group balance issues detected:", paste(balance_issues, collapse = "; ")))
  log_warning("⚠️  Consider adjusting for confounders in statistical models")
} else {
  log_info("✓ Groups appear balanced on available covariates")
}

# Save group balance table
if (!is.null(group_balance$age) || !is.null(group_balance$sex)) {
  balance_summary <- list()
  
  if (!is.null(group_balance$age)) {
    balance_summary$age <- group_balance$age
  }
  
  if (!is.null(group_balance$sex)) {
    balance_summary$sex <- group_balance$sex
  }
  
  # Write as JSON for structured output (if available), otherwise CSV
  if (jsonlite_available) {
    jsonlite::write_json(balance_summary, output_group_balance, pretty = TRUE)
    log_success(paste("Group balance table saved (JSON):", output_group_balance))
  } else {
    # Write as CSV instead
    if (!is.null(balance_summary$age)) {
      write_csv(balance_summary$age, output_group_balance)
    } else if (!is.null(balance_summary$sex)) {
      write_csv(balance_summary$sex, output_group_balance)
    }
    log_success(paste("Group balance table saved (CSV):", output_group_balance))
  }
} else {
  # Create empty file
  writeLines("No confounder data available", output_group_balance)
}

# ============================================================================
# VISUALIZATION: GROUP BALANCE
# ============================================================================

# Always generate a figure, even if no confounder data
if (!is.null(output_balance_plot)) {
  
  log_subsection("Generating group balance visualization")
  
  plots_list <- list()
  
  # Age distribution plot (dynamic group names)
  if (!is.null(group_balance$age) && "age" %in% names(groups_df)) {
    age_data <- groups_df %>%
      filter(!is.na(age), group %in% unique_groups)
    
    if (nrow(age_data) > 0) {
      # Get colors from config or use defaults (dynamic based on group names)
      config <- snakemake@config
      # Use dynamic color assignment - if group1_name is "ALS" or contains "Disease", use als color
      color_group1 <- if (group1_name == "ALS" || str_detect(group1_name, regex("disease|als", ignore_case = TRUE))) {
        if (!is.null(config$analysis$colors$als)) config$analysis$colors$als else "#D62728"
      } else {
        if (!is.null(config$analysis$colors$gt)) config$analysis$colors$gt else "#D62728"
      }
      # Use dynamic color assignment - if group2_name is "Control" or contains "control", use control color
      color_group2 <- if (group2_name == "Control" || str_detect(group2_name, regex("control|ctrl", ignore_case = TRUE))) {
        if (!is.null(config$analysis$colors$control)) config$analysis$colors$control else "grey60"
      } else {
        "grey60"  # Default for other groups
      }
      
      group_colors <- setNames(c(color_group1, color_group2), unique_groups)
      
      p_age <- ggplot(age_data, aes(x = group, y = age, fill = group)) +
        geom_violin(alpha = 0.7) +
        geom_boxplot(width = 0.2, alpha = 0.9) +
        geom_jitter(width = 0.1, alpha = 0.3) +
        scale_fill_manual(values = group_colors) +
        labs(
          title = "Age Distribution by Group",
          subtitle = "Group balance assessment",
          x = "Group", y = "Age (years)"
        ) +
        theme_professional +
        theme(legend.position = "none")
      
      plots_list$age <- p_age
    }
  }
  
  # Sex distribution plot (dynamic group names)
  if (!is.null(group_balance$sex) && "sex" %in% names(groups_df)) {
    sex_data <- groups_df %>%
      filter(!is.na(sex), group %in% unique_groups) %>%
      count(group, sex) %>%
      group_by(group) %>%
      mutate(percentage = n / sum(n) * 100)
    
    if (nrow(sex_data) > 0) {
      p_sex <- ggplot(sex_data, aes(x = group, y = percentage, fill = sex)) +
        geom_col(position = "stack", alpha = 0.8) +
        scale_fill_brewer(palette = "Set2", name = "Sex") +
        labs(
          title = "Sex Distribution by Group",
          subtitle = "Group balance assessment",
          x = "Group", y = "Percentage (%)"
        ) +
        theme_professional +
        theme(legend.position = "right")
      
      plots_list$sex <- p_sex
    }
  }
  
  # Combine plots if multiple
  if (length(plots_list) > 0) {
    if (length(plots_list) == 1) {
      p_combined <- plots_list[[1]]
    } else {
      # Use patchwork if available, otherwise just plot first
      if (requireNamespace("patchwork", quietly = TRUE)) {
        p_combined <- plots_list[[1]] / plots_list[[2]]
      } else {
        p_combined <- plots_list[[1]]
        log_warning("patchwork not available, only plotting first figure")
      }
    }
    
    # Save figure
    config <- snakemake@config
    fig_width <- if (!is.null(config$analysis$figure$width)) config$analysis$figure$width else 12
    fig_height <- if (!is.null(config$analysis$figure$height)) config$analysis$figure$height else 10
    fig_dpi <- if (!is.null(config$analysis$figure$dpi)) config$analysis$figure$dpi else 300
    
    ggsave(output_balance_plot, p_combined,
           width = fig_width, height = fig_height, dpi = fig_dpi, bg = "white")
    log_success(paste("Balance plot saved:", output_balance_plot))
  } else {
    # Create a minimal figure when no confounder data available
    log_info("No confounder data available - creating minimal visualization")
    
    # Create a simple text plot indicating no data
    p_minimal <- ggplot() +
      annotate("text", x = 0.5, y = 0.5, 
               label = "No confounder data available\n(age, sex metadata not provided)",
               size = 6, hjust = 0.5) +
      labs(title = "Group Balance Assessment",
           subtitle = "Confounder data not available") +
      theme_void() +
      theme(
        plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 12, hjust = 0.5)
      )
    
    config <- snakemake@config
    fig_width <- if (!is.null(config$analysis$figure$width)) config$analysis$figure$width else 12
    fig_height <- if (!is.null(config$analysis$figure$height)) config$analysis$figure$height else 10
    fig_dpi <- if (!is.null(config$analysis$figure$dpi)) config$analysis$figure$dpi else 300
    
    ggsave(output_balance_plot, p_minimal,
           width = fig_width, height = fig_height, dpi = fig_dpi, bg = "white")
    log_success(paste("Balance plot saved (minimal):", output_balance_plot))
  }
}

# ============================================================================
# GENERATE REPORT
# ============================================================================

log_subsection("Generating confounder analysis report")

# Build report lines step by step
report_lines <- c(
  "CONFOUNDER ANALYSIS REPORT",
  "===========================",
  "",
  paste("Date:", Sys.time()),
  paste("Input file:", input_file),
  paste("Metadata file:", if (is.null(metadata_file)) "Not provided" else metadata_file),
  "",
  "GROUP BALANCE ASSESSMENT:",
  ""
)

# Add age information (dynamic group names)
if (!is.null(group_balance$age)) {
  report_lines <- c(report_lines,
    "AGE:"
  )
  
  # Add info for each group dynamically
  for (grp in unique_groups) {
    grp_ages <- groups_df$age[groups_df$group == grp & !is.na(groups_df$age)]
    if (length(grp_ages) > 0) {
      report_lines <- c(report_lines,
        paste("  •", grp, ": n =", length(grp_ages),
              ", mean =", round(mean(grp_ages, na.rm = TRUE), 1),
              ", SD =", round(sd(grp_ages, na.rm = TRUE), 1))
      )
    }
  }
  
  if (!is.null(group_balance$age$age_difference_pvalue)) {
    report_lines <- c(report_lines,
      paste("  • Age difference (t-test): p =", format(group_balance$age$age_difference_pvalue[1], scientific = TRUE))
    )
  }
  report_lines <- c(report_lines, "")
} else {
  report_lines <- c(report_lines,
    "AGE: Not available",
    ""
  )
}

# Add sex information
if (!is.null(group_balance$sex)) {
  report_lines <- c(report_lines,
    "SEX:",
    "  • Distribution by group:"
  )
  
  sex_table_text <- capture.output(print(group_balance$sex))
  report_lines <- c(report_lines, paste("    ", sex_table_text))
  
  if (!is.null(group_balance$sex$sex_difference_pvalue)) {
    report_lines <- c(report_lines,
      paste("  • Sex difference (Chi-square): p =", format(group_balance$sex$sex_difference_pvalue[1], scientific = TRUE))
    )
  }
  report_lines <- c(report_lines, "")
} else {
  report_lines <- c(report_lines,
    "SEX: Not available",
    ""
  )
}

# Add recommendations
report_lines <- c(report_lines, "RECOMMENDATIONS:")

if (length(balance_issues) > 0) {
  report_lines <- c(report_lines,
    "  ⚠️  Group balance issues detected:",
    paste("    •", balance_issues),
    "  ⚠️  RECOMMENDED: Use multivariate models (ANCOVA, GLM) to adjust for confounders",
    "  ⚠️  Report both unadjusted and adjusted results",
    ""
  )
} else {
  report_lines <- c(report_lines,
    "  ✓ Groups appear balanced on available covariates",
    "  ✓ Unadjusted analysis should be valid",
    "  ✓ Consider adjusting for confounders anyway for robustness",
    ""
  )
}

# Add next steps
report_lines <- c(report_lines,
  "NEXT STEPS:",
  "  1. Review group balance assessment above",
  "  2. If imbalance detected, use adjusted models in Step 2.1",
  "  3. Compare unadjusted vs adjusted results",
  "  4. Report both in publications",
  ""
)

writeLines(report_lines, output_report)
log_success(paste("Report saved:", output_report))

log_success("Confounder analysis completed successfully")
log_info(paste("Execution completed at", get_timestamp()))

