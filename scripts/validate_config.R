#!/usr/bin/env Rscript
# ============================================================================
# CONFIGURATION VALIDATION SCRIPT
# ============================================================================
# Purpose: Validate config.yaml before pipeline execution
# Usage: Rscript scripts/validate_config.R [config_file]
# ============================================================================

# Get config file path from command line or use default
args <- commandArgs(trailingOnly = TRUE)
config_file <- if (length(args) > 0) args[1] else "config/config.yaml"

# Check if yaml package is available
if (!requireNamespace("yaml", quietly = TRUE)) {
  cat("⚠️  Warning: 'yaml' package not installed. Using basic validation.\n")
  cat("   Install with: install.packages('yaml')\n")
  cat("   Continuing with basic file checks...\n\n")
  
  # Basic validation without yaml
  if (!file.exists(config_file)) {
    cat("❌ ERROR: Configuration file not found\n")
    cat("   Expected: ", config_file, "\n", sep = "")
    quit(status = 1)
  }
  
  # Check for placeholder paths (basic check)
  config_content <- readLines(config_file, n = 100, warn = FALSE)
  if (any(grepl("/path/to/", config_content, ignore.case = TRUE))) {
    cat("❌ ERROR: Configuration contains placeholder paths\n")
    quit(status = 1)
  }
  
  cat("✅ Basic validation passed (install 'yaml' for full validation)\n")
  quit(status = 0)
}

suppressPackageStartupMessages({
  library(yaml)
})

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  ⚙️  CONFIGURATION VALIDATION\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

# Check if config exists
if (!file.exists(config_file)) {
  cat("❌ ERROR: Configuration file not found\n")
  cat("   Expected: ", config_file, "\n", sep = "")
  cat("   Action: Copy config/config.yaml.example to config/config.yaml\n")
  cat("   Then edit config/config.yaml with your paths\n\n")
  quit(status = 1)
}

cat("✅ Config file exists: ", config_file, "\n", sep = "")

# Try to read and parse YAML
tryCatch({
  config <- read_yaml(config_file)
  cat("✅ Config file is valid YAML\n")
}, error = function(e) {
  cat("❌ ERROR: Cannot parse YAML file\n")
  cat("   Error: ", e$message, "\n", sep = "")
  cat("   Action: Verify YAML syntax\n\n")
  quit(status = 1)
})

# Validate structure
errors <- character(0)
warnings <- character(0)

# Check for required sections
required_sections <- list(
  "paths" = list("data", "outputs", "scripts"),
  "analysis" = NULL,
  "resources" = NULL
)

cat("\n📋 Validating structure...\n")

for (section in names(required_sections)) {
  if (!section %in% names(config)) {
    errors <- c(errors, paste("Missing required section:", section))
  } else {
    cat("   ✅ Section '", section, "' present\n", sep = "")
    
    # Check subsections if specified
    if (!is.null(required_sections[[section]])) {
      for (subsec in required_sections[[section]]) {
        if (!subsec %in% names(config[[section]])) {
          errors <- c(errors, paste("Missing subsection:", section, "->", subsec))
        }
      }
    }
  }
}

# Validate paths
if ("paths" %in% names(config)) {
  cat("\n📂 Validating paths...\n")
  
  # Check data paths
  if ("data" %in% names(config$paths)) {
    data_paths <- config$paths$data
    
    # Check for placeholder paths
    for (path_name in names(data_paths)) {
      path_value <- data_paths[[path_name]]
      
      if (grepl("/path/to/|/your/", path_value, ignore.case = TRUE)) {
        errors <- c(errors, paste("Placeholder path in data.", path_name, ":", path_value))
      } else {
        # Check if path exists
        if (path_name %in% c("raw", "processed_clean", "step1_original")) {
          if (!file.exists(path_value)) {
            errors <- c(errors, paste("Data file not found:", path_name, "=", path_value))
          } else {
            cat("   ✅ ", path_name, " exists\n", sep = "")
          }
        }
      }
    }
  }
  
  # Check output directories (will be created, but check parent exists)
  if ("outputs" %in% names(config$paths)) {
    output_paths <- config$paths$outputs
    snakemake_dir <- if ("snakemake_dir" %in% names(config$paths)) {
      config$paths$snakemake_dir
    } else {
      getwd()
    }
    
    for (output_name in names(output_paths)) {
      output_path <- file.path(snakemake_dir, output_paths[[output_name]])
      output_parent <- dirname(output_path)
      
      if (!dir.exists(output_parent)) {
        warnings <- c(warnings, paste("Output parent directory does not exist:", output_parent, 
                                     "(will be created)"))
      }
    }
  }
}

# Validate analysis parameters
if ("analysis" %in% names(config)) {
  cat("\n⚙️  Validating analysis parameters...\n")
  
  # VAF threshold
  if ("vaf_filter_threshold" %in% names(config$analysis)) {
    vaf_threshold <- config$analysis$vaf_filter_threshold
    if (!is.numeric(vaf_threshold) || vaf_threshold < 0 || vaf_threshold > 1) {
      errors <- c(errors, "vaf_filter_threshold must be between 0 and 1")
    } else {
      cat("   ✅ vaf_filter_threshold = ", vaf_threshold, "\n", sep = "")
    }
  }
  
  # Alpha (significance level)
  if ("alpha" %in% names(config$analysis)) {
    alpha <- config$analysis$alpha
    if (!is.numeric(alpha) || alpha < 0 || alpha > 1) {
      errors <- c(errors, "alpha must be between 0 and 1")
    } else {
      cat("   ✅ alpha = ", alpha, "\n", sep = "")
    }
  }
}

# Validate resources
if ("resources" %in% names(config)) {
  cat("\n💻 Validating resource settings...\n")
  
  if ("threads" %in% names(config$resources)) {
    threads <- config$resources$threads
    if (!is.numeric(threads) || threads < 1) {
      errors <- c(errors, "threads must be >= 1")
    } else {
      cat("   ✅ threads = ", threads, "\n", sep = "")
    }
  }
}

# Print results
cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")

if (length(errors) > 0) {
  cat("❌ VALIDATION FAILED\n")
  cat("═══════════════════════════════════════════════════════════════════\n\n")
  cat("Errors found:\n")
  for (i in seq_along(errors)) {
    cat("   ", i, ". ", errors[i], "\n", sep = "")
  }
  cat("\n")
  quit(status = 1)
}

if (length(warnings) > 0) {
  cat("⚠️  VALIDATION PASSED WITH WARNINGS\n")
  cat("═══════════════════════════════════════════════════════════════════\n\n")
  cat("Warnings:\n")
  for (i in seq_along(warnings)) {
    cat("   ", i, ". ", warnings[i], "\n", sep = "")
  }
  cat("\n")
  quit(status = 0)
}

cat("✅ VALIDATION PASSED\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")
quit(status = 0)


