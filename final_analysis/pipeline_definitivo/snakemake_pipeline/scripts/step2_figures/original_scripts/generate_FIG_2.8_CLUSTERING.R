#!/usr/bin/env Rscript
# ============================================================================
# FIGURA 2.8 - HIERARCHICAL CLUSTERING HEATMAP
# Clustering of samples by G>T mutational profile
# Uses biological filtering (expressed miRNAs with good G>T) instead of arbitrary "top N"
# ============================================================================

library(ggplot2)
library(dplyr)
library(tidyr)
library(readr)
library(stringr)
library(tibble)
library(pheatmap)
library(viridis)
library(yaml)

# Colores profesionales
COLOR_ALS <- "#D62728"
COLOR_CONTROL <- "#2E86AB"

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  GENERATING FIG 2.8 - CLUSTERING HEATMAP (Biological Filtering)\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# ============================================================================
# LOAD CONFIGURATION
# ============================================================================

# Initialize snakemake_dir for later use
snakemake_dir <- NULL

# Try to get config from Snakemake, otherwise read from YAML
if (exists("snakemake") && !is.null(snakemake@config)) {
  config <- snakemake@config
  cat("📋 Configuration loaded from Snakemake\n")
  # Try to determine snakemake_dir from Snakemake object
  if (exists("snakemake") && "workflow" %in% slotNames(snakemake)) {
    tryCatch({
      snakemake_dir <- dirname(snakemake@workflow$basedir)
    }, error = function(e) {
      # Ignore errors
    })
  }
} else {
  # Calculate path to snakemake_pipeline directory
  # From work_dir (results/step2/figures/work), we need to go up to snakemake_pipeline/
  # Work dir structure: snakemake_pipeline/results/step2/figures/work
  # So from work_dir, go up 4 levels: ../../../../ = snakemake_pipeline/
  current_dir <- getwd()
  
  # Try multiple strategies to find snakemake_pipeline directory
  # Strategy 1: From work_dir (results/step2/figures/work), go up 4 levels
  if (grepl("/results/step2/figures/work", current_dir)) {
    snakemake_dir <- normalizePath(file.path(current_dir, "../../../../"), mustWork = FALSE)
    if (!file.exists(file.path(snakemake_dir, "config/config.yaml"))) {
      snakemake_dir <- NULL
    }
  }
  
  # Strategy 2: Look for config.yaml in parent directories
  if (is.null(snakemake_dir)) {
    test_dir <- current_dir
    for (i in 1:10) {
      config_test <- file.path(test_dir, "config/config.yaml")
      if (file.exists(config_test)) {
        snakemake_dir <- test_dir
        break
      }
      test_dir <- dirname(test_dir)
      if (test_dir == dirname(test_dir)) break  # Reached filesystem root
    }
  }
  
  # Strategy 3: Try relative paths from current directory
  config_paths <- c(
    if (!is.null(snakemake_dir)) file.path(snakemake_dir, "config/config.yaml") else NULL,
    "../../../../config/config.yaml",  # From work_dir
    "../../../../../config/config.yaml",
    "../../../../../../config/config.yaml",
    "../snakemake_pipeline/config/config.yaml",
    "../../snakemake_pipeline/config/config.yaml",
    "config/config.yaml"
  )
  config_paths <- config_paths[!is.null(config_paths)]
  
  config <- NULL
  config_path_used <- NULL
  for (cp in config_paths) {
    if (file.exists(cp)) {
      config <- yaml::read_yaml(cp)
      config_path_used <- cp
      cat("📋 Configuration loaded from:", cp, "\n")
      break
    }
  }
  
  if (is.null(config)) {
    cat("⚠️  Config not found, using defaults\n")
    # Default config structure
    config <- list(
      analysis = list(
        heatmap_filtering = list(
          require_seed_gt = TRUE,
          seed_positions = c(2, 3, 4, 5, 6, 7, 8),
          min_mean_vaf = 0.0,
          min_samples_with_vaf = 1,
          min_rpm_mean = NULL,
          require_significance = FALSE,
          position_range = NULL,
          min_log2_fold_change = NULL
        ),
        alpha = 0.05
      )
    )
  } else {
    # Store snakemake_dir for later use if not already found
    if (is.null(snakemake_dir) && !is.null(config_path_used)) {
      snakemake_dir <- dirname(dirname(config_path_used))  # Go up from config/config.yaml to snakemake_pipeline/
      # Verify it's correct
      if (!file.exists(file.path(snakemake_dir, "config/config.yaml"))) {
        snakemake_dir <- NULL
      }
    }
  }
}

