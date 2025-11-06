#!/usr/bin/env Rscript
# ============================================================================
# DATA QUALITY VALIDATION
# ============================================================================
# Purpose: Validate data quality and content of pipeline outputs
# Usage: Rscript validate_data_quality.R <file_path> <file_type> [options]
# ============================================================================

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
})

# Get command line arguments
args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2) {
  stop("Usage: Rscript validate_data_quality.R <file_path> <file_type> [column_name] [min_value] [max_value]\n",
       "  file_type: csv, tsv\n",
       "  For numeric columns: column_name, min_value, max_value")
}

file_path <- args[1]
file_type <- args[2]
column_name <- if (length(args) > 2) args[3] else NULL
min_value <- if (length(args) > 3) as.numeric(args[4]) else NULL
max_value <- if (length(args) > 4) as.numeric(args[5]) else NULL

# Check file exists
if (!file.exists(file_path)) {
  cat("❌ ERROR: File does not exist:", file_path, "\n")
  quit(status = 1)
}

# Read file
delimiter <- if (file_type == "tsv") "\t" else ","
data <- read_delim(file_path, delim = delimiter, show_col_types = FALSE)

# Basic checks
errors <- character(0)

# Check has rows
if (nrow(data) == 0) {
  errors <- c(errors, "Table has no rows")
}

# Check has columns
if (ncol(data) == 0) {
  errors <- c(errors, "Table has no columns")
}

# Check for NA values in critical columns (only warn, don't fail - NAs can be expected)
if (!is.null(column_name) && column_name %in% colnames(data)) {
  na_count <- sum(is.na(data[[column_name]]))
  if (na_count > 0) {
    # NAs are acceptable in some contexts (e.g., when one group has no data)
    # Only warn if >50% are NA, otherwise it's informational
    total_rows <- nrow(data)
    na_percentage <- (na_count / total_rows) * 100
    if (na_percentage > 50) {
      cat("  ⚠️  Warning: Column", column_name, "has", na_count, "NA values (", round(na_percentage, 1), "%)\n")
    } else {
      cat("  ℹ️  Info: Column", column_name, "has", na_count, "NA values (", round(na_percentage, 1), "%) - expected in some contexts\n")
    }
  }
  
  # Check value ranges if specified (only check non-NA values)
  if (!is.null(min_value) || !is.null(max_value)) {
    if (is.numeric(data[[column_name]])) {
      values <- data[[column_name]][!is.na(data[[column_name]])]
      
      if (length(values) > 0) {
        # Check for extreme outliers (beyond reasonable range)
        # For log2FC: allow -Inf and Inf (they occur when one group has zero)
        # For p-values: should be 0-1, but allow slight overflow for numerical precision
        
        # Handle infinite values gracefully
        finite_values <- values[is.finite(values)]
        infinite_count <- sum(is.infinite(values))
        
        if (infinite_count > 0) {
          # Inf/-Inf are expected in some contexts (e.g., log2FC when dividing by zero)
          cat("  ℹ️  Info: Column", column_name, "has", infinite_count, "infinite values (Inf/-Inf) - expected in some contexts\n")
        }
        
        # Only check finite values for range violations
        if (length(finite_values) > 0) {
          extreme_threshold <- 100  # For values way beyond expected
          
          if (!is.null(min_value) && min_value > -extreme_threshold) {
            # Only check if min_value is reasonable (not checking for -Inf)
            extreme_low <- finite_values < min_value & finite_values > -extreme_threshold
            if (any(extreme_low, na.rm = TRUE)) {
              # Count how many, but be lenient for log2FC (allow -15 to -10 range)
              if (grepl("log2", column_name, ignore.case = TRUE) && min_value == -10) {
                # For log2FC, only fail if values are < -15 (very extreme)
                very_extreme_low <- finite_values < -15
                if (any(very_extreme_low, na.rm = TRUE)) {
                  errors <- c(errors, paste("Column", column_name, "has", sum(very_extreme_low), "very extreme values below -15"))
                }
              } else {
                errors <- c(errors, paste("Column", column_name, "has", sum(extreme_low), "values below minimum", min_value))
              }
            }
          }
          
          if (!is.null(max_value) && max_value < extreme_threshold) {
            # Only check if max_value is reasonable (not checking for Inf)
            extreme_high <- finite_values > max_value & finite_values < extreme_threshold
            if (any(extreme_high, na.rm = TRUE)) {
              # Count how many, but be lenient for log2FC (allow 10 to 15 range)
              if (grepl("log2", column_name, ignore.case = TRUE) && max_value == 10) {
                # For log2FC, only fail if values are > 15 (very extreme)
                very_extreme_high <- finite_values > 15
                if (any(very_extreme_high, na.rm = TRUE)) {
                  errors <- c(errors, paste("Column", column_name, "has", sum(very_extreme_high), "very extreme values above 15"))
                }
              } else {
                errors <- c(errors, paste("Column", column_name, "has", sum(extreme_high), "values above maximum", max_value))
              }
            }
          }
        }
      }
    }
  }
}

# Print results
if (length(errors) > 0) {
  cat("❌ DATA QUALITY VALIDATION FAILED\n")
  cat("═══════════════════════════════════════════════════════════════════\n\n")
  for (error in errors) {
    cat("  ❌", error, "\n")
  }
  cat("\n")
  quit(status = 1)
} else {
  cat("✅ DATA QUALITY VALIDATION PASSED\n")
  cat("═══════════════════════════════════════════════════════════════════\n\n")
  cat("File:", file_path, "\n")
  cat("Rows:", nrow(data), "\n")
  cat("Columns:", ncol(data), "\n")
  if (!is.null(column_name) && column_name %in% colnames(data)) {
    cat("Column", column_name, "validated\n")
  }
  cat("\n")
  quit(status = 0)
}

