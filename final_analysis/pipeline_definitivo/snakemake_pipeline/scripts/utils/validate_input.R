# ============================================================================
# INPUT VALIDATION FUNCTIONS
# ============================================================================
# Purpose: Validate input files before processing to fail fast with clear errors
# Usage: Call validate_input() at the start of each script
# ============================================================================

suppressPackageStartupMessages({
  library(readr)
  library(stringr)
})

# ============================================================================
# MAIN VALIDATION FUNCTION
# ============================================================================

#' Validate input file for pipeline processing
#' 
#' @param input_file Path to input file
#' @param expected_format "csv" or "tsv" or "auto" (detect from extension)
#' @param required_columns Character vector of required column names
#' @param validate_data_types Logical, whether to validate data types
#' @return TRUE if valid, stops execution with error message if invalid
#' @examples
#' validate_input("data.csv", expected_format = "csv", 
#'                required_columns = c("miRNA name", "pos:mut"))
validate_input <- function(input_file, 
                          expected_format = "auto",
                          required_columns = NULL,
                          validate_data_types = FALSE) {
  
  cat("\n")
  cat("═══════════════════════════════════════════════════════════════════\n")
  cat("  📋 VALIDATING INPUT FILE\n")
  cat("═══════════════════════════════════════════════════════════════════\n\n")
  
  # 1. Check if file exists
  if (!file.exists(input_file)) {
    stop(paste0(
      "\n❌ ERROR: Input file not found\n",
      "   Path: ", input_file, "\n",
      "   Action: Verify the path in config/config.yaml\n"
    ))
  }
  
  cat("✅ File exists:", input_file, "\n")
  
  # 2. Check if file is readable
  if (file.access(input_file, 4) != 0) {
    stop(paste0(
      "\n❌ ERROR: Cannot read input file (permission denied)\n",
      "   Path: ", input_file, "\n",
      "   Action: Check file permissions\n"
    ))
  }
  
  cat("✅ File is readable\n")
  
  # 3. Check if file is not empty
  file_size <- file.info(input_file)$size
  if (file_size == 0) {
    stop(paste0(
      "\n❌ ERROR: Input file is empty\n",
      "   Path: ", input_file, "\n",
      "   Action: Check that the file contains data\n"
    ))
  }
  
  cat("✅ File is not empty (", format(file_size, big.mark = ","), " bytes)\n", sep = "")
  
  # 4. Detect or validate format
  file_ext <- tolower(tools::file_ext(input_file))
  
  if (expected_format == "auto") {
    expected_format <- file_ext
  }
  
  if (!file_ext %in% c("csv", "tsv", "txt")) {
    cat("⚠️  Warning: Unusual file extension (.", file_ext, ")\n", sep = "")
    cat("   Expected: .csv, .tsv, or .txt\n")
  }
  
  # 5. Try to read file (first few rows to validate structure)
  cat("\n📊 Reading file structure...\n")
  
  tryCatch({
    if (expected_format == "csv" || file_ext == "csv") {
      # Try reading as CSV
      data_preview <- read_csv(input_file, 
                               n_max = 5,
                               show_col_types = FALSE,
                               progress = FALSE)
    } else {
      # Try reading as TSV
      data_preview <- read_tsv(input_file,
                               n_max = 5,
                               show_col_types = FALSE,
                               progress = FALSE)
    }
  }, error = function(e) {
    stop(paste0(
      "\n❌ ERROR: Cannot parse input file\n",
      "   Path: ", input_file, "\n",
      "   Error: ", e$message, "\n",
      "   Action: Verify file format (CSV/TSV) and encoding (UTF-8)\n"
    ))
  })
  
  cat("✅ File format is valid (", ncol(data_preview), " columns detected)\n", sep = "")
  cat("✅ Preview rows:", nrow(data_preview), "\n")
  
  # 6. Validate required columns (flexible matching for common variations)
  if (!is.null(required_columns) && length(required_columns) > 0) {
    cat("\n📋 Validating required columns...\n")
    
    # Handle common column name variations
    # "miRNA name" can be "miRNA_name" or "miRNA.name"
    # "pos:mut" can be "pos.mut" or "pos_mut"
    column_mappings <- list(
      "miRNA name" = c("miRNA name", "miRNA_name", "miRNA.name"),
      "pos:mut" = c("pos:mut", "pos.mut", "pos_mut")
    )
    
    missing_cols <- c()
    for (req_col in required_columns) {
      # Check if exact match exists
      if (req_col %in% names(data_preview)) {
        next  # Found exact match
      }
      
      # Check for variations
      if (req_col %in% names(column_mappings)) {
        variations <- column_mappings[[req_col]]
        found <- any(variations %in% names(data_preview))
        if (!found) {
          missing_cols <- c(missing_cols, req_col)
        }
      } else {
        # No known variations, check exact match only
        if (!req_col %in% names(data_preview)) {
          missing_cols <- c(missing_cols, req_col)
        }
      }
    }
    
    if (length(missing_cols) > 0) {
      # Find actual column names that might be variations
      actual_cols <- names(data_preview)
      suggested <- character(0)
      
      for (miss_col in missing_cols) {
        if (miss_col == "miRNA name") {
          # Look for miRNA-related columns
          mirna_cols <- grep("miRNA|mirna|miR", actual_cols, ignore.case = TRUE, value = TRUE)
          if (length(mirna_cols) > 0) {
            suggested <- c(suggested, paste0("   Maybe you meant: ", paste(mirna_cols, collapse = ", ")))
          }
        }
        if (miss_col == "pos:mut") {
          # Look for position/mutation related columns
          pos_cols <- grep("pos|mut|mutation", actual_cols, ignore.case = TRUE, value = TRUE)
          if (length(pos_cols) > 0) {
            suggested <- c(suggested, paste0("   Maybe you meant: ", paste(pos_cols, collapse = ", ")))
          }
        }
      }
      
      error_msg <- paste0(
        "\n❌ ERROR: Required columns missing\n",
        "   Missing: ", paste(missing_cols, collapse = ", "), "\n",
        "   Found columns: ", paste(head(names(data_preview), 10), collapse = ", "),
        ifelse(length(names(data_preview)) > 10, "...", ""), "\n"
      )
      
      if (length(suggested) > 0) {
        error_msg <- paste0(error_msg, paste(suggested, collapse = "\n"), "\n")
      }
      
      error_msg <- paste0(
        error_msg,
        "   Action: Verify column names match expected format\n",
        "   Expected: ", paste(required_columns, collapse = ", "), "\n",
        "   Note: Column names can use spaces, dots, or underscores\n"
      )
      
      stop(error_msg)
    }
    
    cat("✅ All required columns present:\n")
    for (col in required_columns) {
      # Find the actual column name (might be a variation)
      actual_name <- col
      if (col %in% names(column_mappings)) {
        variations <- column_mappings[[col]]
        found_var <- variations[variations %in% names(data_preview)]
        if (length(found_var) > 0) {
          actual_name <- found_var[1]
        }
      }
      cat("      - ", actual_name, "\n", sep = "")
    }
  }
  
  # 7. Validate data types (if requested)
  if (validate_data_types && !is.null(required_columns)) {
    cat("\n📊 Validating data types...\n")
    
    # Read full file for type validation (only if file is small)
    file_size_mb <- file_size / (1024^2)
    if (file_size_mb < 50) {  # Only validate types if file < 50 MB
      full_data <- read_csv(input_file, show_col_types = FALSE, progress = FALSE)
      
      # Check for common issues
      if ("pos:mut" %in% names(full_data)) {
        # Validate pos:mut format
        invalid_format <- !grepl("^\\d+:[A-Z]>[A-Z]$", full_data$`pos:mut`, perl = TRUE)
        invalid_format <- invalid_format & !is.na(full_data$`pos:mut`)
        invalid_format <- invalid_format & full_data$`pos:mut` != "PM"
        
        if (sum(invalid_format, na.rm = TRUE) > 0) {
          n_invalid <- sum(invalid_format, na.rm = TRUE)
          cat("⚠️  Warning: ", n_invalid, " rows with invalid 'pos:mut' format\n", sep = "")
          cat("      Expected format: 'position:mutation' (e.g., '1:G>T')\n")
          cat("      First invalid examples:\n")
          invalid_examples <- head(unique(full_data$`pos:mut`[invalid_format]), 3)
          for (ex in invalid_examples) {
            cat("         - ", ex, "\n", sep = "")
          }
        } else {
          cat("✅ 'pos:mut' format is valid\n")
        }
      }
    } else {
      cat("⚠️  Skipping data type validation (file too large: ", 
          round(file_size_mb, 1), " MB)\n", sep = "")
    }
  }
  
  cat("\n✅ Input validation PASSED\n")
  cat("═══════════════════════════════════════════════════════════════════\n\n")
  
  return(TRUE)
}

