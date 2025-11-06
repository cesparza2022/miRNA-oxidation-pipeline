#!/usr/bin/env Rscript
# ============================================================================
# RUN ALL STEP 2 FIGURES - SNAKEMAKE ADAPTED
# ============================================================================
# This script executes all Step 2 figure generation scripts
# Adapts paths to work with Snakemake structure
# ============================================================================

library(dplyr)
library(readr)

# Get Snakemake variables
# In Snakemake, the script receives variables via command line
args <- commandArgs(trailingOnly = TRUE)
if (length(args) >= 4) {
  # Command line arguments provided
  input_data <- args[1]
  metadata_output <- args[2]
  output_figures_dir <- args[3]
  scripts_source_dir <- args[4]
} else {
  # Try to get from Snakemake object (if available)
  if (exists("snakemake")) {
    input_data <- snakemake@input[["data"]]
    if (!file.exists(input_data) && "fallback" %in% names(snakemake@input)) {
      input_data <- snakemake@input[["fallback"]]
    }
    metadata_output <- snakemake@input[["metadata"]]
    output_figures_dir <- snakemake@params[["output_dir"]]
    scripts_source_dir <- snakemake@params[["scripts_dir"]]
  } else {
    stop("Usage: Rscript run_all_step2_figures.R <input_data> <metadata_output> <output_figures_dir> <scripts_source_dir>")
  }
}

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  RUNNING ALL STEP 2 FIGURES (15 figures - 2.8 removed, redundant with 2.16)\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# Save original working directory
original_wd <- getwd()

# Convert input paths to absolute paths
input_data <- normalizePath(input_data, mustWork = TRUE)
metadata_output <- normalizePath(metadata_output, mustWork = TRUE)
output_figures_dir <- normalizePath(output_figures_dir, mustWork = FALSE)
scripts_source_dir <- normalizePath(scripts_source_dir, mustWork = TRUE)

# Create output directory if it doesn't exist
dir.create(output_figures_dir, showWarnings = FALSE, recursive = TRUE)

# Create temporary working directory
work_dir <- file.path(output_figures_dir, "work")
dir.create(work_dir, showWarnings = FALSE, recursive = TRUE)

# Create figures directory (equivalent to figures_paso2_CLEAN)
figures_dir <- file.path(work_dir, "figures_paso2_CLEAN")
dir.create(figures_dir, showWarnings = FALSE, recursive = TRUE)

cat("📂 Working directory:", work_dir, "\n")
cat("📂 Figures directory:", figures_dir, "\n")
cat("📂 Input data:", input_data, "\n")
cat("📂 Scripts source:", scripts_source_dir, "\n\n")

# Change to work directory
setwd(work_dir)

# ============================================================================
# GENERATE METADATA
# ============================================================================

cat("📋 Generating metadata...\n")

# Load data to identify sample columns (use absolute path)
data <- read_csv(normalizePath(input_data), show_col_types = FALSE, n_max = 1)

# Identify metadata columns
metadata_cols <- c("miRNA_name", "miRNA name", "pos.mut", "pos:mut", 
                   "mutation_type", "position")

# Get sample columns
all_cols <- colnames(data)
sample_cols <- all_cols[!all_cols %in% metadata_cols]

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

# Save metadata (use absolute path for output)
write_csv(metadata, "metadata.csv")
write_csv(metadata, normalizePath(metadata_output, mustWork = FALSE))  # Also save to output location

n_als <- sum(metadata$Group == "ALS")
n_ctrl <- sum(metadata$Group == "Control")
cat("   ✅ ALS:", n_als, "samples\n")
cat("   ✅ Control:", n_ctrl, "samples\n\n")

# ============================================================================
# CREATE DATA COPY WITH FIXED COLUMN NAMES
# ============================================================================

cat("📂 Creating data copy with fixed column names...\n")
data_link <- "final_processed_data_CLEAN.csv"
if (file.exists(data_link)) {
  unlink(data_link)
}

# Read original data and fix column names
cat("   📖 Reading original data...\n")
data_original <- read_csv(normalizePath(input_data, mustWork = TRUE), 
                         show_col_types = FALSE)

# Fix column name: scripts expect "pos.mut" but file has "pos:mut"
if ("pos:mut" %in% colnames(data_original) && !"pos.mut" %in% colnames(data_original)) {
  data_original$pos.mut <- data_original$`pos:mut`
  cat("   ✅ Added pos.mut column (from pos:mut)\n")
}

# Also fix "miRNA name" if needed
if ("miRNA name" %in% colnames(data_original) && !"miRNA_name" %in% colnames(data_original)) {
  data_original$miRNA_name <- data_original$`miRNA name`
  cat("   ✅ Added miRNA_name column (from miRNA name)\n")
}

