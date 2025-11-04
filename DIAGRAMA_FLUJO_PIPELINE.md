# 🔄 Diagrama de Flujo del Pipeline: Preguntas y Respuestas

**Pipeline:** ALS miRNA Oxidation Analysis  
**Última actualización:** 2025-11-02

---

## 📊 Flujo Completo: INPUT → PROCESAMIENTO → OUTPUT

```
┌─────────────────────────────────────────────────────────────────┐
│                    INPUT DATA                                    │
├─────────────────────────────────────────────────────────────────┤
│ • final_processed_data_CLEAN.csv      (para Step 1)            │
│ • step1_original_data.csv              (para Step 1.5)          │
│   └─ Requiere: SNV columns + Total columns para calcular VAF   │
└─────────────────────────────────────────────────────────────────┘
                            ↓
╔═══════════════════════════════════════════════════════════════════╗
║  STEP 1: ANÁLISIS EXPLORATORIO                                   ║
╠═══════════════════════════════════════════════════════════════════╣
║  🎯 PREGUNTA CENTRAL:                                            ║
║     "¿Cómo se ven los datos antes de aplicar filtros?"          ║
║                                                                   ║
║  📊 ANÁLISIS POR PANEL:                                          ║
║                                                                   ║
║  Panel B: ¿Cuántos G>T por posición?                            ║
║    → TABLE_1.B_gt_counts_by_position.csv                         ║
║    → Métricas: total_GT_count, n_SNVs, n_miRNAs                 ║
║                                                                   ║
║  Panel C: ¿Qué tipos de mutaciones G>X?                         ║
║    → TABLE_1.C_gx_spectrum_by_position.csv                       ║
║    → Métricas: mutation_type, percentage                         ║
║                                                                   ║
║  Panel D: ¿Qué fracción de mutaciones por posición?              ║
║    → TABLE_1.D_positional_fractions.csv                          ║
║    → Métricas: fraction, snv_count                               ║
║                                                                   ║
║  Panel E: ¿Hay relación G-content vs mutaciones?                 ║
║    → TABLE_1.E_gcontent_landscape.csv                            ║
║    → Métricas: total_G_copies, GT_counts_at_position            ║
║                                                                   ║
║  Panel F: ⭐ ¿Más G>T en seed vs non-seed?                      ║
║    → TABLE_1.F_seed_vs_nonseed.csv                               ║
║    → Métricas: fraction_snvs (seed vs non-seed)                 ║
║                                                                   ║
║  Panel G: ¿Qué proporción de G>X es G>T?                        ║
║    → TABLE_1.G_gt_specificity.csv                                ║
║    → Métricas: gt_fraction                                        ║
║                                                                   ║
║  📋 OUTPUT: 6 figuras + 6 tablas resumen                         ║
║     ⚠️ NO genera datos para Step 2 (solo resúmenes)             ║
╚═══════════════════════════════════════════════════════════════════╝
                            ↓
╔═══════════════════════════════════════════════════════════════════╗
║  STEP 1.5: CONTROL DE CALIDAD VAF                                 ║
╠═══════════════════════════════════════════════════════════════════╣
║  🎯 PREGUNTA CENTRAL:                                            ║
║     "¿Qué datos son confiables (VAF < 0.5)?"                    ║
║                                                                   ║
║  📊 ANÁLISIS:                                                    ║
║                                                                   ║
║  1. Calcular VAF para cada mutación                              ║
║     VAF = SNV_count / Total_count                               ║
║                                                                   ║
║  2. Filtrar VAF >= 0.5 (artefactos técnicos)                     ║
║     → ALL_MUTATIONS_VAF_FILTERED.csv ⭐                          ║
║     ⭐ ESTE ES EL INPUT PARA STEP 2                              ║
║                                                                   ║
║  3. Generar reportes del filtro:                                 ║
║     → vaf_filter_report.csv (cuánto se perdió)                   ║
║     → vaf_statistics_by_type.csv (por tipo)                      ║
║     → vaf_statistics_by_mirna.csv (por miRNA)                    ║
║                                                                   ║
║  4. Métricas post-filtro:                                        ║
║     → sample_metrics_vaf_filtered.csv                             ║
║     → position_metrics_vaf_filtered.csv                           ║
║     → mutation_type_summary_vaf_filtered.csv                      ║
║                                                                   ║
║  📋 OUTPUT: 11 figuras + 7 tablas                                ║
║     ⭐ ALL_MUTATIONS_VAF_FILTERED.csv = INPUT para Step 2        ║
╚═══════════════════════════════════════════════════════════════════╝
                            ↓
╔═══════════════════════════════════════════════════════════════════╗
║  STEP 2: COMPARACIONES ESTADÍSTICAS (ALS vs Control)             ║
╠═══════════════════════════════════════════════════════════════════╣
║  🎯 PREGUNTA CENTRAL:                                            ║
║     "¿Hay diferencias significativas entre ALS y Control?"      ║
║                                                                   ║
║  📊 ANÁLISIS:                                                    ║
║                                                                   ║
║  1. Separar muestras en grupos (ALS vs Control)                 ║
║     Basado en nombres de muestras                                 ║
║                                                                   ║
║  2. Tests estadísticos por mutación:                             ║
║     • t-test (paramétrico)                                       ║
║     • Wilcoxon rank-sum test (no paramétrico)                    ║
║     • FDR correction (Benjamini-Hochberg)                         ║
║                                                                   ║
║     → step2_statistical_comparisons.csv ⭐                       ║
║     Columnas: ALS_mean, Control_mean, fold_change,               ║
║               p_value, p_adjusted, significant                    ║
║                                                                   ║
║  3. Calcular tamaños de efecto:                                  ║
║     • Cohen's d                                                  ║
║     • Categorías: Negligible, Small, Medium, Large                ║
║                                                                   ║
║     → step2_effect_sizes.csv                                     ║
║     Columnas: cohens_d, effect_size_category                      ║
║                                                                   ║
║  ⚠️ TABLAS FALTANTES (PROPUESTAS):                               ║
║     → S2_significant_mutations.csv (solo p_adj < 0.05)          ║
║     → S2_top_effect_sizes.csv (top 50 por efecto)                ║
║     → S2_seed_region_significant.csv (significativos en seed)   ║
║                                                                   ║
║  📋 OUTPUT: 2 figuras + 2 tablas (actuales)                     ║
║             + 3 tablas propuestas                                ║
║     ⭐ Resultados finales para interpretación y publicación     ║
╚═══════════════════════════════════════════════════════════════════╝
```

