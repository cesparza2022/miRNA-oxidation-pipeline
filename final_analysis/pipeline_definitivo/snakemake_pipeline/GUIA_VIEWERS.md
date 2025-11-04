# 🌐 GUÍA DE VIEWERS HTML

**Fecha:** 2025-11-02  
**Pipeline:** Snakemake ALS miRNA Oxidation Analysis

---

## 📋 VIEWERS DISPONIBLES

Cada paso del pipeline tiene un viewer HTML interactivo que muestra todas las figuras, tablas y estadísticas generadas.

### Ubicación
```
viewers/
├── step1.html      (1.4 MB)
├── step1_5.html    (1.6 MB)
└── step2.html      (898 KB)
```

---

## 📊 STEP 1 VIEWER (`viewers/step1.html`)

**Contenido:** Análisis exploratorio inicial

### Figuras Incluidas (6)

1. **Panel B: G>T Count by Position**
   - Conteo absoluto de mutaciones G>T por posición
   - Distribución a lo largo de la secuencia miRNA

2. **Panel C: G>X Mutation Spectrum by Position**
   - Espectro completo de mutaciones G (G>T, G>C, G>A)
   - Comparación de G>T vs otras transiciones

3. **Panel D: Positional Fraction of Mutations**
   - Proporción de todas las SNVs por posición
   - Normalizado al total de mutaciones

4. **Panel E: G-Content Landscape**
   - Bubble plot: relación contenido G vs conteo G>T
   - Visualización multidimensional

5. **Panel F: Seed vs Non-seed Comparison**
   - Comparación entre región semilla (pos 1-7) y no-semilla (pos 8-23)
   - Impacto funcional crítico

6. **Panel G: G>T Specificity (Overall)**
   - Proporción de G>T relativo a todas las mutaciones G>X
   - Especificidad del daño oxidativo

### Tablas Incluidas (4)

- `TABLE_1.B_gt_counts_by_position.csv`
- `TABLE_1.C_gx_spectrum_by_position.csv`
- `TABLE_1.D_positional_fractions.csv`
- `TABLE_1.E_gcontent_landscape.csv`

### Características

- ✅ Navegación por secciones
- ✅ Descripción detallada de cada panel
- ✅ Imágenes embebidas (base64)
- ✅ Enlaces a tablas CSV descargables
- ✅ Diseño responsive

---

## 🔬 STEP 1.5 VIEWER (`viewers/step1_5.html`)

**Contenido:** Control de calidad VAF y análisis diagnósticos

### Figuras Incluidas (11)

#### Quality Control (4)

1. **QC_FIG1_VAF_DISTRIBUTION.png**
   - Distribución de VAFs antes y después del filtro
   - Histogramas/density plots comparativos

2. **QC_FIG2_FILTER_IMPACT.png**
   - Impacto del filtro VAF (≥ 0.5)
   - Cantidad de SNVs/muestras afectadas

3. **QC_FIG3_AFFECTED_MIRNAS.png**
   - miRNAs más afectados por el filtro
   - Ranking de miRNAs con más SNVs filtrados

4. **QC_FIG4_BEFORE_AFTER.png**
   - Comparación visual antes/después del filtro
   - Validación del proceso de calidad

#### Diagnósticas (7)

5. **STEP1.5_FIG1_HEATMAP_SNVS.png**
   - Heatmap de número de SNVs (datos filtrados)
   - miRNAs × muestras

6. **STEP1.5_FIG2_HEATMAP_COUNTS.png**
   - Heatmap de conteos totales (datos filtrados)
   - miRNAs × muestras

7. **STEP1.5_FIG3_G_TRANSVERSIONS_SNVS.png**
   - Análisis de transiciones G por SNVs
   - G>T, G>A, G>C (datos filtrados)

8. **STEP1.5_FIG4_G_TRANSVERSIONS_COUNTS.png**
   - Análisis de transiciones G por conteos
   - G>T, G>A, G>C (datos filtrados)

9. **STEP1.5_FIG5_BUBBLE_PLOT.png**
   - Bubble plot multidimensional
   - Visualización de múltiples métricas

10. **STEP1.5_FIG6_VIOLIN_DISTRIBUTIONS.png**
    - Distribuciones violin por muestra
    - Top 8 tipos de mutación

11. **STEP1.5_FIG7_FOLD_CHANGE.png**
    - Análisis de fold change
    - Comparaciones de mutaciones

### Tablas Incluidas (7)

