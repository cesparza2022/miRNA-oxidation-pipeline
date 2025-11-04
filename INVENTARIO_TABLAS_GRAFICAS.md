# 📊 INVENTARIO COMPLETO: Tablas y Gráficas del Pipeline

**Fecha:** 2025-11-02  
**Pipeline:** Snakemake ALS miRNA Oxidation Analysis

---

## 📋 RESUMEN EJECUTIVO

| Paso | Figuras | Tablas | Descripción |
|------|---------|--------|-------------|
| **Step 1** | 6 | 5 | Análisis exploratorio inicial |
| **Step 1.5** | 11 | 6 | Control de calidad VAF |
| **Step 2** | 2 | 2 | Comparaciones ALS vs Control |
| **TOTAL** | **19** | **13** | **32 outputs principales** |

---

## 📊 STEP 1: EXPLORATORY ANALYSIS

**Objetivo:** Análisis exploratorio inicial de las mutaciones G>T y patrones generales.

### FIGURAS (6)

#### Panel B: G>T Count by Position
- **Archivo:** `outputs/step1/figures/step1_panelB_gt_count_by_position.png`
- **Descripción:** Conteo absoluto de mutaciones G>T por posición (1-23)
- **Muestra:** Distribución de eventos de oxidación a lo largo de la secuencia miRNA

#### Panel C: G>X Mutation Spectrum by Position
- **Archivo:** `outputs/step1/figures/step1_panelC_gx_spectrum.png`
- **Descripción:** Espectro completo de mutaciones G (G>T, G>C, G>A) por posición
- **Muestra:** Prevalencia de G>T (oxidación) vs otras transiciones G

#### Panel D: Positional Fraction of Mutations
- **Archivo:** `outputs/step1/figures/step1_panelD_positional_fraction.png`
- **Descripción:** Proporción de TODAS las SNVs por posición (relativo al total)
- **Muestra:** Qué posiciones acumulan más mutaciones en general

#### Panel E: G-Content Landscape
- **Archivo:** `outputs/step1/figures/step1_panelE_gcontent.png`
- **Descripción:** Bubble plot: relación entre contenido G por posición y conteo G>T
- **Muestra:** Burbujas más grandes = mayor conteo de mutaciones

#### Panel F: Seed vs Non-seed Comparison
- **Archivo:** `outputs/step1/figures/step1_panelF_seed_interaction.png`
- **Descripción:** Comparación G>T entre región semilla (pos 1-7) vs no-semilla (pos 8-23)
- **Muestra:** Impacto funcional crítico de mutaciones en región semilla

#### Panel G: G>T Specificity (Overall)
- **Archivo:** `outputs/step1/figures/step1_panelG_gt_specificity.png`
- **Descripción:** Proporción de G>T relativo a todas las mutaciones G>X
- **Muestra:** Especificidad del daño oxidativo (8-oxoG) entre mutaciones G

### TABLAS (5)

1. **`TABLE_1.B_gt_counts_by_position.csv`**
   - Conteos de G>T por posición
   - Columnas: Position, GT_Count, Total_Count, Proportion

2. **`TABLE_1.C_gx_spectrum_by_position.csv`**
   - Espectro completo de mutaciones G>X por posición
   - Incluye: G>T, G>C, G>A y sus proporciones

3. **`TABLE_1.D_positional_fractions.csv`**
   - Fracciones posicionales de todas las mutaciones
   - Proporciones normalizadas por posición

4. **`TABLE_1.E_gcontent_landscape.csv`**
   - Contenido G y conteos G>T por posición
   - Datos para bubble plot

5. **`TABLE_1.F_seed_vs_nonseed.csv`** (si existe)
   - Estadísticas comparativas seed vs non-seed
   - Conteos y proporciones por región

---

## 🔬 STEP 1.5: VAF QUALITY CONTROL

**Objetivo:** Filtrar artefactos técnicos (VAF ≥ 0.5) y generar figuras diagnósticas.

### FIGURAS (11)

#### Quality Control Figures (4)

1. **`QC_FIG1_VAF_DISTRIBUTION.png`**
   - Distribución de VAFs antes y después del filtro
   - Histograma o density plot

2. **`QC_FIG2_FILTER_IMPACT.png`**
   - Impacto del filtro VAF
   - Cantidad de SNVs/muestras afectadas

3. **`QC_FIG3_AFFECTED_MIRNAS.png`**
   - miRNAs más afectados por el filtro
   - Ranking de miRNAs con más SNVs filtrados

4. **`QC_FIG4_BEFORE_AFTER.png`**
   - Comparación antes/después del filtro
   - Visualización del impacto en los datos

#### Diagnostic Figures (7)

5. **`STEP1.5_FIG1_HEATMAP_SNVS.png`**
   - Heatmap de número de SNVs
   - miRNAs × muestras (datos filtrados)

6. **`STEP1.5_FIG2_HEATMAP_COUNTS.png`**
   - Heatmap de conteos totales
   - miRNAs × muestras (datos filtrados)

7. **`STEP1.5_FIG3_G_TRANSVERSIONS_SNVS.png`**
   - Análisis de transiciones G por SNVs
   - G>T, G>A, etc. (datos filtrados)

8. **`STEP1.5_FIG4_G_TRANSVERSIONS_COUNTS.png`**
   - Análisis de transiciones G por conteos
   - G>T, G>A, etc. (datos filtrados)

