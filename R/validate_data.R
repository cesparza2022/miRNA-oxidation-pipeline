# Data Validation Script for ALS miRNA Oxidation Research
# This script validates input data against the project schema

# Load required libraries
library(jsonlite)
library(data.table)
library(yaml)
library(assertthat)

# Function to validate input matrix
validate_input_matrix <- function(matrix_file, schema) {
  cat("Validating input matrix:", matrix_file, "\n")
  
  # Read the matrix
  if (!file.exists(matrix_file)) {
    stop("Input matrix file not found: ", matrix_file)
  }
  
  # Read matrix (assuming CSV format)
  mat <- fread(matrix_file)
  
  # Check required columns
  required_cols <- c("SNV", "TOTAL")
  missing_cols <- setdiff(required_cols, names(mat))
  if (length(missing_cols) > 0) {
    stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
  }
  
  # Check data types
  if (!is.numeric(mat$SNV)) {
    stop("SNV column must be numeric")
  }
  if (!is.numeric(mat$TOTAL)) {
    stop("TOTAL column must be numeric")
  }
  
  # Check value ranges
  if (any(mat$SNV < 0, na.rm = TRUE)) {
    stop("SNV values must be non-negative")
  }
  if (any(mat$TOTAL < 0, na.rm = TRUE)) {
    stop("TOTAL values must be non-negative")
  }
  
  # Check SNV <= TOTAL constraint
  if (any(mat$SNV > mat$TOTAL, na.rm = TRUE)) {
    stop("SNV values must be less than or equal to TOTAL values")
  }
  
  cat("✓ Input matrix validation passed\n")
  return(TRUE)
}

# Function to validate sample metadata
validate_sample_metadata <- function(metadata_file, schema) {
  cat("Validating sample metadata:", metadata_file, "\n")
  
  # Read the metadata
  if (!file.exists(metadata_file)) {
    stop("Sample metadata file not found: ", metadata_file)
  }
  
  # Read metadata (assuming TSV format)
  meta <- fread(metadata_file)
  
  # Check required columns
  required_cols <- c("group", "timepoint", "subject_id", "batch")
  missing_cols <- setdiff(required_cols, names(meta))
  if (length(missing_cols) > 0) {
    stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
  }
  
  # Check group values
  valid_groups <- c("ALS", "Control", "Treatment")
  invalid_groups <- setdiff(unique(meta$group), valid_groups)
  if (length(invalid_groups) > 0) {
    stop("Invalid group values: ", paste(invalid_groups, collapse = ", "))
  }
  
  # Check timepoint format (basic check)
  if (any(is.na(meta$timepoint))) {
    stop("timepoint column cannot contain NA values")
  }
  
  # Check subject_id uniqueness
  if (any(duplicated(meta$subject_id))) {
    stop("subject_id values must be unique")
  }
  
  cat("✓ Sample metadata validation passed\n")
  return(TRUE)
}

# Function to validate miRNA sequences
validate_mirna_sequences <- function(sequences_file, schema) {
  cat("Validating miRNA sequences:", sequences_file, "\n")
  
  # Read the sequences
  if (!file.exists(sequences_file)) {
    stop("miRNA sequences file not found: ", sequences_file)
  }
  
  # Read FASTA file
  sequences <- readLines(sequences_file)
  
  # Check FASTA format
  headers <- sequences[grepl("^>", sequences)]
  if (length(headers) == 0) {
    stop("No FASTA headers found (lines starting with '>')")
  }
  
  # Check sequence lines
  seq_lines <- sequences[!grepl("^>", sequences) & sequences != ""]
  if (length(seq_lines) == 0) {
    stop("No sequence data found")
  }
  
  # Check nucleotide composition
  all_sequences <- paste(seq_lines, collapse = "")
  valid_nucleotides <- grepl("^[ATCGU]+$", all_sequences)
  if (!valid_nucleotides) {
    stop("Sequences contain invalid nucleotides (only A, T, C, G, U allowed)")
  }
  
  # Check sequence lengths
  seq_lengths <- nchar(seq_lines)
  if (any(seq_lengths < 15)) {
    stop("Some sequences are too short (< 15 nucleotides)")
  }
  if (any(seq_lengths > 30)) {
    stop("Some sequences are too long (> 30 nucleotides)")
  }
  
  cat("✓ miRNA sequences validation passed\n")
  return(TRUE)
}

