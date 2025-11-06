#!/usr/bin/env Rscript
# ============================================================================
# STEP 8.5: Sequence-Based Clustering and Heatmap
# ============================================================================
# Purpose: Generate hierarchical clustering + heatmap of miRNAs based on
#          sequence patterns, G>T positions, and context
# ============================================================================

# Suppress renv messages
options(renv.verbose = FALSE)

# Load required libraries
suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(stringr)
  library(ComplexHeatmap)
  library(circlize)
  library(RColorBrewer)
})

# Get Snakemake parameters
input_vaf_filtered <- snakemake@input[["vaf_filtered"]]
input_context_summary <- snakemake@input[["context_summary"]]
input_statistical <- snakemake@input[["statistical"]]
output_figures_dir <- snakemake@params[["output_figures"]]
functions_common <- snakemake@input[["functions"]]
output_heatmap <- snakemake@output[["clustering_heatmap"]]
output_dendro <- snakemake@output[["clustering_dendrogram"]]
output_cluster_table <- snakemake@output[["cluster_assignments"]]

# Load common functions
source(functions_common, local = TRUE)

# Get config
config <- snakemake@config
seed_start <- if (!is.null(config$analysis$seed_region$start)) config$analysis$seed_region$start else 2
seed_end <- if (!is.null(config$analysis$seed_region$end)) config$analysis$seed_region$end else 8
color_gt <- if (!is.null(config$analysis$colors$gt)) config$analysis$colors$gt else "#D62728"
color_als <- if (!is.null(config$analysis$colors$als)) config$analysis$colors$als else "#D62728"
color_control <- if (!is.null(config$analysis$colors$control)) config$analysis$colors$control else "grey60"
top_n_mirnas <- if (!is.null(config$analysis$top_n_mirnas)) config$analysis$top_n_mirnas else 30

log_info("═══════════════════════════════════════════════════════════")
log_info("  STEP 8.5: Sequence-Based Clustering and Heatmap")
log_info("═══════════════════════════════════════════════════════════")

# ============================================================================
# LOAD DATA
# ============================================================================

log_subsection("Loading data")

data <- read_csv(input_vaf_filtered, show_col_types = FALSE)
context_summary <- read_csv(input_context_summary, show_col_types = FALSE)
statistical <- read_csv(input_statistical, show_col_types = FALSE)

# Normalize column names
if ("miRNA name" %in% colnames(data) && !"miRNA_name" %in% colnames(data)) {
  data$miRNA_name <- data$`miRNA name`
}
if ("pos:mut" %in% colnames(data) && !"pos.mut" %in% colnames(data)) {
  data$pos.mut <- data$`pos:mut`
}

# Identify sample columns
metadata_cols <- c("miRNA_name", "miRNA name", "pos.mut", "pos:mut", 
                   "mutation_type", "position")
all_cols <- colnames(data)
sample_cols <- all_cols[!all_cols %in% metadata_cols]

# Generate metadata
metadata <- data.frame(
  Sample_ID = sample_cols,
  Group = ifelse(
    grepl("Magen-ALS|ALS|als|Amyotrophic|motor", sample_cols, ignore.case = TRUE),
    "ALS",
    ifelse(
      grepl("Magen-control|Magen-Control|Control|control|Ctrl|CTRL|healthy|Healthy|Normal|normal", 
            sample_cols, ignore.case = TRUE),
      "Control",
      "Unknown"
    )
  ),
  stringsAsFactors = FALSE
)

log_success(paste("Data loaded:", nrow(data), "SNVs,", length(sample_cols), "samples"))

# ============================================================================
# PREPARE MATRIX FOR CLUSTERING
# ============================================================================

log_subsection("Preparing matrix for clustering")

# Get G>T mutations in seed region
gt_seed <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^[0-9]+"))) %>%
  filter(position >= seed_start, position <= seed_end) %>%
  select(miRNA_name, pos.mut, position, all_of(sample_cols))

# Calculate average VAF per miRNA per position (ALS vs Control)
als_samples <- metadata$Sample_ID[metadata$Group == "ALS"]
control_samples <- metadata$Sample_ID[metadata$Group == "Control"]