# ============================================================================
# SPECIFIC VALIDATION FUNCTIONS FOR PIPELINE STEPS
# ============================================================================

#' Validate processed clean data (for Step 1)
validate_processed_clean <- function(input_file) {
  validate_input(
    input_file = input_file,
    expected_format = "csv",
    required_columns = c("miRNA name", "pos:mut"),
    validate_data_types = TRUE
  )
}

#' Validate raw data (for Step 1 panels C and D)
validate_raw_data <- function(input_file) {
  validate_input(
    input_file = input_file,
    expected_format = "tsv",
    required_columns = c("pos:mut"),
    validate_data_types = FALSE  # Raw data format may vary
  )
}

#' Validate original data for Step 1.5 (needs SNV + total columns)
validate_step1_5_input <- function(input_file) {
  # First, basic validation
  result <- validate_input(
    input_file = input_file,
    expected_format = "csv",
    required_columns = c("miRNA name", "pos:mut"),
    validate_data_types = FALSE
  )
  
  if (!result) return(FALSE)
  
  # Additional validation: Check for SNV and Total columns
  cat("\n📋 Validating Step 1.5 specific requirements...\n")
  
  data_preview <- read_csv(input_file, n_max = 5, show_col_types = FALSE)
  
  snv_cols <- grep("^Magen.*_SNV$|^Magen.*SNV$", names(data_preview), value = TRUE)
  total_cols <- grep("\\(PM\\+1MM\\+2MM\\)$", names(data_preview), value = TRUE)
  
  if (length(snv_cols) == 0 && length(total_cols) == 0) {
    cat("⚠️  Warning: No SNV or Total columns detected with expected naming pattern\n")
    cat("      Expected SNV pattern: 'Magen_XXX_SNV' or 'Magen_XXXSNV'\n")
    cat("      Expected Total pattern: 'Magen_XXX (PM+1MM+2MM)'\n")
    cat("      Found columns: ", paste(head(names(data_preview), 10), collapse = ", "), "\n", sep = "")
    cat("      This may cause issues in VAF calculation\n")
  } else {
    cat("✅ SNV columns found:", length(snv_cols), "\n")
    cat("✅ Total columns found:", length(total_cols), "\n")
    
    # Check if counts match
    if (length(snv_cols) > 0 && length(total_cols) > 0) {
      if (length(snv_cols) != length(total_cols)) {
        cat("⚠️  Warning: Number of SNV columns (", length(snv_cols), 
            ") != Total columns (", length(total_cols), ")\n", sep = "")
        cat("      VAF calculation may be incomplete\n")
      } else {
        cat("✅ SNV and Total column counts match\n")
      }
    }
  }
  
  return(TRUE)
}