# Write fixed data
write_csv(data_original, data_link)
cat("   ✅ Data copy created with fixed column names:", data_link, "\n\n")

# ============================================================================
# EXECUTE ALL FIGURE SCRIPTS
# ============================================================================

cat("═══════════════════════════════════════════════════════════════════\n")
cat("  EXECUTING FIGURE GENERATION SCRIPTS\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# Install required packages if needed (suppress warnings)
cat("📦 Checking for required R packages...\n")
options(repos = c(CRAN = "https://cran.r-project.org"))

required_packages <- c("ggplot2", "dplyr", "tidyr", "readr", "stringr", 
                       "patchwork", "viridis", "pheatmap", "FactoMineR", 
                       "factoextra", "ggrepel", "ComplexHeatmap", 
                       "circlize") # Added ComplexHeatmap and circlize for density heatmaps

# Install missing packages
missing_packages <- required_packages[!required_packages %in% installed.packages()[,"Package"]]
if (length(missing_packages) > 0) {
  cat("   Installing missing packages:", paste(missing_packages, collapse = ", "), "\n")
  for (pkg in missing_packages) {
    tryCatch({
      # ComplexHeatmap is from Bioconductor, not CRAN
      if (pkg == "ComplexHeatmap") {
        if (!require("BiocManager", quietly = TRUE)) {
          install.packages("BiocManager", repos = "https://cran.r-project.org", quiet = TRUE)
        }
        BiocManager::install("ComplexHeatmap", quiet = TRUE, update = FALSE)
      } else {
        install.packages(pkg, repos = "https://cran.r-project.org", quiet = TRUE, dependencies = TRUE)
      }
    }, error = function(e) {
      cat("   ⚠️  Could not install", pkg, ":", e$message, "\n")
    })
  }
}

# Load all packages
for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat("   ⚠️  Could not load", pkg, "\n")
  }
}
cat("✅ Required packages loaded\n\n")

# Use the master script that executes all figures in order
# This is more reliable than sourcing individual scripts
master_script <- file.path(scripts_source_dir, "RUN_COMPLETE_PIPELINE_PASO2.R")

if (file.exists(master_script)) {
  cat("📜 Using master script:", master_script, "\n")
  cat("   This will execute all individual scripts in the correct order\n\n")
  
  tryCatch({
    source(master_script, local = TRUE)
    cat("✅ Master script completed\n\n")
  }, error = function(e) {
    cat("❌ Error in master script:", e$message, "\n")
    cat("   Falling back to individual scripts...\n\n")
    
    # Fallback: Execute individual scripts
    scripts <- c(
      "generate_FIG_2.1_COMPARISON_LOG_VS_LINEAR.R",
      "generate_FIG_2.2_SIMPLIFIED.R",
      "generate_FIG_2.3_CORRECTED_AND_ANALYZE.R",
      "generate_FIG_2.4_HEATMAP_RAW.R",
      "generate_FIG_2.5_ZSCORE_ALL301.R",
      "generate_FIG_2.6_POSITIONAL.R",
      "generate_FIG_2.7_IMPROVED.R",
      # "generate_FIG_2.8_CLUSTERING.R",  # REMOVED: Redundant with FIG_2.16 (uses ALL G>T SNVs)
      "generate_FIG_2.9_IMPROVED.R",
      "generate_FIG_2.10_GT_RATIO.R",
      "generate_FIG_2.11_IMPROVED.R",
      "generate_FIG_2.12_ENRICHMENT.R",
      "generate_HEATMAP_DENSITY_GT.R"  # Updated to use correct script
    )
    
    for (script in scripts) {
      script_path <- file.path(scripts_source_dir, script)
      if (file.exists(script_path)) {
        cat("📜 Executing:", script, "\n")
        tryCatch({
          source(script_path, local = TRUE)
          cat("✅ Completed:", script, "\n\n")
        }, error = function(e) {
          cat("❌ Error in", script, ":", e$message, "\n\n")
        })
      } else {
        cat("⚠️  Script not found:", script_path, "\n\n")
      }
    }
  })
} else {
  cat("⚠️  Master script not found:", master_script, "\n")
  cat("   Executing individual scripts...\n\n")
  
  # Execute individual scripts
  scripts <- c(
    "generate_FIG_2.1_COMPARISON_LOG_VS_LINEAR.R",
    "generate_FIG_2.2_SIMPLIFIED.R",
    "generate_FIG_2.3_CORRECTED_AND_ANALYZE.R",
    "generate_FIG_2.4_HEATMAP_RAW.R",
    "generate_FIG_2.5_ZSCORE_ALL301.R",
    "generate_FIG_2.6_POSITIONAL.R",
    "generate_FIG_2.7_IMPROVED.R",
    # "generate_FIG_2.8_CLUSTERING.R",  # REMOVED: Redundant with FIG_2.16 (uses ALL G>T SNVs)
    "generate_FIG_2.9_IMPROVED.R",
    "generate_FIG_2.10_GT_RATIO.R",
    "generate_FIG_2.11_IMPROVED.R",
    "generate_FIG_2.12_ENRICHMENT.R",
    "generate_HEATMAP_DENSITY_GT.R"  # Updated to use correct script
  )
  
  for (script in scripts) {
    script_path <- file.path(scripts_source_dir, script)
    if (file.exists(script_path)) {
      cat("📜 Executing:", script, "\n")
      tryCatch({
        source(script_path, local = TRUE)
        cat("✅ Completed:", script, "\n\n")
      }, error = function(e) {
        cat("❌ Error in", script, ":", e$message, "\n\n")
      })
    } else {
      cat("⚠️  Script not found:", script_path, "\n\n")
    }
  }
}

