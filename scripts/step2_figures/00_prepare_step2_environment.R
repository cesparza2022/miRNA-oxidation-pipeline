#!/usr/bin/env Rscript
# ============================================================================
# PREPARE STEP 2 ENVIRONMENT
# ============================================================================
# This script prepares the working environment for Step 2 figure generation
# - Generates metadata.csv from sample columns
# - Creates symlink or copy of data file
# - Sets up output directory
# ============================================================================

library(dplyr)
library(readr)

# Get command line arguments
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 3) {
  stop("Usage: Rscript 00_prepare_step2_environment.R <input_data.csv> <output_dir> <metadata_output.csv>")
}

input_data <- args[1]
output_dir <- args[2]
metadata_output <- args[3]

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  PREPARING STEP 2 ENVIRONMENT\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# Create output directory
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
cat("✅ Output directory created:", output_dir, "\n")

# Create figures subdirectory (equivalent to figures_paso2_CLEAN)
figures_dir <- file.path(output_dir, "figures_paso2_CLEAN")
dir.create(figures_dir, showWarnings = FALSE, recursive = TRUE)
cat("✅ Figures directory created:", figures_dir, "\n")

# Load data to identify sample columns
cat("\n📂 Loading data to identify sample columns...\n")
data <- read_csv(input_data, show_col_types = FALSE, n_max = 1)

# Identify metadata columns
metadata_cols <- c("miRNA_name", "miRNA name", "pos.mut", "pos:mut", 
                   "mutation_type", "position")

# Get sample columns
all_cols <- colnames(data)
sample_cols <- all_cols[!all_cols %in% metadata_cols]

cat("   ✅ Found", length(sample_cols), "sample columns\n")

# Create metadata
metadata <- data.frame(
  Sample_ID = sample_cols,
  Group = ifelse(
    grepl("ALS|als|Amyotrophic|motor", sample_cols, ignore.case = TRUE),
    "ALS",
    ifelse(
      grepl("Control|control|Ctrl|CTRL|healthy|Healthy|Normal|normal", 
            sample_cols, ignore.case = TRUE),
      "Control",
      "Unknown"
    )
  ),
  stringsAsFactors = FALSE
)

# If no pattern found, use first half as Control, second as ALS
if (sum(metadata$Group == "Unknown") == length(sample_cols)) {
  cat("   ⚠️  No clear pattern found, using first half as Control, second as ALS\n")
  n_samples <- length(sample_cols)
  metadata$Group <- c(rep("Control", ceiling(n_samples/2)), 
                      rep("ALS", floor(n_samples/2)))
}

n_als <- sum(metadata$Group == "ALS")
n_ctrl <- sum(metadata$Group == "Control")

cat("\n📊 Group assignment:\n")
cat("   ✅ ALS:", n_als, "samples\n")
cat("   ✅ Control:", n_ctrl, "samples\n")

# Save metadata
write_csv(metadata, metadata_output)
cat("\n✅ Metadata saved to:", metadata_output, "\n")

# Create symlink or copy of data file to current directory
# (Scripts expect final_processed_data_CLEAN.csv in current dir)
data_link <- "final_processed_data_CLEAN.csv"
if (file.exists(data_link)) {
  unlink(data_link)
}
file.symlink(normalizePath(input_data), data_link)
cat("✅ Data symlink created:", data_link, "\n")

cat("\n✅ Environment ready for Step 2 figure generation\n\n")

