# ============================================================================
# GROUP COMPARISON UTILITIES
# ============================================================================
# Helper functions for identifying and comparing ALS vs Control groups
# ============================================================================

#' Extract Sample Groups from Column Names
#' 
#' Identifies ALS and Control groups from column names using pattern matching.
#' Column names typically contain "ALS" or "control" (case-insensitive).
#' 
#' @param data Data frame with sample columns
#' @param als_pattern Regex pattern for ALS samples (default: "ALS")
#' @param control_pattern Regex pattern for Control samples (default: "control|Control|CTRL")
#' @return Data frame with columns: sample_id, group
extract_sample_groups <- function(data, 
                                  als_pattern = "ALS", 
                                  control_pattern = "control|Control|CTRL") {
  
  # Get sample column names (excluding metadata columns)
  metadata_cols <- c("miRNA_name", "miRNA name", "pos.mut", "pos:mut")
  sample_cols <- names(data)[!names(data) %in% metadata_cols]
  
  # Extract groups
  groups_df <- tibble(sample_id = sample_cols) %>%
    mutate(
      group = case_when(
        str_detect(sample_id, regex(als_pattern, ignore_case = TRUE)) ~ "ALS",
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
  n_als <- sum(groups_df$group == "ALS")
  n_control <- sum(groups_df$group == "Control")
  
  cat("📊 Sample groups identified:\n")
  cat("   • ALS:", n_als, "samples\n")
  cat("   • Control:", n_control, "samples\n")
  
  if (n_unmatched > 0) {
    cat("   ⚠️  Unmatched:", n_unmatched, "samples\n")
  }
  
  # Validate: need at least 2 groups with samples
  if (n_als == 0 || n_control == 0) {
    stop("Need both ALS and Control groups for comparison. Found: ALS=", n_als, ", Control=", n_control)
  }
  
  return(groups_df)
}

#' Split Data into ALS and Control Groups
#' 
#' Splits data columns into two groups based on group metadata.
#' 
#' @param data Data frame with sample columns
#' @param groups_df Data frame with sample_id and group columns
#' @return List with als_data and control_data data frames
split_data_by_groups <- function(data, groups_df) {
  
  als_samples <- groups_df %>% filter(group == "ALS") %>% pull(sample_id)
  control_samples <- groups_df %>% filter(group == "Control") %>% pull(sample_id)
  
  metadata_cols <- c("miRNA_name", "miRNA name", "pos.mut", "pos:mut")
  metadata_cols <- metadata_cols[metadata_cols %in% names(data)]
  
  als_data <- data %>% select(all_of(c(metadata_cols, als_samples)))
  control_data <- data %>% select(all_of(c(metadata_cols, control_samples)))
  
  return(list(
    als_data = als_data,
    control_data = control_data,
    als_samples = als_samples,
    control_samples = control_samples
  ))
}

#' Calculate Group Statistics
#' 
#' Calculates summary statistics for each group.
#' 
#' @param data_long Long-format data with columns: miRNA_name, pos.mut, Sample, Count, Group
#' @return Data frame with group statistics
calculate_group_statistics <- function(data_long) {
  
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

# GROUP COMPARISON UTILITIES
# ============================================================================
# Helper functions for identifying and comparing ALS vs Control groups
# ============================================================================

#' Extract Sample Groups from Column Names
#' 
#' Identifies ALS and Control groups from column names using pattern matching.
#' Column names typically contain "ALS" or "control" (case-insensitive).
#' 
#' @param data Data frame with sample columns
#' @param als_pattern Regex pattern for ALS samples (default: "ALS")
#' @param control_pattern Regex pattern for Control samples (default: "control|Control|CTRL")
#' @return Data frame with columns: sample_id, group
extract_sample_groups <- function(data, 
                                  als_pattern = "ALS", 
                                  control_pattern = "control|Control|CTRL") {
  
  # Get sample column names (excluding metadata columns)
  metadata_cols <- c("miRNA_name", "miRNA name", "pos.mut", "pos:mut")
  sample_cols <- names(data)[!names(data) %in% metadata_cols]
  
  # Extract groups
  groups_df <- tibble(sample_id = sample_cols) %>%
    mutate(
      group = case_when(
        str_detect(sample_id, regex(als_pattern, ignore_case = TRUE)) ~ "ALS",
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
  n_als <- sum(groups_df$group == "ALS")
  n_control <- sum(groups_df$group == "Control")
  
  cat("📊 Sample groups identified:\n")
  cat("   • ALS:", n_als, "samples\n")
  cat("   • Control:", n_control, "samples\n")
  
  if (n_unmatched > 0) {
    cat("   ⚠️  Unmatched:", n_unmatched, "samples\n")
  }
  
  # Validate: need at least 2 groups with samples
  if (n_als == 0 || n_control == 0) {
    stop("Need both ALS and Control groups for comparison. Found: ALS=", n_als, ", Control=", n_control)
  }
  
  return(groups_df)
}

#' Split Data into ALS and Control Groups
#' 
#' Splits data columns into two groups based on group metadata.
#' 
#' @param data Data frame with sample columns
#' @param groups_df Data frame with sample_id and group columns
#' @return List with als_data and control_data data frames
split_data_by_groups <- function(data, groups_df) {
  
  als_samples <- groups_df %>% filter(group == "ALS") %>% pull(sample_id)
  control_samples <- groups_df %>% filter(group == "Control") %>% pull(sample_id)
  
  metadata_cols <- c("miRNA_name", "miRNA name", "pos.mut", "pos:mut")
  metadata_cols <- metadata_cols[metadata_cols %in% names(data)]
  
  als_data <- data %>% select(all_of(c(metadata_cols, als_samples)))
  control_data <- data %>% select(all_of(c(metadata_cols, control_samples)))
  
  return(list(
    als_data = als_data,
    control_data = control_data,
    als_samples = als_samples,
    control_samples = control_samples
  ))
}

#' Calculate Group Statistics
#' 
#' Calculates summary statistics for each group.
#' 
#' @param data_long Long-format data with columns: miRNA_name, pos.mut, Sample, Count, Group
#' @return Data frame with group statistics
calculate_group_statistics <- function(data_long) {
  
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

# GROUP COMPARISON UTILITIES
# ============================================================================
# Helper functions for identifying and comparing ALS vs Control groups
# ============================================================================

#' Extract Sample Groups from Column Names
#' 
#' Identifies ALS and Control groups from column names using pattern matching.
#' Column names typically contain "ALS" or "control" (case-insensitive).
#' 
#' @param data Data frame with sample columns
#' @param als_pattern Regex pattern for ALS samples (default: "ALS")
#' @param control_pattern Regex pattern for Control samples (default: "control|Control|CTRL")
#' @return Data frame with columns: sample_id, group
extract_sample_groups <- function(data, 
                                  als_pattern = "ALS", 
                                  control_pattern = "control|Control|CTRL") {
  
  # Get sample column names (excluding metadata columns)
  metadata_cols <- c("miRNA_name", "miRNA name", "pos.mut", "pos:mut")
  sample_cols <- names(data)[!names(data) %in% metadata_cols]
  
  # Extract groups
  groups_df <- tibble(sample_id = sample_cols) %>%
    mutate(
      group = case_when(
        str_detect(sample_id, regex(als_pattern, ignore_case = TRUE)) ~ "ALS",
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
  n_als <- sum(groups_df$group == "ALS")
  n_control <- sum(groups_df$group == "Control")
  
  cat("📊 Sample groups identified:\n")
  cat("   • ALS:", n_als, "samples\n")
  cat("   • Control:", n_control, "samples\n")
  
  if (n_unmatched > 0) {
    cat("   ⚠️  Unmatched:", n_unmatched, "samples\n")
  }
  
  # Validate: need at least 2 groups with samples
  if (n_als == 0 || n_control == 0) {
    stop("Need both ALS and Control groups for comparison. Found: ALS=", n_als, ", Control=", n_control)
  }
  
  return(groups_df)
}

#' Split Data into ALS and Control Groups
#' 
#' Splits data columns into two groups based on group metadata.
#' 
#' @param data Data frame with sample columns
#' @param groups_df Data frame with sample_id and group columns
#' @return List with als_data and control_data data frames
split_data_by_groups <- function(data, groups_df) {
  
  als_samples <- groups_df %>% filter(group == "ALS") %>% pull(sample_id)
  control_samples <- groups_df %>% filter(group == "Control") %>% pull(sample_id)
  
  metadata_cols <- c("miRNA_name", "miRNA name", "pos.mut", "pos:mut")
  metadata_cols <- metadata_cols[metadata_cols %in% names(data)]
  
  als_data <- data %>% select(all_of(c(metadata_cols, als_samples)))
  control_data <- data %>% select(all_of(c(metadata_cols, control_samples)))
  
  return(list(
    als_data = als_data,
    control_data = control_data,
    als_samples = als_samples,
    control_samples = control_samples
  ))
}

#' Calculate Group Statistics
#' 
#' Calculates summary statistics for each group.
#' 
#' @param data_long Long-format data with columns: miRNA_name, pos.mut, Sample, Count, Group
#' @return Data frame with group statistics
calculate_group_statistics <- function(data_long) {
  
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