---

## 🎯 Preguntas Clave por Paso

### STEP 1: Exploratory
| # | Pregunta | Tabla | Métrica Clave |
|---|---------|-------|--------------|
| 1 | ¿Cuántos G>T por posición? | `S1_B_gt_counts_by_position.csv` | `total_GT_count`, `n_SNVs` |
| 2 | ¿Qué tipos de mutaciones G>X? | `S1_C_gx_spectrum_by_position.csv` | `mutation_type`, `percentage` |
| 3 | ¿Qué fracción por posición? | `S1_D_positional_fractions.csv` | `fraction` |
| 4 | ¿Hay relación G-content vs mutaciones? | `S1_E_gcontent_landscape.csv` | `total_G_copies` |
| 5 | ⭐ **¿Más G>T en seed vs non-seed?** | `S1_F_seed_vs_nonseed.csv` | `fraction_snvs` (seed) |
| 6 | ¿Qué proporción de G>X es G>T? | `S1_G_gt_specificity.csv` | `gt_fraction` |

### STEP 1.5: VAF QC
| # | Pregunta | Tabla | Métrica Clave |
|---|---------|-------|--------------|
| 1 | ¿Cuántos artefactos se remueven? | `S1.5_filter_report.csv` | `pct_removed` |
| 2 | ¿Qué tipos se filtran más? | `S1.5_stats_by_type.csv` | `N_Filtered`, `Mean_VAF` |
| 3 | ¿Qué miRNAs se ven afectados? | `S1.5_stats_by_mirna.csv` | `N_Filtered` |
| 4 | ⭐ **¿Cuáles son los datos limpios?** | **`ALL_MUTATIONS_VAF_FILTERED.csv`** | Todos los datos con VAF < 0.5 |

### STEP 2: Comparisons
| # | Pregunta | Tabla | Métrica Clave |
|---|---------|-------|--------------|
| 1 | ⭐ **¿Hay diferencias significativas?** | `S2_statistical_comparisons.csv` | `p_adjusted < 0.05`, `significant` |
| 2 | ¿Cuál es el tamaño del efecto? | `S2_effect_sizes.csv` | `cohens_d`, `effect_size_category` |
| 3 | ⚠️ **¿Cuáles son las mutaciones más importantes?** | **`S2_significant_mutations.csv`** | `fold_change`, `effect_size` |
| 4 | ⚠️ **¿Hay enrichment en seed región?** | **`S2_seed_region_significant.csv`** | `position` en 2-7, `significant` |

---

## 📊 Resumen de Tablas por Paso

### Step 1: 6 Tablas (Todas Resúmenes)
- ✅ `S1_B_gt_counts_by_position.csv`
- ✅ `S1_C_gx_spectrum_by_position.csv`
- ✅ `S1_D_positional_fractions.csv`
- ✅ `S1_E_gcontent_landscape.csv`
- ✅ `S1_F_seed_vs_nonseed.csv`
- ✅ `S1_G_gt_specificity.csv`

### Step 1.5: 7 Tablas
- ⭐ **`ALL_MUTATIONS_VAF_FILTERED.csv`** (INPUT Step 2)
- ✅ `S1.5_filter_report.csv`
- ✅ `S1.5_stats_by_type.csv`
- ✅ `S1.5_stats_by_mirna.csv`
- ✅ `S1.5_sample_metrics.csv`
- ✅ `S1.5_position_metrics.csv`
- ✅ `S1.5_mutation_type_summary.csv`

