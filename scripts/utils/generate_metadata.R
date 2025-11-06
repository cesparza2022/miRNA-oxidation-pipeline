#!/usr/bin/env Rscript
# ============================================================================
# GENERATE METADATA AUTOMATICALLY FROM SAMPLE COLUMNS
# ============================================================================
# This script creates metadata.csv from sample column names
# Pattern: Identifies ALS vs Control from sample names
# ============================================================================

# Suppress renv messages
options(renv.verbose = FALSE)

# Try to load libraries, install if needed
if (!require("dplyr", quietly = TRUE)) {
  install.packages("dplyr", repos = "https://cran.r-project.org")
  library(dplyr)
}

if (!require("readr", quietly = TRUE)) {
  install.packages("readr", repos = "https://cran.r-project.org")
  library(readr)
}

# Get command line arguments
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) {
  stop("Usage: Rscript generate_metadata.R <input_data.csv> <output_metadata.csv>")
}

input_data <- args[1]
output_metadata <- args[2]

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  GENERATING METADATA FROM SAMPLE COLUMNS\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# Load data to get column names
cat("📂 Loading data to identify sample columns...\n")
data <- read_csv(input_data, show_col_types = FALSE, n_max = 1)

# Identify metadata columns (non-sample columns)
metadata_cols <- c("miRNA_name", "miRNA name", "pos.mut", "pos:mut", 
                   "mutation_type", "position")

# Get all column names
all_cols <- colnames(data)

# Identify sample columns (everything except metadata columns)
sample_cols <- all_cols[!all_cols %in% metadata_cols]

cat("   ✅ Found", length(sample_cols), "sample columns\n")

# Create metadata based on sample name pattern
# Pattern for this dataset: "Magen-ALS-..." or "Magen-control-..."
metadata <- data.frame(
  Sample_ID = sample_cols,
  Group = ifelse(
    grepl("Magen-ALS|ALS|als|Amyotrophic|motor", sample_cols, ignore.case = TRUE),
    "ALS",
    ifelse(
      grepl("Magen-control|Magen-Control|Control|control|Ctrl|CTRL|healthy|Healthy|Normal|normal", 
            sample_cols, ignore.case = TRUE),
      "Control",
      "Unknown"  # Default if pattern not found
    )
  ),
  stringsAsFactors = FALSE
)

# If no pattern found, try to infer from position or other heuristics
if (sum(metadata$Group == "Unknown") == length(sample_cols)) {
  cat("   ⚠️  No clear pattern found, using first half as Control, second as ALS\n")
  n_samples <- length(sample_cols)
  metadata$Group <- c(rep("Control", ceiling(n_samples/2)), 
                      rep("ALS", floor(n_samples/2)))
}

n_als <- sum(metadata$Group == "ALS")
n_ctrl <- sum(metadata$Group == "Control")
n_unknown <- sum(metadata$Group == "Unknown")

cat("\n📊 Group assignment:\n")
cat("   ✅ ALS:", n_als, "samples\n")
cat("   ✅ Control:", n_ctrl, "samples\n")
if (n_unknown > 0) {
  cat("   ⚠️  Unknown:", n_unknown, "samples\n")
}

# Save metadata
write_csv(metadata, output_metadata)
cat("\n✅ Metadata saved to:", output_metadata, "\n\n")

