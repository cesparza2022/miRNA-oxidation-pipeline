#!/usr/bin/env Rscript
# ============================================================================
# STEP 7: Biomarker Signature Heatmap (Part of Final Integration)
# ============================================================================
# Purpose: Create comprehensive heatmap showing biomarker signatures.
#          Part of Step 7 which runs LAST, after Step 3, integrating all analyses.
#
# This figure shows:
# 1. Heatmap of top biomarkers across samples
# 2. Sample clustering (disease vs control)
# 3. Biomarker performance metrics
# 4. Combined signature visualization
#
# Snakemake parameters:
#   input: ROC results from Step 7.1 and VAF-filtered data
#   output: Comprehensive biomarker heatmap
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
  library(readr)
  library(pheatmap)
  library(RColorBrewer)
  library(stringr)
})

# Load common functions
source(snakemake@params[["functions"]], local = TRUE)

# Load group comparison utilities for dynamic group detection
group_functions_path <- if (!is.null(snakemake@params[["group_functions"]])) {
  snakemake@params[["group_functions"]]
} else {
  "scripts/utils/group_comparison.R"
}

if (file.exists(group_functions_path)) {
  source(group_functions_path, local = TRUE)
}

# Initialize logging
log_file <- if (length(snakemake@log) > 0) snakemake@log[[1]] else {
  file.path(dirname(snakemake@output[[1]]), "biomarker_signature_heatmap.log")
}
initialize_logging(log_file, context = "Step 7.2 - Biomarker Signature Heatmap")

log_section("STEP 7: Biomarker Signature Heatmap (Part of Final Integration)")

# ============================================================================
# GET SNAKEMAKE PARAMETERS
# ============================================================================

input_roc <- snakemake@input[["roc_table"]]
input_vaf_filtered <- snakemake@input[["vaf_filtered"]]
output_heatmap <- snakemake@output[["heatmap"]]

config <- snakemake@config
color_gt <- if (!is.null(config$analysis$colors$gt)) config$analysis$colors$gt else "#D62728"
color_control <- if (!is.null(config$analysis$colors$control)) config$analysis$colors$control else "grey60"
seed_start <- if (!is.null(config$analysis$seed_region$start)) config$analysis$seed_region$start else 2
seed_end <- if (!is.null(config$analysis$seed_region$end)) config$analysis$seed_region$end else 8

log_info(paste("Input ROC:", input_roc))
log_info(paste("Input VAF filtered:", input_vaf_filtered))
ensure_output_dir(dirname(output_heatmap))

# ============================================================================
# LOAD DATA
# ============================================================================

log_subsection("Loading data")

# Validate file existence before reading
if (!file.exists(input_roc)) {
  handle_error(
    paste("ROC table file not found:", input_roc),
    context = "Step 7.2 - Data Loading",
    exit_code = 1,
    log_file = log_file
  )
}
if (!file.exists(input_vaf_filtered)) {
  handle_error(
    paste("VAF filtered data file not found:", input_vaf_filtered),
    context = "Step 7.2 - Data Loading",
    exit_code = 1,
    log_file = log_file
  )
}

roc_table <- tryCatch({
  result <- read_csv(input_roc, show_col_types = FALSE)
  log_success(paste("Loaded ROC table:", nrow(result), "biomarkers"))
  result
}, error = function(e) {
  handle_error(e, context = "Step 7.2 - Loading ROC table", exit_code = 1, log_file = log_file)
})

vaf_data <- tryCatch({
  result <- read_csv(input_vaf_filtered, show_col_types = FALSE)
  log_success(paste("Loaded VAF filtered data:", nrow(result), "SNVs"))
  result
}, error = function(e) {
  handle_error(e, context = "Step 7.2 - Loading VAF data", exit_code = 1, log_file = log_file)
})