### Step 2: 2 Actuales + 3 Propuestas
- ✅ `S2_statistical_comparisons.csv` (completo)
- ✅ `S2_effect_sizes.csv`
- ⚠️ **`S2_significant_mutations.csv`** (PROPUESTA: solo significativos)
- ⚠️ **`S2_top_effect_sizes.csv`** (PROPUESTA: top 50)
- ⚠️ **`S2_seed_region_significant.csv`** (PROPUESTA: significativos en seed)

---

## 🔄 Flujo de Datos Crítico

```
INPUT → STEP 1.5 → STEP 2

step1_original_data.csv
  ↓
[VAF Filter: VAF < 0.5]
  ↓
ALL_MUTATIONS_VAF_FILTERED.csv ⭐
  ↓
[Statistical Tests: ALS vs Control]
  ↓
S2_statistical_comparisons.csv ⭐
```

**Nota:** Step 1 genera solo resúmenes, NO datos para Step 2.

---

## 🗂️ Propuesta de Organización Mejorada

### Estructura Actual vs Propuesta

**Actual:**
```
outputs/
├── step1/tables/          (6 tablas sin categorizar)
├── step1_5/tables/        (7 tablas mezcladas)
└── step2/tables/          (2 tablas sin interpretativas)
```

**Propuesta:**
```
outputs/
├── step1_exploratory/
│   └── tables/summary/    (6 tablas organizadas)
│
├── step1_5_vaf_qc/
│   └── tables/
│       ├── filtered_data/    ⭐ INPUT Step 2
│       ├── filter_report/    (reportes)
│       └── summary/          (métricas)
│
└── step2_comparisons/
    └── tables/
        ├── statistical_results/  (completos)
        └── summary/               ⭐ PROPUESTA (interpretativas)
```

---

## ✅ Ventajas de la Organización Propuesta

1. **Nomenclatura Consistente**
   - Prefijos: `S1_`, `S1.5_`, `S2_`
   - Fácil ordenamiento y búsqueda

2. **Separación Clara de Propósitos**
   - `filtered_data/` = Datos para downstream
   - `summary/` = Métricas resumen
   - `statistical_results/` = Resultados completos

3. **Identificación de Inputs Clave**
   - ⭐ Marca tablas usadas entre pasos
   - Claridad sobre flujo de datos

4. **Tablas Interpretativas Faltantes**
   - `S2_significant_mutations.csv` = Solo significativos
   - `S2_top_effect_sizes.csv` = Top 50
   - `S2_seed_region_significant.csv` = Seed enrichment

5. **Documentación**
   - `README_TABLES.md` en cada paso
   - Explica columnas, propósito, uso

---

## 🚀 Próximos Pasos

### Opción A: Solo Documentación (Completado ✅)
- ✅ Análisis de pasos y preguntas
- ✅ Propuesta de organización
- ✅ Identificación de tablas faltantes

### Opción B: Implementar Mejoras
1. Reorganizar estructura de outputs
2. Generar 3 tablas propuestas para Step 2
3. Crear README_TABLES.md para cada paso
4. Actualizar reglas Snakemake

### Opción C: Implementación Gradual
1. Primero: Generar tablas propuestas (sin reorganizar)
2. Segundo: Reorganizar estructura
3. Tercero: Documentación completa

---

**¿Qué opción prefieres?**


**Pipeline:** ALS miRNA Oxidation Analysis  
**Última actualización:** 2025-11-02

---

## 📊 Flujo Completo: INPUT → PROCESAMIENTO → OUTPUT

