#!/usr/bin/env Rscript
# ============================================================================
# OUTPUT VALIDATION SCRIPT
# ============================================================================
# Purpose: Validate that pipeline outputs exist, are not empty, and have
#          correct structure/content
# Usage: Rscript validate_outputs.R <output_file_or_dir> [validation_type]
# ============================================================================

suppressPackageStartupMessages({
  library(readr)
  library(stringr)
})

# Get command line arguments
args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 1) {
  stop("Usage: Rscript validate_outputs.R <output_path> [validation_type]\n",
       "  validation_type: 'file', 'figure', 'table', 'html', 'directory'")
}

output_path <- args[1]
validation_type <- if (length(args) > 1) args[2] else "auto"

# Determine validation type if auto
if (validation_type == "auto") {
  if (file.info(output_path)$isdir) {
    validation_type <- "directory"
  } else {
    ext <- tolower(tools::file_ext(output_path))
    validation_type <- switch(ext,
      "png" = "figure",
      "pdf" = "figure",
      "csv" = "table",
      "tsv" = "table",
      "html" = "html",
      "json" = "json",
      "yaml" = "yaml",
      "yml" = "yaml",
      "txt" = "file",
      "file"
    )
  }
}

# Validation functions
validate_file <- function(path) {
  errors <- character(0)
  
  # Check exists
  if (!file.exists(path)) {
    errors <- c(errors, paste("File does not exist:", path))
    return(errors)
  }
  
  # Check not empty
  file_size <- file.info(path)$size
  if (file_size == 0) {
    errors <- c(errors, paste("File is empty:", path))
  }
  
  # Check readable
  if (file.access(path, 4) != 0) {
    errors <- c(errors, paste("File is not readable:", path))
  }
  
  return(errors)
}

validate_figure <- function(path) {
  errors <- validate_file(path)
  
  if (length(errors) > 0) return(errors)
  
  # Check if it's a valid image file
  file_type <- system2("file", c("-b", shQuote(path)), stdout = TRUE, stderr = TRUE)
  
  if (length(file_type) == 0 || !grepl("PNG|JPEG|PDF", file_type, ignore.case = TRUE)) {
    errors <- c(errors, paste("File is not a valid image:", path))
  }
  
  # Check minimum size (at least 1KB for a valid image)
  file_size <- file.info(path)$size
  if (file_size < 1024) {
    errors <- c(errors, paste("Image file is suspiciously small (<1KB):", path))
  }
  
  return(errors)
}

validate_table <- function(path) {
  errors <- validate_file(path)
  
  if (length(errors) > 0) return(errors)
  
  # Try to read as CSV/TSV
  tryCatch({
    # Detect delimiter
    first_line <- readLines(path, n = 1)
    delimiter <- if (grepl("\t", first_line)) "\t" else ","
    
    # Read first few lines
    data <- read_delim(path, delim = delimiter, n_max = 10, show_col_types = FALSE)
    
    # Check has rows
    if (nrow(data) == 0) {
      errors <- c(errors, paste("Table has no rows:", path))
    }
    
    # Check has columns
    if (ncol(data) == 0) {
      errors <- c(errors, paste("Table has no columns:", path))
    }
    
  }, error = function(e) {
    errors <<- c(errors, paste("Cannot read table:", path, "-", e$message))
  })
  
  return(errors)
}

validate_html <- function(path) {
  errors <- validate_file(path)
  
  if (length(errors) > 0) return(errors)
  
  # Check contains HTML tags
  content <- readLines(path, n = 10, warn = FALSE)
  if (!any(grepl("<html|<HTML|<!DOCTYPE", content))) {
    errors <- c(errors, paste("File does not appear to be valid HTML:", path))
  }
  
  return(errors)
}

validate_json <- function(path) {
  errors <- validate_file(path)
  
  if (length(errors) > 0) return(errors)
  
  # Try to parse JSON
  tryCatch({
    jsonlite::fromJSON(path)
  }, error = function(e) {
    errors <<- c(errors, paste("Invalid JSON:", path, "-", e$message))
  })
  
  return(errors)
}

validate_yaml <- function(path) {
  errors <- validate_file(path)
  
  if (length(errors) > 0) return(errors)
  
  # Try to parse YAML
  if (requireNamespace("yaml", quietly = TRUE)) {
    tryCatch({
      yaml::read_yaml(path)
    }, error = function(e) {
      errors <<- c(errors, paste("Invalid YAML:", path, "-", e$message))
    })
  } else {
    # Basic check without yaml package
    content <- readLines(path, warn = FALSE)
    if (length(content) == 0) {
      errors <- c(errors, paste("YAML file is empty:", path))
    }
  }
  
  return(errors)
}

validate_directory <- function(path) {
  errors <- character(0)
  
  if (!dir.exists(path)) {
    errors <- c(errors, paste("Directory does not exist:", path))
    return(errors)
  }
  
  # Check not empty
  files <- list.files(path, recursive = FALSE, all.files = FALSE)
  if (length(files) == 0) {
    errors <- c(errors, paste("Directory is empty:", path))
  }
  
  return(errors)
}

# Main validation - only run if called directly (not sourced)
# Check if this script is being sourced or run directly
# When sourced, sys.frame(1)$ofile will be NULL or the calling script
# When run directly, we need to check commandArgs
cmd_args_full <- commandArgs(trailingOnly = FALSE)
is_direct_run <- any(grepl("^--file=", cmd_args_full)) && length(commandArgs(trailingOnly = TRUE)) >= 1

if (is_direct_run) {
  # This script is being run directly, perform validation
  cat("\n")
  cat("═══════════════════════════════════════════════════════════════════\n")
  cat("  📋 VALIDATING OUTPUTS\n")
  cat("═══════════════════════════════════════════════════════════════════\n\n")
  
  cat("Path:", output_path, "\n")
  cat("Type:", validation_type, "\n\n")
  
  errors <- switch(validation_type,
    "file" = validate_file(output_path),
    "figure" = validate_figure(output_path),
    "table" = validate_table(output_path),
    "html" = validate_html(output_path),
    "json" = validate_json(output_path),
    "yaml" = validate_yaml(output_path),
    "directory" = validate_directory(output_path),
    {
      warning("Unknown validation type: ", validation_type, ", using file validation")
      validate_file(output_path)
    }
  )
  
  # Print results
  if (length(errors) > 0) {
    cat("❌ VALIDATION FAILED\n")
    cat("═══════════════════════════════════════════════════════════════════\n\n")
    for (error in errors) {
      cat("  ❌", error, "\n")
    }
    cat("\n")
    quit(status = 1)
  } else {
    cat("✅ VALIDATION PASSED\n")
    cat("═══════════════════════════════════════════════════════════════════\n\n")
    quit(status = 0)
  }
}
# If sourced, just define functions and return silently

