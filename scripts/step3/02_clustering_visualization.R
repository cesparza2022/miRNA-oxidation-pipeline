#!/usr/bin/env Rscript
# ============================================================================
# STEP 3: Clustering Visualization (Part of Structure Discovery)
# ============================================================================
# Purpose: Generate comprehensive figures showing miRNA clusters.
#          Part of Step 3 which runs after Step 2, in parallel with other discovery steps.
#
# This script generates 2 separate figures:
# 1. Panel A: Cluster Heatmap showing oxidation patterns
# 2. Panel B: Dendrogram showing cluster relationships
#
# Snakemake parameters:
#   input: Cluster assignments and summary tables from Step 3.1
#   output: 2 separate figure files
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
  library(readr)
  library(stringr)
  library(pheatmap)
  library(RColorBrewer)
  # library(dendextend)  # Optional: For better dendrogram visualization
})

# Load common functions and theme
source(snakemake@params[["functions"]], local = TRUE)
# Theme is loaded via functions_common.R

# Initialize logging
log_file <- if (length(snakemake@log) > 0) snakemake@log[[1]] else {
  file.path(dirname(snakemake@output[[1]]), "clustering_visualization.log")
}
initialize_logging(log_file, context = "Step 3.2 - Clustering Visualization")

log_section("STEP 3: Clustering Visualization (Part of Structure Discovery)")

# ============================================================================
# GET SNAKEMAKE PARAMETERS
# ============================================================================

input_cluster_assignments <- snakemake@input[["cluster_assignments"]]
input_cluster_summary <- snakemake@input[["cluster_summary"]]

output_figure_a <- snakemake@output[["figure_a"]]
output_figure_b <- snakemake@output[["figure_b"]]

config <- snakemake@config
seed_start <- if (!is.null(config$analysis$seed_region$start)) config$analysis$seed_region$start else 2
seed_end <- if (!is.null(config$analysis$seed_region$end)) config$analysis$seed_region$end else 8
color_gt <- if (!is.null(config$analysis$colors$gt)) config$analysis$colors$gt else "#D62728"

fig_width <- if (!is.null(config$analysis$figure$width)) config$analysis$figure$width else 14
fig_height <- if (!is.null(config$analysis$figure$height)) config$analysis$figure$height else 12
fig_dpi <- if (!is.null(config$analysis$figure$dpi)) config$analysis$figure$dpi else 300

log_info(paste("Output figures:", output_figure_a, output_figure_b))
ensure_output_dir(dirname(output_figure_a))

# ============================================================================
# LOAD DATA AND RECREATE CLUSTERING
# ============================================================================

log_subsection("Loading cluster data")

# Validate file existence before reading
if (!file.exists(input_cluster_assignments)) {
  handle_error(
    paste("Cluster assignments file not found:", input_cluster_assignments),
    context = "Step 3.2 - Data Loading",
    exit_code = 1,
    log_file = log_file
  )
}
if (!file.exists(input_cluster_summary)) {
  handle_error(
    paste("Cluster summary file not found:", input_cluster_summary),
    context = "Step 3.2 - Data Loading",
    exit_code = 1,
    log_file = log_file
  )
}

cluster_assignments <- tryCatch({
  result <- read_csv(input_cluster_assignments, show_col_types = FALSE)
  log_success(paste("Loaded cluster assignments:", nrow(result), "miRNAs"))
  result
}, error = function(e) {
  handle_error(e, context = "Step 3.2 - Loading cluster assignments", exit_code = 1, log_file = log_file)
})

cluster_summary <- tryCatch({
  result <- read_csv(input_cluster_summary, show_col_types = FALSE)
  log_success(paste("Loaded cluster summary:", nrow(result), "rows"))
  result
}, error = function(e) {
  handle_error(e, context = "Step 3.2 - Loading cluster summary", exit_code = 1, log_file = log_file)
})

log_info(paste("Number of clusters:", n_distinct(cluster_assignments$cluster)))

# We need the VAF data to create the heatmap
# Re-load VAF data (same as in clustering analysis)
input_vaf_filtered <- snakemake@input[["filtered_data"]]
if (!file.exists(input_vaf_filtered)) {
  handle_error(
    paste("VAF filtered data file not found:", input_vaf_filtered),
    context = "Step 3.2 - Data Loading",
    exit_code = 1,
    log_file = log_file
  )
}

vaf_data <- tryCatch({
  result <- read_csv(input_vaf_filtered, show_col_types = FALSE)
  log_success(paste("Loaded VAF filtered data:", nrow(result), "SNVs"))
  result
}, error = function(e) {
  handle_error(e, context = "Step 3.2 - Loading VAF data", exit_code = 1, log_file = log_file)
})