# ============================================================================
# VALIDATE CONFIGURATION FILE
# ============================================================================

#' Validate configuration file
#' 
#' @param config_file Path to config.yaml
#' @return TRUE if valid, stops with error if invalid
validate_config <- function(config_file = "config/config.yaml") {
  
  cat("\n")
  cat("═══════════════════════════════════════════════════════════════════\n")
  cat("  ⚙️  VALIDATING CONFIGURATION\n")
  cat("═══════════════════════════════════════════════════════════════════\n\n")
  
  # Check if config exists
  if (!file.exists(config_file)) {
    stop(paste0(
      "\n❌ ERROR: Configuration file not found\n",
      "   Expected: ", config_file, "\n",
      "   Action: Copy config/config.yaml.example to config/config.yaml\n",
      "   Then edit config/config.yaml with your paths\n"
    ))
  }
  
  cat("✅ Config file exists:", config_file, "\n")
  
  # Try to read config (basic YAML validation)
  # Note: In R, we can't easily parse YAML without yaml package
  # This is a basic check - full validation would need yaml package or Python script
  
  config_content <- readLines(config_file, n = 50, warn = FALSE)
  
  # Check for common issues
  if (any(grepl("^paths:", config_content))) {
    cat("✅ Config structure appears valid\n")
  } else {
    cat("⚠️  Warning: Config structure may be invalid\n")
    cat("      Expected 'paths:' section\n")
  }
  
  # Check for placeholder paths
  placeholder_paths <- grepl("/path/to/", config_content, ignore.case = TRUE)
  if (any(placeholder_paths)) {
    stop(paste0(
      "\n❌ ERROR: Configuration contains placeholder paths\n",
      "   Found '/path/to/' in config file\n",
      "   Action: Update all paths in config/config.yaml with your actual data paths\n",
      "   See config/config.yaml.example for guidance\n"
    ))
  }
  
  cat("✅ No placeholder paths found\n")
  
  cat("\n✅ Configuration validation PASSED\n")
  cat("═══════════════════════════════════════════════════════════════════\n\n")
  
  return(TRUE)
}


# ============================================================================
# Purpose: Validate input files before processing to fail fast with clear errors
# Usage: Call validate_input() at the start of each script
# ============================================================================

suppressPackageStartupMessages({
  library(readr)
  library(stringr)
})

# ============================================================================
# MAIN VALIDATION FUNCTION
# ============================================================================

