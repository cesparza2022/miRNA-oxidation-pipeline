#!/usr/bin/env Rscript
# ============================================================================
# CREATE OUTPUT STRUCTURE
# ============================================================================
# Purpose: Create organized output directory structure automatically
# Usage: Rscript create_output_structure.R <base_output_dir>
# ============================================================================

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 1) {
  base_dir <- "results"
} else {
  base_dir <- args[1]
}

# Define output structure
output_structure <- list(
  "step1" = c(
    "figures",
    "tables/summary",
    "tables/raw",
    "logs",
    "logs/benchmarks"
  ),
  "step1_5" = c(
    "figures",
    "tables/filtered_data",
    "tables/filter_report",
    "tables/statistics",
    "logs",
    "logs/benchmarks"
  ),
  "step2" = c(
    "figures",
    "figures_clean",
    "tables/statistical_results",
    "tables/summary",
    "logs",
    "logs/benchmarks"
  ),
  "step3" = c(
    "figures",
    "tables/functional",
    "logs",
    "logs/benchmarks"
  ),
      "step4" = c(
        "figures",
        "tables/biomarkers",
        "logs",
        "logs/benchmarks"
      ),
      "step5" = c(
        "figures",
        "tables/families",
        "logs",
        "logs/benchmarks"
      ),
      "step6" = c(
        "figures",
        "tables/correlation",
        "logs",
        "logs/benchmarks"
      ),
      "step7" = c(
        "figures",
        "tables/clusters",
        "logs",
        "logs/benchmarks"
      ),
      "pipeline_info" = c(),
  "summary" = c(),
  "validation" = c(),
  "viewers" = c()
)

# Create directories
cat("Creating output directory structure...\n\n")

for (step in names(output_structure)) {
  step_dir <- file.path(base_dir, step)
  
  # Create step directory
  if (!dir.exists(step_dir)) {
    dir.create(step_dir, recursive = TRUE, showWarnings = FALSE)
    cat("✅ Created:", step_dir, "\n")
  }
  
  # Create final and intermediate for steps
  if (step %in% c("step1", "step1_5", "step2")) {
    final_dir <- file.path(step_dir, "final")
    intermediate_dir <- file.path(step_dir, "intermediate")
    
    if (!dir.exists(final_dir)) {
      dir.create(final_dir, recursive = TRUE, showWarnings = FALSE)
      cat("  ✅ Created:", final_dir, "\n")
    }
    
    if (!dir.exists(intermediate_dir)) {
      dir.create(intermediate_dir, recursive = TRUE, showWarnings = FALSE)
      cat("  ✅ Created:", intermediate_dir, "\n")
    }
    
    # Create subdirectories within final
    for (subdir in output_structure[[step]]) {
      full_path <- file.path(final_dir, subdir)
      if (!dir.exists(full_path)) {
        dir.create(full_path, recursive = TRUE, showWarnings = FALSE)
        cat("    ✅ Created:", full_path, "\n")
      }
    }
  } else {
    # Create single directory for other outputs
    if (!dir.exists(step_dir)) {
      dir.create(step_dir, recursive = TRUE, showWarnings = FALSE)
      cat("✅ Created:", step_dir, "\n")
    }
  }
}

cat("\n✅ Output structure created successfully!\n")
cat("Base directory:", base_dir, "\n")