```
┌─────────────────────────────────────────────────────────────────┐
│                    INPUT DATA                                    │
├─────────────────────────────────────────────────────────────────┤
│ • final_processed_data_CLEAN.csv      (para Step 1)            │
│ • step1_original_data.csv              (para Step 1.5)          │
│   └─ Requiere: SNV columns + Total columns para calcular VAF   │
└─────────────────────────────────────────────────────────────────┘
                            ↓
╔═══════════════════════════════════════════════════════════════════╗
║  STEP 1: ANÁLISIS EXPLORATORIO                                   ║
╠═══════════════════════════════════════════════════════════════════╣
║  🎯 PREGUNTA CENTRAL:                                            ║
║     "¿Cómo se ven los datos antes de aplicar filtros?"          ║
║                                                                   ║
║  📊 ANÁLISIS POR PANEL:                                          ║
║                                                                   ║
║  Panel B: ¿Cuántos G>T por posición?                            ║
║    → TABLE_1.B_gt_counts_by_position.csv                         ║
║    → Métricas: total_GT_count, n_SNVs, n_miRNAs                 ║
║                                                                   ║
║  Panel C: ¿Qué tipos de mutaciones G>X?                         ║
║    → TABLE_1.C_gx_spectrum_by_position.csv                       ║
║    → Métricas: mutation_type, percentage                         ║
║                                                                   ║
║  Panel D: ¿Qué fracción de mutaciones por posición?              ║
║    → TABLE_1.D_positional_fractions.csv                          ║
║    → Métricas: fraction, snv_count                               ║
║                                                                   ║
║  Panel E: ¿Hay relación G-content vs mutaciones?                 ║
║    → TABLE_1.E_gcontent_landscape.csv                            ║
║    → Métricas: total_G_copies, GT_counts_at_position            ║
║                                                                   ║
║  Panel F: ⭐ ¿Más G>T en seed vs non-seed?                      ║
║    → TABLE_1.F_seed_vs_nonseed.csv                               ║
║    → Métricas: fraction_snvs (seed vs non-seed)                 ║
║                                                                   ║
║  Panel G: ¿Qué proporción de G>X es G>T?                        ║
║    → TABLE_1.G_gt_specificity.csv                                ║
║    → Métricas: gt_fraction                                        ║
║                                                                   ║
║  📋 OUTPUT: 6 figuras + 6 tablas resumen                         ║
║     ⚠️ NO genera datos para Step 2 (solo resúmenes)             ║
╚═══════════════════════════════════════════════════════════════════╝
                            ↓
╔═══════════════════════════════════════════════════════════════════╗
║  STEP 1.5: CONTROL DE CALIDAD VAF                                 ║
╠═══════════════════════════════════════════════════════════════════╣
║  🎯 PREGUNTA CENTRAL:                                            ║
║     "¿Qué datos son confiables (VAF < 0.5)?"                    ║
║                                                                   ║
║  📊 ANÁLISIS:                                                    ║
║                                                                   ║
║  1. Calcular VAF para cada mutación                              ║
║     VAF = SNV_count / Total_count                               ║
║                                                                   ║
║  2. Filtrar VAF >= 0.5 (artefactos técnicos)                     ║
║     → ALL_MUTATIONS_VAF_FILTERED.csv ⭐                          ║
║     ⭐ ESTE ES EL INPUT PARA STEP 2                              ║
║                                                                   ║
║  3. Generar reportes del filtro:                                 ║
║     → vaf_filter_report.csv (cuánto se perdió)                   ║
║     → vaf_statistics_by_type.csv (por tipo)                      ║
║     → vaf_statistics_by_mirna.csv (por miRNA)                    ║
║                                                                   ║
║  4. Métricas post-filtro:                                        ║
║     → sample_metrics_vaf_filtered.csv                             ║
║     → position_metrics_vaf_filtered.csv                           ║
║     → mutation_type_summary_vaf_filtered.csv                      ║
║                                                                   ║
║  📋 OUTPUT: 11 figuras + 7 tablas                                ║
║     ⭐ ALL_MUTATIONS_VAF_FILTERED.csv = INPUT para Step 2        ║
╚═══════════════════════════════════════════════════════════════════╝
                            ↓
╔═══════════════════════════════════════════════════════════════════╗
║  STEP 2: COMPARACIONES ESTADÍSTICAS (ALS vs Control)             ║
╠═══════════════════════════════════════════════════════════════════╣
║  🎯 PREGUNTA CENTRAL:                                            ║
║     "¿Hay diferencias significativas entre ALS y Control?"      ║
║                                                                   ║
║  📊 ANÁLISIS:                                                    ║
║                                                                   ║
║  1. Separar muestras en grupos (ALS vs Control)                 ║
║     Basado en nombres de muestras                                 ║
║                                                                   ║
║  2. Tests estadísticos por mutación:                             ║
║     • t-test (paramétrico)                                       ║
║     • Wilcoxon rank-sum test (no paramétrico)                    ║
║     • FDR correction (Benjamini-Hochberg)                         ║
║                                                                   ║
║     → step2_statistical_comparisons.csv ⭐                       ║
║     Columnas: ALS_mean, Control_mean, fold_change,               ║
║               p_value, p_adjusted, significant                    ║
║                                                                   ║
║  3. Calcular tamaños de efecto:                                  ║
║     • Cohen's d                                                  ║
║     • Categorías: Negligible, Small, Medium, Large                ║
║                                                                   ║
║     → step2_effect_sizes.csv                                     ║
║     Columnas: cohens_d, effect_size_category                      ║
║                                                                   ║
║  ⚠️ TABLAS FALTANTES (PROPUESTAS):                               ║
║     → S2_significant_mutations.csv (solo p_adj < 0.05)          ║
║     → S2_top_effect_sizes.csv (top 50 por efecto)                ║
║     → S2_seed_region_significant.csv (significativos en seed)   ║
║                                                                   ║
║  📋 OUTPUT: 2 figuras + 2 tablas (actuales)                     ║
║             + 3 tablas propuestas                                ║
║     ⭐ Resultados finales para interpretación y publicación     ║
╚═══════════════════════════════════════════════════════════════════╝
```

---

## 🎯 Preguntas Clave por Paso