9. **`STEP1.5_FIG5_BUBBLE_PLOT.png`**
   - Bubble plot de mutaciones
   - Visualización multidimensional

10. **`STEP1.5_FIG6_VIOLIN_DISTRIBUTIONS.png`**
    - Distribuciones violin por muestra
    - Top 8 tipos de mutación

11. **`STEP1.5_FIG7_FOLD_CHANGE.png`**
    - Análisis de fold change
    - Comparaciones de mutaciones

### TABLAS (6)

1. **`ALL_MUTATIONS_VAF_FILTERED.csv`**
   - Datos completos después del filtro VAF
   - Input principal para Step 2

2. **`vaf_filter_report.csv`**
   - Reporte del proceso de filtrado
   - Estadísticas de SNVs filtrados

3. **`mutation_type_summary_vaf_filtered.csv`**
   - Resumen por tipo de mutación (filtrado)
   - Conteos y estadísticas

4. **`position_metrics_vaf_filtered.csv`**
   - Métricas por posición (filtrado)
   - Estadísticas posicionales

5. **`sample_metrics_vaf_filtered.csv`**
   - Métricas por muestra (filtrado)
   - Estadísticas por individuo

6. **`vaf_statistics_by_mirna.csv`**
   - Estadísticas VAF por miRNA
   - Resumen por miRNA

7. **`vaf_statistics_by_type.csv`**
   - Estadísticas VAF por tipo de mutación
   - Resumen por tipo

---

## 📈 STEP 2: STATISTICAL COMPARISONS (ALS vs Control)

**Objetivo:** Comparaciones estadísticas entre grupos ALS y Control.

### FIGURAS (2)

1. **`step2_volcano_plot.png`**
   - Volcano plot: Significancia vs Fold Change
   - Eje X: log2 Fold Change (ALS/Control)
   - Eje Y: -log10 FDR-adjusted p-value
   - Categorías: Upregulated, Downregulated, Significant (low FC), High FC (not sig)
   - Colores profesionales consistentes

2. **`step2_effect_size_distribution.png`**
   - Histograma de distribución de Cohen's d
   - Categorización: Large (|d| ≥ 0.8), Medium (0.5 ≤ |d| < 0.8), Small (0.2 ≤ |d| < 0.5), Negligible (|d| < 0.2)
   - Interpretación de tamaños de efecto

### TABLAS (2)

1. **`step2_statistical_comparisons.csv`**
   - Comparaciones estadísticas completas
   - **Columnas principales:**
     - `miRNA_name`, `pos.mut`: Identificación del SNV
     - `ALS_mean`, `ALS_sd`, `ALS_n`: Estadísticas grupo ALS
     - `Control_mean`, `Control_sd`, `Control_n`: Estadísticas grupo Control
     - `fold_change`, `log2_fold_change`: Cambios de expresión
     - `t_test_pvalue`, `t_test_fdr`: Resultados test t (paramétrico)
     - `wilcoxon_pvalue`, `wilcoxon_fdr`: Resultados Wilcoxon (no paramétrico)
     - `t_test_significant`, `wilcoxon_significant`, `significant`: Flags de significancia
   - **Tamaño:** ~1.1 MB
   - **Filas:** 5,448 SNVs