# ============================================================================
# LOAD COMMON FUNCTIONS
# ============================================================================

# Try to source functions_common.R to get filter_mirnas_for_heatmap()
# Calculate path to functions_common.R based on snakemake_dir found above
functions_paths <- c()
if (!is.null(snakemake_dir)) {
  functions_paths <- c(
    file.path(snakemake_dir, "scripts/utils/functions_common.R")
  )
}

# Add relative paths as fallback
functions_paths <- c(
  functions_paths,
  "../../../../scripts/utils/functions_common.R",  # From work_dir
  "../../../../../scripts/utils/functions_common.R",
  "../../../../../../scripts/utils/functions_common.R",
  "../snakemake_pipeline/scripts/utils/functions_common.R",
  "../../snakemake_pipeline/scripts/utils/functions_common.R",
  "scripts/utils/functions_common.R"
)

functions_loaded <- FALSE
for (fp in functions_paths) {
  if (file.exists(fp)) {
    source(fp, local = TRUE)
    functions_loaded <- TRUE
    cat("✅ Common functions loaded from:", fp, "\n")
    break
  }
}
if (!functions_loaded) {
  cat("⚠️  functions_common.R not found, filtering will use basic approach\n")
}

# ============================================================================
# LOAD DATA
# ============================================================================

cat("\n📂 Loading data...\n")
data <- read_csv("final_processed_data_CLEAN.csv", show_col_types = FALSE)
metadata <- read_csv("metadata.csv", show_col_types = FALSE)
sample_cols <- metadata$Sample_ID

cat("   ✅ Data loaded:", nrow(data), "SNVs,", length(sample_cols), "samples\n\n")

# Try to load statistical results (for significance filtering if required)
statistical_results <- NULL
statistical_paths <- c()
if (!is.null(snakemake_dir)) {
  statistical_paths <- c(
    file.path(snakemake_dir, "results/step2/tables/statistical_results/S2_statistical_comparisons.csv")
  )
}
statistical_paths <- c(
  statistical_paths,
  "../../../../results/step2/tables/statistical_results/S2_statistical_comparisons.csv",  # From work_dir
  "../../../../../results/step2/tables/statistical_results/S2_statistical_comparisons.csv",
  "../../snakemake_pipeline/results/step2/tables/statistical_results/S2_statistical_comparisons.csv",
  "../snakemake_pipeline/results/step2/tables/statistical_results/S2_statistical_comparisons.csv",
  "results/step2/tables/statistical_results/S2_statistical_comparisons.csv"
)
for (sp in statistical_paths) {
  if (file.exists(sp)) {
    statistical_results <- read_csv(sp, show_col_types = FALSE)
    cat("   ✅ Statistical results loaded from:", sp, "\n")
    break
  }
}

# Try to load RPM data (for expression filtering if available)
rpm_data <- NULL
rpm_paths <- c()
if (!is.null(snakemake_dir)) {
  rpm_paths <- c(
    file.path(snakemake_dir, "results/step5/tables/expression_oxidation_correlation.csv")
  )
}
rpm_paths <- c(
  rpm_paths,
  "../../../../results/step5/tables/expression_oxidation_correlation.csv",  # From work_dir
  "../../../../../results/step5/tables/expression_oxidation_correlation.csv",
  "../../snakemake_pipeline/results/step5/tables/expression_oxidation_correlation.csv",
  "../snakemake_pipeline/results/step5/tables/expression_oxidation_correlation.csv",
  "results/step5/tables/expression_oxidation_correlation.csv"
)
for (rp in rpm_paths) {
  if (file.exists(rp)) {
    rpm_data_full <- read_csv(rp, show_col_types = FALSE)
    # Extract miRNA_name and estimated_rpm if available
    if ("miRNA_name" %in% colnames(rpm_data_full) && "estimated_rpm" %in% colnames(rpm_data_full)) {
      rpm_data <- rpm_data_full %>% select(miRNA_name, estimated_rpm)
      cat("   ✅ RPM data loaded from:", rp, "\n")
      break
    }
  }
}
if (is.null(rpm_data)) {
  cat("   ⏭️  RPM data not available (will skip RPM filtering)\n")
}