# Function to run quality control checks
run_quality_control <- function(matrix_file, metadata_file, config) {
  cat("Running quality control checks...\n")
  
  # Read data
  mat <- fread(matrix_file)
  meta <- fread(metadata_file)
  
  # Coverage analysis
  coverage_stats <- mat[, .(
    mean_coverage = mean(TOTAL, na.rm = TRUE),
    median_coverage = median(TOTAL, na.rm = TRUE),
    min_coverage = min(TOTAL, na.rm = TRUE),
    max_coverage = max(TOTAL, na.rm = TRUE),
    samples_with_coverage = sum(TOTAL >= config$qc$coverage$min_coverage, na.rm = TRUE)
  )]
  
  cat("Coverage statistics:\n")
  print(coverage_stats)
  
  # Sample filtering
  sample_reads <- mat[, .(total_reads = sum(TOTAL, na.rm = TRUE)), by = .(sample_id = names(mat)[-1])]
  low_read_samples <- sample_reads[total_reads < config$qc$sample_filtering$min_reads]
  
  if (nrow(low_read_samples) > 0) {
    cat("Warning: Samples with low read counts:\n")
    print(low_read_samples)
  }
  
  # miRNA filtering
  mirna_coverage <- mat[, .(
    samples_with_coverage = sum(TOTAL >= config$qc$coverage$min_coverage, na.rm = TRUE),
    total_variants = sum(SNV, na.rm = TRUE)
  ), by = .(mirna_id = names(mat)[1])]
  
  low_coverage_mirnas <- mirna_coverage[samples_with_coverage < config$qc$mirna_filtering$min_samples]
  
  if (nrow(low_coverage_mirnas) > 0) {
    cat("Warning: miRNAs with low coverage:\n")
    print(low_coverage_mirnas)
  }
  
  cat("✓ Quality control checks completed\n")
  return(list(
    coverage_stats = coverage_stats,
    low_read_samples = low_read_samples,
    low_coverage_mirnas = low_coverage_mirnas
  ))
}

# Main validation function
validate_project_data <- function(config_file = "config.yaml", 
                                 schema_file = "data_schema.json",
                                 matrix_file = NULL,
                                 metadata_file = NULL,
                                 sequences_file = NULL) {
  
  cat("Starting data validation for ALS miRNA Oxidation Research Project\n")
  cat(paste(rep("=", 60), collapse = ""), "\n")
  
  # Load configuration and schema
  config <- read_yaml(config_file)
  schema <- fromJSON(schema_file, simplifyVector = FALSE)
  
  # Use config file paths if not provided
  if (is.null(matrix_file)) {
    matrix_file <- config$data$input_matrix
  }
  if (is.null(metadata_file)) {
    metadata_file <- config$data$sample_metadata
  }
  if (is.null(sequences_file)) {
    sequences_file <- config$data$mirna_sequences
  }
  
  # Run validations
  tryCatch({
    validate_input_matrix(matrix_file, schema)
    validate_sample_metadata(metadata_file, schema)
    validate_mirna_sequences(sequences_file, schema)
    
    # Run quality control
    qc_results <- run_quality_control(matrix_file, metadata_file, config)
    
    cat("\n", paste(rep("=", 60), collapse = ""), "\n")
    cat("✓ All data validation checks passed successfully!\n")
    cat("Project data is ready for analysis.\n")
    
    return(list(
      status = "success",
      qc_results = qc_results
    ))
    
  }, error = function(e) {
    cat("\n", paste(rep("=", 60), collapse = ""), "\n")
    cat("✗ Data validation failed:\n")
    cat("Error:", e$message, "\n")
    cat("Please fix the issues and run validation again.\n")
    
    return(list(
      status = "error",
      error = e$message
    ))
  })
}

# Run validation if script is executed directly
if (sys.nframe() == 0) {
  validate_project_data()
}