#' Validate input file for pipeline processing
#' 
#' @param input_file Path to input file
#' @param expected_format "csv" or "tsv" or "auto" (detect from extension)
#' @param required_columns Character vector of required column names
#' @param validate_data_types Logical, whether to validate data types
#' @return TRUE if valid, stops execution with error message if invalid
#' @examples
#' validate_input("data.csv", expected_format = "csv", 
#'                required_columns = c("miRNA name", "pos:mut"))
validate_input <- function(input_file, 
                          expected_format = "auto",
                          required_columns = NULL,
                          validate_data_types = FALSE) {
  
  cat("\n")
  cat("═══════════════════════════════════════════════════════════════════\n")
  cat("  📋 VALIDATING INPUT FILE\n")
  cat("═══════════════════════════════════════════════════════════════════\n\n")
  
  # 1. Check if file exists
  if (!file.exists(input_file)) {
    stop(paste0(
      "\n❌ ERROR: Input file not found\n",
      "   Path: ", input_file, "\n",
      "   Action: Verify the path in config/config.yaml\n"
    ))
  }
  
  cat("✅ File exists:", input_file, "\n")
  
  # 2. Check if file is readable
  if (file.access(input_file, 4) != 0) {
    stop(paste0(
      "\n❌ ERROR: Cannot read input file (permission denied)\n",
      "   Path: ", input_file, "\n",
      "   Action: Check file permissions\n"
    ))
  }
  
  cat("✅ File is readable\n")
  
  # 3. Check if file is not empty
  file_size <- file.info(input_file)$size
  if (file_size == 0) {
    stop(paste0(
      "\n❌ ERROR: Input file is empty\n",
      "   Path: ", input_file, "\n",
      "   Action: Check that the file contains data\n"
    ))
  }
  
  cat("✅ File is not empty (", format(file_size, big.mark = ","), " bytes)\n", sep = "")
  
  # 4. Detect or validate format
  file_ext <- tolower(tools::file_ext(input_file))
  
  if (expected_format == "auto") {
    expected_format <- file_ext
  }
  
  if (!file_ext %in% c("csv", "tsv", "txt")) {
    cat("⚠️  Warning: Unusual file extension (.", file_ext, ")\n", sep = "")
    cat("   Expected: .csv, .tsv, or .txt\n")
  }
  
  # 5. Try to read file (first few rows to validate structure)
  cat("\n📊 Reading file structure...\n")
  
  tryCatch({
    if (expected_format == "csv" || file_ext == "csv") {
      # Try reading as CSV
      data_preview <- read_csv(input_file, 
                               n_max = 5,
                               show_col_types = FALSE,
                               progress = FALSE)
    } else {
      # Try reading as TSV
      data_preview <- read_tsv(input_file,
                               n_max = 5,
                               show_col_types = FALSE,
                               progress = FALSE)
    }
  }, error = function(e) {
    stop(paste0(
      "\n❌ ERROR: Cannot parse input file\n",
      "   Path: ", input_file, "\n",
      "   Error: ", e$message, "\n",
      "   Action: Verify file format (CSV/TSV) and encoding (UTF-8)\n"
    ))
  })
  
  cat("✅ File format is valid (", ncol(data_preview), " columns detected)\n", sep = "")
  cat("✅ Preview rows:", nrow(data_preview), "\n")
  
  # 6. Validate required columns (flexible matching for common variations)
  if (!is.null(required_columns) && length(required_columns) > 0) {
    cat("\n📋 Validating required columns...\n")
    
    # Handle common column name variations
    # "miRNA name" can be "miRNA_name" or "miRNA.name"
    # "pos:mut" can be "pos.mut" or "pos_mut"
    column_mappings <- list(
      "miRNA name" = c("miRNA name", "miRNA_name", "miRNA.name"),
      "pos:mut" = c("pos:mut", "pos.mut", "pos_mut")
    )
    
    missing_cols <- c()
    for (req_col in required_columns) {
      # Check if exact match exists
      if (req_col %in% names(data_preview)) {
        next  # Found exact match
      }
      
      # Check for variations
      if (req_col %in% names(column_mappings)) {
        variations <- column_mappings[[req_col]]
        found <- any(variations %in% names(data_preview))
        if (!found) {
          missing_cols <- c(missing_cols, req_col)
        }
      } else {
        # No known variations, check exact match only
        if (!req_col %in% names(data_preview)) {
          missing_cols <- c(missing_cols, req_col)
        }
      }
    }
    
    if (length(missing_cols) > 0) {
      # Find actual column names that might be variations
      actual_cols <- names(data_preview)
      suggested <- character(0)
      
      for (miss_col in missing_cols) {
        if (miss_col == "miRNA name") {
          # Look for miRNA-related columns
          mirna_cols <- grep("miRNA|mirna|miR", actual_cols, ignore.case = TRUE, value = TRUE)
          if (length(mirna_cols) > 0) {
            suggested <- c(suggested, paste0("   Maybe you meant: ", paste(mirna_cols, collapse = ", ")))
          }
        }
        if (miss_col == "pos:mut") {
          # Look for position/mutation related columns
          pos_cols <- grep("pos|mut|mutation", actual_cols, ignore.case = TRUE, value = TRUE)
          if (length(pos_cols) > 0) {
            suggested <- c(suggested, paste0("   Maybe you meant: ", paste(pos_cols, collapse = ", ")))
          }
        }
      }
      
      error_msg <- paste0(
        "\n❌ ERROR: Required columns missing\n",
        "   Missing: ", paste(missing_cols, collapse = ", "), "\n",
        "   Found columns: ", paste(head(names(data_preview), 10), collapse = ", "),
        ifelse(length(names(data_preview)) > 10, "...", ""), "\n"
      )
      
      if (length(suggested) > 0) {
        error_msg <- paste0(error_msg, paste(suggested, collapse = "\n"), "\n")
      }
      
      error_msg <- paste0(
        error_msg,
        "   Action: Verify column names match expected format\n",
        "   Expected: ", paste(required_columns, collapse = ", "), "\n",
        "   Note: Column names can use spaces, dots, or underscores\n"
      )
      
      stop(error_msg)
    }
    
    cat("✅ All required columns present:\n")
    for (col in required_columns) {
      # Find the actual column name (might be a variation)
      actual_name <- col
      if (col %in% names(column_mappings)) {
        variations <- column_mappings[[col]]
        found_var <- variations[variations %in% names(data_preview)]
        if (length(found_var) > 0) {
          actual_name <- found_var[1]
        }
      }
      cat("      - ", actual_name, "\n", sep = "")
    }
  }
  
  # 7. Validate data types (if requested)
  if (validate_data_types && !is.null(required_columns)) {
    cat("\n📊 Validating data types...\n")
    
    # Read full file for type validation (only if file is small)
    file_size_mb <- file_size / (1024^2)
    if (file_size_mb < 50) {  # Only validate types if file < 50 MB
      full_data <- read_csv(input_file, show_col_types = FALSE, progress = FALSE)
      
      # Check for common issues
      if ("pos:mut" %in% names(full_data)) {
        # Validate pos:mut format
        invalid_format <- !grepl("^\\d+:[A-Z]>[A-Z]$", full_data$`pos:mut`, perl = TRUE)
        invalid_format <- invalid_format & !is.na(full_data$`pos:mut`)
        invalid_format <- invalid_format & full_data$`pos:mut` != "PM"
        
        if (sum(invalid_format, na.rm = TRUE) > 0) {
          n_invalid <- sum(invalid_format, na.rm = TRUE)
          cat("⚠️  Warning: ", n_invalid, " rows with invalid 'pos:mut' format\n", sep = "")
          cat("      Expected format: 'position:mutation' (e.g., '1:G>T')\n")
          cat("      First invalid examples:\n")
          invalid_examples <- head(unique(full_data$`pos:mut`[invalid_format]), 3)
          for (ex in invalid_examples) {
            cat("         - ", ex, "\n", sep = "")
          }
        } else {
          cat("✅ 'pos:mut' format is valid\n")
        }
      }
    } else {
      cat("⚠️  Skipping data type validation (file too large: ", 
          round(file_size_mb, 1), " MB)\n", sep = "")
    }
  }
  
  cat("\n✅ Input validation PASSED\n")
  cat("═══════════════════════════════════════════════════════════════════\n\n")
  
  return(TRUE)
}