# ============================================================================
# BIOLOGICAL FILTERING: Filter miRNAs by expression and G>T quality
# ============================================================================

cat("\n🔍 BIOLOGICAL FILTERING: Filtering miRNAs by expression and G>T quality...\n")

# Use filtering function if available, otherwise use basic approach
if (exists("filter_mirnas_for_heatmap") && functions_loaded) {
  filtered_mirnas <- filter_mirnas_for_heatmap(
    data = data,
    metadata = metadata,
    config = config,
    sample_cols = sample_cols,
    statistical_results = statistical_results,
    rpm_data = rpm_data
  )
  cat("   ✅ Filtered miRNAs:", length(filtered_mirnas), "(using configurable thresholds)\n")
} else {
  # Fallback: Basic filtering (seed G>T requirement)
  cat("⚠️  Using basic filtering (fallback mode)\n")
  seed_positions <- if (!is.null(config$analysis$heatmap_filtering$seed_positions)) {
    config$analysis$heatmap_filtering$seed_positions
  } else {
    c(2, 3, 4, 5, 6, 7, 8)
  }
  seed_pattern <- paste0("^(", paste(seed_positions, collapse = "|"), "):GT$")
  
  seed_gt_data <- data %>%
    filter(str_detect(pos.mut, seed_pattern))
  
  filtered_mirnas <- unique(seed_gt_data$miRNA_name)
  cat("   ✅ Basic filter: miRNAs with G>T in seed region\n")
  cat("   ✅ Total miRNAs:", length(filtered_mirnas), "\n")
}

# ============================================================================
# PREPARE MATRIX FOR CLUSTERING: Filter SNVs by filtered miRNAs
# ============================================================================

cat("\n📊 Preparing matrix for clustering (filtered by biological criteria)...\n")

# Get all G>T mutations from filtered miRNAs
vaf_gt <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  filter(miRNA_name %in% filtered_mirnas) %>%
  mutate(SNV_ID = paste(miRNA_name, pos.mut, sep = "_"))

# Count unique miRNAs
n_mirnas <- length(unique(vaf_gt$miRNA_name))
cat("   ✅ Total G>T SNVs from filtered miRNAs:", nrow(vaf_gt), "\n")
cat("   ✅ Unique miRNAs with G>T (after filtering):", n_mirnas, "\n")

if (nrow(vaf_gt) == 0) {
  stop("❌ No G>T mutations found after filtering!")
}

# Calculate VAF for each sample: VAF = SNV_Count / Total_Count
cat("   📊 Calculating VAF for each sample (SNV_Count / Total_Count)...\n")

# Initialize VAF matrix
vaf_matrix <- matrix(NA, nrow = nrow(vaf_gt), ncol = length(sample_cols))
rownames(vaf_matrix) <- vaf_gt$SNV_ID
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
    base_name <- gsub("^Magen-", "", snv_col)
    total_candidates <- grep(paste0(base_name, ".*\\(PM\\+1MM\\+2MM\\)"), colnames(data), value = TRUE)
    if (length(total_candidates) > 0) {
      total_col <- total_candidates[1]
    }
  }
  
  # Get SNV counts and Total counts directly from data
  snv_counts <- as.numeric(as.character(vaf_gt[[snv_col]]))
  
  if (total_col %in% colnames(data)) {
    total_counts <- as.numeric(as.character(vaf_gt[[total_col]]))
    
    # Calculate VAF: VAF = SNV_Count / Total_Count (avoid division by zero)
    vaf_values <- ifelse(!is.na(total_counts) & total_counts > 0,
                        snv_counts / total_counts,
                        NA)
    
    # VAF should be <= 0.5 (already filtered in Step 1.5, but double-check)
    vaf_values <- ifelse(!is.na(vaf_values) & vaf_values <= 0.5, vaf_values, NA)
    
    vaf_matrix[, i] <- vaf_values
  } else {
    cat("   ⚠️  Total column not found for", snv_col, "- using raw counts as fallback\n")
    # If no total column found, use raw counts (but this is not ideal)
    vaf_matrix[, i] <- snv_counts
  }
}

