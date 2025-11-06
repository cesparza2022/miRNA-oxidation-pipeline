#!/usr/bin/env Rscript
# ============================================================================
# FIGURA 2.3 - VOLCANO PLOT CORREGIDO + ANÁLISIS DE CONSISTENCIA
# ============================================================================

library(ggplot2)
library(dplyr)
library(tidyr)
library(readr)
library(stringr)
library(ggrepel)

# Colores
COLOR_ALS <- "#D62728"        # Rojo para ALS
COLOR_CONTROL <- "#404040"    # Gris oscuro para Control
COLOR_NS <- "gray80"          # Gris claro para no significativo

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  FIGURA 2.3 - VOLCANO PLOT + ANÁLISIS DE CONSISTENCIA\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# ============================================================================
# LOAD DATA
# ============================================================================

cat("📂 Cargando datos...\n")
data <- read_csv("final_processed_data_CLEAN.csv", show_col_types = FALSE)
metadata <- read_csv("metadata.csv", show_col_types = FALSE)
sample_cols <- metadata$Sample_ID

# Filtrar solo G>T en seed
vaf_gt_seed <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  filter(str_detect(pos.mut, "^(2|3|4|5|6|7|8):GT$")) %>%  # Solo seed (2-8)
  select(all_of(c("miRNA_name", "pos.mut", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  left_join(metadata, by = "Sample_ID")

# Lista de miRNAs únicos
all_seed_gt_mirnas <- unique(vaf_gt_seed$miRNA_name)

cat("   ✅ Datos cargados\n")
cat("   ✅ miRNAs con G>T en seed:", length(all_seed_gt_mirnas), "\n\n")

# ============================================================================
# GENERATE VOLCANO DATA
# ============================================================================

cat("🔢 Generando datos para volcano plot...\n\n")

volcano_data <- data.frame()
for (mirna in all_seed_gt_mirnas) {
  mirna_data <- vaf_gt_seed %>% filter(miRNA_name == mirna)
  als_vals <- mirna_data %>% filter(Group == "ALS") %>% pull(VAF) %>% na.omit()
  ctrl_vals <- mirna_data %>% filter(Group == "Control") %>% pull(VAF) %>% na.omit()
  
  if (length(als_vals) > 5 && length(ctrl_vals) > 5) {
    mean_als <- mean(als_vals) + 0.001
    mean_ctrl <- mean(ctrl_vals) + 0.001
    fc <- log2(mean_als / mean_ctrl)
    test_result <- tryCatch(wilcox.test(als_vals, ctrl_vals), error = function(e) list(p.value = 1))
    
    volcano_data <- rbind(volcano_data, data.frame(
      miRNA = mirna, 
      log2FC = fc, 
      pvalue = test_result$p.value,
      Mean_ALS = mean_als,
      Mean_Control = mean_ctrl
    ))
  }
}

volcano_data$padj <- p.adjust(volcano_data$pvalue, method = "fdr")
volcano_data$neg_log10_padj <- -log10(volcano_data$padj)
volcano_data$Sig <- "NS"
volcano_data$Sig[volcano_data$log2FC > 0.58 & volcano_data$padj < 0.05] <- "ALS"
volcano_data$Sig[volcano_data$log2FC < -0.58 & volcano_data$padj < 0.05] <- "Control"

cat("   ✅ Volcano data generado para", nrow(volcano_data), "miRNAs\n\n")

# ============================================================================
# ANÁLISIS DE CONSISTENCIA CON FIG 2.1-2.2
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("🔍 ANÁLISIS DE CONSISTENCIA CON FIGURAS 2.1-2.2\n")
cat("\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")

# Hallazgo de Fig 2.1-2.2
cat("HALLAZGO PREVIO (Fig 2.1-2.2):\n")
cat("   • Control > ALS en G>T VAF global\n")
cat("   • Control Mean: 3.69\n")
cat("   • ALS Mean: 2.58\n")
cat("   • p = 2.5e-13 (altamente significativo)\n")
cat("\n")

# Conteo en volcano
count_sig_als <- sum(volcano_data$Sig == "ALS")
count_sig_control <- sum(volcano_data$Sig == "Control")
count_ns <- sum(volcano_data$Sig == "NS")

cat("RESULTADOS VOLCANO PLOT:\n")
cat("   • miRNAs elevados en ALS:", count_sig_als, "\n")
cat("   • miRNAs elevados en Control:", count_sig_control, "\n")
cat("   • miRNAs no significativos:", count_ns, "\n")
cat("\n")

# Análisis de dirección global
mean_log2fc_all <- mean(volcano_data$log2FC)
median_log2fc_all <- median(volcano_data$log2FC)

cat("DIRECCIÓN GLOBAL (log2FC):\n")
cat("   • Media de log2FC:", round(mean_log2fc_all, 3), "\n")
cat("   • Mediana de log2FC:", round(median_log2fc_all, 3), "\n")
cat("\n")

if (median_log2fc_all < 0) {
  cat("   ✅ CONSISTENTE: Mediana < 0 → Tendencia hacia Control\n")
} else {
  cat("   ⚠️  INCONSISTENTE: Mediana > 0 → Tendencia hacia ALS\n")
}
cat("\n")

# Proporción de miRNAs con dirección hacia Control
prop_control_direction <- sum(volcano_data$log2FC < 0) / nrow(volcano_data) * 100

cat("PROPORCIÓN DE miRNAs:\n")
cat("   • Dirección Control (log2FC < 0):", round(prop_control_direction, 1), "%\n")
cat("   • Dirección ALS (log2FC > 0):", round(100 - prop_control_direction, 1), "%\n")
cat("\n")

if (prop_control_direction > 50) {
  cat("   ✅ CONSISTENTE: Mayoría de miRNAs tienen más G>T en Control\n")
} else {
  cat("   ⚠️  INCONSISTENTE: Mayoría de miRNAs tienen más G>T en ALS\n")
}
cat("\n")

# ============================================================================
# EXPLICACIÓN DE LA APARENTE CONTRADICCIÓN
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("💡 RECONCILIANDO LOS HALLAZGOS:\n")
cat("\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")

cat("DIFERENCIA CLAVE:\n")
cat("\n")
cat("Fig 2.1-2.2: GLOBAL burden (suma de TODOS los miRNAs)\n")
cat("   • Métrica: Suma total de VAF por muestra\n")
cat("   • Pregunta: ¿Qué grupo tiene más G>T en TOTAL?\n")
cat("   • Respuesta: Control > ALS\n")
cat("\n")
cat("Fig 2.3: miRNA-ESPECÍFICO (cada miRNA individualmente)\n")
cat("   • Métrica: Media de VAF por miRNA\n")
cat("   • Pregunta: ¿Qué miRNAs ESPECÍFICOS difieren entre grupos?\n")
cat("   • Respuesta: Depende del miRNA\n")
cat("\n")

cat("ESCENARIO POSIBLE (reconcilia ambos hallazgos):\n")
cat("\n")
cat("Opción 1: CONTROL tiene más miRNAs afectados (más spread)\n")
cat("   • Control: 50 miRNAs con G>T moderado cada uno\n")
cat("   • ALS: 20 miRNAs con G>T alto cada uno\n")
cat("   → Total Control > Total ALS (Fig 2.1-2.2)\n")
cat("   → Pero algunos miRNAs específicos ALS > Control (Fig 2.3)\n")
cat("\n")
cat("Opción 2: CONTROL tiene algunos miRNAs MUY altos\n")
cat("   • Unos pocos miRNAs dominan el burden global en Control\n")
cat("   • Otros miRNAs son más altos en ALS\n")
cat("   → Volcano muestra la heterogeneidad miRNA-específica\n")
cat("\n")
cat("Opción 3: Diferentes POSICIONES dentro del seed\n")
cat("   • Algunas posiciones seed más en ALS\n")
cat("   • Otras posiciones más en Control\n")
cat("   → Global: Control gana, pero hay miRNAs específicos en ALS\n")
cat("\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")

# Analizar los top miRNAs significativos
if (count_sig_als > 0) {
  cat("TOP miRNAs ELEVADOS EN ALS:\n")
  top_als <- volcano_data %>% 
    filter(Sig == "ALS") %>% 
    arrange(padj) %>% 
    head(5)
  print(top_als %>% select(miRNA, log2FC, Mean_ALS, Mean_Control, padj))
  cat("\n")
}

if (count_sig_control > 0) {
  cat("TOP miRNAs ELEVADOS EN CONTROL:\n")
  top_control <- volcano_data %>% 
    filter(Sig == "Control") %>% 
    arrange(padj) %>% 
    head(5)
  print(top_control %>% select(miRNA, log2FC, Mean_ALS, Mean_Control, padj))
  cat("\n")
}

# ============================================================================
# GENERATE CORRECTED FIGURE
# ============================================================================

cat("🎨 Generando volcano plot CORREGIDO (Control = gris oscuro)...\n")

theme_prof <- theme_classic(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 15, hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5, color = "gray40"),
    axis.title = element_text(face = "bold", size = 12),
    axis.text = element_text(size = 11),
    legend.position = c(0.15, 0.85),
    legend.background = element_rect(fill = "white", color = "gray80"),
    legend.title = element_text(face = "bold", size = 11),
    panel.grid.major = element_line(color = "gray90", linewidth = 0.3)
  )

# Top labels (15 más significativos)
top_labels <- volcano_data %>% 
  filter(Sig != "NS") %>% 
  arrange(padj) %>% 
  head(15)

fig_2_3 <- ggplot(volcano_data, aes(x = log2FC, y = neg_log10_padj, color = Sig)) +
  geom_point(alpha = 0.6, size = 2.5) +
  geom_hline(yintercept = -log10(0.05), linetype = "dashed", color = "gray50", linewidth = 0.5) +
  geom_vline(xintercept = c(-0.58, 0.58), linetype = "dashed", color = "gray50", linewidth = 0.5) +
  scale_color_manual(
    values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL, "NS" = COLOR_NS),
    labels = c("ALS" = paste0("Elevated in ALS (n=", count_sig_als, ")"),
               "Control" = paste0("Elevated in Control (n=", count_sig_control, ")"),
               "NS" = paste0("Not Significant (n=", count_ns, ")"))
  ) +
  labs(
    title = "Differential G>T in Seed Region by miRNA",
    subtitle = paste0("Total miRNAs analyzed: ", nrow(volcano_data), " | FDR < 0.05, |log₂FC| > 0.58"),
    x = "log₂(Fold Change) [ALS vs Control]",
    y = "-log₁₀(FDR p-value)",
    color = "Significance"
  ) +
  theme_prof

# Agregar etiquetas para top miRNAs
if (nrow(top_labels) > 0) {
  fig_2_3 <- fig_2_3 + 
    geom_text_repel(
      data = top_labels, 
      aes(label = miRNA), 
      size = 3, 
      max.overlaps = 20, 
      color = "black",
      box.padding = 0.5,
      point.padding = 0.3,
      segment.color = "gray60",
      segment.size = 0.3
    )
}

ggsave("figures_paso2_CLEAN/FIG_2.3_VOLCANO_CORRECTED.png", fig_2_3, 
       width = 12, height = 10, dpi = 300, bg = "white")
cat("   ✅ Volcano plot CORREGIDO guardado\n\n")

# ============================================================================
# ANÁLISIS DE CONSISTENCIA DETALLADO
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("📊 ANÁLISIS DE CONSISTENCIA CON FIG 2.1-2.2\n")
cat("\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")

# 1. DIRECCIÓN GLOBAL
cat("1️⃣ DIRECCIÓN GLOBAL:\n")
cat("   Fig 2.1-2.2: Control > ALS (p = 2.5e-13)\n")
cat("   Fig 2.3 Volcano:\n")
cat("      • Media log2FC:", round(mean_log2fc_all, 3), 
    ifelse(mean_log2fc_all < 0, "→ Control > ALS ✅", "→ ALS > Control ⚠️"), "\n")
cat("      • Mediana log2FC:", round(median_log2fc_all, 3),
    ifelse(median_log2fc_all < 0, "→ Control > ALS ✅", "→ ALS > Control ⚠️"), "\n")
cat("\n")

# 2. PROPORCIÓN DE miRNAs
cat("2️⃣ PROPORCIÓN DE miRNAs POR DIRECCIÓN:\n")
cat("   • log2FC < 0 (Control > ALS):", round(prop_control_direction, 1), "% (", 
    sum(volcano_data$log2FC < 0), "/", nrow(volcano_data), ")\n")
cat("   • log2FC > 0 (ALS > Control):", round(100 - prop_control_direction, 1), "% (", 
    sum(volcano_data$log2FC > 0), "/", nrow(volcano_data), ")\n")
cat("\n")

if (prop_control_direction > 50) {
  cat("   ✅ CONSISTENTE: Mayoría de miRNAs con dirección Control\n")
} else {
  cat("   ⚠️  Distribución equilibrada o inversa\n")
}
cat("\n")

# 3. SIGNIFICATIVOS
cat("3️⃣ miRNAs SIGNIFICATIVOS:\n")
cat("   • Elevados en ALS:", count_sig_als, "\n")
cat("   • Elevados en Control:", count_sig_control, "\n")
cat("\n")

if (count_sig_control > count_sig_als) {
  cat("   ✅ CONSISTENTE: Más miRNAs significativos en Control\n")
} else if (count_sig_control < count_sig_als) {
  cat("   ⚠️  MÁS miRNAs significativos en ALS (inconsistente con burden global)\n")
} else {
  cat("   ➖ NEUTRAL: Igual número de miRNAs significativos\n")
}
cat("\n")

# 4. MAGNITUD PROMEDIO
mean_fc_control_mirnas <- volcano_data %>% filter(Sig == "Control") %>% pull(log2FC) %>% abs() %>% mean()
mean_fc_als_mirnas <- volcano_data %>% filter(Sig == "ALS") %>% pull(log2FC) %>% abs() %>% mean()

cat("4️⃣ MAGNITUD DEL EFECTO:\n")
if (count_sig_control > 0) {
  cat("   • |log2FC| promedio miRNAs Control:", round(mean_fc_control_mirnas, 2), 
      "(~", round(2^mean_fc_control_mirnas, 1), "x fold change)\n")
}
if (count_sig_als > 0) {
  cat("   • |log2FC| promedio miRNAs ALS:", round(mean_fc_als_mirnas, 2),
      "(~", round(2^mean_fc_als_mirnas, 1), "x fold change)\n")
}
cat("\n")

# ============================================================================
# INTERPRETACIÓN INTEGRADA
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("🧠 INTERPRETACIÓN INTEGRADA:\n")
cat("\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")

cat("RECONCILIANDO LOS HALLAZGOS:\n")
cat("\n")

if (median_log2fc_all < 0 & count_sig_control >= count_sig_als) {
  cat("✅ TOTALMENTE CONSISTENTE:\n")
  cat("   • Fig 2.1-2.2: Control > ALS (global)\n")
  cat("   • Fig 2.3: Mayoría de miRNAs Control > ALS (específico)\n")
  cat("   • Conclusión: El hallazgo global se refleja a nivel de miRNAs individuales\n")
  cat("\n")
  
} else if (median_log2fc_all < 0 & count_sig_control < count_sig_als) {
  cat("⚠️  PARCIALMENTE CONSISTENTE:\n")
  cat("   • Tendencia global hacia Control (mediana < 0)\n")
  cat("   • PERO: Más miRNAs SIGNIFICATIVOS en ALS\n")
  cat("\n")
  cat("   POSIBLE EXPLICACIÓN:\n")
  cat("   • Control tiene MUCHOS miRNAs con pequeñas elevaciones (no significativas)\n")
  cat("   • ALS tiene POCOS miRNAs pero con cambios MÁS GRANDES (significativos)\n")
  cat("   • El burden global lo domina Control (más miRNAs)\n")
  cat("   • Pero los cambios individuales fuertes están en ALS\n")
  cat("\n")
  
} else if (median_log2fc_all > 0) {
  cat("❌ APARENTEMENTE INCONSISTENTE:\n")
  cat("   • Fig 2.1-2.2: Control > ALS (global)\n")
  cat("   • Fig 2.3: Tendencia hacia ALS > Control (miRNAs individuales)\n")
  cat("\n")
  cat("   POSIBLES EXPLICACIONES:\n")
  cat("   • Control tiene POCOS miRNAs pero con VAF MUY ALTO\n")
  cat("   • ALS tiene MUCHOS miRNAs con VAF bajo/moderado\n")
  cat("   • Los outliers de Control dominan el burden global\n")
  cat("   • Necesitamos investigar distribución de expresión\n")
  cat("\n")
}

# ============================================================================
# RECOMENDACIONES
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("💡 RECOMENDACIONES:\n")
cat("\n")

cat("1. Revisar los TOP miRNAs significativos (arriba)\n")
cat("2. Verificar si algunos miRNAs dominan el burden global\n")
cat("3. Considerar análisis de:\n")
cat("   • Número de miRNAs expresados por grupo\n")
cat("   • Contribución relativa de cada miRNA al burden total\n")
cat("   • Distribución de expresión basal por grupo\n")
cat("\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("✅ FIGURA CORREGIDA GENERADA:\n")
cat("   • FIG_2.3_VOLCANO_CORRECTED.png\n")
cat("   • Control en gris oscuro (no azul)\n")
cat("   • Análisis de consistencia completo\n")
cat("\n")