# Normalize column names
if ("miRNA name" %in% names(vaf_data)) {
  vaf_data <- vaf_data %>% rename(miRNA_name = `miRNA name`)
}
if ("pos:mut" %in% names(vaf_data)) {
  vaf_data <- vaf_data %>% rename(pos.mut = `pos:mut`)
}

sample_cols <- setdiff(names(vaf_data), c("miRNA_name", "pos.mut", "miRNA name", "pos:mut"))

# Prepare heatmap data
heatmap_data <- vaf_data %>%
  filter(
    str_detect(pos.mut, ":GT$"),
    miRNA_name %in% cluster_assignments$miRNA_name
  ) %>%
  mutate(
    position = as.numeric(str_extract(pos.mut, "^\\d+")),
    in_seed = position >= seed_start & position <= seed_end
  ) %>%
  filter(in_seed == TRUE) %>%
  select(miRNA_name, all_of(sample_cols)) %>%
  group_by(miRNA_name) %>%
  summarise(
    across(all_of(sample_cols), ~ mean(.x, na.rm = TRUE)),
    .groups = "drop"
  ) %>%
  left_join(cluster_assignments, by = "miRNA_name") %>%
  arrange(cluster)

# ============================================================================
# PANEL A: Cluster Heatmap
# ============================================================================

log_subsection("Creating Panel A: Cluster Heatmap (separate figure)")

# Create matrix for heatmap
heatmap_matrix <- heatmap_data %>%
  select(-cluster) %>%
  column_to_rownames(var = "miRNA_name") %>%
  as.matrix()

# Normalize by row
heatmap_matrix_norm <- t(scale(t(heatmap_matrix)))
heatmap_matrix_norm[is.na(heatmap_matrix_norm)] <- 0

# Create cluster annotation
cluster_annotation <- heatmap_data %>%
  select(miRNA_name, Cluster = cluster) %>%
  column_to_rownames(var = "miRNA_name") %>%
  mutate(Cluster = as.factor(Cluster))

# Ensure order matches
heatmap_matrix_norm <- heatmap_matrix_norm[rownames(cluster_annotation), , drop = FALSE]

# Define cluster colors
n_clusters <- n_distinct(cluster_annotation$Cluster)
cluster_colors <- colorRampPalette(brewer.pal(min(n_clusters, 8), "Set2"))(n_clusters)
names(cluster_colors) <- as.character(1:n_clusters)

# Generate heatmap
# Validate output directory exists before saving
ensure_output_dir(dirname(output_figure_a))

png(output_figure_a, width = 16, height = 14, units = "in", res = 300)

pheatmap(
  heatmap_matrix_norm,
  color = colorRampPalette(c("#2E86AB", "white", color_gt))(100),
  cluster_rows = TRUE,
  cluster_cols = TRUE,
  show_colnames = FALSE,
  show_rownames = FALSE,
  annotation_row = cluster_annotation,
  annotation_colors = list(Cluster = cluster_colors),
  main = "miRNA Clustering by Oxidation Patterns\nG>T Mutations in Seed Region",
  fontsize = 10,
  fontsize_row = 6,
  fontsize_col = 6,
  border_color = NA,
  treeheight_row = 100,
  treeheight_col = 50
)

dev.off()

# Validate output file was created
validate_output_file(output_figure_a, min_size_bytes = 5000, context = "Step 3.2 - Panel A")

log_success(paste("Panel A saved:", output_figure_a))

# ============================================================================
# PANEL B: Cluster Dendrogram
# ============================================================================

log_subsection("Creating Panel B: Cluster Dendrogram (separate figure)")

# Recreate distance and clustering
dist_matrix <- dist(heatmap_matrix_norm, method = "euclidean")
hc <- hclust(dist_matrix, method = "ward.D2")

# Create dendrogram plot using base R plot (simpler, no extra packages)
png(output_figure_b, width = 16, height = 12, units = "in", res = 300)

par(mar = c(8, 4, 4, 2))
plot(hc, 
     main = "miRNA Clustering Dendrogram",
     sub = paste("Hierarchical clustering (Ward.D2) |", nrow(cluster_assignments), 
                "miRNAs |", n_clusters, "clusters"),
     xlab = "",
     ylab = "Height (Distance)",
     labels = FALSE,
     hang = -1)

# Add cluster rectangles
rect.hclust(hc, k = n_clusters, border = cluster_colors)

dev.off()

# Validate output file was created
validate_output_file(output_figure_b, min_size_bytes = 5000, context = "Step 3.2 - Panel B")

log_success(paste("Panel B saved:", output_figure_b))

log_success("Step 3.2 completed successfully - All 2 figures generated separately")