1. `ALL_MUTATIONS_VAF_FILTERED.csv` ⭐
   - Datos filtrados principales (input para Step 2)

2. `vaf_filter_report.csv`
   - Reporte completo del proceso de filtrado

3. `mutation_type_summary_vaf_filtered.csv`
   - Resumen por tipo de mutación

4. `position_metrics_vaf_filtered.csv`
   - Métricas por posición

5. `sample_metrics_vaf_filtered.csv`
   - Métricas por muestra

6. `vaf_statistics_by_mirna.csv`
   - Estadísticas VAF por miRNA

7. `vaf_statistics_by_type.csv`
   - Estadísticas VAF por tipo

### Características

- ✅ Separación entre figuras QC y Diagnósticas
- ✅ Estadísticas de filtrado destacadas
- ✅ Comparaciones antes/después
- ✅ Tablas descargables

---

## 📈 STEP 2 VIEWER (`viewers/step2.html`)

**Contenido:** Comparaciones estadísticas ALS vs Control

### Figuras Incluidas (2)

1. **step2_volcano_plot.png**
   - Volcano plot profesional
   - Eje X: log2 Fold Change (ALS/Control)
   - Eje Y: -log10 FDR-adjusted p-value
   - Categorización:
     - 🔴 Rojo: Upregulated (ALS > Control)
     - 🔵 Azul: Downregulated (ALS < Control)
     - 🟠 Naranja: Significant (low FC)
     - ⚪ Gris: Not significant / High FC (not sig)

2. **step2_effect_size_distribution.png**
   - Histograma de distribución de Cohen's d
   - Categorización visual:
     - Large (|d| ≥ 0.8): Rojo
     - Medium (0.5 ≤ |d| < 0.8): Naranja
     - Small (0.2 ≤ |d| < 0.5): Amarillo claro
     - Negligible (|d| < 0.2): Gris

### Tablas Incluidas (2)

1. **step2_statistical_comparisons.csv** (1.1 MB)
   - Comparaciones estadísticas completas
   - **Contenido:**
     - Identificación: miRNA_name, pos.mut
     - Estadísticas ALS: mean, sd, n
     - Estadísticas Control: mean, sd, n
     - Fold changes: fold_change, log2_fold_change
     - Tests paramétricos: t_test_pvalue, t_test_fdr
     - Tests no paramétricos: wilcoxon_pvalue, wilcoxon_fdr
     - Flags de significancia: t_test_significant, wilcoxon_significant, significant
   - **Total:** 5,448 SNVs

2. **step2_effect_sizes.csv** (909 KB)
   - Análisis de effect size (Cohen's d)
   - **Contenido:**
     - Identificación: miRNA_name, pos.mut
     - Effect size: cohens_d, effect_size_category
     - Intervalos de confianza: cohens_d_ci_lower, cohens_d_ci_upper
     - Referencia estadística: t_test_fdr, wilcoxon_fdr
     - Flag de significancia: significant
   - **Total:** 5,448 SNVs

### Estadísticas Resumidas

El viewer muestra un resumen destacado con:

- **Total SNVs analizados:** 5,448
- **Significativos (FDR < 0.05):** 269
- **Upregulated (ALS > Control):** 19
- **Downregulated (ALS < Control):** 92

### Características

- ✅ Estadísticas resumidas destacadas
- ✅ Visualización clara de resultados
- ✅ Figuras profesionales embebidas
- ✅ Información de interpretación

---

## 🚀 CÓMO USAR LOS VIEWERS

### Opción 1: Abrir desde el sistema
```bash
open viewers/step1.html
open viewers/step1_5.html
open viewers/step2.html
```

### Opción 2: Abrir desde navegador
- Navegar a: `/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/pipeline_definitivo/snakemake_pipeline/viewers/`
- Abrir cualquier archivo `.html` directamente

### Opción 3: Generar automáticamente con Snakemake
```bash
# Generar todos los viewers
snakemake -j 1 generate_step1_viewer generate_step1_5_viewer generate_step2_viewer

# O generar todos los outputs (incluye viewers)
snakemake -j 1
```

---

## 📝 NOTAS

1. **Imágenes embebidas:** Los viewers usan imágenes base64 para portabilidad
2. **Tamaños:** Los viewers son grandes (1-1.6 MB) debido a imágenes embebidas
3. **Compatibilidad:** Funcionan en cualquier navegador moderno
4. **Actualización:** Se regeneran automáticamente cuando cambian los outputs

---

**Todos los viewers están listos para revisar! 🎉**

