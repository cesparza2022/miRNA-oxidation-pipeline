#!/usr/bin/env Rscript
# ============================================================================
# STEP 4: Family Comparison Visualization (Part of Biological Grouping)
# ============================================================================
# Purpose: Generate comprehensive figures comparing oxidation patterns by miRNA family.
#          Part of Step 4 which runs after Step 2, in parallel with other discovery steps.
#
# This script generates 2 separate figures:
# 1. Panel A: Family Oxidation Comparison (disease vs control) - Barplot
# 2. Panel B: Family Heatmap - Heatmap showing oxidation patterns across families
#
# Snakemake parameters:
#   input: Family summary and comparison tables from Step 4.1
#   output: 2 separate figure files
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
  library(readr)
  library(stringr)
  library(pheatmap)
  library(RColorBrewer)
  library(scales)
})

# Load common functions and theme
source(snakemake@params[["functions"]], local = TRUE)
# Theme is loaded via functions_common.R

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
  file.path(dirname(snakemake@output[[1]]), "family_visualization.log")
}
initialize_logging(log_file, context = "Step 4.2 - Family Comparison Visualization")

log_section("STEP 4: Family Comparison Visualization (Part of Biological Grouping)")

# ============================================================================
# GET SNAKEMAKE PARAMETERS
# ============================================================================

input_family_summary <- snakemake@input[["family_summary"]]
input_family_comparison <- snakemake@input[["family_comparison"]]

output_figure_a <- snakemake@output[["figure_a"]]
output_figure_b <- snakemake@output[["figure_b"]]

config <- snakemake@config
alpha <- if (!is.null(config$analysis$alpha)) config$analysis$alpha else 0.05
seed_start <- if (!is.null(config$analysis$seed_region$start)) config$analysis$seed_region$start else 2
seed_end <- if (!is.null(config$analysis$seed_region$end)) config$analysis$seed_region$end else 8
color_gt <- if (!is.null(config$analysis$colors$gt)) config$analysis$colors$gt else "#D62728"
color_control <- if (!is.null(config$analysis$colors$control)) config$analysis$colors$control else "grey60"
color_als <- if (!is.null(config$analysis$colors$als)) config$analysis$colors$als else "#D62728"

fig_width <- if (!is.null(config$analysis$figure$width)) config$analysis$figure$width else 12
fig_height <- if (!is.null(config$analysis$figure$height)) config$analysis$figure$height else 10
fig_dpi <- if (!is.null(config$analysis$figure$dpi)) config$analysis$figure$dpi else 300

log_info(paste("Output figures:", output_figure_a, output_figure_b))
ensure_output_dir(dirname(output_figure_a))

# ============================================================================
# LOAD DATA
# ============================================================================

log_subsection("Loading family analysis data")

# Validate file existence before reading
if (!file.exists(input_family_summary)) {
  handle_error(
    paste("Family summary file not found:", input_family_summary),
    context = "Step 4.2 - Data Loading",
    exit_code = 1,
    log_file = log_file
  )
}
if (!file.exists(input_family_comparison)) {
  handle_error(
    paste("Family comparison file not found:", input_family_comparison),
    context = "Step 4.2 - Data Loading",
    exit_code = 1,
    log_file = log_file
  )
}

family_summary <- tryCatch({
  result <- read_csv(input_family_summary, show_col_types = FALSE)
  log_success(paste("Loaded family summary:", nrow(result), "families"))
  result
}, error = function(e) {
  handle_error(e, context = "Step 4.2 - Loading family summary", exit_code = 1, log_file = log_file)
})

family_comparison <- tryCatch({
  result <- read_csv(input_family_comparison, show_col_types = FALSE)
  log_success(paste("Loaded family comparison:", nrow(result), "families"))
  result
}, error = function(e) {
  handle_error(e, context = "Step 4.2 - Loading family comparison", exit_code = 1, log_file = log_file)
})

# Detect group names from family_comparison columns
# Try to extract from column names in family_summary first (most reliable)
mean_cols <- names(family_summary)[str_detect(names(family_summary), "avg_.*_mean$")]
if (length(mean_cols) >= 2) {
  group_names <- str_replace(mean_cols, "avg_|_mean", "")
  # Remove backward compatibility columns if dynamic names exist
  group_names <- group_names[!group_names %in% c("ALS", "Control")]
  if (length(group_names) >= 2) {
    group1_name <- sort(group_names)[1]
    group2_name <- sort(group_names)[2]
  } else {
    # Fallback to ALS/Control
    group1_name <- "ALS"
    group2_name <- "Control"
  }
} else {
  # Fallback: use ALS/Control
  group1_name <- "ALS"
  group2_name <- "Control"
}

