#!/usr/bin/env Rscript
# ============================================================================
# FIGURA 2.4 - HEATMAP RAW VAF (Configurable thresholds, not "top 50")
# Raw VAF values with hierarchical clustering
# Uses configurable thresholds instead of arbitrary "top 50"
# ============================================================================

library(ggplot2)
library(dplyr)
library(tidyr)
library(readr)
library(stringr)
library(tibble)
library(viridis)
library(yaml)

# Colores profesionales
COLOR_ALS <- "#D62728"
COLOR_CONTROL <- "#2E86AB"

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  GENERATING FIG 2.4 - RAW VAF HEATMAP (Configurable Thresholds)\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# ============================================================================
# LOAD CONFIGURATION AND FUNCTIONS
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
        )
      ),
      alpha = 0.05
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

# Try to source functions_common.R to get filter_mirnas_for_heatmap()
functions_paths <- c()
if (!is.null(snakemake_dir)) {
  functions_paths <- c(
    file.path(snakemake_dir, "scripts/utils/functions_common.R")
  )
}
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
# LOAD DATA
# ============================================================================

cat("\n")
cat("📂 Loading data...\n")
data <- read_csv("final_processed_data_CLEAN.csv", show_col_types = FALSE)
metadata <- read_csv("metadata.csv", show_col_types = FALSE)
sample_cols <- metadata$Sample_ID

cat("   ✅ Data loaded:", nrow(data), "rows\n")
cat("   ✅ Samples:", length(sample_cols), "\n\n")

# ============================================================================
# FILTER miRNAs USING CONFIGURABLE THRESHOLDS
# ============================================================================

cat("🔍 FILTERING miRNAs USING CONFIGURABLE THRESHOLDS:\n")
cat("   (Replacing arbitrary 'top 50' with biological filtering)\n\n")

# Use filter_mirnas_for_heatmap() if available, otherwise use basic filtering
if (functions_loaded && exists("filter_mirnas_for_heatmap")) {
  filtered_mirnas <- filter_mirnas_for_heatmap(
    data = data,
    metadata = metadata,
    config = config,
    sample_cols = sample_cols,
    statistical_results = statistical_results,
    rpm_data = rpm_data
  )
  n_mirnas <- length(filtered_mirnas)
  cat("\n   ✅ Filtered miRNAs:", n_mirnas, "\n\n")
} else {
  # Fallback: Basic filtering (G>T in seed region)
  cat("   ⚠️  Using basic filtering (G>T in seed region)\n")
  seed_positions <- if (!is.null(config$analysis$heatmap_filtering$seed_positions)) {
    config$analysis$heatmap_filtering$seed_positions
  } else {
    c(2, 3, 4, 5, 6, 7, 8)
  }
  seed_pattern <- paste0("^(", paste(seed_positions, collapse = "|"), "):GT$")
  
  seed_gt_data <- data %>%
    filter(str_detect(pos.mut, seed_pattern)) %>%
    distinct(miRNA_name) %>%
    pull(miRNA_name)
  
  filtered_mirnas <- seed_gt_data
  n_mirnas <- length(filtered_mirnas)
  cat("   ✅ miRNAs with G>T in seed region:", n_mirnas, "\n\n")
}

# ============================================================================
# PREPARE DATA: ALL G>T for FILTERED miRNAs
# ============================================================================

cat("📊 Preparing data for", n_mirnas, "filtered miRNAs (all positions)...\n")

vaf_gt_all <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  filter(miRNA_name %in% filtered_mirnas) %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^[0-9]+"))) %>%
  select(all_of(c("miRNA_name", "position", sample_cols)))

cat("   ✅ Total observations:", nrow(vaf_gt_all), "\n\n")

# Calcular VAF promedio por miRNA-position-group
vaf_summary <- vaf_gt_all %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  left_join(metadata %>% select(Sample_ID, Group), by = "Sample_ID") %>%
  group_by(miRNA_name, position, Group) %>%
  summarise(Mean_VAF = mean(VAF, na.rm = TRUE), .groups = "drop")

cat("   ✅ Data summarized\n\n")

# Rank miRNAs by total G>T burden for visualization
mirna_ranking <- vaf_summary %>%
  group_by(miRNA_name) %>%
  summarise(Total_VAF = sum(Mean_VAF, na.rm = TRUE), .groups = "drop") %>%
  arrange(desc(Total_VAF)) %>%
  pull(miRNA_name)

# ============================================================================
# STATISTICS
# ============================================================================

cat("📊 RAW VAF STATISTICS:\n\n")

vaf_stats <- vaf_summary %>%
  group_by(Group) %>%
  summarise(
    Mean_VAF = mean(Mean_VAF, na.rm = TRUE),
    Median_VAF = median(Mean_VAF, na.rm = TRUE),
    Min_VAF = min(Mean_VAF, na.rm = TRUE),
    Max_VAF = max(Mean_VAF, na.rm = TRUE),
    SD_VAF = sd(Mean_VAF, na.rm = TRUE),
    .groups = "drop"
  )

print(vaf_stats)
cat("\n")

# ============================================================================
# GENERATE HEATMAP (PROFESSIONAL - WHITE TO RED FOR VAF)
# ============================================================================

cat("🎨 Generating RAW VAF heatmap (white→red color scale)...\n")

