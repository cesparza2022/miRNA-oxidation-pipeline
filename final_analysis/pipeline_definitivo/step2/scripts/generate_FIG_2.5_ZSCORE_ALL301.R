#!/usr/bin/env Rscript
# ============================================================================
# FIGURA 2.5 - Z-SCORE HEATMAP (Filtered by configurable thresholds)
# Z-score normalization per miRNA to identify positional outliers
# Uses miRNAs that pass configurable thresholds (RPM, VAF, seed, significance)
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
cat("  GENERATING FIG 2.5 - Z-SCORE HEATMAP (Threshold-based filtering)\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# ============================================================================
# LOAD CONFIGURATION
# ============================================================================

# Try to get config from Snakemake, otherwise read from YAML
if (exists("snakemake") && !is.null(snakemake@config)) {
  config <- snakemake@config
  cat("📋 Configuration loaded from Snakemake\n")
} else {
  # Try to find config.yaml (relative to script location or current directory)
  config_paths <- c(
    "../../snakemake_pipeline/config/config.yaml",
    "../snakemake_pipeline/config/config.yaml",
    "config/config.yaml",
    "../../../snakemake_pipeline/config/config.yaml"
  )
  config <- NULL
  for (cp in config_paths) {
    if (file.exists(cp)) {
      config <- yaml::read_yaml(cp)
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
  }
}

# ============================================================================
# LOAD COMMON FUNCTIONS
# ============================================================================

# Try to source functions_common.R to get filter_mirnas_for_heatmap()
functions_paths <- c(
  "../../snakemake_pipeline/scripts/utils/functions_common.R",
  "../snakemake_pipeline/scripts/utils/functions_common.R",
  "scripts/utils/functions_common.R"
)
functions_loaded <- FALSE
for (fp in functions_paths) {
  if (file.exists(fp)) {
    source(fp, local = TRUE)
    functions_loaded <- TRUE
    cat("📦 Common functions loaded from:", fp, "\n")
    break
  }
}

if (!functions_loaded) {
  cat("⚠️  functions_common.R not found, filtering will use basic approach\n")
}

# ============================================================================
# LOAD DATA
# ============================================================================

cat("📂 Loading data...\n")
data <- read_csv("final_processed_data_CLEAN.csv", show_col_types = FALSE)
metadata <- read_csv("metadata.csv", show_col_types = FALSE)
sample_cols <- metadata$Sample_ID

# Fix column names if needed
if ("pos:mut" %in% colnames(data) && !"pos.mut" %in% colnames(data)) {
  data$pos.mut <- data$`pos:mut`
}
if ("miRNA name" %in% colnames(data) && !"miRNA_name" %in% colnames(data)) {
  data$miRNA_name <- data$`miRNA name`
}

cat("   ✅ Data loaded\n")

# ============================================================================
# FILTER miRNAs USING CONFIGURABLE THRESHOLDS
# ============================================================================

cat("\n")
cat("🔍 FILTERING miRNAs USING CONFIGURABLE THRESHOLDS\n")
cat("═══════════════════════════════════════════════════════════════════\n")

# Try to load statistical results if available (for significance filtering)
statistical_results <- NULL
stat_paths <- c(
  "../results/step2/tables/statistical_results/S2_statistical_comparisons.csv",
  "../../results/step2/tables/statistical_results/S2_statistical_comparisons.csv",
  "results/step2/tables/statistical_results/S2_statistical_comparisons.csv"
)
for (sp in stat_paths) {
  if (file.exists(sp)) {
    statistical_results <- read_csv(sp, show_col_types = FALSE)
    cat("📊 Statistical results loaded for significance filtering\n")
    break
  }
}

# Try to load RPM data if available (for expression filtering)
rpm_data <- NULL
# RPM data would typically come from expression analysis (Step 5)
# For now, we'll skip RPM filtering if not available

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

all_mirnas <- filtered_mirnas

cat("\n")
cat("   ✅ Final filtered miRNAs:", length(all_mirnas), "\n")
cat("   ✅ Using configurable thresholds (not hardcoded 'top 50')\n\n")

# ============================================================================
# PREPARE DATA: ALL G>T (positions 1-23) for filtered miRNAs
# ============================================================================

cat("📊 Preparing data for", length(all_mirnas), "filtered miRNAs (all positions)...\n")

# Todos los G>T de los miRNAs filtrados (todas las posiciones, no solo seed)
vaf_gt_all <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  filter(miRNA_name %in% all_mirnas) %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^[0-9]+"))) %>%
  select(all_of(c("miRNA_name", "position", sample_cols)))

cat("   ✅ Total observations:", nrow(vaf_gt_all), "\n")
cat("   ✅ Positions covered:", paste(sort(unique(vaf_gt_all$position)), collapse = ", "), "\n\n")

# Calcular VAF promedio por miRNA-position
vaf_summary <- vaf_gt_all %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  left_join(metadata %>% select(Sample_ID, Group), by = "Sample_ID") %>%
  group_by(miRNA_name, position, Group) %>%
  summarise(Mean_VAF = mean(VAF, na.rm = TRUE), .groups = "drop")

# ============================================================================
# CALCULATE Z-SCORES (per miRNA, across positions)
# ============================================================================

cat("📊 Calculating Z-scores (per miRNA normalization)...\n")

# Z-score: Para cada miRNA, normalizar sus posiciones
zscore_data <- vaf_summary %>%
  group_by(miRNA_name, Group) %>%
  mutate(
    Z_score = scale(Mean_VAF)[,1]
  ) %>%
  ungroup()

cat("   ✅ Z-scores calculated\n")
cat("   ✅ Total data points:", nrow(zscore_data), "\n\n")

# Estadísticas de Z-scores
zscore_stats <- zscore_data %>%
  summarise(
    Mean_Z = mean(Z_score, na.rm = TRUE),
    SD_Z = sd(Z_score, na.rm = TRUE),
    Min_Z = min(Z_score, na.rm = TRUE),
    Max_Z = max(Z_score, na.rm = TRUE)
  )

cat("📊 Z-SCORE STATISTICS:\n\n")
print(zscore_stats)
cat("\n")

# ============================================================================
# GENERATE HEATMAP (PROFESSIONAL)
# ============================================================================

cat("🎨 Generating Z-score heatmap...\n")

# Preparar datos para heatmap (2 paneles: ALS y Control)
heatmap_data <- zscore_data %>%
  mutate(
    miRNA_name = factor(miRNA_name, levels = all_mirnas),
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
    axis.text.y = element_blank(),
    legend.title = element_text(size = 11, face = "bold"),
    legend.text = element_text(size = 10),
    legend.position = "right",
    panel.grid = element_blank(),
    strip.text = element_text(size = 13, face = "bold"),
    strip.background = element_rect(fill = "gray90", color = "gray50")
  )

# Heatmap con facet por grupo
# Escala divergente azul→blanco→rojo para z-scores (centrado en 0)
fig_2_5 <- ggplot(heatmap_data, aes(x = position, y = miRNA_name, fill = Z_score)) +
  geom_tile(color = NA) +
  scale_fill_gradient2(
    low = "#1E88E5",  # Blue for negative z-scores
    mid = "white",    # White at zero (midpoint)
    high = COLOR_ALS, # Red (#D62728) for positive z-scores
    midpoint = 0,
    na.value = "gray90",
    limits = c(-3, 3),
    oob = scales::squish,
    name = "Z-score\n(per miRNA)"
  ) +
  facet_wrap(~Group, ncol = 2) +
  # Seed region markers
  geom_vline(xintercept = c(1.5, 8.5), linetype = "dashed", color = "black", linewidth = 0.8, alpha = 0.7) +
  labs(
    title = "Z-Score Normalized G>T VAF by Position",
    subtitle = paste0(length(all_mirnas), " miRNAs passing configurable thresholds | ",
                     "Z-score normalized per miRNA (identifies positional outliers)"),
    x = "Position in miRNA",
    y = paste0("miRNAs (n=", length(all_mirnas), ", filtered by thresholds, ranked by total G>T burden)")
  ) +
  theme_prof

ggsave("figures_paso2_CLEAN/FIG_2.5_ZSCORE_ALL301_PROFESSIONAL.png", 
       fig_2_5, width = 16, height = 18, dpi = 300, bg = "white")

cat("   ✅ Figure saved: FIG_2.5_ZSCORE_ALL301_PROFESSIONAL.png\n\n")

# ============================================================================
# OUTLIER ANALYSIS
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("📊 OUTLIER ANALYSIS (Z-score > 2 or < -2):\n")
cat("\n")

outliers <- zscore_data %>%
  filter(abs(Z_score) > 2)

cat("TOTAL OUTLIERS (|Z| > 2):", nrow(outliers), "\n\n")

cat("OUTLIERS BY GROUP:\n")
outliers_by_group <- outliers %>%
  group_by(Group) %>%
  summarise(
    N_outliers = n(),
    N_positive = sum(Z_score > 2),
    N_negative = sum(Z_score < -2),
    .groups = "drop"
  )
print(outliers_by_group)
cat("\n")

cat("TOP POSITIVE OUTLIERS (highest Z-score):\n")
top_positive <- zscore_data %>%
  arrange(desc(Z_score)) %>%
  head(10) %>%
  select(miRNA_name, position, Group, Z_score, Mean_VAF)
print(top_positive)
cat("\n")

cat("TOP NEGATIVE OUTLIERS (lowest Z-score):\n")
top_negative <- zscore_data %>%
  arrange(Z_score) %>%
  head(10) %>%
  select(miRNA_name, position, Group, Z_score, Mean_VAF)
print(top_negative)
cat("\n")

# ============================================================================
# POSITIONAL OUTLIER ANALYSIS
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("📊 POSITIONAL OUTLIER ANALYSIS:\n")
cat("\n")

outliers_by_position <- outliers %>%
  group_by(position, Group) %>%
  summarise(N_outliers = n(), .groups = "drop") %>%
  pivot_wider(names_from = Group, values_from = N_outliers, values_fill = 0)

cat("OUTLIERS BY POSITION:\n")
print(outliers_by_position)
cat("\n")

# Seed vs non-seed
seed_outliers <- outliers %>%
  filter(position >= 2, position <= 8) %>%
  nrow()

nonseed_outliers <- outliers %>%
  filter(position < 2 | position > 8) %>%
  nrow()

cat("SEED vs NON-SEED OUTLIERS:\n")
cat("   Seed region (2-8):", seed_outliers, "outliers\n")
cat("   Non-seed region:", nonseed_outliers, "outliers\n\n")

# ============================================================================
# INTERPRETATION
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("💡 INTERPRETATION:\n")
cat("\n")

cat("Z-SCORE NORMALIZATION:\n")
cat("   • Per-miRNA normalization identifies POSITIONAL outliers\n")
cat("   • Independent of absolute VAF magnitude\n")
cat("   • Z > 2: Position has unusually HIGH G>T for that miRNA\n")
cat("   • Z < -2: Position has unusually LOW G>T for that miRNA\n\n")

cat("WHAT THIS FIGURE SHOWS:\n")
cat("   • Which positions are atypical WITHIN each miRNA\n")
cat("   • Hotspots and coldspots (relative to miRNA baseline)\n")
cat("   • Complements Fig 2.4 (raw values) and Fig 2.6 (positional means)\n\n")

cat("COMPARISON WITH OTHER FIGURES:\n")
cat("   • Fig 2.4: Absolute VAF values\n")
cat("   • Fig 2.5: Z-score (positional outliers) ⭐\n")
cat("   • Fig 2.6: Positional means (averaged)\n")
cat("   → COMPLEMENTARY perspectives\n\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("✅ FIGURE GENERATED:\n\n")
cat("   FIG_2.5_ZSCORE_ALL301_PROFESSIONAL.png\n")
cat("      →", length(all_mirnas), "miRNAs (filtered by configurable thresholds)\n")
cat("      → All positions (not just seed)\n")
cat("      → Z-score normalized per miRNA\n")
cat("      → 2 panels: ALS vs Control\n")
cat("      → Blue = below miRNA average\n")
cat("      → Red = above miRNA average\n")
cat("      → Seed region marked (positions 2-8)\n")
cat("      → Thresholds configurable in config.yaml\n\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")

