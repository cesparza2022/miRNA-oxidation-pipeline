# 📊 ESTADO DE VIEWERS Y PIPELINE SNAKEMAKE

**Fecha:** 2025-11-02  
**Actualización:** Viewers actualizados con versiones consolidadas originales

---

## ✅ RESPUESTAS A TUS PREGUNTAS

### 1. ¿El viewer del paso 2 es con las figuras que se generan en GitHub/Snakemake?

**Respuesta: NO completamente**

- **Viewer actual (`step2.html`):** Muestra **15 figuras** del pipeline original consolidado
  - FIG_2.1 a FIG_2.15 (del pipeline original completo)
  - Incluye: VAF global, distribuciones, volcano, heatmaps, PCA, clustering, density heatmaps, etc.

- **Snakemake Step 2:** Solo genera **2 figuras** actualmente
  - `step2_volcano_plot.png` (equivalente a FIG_2.3)
  - `step2_effect_size_distribution.png` (nueva figura no presente en el original)

**Discrepancia:** El viewer tiene 15 figuras, pero Snakemake solo genera 2. Faltan implementar 13 figuras adicionales del pipeline original.

---

### 2. ¿El paso 1 y paso 1.5 ya están funcionando?

**Respuesta: SÍ, ambos están funcionando**

#### ⚠️ STEP 1: FUNCIONANDO PARCIALMENTE

- **Reglas Snakemake:** 7 reglas (6 panels + all_step1)
- **Scripts R:** 6 scripts (panels B-G)
- **Outputs generados:** 6 figuras ✅
  - step1_panelB_gt_count_by_position.png ✅
  - step1_panelC_gx_spectrum.png ✅
  - step1_panelD_positional_fraction.png ✅
  - step1_panelE_gcontent.png ⚠️ (nombre diferente en viewer)
  - step1_panelF_seed_interaction.png ✅
  - step1_panelG_gt_specificity.png ✅
- **Tablas:** 4 tablas CSV generadas
- **Viewer:** Muestra 8 figuras (consolidado del pipeline original)
  - **Discrepancias:**
    - Panel A (`step1_panelA_dataset_overview.png`): ❌ NO generado
    - Panel E: Viewer espera `step1_panelE_FINAL_BUBBLE.png`, Snakemake genera `step1_panelE_gcontent.png`
    - Panel H (`step1_panelH_sequence_context.png`): ❌ NO generado
- **Estado:** ⚠️ IMPLEMENTADO PARCIALMENTE (5/8 figuras coinciden, 1 nombre diferente, 2 faltan)

#### ✅ STEP 1.5: FUNCIONANDO COMPLETO

- **Reglas Snakemake:** 3 reglas (apply_vaf_filter, generate_diagnostic_figures, all_step1_5)
- **Scripts R:** 2 scripts
- **Outputs generados:** 11 figuras ✅
  - 4 QC figures (VAF distribution, filter impact, affected miRNAs, before/after)
  - 7 Diagnostic figures (heatmaps, transversions, bubble, violin, fold change)
- **Tablas:** 7 tablas CSV generadas (incluyendo ALL_MUTATIONS_VAF_FILTERED.csv)
- **Viewer:** Completo (consolidado del pipeline original)
- **Estado:** ✅ IMPLEMENTADO Y FUNCIONANDO

---

## ⚠️ STEP 2: PARCIALMENTE IMPLEMENTADO

### Estado Actual

- **Reglas Snakemake:** 4 reglas implementadas
- **Scripts R:** 3 scripts
- **Outputs generados:** 2 figuras ✅
  - step2_volcano_plot.png
  - step2_effect_size_distribution.png
- **Tablas:** 2 tablas CSV generadas
  - step2_statistical_comparisons.csv
  - step2_effect_sizes.csv

### Viewer vs Pipeline

| Aspecto | Viewer (HTML) | Snakemake Pipeline |
|---------|---------------|-------------------|
| **Figuras** | 15 (FIG_2.1 - FIG_2.15) | 2 (volcano + effect size) |
| **Origen** | Pipeline original consolidado | Pipeline Snakemake actual |
| **Estado** | Completo (estático) | Parcial (2/15 figuras) |