# ============================================================================
# SPECIFIC VALIDATION FUNCTIONS FOR PIPELINE STEPS
# ============================================================================

#' Validate processed clean data (for Step 1)
validate_processed_clean <- function(input_file) {
  validate_input(
    input_file = input_file,
    expected_format = "csv",
    required_columns = c("miRNA name", "pos:mut"),
    validate_data_types = TRUE
  )
}

#' Validate raw data (for Step 1 panels C and D)
validate_raw_data <- function(input_file) {
  validate_input(
    input_file = input_file,
    expected_format = "tsv",
    required_columns = c("pos:mut"),
    validate_data_types = FALSE  # Raw data format may vary
  )
}

#' Validate original data for Step 1.5 (needs SNV + total columns)
validate_step1_5_input <- function(input_file) {
  # First, basic validation
  result <- validate_input(
    input_file = input_file,
    expected_format = "csv",
    required_columns = c("miRNA name", "pos:mut"),
    validate_data_types = FALSE
  )
  
  if (!result) return(FALSE)
  
  # Additional validation: Check for SNV and Total columns
  cat("\n📋 Validating Step 1.5 specific requirements...\n")
  
  data_preview <- read_csv(input_file, n_max = 5, show_col_types = FALSE)
  
  snv_cols <- grep("^Magen.*_SNV$|^Magen.*SNV$", names(data_preview), value = TRUE)
  total_cols <- grep("\\(PM\\+1MM\\+2MM\\)$", names(data_preview), value = TRUE)
  
  if (length(snv_cols) == 0 && length(total_cols) == 0) {
    cat("⚠️  Warning: No SNV or Total columns detected with expected naming pattern\n")
    cat("      Expected SNV pattern: 'Magen_XXX_SNV' or 'Magen_XXXSNV'\n")
    cat("      Expected Total pattern: 'Magen_XXX (PM+1MM+2MM)'\n")
    cat("      Found columns: ", paste(head(names(data_preview), 10), collapse = ", "), "\n", sep = "")
    cat("      This may cause issues in VAF calculation\n")
  } else {
    cat("✅ SNV columns found:", length(snv_cols), "\n")
    cat("✅ Total columns found:", length(total_cols), "\n")
    
    # Check if counts match
    if (length(snv_cols) > 0 && length(total_cols) > 0) {
      if (length(snv_cols) != length(total_cols)) {
        cat("⚠️  Warning: Number of SNV columns (", length(snv_cols), 
            ") != Total columns (", length(total_cols), ")\n", sep = "")
        cat("      VAF calculation may be incomplete\n")
      } else {
        cat("✅ SNV and Total column counts match\n")
      }
    }
  }
  
  return(TRUE)
}

# ============================================================================
# VALIDATE CONFIGURATION FILE
# ============================================================================