# Create matrix: miRNAs × Positions
# Values: Mean VAF difference (ALS - Control) for each miRNA-position combination
clustering_data <- gt_seed %>%
  select(miRNA_name, position, all_of(sample_cols)) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  left_join(metadata, by = "Sample_ID") %>%
  filter(!is.na(VAF), VAF > 0, Group != "Unknown") %>%
  group_by(miRNA_name, position, Group) %>%
  summarise(mean_vaf = mean(VAF, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = Group, values_from = mean_vaf, values_fill = 0) %>%
  mutate(
    vaf_diff = ALS - Control,
    log2_fc = log2((ALS + 0.001) / (Control + 0.001))
  ) %>%
  select(miRNA_name, position, vaf_diff) %>%
  # Pivot to wide format: miRNAs × positions
  pivot_wider(names_from = position, values_from = vaf_diff, values_fill = 0)

# Check for duplicate miRNA names
if (any(duplicated(clustering_data$miRNA_name))) {
  log_warning("Duplicate miRNA names found, aggregating...")
  clustering_data <- clustering_data %>%
    group_by(miRNA_name) %>%
    summarise(across(everything(), ~ mean(.x, na.rm = TRUE)), .groups = "drop")
}

# Convert to matrix
mirna_names <- clustering_data$miRNA_name
clustering_matrix <- clustering_data %>%
  select(-miRNA_name) %>%
  as.matrix()
rownames(clustering_matrix) <- mirna_names

# Select top miRNAs by total activity (sum of absolute differences)
top_mirnas <- names(sort(rowSums(abs(clustering_matrix)), decreasing = TRUE))[1:min(top_n_mirnas, nrow(clustering_matrix))]
clustering_matrix <- clustering_matrix[top_mirnas, ]

log_success(paste("Matrix prepared:", nrow(clustering_matrix), "miRNAs ×", ncol(clustering_matrix), "positions"))

# ============================================================================
# HIERARCHICAL CLUSTERING
# ============================================================================

log_subsection("Performing hierarchical clustering")

# Distance matrix and clustering
dist_matrix <- dist(clustering_matrix, method = "euclidean")
hc_mirnas <- hclust(dist_matrix, method = "ward.D2")

# Cut tree to get clusters (k = 4-6 clusters)
n_clusters <- min(6, max(3, ceiling(nrow(clustering_matrix) / 10)))
mirna_clusters <- stats::cutree(hc_mirnas, k = n_clusters)

log_success(paste("Clustering completed:", n_clusters, "clusters identified"))

# ============================================================================
# GENERATE HEATMAP WITH CLUSTERING
# ============================================================================

log_subsection("Generating heatmap with clustering")

# Create annotation for clusters
cluster_annotation <- data.frame(
  Cluster = factor(mirna_clusters),
  row.names = names(mirna_clusters)
)

# Create color palette for clusters
cluster_colors <- brewer.pal(min(n_clusters, 8), "Set2")
if (n_clusters > 8) {
  cluster_colors <- colorRampPalette(cluster_colors)(n_clusters)
}

# Create heatmap
png(output_heatmap, width = 14, height = 12, units = "in", res = 300)

# Annotation row
ha_row <- rowAnnotation(
  Cluster = cluster_annotation$Cluster,
  col = list(Cluster = setNames(cluster_colors, 1:n_clusters)),
  annotation_name_gp = gpar(fontsize = 10)
)

# Heatmap
ht <- Heatmap(
  clustering_matrix,
  name = "VAF\nDifference\n(ALS-Control)",
  col = colorRamp2(c(-0.1, 0, 0.1), c("blue", "white", color_gt)),
  cluster_rows = hc_mirnas,
  cluster_columns = FALSE,  # Keep positions in order
  show_row_names = TRUE,
  show_column_names = TRUE,
  row_names_gp = gpar(fontsize = 8),
  column_names_gp = gpar(fontsize = 10),
  right_annotation = ha_row,
  row_title = "miRNAs (clustered)",
  column_title = paste("Positions (seed region:", seed_start, "-", seed_end, ")"),
  heatmap_legend_param = list(
    title_gp = gpar(fontsize = 10),
    labels_gp = gpar(fontsize = 9)
  )
)

draw(ht)
dev.off()

log_success(paste("Heatmap saved:", output_heatmap))

# ============================================================================
# GENERATE DENDROGRAM
# ============================================================================

log_subsection("Generating dendrogram")

png(output_dendro, width = 14, height = 8, units = "in", res = 300)

# Color branches by cluster (using circlize)
dend <- as.dendrogram(hc_mirnas)
# Try to color branches - if dendextend not available, use simple coloring
if (requireNamespace("dendextend", quietly = TRUE)) {
  library(dendextend)
  dend <- dendextend::color_branches(dend, k = n_clusters, col = cluster_colors)
} else {
  # Simple dendrogram without branch coloring
  dend <- dend
}

par(mar = c(5, 4, 4, 2))
plot(dend,
     main = "Hierarchical Clustering of miRNAs\n(Based on G>T Positional Patterns)",
     xlab = "miRNAs",
     ylab = "Distance",
     sub = paste("Method: Ward.D2 |", n_clusters, "clusters identified"),
     cex = 0.6)

# Add cluster labels
stats::rect.hclust(hc_mirnas, k = n_clusters, border = "grey50")

dev.off()

log_success(paste("Dendrogram saved:", output_dendro))

# ============================================================================
# SAVE CLUSTER ASSIGNMENTS
# ============================================================================

log_subsection("Saving cluster assignments")

cluster_table <- data.frame(
  miRNA_name = names(mirna_clusters),
  cluster = mirna_clusters,
  stringsAsFactors = FALSE
) %>%
  arrange(cluster, miRNA_name)

dir.create(dirname(output_cluster_table), showWarnings = FALSE, recursive = TRUE)
write_csv(cluster_table, output_cluster_table)

log_success(paste("Cluster assignments saved:", output_cluster_table))

# Summary
log_info("")
log_info("═══════════════════════════════════════════════════════════")
log_info("  CLUSTERING SUMMARY")
log_info("═══════════════════════════════════════════════════════════")
for (i in 1:n_clusters) {
  n_mirnas <- sum(cluster_table$cluster == i)
  log_info(paste("  Cluster", i, ":", n_mirnas, "miRNAs"))
}

log_success("Step 8.5 completed successfully")