log_info(paste("Detected groups:", group1_name, "vs", group2_name))

# ============================================================================
# PANEL A: Family Oxidation Comparison (ALS vs Control)
# ============================================================================

log_subsection("Creating Panel A: Family Oxidation Comparison (separate figure)")

# Prepare data for grouped barplot
# Use dynamic columns if available, fallback to als_mean_vaf/control_mean_vaf
vaf_cols <- if ("group1_mean_vaf" %in% names(family_comparison) && "group2_mean_vaf" %in% names(family_comparison)) {
  c("group1_mean_vaf", "group2_mean_vaf")
} else if ("als_mean_vaf" %in% names(family_comparison) && "control_mean_vaf" %in% names(family_comparison)) {
  c("als_mean_vaf", "control_mean_vaf")
} else {
  # If no VAF columns found, try to find any mean columns
  mean_cols <- names(family_comparison)[str_detect(names(family_comparison), "_mean_vaf$")]
  if (length(mean_cols) >= 2) {
    mean_cols[1:2]
  } else {
    log_warning("No VAF columns found, skipping Panel A")
    vaf_cols <- NULL
  }
}

# Check if we have valid VAF columns
if (is.null(vaf_cols) || length(vaf_cols) < 2 || !all(vaf_cols %in% names(family_comparison))) {
  log_warning("Required VAF columns not found in family_comparison. Available columns:")
  log_warning(paste(names(family_comparison), collapse = ", "))
  log_warning("Skipping Panel A generation")
  # Create empty figure
  panel_a <- ggplot() + 
    annotate("text", x = 0.5, y = 0.5, label = "Insufficient data for family comparison", size = 5) +
    theme_void()
} else {
  top_families <- family_comparison %>%
    arrange(desc(n_significant), desc(abs(vaf_difference))) %>%
    head(20)  # Top 20 families

  # Verify columns exist before selecting
  cols_to_select <- c("family", vaf_cols, "n_significant")
  cols_to_select <- cols_to_select[cols_to_select %in% names(top_families)]
  
  if (length(cols_to_select) < 3) {
    log_warning("Not enough columns for Panel A. Available:", paste(names(top_families), collapse = ", "))
    panel_a <- ggplot() + 
      annotate("text", x = 0.5, y = 0.5, label = "Insufficient data for family comparison", size = 5) +
      theme_void()
  } else {
    family_comparison_long <- top_families %>%
      select(all_of(cols_to_select)) %>%
      pivot_longer(
        cols = all_of(vaf_cols),
        names_to = "Group",
        values_to = "Mean_VAF"
      ) %>%
      mutate(
        Group = case_when(
          Group == vaf_cols[1] ~ group1_name,
          Group == vaf_cols[2] ~ group2_name,
          Group == "als_mean_vaf" ~ "ALS",  # Backward compatibility
          Group == "control_mean_vaf" ~ "Control",  # Backward compatibility
          TRUE ~ Group
        )
      )

    # Get statistics for caption
    total_families <- nrow(family_summary)
    top_family_name <- top_families$family[1]
    top_family_diff <- round(top_families$vaf_difference[1], 3)
    top_family_significant <- top_families$n_significant[1]

    panel_a <- ggplot(family_comparison_long, aes(x = reorder(family, Mean_VAF), y = Mean_VAF, fill = Group)) +
      geom_bar(stat = "identity", position = "dodge", alpha = 0.85, width = 0.7) +
      scale_fill_manual(
        values = c(
          setNames(c(color_als, color_control), c(group1_name, group2_name)),
          "ALS" = color_als,  # Backward compatibility
          "Control" = color_control  # Backward compatibility
        ),
        name = "Group"
      ) +
      scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
      coord_flip() +
      labs(
        title = paste0("miRNA Family Oxidation Patterns: ", group1_name, " vs ", group2_name),
        subtitle = paste("Top 20 families by significance | Seed region (", seed_start, "-", seed_end, ") |",
                         "Total families analyzed:", total_families),
        x = "miRNA Family",
        y = "Mean VAF (Variant Allele Frequency)",
        caption = paste("Top family (", top_family_name, "):", top_family_diff, "VAF difference |",
                       top_family_significant, "significant mutations")
      ) +
      theme_professional +
      theme(
        legend.position = "right",
        plot.title = element_text(size = 12, face = "bold", hjust = 0),
        plot.subtitle = element_text(size = 9, color = "grey50", hjust = 0)
      )
  }
}

