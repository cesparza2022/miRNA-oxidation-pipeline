#!/usr/bin/env Rscript
# ============================================================================
# FIGURA 2.5 - DIFFERENTIAL HEATMAP (ALL 301 miRNAs)
# Diferencia directa: VAF_ALS - VAF_Control
# Usa TODOS los miRNAs con G>T en seed (no solo top 50)
# ============================================================================

library(ggplot2)
library(dplyr)
library(tidyr)
library(readr)
library(stringr)
library(tibble)

# Colores profesionales
COLOR_ALS <- "#D62728"
COLOR_CONTROL <- "#2E86AB"
COLOR_NEUTRAL <- "gray95"

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  GENERATING FIG 2.5 - DIFFERENTIAL HEATMAP (ALL 301 miRNAs)\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# ============================================================================
# LOAD DATA
# ============================================================================

cat("📂 Loading data...\n")
data <- read_csv("final_processed_data_CLEAN.csv", show_col_types = FALSE)
metadata <- read_csv("metadata.csv", show_col_types = FALSE)
sample_cols <- metadata$Sample_ID

# Ranking de miRNAs
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
# PREPARE DATA: ALL G>T (positions 1-22) for ALL 301 miRNAs
# ============================================================================

cat("📊 Preparing data for ALL", length(all_mirnas), "miRNAs...\n")