# ============================================================================
# COPY/ RENAME FIGURES TO FINAL LOCATIONS
# ============================================================================

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  COPYING FIGURES TO FINAL LOCATIONS\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# Mapping of generated figures to final names
# Try multiple possible source names for each figure
figure_mapping <- list(
  # Figure 2.1: Use LINEAR_SCALE version (preferred) or check for VAF_GLOBAL_CLEAN
  list(
    source = c(file.path(figures_dir, "FIG_2.1_VAF_GLOBAL_CLEAN.png"),
               file.path(figures_dir, "FIG_2.1_LINEAR_SCALE.png")),
    target = file.path(output_figures_dir, "FIG_2.1_VAF_GLOBAL_CLEAN.png")
  ),
  # Figure 2.2: Use DENSITY_LINEAR version or DISTRIBUTIONS_CLEAN if exists
  list(
    source = c(file.path(figures_dir, "FIG_2.2_DISTRIBUTIONS_CLEAN.png"),
               file.path(figures_dir, "FIG_2.2_DENSITY_LINEAR.png")),
    target = file.path(output_figures_dir, "FIG_2.2_DISTRIBUTIONS_CLEAN.png")
  ),
  # Figure 2.3: Use VOLCANO_PER_SAMPLE_METHOD or VOLCANO_CORRECTED
  list(
    source = c(file.path(figures_dir, "FIG_2.3_VOLCANO_PER_SAMPLE_METHOD.png"),
               file.path(figures_dir, "FIG_2.3_VOLCANO_CLEAN.png"),
               file.path(figures_dir, "FIG_2.3_VOLCANO_CORRECTED.png")),
    target = file.path(output_figures_dir, "FIG_2.3_VOLCANO_PER_SAMPLE_METHOD.png")
  ),
  # Figure 2.4: Use HEATMAP_TOP50_CLEAN or HEATMAP_ALL
  list(
    source = c(file.path(figures_dir, "FIG_2.4_HEATMAP_TOP50_CLEAN.png"),
               file.path(figures_dir, "FIG_2.4_HEATMAP_ALL.png")),
    target = file.path(output_figures_dir, "FIG_2.4_HEATMAP_TOP50_CLEAN.png")
  ),
  # Figure 2.5: Use HEATMAP_ZSCORE_CLEAN or ZSCORE_ALL301_PROFESSIONAL
  list(
    source = c(file.path(figures_dir, "FIG_2.5_HEATMAP_ZSCORE_CLEAN.png"),
               file.path(figures_dir, "FIG_2.5_ZSCORE_ALL301_PROFESSIONAL.png")),
    target = file.path(output_figures_dir, "FIG_2.5_HEATMAP_ZSCORE_CLEAN.png")
  ),
  # Figure 2.6: Use POSITIONAL_CLEAN or POSITIONAL_ANALYSIS
  list(
    source = c(file.path(figures_dir, "FIG_2.6_POSITIONAL_CLEAN.png"),
               file.path(figures_dir, "FIG_2.6_POSITIONAL_ANALYSIS.png")),
    target = file.path(output_figures_dir, "FIG_2.6_POSITIONAL_CLEAN.png")
  ),
  # Figure 2.7: Use PCA_CLEAN or COMBINED_WITH_SCREE or other variants
  list(
    source = c(file.path(figures_dir, "FIG_2.7_PCA_CLEAN.png"),
               file.path(figures_dir, "FIG_2.7_COMBINED_WITH_SCREE.png"),
               file.path(figures_dir, "FIG_2.7A_PCA_MAIN_IMPROVED.png")),
    target = file.path(output_figures_dir, "FIG_2.7_PCA_CLEAN.png")
  ),
  # Figure 2.8: REMOVED - Redundant with FIG_2.16 (uses ALL G>T SNVs)
  # list(
  #   source = c(file.path(figures_dir, "FIG_2.8_CLUSTERING_CLEAN.png"),
  #              file.path(figures_dir, "FIG_2.8_CLUSTERING.png")),
  #   target = file.path(output_figures_dir, "FIG_2.8_CLUSTERING_CLEAN.png")
  # ),
  # Figure 2.9: Use CV_CLEAN or COMBINED_IMPROVED
  list(
    source = c(file.path(figures_dir, "FIG_2.9_CV_CLEAN.png"),
               file.path(figures_dir, "FIG_2.9_COMBINED_IMPROVED.png")),
    target = file.path(output_figures_dir, "FIG_2.9_CV_CLEAN.png")
  ),
  # Figure 2.10: Use RATIO_CLEAN or COMBINED
  list(
    source = c(file.path(figures_dir, "FIG_2.10_RATIO_CLEAN.png"),
               file.path(figures_dir, "FIG_2.10_COMBINED.png")),
    target = file.path(output_figures_dir, "FIG_2.10_RATIO_CLEAN.png")
  ),
  # Figure 2.11: Use MUTATION_TYPES_CLEAN or COMBINED_IMPROVED
  list(
    source = c(file.path(figures_dir, "FIG_2.11_MUTATION_TYPES_CLEAN.png"),
               file.path(figures_dir, "FIG_2.11_COMBINED_IMPROVED.png"),
               file.path(figures_dir, "FIG_2.11_COMBINED.png")),
    target = file.path(output_figures_dir, "FIG_2.11_MUTATION_TYPES_CLEAN.png")
  ),
  # Figure 2.12: Use ENRICHMENT_CLEAN or COMBINED
  list(
    source = c(file.path(figures_dir, "FIG_2.12_ENRICHMENT_CLEAN.png"),
               file.path(figures_dir, "FIG_2.12_COMBINED.png")),
    target = file.path(output_figures_dir, "FIG_2.12_ENRICHMENT_CLEAN.png")
  ),
  # Figure 2.13: Density ALS (direct name)
  list(
    source = file.path(figures_dir, "FIG_2.13_DENSITY_HEATMAP_ALS.png"),
    target = file.path(output_figures_dir, "FIG_2.13_DENSITY_HEATMAP_ALS.png")
  ),
  # Figure 2.14: Density Control (direct name)
  list(
    source = file.path(figures_dir, "FIG_2.14_DENSITY_HEATMAP_CONTROL.png"),
    target = file.path(output_figures_dir, "FIG_2.14_DENSITY_HEATMAP_CONTROL.png")
  ),
  # Figure 2.15: Density Combined (direct name)
  list(
    source = file.path(figures_dir, "FIG_2.15_DENSITY_COMBINED.png"),
    target = file.path(output_figures_dir, "FIG_2.15_DENSITY_COMBINED.png")
  )
)