### STEP 1: Exploratory
| # | Pregunta | Tabla | Métrica Clave |
|---|---------|-------|--------------|
| 1 | ¿Cuántos G>T por posición? | `S1_B_gt_counts_by_position.csv` | `total_GT_count`, `n_SNVs` |
| 2 | ¿Qué tipos de mutaciones G>X? | `S1_C_gx_spectrum_by_position.csv` | `mutation_type`, `percentage` |
| 3 | ¿Qué fracción por posición? | `S1_D_positional_fractions.csv` | `fraction` |
| 4 | ¿Hay relación G-content vs mutaciones? | `S1_E_gcontent_landscape.csv` | `total_G_copies` |
| 5 | ⭐ **¿Más G>T en seed vs non-seed?** | `S1_F_seed_vs_nonseed.csv` | `fraction_snvs` (seed) |
| 6 | ¿Qué proporción de G>X es G>T? | `S1_G_gt_specificity.csv` | `gt_fraction` |

### STEP 1.5: VAF QC
| # | Pregunta | Tabla | Métrica Clave |
|---|---------|-------|--------------|
| 1 | ¿Cuántos artefactos se remueven? | `S1.5_filter_report.csv` | `pct_removed` |
| 2 | ¿Qué tipos se filtran más? | `S1.5_stats_by_type.csv` | `N_Filtered`, `Mean_VAF` |
| 3 | ¿Qué miRNAs se ven afectados? | `S1.5_stats_by_mirna.csv` | `N_Filtered` |
| 4 | ⭐ **¿Cuáles son los datos limpios?** | **`ALL_MUTATIONS_VAF_FILTERED.csv`** | Todos los datos con VAF < 0.5 |

### STEP 2: Comparisons
| # | Pregunta | Tabla | Métrica Clave |
|---|---------|-------|--------------|
| 1 | ⭐ **¿Hay diferencias significativas?** | `S2_statistical_comparisons.csv` | `p_adjusted < 0.05`, `significant` |
| 2 | ¿Cuál es el tamaño del efecto? | `S2_effect_sizes.csv` | `cohens_d`, `effect_size_category` |
| 3 | ⚠️ **¿Cuáles son las mutaciones más importantes?** | **`S2_significant_mutations.csv`** | `fold_change`, `effect_size` |
| 4 | ⚠️ **¿Hay enrichment en seed región?** | **`S2_seed_region_significant.csv`** | `position` en 2-7, `significant` |

---

## 📊 Resumen de Tablas por Paso

### Step 1: 6 Tablas (Todas Resúmenes)
- ✅ `S1_B_gt_counts_by_position.csv`
- ✅ `S1_C_gx_spectrum_by_position.csv`
- ✅ `S1_D_positional_fractions.csv`
- ✅ `S1_E_gcontent_landscape.csv`
- ✅ `S1_F_seed_vs_nonseed.csv`
- ✅ `S1_G_gt_specificity.csv`

### Step 1.5: 7 Tablas
- ⭐ **`ALL_MUTATIONS_VAF_FILTERED.csv`** (INPUT Step 2)
- ✅ `S1.5_filter_report.csv`
- ✅ `S1.5_stats_by_type.csv`
- ✅ `S1.5_stats_by_mirna.csv`
- ✅ `S1.5_sample_metrics.csv`
- ✅ `S1.5_position_metrics.csv`
- ✅ `S1.5_mutation_type_summary.csv`

### Step 2: 2 Actuales + 3 Propuestas
- ✅ `S2_statistical_comparisons.csv` (completo)
- ✅ `S2_effect_sizes.csv`
- ⚠️ **`S2_significant_mutations.csv`** (PROPUESTA: solo significativos)
- ⚠️ **`S2_top_effect_sizes.csv`** (PROPUESTA: top 50)
- ⚠️ **`S2_seed_region_significant.csv`** (PROPUESTA: significativos en seed)

---

## 🔄 Flujo de Datos Crítico

```
INPUT → STEP 1.5 → STEP 2

step1_original_data.csv
  ↓
[VAF Filter: VAF < 0.5]
  ↓
ALL_MUTATIONS_VAF_FILTERED.csv ⭐
  ↓
[Statistical Tests: ALS vs Control]
  ↓
S2_statistical_comparisons.csv ⭐
```

**Nota:** Step 1 genera solo resúmenes, NO datos para Step 2.

---

## 🗂️ Propuesta de Organización Mejorada

### Estructura Actual vs Propuesta

**Actual:**
```
outputs/
├── step1/tables/          (6 tablas sin categorizar)
├── step1_5/tables/        (7 tablas mezcladas)
└── step2/tables/          (2 tablas sin interpretativas)
```

**Propuesta:**
```
outputs/
├── step1_exploratory/
│   └── tables/summary/    (6 tablas organizadas)
│
├── step1_5_vaf_qc/
│   └── tables/
│       ├── filtered_data/    ⭐ INPUT Step 2
│       ├── filter_report/    (reportes)
│       └── summary/          (métricas)
│
└── step2_comparisons/
    └── tables/
        ├── statistical_results/  (completos)
        └── summary/               ⭐ PROPUESTA (interpretativas)
```

