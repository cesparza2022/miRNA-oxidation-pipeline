#!/usr/bin/env Rscript
# ============================================================================
# FIGURA 2.5 - Z-SCORE HEATMAP (ALL 301 miRNAs, ALL positions)
# Z-score normalization per miRNA to identify positional outliers
# Uses ALL miRNAs with G>T in seed (301) but shows ALL their positions
# ============================================================================

library(ggplot2)
library(dplyr)
library(tidyr)
library(readr)
library(stringr)
library(tibble)
library(viridis)

# Colores profesionales
COLOR_ALS <- "#D62728"
COLOR_CONTROL <- "#2E86AB"

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  GENERATING FIG 2.5 - Z-SCORE HEATMAP (ALL 301 miRNAs)\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# ============================================================================
# LOAD DATA
# ============================================================================

cat("📂 Loading data...\n")
data <- read_csv("final_processed_data_CLEAN.csv", show_col_types = FALSE)
metadata <- read_csv("metadata.csv", show_col_types = FALSE)
sample_cols <- metadata$Sample_ID

# Identificar miRNAs con G>T en seed
seed_gt_data <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^[0-9]+"))) %>%
  filter(position >= 2, position <= 8)

seed_gt_summary <- seed_gt_data %>%
  select(all_of(c("miRNA_name", "pos.mut", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  group_by(miRNA_name) %>%
  summarise(Total_VAF = sum(VAF, na.rm = TRUE), .groups = "drop") %>%
  arrange(desc(Total_VAF))

all_mirnas <- seed_gt_summary$miRNA_name  # TODOS los 301

cat("   ✅ Data loaded\n")
cat("   ✅ Total miRNAs with G>T in seed:", length(all_mirnas), "\n\n")

# ============================================================================
# PREPARE DATA: ALL G>T (positions 1-23) for ALL 301 miRNAs
# ============================================================================

cat("📊 Preparing data for ALL", length(all_mirnas), "miRNAs (all positions)...\n")

# Todos los G>T de los 301 miRNAs (todas las posiciones, no solo seed)
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
fig_2_5 <- ggplot(heatmap_data, aes(x = position, y = miRNA_name, fill = Z_score)) +
  geom_tile(color = NA) +
  scale_fill_gradient2(
    low = COLOR_CONTROL,
    mid = "white",
    high = COLOR_ALS,
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
    subtitle = paste0("All ", length(all_mirnas), " miRNAs with G>T in seed region | ",
                     "Z-score normalized per miRNA (identifies positional outliers)"),
    x = "Position in miRNA",
    y = paste0("miRNAs (n=", length(all_mirnas), ", ranked by total G>T burden)")
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
cat("      → All 301 miRNAs (complete dataset)\n")
cat("      → All positions (not just seed)\n")
cat("      → Z-score normalized per miRNA\n")
cat("      → 2 panels: ALS vs Control\n")
cat("      → Blue = below miRNA average\n")
cat("      → Red = above miRNA average\n")
cat("      → Seed region marked (positions 2-8)\n\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")

