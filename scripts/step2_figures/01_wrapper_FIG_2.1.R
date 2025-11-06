#!/usr/bin/env Rscript
# ============================================================================
# WRAPPER: FIGURA 2.1 - VAF GLOBAL COMPARISON
# ============================================================================
# Adapts paths and executes the original script
# Output: FIG_2.1_VAF_GLOBAL_CLEAN.png (uses LINEAR_SCALE version)
# ============================================================================

# Get Snakemake variables
snakemake <- S4Vectors::new("Snakemake")
if (exists("snakemake")) {
  input_data <- snakemake@input[["data"]]
  metadata_file <- snakemake@input[["metadata"]]
  output_figure <- snakemake@output[["figure"]]
  original_script <- snakemake@params[["original_script"]]
  work_dir <- snakemake@params[["work_dir"]]
} else {
  # Fallback for testing
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) < 5) {
    stop("Usage: Rscript 01_wrapper_FIG_2.1.R <input_data> <metadata> <output_figure> <original_script> <work_dir>")
  }
  input_data <- args[1]
  metadata_file <- args[2]
  output_figure <- args[3]
  original_script <- args[4]
  work_dir <- args[5]
}

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  WRAPPER: FIGURA 2.1 - VAF GLOBAL COMPARISON\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# Save original working directory
original_wd <- getwd()

# Change to work directory
setwd(work_dir)
cat("📂 Working directory:", work_dir, "\n")

# Create symlinks/copies for scripts
data_link <- "final_processed_data_CLEAN.csv"
metadata_link <- "metadata.csv"

if (file.exists(data_link)) unlink(data_link)
if (file.exists(metadata_link)) unlink(metadata_link)

file.symlink(normalizePath(input_data), data_link)
file.symlink(normalizePath(metadata_file), metadata_link)

cat("✅ Symlinks created\n")

# Source the original script
cat("📜 Sourcing original script:", original_script, "\n")
source(original_script, local = TRUE)

# Find the generated figure and copy to final location
figures_dir <- file.path(work_dir, "figures_paso2_CLEAN")
generated_fig <- file.path(figures_dir, "FIG_2.1_LINEAR_SCALE.png")

if (file.exists(generated_fig)) {
  # Copy to final location with correct name
  file.copy(generated_fig, output_figure, overwrite = TRUE)
  cat("✅ Figure copied to:", output_figure, "\n")
} else {
  stop("❌ Generated figure not found:", generated_fig)
}

# Cleanup
setwd(original_wd)
cat("\n✅ Wrapper completed\n\n")

