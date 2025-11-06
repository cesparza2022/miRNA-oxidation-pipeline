#!/usr/bin/env Rscript
# ============================================================================
# Generate Pipeline Info (Metadata)
# FASE 2: Creates execution_info.yaml, software_versions.yml, config_used.yaml
# ============================================================================

library(yaml)
library(jsonlite)

# Check if running in Snakemake context
if (exists("snakemake")) {
  # Snakemake context: use snakemake object
  config_file <- snakemake@params[["config_file"]]
  output_dir <- snakemake@params[["output_dir"]]
  snakemake_dir <- snakemake@params[["snakemake_dir"]]
} else {
  # Command-line context: use commandArgs
  args <- commandArgs(trailingOnly = TRUE)
  config_file <- args[1]  # Path to config.yaml
  output_dir <- args[2]   # Path to results/pipeline_info/
  snakemake_dir <- args[3] # Path to snakemake directory
  
  if (is.na(config_file) || is.na(output_dir)) {
    stop("Usage: Rscript generate_pipeline_info.R <config.yaml> <output_dir> <snakemake_dir>")
  }
}

# Create output directory if it doesn't exist
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# 1. GENERATE execution_info.yaml
# ============================================================================

cat("Generating execution_info.yaml...\n")

# Load config
config <- yaml::read_yaml(config_file)

# Get execution info
execution_date <- Sys.Date()
execution_time <- format(Sys.time(), "%H:%M:%S")
execution_datetime <- format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")

# Count outputs
count_files <- function(pattern, dirs) {
  total <- 0
  for (dir in dirs) {
    if (file.exists(dir) && file.info(dir)$isdir) {
      files <- list.files(dir, pattern = pattern, recursive = TRUE, full.names = FALSE)
      total <- total + length(files)
    }
  }
  return(total)
}

# Define all step directories
# ORDER: Sequential (1, 1.5, 2) → Parallel discovery (7, 5, 6, 3) → Integration (4)
all_steps <- c("step1", "step1_5", "step2", "step3", "step4", "step5", "step6", "step7")
step_dirs <- sapply(all_steps, function(step) {
  file.path(snakemake_dir, "results", step, "final")
}, simplify = FALSE)

# Count outputs across all steps
all_step_dirs <- unlist(step_dirs)
num_figures <- count_files("\\.png$", all_step_dirs)
num_tables <- count_files("\\.csv$", all_step_dirs)

# Count logs (check logs subdirectories)
log_dirs <- sapply(all_steps, function(step) {
  file.path(snakemake_dir, "results", step, "final", "logs")
}, simplify = FALSE)
num_logs <- count_files("\\.log$", unlist(log_dirs))

# Determine pipeline status (check if key outputs exist for each step)
steps_completed <- c()
for (step in all_steps) {
  step_dir <- step_dirs[[step]]
  if (file.exists(step_dir) && file.info(step_dir)$isdir) {
    # Check if step has any outputs (figures or tables)
    has_outputs <- length(list.files(step_dir, recursive = TRUE)) > 0
    if (has_outputs) {
      steps_completed <- c(steps_completed, step)
    }
  }
}

# Helper function for NULL coalescing
`%||%` <- function(x, y) if (is.null(x) || length(x) == 0) y else x

execution_info <- list(
  pipeline = list(
    name = config$project$name %||% "miRNA Oxidation Analysis",
    version = config$project$version %||% "1.0.0",
    description = config$project$description %||% "Reproducible pipeline for analyzing G>T oxidation patterns"
  ),
  execution = list(
    date = as.character(execution_date),
    time = execution_time,
    datetime = execution_datetime,
    status = ifelse(length(steps_completed) == length(all_steps), "completed", "partial"),
    steps_completed = steps_completed
  ),
  parameters = list(
    vaf_threshold = config$analysis$vaf_filter_threshold %||% 0.5,
    alpha = config$analysis$alpha %||% 0.05,
    fdr_method = config$analysis$fdr_method %||% "BH",
    log2fc_threshold = config$analysis$log2fc_threshold %||% 0.58,
    threads = config$resources$threads %||% 4,
    memory_gb = config$resources$memory_gb %||% 8
  ),
  inputs = list(
    raw_data = config$paths$data$raw,
    processed_data = config$paths$data$processed_clean
  ),
  outputs = list(
    step1 = config$paths$outputs$step1,
    step1_5 = config$paths$outputs$step1_5,
    step2 = config$paths$outputs$step2,
    step3 = config$paths$outputs$step3 %||% "results/step3",
    step4 = config$paths$outputs$step4 %||% "results/step4",
    step5 = config$paths$outputs$step5 %||% "results/step5",
    step6 = config$paths$outputs$step6 %||% "results/step6",
    step7 = config$paths$outputs$step7 %||% "results/step7",
    total_figures = num_figures,
    total_tables = num_tables,
    total_logs = num_logs,
    steps_completed_count = length(steps_completed),
    total_steps = length(all_steps)
  )
)

# Write execution_info.yaml
write_yaml(execution_info, file.path(output_dir, "execution_info.yaml"))
cat("execution_info.yaml created\n")

# ============================================================================
# 2. GENERATE software_versions.yml
# ============================================================================

cat("Generating software_versions.yml...\n")

# Get R version
r_version <- R.version.string

# Get R package versions
get_package_version <- function(pkg) {
  tryCatch({
    as.character(packageVersion(pkg))
  }, error = function(e) "not installed")
}