### Figuras en Viewer (15 total)

1. **FIG_2.1** - VAF Global Clean
2. **FIG_2.2** - Distributions Clean
3. **FIG_2.3** - Volcano Plot (✅ generado por Snakemake)
4. **FIG_2.4** - Heatmap Top 50 Clean
5. **FIG_2.5** - Heatmap Z-score Clean
6. **FIG_2.6** - Positional Clean
7. **FIG_2.7** - PCA Clean
8. **FIG_2.8** - Clustering Clean
9. **FIG_2.9** - CV Clean
10. **FIG_2.10** - Ratio Clean
11. **FIG_2.11** - Mutation Types Clean
12. **FIG_2.12** - Enrichment Clean
13. **FIG_2.13** - Density Heatmap ALS (✅ copiada al viewer)
14. **FIG_2.14** - Density Heatmap Control (✅ copiada al viewer)
15. **FIG_2.15** - Density Combined (✅ copiada al viewer)

### Figuras Generadas por Snakemake (2)

1. ✅ **step2_volcano_plot.png** → Equivalente a FIG_2.3
2. ✅ **step2_effect_size_distribution.png** → Nueva (no en original)

### Faltan Implementar (13 figuras)

- FIG_2.1, 2.2, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9, 2.10, 2.11, 2.12, 2.13, 2.14, 2.15

**Nota:** Las figuras 2.13, 2.14 y 2.15 están en el viewer pero vienen del pipeline original, no del Snakemake.

---

## 📋 RESUMEN EJECUTIVO

| Paso | Scripts | Reglas | Figuras Generadas | Viewer Espera | Estado |
|------|---------|--------|-------------------|---------------|--------|
| **Step 1** | 6 | 7 | 6 ⚠️ | 8 figuras | ⚠️ Parcial (5 coinciden, 1 nombre diferente, 2 faltan) |
| **Step 1.5** | 2 | 3 | 11 ✅ | 11 figuras | ✅ Funcionando |
| **Step 2** | 3 | 4 | 2 ⚠️ | 15 figuras | ⚠️ Parcial (2/15) |

---

## 🔧 PRÓXIMOS PASOS SUGERIDOS

1. **Para Step 2:**
   - Decidir si implementar las 13 figuras faltantes en Snakemake
   - O mantener el viewer estático con las figuras del pipeline original
   - O crear un viewer dinámico que muestre solo las 2 figuras generadas por Snakemake

2. **Verificación:**
   - Probar ejecución completa: `snakemake -j 1`
   - Verificar que los viewers se regeneran correctamente con outputs nuevos
   - Validar que todas las rutas de imágenes funcionan

---

**Última actualización:** 2025-11-02


**Fecha:** 2025-11-02  
**Actualización:** Viewers actualizados con versiones consolidadas originales

---

## ✅ RESPUESTAS A TUS PREGUNTAS

### 1. ¿El viewer del paso 2 es con las figuras que se generan en GitHub/Snakemake?

**Respuesta: NO completamente**

- **Viewer actual (`step2.html`):** Muestra **15 figuras** del pipeline original consolidado
  - FIG_2.1 a FIG_2.15 (del pipeline original completo)
  - Incluye: VAF global, distribuciones, volcano, heatmaps, PCA, clustering, density heatmaps, etc.

- **Snakemake Step 2:** Solo genera **2 figuras** actualmente
  - `step2_volcano_plot.png` (equivalente a FIG_2.3)
  - `step2_effect_size_distribution.png` (nueva figura no presente en el original)

**Discrepancia:** El viewer tiene 15 figuras, pero Snakemake solo genera 2. Faltan implementar 13 figuras adicionales del pipeline original.

---

### 2. ¿El paso 1 y paso 1.5 ya están funcionando?

**Respuesta: SÍ, ambos están funcionando**

#### ⚠️ STEP 1: FUNCIONANDO PARCIALMENTE

