#!/usr/bin/env Rscript
# ============================================================================
# STEP 2.7: Hierarchical Clustering - SEED REGION G>T SNVs ONLY
# ============================================================================
# Purpose: Clustering jerárquico de muestras usando SOLO SNVs G>T en seed region
#          Para entender agrupación específica de muestras por patrones en seed
# ============================================================================

# Get Snakemake parameters
# Use fallback logic: prefer vaf_filtered, else fallback
input_data <- if (file.exists(snakemake@input[["vaf_filtered_data"]])) {
  snakemake@input[["vaf_filtered_data"]]
} else {
  snakemake@input[["fallback_data"]]
}
output_figure <- snakemake@output[["clustering_figure"]]
output_clusters <- snakemake@output[["cluster_assignments"]]
output_table <- snakemake@output[["clustering_table"]]
config <- snakemake@config

# Load required libraries
suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(stringr)
  library(tibble)
  library(pheatmap)
  library(viridis)
  library(ComplexHeatmap)
  library(circlize)
  library(grid)
})

# Source common functions
source(snakemake@input[["functions"]], local = TRUE)

# Get configuration
seed_start <- if (!is.null(config$analysis$seed_region$start)) config$analysis$seed_region$start else 2
seed_end <- if (!is.null(config$analysis$seed_region$end)) config$analysis$seed_region$end else 8
fig_width <- if (!is.null(config$analysis$figure$width)) config$analysis$figure$width else 12
fig_height <- if (!is.null(config$analysis$figure$height)) config$analysis$figure$height else 10
fig_dpi <- if (!is.null(config$analysis$figure$dpi)) config$analysis$figure$dpi else 300
# Use standardized colors from colors.R (loaded via functions_common.R)
# Allow override from config if specified, otherwise use COLOR_ALS, COLOR_CONTROL
color_als <- if (!is.null(config$analysis$colors$als)) config$analysis$colors$als else COLOR_ALS
color_control <- if (!is.null(config$analysis$colors$control)) config$analysis$colors$control else COLOR_CONTROL

log_info("═══════════════════════════════════════════════════════════════════")
log_info("STEP 2.7: Hierarchical Clustering - SEED REGION G>T SNVs ONLY")
log_info("═══════════════════════════════════════════════════════════════════")
log_info(paste("Purpose: Clustering jerárquico de MUESTRAS usando SOLO SNVs G>T en seed region (pos", 
               seed_start, "-", seed_end, ")"))
log_info("")

# ============================================================================
# LOAD DATA
# ============================================================================

log_subsection("Loading data")

# Try to load VAF filtered data, fallback to processed clean
if (file.exists(input_data)) {
  data <- readr::read_csv(input_data, show_col_types = FALSE)
  
  # Validate data is not empty
  if (nrow(data) == 0) {
    stop("Input dataset is empty (0 rows)")
  }
  if (ncol(data) == 0) {
    stop("Input dataset has no columns")
  }
  
  log_success(paste("Data loaded:", nrow(data), "SNVs"))
} else {
  stop("❌ Input data file not found: ", input_data)
}

# Identify metadata columns
metadata_cols <- c("miRNA_name", "miRNA name", "pos.mut", "pos:mut", 
                   "mutation_type", "position")

# Fix column names if needed
if ("pos:mut" %in% colnames(data) && !"pos.mut" %in% colnames(data)) {
  data$pos.mut <- data$`pos:mut`
}
if ("miRNA name" %in% colnames(data) && !"miRNA_name" %in% colnames(data)) {
  data$miRNA_name <- data$`miRNA name`
}

# Get sample columns (SNV counts) and total columns (for VAF calculation)
all_cols <- colnames(data)

# Exclude metadata columns
sample_cols_raw <- all_cols[!all_cols %in% metadata_cols]

# Identify SNV columns (sample columns without totals)
sample_cols <- sample_cols_raw[!grepl("\\(PM\\+1MM\\+2MM\\)|Total|TOTAL", sample_cols_raw, ignore.case = TRUE)]

# Identify total columns (for VAF calculation)
total_cols <- sample_cols_raw[grepl("\\(PM\\+1MM\\+2MM\\)", sample_cols_raw, ignore.case = TRUE)]

# If no pattern matches, try alternative approach
if (length(sample_cols) == 0) {
  sample_cols <- sample_cols_raw[grepl("^Magen-", sample_cols_raw)]
  sample_cols <- sample_cols[!grepl("\\(PM\\+1MM\\+2MM\\)|Total|TOTAL", sample_cols, ignore.case = TRUE)]
}

if (length(sample_cols) == 0) {
  stop("❌ No sample columns found! (after excluding totals)")
}

log_info(paste("Found", length(sample_cols), "SNV sample columns"))
log_info(paste("Found", length(total_cols), "total columns for VAF calculation"))

# Generate metadata automatically
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

# If no pattern found, use first half as Control, second as ALS
if (sum(metadata$Group == "Unknown") == length(sample_cols)) {
  n_samples <- length(sample_cols)
  metadata$Group <- c(rep("Control", ceiling(n_samples/2)), 
                      rep("ALS", floor(n_samples/2)))
}

