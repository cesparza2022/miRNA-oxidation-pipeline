#!/usr/bin/env Rscript
# ============================================================================
# FIGURA 2.1 - COMPARACIÓN LOG vs LINEAR SCALE
# También: Clarificar diferencias entre Panel B y Panel C
# ============================================================================

library(ggplot2)
library(dplyr)
library(tidyr)
library(stringr)
library(patchwork)
library(readr)

# Colores
COLOR_ALS <- "#D62728"
COLOR_CONTROL <- "#666666"

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  FIGURA 2.1 - CLARIFICACIÓN Y COMPARACIÓN\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# ============================================================================
# LOAD DATA
# ============================================================================

cat("📂 Cargando datos...\n")
data <- read_csv("final_processed_data_CLEAN.csv", show_col_types = FALSE)
metadata <- read_csv("metadata.csv", show_col_types = FALSE)

sample_cols <- metadata$Sample_ID

cat("   ✅ Datos cargados\n")
cat("   ✅ Muestras ALS:", sum(metadata$Group == "ALS"), "\n")
cat("   ✅ Muestras Control:", sum(metadata$Group == "Control"), "\n\n")

# ============================================================================
# CALCULATE METRICS
# ============================================================================

cat("🔢 Calculando métricas...\n\n")

# Total VAF por muestra (TODAS las mutaciones)
cat("   PANEL A: Total VAF (suma de TODOS los VAF)\n")
vaf_total <- data %>%
  select(all_of(c("miRNA_name", "pos.mut", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  group_by(Sample_ID) %>%
  summarise(Total_VAF = sum(VAF, na.rm = TRUE), .groups = "drop") %>%
  left_join(metadata, by = "Sample_ID")

cat("   ✅ Total VAF calculado\n")
cat("      Ejemplo: Si una muestra tiene 100 SNVs con VAF promedio 0.01\n")
cat("               Total_VAF = 100 × 0.01 = 1.0\n\n")

# G>T VAF por muestra
cat("   PANEL B: G>T VAF (suma de VAF solo de mutaciones G>T)\n")
vaf_gt <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%  # SOLO G>T
  select(all_of(c("miRNA_name", "pos.mut", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  group_by(Sample_ID) %>%
  summarise(GT_VAF = sum(VAF, na.rm = TRUE), .groups = "drop")

cat("   ✅ G>T VAF calculado\n")
cat("      Ejemplo: Si una muestra tiene 50 SNVs G>T con VAF promedio 0.01\n")
cat("               GT_VAF = 50 × 0.01 = 0.5\n\n")

# Combinar
combined_data <- vaf_total %>%
  left_join(vaf_gt, by = "Sample_ID") %>%
  replace_na(list(GT_VAF = 0)) %>%
  mutate(
    GT_Ratio = GT_VAF / Total_VAF,
    GT_Ratio = replace_na(GT_Ratio, 0)
  )

cat("   PANEL C: G>T Ratio (G>T_VAF / Total_VAF)\n")
cat("   ✅ Ratio calculado\n")
cat("      Ejemplo: Si Total_VAF = 1.0 y GT_VAF = 0.5\n")
cat("               GT_Ratio = 0.5 / 1.0 = 0.5 (50%)\n\n")

# ============================================================================
# CLARIFICATION: What each metric means
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("💡 CLARIFICACIÓN DE MÉTRICAS:\n")
cat("\n")
cat("PANEL A: Total_VAF = Suma de TODOS los VAF\n")
cat("   • Incluye: GT, GC, GA, CT, CA, TA, etc. (12 tipos)\n")
cat("   • Unidad: Suma de proporciones (NO es un porcentaje del 0-100%)\n")
cat("   • Rango típico: 0.1 a 10+ (depende de cuántos SNVs)\n")
cat("   • Interpretación: Burden TOTAL de mutaciones en la muestra\n")
cat("\n")
cat("PANEL B: GT_VAF = Suma de VAF solo de G>T\n")
cat("   • Incluye: SOLO mutaciones G>T\n")
cat("   • Unidad: Suma de proporciones\n")
cat("   • Rango típico: 0.05 a 5+ (subset del Panel A)\n")
cat("   • Interpretación: Burden específico de OXIDACIÓN\n")
cat("   • Relación: GT_VAF ≤ Total_VAF (siempre)\n")
cat("\n")
cat("PANEL C: GT_Ratio = GT_VAF / Total_VAF\n")
cat("   • Cálculo: Proporción de G>T relativo al total\n")
cat("   • Unidad: Fracción (0 a 1, o 0% a 100%)\n")
cat("   • Rango típico: 0.3 a 0.9 (30% a 90%)\n")
cat("   • Interpretación: ESPECIFICIDAD de oxidación\n")
cat("   • Diferencia con VAF individual: Esto NO es el VAF de un SNV,\n")
cat("     es la SUMA de VAFs de G>T dividido por SUMA total de VAFs\n")
cat("\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")

# ============================================================================
# CLARIFICATION 2: Panel B vs Panel C
# ============================================================================

cat("🤔 DIFERENCIA PANEL B vs PANEL C:\n")
cat("\n")
cat("PANEL B: GT_VAF (valor absoluto)\n")
cat("   • Pregunta: ¿Cuánto G>T hay en la muestra? (suma)\n")
cat("   • Unidad: Suma de VAF (puede ser 0.5, 1.0, 5.0, etc.)\n")
cat("   • Depende de: Número de SNVs G>T Y sus frecuencias\n")
cat("   • Ejemplo: Muestra con 100 SNVs G>T (VAF=0.01 cada uno) → GT_VAF = 1.0\n")
cat("\n")
cat("PANEL C: GT_Ratio (valor relativo)\n")
cat("   • Pregunta: ¿Qué PROPORCIÓN del total de mutaciones es G>T?\n")
cat("   • Unidad: Fracción (0-1 o 0%-100%)\n")
cat("   • Independiente de: Número total de SNVs\n")
cat("   • Ejemplo: Muestra con GT_VAF=1.0 y Total_VAF=2.0 → GT_Ratio = 0.5 (50%)\n")
cat("\n")
cat("POR QUÉ SON DIFERENTES:\n")
cat("   • Panel B puede ser ALTO simplemente porque hay muchos SNVs\n")
cat("   • Panel C normaliza por el total → Muestra SELECTIVIDAD\n")
cat("\n")
cat("EJEMPLO CONCRETO:\n")
cat("   Muestra A: Total_VAF=10, GT_VAF=8  → GT_Ratio=0.8 (80% es G>T)\n")
cat("   Muestra B: Total_VAF=2,  GT_VAF=1.5 → GT_Ratio=0.75 (75% es G>T)\n")
cat("\n")
cat("   • Muestra A tiene MÁS G>T absoluto (Panel B: 8 vs 1.5)\n")
cat("   • Pero Muestra A también tiene MAYOR especificidad (Panel C: 80% vs 75%)\n")
cat("\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")

# Stats
cat("📊 ESTADÍSTICAS POR GRUPO:\n\n")
stats_summary <- combined_data %>%
  group_by(Group) %>%
  summarise(
    N = n(),
    Mean_Total_VAF = mean(Total_VAF),
    Median_Total_VAF = median(Total_VAF),
    Mean_GT_VAF = mean(GT_VAF),
    Median_GT_VAF = median(GT_VAF),
    Mean_GT_Ratio = mean(GT_Ratio),
    Median_GT_Ratio = median(GT_Ratio),
    .groups = "drop"
  )
print(stats_summary)
cat("\n")

# Tests
test_total <- wilcox.test(Total_VAF ~ Group, data = combined_data)
test_gt <- wilcox.test(GT_VAF ~ Group, data = combined_data)
test_ratio <- wilcox.test(GT_Ratio ~ Group, data = combined_data)

cat("📊 TESTS (Wilcoxon):\n")
cat("   Panel A (Total VAF): p =", format.pval(test_total$p.value, digits = 3), "\n")
cat("   Panel B (G>T VAF): p =", format.pval(test_gt$p.value, digits = 3), "\n")
cat("   Panel C (G>T Ratio): p =", format.pval(test_ratio$p.value, digits = 3), "\n\n")

# ============================================================================
# VERSION 1: LINEAR SCALE
# ============================================================================

cat("🎨 Versión 1: LINEAR SCALE...\n")

theme_prof <- theme_classic(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5, color = "gray40"),
    axis.title = element_text(face = "bold", size = 11),
    axis.text = element_text(size = 10),
    legend.position = "none",
    panel.grid.major.y = element_line(color = "gray90", linewidth = 0.3)
  )

# Panel A - Linear
panel_a_linear <- ggplot(combined_data, aes(x = Group, y = Total_VAF, fill = Group)) +
  geom_boxplot(alpha = 0.7, outlier.shape = NA, width = 0.6) +
  geom_jitter(width = 0.15, alpha = 0.3, size = 1.2) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  labs(
    title = "A. Total VAF per Sample",
    subtitle = paste0("Wilcoxon p = ", format.pval(test_total$p.value, digits = 3)),
    x = NULL,
    y = "Total VAF (linear scale)"
  ) +
  theme_prof +
  annotate("text", x = 1.5, y = max(combined_data$Total_VAF, na.rm = TRUE) * 0.95,
           label = ifelse(test_total$p.value < 0.05, "***", "ns"),
           size = 6, color = ifelse(test_total$p.value < 0.05, "red", "gray50"))

# Panel B - Linear
panel_b_linear <- ggplot(combined_data, aes(x = Group, y = GT_VAF, fill = Group)) +
  geom_boxplot(alpha = 0.7, outlier.shape = NA, width = 0.6) +
  geom_jitter(width = 0.15, alpha = 0.3, size = 1.2) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  labs(
    title = "B. G>T VAF per Sample",
    subtitle = paste0("Wilcoxon p = ", format.pval(test_gt$p.value, digits = 3)),
    x = NULL,
    y = "G>T VAF (linear scale)"
  ) +
  theme_prof +
  annotate("text", x = 1.5, y = max(combined_data$GT_VAF, na.rm = TRUE) * 0.95,
           label = ifelse(test_gt$p.value < 0.05, "***", "ns"),
           size = 6, color = ifelse(test_gt$p.value < 0.05, "red", "gray50"))

# Panel C - Already linear (ratio 0-1)
panel_c_linear <- ggplot(combined_data, aes(x = Group, y = GT_Ratio, fill = Group)) +
  geom_boxplot(alpha = 0.7, outlier.shape = NA, width = 0.6) +
  geom_jitter(width = 0.15, alpha = 0.3, size = 1.2) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  scale_y_continuous(labels = scales::percent) +
  labs(
    title = "C. G>T Specificity (Fraction)",
    subtitle = paste0("Wilcoxon p = ", format.pval(test_ratio$p.value, digits = 3)),
    x = NULL,
    y = "G>T / Total VAF (%)"
  ) +
  theme_prof +
  annotate("text", x = 1.5, y = max(combined_data$GT_Ratio, na.rm = TRUE) * 0.95,
           label = ifelse(test_ratio$p.value < 0.05, "***", "ns"),
           size = 6, color = ifelse(test_ratio$p.value < 0.05, "red", "gray50"))

# Combine
fig_linear <- (panel_a_linear | panel_b_linear | panel_c_linear)
ggsave("figures_paso2_CLEAN/FIG_2.1_LINEAR_SCALE.png", fig_linear, width = 15, height = 5, dpi = 300, bg = "white")
cat("   ✅ Versión LINEAR guardada\n\n")

# ============================================================================
# VERSION 2: LOG SCALE
# ============================================================================

cat("🎨 Versión 2: LOG SCALE...\n")

# Panel A - Log
panel_a_log <- ggplot(combined_data, aes(x = Group, y = Total_VAF, fill = Group)) +
  geom_boxplot(alpha = 0.7, outlier.shape = NA, width = 0.6) +
  geom_jitter(width = 0.15, alpha = 0.3, size = 1.2) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  scale_y_log10(labels = scales::comma) +
  labs(
    title = "A. Total VAF per Sample",
    subtitle = paste0("Wilcoxon p = ", format.pval(test_total$p.value, digits = 3)),
    x = NULL,
    y = "Total VAF (LOG scale)"
  ) +
  theme_prof +
  annotate("text", x = 1.5, y = max(combined_data$Total_VAF, na.rm = TRUE) * 0.7,
           label = ifelse(test_total$p.value < 0.05, "***", "ns"),
           size = 6, color = ifelse(test_total$p.value < 0.05, "red", "gray50"))

# Panel B - Log
panel_b_log <- ggplot(combined_data, aes(x = Group, y = GT_VAF, fill = Group)) +
  geom_boxplot(alpha = 0.7, outlier.shape = NA, width = 0.6) +
  geom_jitter(width = 0.15, alpha = 0.3, size = 1.2) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  scale_y_log10(labels = scales::comma) +
  labs(
    title = "B. G>T VAF per Sample",
    subtitle = paste0("Wilcoxon p = ", format.pval(test_gt$p.value, digits = 3)),
    x = NULL,
    y = "G>T VAF (LOG scale)"
  ) +
  theme_prof +
  annotate("text", x = 1.5, y = max(combined_data$GT_VAF, na.rm = TRUE) * 0.7,
           label = ifelse(test_gt$p.value < 0.05, "***", "ns"),
           size = 6, color = ifelse(test_gt$p.value < 0.05, "red", "gray50"))

# Panel C - Same (already linear)
panel_c_log <- panel_c_linear

# Combine
fig_log <- (panel_a_log | panel_b_log | panel_c_log)
ggsave("figures_paso2_CLEAN/FIG_2.1_LOG_SCALE.png", fig_log, width = 15, height = 5, dpi = 300, bg = "white")
cat("   ✅ Versión LOG guardada\n\n")

# ============================================================================
# COMPARISON AND RECOMMENDATION
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("📊 COMPARACIÓN LOG vs LINEAR:\n")
cat("\n")

# Calculate value ranges
range_total <- range(combined_data$Total_VAF, na.rm = TRUE)
range_gt <- range(combined_data$GT_VAF, na.rm = TRUE)
fold_diff_total <- range_total[2] / range_total[1]
fold_diff_gt <- range_gt[2] / range_gt[1]

cat("RANGO DE VALORES:\n")
cat("   Panel A (Total VAF):", sprintf("%.4f a %.2f", range_total[1], range_total[2]), "\n")
cat("   Panel B (G>T VAF):", sprintf("%.4f a %.2f", range_gt[1], range_gt[2]), "\n")
cat("   Fold difference Total:", sprintf("%.0f-fold", fold_diff_total), "\n")
cat("   Fold difference G>T:", sprintf("%.0f-fold", fold_diff_gt), "\n")
cat("\n")

cat("RECOMENDACIÓN:\n")
if (fold_diff_total > 100 | fold_diff_gt > 100) {
  cat("   ✅ USAR LOG SCALE\n")
  cat("   Razón: Rango de valores > 100-fold\n")
  cat("   Con linear scale, valores bajos no serían visibles\n")
} else if (fold_diff_total > 10 | fold_diff_gt > 10) {
  cat("   ⚠️  LOG SCALE RECOMENDADA pero no esencial\n")
  cat("   Razón: Rango 10-100 fold\n")
  cat("   Linear funcionaría pero log es más claro\n")
} else {
  cat("   ✅ USAR LINEAR SCALE\n")
  cat("   Razón: Rango de valores < 10-fold\n")
  cat("   Linear scale es más intuitiva\n")
}
cat("\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("✅ DOS VERSIONES GENERADAS:\n")
cat("   1. FIG_2.1_LINEAR_SCALE.png (escala linear)\n")
cat("   2. FIG_2.1_LOG_SCALE.png (escala log)\n")
cat("\n")
cat("📊 Compara ambas y decide cuál comunica mejor!\n")
cat("\n")