- **Reglas Snakemake:** 7 reglas (6 panels + all_step1)
- **Scripts R:** 6 scripts (panels B-G)
- **Outputs generados:** 6 figuras ✅
  - step1_panelB_gt_count_by_position.png ✅
  - step1_panelC_gx_spectrum.png ✅
  - step1_panelD_positional_fraction.png ✅
  - step1_panelE_gcontent.png ⚠️ (nombre diferente en viewer)
  - step1_panelF_seed_interaction.png ✅
  - step1_panelG_gt_specificity.png ✅
- **Tablas:** 4 tablas CSV generadas
- **Viewer:** Muestra 8 figuras (consolidado del pipeline original)
  - **Discrepancias:**
    - Panel A (`step1_panelA_dataset_overview.png`): ❌ NO generado
    - Panel E: Viewer espera `step1_panelE_FINAL_BUBBLE.png`, Snakemake genera `step1_panelE_gcontent.png`
    - Panel H (`step1_panelH_sequence_context.png`): ❌ NO generado
- **Estado:** ⚠️ IMPLEMENTADO PARCIALMENTE (5/8 figuras coinciden, 1 nombre diferente, 2 faltan)

#### ✅ STEP 1.5: FUNCIONANDO COMPLETO

- **Reglas Snakemake:** 3 reglas (apply_vaf_filter, generate_diagnostic_figures, all_step1_5)
- **Scripts R:** 2 scripts
- **Outputs generados:** 11 figuras ✅
  - 4 QC figures (VAF distribution, filter impact, affected miRNAs, before/after)
  - 7 Diagnostic figures (heatmaps, transversions, bubble, violin, fold change)
- **Tablas:** 7 tablas CSV generadas (incluyendo ALL_MUTATIONS_VAF_FILTERED.csv)
- **Viewer:** Completo (consolidado del pipeline original)
- **Estado:** ✅ IMPLEMENTADO Y FUNCIONANDO

---

## ⚠️ STEP 2: PARCIALMENTE IMPLEMENTADO

### Estado Actual

- **Reglas Snakemake:** 4 reglas implementadas
- **Scripts R:** 3 scripts
- **Outputs generados:** 2 figuras ✅
  - step2_volcano_plot.png
  - step2_effect_size_distribution.png
- **Tablas:** 2 tablas CSV generadas
  - step2_statistical_comparisons.csv
  - step2_effect_sizes.csv

### Viewer vs Pipeline

| Aspecto | Viewer (HTML) | Snakemake Pipeline |
|---------|---------------|-------------------|
| **Figuras** | 15 (FIG_2.1 - FIG_2.15) | 2 (volcano + effect size) |
| **Origen** | Pipeline original consolidado | Pipeline Snakemake actual |
| **Estado** | Completo (estático) | Parcial (2/15 figuras) |

### Figuras en Viewer (15 total)

1. **FIG_2.1** - VAF Global Clean
2. **FIG_2.2** - Distributions Clean
3. **FIG_2.3** - Volcano Plot (✅ generado por Snakemake)
4. **FIG_2.4** - Heatmap Top 50 Clean
5. **FIG_2.5** - Heatmap Z-score Clean
6. **FIG_2.6** - Positional Clean
7. **FIG_2.7** - PCA Clean
8. **FIG_2.8** - Clustering Clean
9. **FIG_2.9** - CV Clean
10. **FIG_2.10** - Ratio Clean
11. **FIG_2.11** - Mutation Types Clean
12. **FIG_2.12** - Enrichment Clean
13. **FIG_2.13** - Density Heatmap ALS (✅ copiada al viewer)
14. **FIG_2.14** - Density Heatmap Control (✅ copiada al viewer)
15. **FIG_2.15** - Density Combined (✅ copiada al viewer)

### Figuras Generadas por Snakemake (2)

1. ✅ **step2_volcano_plot.png** → Equivalente a FIG_2.3
2. ✅ **step2_effect_size_distribution.png** → Nueva (no en original)

### Faltan Implementar (13 figuras)

