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

# Source validation functions
source("scripts/utils/validate_outputs.R", local = TRUE)

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