# List of key packages used in the pipeline
key_packages <- c(
  "tidyverse", "ggplot2", "dplyr", "tidyr", "readr",
  "yaml", "jsonlite", "pheatmap", "patchwork", "ggrepel",
  "viridis", "RColorBrewer", "scales"
)

package_versions <- sapply(key_packages, get_package_version)
package_versions <- package_versions[package_versions != "not installed"]

# Get Snakemake version (if available via system call)
snakemake_version <- tryCatch({
  version_output <- system2("snakemake", "--version", stdout = TRUE, stderr = TRUE)
  if (length(version_output) > 0) {
    version_output[1]
  } else {
    "unknown"
  }
}, error = function(e) "unknown")

# Helper function for NULL coalescing (if not already defined)
if (!exists("%||%")) {
  `%||%` <- function(x, y) if (is.null(x) || length(x) == 0) y else x
}

software_versions <- list(
  software = list(
    r_version = r_version,
    snakemake_version = snakemake_version,
    platform = R.version$platform,
    r_packages = as.list(package_versions)
  )
)

# Write software_versions.yml
write_yaml(software_versions, file.path(output_dir, "software_versions.yml"))
cat("software_versions.yml created\n")

# ============================================================================
# 3. COPY config_used.yaml
# ============================================================================

cat("Copying config_used.yaml...\n")
file.copy(config_file, file.path(output_dir, "config_used.yaml"), overwrite = TRUE)
cat("config_used.yaml created\n")

# ============================================================================
# 4. GENERATE provenance.json
# ============================================================================

cat("Generating provenance.json...\n")

# Helper function (if not already defined)
if (!exists("%||%")) {
  `%||%` <- function(x, y) if (is.null(x) || length(x) == 0) y else x
}

provenance <- list(
  pipeline = list(
    name = config$project$name %||% "miRNA Oxidation Analysis",
    version = config$project$version %||% "1.0.0",
    execution_date = as.character(execution_date)
  ),
  inputs = list(
    raw_data = list(
      path = config$paths$data$raw,
      description = "Raw miRNA count data",
      exists = file.exists(config$paths$data$raw)
    ),
    processed_clean = list(
      path = config$paths$data$processed_clean,
      description = "Processed clean data (input for Step 1)",
      exists = file.exists(config$paths$data$processed_clean)
    )
  ),
  outputs = list(
    step1 = list(
      path = file.path(snakemake_dir, config$paths$outputs$step1),
      description = "Step 1: Exploratory analysis results",
      exists = file.exists(file.path(snakemake_dir, config$paths$outputs$step1))
    ),
    step1_5 = list(
      path = file.path(snakemake_dir, config$paths$outputs$step1_5),
      description = "Step 1.5: VAF filtered data",
      exists = file.exists(file.path(snakemake_dir, config$paths$outputs$step1_5))
    ),
    step2 = list(
      path = file.path(snakemake_dir, config$paths$outputs$step2),
      description = "Step 2: Statistical comparisons",
      exists = file.exists(file.path(snakemake_dir, config$paths$outputs$step2))
    ),
    step3 = list(
      path = file.path(snakemake_dir, config$paths$outputs$step3 %||% "results/step3"),
      description = "Step 3: Clustering analysis (Structure Discovery)",
      exists = file.exists(file.path(snakemake_dir, config$paths$outputs$step3 %||% "results/step3"))
    ),
    step4 = list(
      path = file.path(snakemake_dir, config$paths$outputs$step4 %||% "results/step4"),
      description = "Step 4: miRNA family analysis",
      exists = file.exists(file.path(snakemake_dir, config$paths$outputs$step4 %||% "results/step4"))
    ),
    step5 = list(
      path = file.path(snakemake_dir, config$paths$outputs$step5 %||% "results/step5"),
      description = "Step 5: Expression vs oxidation correlation",
      exists = file.exists(file.path(snakemake_dir, config$paths$outputs$step5 %||% "results/step5"))
    ),
    step6 = list(
      path = file.path(snakemake_dir, config$paths$outputs$step6 %||% "results/step6"),
      description = "Step 6: Functional analysis",
      exists = file.exists(file.path(snakemake_dir, config$paths$outputs$step6 %||% "results/step6"))
    ),
    step7 = list(
      path = file.path(snakemake_dir, config$paths$outputs$step7 %||% "results/step7"),
      description = "Step 7: Biomarker analysis (Final Integration)",
      exists = file.exists(file.path(snakemake_dir, config$paths$outputs$step7 %||% "results/step7"))
    )
  ),
  processing = list(
    step1_uses = "processed_clean",
    step1_5_uses = "step1_original",
    step2_uses = "step1_5_filtered_data",
    step7_uses = "step2_statistical_comparisons",
    step5_uses = "step2_statistical_comparisons",
    step6_uses = "step2_statistical_comparisons",
    step3_uses = "step2_statistical_comparisons",
    step4_uses = "step3_functional_analysis",
    logical_order = "1 → 1.5 → 2 → [7,5,6,3 parallel] → 4"
  )
)

# Write provenance.json
write_json(provenance, file.path(output_dir, "provenance.json"), pretty = TRUE, auto_unbox = TRUE)
cat("provenance.json created\n")

cat("\nPipeline info generation completed.\n")
cat(sprintf("Output directory: %s\n", output_dir))
cat(sprintf("Files created:\n"))
cat(sprintf("  - execution_info.yaml\n"))
cat(sprintf("  - software_versions.yml\n"))
cat(sprintf("  - config_used.yaml\n"))
cat(sprintf("  - provenance.json\n"))