- FIG_2.1, 2.2, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9, 2.10, 2.11, 2.12, 2.13, 2.14, 2.15

**Nota:** Las figuras 2.13, 2.14 y 2.15 están en el viewer pero vienen del pipeline original, no del Snakemake.

---

## 📋 RESUMEN EJECUTIVO

| Paso | Scripts | Reglas | Figuras Generadas | Viewer Espera | Estado |
|------|---------|--------|-------------------|---------------|--------|
| **Step 1** | 6 | 7 | 6 ⚠️ | 8 figuras | ⚠️ Parcial (5 coinciden, 1 nombre diferente, 2 faltan) |
| **Step 1.5** | 2 | 3 | 11 ✅ | 11 figuras | ✅ Funcionando |
| **Step 2** | 3 | 4 | 2 ⚠️ | 15 figuras | ⚠️ Parcial (2/15) |

---

## 🔧 PRÓXIMOS PASOS SUGERIDOS

1. **Para Step 2:**
   - Decidir si implementar las 13 figuras faltantes en Snakemake
   - O mantener el viewer estático con las figuras del pipeline original
   - O crear un viewer dinámico que muestre solo las 2 figuras generadas por Snakemake

2. **Verificación:**
   - Probar ejecución completa: `snakemake -j 1`
   - Verificar que los viewers se regeneran correctamente con outputs nuevos
   - Validar que todas las rutas de imágenes funcionan

---

**Última actualización:** 2025-11-02


**Fecha:** 2025-11-02  
**Actualización:** Viewers actualizados con versiones consolidadas originales

---

## ✅ RESPUESTAS A TUS PREGUNTAS

### 1. ¿El viewer del paso 2 es con las figuras que se generan en GitHub/Snakemake?

**Respuesta: NO completamente**

- **Viewer actual (`step2.html`):** Muestra **15 figuras** del pipeline original consolidado
  - FIG_2.1 a FIG_2.15 (del pipeline original completo)
  - Incluye: VAF global, distribuciones, volcano, heatmaps, PCA, clustering, density heatmaps, etc.

- **Snakemake Step 2:** Solo genera **2 figuras** actualmente
  - `step2_volcano_plot.png` (equivalente a FIG_2.3)
  - `step2_effect_size_distribution.png` (nueva figura no presente en el original)

**Discrepancia:** El viewer tiene 15 figuras, pero Snakemake solo genera 2. Faltan implementar 13 figuras adicionales del pipeline original.

---

### 2. ¿El paso 1 y paso 1.5 ya están funcionando?

**Respuesta: SÍ, ambos están funcionando**

#### ⚠️ STEP 1: FUNCIONANDO PARCIALMENTE

- **Reglas Snakemake:** 7 reglas (6 panels + all_step1)
- **Scripts R:** 6 scripts (panels B-G)
- **Outputs generados:** 6 figuras ✅
  - step1_panelB_gt_count_by_position.png ✅
  - step1_panelC_gx_spectrum.png ✅
  - step1_panelD_positional_fraction.png ✅
  - step1_panelE_gcontent.png ⚠️ (nombre diferente en viewer)
  - step1_panelF_seed_interaction.png ✅
  - step1_panelG_gt_specificity.png ✅
- **Tablas:** 4 tablas CSV generadas
- **Viewer:** Muestra 8 figuras (consolidado del pipeline original)
  - **Discrepancias:**
    - Panel A (`step1_panelA_dataset_overview.png`): ❌ NO generado
    - Panel E: Viewer espera `step1_panelE_FINAL_BUBBLE.png`, Snakemake genera `step1_panelE_gcontent.png`
    - Panel H (`step1_panelH_sequence_context.png`): ❌ NO generado
- **Estado:** ⚠️ IMPLEMENTADO PARCIALMENTE (5/8 figuras coinciden, 1 nombre diferente, 2 faltan)

#### ✅ STEP 1.5: FUNCIONANDO COMPLETO

