#!/usr/bin/env Rscript
# ============================================================================
# PACKAGE VERSION VALIDATION
# ============================================================================
# Purpose: Validate that required R packages are installed with correct versions
# 
# Usage:
#   source("scripts/utils/validate_package_versions.R")
#   validate_required_packages()
# ============================================================================

# ============================================================================
# REQUIRED PACKAGES WITH MINIMUM VERSIONS
# ============================================================================

REQUIRED_PACKAGES <- list(
  # Core tidyverse
  "tidyverse" = "2.0.0",
  "dplyr" = "1.1.0",
  "tidyr" = "1.3.0",
  "readr" = "2.1.0",
  "stringr" = "1.5.0",
  "ggplot2" = "3.4.0",
  "tibble" = "3.2.0",
  "scales" = "1.2.0",
  "purrr" = "1.0.0",
  
  # Visualization
  "patchwork" = "1.1.0",
  "ggrepel" = "0.9.0",
  "pheatmap" = "1.0.12",
  "viridis" = "0.6.0",
  "RColorBrewer" = "1.1.3",
  
  # Statistical
  "pROC" = "1.18.0",
  "e1071" = "1.7.13",
  "cluster" = "2.1.4",
  "factoextra" = "1.0.7",
  
  # Utilities
  "yaml" = "2.3.7",
  "base64enc" = "0.1.3",
  "jsonlite" = "1.8.7"
)

# ============================================================================
# VALIDATION FUNCTIONS
# ============================================================================

#' Compare version strings
#' 
#' @param installed_version Version string (e.g., "1.2.3")
#' @param required_version Minimum required version (e.g., "1.2.0")
#' @return TRUE if installed >= required, FALSE otherwise
compare_versions <- function(installed_version, required_version) {
  # Split version strings into numeric components
  installed_parts <- as.numeric(strsplit(installed_version, "\\.")[[1]])
  required_parts <- as.numeric(strsplit(required_version, "\\.")[[1]])
  
  # Pad to same length
  max_len <- max(length(installed_parts), length(required_parts))
  installed_parts <- c(installed_parts, rep(0, max_len - length(installed_parts)))
  required_parts <- c(required_parts, rep(0, max_len - length(required_parts)))
  
  # Compare component by component
  for (i in seq_along(installed_parts)) {
    if (installed_parts[i] > required_parts[i]) {
      return(TRUE)
    } else if (installed_parts[i] < required_parts[i]) {
      return(FALSE)
    }
  }
  
  # Versions are equal
  return(TRUE)
}

#' Get installed version of a package
#' 
#' @param pkg Package name
#' @return Version string or NULL if not installed
get_package_version <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    return(NULL)
  }
  
  tryCatch({
    # Try packageVersion first (most reliable)
    version <- as.character(packageVersion(pkg))
    return(version)
  }, error = function(e) {
    # Fallback: try installed.packages
    tryCatch({
      installed <- installed.packages()
      if (pkg %in% rownames(installed)) {
        return(installed[pkg, "Version"])
      }
    }, error = function(e2) {
      return(NULL)
    })
    return(NULL)
  })
}

#' Validate required packages
#' 
#' @param required_packages Named list of package names and minimum versions
#' @param verbose Print detailed information (default: TRUE)
#' @return TRUE if all packages are valid, stops execution otherwise
validate_required_packages <- function(required_packages = REQUIRED_PACKAGES, 
                                       verbose = TRUE) {
  
  if (verbose) {
    cat("\n")
    cat("═══════════════════════════════════════════════════════════\n")
    cat("  📦 VALIDATING R PACKAGE VERSIONS\n")
    cat("═══════════════════════════════════════════════════════════\n")
    cat("\n")
  }
  
  missing_packages <- character(0)
  outdated_packages <- character(0)
  valid_packages <- character(0)
  
  for (pkg_name in names(required_packages)) {
    required_version <- required_packages[[pkg_name]]
    installed_version <- get_package_version(pkg_name)
    
    if (is.null(installed_version)) {
      missing_packages <- c(missing_packages, 
                            paste0(pkg_name, " (required: >= ", required_version, ")"))
      if (verbose) {
        cat("❌", pkg_name, ": NOT INSTALLED (required: >=", required_version, ")\n", sep = "")
      }
    } else if (!compare_versions(installed_version, required_version)) {
      outdated_packages <- c(outdated_packages, 
                            paste0(pkg_name, " (installed: ", installed_version, 
                                   ", required: >=", required_version, ")"))
      if (verbose) {
        cat("⚠️ ", pkg_name, ": ", installed_version, " (required: >=", required_version, ")\n", sep = "")
      }
    } else {
      valid_packages <- c(valid_packages, pkg_name)
      if (verbose) {
        cat("✅", pkg_name, ": ", installed_version, " (required: >=", required_version, ")\n", sep = "")
      }
    }
  }
  
  if (verbose) {
    cat("\n")
    cat("═══════════════════════════════════════════════════════════\n")
    cat("  📊 VALIDATION SUMMARY\n")
    cat("═══════════════════════════════════════════════════════════\n")
    cat("\n")
    
    cat("✅ Valid packages:", length(valid_packages), "\n")
    
    if (length(outdated_packages) > 0) {
      cat("⚠️  Outdated packages:", length(outdated_packages), "\n")
      for (pkg in outdated_packages) {
        cat("   -", pkg, "\n")
      }
      cat("\n")
      cat("To update packages, run:\n")
      cat("  conda update -c conda-forge -c bioconda r-<package-name>\n")
      cat("  or\n")
      cat("  install.packages('<package-name>')\n")
      cat("\n")
    }
    
    if (length(missing_packages) > 0) {
      cat("❌ Missing packages:", length(missing_packages), "\n")
      for (pkg in missing_packages) {
        cat("   -", pkg, "\n")
      }
      cat("\n")
      cat("═══════════════════════════════════════════════════════════\n")
      cat("❌ PACKAGE VALIDATION FAILED\n")
      cat("═══════════════════════════════════════════════════════════\n")
      cat("\n")
      cat("Please install missing packages before running the pipeline.\n")
      cat("\n")
      cat("To install packages, run:\n")
      cat("  conda env create -f environment.yml\n")
      cat("  or\n")
      cat("  conda activate mirna_oxidation_pipeline\n")
      cat("  conda install -c conda-forge -c bioconda r-<package-name>\n")
      cat("\n")
      stop("Package validation failed")
    }
    
    if (length(outdated_packages) > 0) {
      cat("⚠️  Some packages are outdated but may still work.\n")
      cat("   Consider updating for best compatibility.\n")
      cat("\n")
    }
    
    cat("✅ All required packages are installed!\n")
    cat("\n")
    cat("═══════════════════════════════════════════════════════════\n")
    cat("✅ PACKAGE VALIDATION PASSED\n")
    cat("═══════════════════════════════════════════════════════════\n")
    cat("\n")
  }
  
  # Return TRUE only if no missing packages
  return(length(missing_packages) == 0)
}

# ============================================================================
# MAIN EXECUTION (if run as script)
# ============================================================================

if (!interactive()) {
  # Get custom package list from command line (optional)
  args <- commandArgs(trailingOnly = TRUE)
  
  if (length(args) > 0 && args[1] == "--quiet") {
    validate_required_packages(verbose = FALSE)
  } else {
    validate_required_packages(verbose = TRUE)
  }
}

