#!/usr/bin/env Rscript
# ============================================================================
# CLEAN RESULTS DIRECTORY
# ============================================================================
# Script to clean results/ directory by moving non-pipeline files to archive
#
# USAGE:
#   Rscript scripts/utils/clean_results_directory.R [--dry-run] [--archive-dir=path]
#
# OPTIONS:
#   --dry-run: Show what would be moved without actually moving files
#   --archive-dir: Directory to move files to (default: results_archive/)
# ============================================================================

# Parse command line arguments
args <- commandArgs(trailingOnly = TRUE)
dry_run <- "--dry-run" %in% args
archive_dir_arg <- grep("--archive-dir=", args, value = TRUE)
archive_dir <- if (length(archive_dir_arg) > 0) {
  gsub("--archive-dir=", "", archive_dir_arg[1])
} else {
  "../results_archive"  # Relative to snakemake_pipeline/
}

# Get script directory and set working directory
# Try to get script location from commandArgs
script_args <- commandArgs(trailingOnly = FALSE)
script_path <- grep("^--file=", script_args, value = TRUE)
if (length(script_path) > 0) {
  script_dir <- dirname(gsub("^--file=", "", script_path))
} else {
  # Fallback: assume we're in snakemake_pipeline/scripts/utils/
  script_dir <- file.path(getwd(), "scripts", "utils")
  if (!dir.exists(script_dir)) {
    # Try to find from current working directory
    if (basename(getwd()) == "snakemake_pipeline") {
      script_dir <- file.path(getwd(), "scripts", "utils")
    } else {
      script_dir <- getwd()
    }
  }
}

# Determine snakemake_dir
if (basename(getwd()) == "snakemake_pipeline") {
  snakemake_dir <- getwd()
} else {
  # Try to find snakemake_pipeline directory
  current_dir <- getwd()
  if (grepl("snakemake_pipeline", current_dir)) {
    snakemake_dir <- file.path(dirname(current_dir), "snakemake_pipeline")
    if (!dir.exists(snakemake_dir)) {
      snakemake_dir <- current_dir
    }
  } else {
    snakemake_dir <- current_dir
  }
}

results_dir <- file.path(snakemake_dir, "results")

# Define legitimate pipeline directories/files
legitimate_dirs <- c(
  "step1", "step1_5", "step2", "step3", "step4", "step5", "step6", "step7",
  "pipeline_info", "summary", "validation"
)

legitimate_files <- c(
  "INDEX.md", "README.md"  # These should stay in results/
)

cat("═══════════════════════════════════════════════════════════\n")
cat("🧹 CLEANING RESULTS DIRECTORY\n")
cat("═══════════════════════════════════════════════════════════\n\n")
cat(sprintf("Results directory: %s\n", results_dir))
cat(sprintf("Archive directory: %s\n", archive_dir))
cat(sprintf("Mode: %s\n\n", if (dry_run) "DRY RUN" else "MOVE"))

# Check if results directory exists
if (!dir.exists(results_dir)) {
  cat("❌ Results directory does not exist!\n")
  quit(status = 1)
}

# Create archive directory if not in dry-run mode
if (!dry_run && !dir.exists(archive_dir)) {
  dir.create(archive_dir, recursive = TRUE, showWarnings = FALSE)
  cat(sprintf("✅ Created archive directory: %s\n\n", archive_dir))
}

# Get all items in results directory
all_items <- list.files(results_dir, full.names = TRUE, all.files = FALSE)
all_basenames <- basename(all_items)

# Identify items to move
items_to_move <- character(0)
items_to_keep <- character(0)

for (item in all_items) {
  basename_item <- basename(item)
  
  # Check if it's a legitimate directory
  if (dir.exists(item) && basename_item %in% legitimate_dirs) {
    items_to_keep <- c(items_to_keep, item)
    next
  }
  
  # Check if it's a legitimate file
  if (file.exists(item) && basename_item %in% legitimate_files) {
    items_to_keep <- c(items_to_keep, item)
    next
  }
  
  # Everything else should be moved
  items_to_move <- c(items_to_move, item)
}

# Report findings
cat("📊 ANALYSIS RESULTS:\n")
cat(sprintf("   Total items in results/: %d\n", length(all_items)))
cat(sprintf("   Items to keep: %d\n", length(items_to_keep)))
cat(sprintf("   Items to move: %d\n\n", length(items_to_move)))

if (length(items_to_keep) > 0) {
  cat("✅ LEGITIMATE ITEMS (keeping):\n")
  for (item in items_to_keep) {
    cat(sprintf("   - %s\n", basename(item)))
  }
  cat("\n")
}

if (length(items_to_move) > 0) {
  cat("📦 ITEMS TO MOVE TO ARCHIVE:\n")
  for (item in items_to_move) {
    cat(sprintf("   - %s\n", basename(item)))
  }
  cat("\n")
  
  # Move files
  if (!dry_run) {
    cat("🚀 Moving files...\n")
    moved_count <- 0
    failed_count <- 0
    
    for (item in items_to_move) {
      basename_item <- basename(item)
      dest_path <- file.path(archive_dir, basename_item)
      
      # Handle name conflicts
      if (file.exists(dest_path) || dir.exists(dest_path)) {
        timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
        basename_item <- paste0(basename_item, "_", timestamp)
        dest_path <- file.path(archive_dir, basename_item)
      }
      
      tryCatch({
        file.rename(item, dest_path)
        cat(sprintf("   ✅ Moved: %s -> %s\n", basename(item), basename_item))
        moved_count <- moved_count + 1
      }, error = function(e) {
        cat(sprintf("   ❌ Failed to move: %s (%s)\n", basename(item), e$message))
        failed_count <- failed_count + 1
      })
    }
    
    cat(sprintf("\n✅ Move complete: %d moved, %d failed\n", moved_count, failed_count))
  } else {
    cat("⚠️  DRY RUN MODE - No files were moved\n")
  }
} else {
  cat("✅ No files to move - results/ is already clean!\n")
}

cat("\n✅ Cleanup complete!\n")

