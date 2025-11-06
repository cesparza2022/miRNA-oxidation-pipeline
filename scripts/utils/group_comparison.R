# ============================================================================
# GROUP COMPARISON UTILITIES
# ============================================================================
# Flexible system for identifying sample groups:
# 1. Priority: Load from metadata file (if provided)
# 2. Fallback: Pattern matching on column names (for backward compatibility)
# ============================================================================

#' Load Sample Groups from Metadata File
#' 
#' Loads sample group assignments from a metadata TSV file.
#' The metadata file should have at minimum: sample_id, group
#' 
#' @param metadata_file Path to metadata TSV file
#' @param data Data frame with sample columns (for validation)
#' @return Data frame with columns: sample_id, group (and other metadata columns)
load_sample_groups_from_metadata <- function(metadata_file, data) {
  
  if (!file.exists(metadata_file)) {
    return(NULL)
  }
  
  # Load metadata
  metadata <- tryCatch({
    read_tsv(metadata_file, show_col_types = FALSE)
  }, error = function(e) {
    warning(paste("Could not read metadata file:", metadata_file, "- Error:", e$message))
    return(NULL)
  })
  
  # Validate required columns
  if (!"sample_id" %in% names(metadata)) {
    stop("Metadata file must contain 'sample_id' column")
  }
  
  if (!"group" %in% names(metadata)) {
    stop("Metadata file must contain 'group' column")
  }
  
  # Get actual sample column names from data
  metadata_cols <- c("miRNA_name", "miRNA name", "pos.mut", "pos:mut")
  sample_cols <- names(data)[!names(data) %in% metadata_cols]
  
  # Filter metadata to only samples present in data
  groups_df <- metadata %>%
    filter(sample_id %in% sample_cols) %>%
    select(sample_id, group, everything())
  
  # Check for samples in data but not in metadata
  missing_samples <- setdiff(sample_cols, groups_df$sample_id)
  if (length(missing_samples) > 0) {
    warning(paste(length(missing_samples), "samples in data but not in metadata file (will be excluded)"))
  }
  
  # Check for samples in metadata but not in data
  extra_samples <- setdiff(groups_df$sample_id, sample_cols)
  if (length(extra_samples) > 0) {
    warning(paste(length(extra_samples), "samples in metadata but not in data file (will be excluded)"))
    groups_df <- groups_df %>% filter(sample_id %in% sample_cols)
  }
  
  # Remove samples without group assignment
  n_unmatched <- sum(is.na(groups_df$group) | groups_df$group == "")
  if (n_unmatched > 0) {
    warning(paste(n_unmatched, "samples in metadata without group assignment (will be excluded)"))
    groups_df <- groups_df %>% filter(!is.na(group), group != "")
  }
  
  # Get unique groups
  unique_groups <- unique(groups_df$group)
  n_groups <- length(unique_groups)
  
  cat("📊 Sample groups loaded from metadata file:\n")
  for (grp in sort(unique_groups)) {
    n_grp <- sum(groups_df$group == grp)
    cat("   •", grp, ":", n_grp, "samples\n")
  }
  
  if (length(missing_samples) > 0) {
    cat("   ⚠️  Samples in data but not in metadata:", length(missing_samples), "\n")
  }
  
  # Validate: need at least 2 groups with samples
  if (n_groups < 2) {
    stop("Need at least 2 groups for comparison. Found:", paste(unique_groups, collapse = ", "))
  }
  
  # Validate: each group needs at least 2 samples
  for (grp in unique_groups) {
    n_grp <- sum(groups_df$group == grp)
    if (n_grp < 2) {
      stop("Each group needs at least 2 samples. Group '", grp, "' has only ", n_grp, " sample(s)")
    }
  }
  
  return(groups_df)
}

#' Extract Sample Groups from Column Names (Fallback Method)
#' 
#' Identifies groups from column names using pattern matching.
#' This is a fallback method when metadata file is not available.
#' 
#' @param data Data frame with sample columns
#' @param als_pattern Regex pattern for disease samples (default: "ALS")
#' @param control_pattern Regex pattern for control samples (default: "control|Control|CTRL")
#' @param metadata_file Path to metadata file (optional, if provided will try to load first)
#' @return Data frame with columns: sample_id, group
extract_sample_groups <- function(data, 
                                  als_pattern = "ALS", 
                                  control_pattern = "control|Control|CTRL",
                                  metadata_file = NULL) {
  
  # Priority 1: Try to load from metadata file if provided
  if (!is.null(metadata_file) && file.exists(metadata_file)) {
    groups_df <- load_sample_groups_from_metadata(metadata_file, data)
    if (!is.null(groups_df)) {
      return(groups_df)
    }
    warning("Metadata file provided but could not be loaded. Falling back to pattern matching.")
  }
  
  # Priority 2: Pattern matching (backward compatibility)
  # Get sample column names (excluding metadata columns)
  metadata_cols <- c("miRNA_name", "miRNA name", "pos.mut", "pos:mut")
  sample_cols <- names(data)[!names(data) %in% metadata_cols]
  
  # Extract groups using pattern matching
  groups_df <- tibble(sample_id = sample_cols) %>%
    mutate(
      group = case_when(
        str_detect(sample_id, regex(als_pattern, ignore_case = TRUE)) ~ "Disease",
        str_detect(sample_id, regex(control_pattern, ignore_case = TRUE)) ~ "Control",
        TRUE ~ NA_character_
      )
    )
  
  # Remove unmatched samples
  n_unmatched <- sum(is.na(groups_df$group))
  if (n_unmatched > 0) {
    warning(paste(n_unmatched, "samples without group assignment (will be excluded)"))
  }
  
  groups_df <- groups_df %>% filter(!is.na(group))
  
  # Summary
  unique_groups <- unique(groups_df$group)
  
  cat("📊 Sample groups identified by pattern matching:\n")
  for (grp in sort(unique_groups)) {
    n_grp <- sum(groups_df$group == grp)
    cat("   •", grp, ":", n_grp, "samples\n")
  }
  
  if (n_unmatched > 0) {
    cat("   ⚠️  Unmatched:", n_unmatched, "samples\n")
  }
  
  # Validate: need at least 2 groups with samples
  if (length(unique_groups) < 2) {
    stop("Need at least 2 groups for comparison. Found:", paste(unique_groups, collapse = ", "))
  }
  
  # Validate: each group needs at least 2 samples
  for (grp in unique_groups) {
    n_grp <- sum(groups_df$group == grp)
    if (n_grp < 2) {
      stop("Each group needs at least 2 samples. Group '", grp, "' has only ", n_grp, " sample(s)")
    }
  }
  
  return(groups_df)
}