# Replace NA with 0 for clustering (temporarily, will filter before final matrix)
vaf_matrix_temp <- vaf_matrix
vaf_matrix_temp[is.na(vaf_matrix_temp)] <- 0

cat("   ✅ Matrix prepared (VAF):", nrow(vaf_matrix_temp), "SNVs ×", ncol(vaf_matrix_temp), "samples\n")
cat("   ✅ Non-zero VAF values:", sum(vaf_matrix_temp > 0), "(", 
    round(100 * sum(vaf_matrix_temp > 0) / length(vaf_matrix_temp), 2), "%)\n")
cat("   ✅ VAF range:", round(min(vaf_matrix_temp[vaf_matrix_temp > 0], na.rm = TRUE), 6), "to", 
    round(max(vaf_matrix_temp, na.rm = TRUE), 6), "\n\n")

# ============================================================================
# ADDITIONAL SNV-LEVEL FILTERING (good G>T quality)
# ============================================================================

cat("📊 Applying SNV-level filters (good G>T quality)...\n")

# Get filtering thresholds from config
filters <- config$analysis$heatmap_filtering
min_snv_mean_vaf <- ifelse(is.null(filters$min_mean_vaf), 0.0, filters$min_mean_vaf)
min_snv_samples_with_vaf <- ifelse(is.null(filters$min_samples_with_vaf), 1, filters$min_samples_with_vaf)

# Calculate per-SNV statistics
snv_stats <- data.frame(
  SNV_ID = rownames(vaf_matrix_temp),
  mean_vaf = rowMeans(vaf_matrix_temp, na.rm = TRUE),
  n_samples_with_vaf = rowSums(vaf_matrix_temp > 0, na.rm = TRUE),
  variance = apply(vaf_matrix_temp, 1, var, na.rm = TRUE)
)

# Filter SNVs by quality thresholds
snvs_filtered <- snv_stats %>%
  filter(
    mean_vaf >= min_snv_mean_vaf,
    n_samples_with_vaf >= min_snv_samples_with_vaf
  ) %>%
  pull(SNV_ID)

vaf_matrix_filtered <- vaf_matrix_temp[snvs_filtered, ]

cat("   ✅ SNVs passing quality filters:", length(snvs_filtered), "(out of", nrow(vaf_matrix_temp), "total)\n")
cat("      - Mean VAF >=", min_snv_mean_vaf, "\n")
cat("      - Detected in >=", min_snv_samples_with_vaf, "samples\n\n")

# ============================================================================
# SELECT MOST VARIABLE SNVs FOR VISUALIZATION (prevents saturation)
# ============================================================================

cat("📊 Selecting most variable SNVs for visualization (prevents saturation)...\n")

# Calculate variance per SNV (from filtered set)
snv_variance_filtered <- apply(vaf_matrix_filtered, 1, var, na.rm = TRUE)

# Select top 1000 most variable for visualization (to prevent saturation)
# But show all if less than 1000
max_snvs <- min(1000, nrow(vaf_matrix_filtered))
top_snvs <- names(sort(snv_variance_filtered, decreasing = TRUE)[1:max_snvs])

vaf_matrix_top <- vaf_matrix_filtered[top_snvs, ]

cat("   ✅ Selected", max_snvs, "most variable SNVs (out of", nrow(vaf_matrix_filtered), "biologically filtered)\n")
cat("   ✅ This prevents saturation while maintaining biological relevance\n")
cat("   ✅ All SNVs shown come from expressed miRNAs with good G>T quality\n\n")

# ============================================================================
# PREPARE ANNOTATION
# ============================================================================

cat("📊 Preparing sample annotations...\n")

annotation_col <- data.frame(
  Group = metadata$Group,
  row.names = metadata$Sample_ID
)

annotation_colors <- list(
  Group = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)
)

cat("   ✅ Annotations ready\n\n")

# ============================================================================
# GENERATE HEATMAP WITH CLUSTERING
# ============================================================================

cat("🎨 Generating clustering heatmap...\n")

# Save as PNG
png("figures_paso2_CLEAN/FIG_2.8_CLUSTERING.png", 
    width = 14, height = 10, units = "in", res = 300)

