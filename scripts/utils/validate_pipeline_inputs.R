# ============================================================================
# Pipeline Input Validation
# ============================================================================
# Validates input files and output directories at the start of each pipeline script
# 
# Usage: 
#   source("scripts/utils/validate_pipeline_inputs.R")
#   validate_pipeline_inputs(snakemake, step_name = "Step 1", required_inputs = list(data = "csv"))
# ============================================================================

#' Validate pipeline inputs at script start
#' 
#' This function should be called at the beginning of each pipeline script
#' to validate all inputs before processing begins.
#' 
#' @param snakemake Snakemake object from script
#' @param step_name Name of the step (e.g., "Step 1", "Step 1.5")
#' @param required_inputs Named list of required inputs with their types
#' @return TRUE if all validations pass, stops execution otherwise
validate_pipeline_inputs <- function(snakemake, 
                                     step_name = "Pipeline step",
                                     required_inputs = NULL) {
  
  cat("\n")
  cat("Validating inputs for", step_name, "\n")
  cat("----------------------------------------\n")
  
  # Check if we have the standardized error handling function available
  use_standard <- exists("validate_file_exists")
  
  # Validate all input files
  if (length(snakemake@input) > 0) {
    cat("Checking input files...\n")
    
    for (input_name in names(snakemake@input)) {
      input_path <- snakemake@input[[input_name]]
      
      # Handle both single paths and lists of paths
      if (is.character(input_path) && length(input_path) == 1) {
        input_paths <- input_path
      } else if (is.list(input_path)) {
        input_paths <- unlist(input_path)
      } else {
        input_paths <- input_path
      }
      
      for (path in input_paths) {
        # Use standardized error handling if available
        if (use_standard) {
          validate_file_exists(path, context = paste(step_name, "- Input:", input_name))
          cat("  [OK] ", input_name, ": ", basename(path), "\n", sep = "")
        } else {
          # Basic file existence check
          if (!file.exists(path)) {
            stop(paste0(
              "\nERROR: Required input file not found\n",
              "  Step: ", step_name, "\n",
              "  Input: ", input_name, "\n",
              "  Path: ", path, "\n",
              "  Please verify the path in config/config.yaml or check previous step outputs\n"
            ))
          }
          cat("  [OK] ", input_name, ": ", basename(path), "\n", sep = "")
        }
      }
    }
    cat("\n")
  }
  
  # Check output directories exist or can be created
  if (length(snakemake@output) > 0) {
    cat("Checking output directories...\n")
    
    for (output_name in names(snakemake@output)) {
      output_path <- snakemake@output[[output_name]]
      
      # Handle both single paths and lists of paths
      if (is.character(output_path) && length(output_path) == 1) {
        output_paths <- output_path
      } else if (is.list(output_path)) {
        output_paths <- unlist(output_path)
      } else {
        output_paths <- output_path
      }
      
      for (path in output_paths) {
        output_dir <- dirname(path)
        
        # Create directory if it doesn't exist
        if (!dir.exists(output_dir)) {
          tryCatch({
            dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
            cat("  [OK] Created output directory: ", output_dir, "\n", sep = "")
          }, error = function(e) {
            stop(paste0(
              "\nERROR: Cannot create output directory\n",
              "  Step: ", step_name, "\n",
              "  Output: ", output_name, "\n",
              "  Directory: ", output_dir, "\n",
              "  Error: ", e$message, "\n",
              "  Please check permissions and disk space\n"
            ))
          })
        } else {
          cat("  [OK] Output directory exists: ", output_dir, "\n", sep = "")
        }
      }
    }
    cat("\n")
  }
  
  # Check required input types if specified
  if (!is.null(required_inputs)) {
    cat("Checking required input types...\n")
    
    for (input_name in names(required_inputs)) {
      expected_type <- required_inputs[[input_name]]
      
      if (!input_name %in% names(snakemake@input)) {
        stop(paste0(
          "\nERROR: Required input missing\n",
          "  Step: ", step_name, "\n",
          "  Required input: ", input_name, "\n",
          "  Expected type: ", expected_type, "\n"
        ))
      }
      
      input_path <- snakemake@input[[input_name]]
      
      # Warn if file extension doesn't match expected type
      if (expected_type == "csv") {
        if (!grepl("\\.csv$", input_path, ignore.case = TRUE)) {
          cat("  [WARN] ", input_name, " does not have .csv extension\n", sep = "")
        }
      } else if (expected_type == "tsv") {
        if (!grepl("\\.tsv$|\\.txt$", input_path, ignore.case = TRUE)) {
          cat("  [WARN] ", input_name, " does not have .tsv/.txt extension\n", sep = "")
        }
      }
      
      cat("  [OK] ", input_name, ": ", expected_type, "\n", sep = "")
    }
    cat("\n")
  }
  
  cat("All input validations passed.\n\n")
  return(TRUE)
}

# Export function
if (!exists("pipeline_input_validation_loaded")) {
  pipeline_input_validation_loaded <- TRUE
  assign("validate_pipeline_inputs", validate_pipeline_inputs, envir = .GlobalEnv)
}