ggsave(output_figure_a, panel_a,
       width = fig_width, height = fig_height, dpi = fig_dpi,
       bg = "white")
log_success(paste("Panel A saved:", output_figure_a))

# ============================================================================
# PANEL B: Family Heatmap
# ============================================================================

log_subsection("Creating Panel B: Family Heatmap (separate figure)")

# Prepare heatmap data
# Select top families by multiple criteria
heatmap_families <- family_comparison %>%
  arrange(desc(n_significant), desc(abs(vaf_difference)), desc(n_mutations)) %>%
  head(25)  # Top 25 families

# Create matrix for heatmap
# Rows: families, Columns: metrics
# First, verify required columns exist
required_cols <- c("family", "vaf_difference", "log2_fold_change", "n_significant", "n_mutations")
missing_cols <- required_cols[!required_cols %in% names(heatmap_families)]
if (length(missing_cols) > 0) {
  log_warning(paste("Missing required columns for heatmap:", paste(missing_cols, collapse = ", ")))
  log_warning("Available columns:", paste(names(heatmap_families), collapse = ", "))
  log_warning("Creating empty heatmap matrix")
  heatmap_matrix <- matrix(nrow = 0, ncol = 0)
} else {
  # Build select columns list dynamically
  select_cols <- c("family", "vaf_difference", "log2_fold_change", "n_significant", "n_mutations")
  
  # Add VAF columns if they exist
  vaf_cols_to_add <- c()
  if ("group1_mean_vaf" %in% names(heatmap_families)) {
    vaf_cols_to_add <- c(vaf_cols_to_add, "group1_mean_vaf")
  }
  if ("group2_mean_vaf" %in% names(heatmap_families)) {
    vaf_cols_to_add <- c(vaf_cols_to_add, "group2_mean_vaf")
  }
  if ("als_mean_vaf" %in% names(heatmap_families)) {
    vaf_cols_to_add <- c(vaf_cols_to_add, "als_mean_vaf")
  }
  if ("control_mean_vaf" %in% names(heatmap_families)) {
    vaf_cols_to_add <- c(vaf_cols_to_add, "control_mean_vaf")
  }
  
  heatmap_matrix <- heatmap_families %>%
    select(all_of(c(select_cols, vaf_cols_to_add))) %>%
    rename(
      VAF_Difference = vaf_difference,
      Log2FC = log2_fold_change,
      N_Significant = n_significant,
      N_Mutations = n_mutations
    )
  
  # Add Group columns if they exist
  if ("group1_mean_vaf" %in% names(heatmap_matrix)) {
    heatmap_matrix <- heatmap_matrix %>% rename(Group1_Mean_VAF = group1_mean_vaf)
  } else if ("als_mean_vaf" %in% names(heatmap_matrix)) {
    heatmap_matrix <- heatmap_matrix %>% mutate(Group1_Mean_VAF = als_mean_vaf)
  }
  
  if ("group2_mean_vaf" %in% names(heatmap_matrix)) {
    heatmap_matrix <- heatmap_matrix %>% rename(Group2_Mean_VAF = group2_mean_vaf)
  } else if ("control_mean_vaf" %in% names(heatmap_matrix)) {
    heatmap_matrix <- heatmap_matrix %>% mutate(Group2_Mean_VAF = control_mean_vaf)
  }
  
  # Add backward compatibility columns
  if ("als_mean_vaf" %in% names(heatmap_families)) {
    heatmap_matrix <- heatmap_matrix %>% mutate(ALS_Mean_VAF = als_mean_vaf)
  }
  if ("control_mean_vaf" %in% names(heatmap_families)) {
    heatmap_matrix <- heatmap_matrix %>% mutate(Control_Mean_VAF = control_mean_vaf)
  }
  
  heatmap_matrix <- heatmap_matrix %>%
    # Normalize columns to 0-1 scale for better visualization
    mutate(
      VAF_Diff_norm = scales::rescale(VAF_Difference, to = c(0, 1)),
      Log2FC_norm = scales::rescale(Log2FC, to = c(0, 1), na.rm = TRUE),
      N_Sig_norm = scales::rescale(N_Significant, to = c(0, 1)),
      N_Mut_norm = scales::rescale(N_Mutations, to = c(0, 1))
    )
  
  # Add normalized VAF columns if they exist
  if ("Group1_Mean_VAF" %in% names(heatmap_matrix)) {
    heatmap_matrix <- heatmap_matrix %>% 
      mutate(Group1_VAF_norm = scales::rescale(Group1_Mean_VAF, to = c(0, 1)))
  }
  if ("Group2_Mean_VAF" %in% names(heatmap_matrix)) {
    heatmap_matrix <- heatmap_matrix %>% 
      mutate(Group2_VAF_norm = scales::rescale(Group2_Mean_VAF, to = c(0, 1)))
  }
  if ("ALS_Mean_VAF" %in% names(heatmap_matrix)) {
    heatmap_matrix <- heatmap_matrix %>% 
      mutate(ALS_VAF_norm = scales::rescale(ALS_Mean_VAF, to = c(0, 1)))
  }
  if ("Control_Mean_VAF" %in% names(heatmap_matrix)) {
    heatmap_matrix <- heatmap_matrix %>% 
      mutate(Control_VAF_norm = scales::rescale(Control_Mean_VAF, to = c(0, 1)))
  }
  
  # Select only columns that exist
  norm_cols <- c("family", "VAF_Diff_norm", "Log2FC_norm", "N_Sig_norm", "N_Mut_norm")
  if ("Group1_VAF_norm" %in% names(heatmap_matrix)) norm_cols <- c(norm_cols, "Group1_VAF_norm")
  if ("Group2_VAF_norm" %in% names(heatmap_matrix)) norm_cols <- c(norm_cols, "Group2_VAF_norm")
  if ("ALS_VAF_norm" %in% names(heatmap_matrix)) norm_cols <- c(norm_cols, "ALS_VAF_norm")
  if ("Control_VAF_norm" %in% names(heatmap_matrix)) norm_cols <- c(norm_cols, "Control_VAF_norm")
  
  heatmap_matrix <- heatmap_matrix %>%
    select(all_of(norm_cols)) %>%
    column_to_rownames(var = "family") %>%
    as.matrix()
}

