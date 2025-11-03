#!/usr/bin/env Rscript
# ============================================================================
# STEP OUTPUT VALIDATION
# ============================================================================
# Purpose: Validate all outputs for a specific pipeline step
# Usage: Rscript validate_step_outputs.R <step_name> <output_dir> <expected_files>
# ============================================================================

suppressPackageStartupMessages({
  library(readr)
  library(stringr)
})

# Source validation functions - find the script in the same directory
# Get script path from commandArgs (works in Rscript)
cmd_args <- commandArgs(trailingOnly = FALSE)
script_path <- grep("^--file=", cmd_args, value = TRUE)
if (length(script_path) > 0) {
  script_dir <- dirname(sub("^--file=", "", script_path))
} else {
  # Fallback: try to find from current working directory
  script_dir <- file.path(getwd(), "scripts", "utils")
}

validate_outputs_script <- file.path(script_dir, "validate_outputs.R")
if (!file.exists(validate_outputs_script)) {
  # Try alternative paths
  alt_paths <- c(
    "scripts/utils/validate_outputs.R",
    file.path(getwd(), "scripts/utils/validate_outputs.R"),
    "./scripts/utils/validate_outputs.R",
    file.path(dirname(getwd()), "scripts/utils/validate_outputs.R")
  )
  for (alt_path in alt_paths) {
    if (file.exists(alt_path)) {
      validate_outputs_script <- alt_path
      break
    }
  }
}

if (file.exists(validate_outputs_script)) {
  source(validate_outputs_script, local = TRUE)
} else {
  # Define basic validation functions inline if script not found
  validate_file <- function(path) {
    errors <- character(0)
    if (!file.exists(path)) {
      errors <- c(errors, paste("File does not exist:", path))
      return(errors)
    }
    if (file.info(path)$size == 0) {
      errors <- c(errors, paste("File is empty:", path))
    }
    return(errors)
  }
  
  validate_figure <- function(path) {
    errors <- validate_file(path)
    if (length(errors) > 0) return(errors)
    file_size <- file.info(path)$size
    if (file_size < 1024) {
      errors <- c(errors, paste("Image file is suspiciously small (<1KB):", path))
    }
    return(errors)
  }
  
  validate_table <- function(path) {
    errors <- validate_file(path)
    if (length(errors) > 0) return(errors)
    tryCatch({
      data <- read_delim(path, delim = ",", n_max = 10, show_col_types = FALSE)
      if (nrow(data) == 0 || ncol(data) == 0) {
        errors <- c(errors, paste("Table has no rows or columns:", path))
      }
    }, error = function(e) {
      errors <<- c(errors, paste("Cannot read table:", path, "-", e$message))
    })
    return(errors)
  }
}

# Get command line arguments
args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2) {
  stop("Usage: Rscript validate_step_outputs.R <step_name> <output_dir> [expected_files_file]\n",
       "  expected_files_file: JSON file with list of expected files (optional)")
}

step_name <- args[1]
output_dir <- args[2]
expected_files_file <- if (length(args) > 2) args[3] else NULL

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  📋 VALIDATING STEP:", step_name, "\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

# Check output directory exists
if (!dir.exists(output_dir)) {
  cat("❌ ERROR: Output directory does not exist:", output_dir, "\n")
  quit(status = 1)
}

# Load expected files if provided
expected_files <- list()
if (!is.null(expected_files_file) && file.exists(expected_files_file)) {
  if (requireNamespace("jsonlite", quietly = TRUE)) {
    expected_files <- jsonlite::fromJSON(expected_files_file)
  }
}

# Validate figures
figures_dir <- file.path(output_dir, "figures")
if (dir.exists(figures_dir)) {
  cat("📊 Validating figures...\n")
  figures <- list.files(figures_dir, pattern = "\\.(png|pdf)$", full.names = TRUE)
  
  if (length(figures) == 0) {
    cat("  ⚠️  Warning: No figures found in", figures_dir, "\n")
  } else {
    for (fig in figures) {
      errors <- validate_figure(fig)
      if (length(errors) > 0) {
        cat("  ❌", basename(fig), ":", errors[1], "\n")
        quit(status = 1)
      }
    }
    cat("  ✅", length(figures), "figures validated\n")
  }
}

# Validate tables
tables_dir <- file.path(output_dir, "tables")
if (dir.exists(tables_dir)) {
  cat("\n📋 Validating tables...\n")
  tables <- list.files(tables_dir, pattern = "\\.(csv|tsv)$", full.names = TRUE)
  
  if (length(tables) == 0) {
    cat("  ⚠️  Warning: No tables found in", tables_dir, "\n")
  } else {
    for (table in tables) {
      errors <- validate_table(table)
      if (length(errors) > 0) {
        cat("  ❌", basename(table), ":", errors[1], "\n")
        quit(status = 1)
      }
    }
    cat("  ✅", length(tables), "tables validated\n")
  }
}

# Validate summary tables if they exist
summary_tables_dir <- file.path(output_dir, "tables", "summary")
if (dir.exists(summary_tables_dir)) {
  cat("\n📋 Validating summary tables...\n")
  summary_tables <- list.files(summary_tables_dir, pattern = "\\.(csv|tsv)$", full.names = TRUE)
  
  for (table in summary_tables) {
    errors <- validate_table(table)
    if (length(errors) > 0) {
      cat("  ❌", basename(table), ":", errors[1], "\n")
      quit(status = 1)
    }
  }
  if (length(summary_tables) > 0) {
    cat("  ✅", length(summary_tables), "summary tables validated\n")
  }
}

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("✅ STEP", step_name, "VALIDATION COMPLETE\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")
quit(status = 0)