# Normalize column names (handle different formats)
if ("miRNA name" %in% names(vaf_data)) {
  vaf_data <- vaf_data %>% rename(miRNA_name = `miRNA name`)
}
if ("pos:mut" %in% names(vaf_data)) {
  vaf_data <- vaf_data %>% rename(pos.mut = `pos:mut`)
}

# Extract sample groups
sample_cols <- setdiff(names(vaf_data), c("miRNA_name", "pos.mut", "miRNA name", "pos:mut"))
# Get metadata file path from Snakemake params if available
metadata_file <- if (!is.null(snakemake@params[["metadata_file"]])) {
  metadata_path <- snakemake@params[["metadata_file"]]
  if (metadata_path != "" && file.exists(metadata_path)) {
    log_info(paste("Using metadata file:", metadata_path))
    metadata_path
  } else {
    NULL
  }
} else {
  NULL
}

# Use flexible group extraction
sample_groups <- tryCatch({
  extract_sample_groups(vaf_data, metadata_file = metadata_file)
}, error = function(e) {
  handle_error(e, context = "Step 7.2 - Group Identification", exit_code = 1, log_file = log_file)
})

# Get dynamic group names
unique_groups <- sort(unique(sample_groups$group))
if (length(unique_groups) < 2) {
  stop("Need at least 2 groups for heatmap. Found:", paste(unique_groups, collapse = ", "))
}

group1_name <- unique_groups[1]
group2_name <- unique_groups[2]

# Select top 20 biomarkers for heatmap visualization
# Exclude combined signature from individual biomarker list
top_biomarkers <- roc_table %>%
  filter(SNV_id != "COMBINED_SIGNATURE") %>%  # Exclude combined signature
  arrange(desc(AUC)) %>%
  head(min(20, nrow(roc_table)))

log_info(paste("Top biomarkers selected:", nrow(top_biomarkers)))
if (nrow(top_biomarkers) > 0) {
  log_info(paste("AUC range:", round(min(top_biomarkers$AUC), 3), "-", round(max(top_biomarkers$AUC), 3)))
}

# ============================================================================
# PREPARE HEATMAP DATA
# ============================================================================

log_subsection("Preparing heatmap data")

# Extract data for top biomarkers
heatmap_matrix_list <- list()

for (i in seq_len(nrow(top_biomarkers))) {
  snv_id <- top_biomarkers$SNV_id[i]
  mirna <- top_biomarkers$miRNA_name[i]
  pos_mut <- top_biomarkers$pos.mut[i]
  
  # Handle cases where pos.mut contains multiple mutations (e.g., "6:TC,13:GT")
  # For now, use the first mutation or try to match exactly
  if (str_detect(pos_mut, ",")) {
    pos_mut_clean <- str_split(pos_mut, ",")[[1]][1]  # Take first mutation if multiple
  } else {
    pos_mut_clean <- pos_mut
  }
  
  # Try exact match first
  snv_data <- vaf_data %>%
    filter(miRNA_name == mirna & pos.mut == pos_mut) %>%
    select(all_of(sample_cols))
  
  # If no exact match, try with first mutation only
  if (nrow(snv_data) == 0 && pos_mut != pos_mut_clean) {
    snv_data <- vaf_data %>%
      filter(miRNA_name == mirna & pos.mut == pos_mut_clean) %>%
      select(all_of(sample_cols))
  }
  
  if (nrow(snv_data) > 0) {
    # Extract values for this SNV across all samples
    values <- tryCatch({
      as.numeric(snv_data[1, sample_cols, drop = TRUE])
    }, error = function(e) {
      log_warning(paste("Error extracting values for", mirna, pos_mut, ":", e$message))
      NULL
    })
    
        if (!is.null(values) && length(values) == length(sample_cols) && !all(is.na(values))) {
          names(values) <- sample_cols
          # Use clean label for row name (replace : with - for valid R names)
          # ALWAYS include index to ensure uniqueness from the start
          row_name_base <- paste0(mirna, "_", gsub(":", "-", pos_mut_clean))
          # Always append index to ensure uniqueness (even if not strictly needed)
          row_name <- paste0(row_name_base, "_idx", i)
          heatmap_matrix_list[[row_name]] <- values
          log_info(paste("  Added biomarker:", row_name))
        } else {
          log_warning(paste("  Skipping", mirna, pos_mut, "- invalid values"))
        }
  } else {
    log_warning(paste("  No data found for biomarker:", mirna, pos_mut))
  }
}