---

## ✅ Ventajas de la Organización Propuesta

1. **Nomenclatura Consistente**
   - Prefijos: `S1_`, `S1.5_`, `S2_`
   - Fácil ordenamiento y búsqueda

2. **Separación Clara de Propósitos**
   - `filtered_data/` = Datos para downstream
   - `summary/` = Métricas resumen
   - `statistical_results/` = Resultados completos

3. **Identificación de Inputs Clave**
   - ⭐ Marca tablas usadas entre pasos
   - Claridad sobre flujo de datos

4. **Tablas Interpretativas Faltantes**
   - `S2_significant_mutations.csv` = Solo significativos
   - `S2_top_effect_sizes.csv` = Top 50
   - `S2_seed_region_significant.csv` = Seed enrichment

5. **Documentación**
   - `README_TABLES.md` en cada paso
   - Explica columnas, propósito, uso

---

## 🚀 Próximos Pasos

### Opción A: Solo Documentación (Completado ✅)
- ✅ Análisis de pasos y preguntas
- ✅ Propuesta de organización
- ✅ Identificación de tablas faltantes

### Opción B: Implementar Mejoras
1. Reorganizar estructura de outputs
2. Generar 3 tablas propuestas para Step 2
3. Crear README_TABLES.md para cada paso
4. Actualizar reglas Snakemake

### Opción C: Implementación Gradual
1. Primero: Generar tablas propuestas (sin reorganizar)
2. Segundo: Reorganizar estructura
3. Tercero: Documentación completa

---

**¿Qué opción prefieres?**


**Pipeline:** ALS miRNA Oxidation Analysis  
**Última actualización:** 2025-11-02

---

## 📊 Flujo Completo: INPUT → PROCESAMIENTO → OUTPUT

