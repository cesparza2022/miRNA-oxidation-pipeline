# ============================================================================
# COMMON FUNCTIONS FOR SNAKEMAKE PIPELINE
# ============================================================================
# Shared utility functions used across all pipeline steps

suppressPackageStartupMessages({
  library(tidyverse)
  library(readr)
  library(stringr)
})

# Source logging functions (robust method)
if (!exists("log_info")) {
  script_dir <- getwd()
  utils_dir <- file.path(script_dir, "scripts", "utils")
  
  logging_paths <- c(
    file.path(utils_dir, "logging.R"),
    "scripts/utils/logging.R",
    "./scripts/utils/logging.R"
  )
  
  for (log_path in logging_paths) {
    if (file.exists(log_path)) {
      source(log_path, local = TRUE)
      break
    }
  }
}

# Source validation functions (robust method that works with Rscript/Snakemake)
# Try multiple methods to find validate_input.R
if (!exists("validate_input")) {
  # Get the directory where functions_common.R is located
  # When sourced from Snakemake, we can infer the path
  script_dir <- getwd()  # Snakemake sets working directory to pipeline root
  utils_dir <- file.path(script_dir, "scripts", "utils")
  
  # Try multiple possible paths
  possible_paths <- c(
    file.path(utils_dir, "validate_input.R"),           # Most common case
    "scripts/utils/validate_input.R",                    # Relative from any location
    file.path(dirname(sys.frame(1)$ofile %||% "."), "validate_input.R"),  # Same dir as this file
    "./scripts/utils/validate_input.R"                   # From root
  )
  
  # Try each path
  for (validate_path in possible_paths) {
    if (file.exists(validate_path)) {
      source(validate_path, local = TRUE)
      cat("✅ Loaded validation functions from:", validate_path, "\n")
      break
    }
  }
  
  # If still not found, warn but don't fail (validation is optional)
  if (!exists("validate_input")) {
    cat("⚠️  Warning: validate_input.R not found. Validation functions unavailable.\n")
    cat("   Searched in:", paste(possible_paths, collapse = ", "), "\n")
    cat("   Continuing without input validation...\n")
  }
}

# Professional colors (consistent across pipeline)
COLOR_GT <- "#D62728"  # Red for G>T (oxidation)
COLOR_CONTROL <- "grey60"
COLOR_ALS <- "#D62728"

# Load professional theme if available
if (file.exists("scripts/utils/theme_professional.R")) {
  source("scripts/utils/theme_professional.R", local = TRUE)
} else if (file.exists(file.path(dirname(getwd()), "scripts/utils/theme_professional.R"))) {
  source(file.path(dirname(getwd()), "scripts/utils/theme_professional.R"), local = TRUE)
} else {
  # Fallback theme
  theme_professional <- theme_minimal(base_size = 11) +
    theme(
      plot.title = element_text(size = 13, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 10, color = "grey40", hjust = 0.5),
      axis.title = element_text(size = 11, face = "bold"),
      axis.text = element_text(size = 10, color = "grey30"),
      panel.grid.major = element_line(color = "grey90", linewidth = 0.5),
      panel.grid.minor = element_line(color = "grey95", linewidth = 0.25)
    )
}

# ============================================================================
# DATA LOADING FUNCTIONS
# ============================================================================

#' Load processed data from CSV file
#' 
#' @param input_file Path to the processed data CSV
#' @return Data frame with miRNA data
load_processed_data <- function(input_file) {
  if (!file.exists(input_file)) {
    stop(paste("❌ Input file not found:", input_file))
  }
  
  cat("📂 Loading data from:", input_file, "\n")
  data <- read_csv(input_file, show_col_types = FALSE)
  
  # Verify expected columns exist
  if (!"miRNA_name" %in% names(data) || !"pos.mut" %in% names(data)) {
    stop("❌ Input file missing required columns: 'miRNA_name' or 'pos.mut'")
  }
  
  sample_cols <- setdiff(names(data), c("miRNA_name", "pos.mut"))
  
  cat("   ✅ Data loaded:", nrow(data), "rows\n")
  cat("   ✅ Samples:", length(sample_cols), "\n")
  
  return(data)
}

#' Load and process raw data (TSV format with pos:mut column)
#' 
#' @param raw_file Path to raw TSV file (miRNA_count.Q33.txt)
#' @return Processed data frame with separated mutations
load_and_process_raw_data <- function(raw_file) {
  if (!file.exists(raw_file)) {
    stop(paste("❌ Raw file not found:", raw_file))
  }
  
  cat("📂 Loading raw data from:", raw_file, "\n")
  raw_data <- read_tsv(raw_file, show_col_types = FALSE)
  
  cat("   ✅ Raw data loaded:", nrow(raw_data), "rows\n")
  
  # Process data: separate rows and extract mutations
  processed_data <- raw_data %>%
    separate_rows(`pos:mut`, sep = ",") %>%
    filter(`pos:mut` != "PM") %>%
    separate(`pos:mut`, into = c("position", "mutation_type_raw"), sep = ":", remove = FALSE) %>%
    mutate(
      position = as.numeric(position),
      mutation_type = str_replace_all(mutation_type_raw, c(
        "TC" = "T>C", "AG" = "A>G", "GA" = "G>A", "CT" = "C>T",
        "TA" = "T>A", "GT" = "G>T", "TG" = "T>G", "AT" = "A>T",
        "CA" = "C>A", "CG" = "C>G", "GC" = "G>C", "AC" = "A>C"
      ))
    ) %>%
    filter(position >= 1 & position <= 22)
  
  cat("   ✅ Data processed:", nrow(processed_data), "SNVs\n")
  
  return(processed_data)
}

# ============================================================================
# OUTPUT DIRECTORIES
# ============================================================================

#' Ensure output directory exists
#' 
#' @param output_dir Path to output directory
ensure_output_dir <- function(output_dir) {
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
    cat("   📁 Created output directory:", output_dir, "\n")
  }
}

# ============================================================================
# PROFESSIONAL THEME FOR GGPLOT
# ============================================================================

theme_professional <- theme_classic() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5),
    axis.title = element_text(size = 11),
    axis.text = element_text(size = 10),
    legend.title = element_text(size = 11),
    legend.text = element_text(size = 10),
    strip.text = element_text(size = 11, face = "bold")
  )
