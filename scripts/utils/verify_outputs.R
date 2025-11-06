#!/usr/bin/env Rscript
# ============================================================================
# OUTPUT VERIFICATION UTILITY
# ============================================================================
# Purpose: Comprehensive verification of pipeline outputs
# 
# Usage:
#   Rscript scripts/utils/verify_outputs.R [step_name] [output_dir]
#   Or use as function: verify_step_outputs(step_name, output_dir)
# ============================================================================

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
})

# ============================================================================
# VERIFICATION FUNCTIONS
# ============================================================================

#' Verify that a file exists and has minimum size
#' 
#' @param file_path Path to file
#' @param min_size_bytes Minimum file size in bytes (default: 1000)
#' @param context Context for error messages
#' @return TRUE if valid, FALSE otherwise
verify_file <- function(file_path, min_size_bytes = 1000, context = "File verification") {
  if (!file.exists(file_path)) {
    cat("❌", context, "- File not found:", file_path, "\n")
    return(FALSE)
  }
  
  file_size <- file.info(file_path)$size
  if (file_size < min_size_bytes) {
    cat("⚠️", context, "- File too small (", file_size, "bytes):", basename(file_path), "\n", sep = "")
    return(FALSE)
  }
  
  cat("✅", context, "- File valid:", basename(file_path), "(", file_size, "bytes)\n", sep = "")
  return(TRUE)
}

#' Verify CSV file structure
#' 
#' @param csv_path Path to CSV file
#' @param min_rows Minimum number of rows (default: 1)
#' @param required_cols Required column names (optional)
#' @return TRUE if valid, FALSE otherwise
verify_csv <- function(csv_path, min_rows = 1, required_cols = NULL) {
  if (!file.exists(csv_path)) {
    cat("❌ CSV file not found:", csv_path, "\n")
    return(FALSE)
  }
  
  tryCatch({
    data <- read_csv(csv_path, show_col_types = FALSE)
    
    if (nrow(data) < min_rows) {
      cat("⚠️ CSV file has fewer rows than expected:", basename(csv_path), "\n")
      return(FALSE)
    }
    
    if (!is.null(required_cols)) {
      missing_cols <- setdiff(required_cols, names(data))
      if (length(missing_cols) > 0) {
        cat("⚠️ CSV file missing required columns:", paste(missing_cols, collapse = ", "), "\n")
        return(FALSE)
      }
    }
    
    cat("✅ CSV file valid:", basename(csv_path), "(", nrow(data), "rows, ", length(names(data)), "columns)\n", sep = "")
    return(TRUE)
  }, error = function(e) {
    cat("❌ CSV file cannot be read:", basename(csv_path), "-", e$message, "\n")
    return(FALSE)
  })
}

#' Verify PNG file
#' 
#' @param png_path Path to PNG file
#' @param min_size_bytes Minimum file size in bytes (default: 5000)
#' @return TRUE if valid, FALSE otherwise
verify_png <- function(png_path, min_size_bytes = 5000) {
  if (!file.exists(png_path)) {
    cat("❌ PNG file not found:", png_path, "\n")
    return(FALSE)
  }
  
  file_size <- file.info(png_path)$size
  if (file_size < min_size_bytes) {
    cat("⚠️ PNG file too small (", file_size, "bytes):", basename(png_path), "\n", sep = "")
    return(FALSE)
  }
  
  # Check if it's a valid PNG by reading magic bytes
  tryCatch({
    magic_bytes <- readBin(png_path, "raw", n = 8)
    if (magic_bytes[1] == 0x89 && magic_bytes[2] == 0x50 && 
        magic_bytes[3] == 0x4E && magic_bytes[4] == 0x47) {
      cat("✅ PNG file valid:", basename(png_path), "(", file_size, "bytes)\n", sep = "")
      return(TRUE)
    } else {
      cat("⚠️ File may not be a valid PNG:", basename(png_path), "\n")
      return(FALSE)
    }
  }, error = function(e) {
    cat("⚠️ Could not verify PNG format:", basename(png_path), "\n")
    return(FALSE)
  })
}

#' Verify step outputs
#' 
#' @param step_name Name of the step (e.g., "Step 1", "Step 2")
#' @param output_dir Output directory for the step
#' @param expected_files Named list of expected files with their types and min sizes
#' @return TRUE if all verifications pass
verify_step_outputs <- function(step_name, output_dir, expected_files = NULL) {
  
  cat("\n")
  cat("═══════════════════════════════════════════════════════════\n")
  cat("  📊 VERIFYING OUTPUTS:", step_name, "\n")
  cat("═══════════════════════════════════════════════════════════\n")
  cat("\n")
  
  if (!dir.exists(output_dir)) {
    cat("❌ Output directory not found:", output_dir, "\n")
    return(FALSE)
  }
  
  cat("📂 Output directory:", output_dir, "\n\n")
  
  all_valid <- TRUE
  
  # If expected files provided, verify them
  if (!is.null(expected_files)) {
    cat("🔍 Verifying expected files...\n")
    
    for (file_name in names(expected_files)) {
      file_info <- expected_files[[file_name]]
      file_path <- file.path(output_dir, file_name)
      
      file_type <- if (!is.null(file_info$type)) file_info$type else "file"
      min_size <- if (!is.null(file_info$min_size)) file_info$min_size else 1000
      
      if (file_type == "png") {
        valid <- verify_png(file_path, min_size_bytes = min_size)
      } else if (file_type == "csv") {
        valid <- verify_csv(file_path, min_rows = if (!is.null(file_info$min_rows)) file_info$min_rows else 1,
                           required_cols = file_info$required_cols)
      } else {
        valid <- verify_file(file_path, min_size_bytes = min_size, 
                           context = paste(step_name, "-", basename(file_name)))
      }
      
      if (!valid) {
        all_valid <- FALSE
      }
    }
    
    cat("\n")
  }
  
  # Also check directory structure
  cat("🔍 Verifying directory structure...\n")
  
  expected_dirs <- c("figures", "tables", "logs")
  for (dir_name in expected_dirs) {
    dir_path <- file.path(output_dir, dir_name)
    if (dir.exists(dir_path)) {
      n_files <- length(list.files(dir_path, recursive = FALSE))
      cat("   ✅", dir_name, "directory exists (", n_files, "files)\n", sep = "")
    } else {
      cat("   ⚠️", dir_name, "directory not found\n")
    }
  }
  
  cat("\n")
  
  # Summary
  cat("═══════════════════════════════════════════════════════════\n")
  if (all_valid) {
    cat("✅", step_name, "outputs verified successfully\n")
  } else {
    cat("⚠️", step_name, "outputs have some issues (see above)\n")
  }
  cat("═══════════════════════════════════════════════════════════\n")
  cat("\n")
  
  return(all_valid)
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  
  if (length(args) < 2) {
    cat("Usage: Rscript verify_outputs.R <step_name> <output_dir>\n")
    cat("Example: Rscript verify_outputs.R 'Step 1' results/step1/final\n")
    quit(status = 1)
  }
  
  step_name <- args[1]
  output_dir <- args[2]
  
  # Adjust path if running from scripts/utils/
  if (basename(getwd()) == "utils") {
    output_dir <- file.path("..", "..", output_dir)
  }
  
  success <- verify_step_outputs(step_name, output_dir)
  
  # Exit with appropriate code
  if (!success) {
    quit(status = 1)
  }
}