# Preparar datos para heatmap
heatmap_data <- vaf_summary %>%
  mutate(
    miRNA_name = factor(miRNA_name, levels = mirna_ranking),
    position = factor(position, levels = sort(unique(position))),
    Group = factor(Group, levels = c("ALS", "Control"))
  )

# Theme profesional
theme_prof <- theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(size = 18, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5, color = "gray30"),
    axis.title = element_text(size = 13, face = "bold"),
    axis.text.x = element_text(size = 10, angle = 0, hjust = 0.5),
    axis.text.y = element_blank(),  # Too many miRNAs to show names
    legend.title = element_text(size = 11, face = "bold"),
    legend.text = element_text(size = 10),
    legend.position = "right",
    panel.grid = element_blank(),
    strip.text = element_text(size = 13, face = "bold"),
    strip.background = element_rect(fill = "gray90", color = "gray50")
  )

# Heatmap con facet por grupo - WHITE TO RED color scale
fig_2_4 <- ggplot(heatmap_data, aes(x = position, y = miRNA_name, fill = Mean_VAF)) +
  geom_tile(color = NA) +
  scale_fill_gradientn(
    colors = colorRampPalette(c("white", "#FFE5E5", "#FF9999", "#FF6666", "#FF3333", "#D62728"))(100),
    na.value = "gray90",
    name = "Mean VAF",
    trans = "sqrt",  # Sqrt scale for better visibility of low VAF values
    breaks = c(0, 0.001, 0.01, 0.1, 0.3),
    labels = c("0", "0.001", "0.01", "0.1", "0.3")
  ) +
  facet_wrap(~Group, ncol = 2) +
  # Seed region markers
  geom_vline(xintercept = c(1.5, 8.5), linetype = "dashed", color = "white", linewidth = 0.8, alpha = 0.9) +
  labs(
    title = "Raw G>T VAF by Position",
    subtitle = paste0(n_mirnas, " miRNAs (filtered by configurable thresholds) | ",
                     "Mean VAF across samples (sqrt scale, white→red for oxidation)"),
    x = "Position in miRNA",
    y = paste0("miRNAs (n=", n_mirnas, ", ranked by total G>T burden)")
  ) +
  theme_prof

ggsave("figures_paso2_CLEAN/FIG_2.4_HEATMAP_TOP50_CLEAN.png", 
       fig_2_4, width = 16, height = max(10, min(18, 8 + n_mirnas * 0.05)), dpi = 300, bg = "white")

cat("   ✅ Figure saved: FIG_2.4_HEATMAP_TOP50_CLEAN.png\n\n")

# ============================================================================
# POSITIONAL ANALYSIS
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("📊 POSITIONAL ANALYSIS:\n\n")

pos_summary <- vaf_summary %>%
  group_by(position, Group) %>%
  summarise(
    Mean_VAF = mean(Mean_VAF, na.rm = TRUE),
    N_nonzero = sum(Mean_VAF > 0, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  pivot_wider(names_from = Group, values_from = c(Mean_VAF, N_nonzero))

cat("MEAN VAF BY POSITION:\n")
print(pos_summary)
cat("\n")

# Hotspots
top_positions <- pos_summary %>%
  mutate(Total_VAF = Mean_VAF_ALS + Mean_VAF_Control) %>%
  arrange(desc(Total_VAF)) %>%
  head(5)

cat("TOP 5 HOTSPOT POSITIONS (highest total VAF):\n")
print(top_positions %>% select(position, Mean_VAF_ALS, Mean_VAF_Control, Total_VAF))
cat("\n")

# ============================================================================
# INTERPRETATION
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("💡 INTERPRETATION:\n\n")

cat("WHAT THIS FIGURE SHOWS:\n")
cat("   • Absolute VAF values (raw, not normalized)\n")
cat("   • Direct comparison ALS vs Control (side-by-side)\n")
cat("   • Hierarchical structure (miRNAs ranked by burden)\n")
cat("   • Sqrt scale for better visibility of low VAF values\n")
cat("   • White→red color scale for VAF (oxidation intensity)\n")
cat("   • Filtered by configurable thresholds (not arbitrary 'top 50')\n\n")

cat("FILTERING CRITERIA:\n")
if (functions_loaded && exists("filter_mirnas_for_heatmap")) {
  filters <- config$analysis$heatmap_filtering
  cat("   • Seed G>T required:", filters$require_seed_gt, "\n")
  if (!is.null(filters$min_rpm_mean) && !is.na(filters$min_rpm_mean)) {
    cat("   • Min RPM:", filters$min_rpm_mean, "\n")
  }
  cat("   • Min mean VAF:", filters$min_mean_vaf, "\n")
  cat("   • Min samples with VAF:", filters$min_samples_with_vaf, "\n")
  if (isTRUE(filters$require_significance)) {
    cat("   • Significance required: TRUE\n")
  }
} else {
  cat("   • Basic filtering: G>T in seed region only\n")
}
cat("\n")

cat("COMPARISON WITH OTHER FIGURES:\n")
cat("   • Fig 2.4: RAW values (absolute, filtered by thresholds) ⭐ THIS ONE\n")
cat("   • Fig 2.5: Z-score (normalized, outliers)\n")
cat("   • Fig 2.6: Positional means (averaged profiles)\n")
cat("   → COMPLEMENTARY perspectives\n\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("✅ FIGURE 2.4 GENERATED SUCCESSFULLY\n\n")