#' Validate configuration file
#' 
#' @param config_file Path to config.yaml
#' @return TRUE if valid, stops with error if invalid
validate_config <- function(config_file = "config/config.yaml") {
  
  cat("\n")
  cat("═══════════════════════════════════════════════════════════════════\n")
  cat("  ⚙️  VALIDATING CONFIGURATION\n")
  cat("═══════════════════════════════════════════════════════════════════\n\n")
  
  # Check if config exists
  if (!file.exists(config_file)) {
    stop(paste0(
      "\n❌ ERROR: Configuration file not found\n",
      "   Expected: ", config_file, "\n",
      "   Action: Copy config/config.yaml.example to config/config.yaml\n",
      "   Then edit config/config.yaml with your paths\n"
    ))
  }
  
  cat("✅ Config file exists:", config_file, "\n")
  
  # Try to read config (basic YAML validation)
  # Note: In R, we can't easily parse YAML without yaml package
  # This is a basic check - full validation would need yaml package or Python script
  
  config_content <- readLines(config_file, n = 50, warn = FALSE)
  
  # Check for common issues
  if (any(grepl("^paths:", config_content))) {
    cat("✅ Config structure appears valid\n")
  } else {
    cat("⚠️  Warning: Config structure may be invalid\n")
    cat("      Expected 'paths:' section\n")
  }
  
  # Check for placeholder paths
  placeholder_paths <- grepl("/path/to/", config_content, ignore.case = TRUE)
  if (any(placeholder_paths)) {
    stop(paste0(
      "\n❌ ERROR: Configuration contains placeholder paths\n",
      "   Found '/path/to/' in config file\n",
      "   Action: Update all paths in config/config.yaml with your actual data paths\n",
      "   See config/config.yaml.example for guidance\n"
    ))
  }
  
  cat("✅ No placeholder paths found\n")
  
  cat("\n✅ Configuration validation PASSED\n")
  cat("═══════════════════════════════════════════════════════════════════\n\n")
  
  return(TRUE)
}


# ============================================================================
# Purpose: Validate input files before processing to fail fast with clear errors
# Usage: Call validate_input() at the start of each script
# ============================================================================

suppressPackageStartupMessages({
  library(readr)
  library(stringr)
})

# ============================================================================
# MAIN VALIDATION FUNCTION
# ============================================================================

