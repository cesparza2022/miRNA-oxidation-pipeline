#!/usr/bin/env Rscript
# ============================================================================
# FIGURA 2.2 SIMPLIFICADA - SOLO DENSITY PLOT
# Comparación LINEAR vs LOG scale
# ============================================================================

library(ggplot2)
library(dplyr)
library(tidyr)
library(readr)
library(stringr)

# Colores
COLOR_ALS <- "#D62728"
COLOR_CONTROL <- "#666666"

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  FIGURA 2.2 - DENSITY PLOT DE G>T VAF\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# ============================================================================
# LOAD DATA
# ============================================================================

cat("📂 Cargando datos...\n")
data <- read_csv("final_processed_data_CLEAN.csv", show_col_types = FALSE)
metadata <- read_csv("metadata.csv", show_col_types = FALSE)
sample_cols <- metadata$Sample_ID

# Filtrar solo G>T
vaf_gt_all <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  select(all_of(c("miRNA_name", "pos.mut", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  left_join(metadata, by = "Sample_ID")

# Total G>T VAF por muestra
vaf_summary <- vaf_gt_all %>%
  group_by(Sample_ID, Group) %>%
  summarise(Total_GT_VAF = sum(VAF, na.rm = TRUE), .groups = "drop")

cat("   ✅ Datos cargados y procesados\n")
cat("   ✅ Muestras ALS:", sum(vaf_summary$Group == "ALS"), "\n")
cat("   ✅ Muestras Control:", sum(vaf_summary$Group == "Control"), "\n\n")

# ============================================================================
# ¿QUÉ NOS DICE ESTA GRÁFICA?
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("💡 ¿QUÉ NOS DICE EL DENSITY PLOT?\n")
cat("\n")
cat("INFORMACIÓN QUE APORTA:\n")
cat("\n")
cat("1. FORMA DE LA DISTRIBUCIÓN:\n")
cat("   • ¿Es normal (campana)?\n")
cat("   • ¿Es sesgada (skewed)?\n")
cat("   • ¿Tiene múltiples picos (bimodal)?\n")
cat("   • Ejemplo: Si Control es bimodal → Puede haber subgrupos\n")
cat("\n")
cat("2. POSICIÓN DE LOS PICOS:\n")
cat("   • ¿Dónde está el pico de cada grupo?\n")
cat("   • ¿ALS tiene pico más alto o bajo que Control?\n")
cat("   • Ejemplo: Pico de ALS a la izquierda → Valores menores\n")
cat("\n")
cat("3. DISPERSIÓN (SPREAD):\n")
cat("   • ¿Qué grupo tiene distribución más ancha?\n")
cat("   • Mayor spread → Mayor variabilidad entre muestras\n")
cat("   • Ejemplo: Control más ancho → Control más heterogéneo\n")
cat("\n")
cat("4. SUPERPOSICIÓN:\n")
cat("   • ¿Cuánto se superponen las dos distribuciones?\n")
cat("   • Mucha superposición → Grupos similares\n")
cat("   • Poca superposición → Grupos bien separados\n")
cat("   • Ejemplo: 50% overlap → Cierta separación pero no total\n")
cat("\n")
cat("DIFERENCIA CON BOXPLOT (Fig 2.1 Panel B):\n")
cat("   • Boxplot: Muestra mediana, cuartiles, outliers\n")
cat("   • Density: Muestra TODA la forma de la distribución\n")
cat("   • Density detecta: bimodalidad, asimetría, colas\n")
cat("   • Boxplot es más simple, Density es más informativa\n")
cat("\n")
cat("PREGUNTA QUE RESPONDE:\n")
cat("   '¿Las distribuciones de G>T VAF son DIFERENTES entre ALS y Control?'\n")
cat("   '¿Y en qué aspectos difieren: posición, forma, o dispersión?'\n")
cat("\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")

# ============================================================================
# ESTADÍSTICAS
# ============================================================================

cat("📊 ESTADÍSTICAS:\n\n")

# Por grupo
stats_by_group <- vaf_summary %>%
  group_by(Group) %>%
  summarise(
    N = n(),
    Mean = mean(Total_GT_VAF),
    Median = median(Total_GT_VAF),
    SD = sd(Total_GT_VAF),
    Min = min(Total_GT_VAF),
    Max = max(Total_GT_VAF),
    Q25 = quantile(Total_GT_VAF, 0.25),
    Q75 = quantile(Total_GT_VAF, 0.75),
    .groups = "drop"
  )
print(stats_by_group)
cat("\n")

# Test
test_result <- wilcox.test(Total_GT_VAF ~ Group, data = vaf_summary)
cat("📊 Wilcoxon test: p =", format.pval(test_result$p.value, digits = 3), "\n\n")

# Calcular overlap (aproximado)
als_vals <- vaf_summary %>% filter(Group == "ALS") %>% pull(Total_GT_VAF)
ctrl_vals <- vaf_summary %>% filter(Group == "Control") %>% pull(Total_GT_VAF)

overlap_min <- max(min(als_vals), min(ctrl_vals))
overlap_max <- min(max(als_vals), max(ctrl_vals))
overlap_prop <- (overlap_max - overlap_min) / (max(max(als_vals), max(ctrl_vals)) - min(min(als_vals), min(ctrl_vals)))

cat("📊 Superposición aproximada:", round(overlap_prop * 100, 1), "%\n\n")

# ============================================================================
# TEMA PROFESIONAL
# ============================================================================

theme_prof <- theme_classic(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5, color = "gray40"),
    axis.title = element_text(face = "bold", size = 12),
    axis.text = element_text(size = 11),
    legend.position = c(0.85, 0.85),
    legend.background = element_rect(fill = "white", color = "gray80"),
    legend.title = element_text(face = "bold", size = 11),
    legend.text = element_text(size = 10),
    panel.grid.major = element_line(color = "gray90", linewidth = 0.3)
  )

# ============================================================================
# VERSION 1: LINEAR SCALE
# ============================================================================

cat("🎨 Generando versión LINEAR...\n")

fig_linear <- ggplot(vaf_summary, aes(x = Total_GT_VAF, fill = Group, color = Group)) +
  geom_density(alpha = 0.4, linewidth = 1) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  scale_color_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  labs(
    title = "Distribution of Total G>T VAF per Sample",
    subtitle = paste0("Wilcoxon p = ", format.pval(test_result$p.value, digits = 3)),
    x = "Total G>T VAF (linear scale)",
    y = "Density",
    fill = "Group",
    color = "Group"
  ) +
  theme_prof +
  annotate("text", x = max(vaf_summary$Total_GT_VAF) * 0.7, 
           y = Inf, vjust = 1.5,
           label = paste0("Overlap: ~", round(overlap_prop * 100, 0), "%"),
           size = 4, color = "gray30")

ggsave("figures_paso2_CLEAN/FIG_2.2_DENSITY_LINEAR.png", fig_linear, 
       width = 10, height = 6, dpi = 300, bg = "white")
cat("   ✅ Versión LINEAR guardada\n\n")

# ============================================================================
# VERSION 2: LOG SCALE
# ============================================================================

cat("🎨 Generando versión LOG...\n")

fig_log <- ggplot(vaf_summary, aes(x = Total_GT_VAF, fill = Group, color = Group)) +
  geom_density(alpha = 0.4, linewidth = 1) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  scale_color_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  scale_x_log10(labels = scales::comma) +
  labs(
    title = "Distribution of Total G>T VAF per Sample",
    subtitle = paste0("Wilcoxon p = ", format.pval(test_result$p.value, digits = 3)),
    x = "Total G>T VAF (LOG scale)",
    y = "Density",
    fill = "Group",
    color = "Group"
  ) +
  theme_prof +
  annotate("text", x = max(vaf_summary$Total_GT_VAF) * 0.3, 
           y = Inf, vjust = 1.5,
           label = paste0("Overlap: ~", round(overlap_prop * 100, 0), "%"),
           size = 4, color = "gray30")

ggsave("figures_paso2_CLEAN/FIG_2.2_DENSITY_LOG.png", fig_log, 
       width = 10, height = 6, dpi = 300, bg = "white")
cat("   ✅ Versión LOG guardada\n\n")

# ============================================================================
# ANÁLISIS DE FORMA
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("📊 ANÁLISIS DE FORMA DE LAS DISTRIBUCIONES:\n\n")

# Skewness (asimetría)
library(e1071)

skew_als <- skewness(als_vals)
skew_ctrl <- skewness(ctrl_vals)

cat("ASIMETRÍA (Skewness):\n")
cat("   ALS:", round(skew_als, 3), ifelse(skew_als > 0, "(sesgada a la derecha)", "(sesgada a la izquierda)"), "\n")
cat("   Control:", round(skew_ctrl, 3), ifelse(skew_ctrl > 0, "(sesgada a la derecha)", "(sesgada a la izquierda)"), "\n")
cat("   Interpretación: >0 = cola larga derecha, <0 = cola larga izquierda\n\n")

# Kurtosis (forma del pico)
kurt_als <- kurtosis(als_vals)
kurt_ctrl <- kurtosis(ctrl_vals)

cat("CURTOSIS (Kurtosis):\n")
cat("   ALS:", round(kurt_als, 3), "\n")
cat("   Control:", round(kurt_ctrl, 3), "\n")
cat("   Interpretación: >0 = picos agudos, <0 = picos planos\n\n")

# Coeficiente de variación
cv_als <- sd(als_vals) / mean(als_vals) * 100
cv_ctrl <- sd(ctrl_vals) / mean(ctrl_vals) * 100

cat("COEFICIENTE DE VARIACIÓN:\n")
cat("   ALS:", round(cv_als, 1), "%\n")
cat("   Control:", round(cv_ctrl, 1), "%\n")
cat("   Interpretación: Mayor % = más variabilidad relativa\n\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")

# ============================================================================
# COMPARACIÓN Y RECOMENDACIÓN
# ============================================================================

cat("📊 COMPARACIÓN LINEAR vs LOG:\n\n")

range_vals <- range(vaf_summary$Total_GT_VAF)
fold_diff <- range_vals[2] / range_vals[1]

cat("RANGO:", sprintf("%.3f a %.2f", range_vals[1], range_vals[2]), "\n")
cat("Fold difference:", sprintf("%.0f-fold", fold_diff), "\n\n")

if (fold_diff > 100) {
  cat("✅ RECOMENDACIÓN: LOG SCALE\n")
  cat("   Razón: Rango muy amplio (>100-fold)\n")
} else if (fold_diff > 10) {
  cat("⚠️  LOG SCALE probablemente mejor\n")
  cat("   Razón: Rango moderado (10-100 fold)\n")
} else {
  cat("✅ RECOMENDACIÓN: LINEAR SCALE\n")
  cat("   Razón: Rango pequeño (<10-fold)\n")
}

cat("\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("✅ DOS VERSIONES GENERADAS:\n")
cat("   1. FIG_2.2_DENSITY_LINEAR.png\n")
cat("   2. FIG_2.2_DENSITY_LOG.png\n")
cat("\n")
cat("📊 Compara ambas y decide!\n")
cat("\n")