#' Split Data into Groups
#' 
#' Splits data columns into groups based on group metadata.
#' Supports any number of groups (not just ALS/Control).
#' Returns backward-compatible structure for 2 groups.
#' 
#' @param data Data frame with sample columns
#' @param groups_df Data frame with sample_id and group columns
#' @return List with data frames for each group, plus group names and sample lists
split_data_by_groups <- function(data, groups_df) {
  
  # Get unique groups
  unique_groups <- sort(unique(groups_df$group))
  n_groups <- length(unique_groups)
  
  if (n_groups < 2) {
    stop("Need at least 2 groups for comparison. Found:", paste(unique_groups, collapse = ", "))
  }
  
  # For backward compatibility, if exactly 2 groups, use old naming for return list
  if (n_groups == 2) {
    group1_name <- unique_groups[1]
    group2_name <- unique_groups[2]
    
    group1_samples <- groups_df %>% filter(group == group1_name) %>% pull(sample_id)
    group2_samples <- groups_df %>% filter(group == group2_name) %>% pull(sample_id)
    
    metadata_cols <- c("miRNA_name", "miRNA name", "pos.mut", "pos:mut")
    metadata_cols <- metadata_cols[metadata_cols %in% names(data)]
    
    group1_data <- data %>% select(all_of(c(metadata_cols, group1_samples)))
    group2_data <- data %>% select(all_of(c(metadata_cols, group2_samples)))
    
    # Return with backward-compatible names
    result <- list(
      als_data = group1_data,
      control_data = group2_data,
      als_samples = group1_samples,
      control_samples = group2_samples,
      group1_name = group1_name,
      group2_name = group2_name,
      groups = unique_groups,
      n_groups = n_groups
    )
    
    # Also add generic names for flexibility
    result[[paste0(group1_name, "_data")]] <- group1_data
    result[[paste0(group2_name, "_data")]] <- group2_data
    result[[paste0(group1_name, "_samples")]] <- group1_samples
    result[[paste0(group2_name, "_samples")]] <- group2_samples
    
    return(result)
  }
  
  # For more than 2 groups, return flexible structure
  metadata_cols <- c("miRNA_name", "miRNA name", "pos.mut", "pos:mut")
  metadata_cols <- metadata_cols[metadata_cols %in% names(data)]
  
  result <- list(
    groups = unique_groups,
    n_groups = n_groups
  )
  
  # Add data and samples for each group
  for (grp in unique_groups) {
    grp_samples <- groups_df %>% filter(group == grp) %>% pull(sample_id)
    grp_data <- data %>% select(all_of(c(metadata_cols, grp_samples)))
    
    result[[paste0(grp, "_data")]] <- grp_data
    result[[paste0(grp, "_samples")]] <- grp_samples
  }
  
  # For backward compatibility, if exactly 2 groups, also add als_data/control_data
  if (n_groups == 2) {
    result[["als_data"]] <- result[[paste0(unique_groups[1], "_data")]]
    result[["control_data"]] <- result[[paste0(unique_groups[2], "_data")]]
    result[["als_samples"]] <- result[[paste0(unique_groups[1], "_samples")]]
    result[["control_samples"]] <- result[[paste0(unique_groups[2], "_samples")]]
    result[["group1_name"]] <- unique_groups[1]
    result[["group2_name"]] <- unique_groups[2]
  }
  
  return(result)
}

#' Calculate Group Statistics
#' 
#' Calculates summary statistics for each group.
#' Works with any group names (not hardcoded to ALS/Control).
#' 
#' @param data_long Long-format data with columns: miRNA_name, pos.mut, Sample, Count, Group
#' @return Data frame with group statistics
calculate_group_statistics <- function(data_long) {
  
  if (!"Group" %in% names(data_long)) {
    stop("data_long must contain 'Group' column")
  }
  
  stats <- data_long %>%
    group_by(Group) %>%
    summarise(
      n_samples = n_distinct(Sample),
      total_counts = sum(Count, na.rm = TRUE),
      mean_count = mean(Count, na.rm = TRUE),
      median_count = median(Count, na.rm = TRUE),
      sd_count = sd(Count, na.rm = TRUE),
      .groups = "drop"
    )
  
  return(stats)
}
