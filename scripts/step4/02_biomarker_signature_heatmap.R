#!/usr/bin/env Rscript
# ============================================================================
# STEP 4.2: Biomarker Signature Heatmap
# ============================================================================
# Purpose: Create comprehensive heatmap showing biomarker signatures
# 
# This figure shows:
# 1. Heatmap of top biomarkers across samples
# 2. Sample clustering (ALS vs Control)
# 3. Biomarker performance metrics
# 4. Combined signature visualization
#
# Snakemake parameters:
#   input: ROC results and VAF-filtered data
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
initialize_logging(log_file, context = "Step 4.2 - Biomarker Signature Heatmap")

log_section("STEP 4.2: Biomarker Signature Heatmap")

# ============================================================================
# GET SNAKEMAKE PARAMETERS
# ============================================================================

input_roc <- snakemake@input[["roc_table"]]
input_vaf_filtered <- snakemake@input[["vaf_filtered"]]
output_heatmap <- snakemake@output[["heatmap"]]

config <- snakemake@config
color_gt <- if (!is.null(config$analysis$colors$gt)) config$analysis$colors$gt else "#D62728"
color_control <- if (!is.null(config$analysis$colors$control)) config$analysis$colors$control else "grey60"

log_info(paste("Input ROC:", input_roc))
log_info(paste("Input VAF filtered:", input_vaf_filtered))
ensure_output_dir(dirname(output_heatmap))

# ============================================================================
# LOAD DATA
# ============================================================================

log_subsection("Loading data")

roc_table <- read_csv(input_roc, show_col_types = FALSE)
vaf_data <- read_csv(input_vaf_filtered, show_col_types = FALSE)

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
  handle_error(e, context = "Step 4.2 - Group Identification", exit_code = 1, log_file = log_file)
})

# Get dynamic group names
unique_groups <- sort(unique(sample_groups$group))
if (length(unique_groups) < 2) {
  stop("Need at least 2 groups for heatmap. Found:", paste(unique_groups, collapse = ", "))
}

group1_name <- unique_groups[1]
group2_name <- unique_groups[2]

