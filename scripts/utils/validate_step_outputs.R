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

# Define validation functions inline (avoid sourcing to prevent argument conflicts)
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
  
  # Check file type (basic check)
  file_size <- file.info(path)$size
  if (file_size < 1024) {
    errors <- c(errors, paste("Image file is suspiciously small (<1KB):", path))
  }
  
  # Try to check if it's a valid image (basic PNG check)
  if (file_size > 8) {
    # Read first bytes to check PNG signature
    first_bytes <- readBin(path, "raw", n = 8)
    if (length(first_bytes) >= 8) {
      # PNG signature: 89 50 4E 47 0D 0A 1A 0A
      png_signature <- as.raw(c(0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A))
      is_png <- all(first_bytes == png_signature)
      if (!is_png && !grepl("\\.pdf$", path, ignore.case = TRUE)) {
        # Not a PNG and not PDF, might still be valid (JPEG, etc.)
        # Just warn, don't fail
      }
    }
  }
  
  return(errors)
}

validate_table <- function(path) {
  errors <- validate_file(path)
  if (length(errors) > 0) return(errors)
  
  tryCatch({
    # Detect delimiter
    first_line <- readLines(path, n = 1)
    delimiter <- if (grepl("\t", first_line)) "\t" else ","
    
    # Read first few lines
    data <- read_delim(path, delim = delimiter, n_max = 10, show_col_types = FALSE)
    
    if (nrow(data) == 0) {
      errors <- c(errors, paste("Table has no rows:", path))
    }
    if (ncol(data) == 0) {
      errors <- c(errors, paste("Table has no columns:", path))
    }
  }, error = function(e) {
    errors <<- c(errors, paste("Cannot read table:", path, "-", e$message))
  })
  
  return(errors)
}

# Get command line arguments (must be after sourcing functions)
# Note: We need to get args AFTER sourcing validate_outputs.R because it might exit
args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2) {
  stop("Usage: Rscript validate_step_outputs.R <step_name> <output_dir> [expected_files_file]\n",
       "  expected_files_file: JSON file with list of expected files (optional)")
}

step_name <- args[1]
output_dir <- normalizePath(args[2], mustWork = FALSE)
expected_files_file <- if (length(args) > 2) args[3] else NULL

# Normalize output directory path
if (!dir.exists(output_dir)) {
  # Try as relative path
  if (dir.exists(file.path(getwd(), output_dir))) {
    output_dir <- normalizePath(file.path(getwd(), output_dir))
  }
}

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
    all_figure_errors <- character(0)
    for (fig in figures) {
      fig_errors <- validate_figure(fig)
      if (length(fig_errors) > 0) {
        all_figure_errors <- c(all_figure_errors, paste("  ❌", basename(fig), ":", fig_errors[1]))
      }
    }
    if (length(all_figure_errors) > 0) {
      for (err in all_figure_errors) {
        cat(err, "\n")
      }
      quit(status = 1)
    }
    cat("  ✅", length(figures), "figures validated\n")
  }
}

# Validate tables
tables_dir <- file.path(output_dir, "tables")
if (dir.exists(tables_dir)) {
  cat("\n📋 Validating tables...\n")
  tables <- list.files(tables_dir, pattern = "\\.(csv|tsv)$", full.names = TRUE, recursive = TRUE)
  
  if (length(tables) == 0) {
    cat("  ⚠️  Warning: No tables found in", tables_dir, "\n")
  } else {
    all_table_errors <- character(0)
    for (table in tables) {
      table_errors <- validate_table(table)
      if (length(table_errors) > 0) {
        all_table_errors <- c(all_table_errors, paste("  ❌", basename(table), ":", table_errors[1]))
      }
    }
    if (length(all_table_errors) > 0) {
      for (err in all_table_errors) {
        cat(err, "\n")
      }
      quit(status = 1)
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