# Check if we have valid heatmap data
if (nrow(heatmap_matrix) == 0 || ncol(heatmap_matrix) == 0) {
  log_warning("No data for heatmap, creating empty heatmap figure")
  png(output_figure_b, width = 14, height = 12, units = "in", res = 300)
  plot.new()
  text(0.5, 0.5, "Insufficient data for family heatmap", cex = 1.5)
  dev.off()
} else {
  # Create annotation for families
  family_annotation <- heatmap_families %>%
    select(all_of(c("family", "n_significant", "n_mutations"))) %>%
    mutate(
      Significance_Category = case_when(
        n_significant >= 10 ~ "High",
        n_significant >= 5 ~ "Medium",
        n_significant >= 1 ~ "Low",
        TRUE ~ "None"
      )
    ) %>%
    column_to_rownames(var = "family")

  # Generate heatmap
  png(output_figure_b, width = 14, height = 12, units = "in", res = 300)

  pheatmap(
    heatmap_matrix,
    color = colorRampPalette(c("#2E86AB", "white", color_gt))(100),
    cluster_rows = TRUE,
    cluster_cols = TRUE,
    show_colnames = TRUE,
    show_rownames = TRUE,
    annotation_row = if ("Significance_Category" %in% names(family_annotation)) {
      family_annotation %>% select(Significance_Category)
    } else {
      NULL
    },
    annotation_colors = if ("Significance_Category" %in% names(family_annotation)) {
      list(
        Significance_Category = c("High" = "#D62728", "Medium" = "#FF7F0E", "Low" = "#2CA02C", "None" = "grey70")
      )
    } else {
      list()
    },
    main = "miRNA Family Oxidation Patterns Heatmap\nTop 25 Families by Significance",
    fontsize = 10,
    fontsize_row = 9,
    fontsize_col = 10,
    angle_col = 45,
    border_color = "grey60",
    legend = TRUE,
    display_numbers = FALSE,
    treeheight_row = 50,
    treeheight_col = 50
  )

  dev.off()
}

log_success(paste("Panel B saved:", output_figure_b))

log_success("Step 4.2 completed successfully - All 2 figures generated separately")