# Select top 15 biomarkers (or all if AUC < 0.7)
# Since AUCs are low, we'll use top performers regardless of threshold
top_biomarkers <- roc_table %>%
  arrange(desc(AUC)) %>%
  head(min(15, nrow(roc_table)))

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
          # Make it unique by including SNV_id if available, or index
          row_name_base <- paste0(mirna, "_", gsub(":", "-", pos_mut_clean))
          # Check if this row_name already exists, if so, append index
          if (row_name_base %in% names(heatmap_matrix_list)) {
            row_name <- paste0(row_name_base, "_", i)  # Make unique with index
          } else {
            row_name <- row_name_base
          }
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
    }
    
    # Convert list to data frame
    # as_tibble creates columns from list elements, rows from vector positions
    result <- as_tibble(heatmap_matrix_list)
    
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
    result
  }, error = function(e) {
    log_error(paste("Error creating heatmap data frame:", e$message))
    stop(paste("Failed to create heatmap data frame:", e$message))
  })
  
  # Remove samples with too many NAs (if any biomarker columns exist)
  biomarker_cols <- setdiff(names(heatmap_df), c("sample_id", "group"))
  if (length(biomarker_cols) > 0) {
    heatmap_df <- heatmap_df %>%
      filter(rowSums(is.na(select(., all_of(biomarker_cols)))) / length(biomarker_cols) < 0.5)
  }
  
  # Prepare matrix (transpose for pheatmap: rows = biomarkers, cols = samples)
  if (length(biomarker_cols) > 0 && nrow(heatmap_df) > 0) {
    heatmap_matrix <- heatmap_df %>%
      select(all_of(biomarker_cols)) %>%
      t() %>%
      as.matrix()
    
    colnames(heatmap_matrix) <- heatmap_df$sample_id
  
    # Normalize by row (z-score)
    heatmap_matrix_norm <- t(scale(t(heatmap_matrix)))
    heatmap_matrix_norm[is.na(heatmap_matrix_norm)] <- 0  # Replace NA with 0 after scaling
    
    # Create annotation for samples
    sample_annotation <- heatmap_df %>%
      select(sample_id, Group = group) %>%
      column_to_rownames("sample_id")
    
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
    
    biomarker_annotation <- top_biomarkers %>%
      mutate(
        pos_mut_clean = ifelse(str_detect(pos.mut, ","), 
                               str_split(pos.mut, ",", simplify = TRUE)[1,1], 
                               pos.mut),
        base_name = paste0(miRNA_name, "_", gsub(":", "-", pos_mut_clean)),
        Biomarker = base_name,
        AUC_category = case_when(
          AUC >= 0.9 ~ "Excellent",
          AUC >= 0.8 ~ "Good",
          AUC >= 0.7 ~ "Fair",
          TRUE ~ "Poor"
        ),
        index = row_number()
      ) %>%
      # Match by base_name or by index if needed
      left_join(biomarker_label_map, by = c("base_name" = "base_name"), suffix = c("", "_label")) %>%
      # If no match, try by index
      mutate(
        match_index = ifelse(is.na(index_label), index, index_label),
        Biomarker_final = ifelse(Biomarker %in% biomarker_labels, 
                                Biomarker, 
                                paste0(Biomarker, "_", index))
      ) %>%
      # Filter to only those that match biomarker_labels
      filter(Biomarker_final %in% biomarker_labels | Biomarker %in% biomarker_labels) %>%
      # Use the actual biomarker label from the matrix
      mutate(Biomarker_final = ifelse(Biomarker_final %in% biomarker_labels, 
                                     Biomarker_final,
                                     Biomarker)) %>%
      select(Biomarker = Biomarker_final, AUC, AUC_category) %>%
      # Remove duplicates by taking first occurrence
      distinct(Biomarker, .keep_all = TRUE) %>%
      column_to_rownames("Biomarker")
    
    # Ensure row names match
    if (nrow(biomarker_annotation) > 0 && nrow(heatmap_matrix_norm) > 0) {
      # Match and reorder
      matching_rows <- intersect(rownames(heatmap_matrix_norm), rownames(biomarker_annotation))
      if (length(matching_rows) > 0) {
        heatmap_matrix_norm <- heatmap_matrix_norm[matching_rows, , drop = FALSE]
        biomarker_annotation <- biomarker_annotation[matching_rows, , drop = FALSE]
      } else {
        log_warning("No matching rows between heatmap matrix and biomarker annotation")
        # Create minimal annotation if no matches
        biomarker_annotation <- data.frame(
          AUC_category = rep("Poor", nrow(heatmap_matrix_norm)),
          row.names = rownames(heatmap_matrix_norm)
        )
      }
    } else {
      log_warning("Empty biomarker annotation or heatmap matrix")
      # Create minimal annotation
      if (nrow(heatmap_matrix_norm) > 0) {
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
    
    if (nrow(heatmap_matrix_norm) > 0 && ncol(heatmap_matrix_norm) > 0 && nrow(biomarker_annotation) > 0) {
      png(output_heatmap, width = 16, height = 12, units = "in", res = 300)
      
      # Calculate gap position (between groups)
      n_group2 <- sum(sample_annotation$Group == group2_name)
      gap_pos <- if (n_group2 > 0 && n_group2 < nrow(sample_annotation)) n_group2 else NULL
      
      pheatmap(
        heatmap_matrix_norm,
        color = colorRampPalette(c("#2E86AB", "white", color_gt))(100),
        cluster_rows = TRUE,
        cluster_cols = TRUE,
        show_colnames = FALSE,
        show_rownames = TRUE,
        annotation_col = sample_annotation,
        annotation_row = biomarker_annotation %>% select(AUC_category),
        annotation_colors = list(
          Group = group_colors,
          AUC_category = c("Excellent" = "#D62728", "Good" = "#FF7F0E", "Fair" = "#2CA02C", "Poor" = "grey70")
        ),
        main = "Biomarker Signature Heatmap\nTop Performing miRNA Oxidation Patterns",
        fontsize = 10,
        fontsize_row = 9,
        fontsize_col = 6,
        angle_col = 90,
        border_color = "grey60",
        gaps_col = gap_pos,  # Gap between groups
        legend = TRUE,
        legend_breaks = c(min(heatmap_matrix_norm, na.rm = TRUE), 
                         0, 
                         max(heatmap_matrix_norm, na.rm = TRUE)),
        legend_labels = c("Low", "0 (mean)", "High"),
        display_numbers = FALSE,
        treeheight_row = 50,
        treeheight_col = 50
      )
      
      dev.off()
      
      log_success(paste("Heatmap saved:", output_heatmap))
    } else {
      log_warning("Insufficient data for heatmap generation")
      png(output_heatmap, width = 10, height = 8, units = "in", res = 300)
      plot.new()
      text(0.5, 0.5, "Insufficient biomarkers for heatmap", cex = 1.5)
      dev.off()
    }
  } else {
    log_warning("No biomarker columns found for heatmap")
    # Create empty placeholder
    png(output_heatmap, width = 10, height = 8, units = "in", res = 300)
    plot.new()
    text(0.5, 0.5, "No biomarker columns found", cex = 1.5)
    dev.off()
  }
} else {
  log_warning("No biomarkers found for heatmap")
  # Create empty placeholder
  png(output_heatmap, width = 10, height = 8, units = "in", res = 300)
  plot.new()
  text(0.5, 0.5, "No biomarkers found", cex = 1.5)
  dev.off()
}

log_success("Step 4.2 completed successfully")