```
┌─────────────────────────────────────────────────────────────────┐
│                    INPUT DATA                                    │
├─────────────────────────────────────────────────────────────────┤
│ • final_processed_data_CLEAN.csv      (para Step 1)            │
│ • step1_original_data.csv              (para Step 1.5)          │
│   └─ Requiere: SNV columns + Total columns para calcular VAF   │
└─────────────────────────────────────────────────────────────────┘
                            ↓
╔═══════════════════════════════════════════════════════════════════╗
║  STEP 1: ANÁLISIS EXPLORATORIO                                   ║
╠═══════════════════════════════════════════════════════════════════╣
║  🎯 PREGUNTA CENTRAL:                                            ║
║     "¿Cómo se ven los datos antes de aplicar filtros?"          ║
║                                                                   ║
║  📊 ANÁLISIS POR PANEL:                                          ║
║                                                                   ║
║  Panel B: ¿Cuántos G>T por posición?                            ║
║    → TABLE_1.B_gt_counts_by_position.csv                         ║
║    → Métricas: total_GT_count, n_SNVs, n_miRNAs                 ║
║                                                                   ║
║  Panel C: ¿Qué tipos de mutaciones G>X?                         ║
║    → TABLE_1.C_gx_spectrum_by_position.csv                       ║
║    → Métricas: mutation_type, percentage                         ║
║                                                                   ║
║  Panel D: ¿Qué fracción de mutaciones por posición?              ║
║    → TABLE_1.D_positional_fractions.csv                          ║
║    → Métricas: fraction, snv_count                               ║
║                                                                   ║
║  Panel E: ¿Hay relación G-content vs mutaciones?                 ║
║    → TABLE_1.E_gcontent_landscape.csv                            ║
║    → Métricas: total_G_copies, GT_counts_at_position            ║
║                                                                   ║
║  Panel F: ⭐ ¿Más G>T en seed vs non-seed?                      ║
║    → TABLE_1.F_seed_vs_nonseed.csv                               ║
║    → Métricas: fraction_snvs (seed vs non-seed)                 ║
║                                                                   ║
║  Panel G: ¿Qué proporción de G>X es G>T?                        ║
║    → TABLE_1.G_gt_specificity.csv                                ║
║    → Métricas: gt_fraction                                        ║
║                                                                   ║
║  📋 OUTPUT: 6 figuras + 6 tablas resumen                         ║
║     ⚠️ NO genera datos para Step 2 (solo resúmenes)             ║
╚═══════════════════════════════════════════════════════════════════╝
                            ↓
╔═══════════════════════════════════════════════════════════════════╗
║  STEP 1.5: CONTROL DE CALIDAD VAF                                 ║
╠═══════════════════════════════════════════════════════════════════╣
║  🎯 PREGUNTA CENTRAL:                                            ║
║     "¿Qué datos son confiables (VAF < 0.5)?"                    ║
║                                                                   ║
║  📊 ANÁLISIS:                                                    ║
║                                                                   ║
║  1. Calcular VAF para cada mutación                              ║
║     VAF = SNV_count / Total_count                               ║
║                                                                   ║
║  2. Filtrar VAF >= 0.5 (artefactos técnicos)                     ║
║     → ALL_MUTATIONS_VAF_FILTERED.csv ⭐                          ║
║     ⭐ ESTE ES EL INPUT PARA STEP 2                              ║
║                                                                   ║
║  3. Generar reportes del filtro:                                 ║
║     → vaf_filter_report.csv (cuánto se perdió)                   ║
║     → vaf_statistics_by_type.csv (por tipo)                      ║
║     → vaf_statistics_by_mirna.csv (por miRNA)                    ║
║                                                                   ║
║  4. Métricas post-filtro:                                        ║
║     → sample_metrics_vaf_filtered.csv                             ║
║     → position_metrics_vaf_filtered.csv                           ║
║     → mutation_type_summary_vaf_filtered.csv                      ║
║                                                                   ║
║  📋 OUTPUT: 11 figuras + 7 tablas                                ║
║     ⭐ ALL_MUTATIONS_VAF_FILTERED.csv = INPUT para Step 2        ║
╚═══════════════════════════════════════════════════════════════════╝
                            ↓
╔═══════════════════════════════════════════════════════════════════╗
║  STEP 2: COMPARACIONES ESTADÍSTICAS (ALS vs Control)             ║
╠═══════════════════════════════════════════════════════════════════╣
║  🎯 PREGUNTA CENTRAL:                                            ║
║     "¿Hay diferencias significativas entre ALS y Control?"      ║
║                                                                   ║
║  📊 ANÁLISIS:                                                    ║
║                                                                   ║
║  1. Separar muestras en grupos (ALS vs Control)                 ║
║     Basado en nombres de muestras                                 ║
║                                                                   ║
║  2. Tests estadísticos por mutación:                             ║
║     • t-test (paramétrico)                                       ║
║     • Wilcoxon rank-sum test (no paramétrico)                    ║
║     • FDR correction (Benjamini-Hochberg)                         ║
║                                                                   ║
║     → step2_statistical_comparisons.csv ⭐                       ║
║     Columnas: ALS_mean, Control_mean, fold_change,               ║
║               p_value, p_adjusted, significant                    ║
║                                                                   ║
║  3. Calcular tamaños de efecto:                                  ║
║     • Cohen's d                                                  ║
║     • Categorías: Negligible, Small, Medium, Large                ║
║                                                                   ║
║     → step2_effect_sizes.csv                                     ║
║     Columnas: cohens_d, effect_size_category                      ║
║                                                                   ║
║  ⚠️ TABLAS FALTANTES (PROPUESTAS):                               ║
║     → S2_significant_mutations.csv (solo p_adj < 0.05)          ║
║     → S2_top_effect_sizes.csv (top 50 por efecto)                ║
║     → S2_seed_region_significant.csv (significativos en seed)   ║
║                                                                   ║
║  📋 OUTPUT: 2 figuras + 2 tablas (actuales)                     ║
║             + 3 tablas propuestas                                ║
║     ⭐ Resultados finales para interpretación y publicación     ║
╚═══════════════════════════════════════════════════════════════════╝
```

---

## 🎯 Preguntas Clave por Paso

### STEP 1: Exploratory
| # | Pregunta | Tabla | Métrica Clave |
|---|---------|-------|--------------|
| 1 | ¿Cuántos G>T por posición? | `S1_B_gt_counts_by_position.csv` | `total_GT_count`, `n_SNVs` |
| 2 | ¿Qué tipos de mutaciones G>X? | `S1_C_gx_spectrum_by_position.csv` | `mutation_type`, `percentage` |
| 3 | ¿Qué fracción por posición? | `S1_D_positional_fractions.csv` | `fraction` |
| 4 | ¿Hay relación G-content vs mutaciones? | `S1_E_gcontent_landscape.csv` | `total_G_copies` |
| 5 | ⭐ **¿Más G>T en seed vs non-seed?** | `S1_F_seed_vs_nonseed.csv` | `fraction_snvs` (seed) |
| 6 | ¿Qué proporción de G>X es G>T? | `S1_G_gt_specificity.csv` | `gt_fraction` |

### STEP 1.5: VAF QC
| # | Pregunta | Tabla | Métrica Clave |
|---|---------|-------|--------------|
| 1 | ¿Cuántos artefactos se remueven? | `S1.5_filter_report.csv` | `pct_removed` |
| 2 | ¿Qué tipos se filtran más? | `S1.5_stats_by_type.csv` | `N_Filtered`, `Mean_VAF` |
| 3 | ¿Qué miRNAs se ven afectados? | `S1.5_stats_by_mirna.csv` | `N_Filtered` |
| 4 | ⭐ **¿Cuáles son los datos limpios?** | **`ALL_MUTATIONS_VAF_FILTERED.csv`** | Todos los datos con VAF < 0.5 |

