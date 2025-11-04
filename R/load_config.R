# Configuration Loader for ALS miRNA Oxidation Research
# This script loads and validates project configuration

# Load required libraries
library(yaml)
library(jsonlite)
library(assertthat)

# Function to load configuration
load_config <- function(config_file = "config.yaml") {
  cat("Loading configuration from:", config_file, "\n")
  
  if (!file.exists(config_file)) {
    stop("Configuration file not found: ", config_file)
  }
  
  # Load YAML configuration
  config <- read_yaml(config_file)
  
  # Validate configuration structure
  validate_config(config)
  
  cat("✓ Configuration loaded successfully\n")
  return(config)
}

# Function to validate configuration
validate_config <- function(config) {
  cat("Validating configuration...\n")
  
  # Check required sections
  required_sections <- c("project", "data", "analysis", "visualization", "computing", "qc", "output", "logging", "validation")
  missing_sections <- setdiff(required_sections, names(config))
  if (length(missing_sections) > 0) {
    stop("Missing required configuration sections: ", paste(missing_sections, collapse = ", "))
  }
  
  # Validate project section
  assert_that(is.character(config$project$name))
  assert_that(is.character(config$project$version))
  assert_that(is.character(config$project$description))
  
  # Validate data section
  assert_that(is.character(config$data$input_matrix))
  assert_that(is.character(config$data$sample_metadata))
  assert_that(is.character(config$data$mirna_sequences))
  assert_that(is.numeric(config$data$min_coverage))
  assert_that(is.numeric(config$data$min_samples_per_group))
  assert_that(is.numeric(config$data$quality_threshold))
  
  # Validate analysis section
  assert_that(is.numeric(config$analysis$alpha))
  assert_that(is.character(config$analysis$fdr_method))
  assert_that(is.numeric(config$analysis$n_permutations))
  assert_that(is.character(config$analysis$clustering$methods))
  assert_that(is.numeric(config$analysis$clustering$k_range))
  assert_that(is.numeric(config$analysis$seed$start_position))
  assert_that(is.numeric(config$analysis$seed$end_position))
  
  # Validate visualization section
  assert_that(is.numeric(config$visualization$figure$width))
  assert_that(is.numeric(config$visualization$figure$height))
  assert_that(is.numeric(config$visualization$figure$dpi))
  assert_that(is.character(config$visualization$figure$format))
  
  # Validate computing section
  assert_that(is.numeric(config$computing$n_cores))
  assert_that(is.character(config$computing$parallel_backend))
  
  # Validate QC section
  assert_that(is.numeric(config$qc$coverage$min_coverage))
  assert_that(is.numeric(config$qc$coverage$max_coverage))
  assert_that(is.numeric(config$qc$sample_filtering$min_reads))
  assert_that(is.numeric(config$qc$sample_filtering$max_missing))
  assert_that(is.numeric(config$qc$mirna_filtering$min_samples))
  assert_that(is.numeric(config$qc$mirna_filtering$min_variants))
  
  # Validate output section
  assert_that(is.character(config$output$file_prefix))
  assert_that(is.character(config$output$timestamp_format))
  assert_that(is.logical(config$output$generate_reports))
  assert_that(is.character(config$output$report_format))
  assert_that(is.logical(config$output$include_code))
  
  # Validate logging section
  assert_that(is.character(config$logging$level))
  assert_that(is.character(config$logging$file))
  assert_that(is.character(config$logging$max_size))
  assert_that(is.numeric(config$logging$backup_count))
  
  # Validate validation section
  assert_that(is.logical(config$validation$check_required_columns))
  assert_that(is.logical(config$validation$check_data_types))
  assert_that(is.logical(config$validation$check_value_ranges))
  assert_that(is.logical(config$validation$use_schema))
  assert_that(is.character(config$validation$schema_file))
  assert_that(is.logical(config$validation$cross_validate))
  assert_that(is.numeric(config$validation$cv_folds))
  
  cat("✓ Configuration validation passed\n")
}

# Function to get data paths
get_data_paths <- function(config) {
  list(
    input_matrix = config$data$input_matrix,
    sample_metadata = config$data$sample_metadata,
    mirna_sequences = config$data$mirna_sequences,
    output_dir = config$data$output_dir,
    fig_dir = config$data$fig_dir,
    tables_dir = config$data$tables_dir,
    runs_dir = config$data$runs_dir
  )
}

