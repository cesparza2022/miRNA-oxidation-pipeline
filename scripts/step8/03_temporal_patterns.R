#!/usr/bin/env Rscript
# ============================================================================
# STEP 8.3: TEMPORAL PATTERN ANALYSIS
# ============================================================================
# Purpose: Analyze temporal accumulation of G>T mutations (if timepoints available)
#          Similar to reference paper: validates that oxidation is not random degradation
# ============================================================================
# Input: VAF-filtered data from Step 1.5
# Output: Temporal accumulation tables and figures
# ============================================================================
# Note: This script will work if timepoint information is available in sample names
#       If not, it will create a placeholder analysis
# ============================================================================

# Suppress renv messages
options(renv.verbose = FALSE)

# ============================================================================
# SETUP AND LOAD DEPENDENCIES
# ============================================================================

# Get Snakemake parameters
input_vaf_filtered <- snakemake@input[["vaf_filtered"]]
output_table <- snakemake@output[["temporal_table"]]
output_figure <- snakemake@output[["temporal_figure"]]
seed_start <- as.integer(snakemake@params[["seed_start"]])
seed_end <- as.integer(snakemake@params[["seed_end"]])

# Source common functions
source(snakemake@input[["functions"]])

# Load required packages
required_packages <- c("dplyr", "tidyr", "readr", "stringr", "ggplot2", 
                       "patchwork", "purrr")
for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cran.r-project.org", quiet = TRUE)
    library(pkg, character.only = TRUE)
  }
}

log_info("═══════════════════════════════════════════════════════════════════")
log_info("  STEP 8.3: TEMPORAL PATTERN ANALYSIS")
log_info("═══════════════════════════════════════════════════════════════════")
log_info("")
log_info(paste("Input VAF-filtered data:", input_vaf_filtered))
log_info(paste("Seed region: positions", seed_start, "-", seed_end))
log_info("")

# ============================================================================
# LOAD DATA
# ============================================================================

log_subsection("Loading VAF-filtered data")

data <- read_csv(input_vaf_filtered, show_col_types = FALSE)

# Normalize column names
if ("miRNA name" %in% names(data)) {
  data <- data %>% rename(miRNA_name = `miRNA name`)
}
if ("pos:mut" %in% names(data)) {
  data <- data %>% rename(pos.mut = `pos:mut`)
}

# Identify sample columns
metadata_cols <- c("miRNA_name", "miRNA name", "pos.mut", "pos:mut", 
                   "mutation_type", "position")
all_cols <- colnames(data)
sample_cols <- all_cols[!all_cols %in% metadata_cols]

log_info(paste("Data loaded:", nrow(data), "rows"))
log_info(paste("Sample columns:", length(sample_cols)))

# Filter G>T mutations in seed region
gt_seed <- data %>%
  filter(
    str_detect(pos.mut, ":GT$"),
    !is.na(miRNA_name)
  ) %>%
  mutate(
    position = as.numeric(str_extract(pos.mut, "^\\d+")),
    in_seed = position >= seed_start & position <= seed_end
  ) %>%
  filter(in_seed == TRUE)

log_info(paste("G>T mutations in seed region:", nrow(gt_seed), "mutations"))

# ============================================================================
# EXTRACT TIMEPOINT INFORMATION FROM SAMPLE NAMES
# ============================================================================

log_subsection("Extracting timepoint information from sample names")

# Try to extract timepoints from sample names
# Common patterns: "T0", "T6", "T18", "T48", "time0", "time6", etc.
extract_timepoint <- function(sample_name) {
  # Try to extract numeric timepoint
  timepoint_match <- stringr::str_extract(sample_name, "(?i)(?:T|time|h|hr|hour)[_-]?(\\d+)")
  if (!is.na(timepoint_match)) {
    timepoint_num <- as.numeric(stringr::str_extract(timepoint_match, "\\d+"))
    return(timepoint_num)
  }
  
  # Try to extract from position in name (e.g., "sample_0", "sample_6")
  timepoint_match <- stringr::str_extract(sample_name, "(?i)(?:sample|rep)[_-]?(\\d+)")
  if (!is.na(timepoint_match)) {
    timepoint_num <- as.numeric(stringr::str_extract(timepoint_match, "\\d+"))
    return(timepoint_num)
  }
  
  # If no pattern found, return NA
  return(NA_real_)
}

# Extract timepoints for all samples
sample_timepoints <- tibble(
  sample_id = sample_cols,
  timepoint = map_dbl(sample_cols, extract_timepoint)
)

n_with_timepoint <- sum(!is.na(sample_timepoints$timepoint))
log_info(paste("Samples with timepoint information:", n_with_timepoint, "/", length(sample_cols)))