n_als <- sum(metadata$Group == "ALS")
n_ctrl <- sum(metadata$Group == "Control")
log_info(paste("Groups: ALS =", n_als, ", Control =", n_ctrl))

# ============================================================================
# PREPARE MATRIX FOR CLUSTERING (SEED REGION G>T SNVs ONLY)
# ============================================================================

log_subsection("Preparing matrix for clustering (SEED REGION G>T SNVs ONLY)")

# Get G>T mutations in seed region only
vaf_gt_seed <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  mutate(
    position = as.numeric(str_extract(pos.mut, "^[0-9]+")),
    SNV_ID = paste(miRNA_name, pos.mut, sep = "_")
  ) %>%
  filter(!is.na(position), position >= seed_start, position <= seed_end)

# Count unique miRNAs
n_mirnas <- length(unique(vaf_gt_seed$miRNA_name))

log_info(paste("Total G>T SNVs in seed region (", seed_start, "-", seed_end, "):", nrow(vaf_gt_seed)))
log_info(paste("Unique miRNAs with G>T in seed region:", n_mirnas))

if (nrow(vaf_gt_seed) == 0) {
  stop(paste("❌ No G>T mutations found in seed region (", seed_start, "-", seed_end, ")!"))
}

# Calculate VAF for each sample: VAF = SNV_Count / Total_Count
log_info("Calculating VAF for each sample (SNV_Count / Total_Count)")

# Initialize VAF matrix
vaf_matrix <- matrix(NA, nrow = nrow(vaf_gt_seed), ncol = length(sample_cols))
rownames(vaf_matrix) <- vaf_gt_seed$SNV_ID
colnames(vaf_matrix) <- sample_cols

# For each sample, calculate VAF
for (i in seq_along(sample_cols)) {
  snv_col <- sample_cols[i]
  
  # Find corresponding total column
  # Pattern: sample name + " (PM+1MM+2MM)"
  total_col <- paste0(snv_col, " (PM+1MM+2MM)")
  
  # If exact match not found, try to find by base name
  if (!total_col %in% colnames(data)) {
    # Try to find total column by matching base name
    # Remove "Magen-" prefix if present and search
    base_name <- gsub("^Magen-", "", snv_col)
    total_candidates <- grep(paste0(base_name, ".*\\(PM\\+1MM\\+2MM\\)"), colnames(data), value = TRUE)
    if (length(total_candidates) > 0) {
      total_col <- total_candidates[1]
    }
  }
  
  # Get SNV counts and Total counts directly from data
  snv_counts <- as.numeric(as.character(vaf_gt_seed[[snv_col]]))
  
  if (total_col %in% colnames(data)) {
    total_counts <- as.numeric(as.character(vaf_gt_seed[[total_col]]))
    
    # Calculate VAF: VAF = SNV_Count / Total_Count (avoid division by zero)
    vaf_values <- ifelse(!is.na(total_counts) & total_counts > 0,
                        snv_counts / total_counts,
                        NA)
    
    # VAF should be <= 0.5 (already filtered in Step 1.5, but double-check)
    vaf_values <- ifelse(!is.na(vaf_values) & vaf_values <= 0.5, vaf_values, NA)
    
    vaf_matrix[, i] <- vaf_values
  } else {
    log_warning(paste("⚠️  Total column not found for", snv_col, "- using raw counts as fallback"))
    # If no total column found, use raw counts (but this is not ideal)
    vaf_matrix[, i] <- snv_counts
  }
}

# Replace NA with 0 for clustering (missing values)
vaf_matrix[is.na(vaf_matrix)] <- 0

# Log VAF statistics
vaf_non_zero <- vaf_matrix[vaf_matrix > 0]
log_info(paste("Matrix prepared (VAF):", nrow(vaf_matrix), "SNVs ×", ncol(vaf_matrix), "samples"))
log_info(paste("Non-zero VAF values:", length(vaf_non_zero), "(", 
               round(100 * length(vaf_non_zero) / length(vaf_matrix), 2), "%)"))
if (length(vaf_non_zero) > 0) {
  log_info(paste("VAF range:", round(min(vaf_non_zero), 6), "to", round(max(vaf_non_zero), 6)))
  log_info(paste("Mean VAF (non-zero):", round(mean(vaf_non_zero), 6)))
}

# ============================================================================
# HIERARCHICAL CLUSTERING OF SAMPLES
# ============================================================================

log_subsection("Performing hierarchical clustering of samples")

# Calculate distance matrix for SAMPLES (columns)
sample_dist <- dist(t(vaf_matrix), method = "euclidean")
sample_hclust <- hclust(sample_dist, method = "ward.D2")

# Cut tree to get clusters (try k=2, k=3, k=4)
clusters_k2 <- cutree(sample_hclust, k = 2)
clusters_k3 <- cutree(sample_hclust, k = 3)
clusters_k4 <- cutree(sample_hclust, k = 4)

log_info("Clustering completed (k=2, k=3, k=4)")