2. **`step2_effect_sizes.csv`**
   - Análisis de effect size (Cohen's d)
   - **Columnas principales:**
     - `miRNA_name`, `pos.mut`: Identificación del SNV
     - `ALS_mean`, `Control_mean`: Medias por grupo
     - `log2_fold_change`: Fold change
     - `cohens_d`: Effect size (Cohen's d)
     - `effect_size_category`: Large, Medium, Small, Negligible
     - `cohens_d_ci_lower`, `cohens_d_ci_upper`: Intervalos de confianza 95%
     - `t_test_fdr`, `wilcoxon_fdr`: FDR para referencia
     - `significant`: Flag de significancia combinado
   - **Tamaño:** ~909 KB
   - **Filas:** 5,448 SNVs

---

## 📂 ESTRUCTURA DE DIRECTORIOS

```
outputs/
├── step1/
│   ├── figures/
│   │   ├── step1_panelB_gt_count_by_position.png
│   │   ├── step1_panelC_gx_spectrum.png
│   │   ├── step1_panelD_positional_fraction.png
│   │   ├── step1_panelE_gcontent.png
│   │   ├── step1_panelF_seed_interaction.png
│   │   └── step1_panelG_gt_specificity.png
│   ├── tables/
│   │   ├── TABLE_1.B_gt_counts_by_position.csv
│   │   ├── TABLE_1.C_gx_spectrum_by_position.csv
│   │   ├── TABLE_1.D_positional_fractions.csv
│   │   ├── TABLE_1.E_gcontent_landscape.csv
│   │   └── TABLE_1.F_seed_vs_nonseed.csv
│   └── logs/
│
├── step1_5/
│   ├── figures/
│   │   ├── QC_FIG1_VAF_DISTRIBUTION.png
│   │   ├── QC_FIG2_FILTER_IMPACT.png
│   │   ├── QC_FIG3_AFFECTED_MIRNAS.png
│   │   ├── QC_FIG4_BEFORE_AFTER.png
│   │   ├── STEP1.5_FIG1_HEATMAP_SNVS.png
│   │   ├── STEP1.5_FIG2_HEATMAP_COUNTS.png
│   │   ├── STEP1.5_FIG3_G_TRANSVERSIONS_SNVS.png
│   │   ├── STEP1.5_FIG4_G_TRANSVERSIONS_COUNTS.png
│   │   ├── STEP1.5_FIG5_BUBBLE_PLOT.png
│   │   ├── STEP1.5_FIG6_VIOLIN_DISTRIBUTIONS.png
│   │   └── STEP1.5_FIG7_FOLD_CHANGE.png
│   ├── tables/
│   │   ├── ALL_MUTATIONS_VAF_FILTERED.csv
│   │   ├── vaf_filter_report.csv
│   │   ├── mutation_type_summary_vaf_filtered.csv
│   │   ├── position_metrics_vaf_filtered.csv
│   │   ├── sample_metrics_vaf_filtered.csv
│   │   ├── vaf_statistics_by_mirna.csv
│   │   └── vaf_statistics_by_type.csv
│   ├── data/
│   │   └── ALL_MUTATIONS_VAF_FILTERED.csv (duplicado para uso directo)
│   └── logs/
│
└── step2/
    ├── figures/
    │   ├── step2_volcano_plot.png
    │   └── step2_effect_size_distribution.png
    ├── tables/
    │   ├── step2_statistical_comparisons.csv
    │   └── step2_effect_sizes.csv
    └── logs/
```

---

## 🌐 VIEWERS HTML

Cada paso tiene un viewer HTML interactivo que muestra todas sus figuras y estadísticas:

1. **`viewers/step1.html`**
   - Step 1: 6 figuras + 5 tablas
   - Análisis exploratorio completo

2. **`viewers/step1_5.html`**
   - Step 1.5: 11 figuras (QC + Diagnósticas) + 6 tablas
   - Control de calidad VAF

3. **`viewers/step2.html`**
   - Step 2: 2 figuras + 2 tablas + estadísticas resumidas
   - Comparaciones ALS vs Control

---

## 📊 ESTADÍSTICAS POR PASO

### Step 1 (Exploratory)
- **Propósito:** Entender patrones generales
- **Focus:** Distribución posicional, contenido G, seed vs non-seed
- **Sin filtrado:** Usa todos los datos disponibles

### Step 1.5 (VAF Quality Control)
- **Propósito:** Filtrar artefactos técnicos
- **Focus:** Validar calidad de datos
- **Filtro aplicado:** VAF ≥ 0.5 → NA
- **Output clave:** `ALL_MUTATIONS_VAF_FILTERED.csv` (input para Step 2)

### Step 2 (Statistical Comparisons)
- **Propósito:** Comparar grupos ALS vs Control
- **Focus:** Significancia estadística y effect sizes
- **Métodos:** t-test, Wilcoxon, FDR correction
- **Outputs clave:** Comparaciones estadísticas + Volcano plot

---

## 🔄 FLUJO DE DATOS

```
RAW DATA
   ↓
STEP 1 (Exploratory Analysis)
   → 6 figuras + 5 tablas
   ↓
PROCESSED DATA (final_processed_data_CLEAN.csv)
   ↓
STEP 1.5 (VAF Filtering)
   → 11 figuras + 6 tablas
   → ALL_MUTATIONS_VAF_FILTERED.csv
   ↓
STEP 2 (Statistical Comparisons)
   → 2 figuras + 2 tablas
   → Comparaciones ALS vs Control
```

---

## 📝 NOTAS IMPORTANTES

1. **Step 1** usa datos sin filtrar (combinación ALS + Control)
2. **Step 1.5** aplica filtro VAF y genera datos limpios
3. **Step 2** usa datos filtrados de Step 1.5 para comparaciones
4. Todas las figuras usan temas profesionales consistentes
5. Todas las tablas son CSV para fácil análisis posterior
6. Los viewers HTML permiten revisar todos los resultados de cada paso

---

**Total: 19 figuras + 13 tablas = 32 outputs principales**


**Fecha:** 2025-11-02  
**Pipeline:** Snakemake ALS miRNA Oxidation Analysis

---

## 📋 RESUMEN EJECUTIVO

| Paso | Figuras | Tablas | Descripción |
|------|---------|--------|-------------|
| **Step 1** | 6 | 5 | Análisis exploratorio inicial |
| **Step 1.5** | 11 | 6 | Control de calidad VAF |
| **Step 2** | 2 | 2 | Comparaciones ALS vs Control |
| **TOTAL** | **19** | **13** | **32 outputs principales** |

---

## 📊 STEP 1: EXPLORATORY ANALYSIS

**Objetivo:** Análisis exploratorio inicial de las mutaciones G>T y patrones generales.

### FIGURAS (6)

#### Panel B: G>T Count by Position
- **Archivo:** `outputs/step1/figures/step1_panelB_gt_count_by_position.png`
- **Descripción:** Conteo absoluto de mutaciones G>T por posición (1-23)
- **Muestra:** Distribución de eventos de oxidación a lo largo de la secuencia miRNA

#### Panel C: G>X Mutation Spectrum by Position
- **Archivo:** `outputs/step1/figures/step1_panelC_gx_spectrum.png`
- **Descripción:** Espectro completo de mutaciones G (G>T, G>C, G>A) por posición
- **Muestra:** Prevalencia de G>T (oxidación) vs otras transiciones G

#### Panel D: Positional Fraction of Mutations
- **Archivo:** `outputs/step1/figures/step1_panelD_positional_fraction.png`
- **Descripción:** Proporción de TODAS las SNVs por posición (relativo al total)
- **Muestra:** Qué posiciones acumulan más mutaciones en general

#### Panel E: G-Content Landscape
- **Archivo:** `outputs/step1/figures/step1_panelE_gcontent.png`
- **Descripción:** Bubble plot: relación entre contenido G por posición y conteo G>T
- **Muestra:** Burbujas más grandes = mayor conteo de mutaciones

#### Panel F: Seed vs Non-seed Comparison
- **Archivo:** `outputs/step1/figures/step1_panelF_seed_interaction.png`
- **Descripción:** Comparación G>T entre región semilla (pos 1-7) vs no-semilla (pos 8-23)
- **Muestra:** Impacto funcional crítico de mutaciones en región semilla

#### Panel G: G>T Specificity (Overall)
- **Archivo:** `outputs/step1/figures/step1_panelG_gt_specificity.png`
- **Descripción:** Proporción de G>T relativo a todas las mutaciones G>X
- **Muestra:** Especificidad del daño oxidativo (8-oxoG) entre mutaciones G

### TABLAS (5)

1. **`TABLE_1.B_gt_counts_by_position.csv`**
   - Conteos de G>T por posición
   - Columnas: Position, GT_Count, Total_Count, Proportion

2. **`TABLE_1.C_gx_spectrum_by_position.csv`**
   - Espectro completo de mutaciones G>X por posición
   - Incluye: G>T, G>C, G>A y sus proporciones

3. **`TABLE_1.D_positional_fractions.csv`**
   - Fracciones posicionales de todas las mutaciones
   - Proporciones normalizadas por posición

4. **`TABLE_1.E_gcontent_landscape.csv`**
   - Contenido G y conteos G>T por posición
   - Datos para bubble plot

5. **`TABLE_1.F_seed_vs_nonseed.csv`** (si existe)
   - Estadísticas comparativas seed vs non-seed
   - Conteos y proporciones por región

---

## 🔬 STEP 1.5: VAF QUALITY CONTROL

**Objetivo:** Filtrar artefactos técnicos (VAF ≥ 0.5) y generar figuras diagnósticas.

### FIGURAS (11)

#### Quality Control Figures (4)

1. **`QC_FIG1_VAF_DISTRIBUTION.png`**
   - Distribución de VAFs antes y después del filtro
   - Histograma o density plot

2. **`QC_FIG2_FILTER_IMPACT.png`**
   - Impacto del filtro VAF
   - Cantidad de SNVs/muestras afectadas

3. **`QC_FIG3_AFFECTED_MIRNAS.png`**
   - miRNAs más afectados por el filtro
   - Ranking de miRNAs con más SNVs filtrados

4. **`QC_FIG4_BEFORE_AFTER.png`**
   - Comparación antes/después del filtro
   - Visualización del impacto en los datos

#### Diagnostic Figures (7)

5. **`STEP1.5_FIG1_HEATMAP_SNVS.png`**
   - Heatmap de número de SNVs
   - miRNAs × muestras (datos filtrados)

6. **`STEP1.5_FIG2_HEATMAP_COUNTS.png`**
   - Heatmap de conteos totales
   - miRNAs × muestras (datos filtrados)

7. **`STEP1.5_FIG3_G_TRANSVERSIONS_SNVS.png`**
   - Análisis de transiciones G por SNVs
   - G>T, G>A, etc. (datos filtrados)

8. **`STEP1.5_FIG4_G_TRANSVERSIONS_COUNTS.png`**
   - Análisis de transiciones G por conteos
   - G>T, G>A, etc. (datos filtrados)

9. **`STEP1.5_FIG5_BUBBLE_PLOT.png`**
   - Bubble plot de mutaciones
   - Visualización multidimensional

10. **`STEP1.5_FIG6_VIOLIN_DISTRIBUTIONS.png`**
    - Distribuciones violin por muestra
    - Top 8 tipos de mutación

11. **`STEP1.5_FIG7_FOLD_CHANGE.png`**
    - Análisis de fold change
    - Comparaciones de mutaciones

### TABLAS (6)

1. **`ALL_MUTATIONS_VAF_FILTERED.csv`**
   - Datos completos después del filtro VAF
   - Input principal para Step 2

2. **`vaf_filter_report.csv`**
   - Reporte del proceso de filtrado
   - Estadísticas de SNVs filtrados

3. **`mutation_type_summary_vaf_filtered.csv`**
   - Resumen por tipo de mutación (filtrado)
   - Conteos y estadísticas

4. **`position_metrics_vaf_filtered.csv`**
   - Métricas por posición (filtrado)
   - Estadísticas posicionales

5. **`sample_metrics_vaf_filtered.csv`**
   - Métricas por muestra (filtrado)
   - Estadísticas por individuo

6. **`vaf_statistics_by_mirna.csv`**
   - Estadísticas VAF por miRNA
   - Resumen por miRNA

7. **`vaf_statistics_by_type.csv`**
   - Estadísticas VAF por tipo de mutación
   - Resumen por tipo

---

## 📈 STEP 2: STATISTICAL COMPARISONS (ALS vs Control)

**Objetivo:** Comparaciones estadísticas entre grupos ALS y Control.

### FIGURAS (2)

1. **`step2_volcano_plot.png`**
   - Volcano plot: Significancia vs Fold Change
   - Eje X: log2 Fold Change (ALS/Control)
   - Eje Y: -log10 FDR-adjusted p-value
   - Categorías: Upregulated, Downregulated, Significant (low FC), High FC (not sig)
   - Colores profesionales consistentes

2. **`step2_effect_size_distribution.png`**
   - Histograma de distribución de Cohen's d
   - Categorización: Large (|d| ≥ 0.8), Medium (0.5 ≤ |d| < 0.8), Small (0.2 ≤ |d| < 0.5), Negligible (|d| < 0.2)
   - Interpretación de tamaños de efecto

### TABLAS (2)

1. **`step2_statistical_comparisons.csv`**
   - Comparaciones estadísticas completas
   - **Columnas principales:**
     - `miRNA_name`, `pos.mut`: Identificación del SNV
     - `ALS_mean`, `ALS_sd`, `ALS_n`: Estadísticas grupo ALS
     - `Control_mean`, `Control_sd`, `Control_n`: Estadísticas grupo Control
     - `fold_change`, `log2_fold_change`: Cambios de expresión
     - `t_test_pvalue`, `t_test_fdr`: Resultados test t (paramétrico)
     - `wilcoxon_pvalue`, `wilcoxon_fdr`: Resultados Wilcoxon (no paramétrico)
     - `t_test_significant`, `wilcoxon_significant`, `significant`: Flags de significancia
   - **Tamaño:** ~1.1 MB
   - **Filas:** 5,448 SNVs

2. **`step2_effect_sizes.csv`**
   - Análisis de effect size (Cohen's d)
   - **Columnas principales:**
     - `miRNA_name`, `pos.mut`: Identificación del SNV
     - `ALS_mean`, `Control_mean`: Medias por grupo
     - `log2_fold_change`: Fold change
     - `cohens_d`: Effect size (Cohen's d)
     - `effect_size_category`: Large, Medium, Small, Negligible
     - `cohens_d_ci_lower`, `cohens_d_ci_upper`: Intervalos de confianza 95%
     - `t_test_fdr`, `wilcoxon_fdr`: FDR para referencia
     - `significant`: Flag de significancia combinado
   - **Tamaño:** ~909 KB
   - **Filas:** 5,448 SNVs

---

## 📂 ESTRUCTURA DE DIRECTORIOS

```
outputs/
├── step1/
│   ├── figures/
│   │   ├── step1_panelB_gt_count_by_position.png
│   │   ├── step1_panelC_gx_spectrum.png
│   │   ├── step1_panelD_positional_fraction.png
│   │   ├── step1_panelE_gcontent.png
│   │   ├── step1_panelF_seed_interaction.png
│   │   └── step1_panelG_gt_specificity.png
│   ├── tables/
│   │   ├── TABLE_1.B_gt_counts_by_position.csv
│   │   ├── TABLE_1.C_gx_spectrum_by_position.csv
│   │   ├── TABLE_1.D_positional_fractions.csv
│   │   ├── TABLE_1.E_gcontent_landscape.csv
│   │   └── TABLE_1.F_seed_vs_nonseed.csv
│   └── logs/
│
├── step1_5/
│   ├── figures/
│   │   ├── QC_FIG1_VAF_DISTRIBUTION.png
│   │   ├── QC_FIG2_FILTER_IMPACT.png
│   │   ├── QC_FIG3_AFFECTED_MIRNAS.png
│   │   ├── QC_FIG4_BEFORE_AFTER.png
│   │   ├── STEP1.5_FIG1_HEATMAP_SNVS.png
│   │   ├── STEP1.5_FIG2_HEATMAP_COUNTS.png
│   │   ├── STEP1.5_FIG3_G_TRANSVERSIONS_SNVS.png
│   │   ├── STEP1.5_FIG4_G_TRANSVERSIONS_COUNTS.png
│   │   ├── STEP1.5_FIG5_BUBBLE_PLOT.png
│   │   ├── STEP1.5_FIG6_VIOLIN_DISTRIBUTIONS.png
│   │   └── STEP1.5_FIG7_FOLD_CHANGE.png
│   ├── tables/
│   │   ├── ALL_MUTATIONS_VAF_FILTERED.csv
│   │   ├── vaf_filter_report.csv
│   │   ├── mutation_type_summary_vaf_filtered.csv
│   │   ├── position_metrics_vaf_filtered.csv
│   │   ├── sample_metrics_vaf_filtered.csv
│   │   ├── vaf_statistics_by_mirna.csv
│   │   └── vaf_statistics_by_type.csv
│   ├── data/
│   │   └── ALL_MUTATIONS_VAF_FILTERED.csv (duplicado para uso directo)
│   └── logs/
│
└── step2/
    ├── figures/
    │   ├── step2_volcano_plot.png
    │   └── step2_effect_size_distribution.png
    ├── tables/
    │   ├── step2_statistical_comparisons.csv
    │   └── step2_effect_sizes.csv
    └── logs/
```

---

## 🌐 VIEWERS HTML

Cada paso tiene un viewer HTML interactivo que muestra todas sus figuras y estadísticas:

1. **`viewers/step1.html`**
   - Step 1: 6 figuras + 5 tablas
   - Análisis exploratorio completo

2. **`viewers/step1_5.html`**
   - Step 1.5: 11 figuras (QC + Diagnósticas) + 6 tablas
   - Control de calidad VAF

3. **`viewers/step2.html`**
   - Step 2: 2 figuras + 2 tablas + estadísticas resumidas
   - Comparaciones ALS vs Control

---

## 📊 ESTADÍSTICAS POR PASO

### Step 1 (Exploratory)
- **Propósito:** Entender patrones generales
- **Focus:** Distribución posicional, contenido G, seed vs non-seed
- **Sin filtrado:** Usa todos los datos disponibles

### Step 1.5 (VAF Quality Control)
- **Propósito:** Filtrar artefactos técnicos
- **Focus:** Validar calidad de datos
- **Filtro aplicado:** VAF ≥ 0.5 → NA
- **Output clave:** `ALL_MUTATIONS_VAF_FILTERED.csv` (input para Step 2)

### Step 2 (Statistical Comparisons)
- **Propósito:** Comparar grupos ALS vs Control
- **Focus:** Significancia estadística y effect sizes
- **Métodos:** t-test, Wilcoxon, FDR correction
- **Outputs clave:** Comparaciones estadísticas + Volcano plot

---

## 🔄 FLUJO DE DATOS

```
RAW DATA
   ↓
STEP 1 (Exploratory Analysis)
   → 6 figuras + 5 tablas
   ↓
PROCESSED DATA (final_processed_data_CLEAN.csv)
   ↓
STEP 1.5 (VAF Filtering)
   → 11 figuras + 6 tablas
   → ALL_MUTATIONS_VAF_FILTERED.csv
   ↓
STEP 2 (Statistical Comparisons)
   → 2 figuras + 2 tablas
   → Comparaciones ALS vs Control
```

---

## 📝 NOTAS IMPORTANTES

1. **Step 1** usa datos sin filtrar (combinación ALS + Control)
2. **Step 1.5** aplica filtro VAF y genera datos limpios
3. **Step 2** usa datos filtrados de Step 1.5 para comparaciones
4. Todas las figuras usan temas profesionales consistentes
5. Todas las tablas son CSV para fácil análisis posterior
6. Los viewers HTML permiten revisar todos los resultados de cada paso

---

**Total: 19 figuras + 13 tablas = 32 outputs principales**


**Fecha:** 2025-11-02  
**Pipeline:** Snakemake ALS miRNA Oxidation Analysis

---

## 📋 RESUMEN EJECUTIVO

| Paso | Figuras | Tablas | Descripción |
|------|---------|--------|-------------|
| **Step 1** | 6 | 5 | Análisis exploratorio inicial |
| **Step 1.5** | 11 | 6 | Control de calidad VAF |
| **Step 2** | 2 | 2 | Comparaciones ALS vs Control |
| **TOTAL** | **19** | **13** | **32 outputs principales** |

---

## 📊 STEP 1: EXPLORATORY ANALYSIS

**Objetivo:** Análisis exploratorio inicial de las mutaciones G>T y patrones generales.

### FIGURAS (6)

#### Panel B: G>T Count by Position
- **Archivo:** `outputs/step1/figures/step1_panelB_gt_count_by_position.png`
- **Descripción:** Conteo absoluto de mutaciones G>T por posición (1-23)
- **Muestra:** Distribución de eventos de oxidación a lo largo de la secuencia miRNA

#### Panel C: G>X Mutation Spectrum by Position
- **Archivo:** `outputs/step1/figures/step1_panelC_gx_spectrum.png`
- **Descripción:** Espectro completo de mutaciones G (G>T, G>C, G>A) por posición
- **Muestra:** Prevalencia de G>T (oxidación) vs otras transiciones G

#### Panel D: Positional Fraction of Mutations
- **Archivo:** `outputs/step1/figures/step1_panelD_positional_fraction.png`
- **Descripción:** Proporción de TODAS las SNVs por posición (relativo al total)
- **Muestra:** Qué posiciones acumulan más mutaciones en general

#### Panel E: G-Content Landscape
- **Archivo:** `outputs/step1/figures/step1_panelE_gcontent.png`
- **Descripción:** Bubble plot: relación entre contenido G por posición y conteo G>T
- **Muestra:** Burbujas más grandes = mayor conteo de mutaciones

#### Panel F: Seed vs Non-seed Comparison
- **Archivo:** `outputs/step1/figures/step1_panelF_seed_interaction.png`
- **Descripción:** Comparación G>T entre región semilla (pos 1-7) vs no-semilla (pos 8-23)
- **Muestra:** Impacto funcional crítico de mutaciones en región semilla

#### Panel G: G>T Specificity (Overall)
- **Archivo:** `outputs/step1/figures/step1_panelG_gt_specificity.png`
- **Descripción:** Proporción de G>T relativo a todas las mutaciones G>X
- **Muestra:** Especificidad del daño oxidativo (8-oxoG) entre mutaciones G

### TABLAS (5)

1. **`TABLE_1.B_gt_counts_by_position.csv`**
   - Conteos de G>T por posición
   - Columnas: Position, GT_Count, Total_Count, Proportion

2. **`TABLE_1.C_gx_spectrum_by_position.csv`**
   - Espectro completo de mutaciones G>X por posición
   - Incluye: G>T, G>C, G>A y sus proporciones

3. **`TABLE_1.D_positional_fractions.csv`**
   - Fracciones posicionales de todas las mutaciones
   - Proporciones normalizadas por posición

4. **`TABLE_1.E_gcontent_landscape.csv`**
   - Contenido G y conteos G>T por posición
   - Datos para bubble plot

5. **`TABLE_1.F_seed_vs_nonseed.csv`** (si existe)
   - Estadísticas comparativas seed vs non-seed
   - Conteos y proporciones por región

---

## 🔬 STEP 1.5: VAF QUALITY CONTROL

**Objetivo:** Filtrar artefactos técnicos (VAF ≥ 0.5) y generar figuras diagnósticas.

### FIGURAS (11)

#### Quality Control Figures (4)

1. **`QC_FIG1_VAF_DISTRIBUTION.png`**
   - Distribución de VAFs antes y después del filtro
   - Histograma o density plot

2. **`QC_FIG2_FILTER_IMPACT.png`**
   - Impacto del filtro VAF
   - Cantidad de SNVs/muestras afectadas

3. **`QC_FIG3_AFFECTED_MIRNAS.png`**
   - miRNAs más afectados por el filtro
   - Ranking de miRNAs con más SNVs filtrados

4. **`QC_FIG4_BEFORE_AFTER.png`**
   - Comparación antes/después del filtro
   - Visualización del impacto en los datos

#### Diagnostic Figures (7)

5. **`STEP1.5_FIG1_HEATMAP_SNVS.png`**
   - Heatmap de número de SNVs
   - miRNAs × muestras (datos filtrados)

6. **`STEP1.5_FIG2_HEATMAP_COUNTS.png`**
   - Heatmap de conteos totales
   - miRNAs × muestras (datos filtrados)

7. **`STEP1.5_FIG3_G_TRANSVERSIONS_SNVS.png`**
   - Análisis de transiciones G por SNVs
   - G>T, G>A, etc. (datos filtrados)

8. **`STEP1.5_FIG4_G_TRANSVERSIONS_COUNTS.png`**
   - Análisis de transiciones G por conteos
   - G>T, G>A, etc. (datos filtrados)

9. **`STEP1.5_FIG5_BUBBLE_PLOT.png`**
   - Bubble plot de mutaciones
   - Visualización multidimensional

10. **`STEP1.5_FIG6_VIOLIN_DISTRIBUTIONS.png`**
    - Distribuciones violin por muestra
    - Top 8 tipos de mutación

11. **`STEP1.5_FIG7_FOLD_CHANGE.png`**
    - Análisis de fold change
    - Comparaciones de mutaciones

### TABLAS (6)

1. **`ALL_MUTATIONS_VAF_FILTERED.csv`**
   - Datos completos después del filtro VAF
   - Input principal para Step 2

2. **`vaf_filter_report.csv`**
   - Reporte del proceso de filtrado
   - Estadísticas de SNVs filtrados

3. **`mutation_type_summary_vaf_filtered.csv`**
   - Resumen por tipo de mutación (filtrado)
   - Conteos y estadísticas

4. **`position_metrics_vaf_filtered.csv`**
   - Métricas por posición (filtrado)
   - Estadísticas posicionales

5. **`sample_metrics_vaf_filtered.csv`**
   - Métricas por muestra (filtrado)
   - Estadísticas por individuo

6. **`vaf_statistics_by_mirna.csv`**
   - Estadísticas VAF por miRNA
   - Resumen por miRNA

7. **`vaf_statistics_by_type.csv`**
   - Estadísticas VAF por tipo de mutación
   - Resumen por tipo

---

## 📈 STEP 2: STATISTICAL COMPARISONS (ALS vs Control)

**Objetivo:** Comparaciones estadísticas entre grupos ALS y Control.

### FIGURAS (2)

1. **`step2_volcano_plot.png`**
   - Volcano plot: Significancia vs Fold Change
   - Eje X: log2 Fold Change (ALS/Control)
   - Eje Y: -log10 FDR-adjusted p-value
   - Categorías: Upregulated, Downregulated, Significant (low FC), High FC (not sig)
   - Colores profesionales consistentes

2. **`step2_effect_size_distribution.png`**
   - Histograma de distribución de Cohen's d
   - Categorización: Large (|d| ≥ 0.8), Medium (0.5 ≤ |d| < 0.8), Small (0.2 ≤ |d| < 0.5), Negligible (|d| < 0.2)
   - Interpretación de tamaños de efecto

### TABLAS (2)

1. **`step2_statistical_comparisons.csv`**
   - Comparaciones estadísticas completas
   - **Columnas principales:**
     - `miRNA_name`, `pos.mut`: Identificación del SNV
     - `ALS_mean`, `ALS_sd`, `ALS_n`: Estadísticas grupo ALS
     - `Control_mean`, `Control_sd`, `Control_n`: Estadísticas grupo Control
     - `fold_change`, `log2_fold_change`: Cambios de expresión
     - `t_test_pvalue`, `t_test_fdr`: Resultados test t (paramétrico)
     - `wilcoxon_pvalue`, `wilcoxon_fdr`: Resultados Wilcoxon (no paramétrico)
     - `t_test_significant`, `wilcoxon_significant`, `significant`: Flags de significancia
   - **Tamaño:** ~1.1 MB
   - **Filas:** 5,448 SNVs

2. **`step2_effect_sizes.csv`**
   - Análisis de effect size (Cohen's d)
   - **Columnas principales:**
     - `miRNA_name`, `pos.mut`: Identificación del SNV
     - `ALS_mean`, `Control_mean`: Medias por grupo
     - `log2_fold_change`: Fold change
     - `cohens_d`: Effect size (Cohen's d)
     - `effect_size_category`: Large, Medium, Small, Negligible
     - `cohens_d_ci_lower`, `cohens_d_ci_upper`: Intervalos de confianza 95%
     - `t_test_fdr`, `wilcoxon_fdr`: FDR para referencia
     - `significant`: Flag de significancia combinado
   - **Tamaño:** ~909 KB
   - **Filas:** 5,448 SNVs

---

## 📂 ESTRUCTURA DE DIRECTORIOS

```
outputs/
├── step1/
│   ├── figures/
│   │   ├── step1_panelB_gt_count_by_position.png
│   │   ├── step1_panelC_gx_spectrum.png
│   │   ├── step1_panelD_positional_fraction.png
│   │   ├── step1_panelE_gcontent.png
│   │   ├── step1_panelF_seed_interaction.png
│   │   └── step1_panelG_gt_specificity.png
│   ├── tables/
│   │   ├── TABLE_1.B_gt_counts_by_position.csv
│   │   ├── TABLE_1.C_gx_spectrum_by_position.csv
│   │   ├── TABLE_1.D_positional_fractions.csv
│   │   ├── TABLE_1.E_gcontent_landscape.csv
│   │   └── TABLE_1.F_seed_vs_nonseed.csv
│   └── logs/
│
├── step1_5/
│   ├── figures/
│   │   ├── QC_FIG1_VAF_DISTRIBUTION.png
│   │   ├── QC_FIG2_FILTER_IMPACT.png
│   │   ├── QC_FIG3_AFFECTED_MIRNAS.png
│   │   ├── QC_FIG4_BEFORE_AFTER.png
│   │   ├── STEP1.5_FIG1_HEATMAP_SNVS.png
│   │   ├── STEP1.5_FIG2_HEATMAP_COUNTS.png
│   │   ├── STEP1.5_FIG3_G_TRANSVERSIONS_SNVS.png
│   │   ├── STEP1.5_FIG4_G_TRANSVERSIONS_COUNTS.png
│   │   ├── STEP1.5_FIG5_BUBBLE_PLOT.png
│   │   ├── STEP1.5_FIG6_VIOLIN_DISTRIBUTIONS.png
│   │   └── STEP1.5_FIG7_FOLD_CHANGE.png
│   ├── tables/
│   │   ├── ALL_MUTATIONS_VAF_FILTERED.csv
│   │   ├── vaf_filter_report.csv
│   │   ├── mutation_type_summary_vaf_filtered.csv
│   │   ├── position_metrics_vaf_filtered.csv
│   │   ├── sample_metrics_vaf_filtered.csv
│   │   ├── vaf_statistics_by_mirna.csv
│   │   └── vaf_statistics_by_type.csv
│   ├── data/
│   │   └── ALL_MUTATIONS_VAF_FILTERED.csv (duplicado para uso directo)
│   └── logs/
│
└── step2/
    ├── figures/
    │   ├── step2_volcano_plot.png
    │   └── step2_effect_size_distribution.png
    ├── tables/
    │   ├── step2_statistical_comparisons.csv
    │   └── step2_effect_sizes.csv
    └── logs/
```

---

## 🌐 VIEWERS HTML

Cada paso tiene un viewer HTML interactivo que muestra todas sus figuras y estadísticas:

1. **`viewers/step1.html`**
   - Step 1: 6 figuras + 5 tablas
   - Análisis exploratorio completo

2. **`viewers/step1_5.html`**
   - Step 1.5: 11 figuras (QC + Diagnósticas) + 6 tablas
   - Control de calidad VAF

3. **`viewers/step2.html`**
   - Step 2: 2 figuras + 2 tablas + estadísticas resumidas
   - Comparaciones ALS vs Control

---

## 📊 ESTADÍSTICAS POR PASO

### Step 1 (Exploratory)
- **Propósito:** Entender patrones generales
- **Focus:** Distribución posicional, contenido G, seed vs non-seed
- **Sin filtrado:** Usa todos los datos disponibles

### Step 1.5 (VAF Quality Control)
- **Propósito:** Filtrar artefactos técnicos
- **Focus:** Validar calidad de datos
- **Filtro aplicado:** VAF ≥ 0.5 → NA
- **Output clave:** `ALL_MUTATIONS_VAF_FILTERED.csv` (input para Step 2)

### Step 2 (Statistical Comparisons)
- **Propósito:** Comparar grupos ALS vs Control
- **Focus:** Significancia estadística y effect sizes
- **Métodos:** t-test, Wilcoxon, FDR correction
- **Outputs clave:** Comparaciones estadísticas + Volcano plot

---

## 🔄 FLUJO DE DATOS

```
RAW DATA
   ↓
STEP 1 (Exploratory Analysis)
   → 6 figuras + 5 tablas
   ↓
PROCESSED DATA (final_processed_data_CLEAN.csv)
   ↓
STEP 1.5 (VAF Filtering)
   → 11 figuras + 6 tablas
   → ALL_MUTATIONS_VAF_FILTERED.csv
   ↓
STEP 2 (Statistical Comparisons)
   → 2 figuras + 2 tablas
   → Comparaciones ALS vs Control
```

---

## 📝 NOTAS IMPORTANTES

1. **Step 1** usa datos sin filtrar (combinación ALS + Control)
2. **Step 1.5** aplica filtro VAF y genera datos limpios
3. **Step 2** usa datos filtrados de Step 1.5 para comparaciones
4. Todas las figuras usan temas profesionales consistentes
5. Todas las tablas son CSV para fácil análisis posterior
6. Los viewers HTML permiten revisar todos los resultados de cada paso

---

**Total: 19 figuras + 13 tablas = 32 outputs principales**

