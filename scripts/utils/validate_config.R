#!/usr/bin/env Rscript
# ============================================================================
# CONFIGURATION VALIDATION
# ============================================================================
# Purpose: Validate config.yaml parameters before pipeline execution
# 
# Usage:
#   Rscript scripts/utils/validate_config.R config/config.yaml
# ============================================================================

suppressPackageStartupMessages({
  library(yaml)
  library(readr)
})

# ============================================================================
# VALIDATION FUNCTIONS
# ============================================================================

#' Validate configuration file
#' 
#' @param config_file Path to config.yaml file
#' @return TRUE if valid, stops execution with detailed error messages otherwise
validate_config <- function(config_file) {
  
  cat("\n")
  cat("═══════════════════════════════════════════════════════════\n")
  cat("  📋 VALIDATING CONFIGURATION FILE\n")
  cat("═══════════════════════════════════════════════════════════\n")
  cat("\n")
  
  # Check if config file exists
  if (!file.exists(config_file)) {
    stop(paste("❌ Configuration file not found:", config_file))
  }
  
  cat("📂 Loading configuration from:", config_file, "\n")
  
  # Load config
  config <- tryCatch({
    yaml::read_yaml(config_file)
  }, error = function(e) {
    stop(paste("❌ Failed to parse YAML file:", e$message))
  })
  
  cat("   ✅ Configuration file loaded successfully\n\n")
  
  errors <- character(0)
  warnings <- character(0)
  
  # ==========================================================================
  # VALIDATE PATHS
  # ==========================================================================
  
  cat("🔍 Validating paths...\n")
  
  if (is.null(config$paths)) {
    errors <- c(errors, "Missing 'paths' section in config")
  } else {
    # Validate data paths
    if (!is.null(config$paths$data)) {
      # Raw data file
      if (!is.null(config$paths$data$raw)) {
        raw_path <- config$paths$data$raw
        if (!file.exists(raw_path)) {
          errors <- c(errors, paste("Raw data file not found:", raw_path))
        } else {
          cat("   ✅ Raw data file exists:", basename(raw_path), "\n")
        }
      }
      
      # Processed data file
      if (!is.null(config$paths$data$processed_clean)) {
        processed_path <- config$paths$data$processed_clean
        if (!file.exists(processed_path)) {
          warnings <- c(warnings, paste("Processed data file not found (will be created):", processed_path))
        } else {
          cat("   ✅ Processed data file exists:", basename(processed_path), "\n")
        }
      }
      
      # Metadata file (optional)
      if (!is.null(config$paths$data$metadata)) {
        metadata_path <- config$paths$data$metadata
        if (!is.null(metadata_path) && metadata_path != "null" && metadata_path != "") {
          if (!file.exists(metadata_path)) {
            warnings <- c(warnings, paste("Metadata file not found (will use pattern matching):", metadata_path))
          } else {
            cat("   ✅ Metadata file exists:", basename(metadata_path), "\n")
          }
        }
      }
    }
    
    # Validate output directories can be created
    if (!is.null(config$paths$outputs)) {
      output_dirs <- unlist(config$paths$outputs)
      for (dir_name in names(output_dirs)) {
        dir_path <- output_dirs[[dir_name]]
        dir_parent <- dirname(dir_path)
        if (dir_parent != "." && !dir.exists(dir_parent)) {
          # Try to create parent directory
          tryCatch({
            dir.create(dir_parent, recursive = TRUE, showWarnings = FALSE)
            cat("   ✅ Created output directory parent:", dir_parent, "\n")
          }, error = function(e) {
            errors <- c(errors, paste("Cannot create output directory parent:", dir_parent, "-", e$message))
          })
        }
      }
      cat("   ✅ Output directories validated\n")
    }
  }
  
  cat("\n")
  
  # ==========================================================================
  # VALIDATE ANALYSIS PARAMETERS
  # ==========================================================================
  
  cat("🔍 Validating analysis parameters...\n")
  
  if (is.null(config$analysis)) {
    errors <- c(errors, "Missing 'analysis' section in config")
  } else {
    # VAF filter threshold
    if (!is.null(config$analysis$vaf_filter_threshold)) {
      vaf_threshold <- config$analysis$vaf_filter_threshold
      if (!is.numeric(vaf_threshold) || vaf_threshold <= 0 || vaf_threshold >= 1) {
        errors <- c(errors, paste("vaf_filter_threshold must be between 0 and 1. Found:", vaf_threshold))
      } else {
        cat("   ✅ VAF filter threshold:", vaf_threshold, "\n")
      }
    }
    
    # Alpha (significance threshold)
    if (!is.null(config$analysis$alpha)) {
      alpha <- config$analysis$alpha
      if (!is.numeric(alpha) || alpha <= 0 || alpha >= 1) {
        errors <- c(errors, paste("alpha must be between 0 and 1. Found:", alpha))
      } else {
        cat("   ✅ Significance threshold (alpha):", alpha, "\n")
      }
    }
    
    # Log2FC thresholds
    log2fc_params <- c("log2fc_threshold_step2", "log2fc_threshold_step3", "log2fc_threshold_step6")
    for (param in log2fc_params) {
      if (!is.null(config$analysis[[param]])) {
        log2fc_val <- config$analysis[[param]]
        if (!is.numeric(log2fc_val) || log2fc_val < 0) {
          errors <- c(errors, paste(param, "must be >= 0. Found:", log2fc_val))
        } else {
          cat("   ✅", param, ":", log2fc_val, "\n")
        }
      }
    }
    
    # Seed region
    if (!is.null(config$analysis$seed_region)) {
      seed_start <- config$analysis$seed_region$start
      seed_end <- config$analysis$seed_region$end
      if (!is.null(seed_start) && !is.null(seed_end)) {
        if (!is.numeric(seed_start) || seed_start < 1 || seed_start > 24) {
          errors <- c(errors, paste("seed_region.start must be between 1 and 24. Found:", seed_start))
        }
        if (!is.numeric(seed_end) || seed_end < 1 || seed_end > 24) {
          errors <- c(errors, paste("seed_region.end must be between 1 and 24. Found:", seed_end))
        }
        if (seed_start >= seed_end) {
          errors <- c(errors, paste("seed_region.start must be < seed_region.end. Found:", seed_start, ">=", seed_end))
        } else {
          cat("   ✅ Seed region: positions", seed_start, "-", seed_end, "\n")
        }
      }
    }
    
    # Figure settings
    if (!is.null(config$analysis$figure)) {
      dpi <- config$analysis$figure$dpi
      if (!is.null(dpi) && (!is.numeric(dpi) || dpi < 72 || dpi > 600)) {
        warnings <- c(warnings, paste("DPI should typically be between 72-600. Found:", dpi))
      } else if (!is.null(dpi)) {
        cat("   ✅ Figure DPI:", dpi, "\n")
      }
    }
  }
  
  cat("\n")
  
  # ==========================================================================
  # VALIDATE COLORS
  # ==========================================================================
  
  cat("🔍 Validating visualization colors...\n")
  
  if (!is.null(config$analysis$colors)) {
    # Check if colors are valid (basic check - valid hex or named colors)
    color_params <- c("gt", "control", "als")
    for (color_param in color_params) {
      if (!is.null(config$analysis$colors[[color_param]])) {
        color_val <- config$analysis$colors[[color_param]]
        # Basic validation: check if it's a valid color format
        if (is.character(color_val) && nchar(color_val) > 0) {
          cat("   ✅", color_param, "color:", color_val, "\n")
        } else {
          warnings <- c(warnings, paste("Color", color_param, "may not be valid:", color_val))
        }
      }
    }
  }
  
  cat("\n")
  
  # ==========================================================================
  # REPORT RESULTS
  # ==========================================================================
  
  cat("═══════════════════════════════════════════════════════════\n")
  cat("  📊 VALIDATION SUMMARY\n")
  cat("═══════════════════════════════════════════════════════════\n")
  cat("\n")
  
  if (length(warnings) > 0) {
    cat("⚠️  WARNINGS (", length(warnings), "):\n", sep = "")
    for (i in seq_along(warnings)) {
      cat("   ", i, ". ", warnings[i], "\n", sep = "")
    }
    cat("\n")
  }
  
  if (length(errors) > 0) {
    cat("❌ ERRORS (", length(errors), "):\n", sep = "")
    for (i in seq_along(errors)) {
      cat("   ", i, ". ", errors[i], "\n", sep = "")
    }
    cat("\n")
    cat("═══════════════════════════════════════════════════════════\n")
    cat("❌ CONFIGURATION VALIDATION FAILED\n")
    cat("═══════════════════════════════════════════════════════════\n")
    cat("\n")
    cat("Please fix the errors above before running the pipeline.\n")
    cat("See config/config.yaml.example for reference.\n")
    cat("\n")
    stop("Configuration validation failed")
  }
  
  cat("✅ All configuration parameters are valid!\n")
  cat("\n")
  cat("═══════════════════════════════════════════════════════════\n")
  cat("✅ CONFIGURATION VALIDATION PASSED\n")
  cat("═══════════════════════════════════════════════════════════\n")
  cat("\n")
  
  return(TRUE)
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

if (!interactive()) {
  # Get config file from command line or use default
  args <- commandArgs(trailingOnly = TRUE)
  config_file <- if (length(args) > 0) args[1] else "config/config.yaml"
  
  # If running from scripts/utils/, adjust path
  if (basename(getwd()) == "utils") {
    config_file <- file.path("..", "..", config_file)
  }
  
  validate_config(config_file)
}