# Analyze cluster composition
cluster_analysis_k2 <- data.frame(
  Sample_ID = names(clusters_k2),
  Cluster = clusters_k2
) %>%
  left_join(metadata %>% select(Sample_ID, Group), by = "Sample_ID") %>%
  group_by(Cluster, Group) %>%
  summarise(N = n(), .groups = "drop") %>%
  pivot_wider(names_from = Group, values_from = N, values_fill = 0)

log_info("Cluster composition (k=2):")
log_info(paste(capture.output(print(cluster_analysis_k2)), collapse = "\n"))

# Save cluster assignments (use k=2 as default)
cluster_assignments <- data.frame(
  Sample_ID = names(clusters_k2),
  Cluster_k2 = clusters_k2,
  Cluster_k3 = clusters_k3,
  Cluster_k4 = clusters_k4
) %>%
  left_join(metadata, by = "Sample_ID")

write_csv(cluster_assignments, output_clusters)
log_success(paste("Cluster assignments saved:", output_clusters))

# ============================================================================
# PREPARE ANNOTATION
# ============================================================================

log_subsection("Preparing sample annotations")

annotation_col <- data.frame(
  Group = metadata$Group,
  Cluster_k2 = as.character(clusters_k2[metadata$Sample_ID]),
  row.names = metadata$Sample_ID
)

# Colors are defined in colors.R (sourced via functions_common.R)
annotation_colors <- list(
  Group = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL, "Unknown" = "grey70"),
  Cluster_k2 = c("1" = COLOR_CLUSTER_1, "2" = COLOR_CLUSTER_2)
)

# ============================================================================
# GENERATE HEATMAP WITH CLUSTERING
# ============================================================================

log_subsection("Generating clustering heatmap with dendrogram")

# Use all seed region SNVs (should be manageable)
vaf_matrix_viz <- vaf_matrix

# Reorder samples according to clustering
sample_order <- sample_hclust$order
vaf_matrix_viz <- vaf_matrix_viz[, sample_order, drop = FALSE]
annotation_col <- annotation_col[sample_order, , drop = FALSE]

# Generate heatmap
png(output_figure, width = fig_width, height = fig_height, units = "in", res = fig_dpi)

pheatmap(
  vaf_matrix_viz,
  
  # Clustering (only on columns, rows already ordered by variance)
  cluster_rows = TRUE,
  cluster_cols = FALSE,  # Already ordered by hclust
  clustering_distance_rows = "euclidean",
  clustering_method = "ward.D2",
  
  # Display
  show_rownames = FALSE,  # Too many SNVs potentially
  show_colnames = FALSE,  # Don't show sample names (too long and many)
  
  # Colors (white to red for VAF/oxidation)
  # VAF range: 0 to 0.5 (max VAF after filtering, Step 1.5)
  # Use 100 colors for smooth gradient
  # Gradient function is defined in colors.R (sourced via functions_common.R)
  color = get_heatmap_gradient(100),
  
  # Annotations
  annotation_col = annotation_col,
  annotation_colors = annotation_colors,
  
  # Scale (none for raw VAF values)
  scale = "none",  # Show raw VAF values (0 to 0.5, blanco→rojo)
  
  # Borders
  border_color = NA,
  
  # Legend
  legend = TRUE,
  
  # Main title (include number of miRNAs)
  main = paste("Hierarchical Clustering of Samples by G>T Profile (SEED REGION ONLY)\n(Positions", 
               seed_start, "-", seed_end, ": functional binding domain | n =", format(nrow(vaf_matrix), big.mark = ","), "SNVs,", 
               n_mirnas, "miRNAs,", ncol(vaf_matrix), "samples)"),
  fontsize = 12,
  fontsize_row = 6,
  fontsize_col = 8,
  angle_col = "90"
)

dev.off()

log_success(paste("Clustering heatmap saved:", output_figure))

# ============================================================================
# SAVE SUMMARY TABLE
# ============================================================================

log_subsection("Saving summary table")

# Create summary table with cluster composition
summary_table <- data.frame(
  Analysis = paste("Hierarchical Clustering - SEED REGION G>T SNVs (positions", seed_start, "-", seed_end, ": functional binding domain)"),
  Total_SNVs = nrow(vaf_matrix),
  Total_Samples = ncol(vaf_matrix),
  ALS_Samples = n_als,
  Control_Samples = n_ctrl,
  Cluster_k2_1_ALS = sum(cluster_assignments$Cluster_k2 == 1 & cluster_assignments$Group == "ALS"),
  Cluster_k2_1_Control = sum(cluster_assignments$Cluster_k2 == 1 & cluster_assignments$Group == "Control"),
  Cluster_k2_2_ALS = sum(cluster_assignments$Cluster_k2 == 2 & cluster_assignments$Group == "ALS"),
  Cluster_k2_2_Control = sum(cluster_assignments$Cluster_k2 == 2 & cluster_assignments$Group == "Control"),
  Cluster_Purity_k2 = round(mean(cluster_assignments$Cluster_k2 == ifelse(cluster_assignments$Group == "ALS", 1, 2)), 3)
)

write_csv(summary_table, output_table)
log_success(paste("Summary table saved:", output_table))

log_success("Step 2.7 completed successfully")