### STEP 2: Comparisons
| # | Pregunta | Tabla | Métrica Clave |
|---|---------|-------|--------------|
| 1 | ⭐ **¿Hay diferencias significativas?** | `S2_statistical_comparisons.csv` | `p_adjusted < 0.05`, `significant` |
| 2 | ¿Cuál es el tamaño del efecto? | `S2_effect_sizes.csv` | `cohens_d`, `effect_size_category` |
| 3 | ⚠️ **¿Cuáles son las mutaciones más importantes?** | **`S2_significant_mutations.csv`** | `fold_change`, `effect_size` |
| 4 | ⚠️ **¿Hay enrichment en seed región?** | **`S2_seed_region_significant.csv`** | `position` en 2-7, `significant` |

---

## 📊 Resumen de Tablas por Paso

### Step 1: 6 Tablas (Todas Resúmenes)
- ✅ `S1_B_gt_counts_by_position.csv`
- ✅ `S1_C_gx_spectrum_by_position.csv`
- ✅ `S1_D_positional_fractions.csv`
- ✅ `S1_E_gcontent_landscape.csv`
- ✅ `S1_F_seed_vs_nonseed.csv`
- ✅ `S1_G_gt_specificity.csv`

### Step 1.5: 7 Tablas
- ⭐ **`ALL_MUTATIONS_VAF_FILTERED.csv`** (INPUT Step 2)
- ✅ `S1.5_filter_report.csv`
- ✅ `S1.5_stats_by_type.csv`
- ✅ `S1.5_stats_by_mirna.csv`
- ✅ `S1.5_sample_metrics.csv`
- ✅ `S1.5_position_metrics.csv`
- ✅ `S1.5_mutation_type_summary.csv`

### Step 2: 2 Actuales + 3 Propuestas
- ✅ `S2_statistical_comparisons.csv` (completo)
- ✅ `S2_effect_sizes.csv`
- ⚠️ **`S2_significant_mutations.csv`** (PROPUESTA: solo significativos)
- ⚠️ **`S2_top_effect_sizes.csv`** (PROPUESTA: top 50)
- ⚠️ **`S2_seed_region_significant.csv`** (PROPUESTA: significativos en seed)

---

## 🔄 Flujo de Datos Crítico

```
INPUT → STEP 1.5 → STEP 2

step1_original_data.csv
  ↓
[VAF Filter: VAF < 0.5]
  ↓
ALL_MUTATIONS_VAF_FILTERED.csv ⭐
  ↓
[Statistical Tests: ALS vs Control]
  ↓
S2_statistical_comparisons.csv ⭐
```

**Nota:** Step 1 genera solo resúmenes, NO datos para Step 2.

---

## 🗂️ Propuesta de Organización Mejorada

### Estructura Actual vs Propuesta

**Actual:**
```
outputs/
├── step1/tables/          (6 tablas sin categorizar)
├── step1_5/tables/        (7 tablas mezcladas)
└── step2/tables/          (2 tablas sin interpretativas)
```

**Propuesta:**
```
outputs/
├── step1_exploratory/
│   └── tables/summary/    (6 tablas organizadas)
│
├── step1_5_vaf_qc/
│   └── tables/
│       ├── filtered_data/    ⭐ INPUT Step 2
│       ├── filter_report/    (reportes)
│       └── summary/          (métricas)
│
└── step2_comparisons/
    └── tables/
        ├── statistical_results/  (completos)
        └── summary/               ⭐ PROPUESTA (interpretativas)
```

---

## ✅ Ventajas de la Organización Propuesta

1. **Nomenclatura Consistente**
   - Prefijos: `S1_`, `S1.5_`, `S2_`
   - Fácil ordenamiento y búsqueda

2. **Separación Clara de Propósitos**
   - `filtered_data/` = Datos para downstream
   - `summary/` = Métricas resumen
   - `statistical_results/` = Resultados completos

3. **Identificación de Inputs Clave**
   - ⭐ Marca tablas usadas entre pasos
   - Claridad sobre flujo de datos

4. **Tablas Interpretativas Faltantes**
   - `S2_significant_mutations.csv` = Solo significativos
   - `S2_top_effect_sizes.csv` = Top 50
   - `S2_seed_region_significant.csv` = Seed enrichment

5. **Documentación**
   - `README_TABLES.md` en cada paso
   - Explica columnas, propósito, uso

---

## 🚀 Próximos Pasos

### Opción A: Solo Documentación (Completado ✅)
- ✅ Análisis de pasos y preguntas
- ✅ Propuesta de organización
- ✅ Identificación de tablas faltantes

### Opción B: Implementar Mejoras
1. Reorganizar estructura de outputs
2. Generar 3 tablas propuestas para Step 2
3. Crear README_TABLES.md para cada paso
4. Actualizar reglas Snakemake

### Opción C: Implementación Gradual
1. Primero: Generar tablas propuestas (sin reorganizar)
2. Segundo: Reorganizar estructura
3. Tercero: Documentación completa

---

**¿Qué opción prefieres?**