log_info(paste("Total biomarkers in heatmap matrix:", length(heatmap_matrix_list)))

# Combine into matrix
if (length(heatmap_matrix_list) > 0) {
  # CRITICAL FIX: Ensure all list names are unique before converting to tibble
  names(heatmap_matrix_list) <- make.unique(names(heatmap_matrix_list), sep = "_")
  
  # Convert list to data frame
  # Each list element is a named vector (sample_cols as names)
  # We want: rows = samples, columns = biomarkers
  # as_tibble will create columns from list elements, rows from vector positions
  heatmap_df <- tryCatch({
    # Ensure all vectors have the same length
    all_lengths <- sapply(heatmap_matrix_list, length)
    if (length(unique(all_lengths)) > 1) {
      log_warning(paste("Biomarker vectors have different lengths:", paste(unique(all_lengths), collapse = ", ")))
      # Use minimum length
      min_length <- min(all_lengths)
      heatmap_matrix_list <- lapply(heatmap_matrix_list, function(x) x[1:min_length])
      # Re-apply unique names after subsetting
      names(heatmap_matrix_list) <- make.unique(names(heatmap_matrix_list), sep = "_")
    }
    
    # Convert list to data frame
    # as_tibble creates columns from list elements, rows from vector positions
    result <- as_tibble(heatmap_matrix_list)
    
    # CRITICAL: Ensure column names are unique (as_tibble may have created duplicates)
    names(result) <- make.unique(names(result), sep = "_")
    
    # Add sample_id column from the names of the first vector
    if (length(heatmap_matrix_list) > 0 && length(names(heatmap_matrix_list[[1]])) > 0) {
      result$sample_id <- names(heatmap_matrix_list[[1]])
    } else if (nrow(result) > 0) {
      result$sample_id <- sample_cols[seq_len(nrow(result))]
    }
    
    result <- result %>%
      left_join(sample_groups, by = "sample_id") %>%
      filter(!is.na(group)) %>%  # Remove samples without group assignment
      arrange(group)  # Sort by group
    
    log_info(paste("Heatmap data frame created:", nrow(result), "samples,", ncol(result) - 2, "biomarkers"))
    log_info(paste("Will aggregate by group to show mean VAF per group (much more interpretable)"))
    result
  }, error = function(e) {
    log_error(paste("Error creating heatmap data frame:", e$message))
    stop(paste("Failed to create heatmap data frame:", e$message))
  })
  
  # Remove samples with too many NAs (if any biomarker columns exist)
  biomarker_cols <- setdiff(names(heatmap_df), c("sample_id", "group"))
  
  # Ensure biomarker column names are unique (critical fix for duplicate row names)
  if (length(biomarker_cols) > 0) {
    biomarker_cols <- make.unique(biomarker_cols, sep = "_")
    # Update column names in heatmap_df to match
    names(heatmap_df)[names(heatmap_df) %in% setdiff(names(heatmap_df), c("sample_id", "group"))] <- biomarker_cols
  }
  
  if (length(biomarker_cols) > 0) {
    heatmap_df <- heatmap_df %>%
      filter(rowSums(is.na(select(., all_of(biomarker_cols)))) / length(biomarker_cols) < 0.5)
  }
  
  # Prepare matrix (transpose for pheatmap: rows = biomarkers, cols = samples)
  if (length(biomarker_cols) > 0 && nrow(heatmap_df) > 0) {
    # ============================================================================
    # IMPROVED: Group samples by group and calculate mean VAF per group
    # This makes the heatmap much more interpretable
    # ============================================================================
    
    # Calculate mean VAF per group for each biomarker
    heatmap_by_group <- heatmap_df %>%
      group_by(group) %>%
      summarise(
        across(all_of(biomarker_cols), ~ mean(.x, na.rm = TRUE)),
        .groups = "drop"
      ) %>%
      column_to_rownames("group")
    
    # Transpose: rows = biomarkers, columns = groups (ALS, Control)
    heatmap_matrix <- t(as.matrix(heatmap_by_group))
    
    # Ensure row names are unique (critical to avoid duplicate row names error)
    rownames(heatmap_matrix) <- make.unique(rownames(heatmap_matrix), sep = "_")
    
    # Use VAF values directly (not z-score) for interpretability
    # Log2 transform to handle wide range of values
    heatmap_matrix_norm <- log2(heatmap_matrix + 1e-6)  # Add small value to avoid log(0)
    heatmap_matrix_norm[is.na(heatmap_matrix_norm)] <- 0  # Replace NA with 0
    
    # Annotation for groups (columns now represent groups, not individual samples)
    # No longer needed since we have only 2 columns (groups)
    sample_annotation <- NULL
    
    # Create annotation for biomarkers (AUC values)
    biomarker_labels <- rownames(heatmap_matrix_norm)
    
    # Create biomarker annotation matching the row names
    # First, create a mapping from the biomarker labels (which may have duplicates handled)
    # to the original top_biomarkers data
    biomarker_label_map <- tibble(
      Biomarker = biomarker_labels,
      index = seq_along(biomarker_labels)
    ) %>%
      mutate(
        # Extract base name (before any _index suffix)
        base_name = str_replace(Biomarker, "_\\d+$", ""),
        # Extract miRNA and position from base name
        miRNA_from_label = str_extract(base_name, "^[^_]+"),
        pos_from_label = str_extract(base_name, "(?<=_)[^-]+$")
      )
    
    # Create improved biomarker annotation with AUC values
    # Match biomarker labels from matrix to top_biomarkers data
    biomarker_annotation <- tibble(
      Biomarker = rownames(heatmap_matrix_norm)
    ) %>%
      mutate(
        # Extract miRNA name and position from biomarker label
        base_name = str_replace(Biomarker, "_\\d+$", ""),  # Remove _index suffix if exists
        miRNA_from_label = str_extract(base_name, "^[^_]+"),
        pos_from_label = str_extract(base_name, "(?<=_)[^-]+$")
      ) %>%
      # Join with top_biomarkers to get AUC
      left_join(
        top_biomarkers %>%
          mutate(
            pos_mut_clean = ifelse(str_detect(pos.mut, ","), 
                                   str_split(pos.mut, ",", simplify = TRUE)[1,1], 
                                   pos.mut),
            base_name_match = paste0(miRNA_name, "_", gsub(":", "-", pos_mut_clean))
          ),
        by = c("base_name" = "base_name_match")
      ) %>%
      mutate(
        # Create improved label with AUC
        Label = ifelse(!is.na(AUC), 
                      paste0(miRNA_name, " (pos ", gsub("-", ":", pos_mut_clean), ") - AUC=", round(AUC, 3)),
                      Biomarker),
        AUC_category = case_when(
          AUC >= 0.9 ~ "Excellent",
          AUC >= 0.8 ~ "Good",
          AUC >= 0.7 ~ "Fair",
          !is.na(AUC) ~ "Poor",
          TRUE ~ "Unknown"
        ),
        AUC_value = ifelse(is.na(AUC), 0, AUC)
      ) %>%
      select(Biomarker, Label, AUC_value, AUC_category) %>%
      column_to_rownames("Biomarker")
    
    # Update row names to include AUC for better readability
    # Make sure labels are unique (some biomarkers might have duplicates)
    unique_labels <- make.unique(biomarker_annotation$Label, sep = "_")
    rownames(heatmap_matrix_norm) <- unique_labels
    rownames(biomarker_annotation) <- unique_labels
    
    # Update biomarker annotation row names to match updated matrix row names
    if (nrow(biomarker_annotation) > 0 && nrow(heatmap_matrix_norm) > 0) {
      # Row names should already match (we just updated them)
      # But ensure biomarker_annotation has the same row names
      matching_rows <- intersect(rownames(heatmap_matrix_norm), rownames(biomarker_annotation))
      if (length(matching_rows) == nrow(heatmap_matrix_norm)) {
        biomarker_annotation <- biomarker_annotation[matching_rows, , drop = FALSE]
      } else {
        log_warning("Row name mismatch - creating minimal annotation")
        biomarker_annotation <- data.frame(
          AUC_category = rep("Poor", nrow(heatmap_matrix_norm)),
          row.names = rownames(heatmap_matrix_norm)
        )
      }
    }
    
    # Color schemes (move inside the if block)
    # Dynamic group colors
    group_colors <- setNames(c(color_gt, color_control), c(group1_name, group2_name))
    # For backward compatibility, also include ALS/Control if they exist
    if ("ALS" %in% unique_groups) {
      group_colors <- c(group_colors, "ALS" = color_gt)
    }
    if ("Control" %in% unique_groups) {
      group_colors <- c(group_colors, "Control" = color_control)
    }
    auc_colors <- colorRampPalette(c("white", color_gt))(100)
  
    # ============================================================================
    # GENERATE HEATMAP
    # ============================================================================
    
    log_subsection("Generating comprehensive heatmap")
    
    if (nrow(heatmap_matrix_norm) > 0 && ncol(heatmap_matrix_norm) > 0) {
      png(output_heatmap, width = 14, height = 12, units = "in", res = 300)
      
      # Determine if clustering is possible (need at least 2 rows)
      can_cluster_rows <- nrow(heatmap_matrix_norm) >= 2
      # Don't cluster columns (only 2 groups: Control and ALS)
      can_cluster_cols <- FALSE
      
      # Create improved annotation for biomarkers (AUC category)
      if (nrow(biomarker_annotation) > 0 && "AUC_category" %in% names(biomarker_annotation)) {
        # Ensure AUC_category is a factor with all possible levels
        auc_levels <- c("Excellent", "Good", "Fair", "Poor", "Unknown")
        biomarker_annotation$AUC_category <- factor(
          biomarker_annotation$AUC_category,
          levels = auc_levels
        )
        annotation_row_data <- biomarker_annotation %>% select(AUC_category)
      } else {
        annotation_row_data <- NULL
      }
      
      # Improved color scheme: blue-white-red for log2(VAF)
      # Blue = lower VAF, Red = higher VAF
      vaf_range <- range(heatmap_matrix_norm, na.rm = TRUE, finite = TRUE)
      col_fun <- colorRampPalette(c("#2E86AB", "white", color_gt))(100)
      
      # Calculate actual VAF range for legend (convert back from log2)
      vaf_actual_min <- round(2^vaf_range[1], 4)
      vaf_actual_max <- round(2^vaf_range[2], 4)
      vaf_actual_mid <- round(2^0, 4)  # log2(1) = 0 means VAF = 1
      
      # Check if we should show AUC categories or just AUC values
      # If all biomarkers are "Poor" (AUC < 0.7), show AUC values directly instead
      unique_categories <- unique(biomarker_annotation$AUC_category)
      if (length(unique_categories) == 1 && unique_categories == "Poor") {
        # All are Poor - show AUC values as annotation instead
        log_info("All biomarkers are 'Poor' category - showing AUC values directly in annotation")
        biomarker_annotation$AUC_annotation <- paste0("AUC=", round(biomarker_annotation$AUC_value, 3))
        annotation_row_data <- biomarker_annotation %>% select(AUC_annotation)
        annotation_colors <- NULL  # No color coding for AUC values
      } else {
        # Multiple categories - use color coding
        auc_category_colors <- c(
          "Excellent" = "#D62728",
          "Good" = "#FF7F0E",
          "Fair" = "#2CA02C",
          "Poor" = "grey70",
          "Unknown" = "grey90"
        )
        annotation_row_data <- biomarker_annotation %>% select(AUC_category)
        annotation_colors <- list(
          AUC_category = auc_category_colors[names(auc_category_colors) %in% levels(biomarker_annotation$AUC_category)]
        )
      }
      
      # Create comprehensive title
      title_text <- paste0(
        "Biomarker Signature Heatmap: Mean VAF Comparison\n",
        "Top 20 G>T Oxidation Biomarkers | Seed Region (pos ", seed_start, "-", seed_end, ")\n",
        "Rows: miRNAs with mutations | Columns: Mean VAF per group"
      )
      
      # Create subtitle explaining the color scale
      subtitle_text <- paste0(
        "Color scale: log2(VAF) | Blue = Low VAF (", vaf_actual_min, ") | Red = High VAF (", vaf_actual_max, ") | ",
        "Numbers in cells = log2(VAF) values"
      )
      
      pheatmap(
        heatmap_matrix_norm,
        color = col_fun,
        cluster_rows = can_cluster_rows,
        cluster_cols = can_cluster_cols,
        show_colnames = TRUE,  # Show group names (Control, ALS)
        show_rownames = TRUE,
        annotation_row = annotation_row_data,
        annotation_colors = annotation_colors,
        main = title_text,
        fontsize = 10,
        fontsize_row = 7,
        fontsize_col = 11,
        angle_col = 0,  # Horizontal labels for groups
        border_color = "grey60",
        gaps_col = NULL,  # No gap needed (only 2 columns)
        legend = TRUE,
        legend_breaks = c(vaf_range[1], 0, vaf_range[2]),
        legend_labels = c(
          paste0("Low (log2=", round(vaf_range[1], 2), ", VAF=", vaf_actual_min, ")"),
          paste0("Mid (log2=0, VAF=1.0)"),
          paste0("High (log2=", round(vaf_range[2], 2), ", VAF=", vaf_actual_max, ")")
        ),
        display_numbers = TRUE,  # Show actual values for clarity
        number_format = "%.2f",
        number_color = ifelse(abs(heatmap_matrix_norm) > 1, "white", "black"),
        treeheight_row = 50,
        treeheight_col = 0  # No column dendrogram (only 2 groups)
      )
      
      dev.off()
      
      # Validate output file was created
      validate_output_file(output_heatmap, min_size_bytes = 5000, context = "Step 7.2 - Heatmap")
      
      log_success(paste("Heatmap saved:", output_heatmap))
    } else {
      log_warning("Insufficient data for heatmap generation")
      png(output_heatmap, width = 10, height = 8, units = "in", res = 300)
      plot.new()
      text(0.5, 0.5, "Insufficient biomarkers for heatmap", cex = 1.5)
      dev.off()
      validate_output_file(output_heatmap, min_size_bytes = 1000, context = "Step 7.2 - Placeholder heatmap")
    }
  } else {
    log_warning("No biomarker columns found for heatmap")
    # Create empty placeholder
    png(output_heatmap, width = 10, height = 8, units = "in", res = 300)
    plot.new()
    text(0.5, 0.5, "No biomarker columns found", cex = 1.5)
    dev.off()
    validate_output_file(output_heatmap, min_size_bytes = 1000, context = "Step 7.2 - Placeholder heatmap")
  }
} else {
  log_warning("No biomarkers found for heatmap")
  # Create empty placeholder
  png(output_heatmap, width = 10, height = 8, units = "in", res = 300)
  plot.new()
  text(0.5, 0.5, "No biomarkers found", cex = 1.5)
  dev.off()
  validate_output_file(output_heatmap, min_size_bytes = 1000, context = "Step 7.2 - Placeholder heatmap")
}

log_success("Step 7.2 completed successfully")