# ============================================================================
# CALCULATE TEMPORAL ACCUMULATION
# ============================================================================

if (n_with_timepoint > 0) {
  log_subsection("Calculating temporal accumulation patterns")
  
  # Prepare data for temporal analysis
  temporal_data <- gt_seed %>%
    select(miRNA_name, pos.mut, position, all_of(sample_cols)) %>%
    pivot_longer(
      cols = all_of(sample_cols),
      names_to = "sample_id",
      values_to = "count"
    ) %>%
    left_join(sample_timepoints, by = "sample_id") %>%
    filter(!is.na(timepoint), !is.na(count), count > 0) %>%
    group_by(miRNA_name, pos.mut, position, timepoint) %>%
    summarise(
      mean_count = mean(count, na.rm = TRUE),
      median_count = median(count, na.rm = TRUE),
      n_samples = n(),
      .groups = "drop"
    ) %>%
    arrange(miRNA_name, pos.mut, timepoint)
  
  # Calculate accumulation (change over time)
  temporal_accumulation <- temporal_data %>%
    group_by(miRNA_name, pos.mut, position) %>%
    arrange(timepoint) %>%
    mutate(
      first_timepoint = first(timepoint),
      last_timepoint = last(timepoint),
      first_count = first(mean_count),
      last_count = last(mean_count),
      accumulation_ratio = last_count / first_count,
      accumulation_absolute = last_count - first_count,
      n_timepoints = n()
    ) %>%
    filter(n_timepoints >= 2) %>%
    distinct(miRNA_name, pos.mut, position, .keep_all = TRUE)
  
  log_info(paste("Mutations with temporal data:", nrow(temporal_accumulation)))
  
  # Create visualization
  p1 <- temporal_data %>%
    group_by(timepoint) %>%
    summarise(
      total_gt_count = sum(mean_count, na.rm = TRUE),
      n_mutations = n_distinct(paste(miRNA_name, pos.mut)),
      .groups = "drop"
    ) %>%
    ggplot(aes(x = timepoint, y = total_gt_count)) +
    geom_line(color = "#D62728", linewidth = 1.5) +
    geom_point(color = "#D62728", size = 3) +
    labs(
      title = "Temporal Accumulation of G>T Mutations",
      subtitle = paste("Seed region (positions", seed_start, "-", seed_end, ")"),
      x = "Timepoint",
      y = "Total G>T Count (mean across samples)",
      caption = paste("n =", nrow(temporal_accumulation), "mutations tracked")
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 12, face = "bold"),
      plot.subtitle = element_text(size = 10, color = "grey50")
    )
  
  p2 <- temporal_accumulation %>%
    ggplot(aes(x = accumulation_ratio)) +
    geom_histogram(bins = 30, fill = "#D62728", alpha = 0.7) +
    geom_vline(xintercept = 1.0, linetype = "dashed", color = "grey50", linewidth = 1) +
    labs(
      title = "Distribution of Accumulation Ratios",
      subtitle = "Last timepoint / First timepoint",
      x = "Accumulation Ratio",
      y = "Frequency",
      caption = paste("Ratio > 1 = accumulation over time")
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 12, face = "bold"),
      plot.subtitle = element_text(size = 10, color = "grey50")
    )
  
  combined_plot <- p1 / p2 +
    plot_annotation(
      title = "Temporal Pattern Analysis",
      subtitle = paste("G>T mutations in seed region |", n_with_timepoint, "samples with timepoints")
    )
  
} else {
  log_warning("No timepoint information found in sample names")
  log_warning("Creating placeholder analysis")
  
  # Create placeholder table
  temporal_accumulation <- tibble(
    miRNA_name = character(),
    pos.mut = character(),
    position = numeric(),
    timepoint = numeric(),
    mean_count = numeric(),
    accumulation_ratio = numeric(),
    note = character()
  )
  
  # Create placeholder figure
  combined_plot <- ggplot() +
    annotate("text", x = 0.5, y = 0.5, 
             label = "No timepoint information available\nin sample names\n\nTo enable temporal analysis:\n- Include timepoint in sample names (e.g., 'T0', 'T6', 'T18')\n- Or provide timepoint metadata file",
             size = 5, hjust = 0.5) +
    theme_void() +
    labs(
      title = "Temporal Pattern Analysis",
      subtitle = "Timepoint information not available"
    )
}

# Save figure
ggsave(output_figure, combined_plot,
       width = 12, height = 10, dpi = 300, bg = "white")

log_success(paste("Figure saved:", output_figure))

# Save table
write_csv(temporal_accumulation, output_table)
log_success(paste("Temporal table saved:", output_table))

log_success("Step 8.3 completed successfully")