# Function to get analysis parameters
get_analysis_params <- function(config) {
  list(
    alpha = config$analysis$alpha,
    fdr_method = config$analysis$fdr_method,
    n_permutations = config$analysis$n_permutations,
    clustering_methods = config$analysis$clustering$methods,
    k_range = config$analysis$clustering$k_range,
    consensus_threshold = config$analysis$clustering$consensus_threshold,
    seed_start = config$analysis$seed$start_position,
    seed_end = config$analysis$seed$end_position,
    min_seed_match = config$analysis$target_prediction$min_seed_match,
    max_mismatch = config$analysis$target_prediction$max_mismatch,
    min_free_energy = config$analysis$target_prediction$min_free_energy
  )
}

# Function to get quality control parameters
get_qc_params <- function(config) {
  list(
    min_coverage = config$qc$coverage$min_coverage,
    max_coverage = config$qc$coverage$max_coverage,
    coverage_percentiles = config$qc$coverage$coverage_percentiles,
    min_reads = config$qc$sample_filtering$min_reads,
    max_missing = config$qc$sample_filtering$max_missing,
    min_samples = config$qc$mirna_filtering$min_samples,
    min_variants = config$qc$mirna_filtering$min_variants
  )
}

# Function to get visualization parameters
get_viz_params <- function(config) {
  list(
    figure_width = config$visualization$figure$width,
    figure_height = config$visualization$figure$height,
    figure_dpi = config$visualization$figure$dpi,
    figure_format = config$visualization$figure$format,
    group_colors = config$visualization$colors$group_colors,
    heatmap_colors = config$visualization$colors$heatmap_colors,
    theme = config$visualization$theme
  )
}

# Function to get computing parameters
get_computing_params <- function(config) {
  list(
    n_cores = config$computing$n_cores,
    parallel_backend = config$computing$parallel_backend,
    max_memory = config$computing$max_memory,
    chunk_size = config$computing$chunk_size
  )
}

# Function to get output parameters
get_output_params <- function(config) {
  list(
    file_prefix = config$output$file_prefix,
    timestamp_format = config$output$timestamp_format,
    generate_reports = config$output$generate_reports,
    report_format = config$output$report_format,
    include_code = config$output$include_code,
    export_formats = config$output$export_formats,
    include_metadata = config$output$include_metadata
  )
}

# Function to get logging parameters
get_logging_params <- function(config) {
  list(
    level = config$logging$level,
    file = config$logging$file,
    max_size = config$logging$max_size,
    backup_count = config$logging$backup_count
  )
}

# Function to get validation parameters
get_validation_params <- function(config) {
  list(
    check_required_columns = config$validation$check_required_columns,
    check_data_types = config$validation$check_data_types,
    check_value_ranges = config$validation$check_value_ranges,
    use_schema = config$validation$use_schema,
    schema_file = config$validation$schema_file,
    cross_validate = config$validation$cross_validate,
    cv_folds = config$validation$cv_folds
  )
}

# Function to create output directories
create_output_dirs <- function(config) {
  dirs <- c(
    config$data$fig_dir,
    config$data$tables_dir,
    config$data$runs_dir
  )
  
  for (dir in dirs) {
    if (!dir.exists(dir)) {
      dir.create(dir, recursive = TRUE)
      cat("Created directory:", dir, "\n")
    }
  }
}

# Function to setup logging
setup_logging <- function(config) {
  # Create runs directory if it doesn't exist
  if (!dir.exists(config$data$runs_dir)) {
    dir.create(config$data$runs_dir, recursive = TRUE)
  }
  
  # Setup logging parameters
  log_file <- file.path(config$data$runs_dir, basename(config$logging$file))
  
  # Configure logging level
  log_level <- switch(config$logging$level,
    "DEBUG" = 0,
    "INFO" = 1,
    "WARN" = 2,
    "ERROR" = 3,
    1  # Default to INFO
  )
  
  cat("Logging configured - Level:", config$logging$level, "- File:", log_file, "\n")
  
  return(list(
    log_file = log_file,
    log_level = log_level
  ))
}

# Main configuration loader function
load_project_config <- function(config_file = "config.yaml") {
  cat("Loading ALS miRNA Oxidation Research Project Configuration\n")
  cat(paste(rep("=", 60), collapse = ""), "\n")
  
  # Load configuration
  config <- load_config(config_file)
  
  # Create output directories
  create_output_dirs(config)
  
  # Setup logging
  logging_config <- setup_logging(config)
  
  # Return comprehensive configuration
  list(
    config = config,
    data_paths = get_data_paths(config),
    analysis_params = get_analysis_params(config),
    qc_params = get_qc_params(config),
    viz_params = get_viz_params(config),
    computing_params = get_computing_params(config),
    output_params = get_output_params(config),
    logging_params = get_logging_params(config),
    validation_params = get_validation_params(config),
    logging_config = logging_config
  )
}

# Run configuration loading if script is executed directly
if (sys.nframe() == 0) {
  project_config <- load_project_config()
  cat("Project configuration loaded successfully!\n")
}