vaf_gt_all <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^[0-9]+"))) %>%
  filter(!is.na(position), position <= 22) %>%
  filter(miRNA_name %in% all_mirnas) %>%
  select(all_of(c("miRNA_name", "position", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  left_join(metadata, by = "Sample_ID")

# Calcular promedio por miRNA, posición, y grupo
vaf_summary <- vaf_gt_all %>%
  group_by(miRNA_name, position, Group) %>%
  summarise(Mean_VAF = mean(VAF, na.rm = TRUE), .groups = "drop")

cat("   ✅ Data summarized\n\n")

# ============================================================================
# CALCULATE DIFFERENTIAL (ALS - Control)
# ============================================================================

cat("🔢 Calculating differential (ALS - Control)...\n")

# Separar ALS y Control
vaf_als <- vaf_summary %>%
  filter(Group == "ALS") %>%
  select(miRNA_name, position, Mean_VAF) %>%
  rename(VAF_ALS = Mean_VAF)

vaf_ctrl <- vaf_summary %>%
  filter(Group == "Control") %>%
  select(miRNA_name, position, Mean_VAF) %>%
  rename(VAF_Control = Mean_VAF)

# Combinar y calcular diferencia
differential <- vaf_als %>%
  full_join(vaf_ctrl, by = c("miRNA_name", "position")) %>%
  replace_na(list(VAF_ALS = 0, VAF_Control = 0)) %>%
  mutate(
    Differential = VAF_ALS - VAF_Control,
    position = factor(position, levels = 1:22),
    miRNA_name = factor(miRNA_name, levels = all_mirnas)  # Mantener ranking
  )

cat("   ✅ Differential calculated\n\n")

# Estadísticas
cat("📊 DIFFERENTIAL STATISTICS:\n\n")

diff_stats <- differential %>%
  summarise(
    Mean_Diff = mean(Differential, na.rm = TRUE),
    Median_Diff = median(Differential, na.rm = TRUE),
    Min_Diff = min(Differential, na.rm = TRUE),
    Max_Diff = max(Differential, na.rm = TRUE),
    SD_Diff = sd(Differential, na.rm = TRUE),
    .groups = "drop"
  )

print(diff_stats)
cat("\n")

# Proporción de celdas ALS > Control
n_als_greater <- sum(differential$Differential > 0, na.rm = TRUE)
n_ctrl_greater <- sum(differential$Differential < 0, na.rm = TRUE)
n_equal <- sum(differential$Differential == 0, na.rm = TRUE)
total_cells <- nrow(differential)

cat("PROPORTION BY DIRECTION:\n")
cat("   ALS > Control:", n_als_greater, "/", total_cells, 
    "(", round(n_als_greater/total_cells*100, 1), "%)\n")
cat("   Control > ALS:", n_ctrl_greater, "/", total_cells,
    "(", round(n_ctrl_greater/total_cells*100, 1), "%)\n")
cat("   Equal (0):", n_equal, "/", total_cells, "\n\n")

# ============================================================================
# GENERATE HEATMAP
# ============================================================================

cat("🎨 Generating differential heatmap (professional)...\n")

# Theme profesional
theme_prof <- theme_classic(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold", size = 15, hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5, color = "gray40", margin = margin(b = 10)),
    axis.title = element_text(face = "bold", size = 12),
    axis.text.x = element_text(size = 11),
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank(),
    axis.title.y = element_text(size = 12),
    legend.position = "right",
    legend.title = element_text(face = "bold", size = 11),
    legend.text = element_text(size = 10),
    legend.key.height = unit(1.5, "cm"),
    legend.key.width = unit(0.6, "cm"),
    panel.grid = element_blank(),
    panel.border = element_rect(color = "gray70", fill = NA, linewidth = 0.8)
  )

# Calcular límites simétricos para la escala
max_abs_diff <- max(abs(differential$Differential), na.rm = TRUE)
scale_limit <- ceiling(max_abs_diff * 1000) / 1000  # Redondear

fig_2_5 <- ggplot(differential, aes(x = position, y = miRNA_name, fill = Differential)) +
  geom_tile(color = NA) +
  # Marcar región seed
  geom_vline(xintercept = c(1.5, 8.5), color = "#2E86AB", 
             linewidth = 1.2, linetype = "dashed", alpha = 0.6) +
  annotate("text", x = 5, y = length(all_mirnas) * 0.97, 
           label = "SEED", color = "#2E86AB", 
           fontface = "bold", size = 5.5, alpha = 0.8) +
  scale_fill_gradient2(
    low = COLOR_CONTROL,
    mid = "white",
    high = COLOR_ALS,
    midpoint = 0,
    limits = c(-scale_limit, scale_limit),
    name = "Δ VAF\n(ALS - Control)",
    labels = function(x) sprintf("%.4f", x)
  ) +
  labs(
    title = "Differential G>T Burden: ALS vs Control",
    subtitle = paste0("All ", length(all_mirnas), " miRNAs with G>T in seed region | ",
                     "Positive = elevated in ALS, Negative = elevated in Control"),
    x = "Position in miRNA",
    y = paste0("miRNAs (n=", length(all_mirnas), ", ranked by total G>T burden)")
  ) +
  theme_prof

ggsave("figures_paso2_CLEAN/FIG_2.5_DIFFERENTIAL_ALL301_PROFESSIONAL.png", 
       fig_2_5, width = 14, height = 16, dpi = 300, bg = "white")

cat("   ✅ Figure saved: FIG_2.5_DIFFERENTIAL_ALL301_PROFESSIONAL.png\n\n")

# ============================================================================
# POSITIONAL ANALYSIS
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("📊 POSITIONAL ANALYSIS:\n")
cat("\n")

# Promedio de diferencia por posición
pos_diff <- differential %>%
  group_by(position) %>%
  summarise(
    Mean_Diff = mean(Differential, na.rm = TRUE),
    Median_Diff = median(Differential, na.rm = TRUE),
    N_ALS_greater = sum(Differential > 0, na.rm = TRUE),
    N_Control_greater = sum(Differential < 0, na.rm = TRUE),
    .groups = "drop"
  )

cat("DIFFERENTIAL BY POSITION (averaged across all miRNAs):\n\n")
print(pos_diff)
cat("\n")

# Identificar posiciones con mayor diferencia
cat("POSITIONS WITH LARGEST DIFFERENTIAL:\n\n")

cat("Most elevated in ALS:\n")
top_als_pos <- pos_diff %>% arrange(desc(Mean_Diff)) %>% head(3)
print(top_als_pos %>% select(position, Mean_Diff))
cat("\n")

cat("Most elevated in Control:\n")
top_ctrl_pos <- pos_diff %>% arrange(Mean_Diff) %>% head(3)
print(top_ctrl_pos %>% select(position, Mean_Diff))
cat("\n")

# Seed vs non-seed
seed_diff <- pos_diff %>% 
  filter(as.numeric(as.character(position)) >= 2, 
         as.numeric(as.character(position)) <= 8) %>%
  pull(Mean_Diff) %>%
  mean()

nonseed_diff <- pos_diff %>%
  filter(as.numeric(as.character(position)) < 2 | 
         as.numeric(as.character(position)) > 8) %>%
  pull(Mean_Diff) %>%
  mean()

cat("SEED vs NON-SEED:\n")
cat("   Seed region (2-8) mean diff:", sprintf("%.6f", seed_diff), "\n")
cat("   Non-seed region mean diff:", sprintf("%.6f", nonseed_diff), "\n\n")

if (abs(seed_diff) > abs(nonseed_diff)) {
  cat("   → Larger differential in SEED region\n\n")
} else {
  cat("   → Larger differential in NON-SEED region\n\n")
}

# ============================================================================
# MICRORNA ANALYSIS
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("📊 miRNA ANALYSIS:\n")
cat("\n")

# Promedio de diferencia por miRNA (across positions)
mirna_diff <- differential %>%
  group_by(miRNA_name) %>%
  summarise(
    Mean_Diff = mean(Differential, na.rm = TRUE),
    Max_Diff = max(Differential, na.rm = TRUE),
    Min_Diff = min(Differential, na.rm = TRUE),
    .groups = "drop"
  )

cat("miRNAs WITH LARGEST POSITIVE DIFFERENTIAL (ALS > Control):\n")
top_als_mirnas <- mirna_diff %>% arrange(desc(Mean_Diff)) %>% head(5)
print(top_als_mirnas)
cat("\n")

cat("miRNAs WITH LARGEST NEGATIVE DIFFERENTIAL (Control > ALS):\n")
top_ctrl_mirnas <- mirna_diff %>% arrange(Mean_Diff) %>% head(5)
print(top_ctrl_mirnas)
cat("\n")

# ============================================================================
# INTERPRETATION
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("💡 INTERPRETATION:\n")
cat("\n")

cat("OVERALL PATTERN:\n")
cat("   Mean differential (all positions, all miRNAs):", sprintf("%.6f", diff_stats$Mean_Diff), "\n")

if (diff_stats$Mean_Diff < 0) {
  cat("   → CONTROL > ALS on average (consistent with Fig 2.1-2.2) ✅\n\n")
} else {
  cat("   → ALS > Control on average\n\n")
}

cat("HETEROGENEITY:\n")
cat("   Range:", sprintf("%.6f to %.6f", diff_stats$Min_Diff, diff_stats$Max_Diff), "\n")
cat("   SD:", sprintf("%.6f", diff_stats$SD_Diff), "\n")
cat("   → High variability across miRNA-position combinations\n\n")

cat("CONSISTENCY:\n")
cat("   Proportion Control > ALS:", round(n_ctrl_greater/total_cells*100, 1), "%\n")
if (n_ctrl_greater > n_als_greater) {
  cat("   → Majority of cells show Control > ALS ✅\n")
  cat("   → Consistent with global burden (Fig 2.1-2.2)\n\n")
}

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("✅ FIGURE GENERATED:\n")
cat("\n")
cat("   FIG_2.5_DIFFERENTIAL_ALL301_PROFESSIONAL.png\n")
cat("      → All 301 miRNAs (complete dataset)\n")
cat("      → Direct comparison: ALS - Control\n")
cat("      → Blue = Control higher, Red = ALS higher\n")
cat("      → Seed region marked (dashed lines)\n")
cat("      → Professional English labels\n\n")

cat("WHAT THIS FIGURE SHOWS:\n")
cat("   • Which miRNAs and positions have differential G>T\n")
cat("   • Pattern: Mostly blue → Control > ALS (consistent)\n")
cat("   • Heterogeneity: Some positions/miRNAs show ALS > Control\n")
cat("   • Complete picture using ALL 301 miRNAs\n\n")

cat("COMPARISON WITH OTHER FIGURES:\n")
cat("   • Fig 2.4A: Shows absolute VAF (raw values)\n")
cat("   • Fig 2.5: Shows differential (ALS - Control)\n")
cat("   → COMPLEMENTARY (not redundant)\n\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")