#' Validate input file for pipeline processing
#' 
#' @param input_file Path to input file
#' @param expected_format "csv" or "tsv" or "auto" (detect from extension)
#' @param required_columns Character vector of required column names
#' @param validate_data_types Logical, whether to validate data types
#' @return TRUE if valid, stops execution with error message if invalid
#' @examples
#' validate_input("data.csv", expected_format = "csv", 
#'                required_columns = c("miRNA name", "pos:mut"))
validate_input <- function(input_file, 
                          expected_format = "auto",
                          required_columns = NULL,
                          validate_data_types = FALSE) {
  
  cat("\n")
  cat("═══════════════════════════════════════════════════════════════════\n")
  cat("  📋 VALIDATING INPUT FILE\n")
  cat("═══════════════════════════════════════════════════════════════════\n\n")
  
  # 1. Check if file exists
  if (!file.exists(input_file)) {
    stop(paste0(
      "\n❌ ERROR: Input file not found\n",
      "   Path: ", input_file, "\n",
      "   Action: Verify the path in config/config.yaml\n"
    ))
  }
  
  cat("✅ File exists:", input_file, "\n")
  
  # 2. Check if file is readable
  if (file.access(input_file, 4) != 0) {
    stop(paste0(
      "\n❌ ERROR: Cannot read input file (permission denied)\n",
      "   Path: ", input_file, "\n",
      "   Action: Check file permissions\n"
    ))
  }
  
  cat("✅ File is readable\n")
  
  # 3. Check if file is not empty
  file_size <- file.info(input_file)$size
  if (file_size == 0) {
    stop(paste0(
      "\n❌ ERROR: Input file is empty\n",
      "   Path: ", input_file, "\n",
      "   Action: Check that the file contains data\n"
    ))
  }
  
  cat("✅ File is not empty (", format(file_size, big.mark = ","), " bytes)\n", sep = "")
  
  # 4. Detect or validate format
  file_ext <- tolower(tools::file_ext(input_file))
  
  if (expected_format == "auto") {
    expected_format <- file_ext
  }
  
  if (!file_ext %in% c("csv", "tsv", "txt")) {
    cat("⚠️  Warning: Unusual file extension (.", file_ext, ")\n", sep = "")
    cat("   Expected: .csv, .tsv, or .txt\n")
  }
  
  # 5. Try to read file (first few rows to validate structure)
  cat("\n📊 Reading file structure...\n")
  
  tryCatch({
    if (expected_format == "csv" || file_ext == "csv") {
      # Try reading as CSV
      data_preview <- read_csv(input_file, 
                               n_max = 5,
                               show_col_types = FALSE,
                               progress = FALSE)
    } else {
      # Try reading as TSV
      data_preview <- read_tsv(input_file,
                               n_max = 5,
                               show_col_types = FALSE,
                               progress = FALSE)
    }
  }, error = function(e) {
    stop(paste0(
      "\n❌ ERROR: Cannot parse input file\n",
      "   Path: ", input_file, "\n",
      "   Error: ", e$message, "\n",
      "   Action: Verify file format (CSV/TSV) and encoding (UTF-8)\n"
    ))
  })
  
  cat("✅ File format is valid (", ncol(data_preview), " columns detected)\n", sep = "")
  cat("✅ Preview rows:", nrow(data_preview), "\n")
  
  # 6. Validate required columns (flexible matching for common variations)
  if (!is.null(required_columns) && length(required_columns) > 0) {
    cat("\n📋 Validating required columns...\n")
    
    # Handle common column name variations
    # "miRNA name" can be "miRNA_name" or "miRNA.name"
    # "pos:mut" can be "pos.mut" or "pos_mut"
    column_mappings <- list(
      "miRNA name" = c("miRNA name", "miRNA_name", "miRNA.name"),
      "pos:mut" = c("pos:mut", "pos.mut", "pos_mut")
    )
    
    missing_cols <- c()
    for (req_col in required_columns) {
      # Check if exact match exists
      if (req_col %in% names(data_preview)) {
        next  # Found exact match
      }
      
      # Check for variations
      if (req_col %in% names(column_mappings)) {
        variations <- column_mappings[[req_col]]
        found <- any(variations %in% names(data_preview))
        if (!found) {
          missing_cols <- c(missing_cols, req_col)
        }
      } else {
        # No known variations, check exact match only
        if (!req_col %in% names(data_preview)) {
          missing_cols <- c(missing_cols, req_col)
        }
      }
    }
    
    if (length(missing_cols) > 0) {
      # Find actual column names that might be variations
      actual_cols <- names(data_preview)
      suggested <- character(0)
      
      for (miss_col in missing_cols) {
        if (miss_col == "miRNA name") {
          # Look for miRNA-related columns
          mirna_cols <- grep("miRNA|mirna|miR", actual_cols, ignore.case = TRUE, value = TRUE)
          if (length(mirna_cols) > 0) {
            suggested <- c(suggested, paste0("   Maybe you meant: ", paste(mirna_cols, collapse = ", ")))
          }
        }
        if (miss_col == "pos:mut") {
          # Look for position/mutation related columns
          pos_cols <- grep("pos|mut|mutation", actual_cols, ignore.case = TRUE, value = TRUE)
          if (length(pos_cols) > 0) {
            suggested <- c(suggested, paste0("   Maybe you meant: ", paste(pos_cols, collapse = ", ")))
          }
        }
      }
      
      error_msg <- paste0(
        "\n❌ ERROR: Required columns missing\n",
        "   Missing: ", paste(missing_cols, collapse = ", "), "\n",
        "   Found columns: ", paste(head(names(data_preview), 10), collapse = ", "),
        ifelse(length(names(data_preview)) > 10, "...", ""), "\n"
      )
      
      if (length(suggested) > 0) {
        error_msg <- paste0(error_msg, paste(suggested, collapse = "\n"), "\n")
      }
      
      error_msg <- paste0(
        error_msg,
        "   Action: Verify column names match expected format\n",
        "   Expected: ", paste(required_columns, collapse = ", "), "\n",
        "   Note: Column names can use spaces, dots, or underscores\n"
      )
      
      stop(error_msg)
    }
    
    cat("✅ All required columns present:\n")
    for (col in required_columns) {
      # Find the actual column name (might be a variation)
      actual_name <- col
      if (col %in% names(column_mappings)) {
        variations <- column_mappings[[col]]
        found_var <- variations[variations %in% names(data_preview)]
        if (length(found_var) > 0) {
          actual_name <- found_var[1]
        }
      }
      cat("      - ", actual_name, "\n", sep = "")
    }
  }
  
  # 7. Validate data types (if requested)
  if (validate_data_types && !is.null(required_columns)) {
    cat("\n📊 Validating data types...\n")
    
    # Read full file for type validation (only if file is small)
    file_size_mb <- file_size / (1024^2)
    if (file_size_mb < 50) {  # Only validate types if file < 50 MB
      full_data <- read_csv(input_file, show_col_types = FALSE, progress = FALSE)
      
      # Check for common issues
      if ("pos:mut" %in% names(full_data)) {
        # Validate pos:mut format
        invalid_format <- !grepl("^\\d+:[A-Z]>[A-Z]$", full_data$`pos:mut`, perl = TRUE)
        invalid_format <- invalid_format & !is.na(full_data$`pos:mut`)
        invalid_format <- invalid_format & full_data$`pos:mut` != "PM"
        
        if (sum(invalid_format, na.rm = TRUE) > 0) {
          n_invalid <- sum(invalid_format, na.rm = TRUE)
          cat("⚠️  Warning: ", n_invalid, " rows with invalid 'pos:mut' format\n", sep = "")
          cat("      Expected format: 'position:mutation' (e.g., '1:G>T')\n")
          cat("      First invalid examples:\n")
          invalid_examples <- head(unique(full_data$`pos:mut`[invalid_format]), 3)
          for (ex in invalid_examples) {
            cat("         - ", ex, "\n", sep = "")
          }
        } else {
          cat("✅ 'pos:mut' format is valid\n")
        }
      }
    } else {
      cat("⚠️  Skipping data type validation (file too large: ", 
          round(file_size_mb, 1), " MB)\n", sep = "")
    }
  }
  
  cat("\n✅ Input validation PASSED\n")
  cat("═══════════════════════════════════════════════════════════════════\n\n")
  
  return(TRUE)
}