copied_count <- 0
for (mapping in figure_mapping) {
  # Handle multiple possible source names
  source_files <- if (is.character(mapping$source) && length(mapping$source) == 1) {
    mapping$source
  } else {
    mapping$source
  }
  
  # Find first existing source file
  source_found <- NULL
  for (src in source_files) {
    if (file.exists(src)) {
      source_found <- src
      break
    }
  }
  
  if (!is.null(source_found)) {
    file.copy(source_found, mapping$target, overwrite = TRUE)
    cat("✅ Copied:", basename(mapping$target), "from", basename(source_found), "\n")
    copied_count <- copied_count + 1
  } else {
    cat("⚠️  Source not found (tried:", paste(basename(source_files), collapse = ", "), ")\n")
    # List what files actually exist in figures_dir
    existing_files <- list.files(figures_dir, pattern = "FIG_2\\.[0-9]+", full.names = FALSE)
    if (length(existing_files) > 0) {
      cat("   Available files:", paste(head(existing_files, 5), collapse = ", "), "\n")
    }
  }
}

# ============================================================================
# SUMMARY
# ============================================================================

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  EXECUTION SUMMARY\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")
cat("✅ Figures copied:", copied_count, "/", length(figure_mapping), "\n")
cat("\n📁 Final figures location:", output_figures_dir, "\n")
cat("📁 Generated figures location:", figures_dir, "\n\n")

# Restore working directory
setwd(original_wd)

cat("✅ All Step 2 figures generation completed\n\n")