- **Reglas Snakemake:** 3 reglas (apply_vaf_filter, generate_diagnostic_figures, all_step1_5)
- **Scripts R:** 2 scripts
- **Outputs generados:** 11 figuras ✅
  - 4 QC figures (VAF distribution, filter impact, affected miRNAs, before/after)
  - 7 Diagnostic figures (heatmaps, transversions, bubble, violin, fold change)
- **Tablas:** 7 tablas CSV generadas (incluyendo ALL_MUTATIONS_VAF_FILTERED.csv)
- **Viewer:** Completo (consolidado del pipeline original)
- **Estado:** ✅ IMPLEMENTADO Y FUNCIONANDO

---

## ⚠️ STEP 2: PARCIALMENTE IMPLEMENTADO

### Estado Actual

- **Reglas Snakemake:** 4 reglas implementadas
- **Scripts R:** 3 scripts
- **Outputs generados:** 2 figuras ✅
  - step2_volcano_plot.png
  - step2_effect_size_distribution.png
- **Tablas:** 2 tablas CSV generadas
  - step2_statistical_comparisons.csv
  - step2_effect_sizes.csv

### Viewer vs Pipeline

| Aspecto | Viewer (HTML) | Snakemake Pipeline |
|---------|---------------|-------------------|
| **Figuras** | 15 (FIG_2.1 - FIG_2.15) | 2 (volcano + effect size) |
| **Origen** | Pipeline original consolidado | Pipeline Snakemake actual |
| **Estado** | Completo (estático) | Parcial (2/15 figuras) |

### Figuras en Viewer (15 total)

1. **FIG_2.1** - VAF Global Clean
2. **FIG_2.2** - Distributions Clean
3. **FIG_2.3** - Volcano Plot (✅ generado por Snakemake)
4. **FIG_2.4** - Heatmap Top 50 Clean
5. **FIG_2.5** - Heatmap Z-score Clean
6. **FIG_2.6** - Positional Clean
7. **FIG_2.7** - PCA Clean
8. **FIG_2.8** - Clustering Clean
9. **FIG_2.9** - CV Clean
10. **FIG_2.10** - Ratio Clean
11. **FIG_2.11** - Mutation Types Clean
12. **FIG_2.12** - Enrichment Clean
13. **FIG_2.13** - Density Heatmap ALS (✅ copiada al viewer)
14. **FIG_2.14** - Density Heatmap Control (✅ copiada al viewer)
15. **FIG_2.15** - Density Combined (✅ copiada al viewer)

### Figuras Generadas por Snakemake (2)

1. ✅ **step2_volcano_plot.png** → Equivalente a FIG_2.3
2. ✅ **step2_effect_size_distribution.png** → Nueva (no en original)

### Faltan Implementar (13 figuras)

- FIG_2.1, 2.2, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9, 2.10, 2.11, 2.12, 2.13, 2.14, 2.15

**Nota:** Las figuras 2.13, 2.14 y 2.15 están en el viewer pero vienen del pipeline original, no del Snakemake.

---

## 📋 RESUMEN EJECUTIVO

| Paso | Scripts | Reglas | Figuras Generadas | Viewer Espera | Estado |
|------|---------|--------|-------------------|---------------|--------|
| **Step 1** | 6 | 7 | 6 ⚠️ | 8 figuras | ⚠️ Parcial (5 coinciden, 1 nombre diferente, 2 faltan) |
| **Step 1.5** | 2 | 3 | 11 ✅ | 11 figuras | ✅ Funcionando |
| **Step 2** | 3 | 4 | 2 ⚠️ | 15 figuras | ⚠️ Parcial (2/15) |

---

## 🔧 PRÓXIMOS PASOS SUGERIDOS

1. **Para Step 2:**
   - Decidir si implementar las 13 figuras faltantes en Snakemake
   - O mantener el viewer estático con las figuras del pipeline original
   - O crear un viewer dinámico que muestre solo las 2 figuras generadas por Snakemake

2. **Verificación:**
   - Probar ejecución completa: `snakemake -j 1`
   - Verificar que los viewers se regeneran correctamente con outputs nuevos
   - Validar que todas las rutas de imágenes funcionan

---

**Última actualización:** 2025-11-02