# ============================================================================
# SPECIFIC VALIDATION FUNCTIONS FOR PIPELINE STEPS
# ============================================================================

#' Validate processed clean data (for Step 1)
validate_processed_clean <- function(input_file) {
  validate_input(
    input_file = input_file,
    expected_format = "csv",
    required_columns = c("miRNA name", "pos:mut"),
    validate_data_types = TRUE
  )
}

#' Validate raw data (for Step 1 panels C and D)
validate_raw_data <- function(input_file) {
  validate_input(
    input_file = input_file,
    expected_format = "tsv",
    required_columns = c("pos:mut"),
    validate_data_types = FALSE  # Raw data format may vary
  )
}

#' Validate original data for Step 1.5 (needs SNV + total columns)
validate_step1_5_input <- function(input_file) {
  # First, basic validation
  result <- validate_input(
    input_file = input_file,
    expected_format = "csv",
    required_columns = c("miRNA name", "pos:mut"),
    validate_data_types = FALSE
  )
  
  if (!result) return(FALSE)
  
  # Additional validation: Check for SNV and Total columns
  cat("\n📋 Validating Step 1.5 specific requirements...\n")
  
  data_preview <- read_csv(input_file, n_max = 5, show_col_types = FALSE)
  
  snv_cols <- grep("^Magen.*_SNV$|^Magen.*SNV$", names(data_preview), value = TRUE)
  total_cols <- grep("\\(PM\\+1MM\\+2MM\\)$", names(data_preview), value = TRUE)
  
  if (length(snv_cols) == 0 && length(total_cols) == 0) {
    cat("⚠️  Warning: No SNV or Total columns detected with expected naming pattern\n")
    cat("      Expected SNV pattern: 'Magen_XXX_SNV' or 'Magen_XXXSNV'\n")
    cat("      Expected Total pattern: 'Magen_XXX (PM+1MM+2MM)'\n")
    cat("      Found columns: ", paste(head(names(data_preview), 10), collapse = ", "), "\n", sep = "")
    cat("      This may cause issues in VAF calculation\n")
  } else {
    cat("✅ SNV columns found:", length(snv_cols), "\n")
    cat("✅ Total columns found:", length(total_cols), "\n")
    
    # Check if counts match
    if (length(snv_cols) > 0 && length(total_cols) > 0) {
      if (length(snv_cols) != length(total_cols)) {
        cat("⚠️  Warning: Number of SNV columns (", length(snv_cols), 
            ") != Total columns (", length(total_cols), ")\n", sep = "")
        cat("      VAF calculation may be incomplete\n")
      } else {
        cat("✅ SNV and Total column counts match\n")
      }
    }
  }
  
  return(TRUE)
}

# ============================================================================
# VALIDATE CONFIGURATION FILE
# ============================================================================

#' Validate configuration file
#' 
#' @param config_file Path to config.yaml
#' @return TRUE if valid, stops with error if invalid
validate_config <- function(config_file = "config/config.yaml") {
  
  cat("\n")
  cat("═══════════════════════════════════════════════════════════════════\n")
  cat("  ⚙️  VALIDATING CONFIGURATION\n")
  cat("═══════════════════════════════════════════════════════════════════\n\n")
  
  # Check if config exists
  if (!file.exists(config_file)) {
    stop(paste0(
      "\n❌ ERROR: Configuration file not found\n",
      "   Expected: ", config_file, "\n",
      "   Action: Copy config/config.yaml.example to config/config.yaml\n",
      "   Then edit config/config.yaml with your paths\n"
    ))
  }
  
  cat("✅ Config file exists:", config_file, "\n")
  
  # Try to read config (basic YAML validation)
  # Note: In R, we can't easily parse YAML without yaml package
  # This is a basic check - full validation would need yaml package or Python script
  
  config_content <- readLines(config_file, n = 50, warn = FALSE)
  
  # Check for common issues
  if (any(grepl("^paths:", config_content))) {
    cat("✅ Config structure appears valid\n")
  } else {
    cat("⚠️  Warning: Config structure may be invalid\n")
    cat("      Expected 'paths:' section\n")
  }
  
  # Check for placeholder paths
  placeholder_paths <- grepl("/path/to/", config_content, ignore.case = TRUE)
  if (any(placeholder_paths)) {
    stop(paste0(
      "\n❌ ERROR: Configuration contains placeholder paths\n",
      "   Found '/path/to/' in config file\n",
      "   Action: Update all paths in config/config.yaml with your actual data paths\n",
      "   See config/config.yaml.example for guidance\n"
    ))
  }
  
  cat("✅ No placeholder paths found\n")
  
  cat("\n✅ Configuration validation PASSED\n")
  cat("═══════════════════════════════════════════════════════════════════\n\n")
  
  return(TRUE)
}