pheatmap(
  vaf_matrix_top,
  
  # Clustering
  cluster_rows = TRUE,
  cluster_cols = TRUE,
  clustering_distance_rows = "euclidean",
  clustering_distance_cols = "euclidean",
  clustering_method = "ward.D2",
  
  # Display
  show_rownames = FALSE,  # Too many SNVs
  show_colnames = FALSE,  # Don't show sample names (too long and many)
  
  # Colors (blanco a rojo para VAF/oxidación)
  # VAF range: 0 to 0.5 (max VAF after filtering, Step 1.5)
  # Use 100 colors for smooth gradient
  color = colorRampPalette(c("white", "#FFE5E5", "#FF9999", "#FF6666", "#FF3333", "#D62728"))(100),
  
  # Annotations
  annotation_col = annotation_col,
  annotation_colors = annotation_colors,
  
  # Scale (none for raw VAF values)
  scale = "none",  # Show raw VAF values (0 to 0.5, blanco→rojo)
  
  # Gaps
  gaps_col = NULL,
  
  # Borders
  border_color = NA,
  
  # Legend
  legend = TRUE,
  
  # Main title
  main = paste("Hierarchical Clustering of Samples by G>T Profile\n(Biological filtering:",
               n_mirnas, "expressed miRNAs with good G>T;",
               format(nrow(vaf_matrix_filtered), big.mark = ","), "quality SNVs;",
               "showing top", nrow(vaf_matrix_top), "most variable of", ncol(vaf_matrix_top), "samples)"),
  fontsize = 12,
  fontsize_row = 8,
  fontsize_col = 8
)

dev.off()

cat("   ✅ Figure saved: FIG_2.8_CLUSTERING.png\n\n")

# ============================================================================
# CLUSTERING ANALYSIS
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("📊 CLUSTERING ANALYSIS:\n\n")

# Perform clustering on samples
sample_dist <- dist(t(vaf_matrix_top), method = "euclidean")
sample_hclust <- hclust(sample_dist, method = "ward.D2")

# Cut tree to get clusters
clusters_k3 <- cutree(sample_hclust, k = 3)
clusters_k4 <- cutree(sample_hclust, k = 4)

# Analyze cluster composition
cluster_composition_k3 <- data.frame(
  Sample_ID = names(clusters_k3),
  Cluster = clusters_k3
) %>%
  left_join(metadata %>% select(Sample_ID, Group), by = "Sample_ID") %>%
  group_by(Cluster, Group) %>%
  summarise(N = n(), .groups = "drop") %>%
  pivot_wider(names_from = Group, values_from = N, values_fill = 0)

cat("CLUSTER COMPOSITION (k=3):\n")
print(cluster_composition_k3)
cat("\n")

cluster_composition_k4 <- data.frame(
  Sample_ID = names(clusters_k4),
  Cluster = clusters_k4
) %>%
  left_join(metadata %>% select(Sample_ID, Group), by = "Sample_ID") %>%
  group_by(Cluster, Group) %>%
  summarise(N = n(), .groups = "drop") %>%
  pivot_wider(names_from = Group, values_from = N, values_fill = 0)

cat("CLUSTER COMPOSITION (k=4):\n")
print(cluster_composition_k4)
cat("\n")

# ============================================================================
# INTERPRETATION
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("💡 INTERPRETATION:\n\n")

cat("WHAT THIS FIGURE SHOWS:\n")
cat("   • Hierarchical clustering of samples by G>T profile\n")
cat("   • Both row (SNVs) and column (samples) dendrograms\n")
cat("   • VAF-based clustering (VAF = SNV_Count / Total_Count)\n")
cat("   • Biological filtering: miRNAs expressed with good G>T (configurable thresholds)\n")
cat("   • SNV-level filtering: mean VAF and detection frequency thresholds\n")
cat("   • Top 1000 most variable SNVs shown (for clarity, prevents saturation)\n")
cat("   • Raw VAF values (0 to 0.5) with white→red color scale\n")
cat("   • Sample names hidden (too many and too long)\n\n")

cat("EXPECTED PATTERN:\n")
cat("   • If groups differ: ALS and Control samples cluster separately\n")
cat("   • If heterogeneous: Mixed clustering (consistent with PCA)\n\n")

cat("CONSISTENCY CHECK:\n")
cat("   • Should align with Fig 2.7 (PCA: R² = 2%, no clear separation)\n")
cat("   • Should align with Fig 2.9 (high CV in ALS)\n\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("✅ FIGURE 2.8 GENERATED SUCCESSFULLY\n\n")

