# 🗂️ Propuesta de Organización Mejorada de Outputs

**Fecha:** 2025-11-02  
**Objetivo:** Mejorar la organización de outputs para facilitar interpretación y uso downstream

---

## 📊 Análisis Actual: Qué Hacemos y Qué Preguntas Respondemos

### 🔬 STEP 1: Análisis Exploratorio

#### Preguntas Biológicas que Responde:

| Panel | Pregunta Principal | Métrica Clave | Interpretación |
|-------|-------------------|---------------|----------------|
| **B** | ¿Cuántos SNVs G>T hay por posición? | `total_GT_count`, `n_SNVs` | Identifica hotspots de mutación G>T |
| **C** | ¿Qué tipos de mutaciones G>X ocurren? | `mutation_type`, `percentage` | Espectro mutacional completo (G>A, G>T, G>C) |
| **D** | ¿Qué fracción de mutaciones ocurren en cada posición? | `fraction` | Posiciones con proporciones desproporcionadas |
| **E** | ¿Hay relación entre contenido G y mutaciones? | `total_G_copies`, `GT_counts_at_position` | Validación mecanicista |
| **F** | ¿Más mutaciones G>T en seed vs non-seed? | `fraction_snvs`, `fraction_counts` | **Pregunta clave:** Seed region enrichment |
| **G** | ¿Qué proporción de G>X es específicamente G>T? | `gt_fraction` | Especificidad de oxidación G>T |

#### Tablas Generadas (6 tablas):

| Tabla | Propósito | Uso Downstream | Columnas Clave |
|-------|-----------|----------------|---------------|
| `S1_B_gt_counts_by_position.csv` | Conteos G>T por posición | **Input para análisis estadísticos** | `position`, `total_GT_count`, `n_SNVs`, `n_miRNAs` |
| `S1_C_gx_spectrum_by_position.csv` | Espectro G>X | Análisis de patrones mutacionales | `position`, `mutation_type`, `n`, `percentage` |
| `S1_D_positional_fractions.csv` | Fracciones posicionales | Identificar posiciones importantes | `position`, `snv_count`, `fraction`, `region` |
| `S1_E_gcontent_landscape.csv` | Contenido G por posición | Validación mecanicista | `Position`, `total_G_copies`, `GT_counts_at_position` |
| `S1_F_seed_vs_nonseed.csv` | Comparación seed/non-seed | **Pregunta biológica clave** | `region`, `total_snvs`, `fraction_snvs`, `fraction_counts` |
| `S1_G_gt_specificity.csv` | Especificidad G>T | Análisis de oxidación | `position`, `gt_count`, `gt_fraction` |

---

### 🔍 STEP 1.5: Control de Calidad VAF

#### Preguntas que Responde:

1. **¿Cuántos artefactos técnicos hay?**
   - Tabla: `S1.5_filter_report.csv`
   - Métricas: `n_before`, `n_after`, `n_removed`, `pct_removed`

2. **¿Qué tipos de mutaciones se filtran más?**
   - Tabla: `S1.5_stats_by_type.csv`
   - Métricas: `N_Filtered`, `Mean_VAF`, `Min_VAF`, `Max_VAF`

3. **¿Qué miRNAs se ven más afectados?**
   - Tabla: `S1.5_stats_by_mirna.csv`
   - Métricas: `N_Filtered`, `Mean_VAF`, `Samples_Affected`

4. **¿Cuáles son las métricas después del filtro?**
   - Tablas: `S1.5_sample_metrics.csv`, `S1.5_position_metrics.csv`, `S1.5_mutation_type_summary.csv`

#### Tabla Clave ⭐ (INPUT para Step 2):

**`ALL_MUTATIONS_VAF_FILTERED.csv`**
- **Propósito:** Datos filtrados listos para análisis downstream
- **Columnas:** `miRNA name`, `pos:mut`, `VAF`, `Sample_SNV`, `Sample (PM+1MM+2MM)`, ...
- **Uso:** Este es el input principal para Step 2 (comparaciones ALS vs Control)

---

### 📊 STEP 2: Comparaciones Estadísticas (ALS vs Control)

#### Preguntas que Responde:

1. **¿Hay diferencias significativas entre ALS y Control?**
   - Tabla: `S2_statistical_comparisons.csv`
   - Métricas: `ALS_mean`, `Control_mean`, `fold_change`, `p_value`, `p_adjusted`, `significant`

2. **¿Cuál es el tamaño del efecto?**
   - Tabla: `S2_effect_sizes.csv`
   - Métricas: `cohens_d`, `effect_size_category`, `log2_fold_change`

3. **¿Qué mutaciones son más importantes?**
   - ⚠️ **FALTA:** Tabla de mutaciones significativas resumidas
   - **Propuesta:** `S2_significant_mutations_summary.csv`

#### Tablas Generadas (2 actuales + 1 propuesta):

| Tabla | Propósito | Columnas Clave |
|-------|-----------|---------------|
| `S2_statistical_comparisons.csv` | Resultados completos de tests | `SNV_id`, `ALS_mean`, `Control_mean`, `fold_change`, `p_value`, `p_adjusted`, `significant` |
| `S2_effect_sizes.csv` | Tamaños de efecto | `miRNA_name`, `pos.mut`, `cohens_d`, `effect_size_category` |
| `S2_significant_mutations_summary.csv` | ⭐ **PROPUESTA:** Resumen de significativos | `SNV_id`, `miRNA_name`, `position`, `mutation_type`, `fold_change`, `p_adjusted`, `effect_size` |

---

## 🗂️ Estructura Propuesta Mejorada

```
outputs/
│
├── step1_exploratory/
│   ├── figures/
│   │   ├── panel_B_gt_counts_by_position.png
│   │   ├── panel_C_gx_spectrum.png
│   │   ├── panel_D_positional_fraction.png
│   │   ├── panel_E_gcontent_landscape.png
│   │   ├── panel_F_seed_vs_nonseed.png
│   │   └── panel_G_gt_specificity.png
│   │
│   ├── tables/
│   │   ├── summary/              # Tablas resumen por análisis
│   │   │   ├── S1_B_gt_counts_by_position.csv
│   │   │   ├── S1_C_gx_spectrum_by_position.csv
│   │   │   ├── S1_D_positional_fractions.csv
│   │   │   ├── S1_E_gcontent_landscape.csv
│   │   │   ├── S1_F_seed_vs_nonseed.csv
│   │   │   └── S1_G_gt_specificity.csv
│   │   │
│   │   └── README_TABLES.md      # Documentación de tablas
│   │
│   ├── viewer/
│   │   └── step1.html
│   │
│   └── logs/
│
├── step1_5_vaf_qc/
│   ├── figures/
│   │   ├── qc/                    # Quality control figures
│   │   │   ├── QC_FIG1_VAF_DISTRIBUTION.png
│   │   │   ├── QC_FIG2_FILTER_IMPACT.png
│   │   │   ├── QC_FIG3_AFFECTED_MIRNAS.png
│   │   │   └── QC_FIG4_BEFORE_AFTER.png
│   │   │
│   │   └── diagnostic/            # Diagnostic figures
│   │       ├── STEP1.5_FIG1_HEATMAP_SNVS.png
│   │       ├── STEP1.5_FIG2_HEATMAP_COUNTS.png
│   │       ├── STEP1.5_FIG3_G_TRANSVERSIONS_SNVS.png
│   │       ├── STEP1.5_FIG4_G_TRANSVERSIONS_COUNTS.png
│   │       ├── STEP1.5_FIG5_BUBBLE_PLOT.png
│   │       ├── STEP1.5_FIG6_VIOLIN_DISTRIBUTIONS.png
│   │       └── STEP1.5_FIG7_FOLD_CHANGE.png
│   │
│   ├── tables/
│   │   ├── filtered_data/         # ⭐ INPUT para Step 2
│   │   │   └── ALL_MUTATIONS_VAF_FILTERED.csv
│   │   │
│   │   ├── filter_report/         # Reportes del filtro
│   │   │   ├── S1.5_filter_report.csv
│   │   │   ├── S1.5_stats_by_type.csv
│   │   │   └── S1.5_stats_by_mirna.csv
│   │   │
│   │   ├── summary/               # Métricas resumen
│   │   │   ├── S1.5_sample_metrics.csv
│   │   │   ├── S1.5_position_metrics.csv
│   │   │   └── S1.5_mutation_type_summary.csv
│   │   │
│   │   └── README_TABLES.md
│   │
│   ├── viewer/
│   │   └── step1_5.html
│   │
│   └── logs/
│
└── step2_comparisons/
    ├── figures/
    │   ├── S2_volcano_plot.png
    │   └── S2_effect_size_distribution.png
    │
    ├── tables/
    │   ├── statistical_results/   # Resultados completos
    │   │   ├── S2_statistical_comparisons.csv  ⭐ RESULTADOS COMPLETOS
    │   │   └── S2_effect_sizes.csv
    │   │
    │   ├── summary/               # Resúmenes interpretativos
    │   │   ├── S2_significant_mutations.csv      # ⭐ PROPUESTA: Solo significativos
    │   │   ├── S2_top_effect_sizes.csv            # ⭐ PROPUESTA: Top 50 por efecto
    │   │   └── S2_seed_region_significant.csv     # ⭐ PROPUESTA: Significativos en seed
    │   │
    │   └── README_TABLES.md
    │
    ├── viewer/
    │   └── step2.html
    │
    └── logs/
```

---

## 📋 Mejoras Específicas Propuestas

### 1. **Nomenclatura Consistente**

**Actual:** `TABLE_1.B_gt_counts_by_position.csv`, `step2_statistical_comparisons.csv`  
**Propuesta:** `S1_B_gt_counts_by_position.csv`, `S2_statistical_comparisons.csv`

**Ventajas:**
- Prefijo consistente (`S1_`, `S1.5_`, `S2_`)
- Fácil ordenamiento alfabético
- Claridad sobre qué paso generó la tabla

### 2. **Separación por Categoría**

**Estructura actual:** Todas las tablas en `tables/`  
**Propuesta:** Subdirectorios por propósito:

- `filtered_data/` - Datos procesados para uso downstream ⭐
- `filter_report/` - Reportes de filtros aplicados
- `summary/` - Métricas resumen
- `statistical_results/` - Resultados de tests estadísticos

**Ventajas:**
- Claridad sobre el propósito de cada tabla
- Fácil encontrar inputs para pasos siguientes
- Separación entre datos intermedios y resultados finales

### 3. **Tablas Faltantes en Step 2**

**Actual:** Solo `statistical_comparisons.csv` y `effect_sizes.csv`  
**Propuestas:**

1. **`S2_significant_mutations.csv`**
   - Solo mutaciones con `p_adjusted < 0.05`
   - Ordenadas por `fold_change` o `effect_size`
   - Columnas: `SNV_id`, `miRNA_name`, `position`, `mutation_type`, `ALS_mean`, `Control_mean`, `fold_change`, `p_adjusted`, `effect_size`

2. **`S2_top_effect_sizes.csv`**
   - Top 50 mutaciones por `cohens_d` absoluto
   - Útil para interpretación rápida

3. **`S2_seed_region_significant.csv`**
   - Solo mutaciones significativas en región seed (pos 2-7)
   - **Pregunta clave:** ¿Hay enrichment en seed?

### 4. **Documentación de Tablas (README_TABLES.md)**

Cada paso tendría un `README_TABLES.md` con:

```markdown
# Tablas Generadas en Step 1: Análisis Exploratorio

## 📊 Resumen

Este paso genera 6 tablas organizadas en:

- `summary/`: Tablas resumen por análisis (6 tablas)

## 📋 Tablas por Propósito

### Análisis de G>T por Posición

| Archivo | Descripción | Columnas Clave | Uso |
|---------|-------------|---------------|-----|
| `S1_B_gt_counts_by_position.csv` | Conteos G>T por posición | `position`, `total_GT_count`, `n_SNVs` | Identificar hotspots |

...

## 🔗 Flujo de Datos

```
Input: final_processed_data_CLEAN.csv
  ↓
Step 1 Processing
  ↓
Outputs: 6 summary tables
  ↓
Step 1.5 (VAF filtering)
```

## 📌 Notas

- ⭐ = Tabla usada como input en pasos siguientes
- 🔒 = Tabla final (no se modifica)
- 📊 = Tabla resumen (puede regenerarse)
```

---

## 🔄 Flujo de Datos Entre Pasos

```
INPUT
├── final_processed_data_CLEAN.csv (para Step 1)
└── step1_original_data.csv (para Step 1.5)

STEP 1: Exploratory Analysis
├── Input: final_processed_data_CLEAN.csv
├── Outputs: 6 tables summary/
└── ⚠️ No genera datos intermedios para downstream

STEP 1.5: VAF Quality Control
├── Input: step1_original_data.csv
├── Outputs:
│   ├── filtered_data/ALL_MUTATIONS_VAF_FILTERED.csv ⭐ INPUT PARA STEP 2
│   ├── filter_report/ (3 tablas)
│   └── summary/ (3 tablas)
└── ⭐ Este es el INPUT principal para Step 2

STEP 2: Statistical Comparisons
├── Input: step1_5_vaf_qc/tables/filtered_data/ALL_MUTATIONS_VAF_FILTERED.csv
├── Outputs:
│   ├── statistical_results/ (2 tablas completas)
│   └── summary/ (3 tablas interpretativas propuestas)
└── ⭐ Resultados finales para publicación
```

---

## ✅ Plan de Implementación

### Fase 1: Reorganización de Estructura (Sin Cambiar Funcionalidad)

1. ✅ Crear nuevos subdirectorios en `outputs/`
2. ✅ Mover tablas existentes a nuevas ubicaciones
3. ✅ Actualizar reglas Snakemake con nuevos paths
4. ✅ Verificar que todo funciona igual

### Fase 2: Generar Tablas Faltantes

1. ✅ Crear script para `S2_significant_mutations.csv`
2. ✅ Crear script para `S2_top_effect_sizes.csv`
3. ✅ Crear script para `S2_seed_region_significant.csv`
4. ✅ Agregar reglas Snakemake para nuevas tablas

### Fase 3: Documentación

1. ✅ Crear `README_TABLES.md` para cada paso
2. ✅ Actualizar `README.md` principal con nueva estructura
3. ✅ Crear diagrama de flujo de datos

### Fase 4: Actualización de Viewers HTML

1. ✅ Actualizar paths en viewers HTML
2. ✅ Agregar secciones para nuevas tablas
3. ✅ Mejorar organización visual en viewers

---

## 📊 Matriz de Preguntas vs Tablas

| Pregunta Biológica | Tabla(s) que Responde | Paso | Interpretación |
|-------------------|----------------------|------|---------------|
| ¿Hay más G>T en seed que en non-seed? | `S1_F_seed_vs_nonseed.csv` | Step 1 | `fraction_snvs` en seed vs non-seed |
| ¿Qué posiciones tienen más mutaciones G>T? | `S1_B_gt_counts_by_position.csv` | Step 1 | `total_GT_count`, `n_SNVs` por posición |
| ¿Hay diferencias significativas ALS vs Control? | `S2_statistical_comparisons.csv` | Step 2 | `p_adjusted < 0.05`, `significant == TRUE` |
| ¿Cuáles son las mutaciones más importantes? | `S2_significant_mutations.csv` ⭐ | Step 2 | Ordenadas por `fold_change` o `effect_size` |
| ¿Qué proporción de datos se perdió con VAF filter? | `S1.5_filter_report.csv` | Step 1.5 | `pct_removed` |
| ¿Hay enrichment de G>T significativo en seed en ALS? | `S2_seed_region_significant.csv` ⭐ | Step 2 | Mutaciones significativas filtradas por pos 2-7 |

---

## 🎯 Próximos Pasos

1. **Revisar esta propuesta** - ¿Tiene sentido? ¿Falta algo?
2. **Decidir si implementar** - ¿Proceder con reorganización?
3. **Crear scripts para tablas faltantes** - Si se aprueba
4. **Actualizar reglas Snakemake** - Con nueva estructura
5. **Probar y validar** - Que todo sigue funcionando

---

**¿Quieres que proceda con la implementación de esta organización mejorada?**


**Fecha:** 2025-11-02  
**Objetivo:** Mejorar la organización de outputs para facilitar interpretación y uso downstream

---

## 📊 Análisis Actual: Qué Hacemos y Qué Preguntas Respondemos

### 🔬 STEP 1: Análisis Exploratorio

#### Preguntas Biológicas que Responde:

| Panel | Pregunta Principal | Métrica Clave | Interpretación |
|-------|-------------------|---------------|----------------|
| **B** | ¿Cuántos SNVs G>T hay por posición? | `total_GT_count`, `n_SNVs` | Identifica hotspots de mutación G>T |
| **C** | ¿Qué tipos de mutaciones G>X ocurren? | `mutation_type`, `percentage` | Espectro mutacional completo (G>A, G>T, G>C) |
| **D** | ¿Qué fracción de mutaciones ocurren en cada posición? | `fraction` | Posiciones con proporciones desproporcionadas |
| **E** | ¿Hay relación entre contenido G y mutaciones? | `total_G_copies`, `GT_counts_at_position` | Validación mecanicista |
| **F** | ¿Más mutaciones G>T en seed vs non-seed? | `fraction_snvs`, `fraction_counts` | **Pregunta clave:** Seed region enrichment |
| **G** | ¿Qué proporción de G>X es específicamente G>T? | `gt_fraction` | Especificidad de oxidación G>T |

#### Tablas Generadas (6 tablas):

| Tabla | Propósito | Uso Downstream | Columnas Clave |
|-------|-----------|----------------|---------------|
| `S1_B_gt_counts_by_position.csv` | Conteos G>T por posición | **Input para análisis estadísticos** | `position`, `total_GT_count`, `n_SNVs`, `n_miRNAs` |
| `S1_C_gx_spectrum_by_position.csv` | Espectro G>X | Análisis de patrones mutacionales | `position`, `mutation_type`, `n`, `percentage` |
| `S1_D_positional_fractions.csv` | Fracciones posicionales | Identificar posiciones importantes | `position`, `snv_count`, `fraction`, `region` |
| `S1_E_gcontent_landscape.csv` | Contenido G por posición | Validación mecanicista | `Position`, `total_G_copies`, `GT_counts_at_position` |
| `S1_F_seed_vs_nonseed.csv` | Comparación seed/non-seed | **Pregunta biológica clave** | `region`, `total_snvs`, `fraction_snvs`, `fraction_counts` |
| `S1_G_gt_specificity.csv` | Especificidad G>T | Análisis de oxidación | `position`, `gt_count`, `gt_fraction` |

---

### 🔍 STEP 1.5: Control de Calidad VAF

#### Preguntas que Responde:

1. **¿Cuántos artefactos técnicos hay?**
   - Tabla: `S1.5_filter_report.csv`
   - Métricas: `n_before`, `n_after`, `n_removed`, `pct_removed`

2. **¿Qué tipos de mutaciones se filtran más?**
   - Tabla: `S1.5_stats_by_type.csv`
   - Métricas: `N_Filtered`, `Mean_VAF`, `Min_VAF`, `Max_VAF`

3. **¿Qué miRNAs se ven más afectados?**
   - Tabla: `S1.5_stats_by_mirna.csv`
   - Métricas: `N_Filtered`, `Mean_VAF`, `Samples_Affected`

4. **¿Cuáles son las métricas después del filtro?**
   - Tablas: `S1.5_sample_metrics.csv`, `S1.5_position_metrics.csv`, `S1.5_mutation_type_summary.csv`

#### Tabla Clave ⭐ (INPUT para Step 2):

**`ALL_MUTATIONS_VAF_FILTERED.csv`**
- **Propósito:** Datos filtrados listos para análisis downstream
- **Columnas:** `miRNA name`, `pos:mut`, `VAF`, `Sample_SNV`, `Sample (PM+1MM+2MM)`, ...
- **Uso:** Este es el input principal para Step 2 (comparaciones ALS vs Control)

---

### 📊 STEP 2: Comparaciones Estadísticas (ALS vs Control)

#### Preguntas que Responde:

1. **¿Hay diferencias significativas entre ALS y Control?**
   - Tabla: `S2_statistical_comparisons.csv`
   - Métricas: `ALS_mean`, `Control_mean`, `fold_change`, `p_value`, `p_adjusted`, `significant`

2. **¿Cuál es el tamaño del efecto?**
   - Tabla: `S2_effect_sizes.csv`
   - Métricas: `cohens_d`, `effect_size_category`, `log2_fold_change`

3. **¿Qué mutaciones son más importantes?**
   - ⚠️ **FALTA:** Tabla de mutaciones significativas resumidas
   - **Propuesta:** `S2_significant_mutations_summary.csv`

#### Tablas Generadas (2 actuales + 1 propuesta):

| Tabla | Propósito | Columnas Clave |
|-------|-----------|---------------|
| `S2_statistical_comparisons.csv` | Resultados completos de tests | `SNV_id`, `ALS_mean`, `Control_mean`, `fold_change`, `p_value`, `p_adjusted`, `significant` |
| `S2_effect_sizes.csv` | Tamaños de efecto | `miRNA_name`, `pos.mut`, `cohens_d`, `effect_size_category` |
| `S2_significant_mutations_summary.csv` | ⭐ **PROPUESTA:** Resumen de significativos | `SNV_id`, `miRNA_name`, `position`, `mutation_type`, `fold_change`, `p_adjusted`, `effect_size` |

---

## 🗂️ Estructura Propuesta Mejorada

```
outputs/
│
├── step1_exploratory/
│   ├── figures/
│   │   ├── panel_B_gt_counts_by_position.png
│   │   ├── panel_C_gx_spectrum.png
│   │   ├── panel_D_positional_fraction.png
│   │   ├── panel_E_gcontent_landscape.png
│   │   ├── panel_F_seed_vs_nonseed.png
│   │   └── panel_G_gt_specificity.png
│   │
│   ├── tables/
│   │   ├── summary/              # Tablas resumen por análisis
│   │   │   ├── S1_B_gt_counts_by_position.csv
│   │   │   ├── S1_C_gx_spectrum_by_position.csv
│   │   │   ├── S1_D_positional_fractions.csv
│   │   │   ├── S1_E_gcontent_landscape.csv
│   │   │   ├── S1_F_seed_vs_nonseed.csv
│   │   │   └── S1_G_gt_specificity.csv
│   │   │
│   │   └── README_TABLES.md      # Documentación de tablas
│   │
│   ├── viewer/
│   │   └── step1.html
│   │
│   └── logs/
│
├── step1_5_vaf_qc/
│   ├── figures/
│   │   ├── qc/                    # Quality control figures
│   │   │   ├── QC_FIG1_VAF_DISTRIBUTION.png
│   │   │   ├── QC_FIG2_FILTER_IMPACT.png
│   │   │   ├── QC_FIG3_AFFECTED_MIRNAS.png
│   │   │   └── QC_FIG4_BEFORE_AFTER.png
│   │   │
│   │   └── diagnostic/            # Diagnostic figures
│   │       ├── STEP1.5_FIG1_HEATMAP_SNVS.png
│   │       ├── STEP1.5_FIG2_HEATMAP_COUNTS.png
│   │       ├── STEP1.5_FIG3_G_TRANSVERSIONS_SNVS.png
│   │       ├── STEP1.5_FIG4_G_TRANSVERSIONS_COUNTS.png
│   │       ├── STEP1.5_FIG5_BUBBLE_PLOT.png
│   │       ├── STEP1.5_FIG6_VIOLIN_DISTRIBUTIONS.png
│   │       └── STEP1.5_FIG7_FOLD_CHANGE.png
│   │
│   ├── tables/
│   │   ├── filtered_data/         # ⭐ INPUT para Step 2
│   │   │   └── ALL_MUTATIONS_VAF_FILTERED.csv
│   │   │
│   │   ├── filter_report/         # Reportes del filtro
│   │   │   ├── S1.5_filter_report.csv
│   │   │   ├── S1.5_stats_by_type.csv
│   │   │   └── S1.5_stats_by_mirna.csv
│   │   │
│   │   ├── summary/               # Métricas resumen
│   │   │   ├── S1.5_sample_metrics.csv
│   │   │   ├── S1.5_position_metrics.csv
│   │   │   └── S1.5_mutation_type_summary.csv
│   │   │
│   │   └── README_TABLES.md
│   │
│   ├── viewer/
│   │   └── step1_5.html
│   │
│   └── logs/
│
└── step2_comparisons/
    ├── figures/
    │   ├── S2_volcano_plot.png
    │   └── S2_effect_size_distribution.png
    │
    ├── tables/
    │   ├── statistical_results/   # Resultados completos
    │   │   ├── S2_statistical_comparisons.csv  ⭐ RESULTADOS COMPLETOS
    │   │   └── S2_effect_sizes.csv
    │   │
    │   ├── summary/               # Resúmenes interpretativos
    │   │   ├── S2_significant_mutations.csv      # ⭐ PROPUESTA: Solo significativos
    │   │   ├── S2_top_effect_sizes.csv            # ⭐ PROPUESTA: Top 50 por efecto
    │   │   └── S2_seed_region_significant.csv     # ⭐ PROPUESTA: Significativos en seed
    │   │
    │   └── README_TABLES.md
    │
    ├── viewer/
    │   └── step2.html
    │
    └── logs/
```

---

## 📋 Mejoras Específicas Propuestas

### 1. **Nomenclatura Consistente**

**Actual:** `TABLE_1.B_gt_counts_by_position.csv`, `step2_statistical_comparisons.csv`  
**Propuesta:** `S1_B_gt_counts_by_position.csv`, `S2_statistical_comparisons.csv`

**Ventajas:**
- Prefijo consistente (`S1_`, `S1.5_`, `S2_`)
- Fácil ordenamiento alfabético
- Claridad sobre qué paso generó la tabla

### 2. **Separación por Categoría**

**Estructura actual:** Todas las tablas en `tables/`  
**Propuesta:** Subdirectorios por propósito:

- `filtered_data/` - Datos procesados para uso downstream ⭐
- `filter_report/` - Reportes de filtros aplicados
- `summary/` - Métricas resumen
- `statistical_results/` - Resultados de tests estadísticos

**Ventajas:**
- Claridad sobre el propósito de cada tabla
- Fácil encontrar inputs para pasos siguientes
- Separación entre datos intermedios y resultados finales

### 3. **Tablas Faltantes en Step 2**

**Actual:** Solo `statistical_comparisons.csv` y `effect_sizes.csv`  
**Propuestas:**

1. **`S2_significant_mutations.csv`**
   - Solo mutaciones con `p_adjusted < 0.05`
   - Ordenadas por `fold_change` o `effect_size`
   - Columnas: `SNV_id`, `miRNA_name`, `position`, `mutation_type`, `ALS_mean`, `Control_mean`, `fold_change`, `p_adjusted`, `effect_size`

2. **`S2_top_effect_sizes.csv`**
   - Top 50 mutaciones por `cohens_d` absoluto
   - Útil para interpretación rápida

3. **`S2_seed_region_significant.csv`**
   - Solo mutaciones significativas en región seed (pos 2-7)
   - **Pregunta clave:** ¿Hay enrichment en seed?

### 4. **Documentación de Tablas (README_TABLES.md)**

Cada paso tendría un `README_TABLES.md` con:

```markdown
# Tablas Generadas en Step 1: Análisis Exploratorio

## 📊 Resumen

Este paso genera 6 tablas organizadas en:

- `summary/`: Tablas resumen por análisis (6 tablas)

## 📋 Tablas por Propósito

### Análisis de G>T por Posición

| Archivo | Descripción | Columnas Clave | Uso |
|---------|-------------|---------------|-----|
| `S1_B_gt_counts_by_position.csv` | Conteos G>T por posición | `position`, `total_GT_count`, `n_SNVs` | Identificar hotspots |

...

## 🔗 Flujo de Datos

```
Input: final_processed_data_CLEAN.csv
  ↓
Step 1 Processing
  ↓
Outputs: 6 summary tables
  ↓
Step 1.5 (VAF filtering)
```

## 📌 Notas

- ⭐ = Tabla usada como input en pasos siguientes
- 🔒 = Tabla final (no se modifica)
- 📊 = Tabla resumen (puede regenerarse)
```

---

## 🔄 Flujo de Datos Entre Pasos

```
INPUT
├── final_processed_data_CLEAN.csv (para Step 1)
└── step1_original_data.csv (para Step 1.5)

STEP 1: Exploratory Analysis
├── Input: final_processed_data_CLEAN.csv
├── Outputs: 6 tables summary/
└── ⚠️ No genera datos intermedios para downstream

STEP 1.5: VAF Quality Control
├── Input: step1_original_data.csv
├── Outputs:
│   ├── filtered_data/ALL_MUTATIONS_VAF_FILTERED.csv ⭐ INPUT PARA STEP 2
│   ├── filter_report/ (3 tablas)
│   └── summary/ (3 tablas)
└── ⭐ Este es el INPUT principal para Step 2

STEP 2: Statistical Comparisons
├── Input: step1_5_vaf_qc/tables/filtered_data/ALL_MUTATIONS_VAF_FILTERED.csv
├── Outputs:
│   ├── statistical_results/ (2 tablas completas)
│   └── summary/ (3 tablas interpretativas propuestas)
└── ⭐ Resultados finales para publicación
```

---

## ✅ Plan de Implementación

### Fase 1: Reorganización de Estructura (Sin Cambiar Funcionalidad)

1. ✅ Crear nuevos subdirectorios en `outputs/`
2. ✅ Mover tablas existentes a nuevas ubicaciones
3. ✅ Actualizar reglas Snakemake con nuevos paths
4. ✅ Verificar que todo funciona igual

### Fase 2: Generar Tablas Faltantes

1. ✅ Crear script para `S2_significant_mutations.csv`
2. ✅ Crear script para `S2_top_effect_sizes.csv`
3. ✅ Crear script para `S2_seed_region_significant.csv`
4. ✅ Agregar reglas Snakemake para nuevas tablas

### Fase 3: Documentación

1. ✅ Crear `README_TABLES.md` para cada paso
2. ✅ Actualizar `README.md` principal con nueva estructura
3. ✅ Crear diagrama de flujo de datos

### Fase 4: Actualización de Viewers HTML

1. ✅ Actualizar paths en viewers HTML
2. ✅ Agregar secciones para nuevas tablas
3. ✅ Mejorar organización visual en viewers

---

## 📊 Matriz de Preguntas vs Tablas

| Pregunta Biológica | Tabla(s) que Responde | Paso | Interpretación |
|-------------------|----------------------|------|---------------|
| ¿Hay más G>T en seed que en non-seed? | `S1_F_seed_vs_nonseed.csv` | Step 1 | `fraction_snvs` en seed vs non-seed |
| ¿Qué posiciones tienen más mutaciones G>T? | `S1_B_gt_counts_by_position.csv` | Step 1 | `total_GT_count`, `n_SNVs` por posición |
| ¿Hay diferencias significativas ALS vs Control? | `S2_statistical_comparisons.csv` | Step 2 | `p_adjusted < 0.05`, `significant == TRUE` |
| ¿Cuáles son las mutaciones más importantes? | `S2_significant_mutations.csv` ⭐ | Step 2 | Ordenadas por `fold_change` o `effect_size` |
| ¿Qué proporción de datos se perdió con VAF filter? | `S1.5_filter_report.csv` | Step 1.5 | `pct_removed` |
| ¿Hay enrichment de G>T significativo en seed en ALS? | `S2_seed_region_significant.csv` ⭐ | Step 2 | Mutaciones significativas filtradas por pos 2-7 |

---

## 🎯 Próximos Pasos

1. **Revisar esta propuesta** - ¿Tiene sentido? ¿Falta algo?
2. **Decidir si implementar** - ¿Proceder con reorganización?
3. **Crear scripts para tablas faltantes** - Si se aprueba
4. **Actualizar reglas Snakemake** - Con nueva estructura
5. **Probar y validar** - Que todo sigue funcionando

---

**¿Quieres que proceda con la implementación de esta organización mejorada?**


**Fecha:** 2025-11-02  
**Objetivo:** Mejorar la organización de outputs para facilitar interpretación y uso downstream

---

## 📊 Análisis Actual: Qué Hacemos y Qué Preguntas Respondemos

### 🔬 STEP 1: Análisis Exploratorio

#### Preguntas Biológicas que Responde:

| Panel | Pregunta Principal | Métrica Clave | Interpretación |
|-------|-------------------|---------------|----------------|
| **B** | ¿Cuántos SNVs G>T hay por posición? | `total_GT_count`, `n_SNVs` | Identifica hotspots de mutación G>T |
| **C** | ¿Qué tipos de mutaciones G>X ocurren? | `mutation_type`, `percentage` | Espectro mutacional completo (G>A, G>T, G>C) |
| **D** | ¿Qué fracción de mutaciones ocurren en cada posición? | `fraction` | Posiciones con proporciones desproporcionadas |
| **E** | ¿Hay relación entre contenido G y mutaciones? | `total_G_copies`, `GT_counts_at_position` | Validación mecanicista |
| **F** | ¿Más mutaciones G>T en seed vs non-seed? | `fraction_snvs`, `fraction_counts` | **Pregunta clave:** Seed region enrichment |
| **G** | ¿Qué proporción de G>X es específicamente G>T? | `gt_fraction` | Especificidad de oxidación G>T |

#### Tablas Generadas (6 tablas):

| Tabla | Propósito | Uso Downstream | Columnas Clave |
|-------|-----------|----------------|---------------|
| `S1_B_gt_counts_by_position.csv` | Conteos G>T por posición | **Input para análisis estadísticos** | `position`, `total_GT_count`, `n_SNVs`, `n_miRNAs` |
| `S1_C_gx_spectrum_by_position.csv` | Espectro G>X | Análisis de patrones mutacionales | `position`, `mutation_type`, `n`, `percentage` |
| `S1_D_positional_fractions.csv` | Fracciones posicionales | Identificar posiciones importantes | `position`, `snv_count`, `fraction`, `region` |
| `S1_E_gcontent_landscape.csv` | Contenido G por posición | Validación mecanicista | `Position`, `total_G_copies`, `GT_counts_at_position` |
| `S1_F_seed_vs_nonseed.csv` | Comparación seed/non-seed | **Pregunta biológica clave** | `region`, `total_snvs`, `fraction_snvs`, `fraction_counts` |
| `S1_G_gt_specificity.csv` | Especificidad G>T | Análisis de oxidación | `position`, `gt_count`, `gt_fraction` |

---

### 🔍 STEP 1.5: Control de Calidad VAF

#### Preguntas que Responde:

1. **¿Cuántos artefactos técnicos hay?**
   - Tabla: `S1.5_filter_report.csv`
   - Métricas: `n_before`, `n_after`, `n_removed`, `pct_removed`

2. **¿Qué tipos de mutaciones se filtran más?**
   - Tabla: `S1.5_stats_by_type.csv`
   - Métricas: `N_Filtered`, `Mean_VAF`, `Min_VAF`, `Max_VAF`

3. **¿Qué miRNAs se ven más afectados?**
   - Tabla: `S1.5_stats_by_mirna.csv`
   - Métricas: `N_Filtered`, `Mean_VAF`, `Samples_Affected`

4. **¿Cuáles son las métricas después del filtro?**
   - Tablas: `S1.5_sample_metrics.csv`, `S1.5_position_metrics.csv`, `S1.5_mutation_type_summary.csv`

#### Tabla Clave ⭐ (INPUT para Step 2):

**`ALL_MUTATIONS_VAF_FILTERED.csv`**
- **Propósito:** Datos filtrados listos para análisis downstream
- **Columnas:** `miRNA name`, `pos:mut`, `VAF`, `Sample_SNV`, `Sample (PM+1MM+2MM)`, ...
- **Uso:** Este es el input principal para Step 2 (comparaciones ALS vs Control)

---

### 📊 STEP 2: Comparaciones Estadísticas (ALS vs Control)

#### Preguntas que Responde:

1. **¿Hay diferencias significativas entre ALS y Control?**
   - Tabla: `S2_statistical_comparisons.csv`
   - Métricas: `ALS_mean`, `Control_mean`, `fold_change`, `p_value`, `p_adjusted`, `significant`

2. **¿Cuál es el tamaño del efecto?**
   - Tabla: `S2_effect_sizes.csv`
   - Métricas: `cohens_d`, `effect_size_category`, `log2_fold_change`

3. **¿Qué mutaciones son más importantes?**
   - ⚠️ **FALTA:** Tabla de mutaciones significativas resumidas
   - **Propuesta:** `S2_significant_mutations_summary.csv`

#### Tablas Generadas (2 actuales + 1 propuesta):

| Tabla | Propósito | Columnas Clave |
|-------|-----------|---------------|
| `S2_statistical_comparisons.csv` | Resultados completos de tests | `SNV_id`, `ALS_mean`, `Control_mean`, `fold_change`, `p_value`, `p_adjusted`, `significant` |
| `S2_effect_sizes.csv` | Tamaños de efecto | `miRNA_name`, `pos.mut`, `cohens_d`, `effect_size_category` |
| `S2_significant_mutations_summary.csv` | ⭐ **PROPUESTA:** Resumen de significativos | `SNV_id`, `miRNA_name`, `position`, `mutation_type`, `fold_change`, `p_adjusted`, `effect_size` |

---

## 🗂️ Estructura Propuesta Mejorada

```
outputs/
│
├── step1_exploratory/
│   ├── figures/
│   │   ├── panel_B_gt_counts_by_position.png
│   │   ├── panel_C_gx_spectrum.png
│   │   ├── panel_D_positional_fraction.png
│   │   ├── panel_E_gcontent_landscape.png
│   │   ├── panel_F_seed_vs_nonseed.png
│   │   └── panel_G_gt_specificity.png
│   │
│   ├── tables/
│   │   ├── summary/              # Tablas resumen por análisis
│   │   │   ├── S1_B_gt_counts_by_position.csv
│   │   │   ├── S1_C_gx_spectrum_by_position.csv
│   │   │   ├── S1_D_positional_fractions.csv
│   │   │   ├── S1_E_gcontent_landscape.csv
│   │   │   ├── S1_F_seed_vs_nonseed.csv
│   │   │   └── S1_G_gt_specificity.csv
│   │   │
│   │   └── README_TABLES.md      # Documentación de tablas
│   │
│   ├── viewer/
│   │   └── step1.html
│   │
│   └── logs/
│
├── step1_5_vaf_qc/
│   ├── figures/
│   │   ├── qc/                    # Quality control figures
│   │   │   ├── QC_FIG1_VAF_DISTRIBUTION.png
│   │   │   ├── QC_FIG2_FILTER_IMPACT.png
│   │   │   ├── QC_FIG3_AFFECTED_MIRNAS.png
│   │   │   └── QC_FIG4_BEFORE_AFTER.png
│   │   │
│   │   └── diagnostic/            # Diagnostic figures
│   │       ├── STEP1.5_FIG1_HEATMAP_SNVS.png
│   │       ├── STEP1.5_FIG2_HEATMAP_COUNTS.png
│   │       ├── STEP1.5_FIG3_G_TRANSVERSIONS_SNVS.png
│   │       ├── STEP1.5_FIG4_G_TRANSVERSIONS_COUNTS.png
│   │       ├── STEP1.5_FIG5_BUBBLE_PLOT.png
│   │       ├── STEP1.5_FIG6_VIOLIN_DISTRIBUTIONS.png
│   │       └── STEP1.5_FIG7_FOLD_CHANGE.png
│   │
│   ├── tables/
│   │   ├── filtered_data/         # ⭐ INPUT para Step 2
│   │   │   └── ALL_MUTATIONS_VAF_FILTERED.csv
│   │   │
│   │   ├── filter_report/         # Reportes del filtro
│   │   │   ├── S1.5_filter_report.csv
│   │   │   ├── S1.5_stats_by_type.csv
│   │   │   └── S1.5_stats_by_mirna.csv
│   │   │
│   │   ├── summary/               # Métricas resumen
│   │   │   ├── S1.5_sample_metrics.csv
│   │   │   ├── S1.5_position_metrics.csv
│   │   │   └── S1.5_mutation_type_summary.csv
│   │   │
│   │   └── README_TABLES.md
│   │
│   ├── viewer/
│   │   └── step1_5.html
│   │
│   └── logs/
│
└── step2_comparisons/
    ├── figures/
    │   ├── S2_volcano_plot.png
    │   └── S2_effect_size_distribution.png
    │
    ├── tables/
    │   ├── statistical_results/   # Resultados completos
    │   │   ├── S2_statistical_comparisons.csv  ⭐ RESULTADOS COMPLETOS
    │   │   └── S2_effect_sizes.csv
    │   │
    │   ├── summary/               # Resúmenes interpretativos
    │   │   ├── S2_significant_mutations.csv      # ⭐ PROPUESTA: Solo significativos
    │   │   ├── S2_top_effect_sizes.csv            # ⭐ PROPUESTA: Top 50 por efecto
    │   │   └── S2_seed_region_significant.csv     # ⭐ PROPUESTA: Significativos en seed
    │   │
    │   └── README_TABLES.md
    │
    ├── viewer/
    │   └── step2.html
    │
    └── logs/
```

---

## 📋 Mejoras Específicas Propuestas

### 1. **Nomenclatura Consistente**

**Actual:** `TABLE_1.B_gt_counts_by_position.csv`, `step2_statistical_comparisons.csv`  
**Propuesta:** `S1_B_gt_counts_by_position.csv`, `S2_statistical_comparisons.csv`

**Ventajas:**
- Prefijo consistente (`S1_`, `S1.5_`, `S2_`)
- Fácil ordenamiento alfabético
- Claridad sobre qué paso generó la tabla

### 2. **Separación por Categoría**

**Estructura actual:** Todas las tablas en `tables/`  
**Propuesta:** Subdirectorios por propósito:

- `filtered_data/` - Datos procesados para uso downstream ⭐
- `filter_report/` - Reportes de filtros aplicados
- `summary/` - Métricas resumen
- `statistical_results/` - Resultados de tests estadísticos

**Ventajas:**
- Claridad sobre el propósito de cada tabla
- Fácil encontrar inputs para pasos siguientes
- Separación entre datos intermedios y resultados finales

### 3. **Tablas Faltantes en Step 2**

**Actual:** Solo `statistical_comparisons.csv` y `effect_sizes.csv`  
**Propuestas:**

1. **`S2_significant_mutations.csv`**
   - Solo mutaciones con `p_adjusted < 0.05`
   - Ordenadas por `fold_change` o `effect_size`
   - Columnas: `SNV_id`, `miRNA_name`, `position`, `mutation_type`, `ALS_mean`, `Control_mean`, `fold_change`, `p_adjusted`, `effect_size`

2. **`S2_top_effect_sizes.csv`**
   - Top 50 mutaciones por `cohens_d` absoluto
   - Útil para interpretación rápida

3. **`S2_seed_region_significant.csv`**
   - Solo mutaciones significativas en región seed (pos 2-7)
   - **Pregunta clave:** ¿Hay enrichment en seed?

### 4. **Documentación de Tablas (README_TABLES.md)**

Cada paso tendría un `README_TABLES.md` con:

```markdown
# Tablas Generadas en Step 1: Análisis Exploratorio

## 📊 Resumen

Este paso genera 6 tablas organizadas en:

- `summary/`: Tablas resumen por análisis (6 tablas)

## 📋 Tablas por Propósito

### Análisis de G>T por Posición

| Archivo | Descripción | Columnas Clave | Uso |
|---------|-------------|---------------|-----|
| `S1_B_gt_counts_by_position.csv` | Conteos G>T por posición | `position`, `total_GT_count`, `n_SNVs` | Identificar hotspots |

...

## 🔗 Flujo de Datos

```
Input: final_processed_data_CLEAN.csv
  ↓
Step 1 Processing
  ↓
Outputs: 6 summary tables
  ↓
Step 1.5 (VAF filtering)
```

## 📌 Notas

- ⭐ = Tabla usada como input en pasos siguientes
- 🔒 = Tabla final (no se modifica)
- 📊 = Tabla resumen (puede regenerarse)
```

---

## 🔄 Flujo de Datos Entre Pasos

```
INPUT
├── final_processed_data_CLEAN.csv (para Step 1)
└── step1_original_data.csv (para Step 1.5)

STEP 1: Exploratory Analysis
├── Input: final_processed_data_CLEAN.csv
├── Outputs: 6 tables summary/
└── ⚠️ No genera datos intermedios para downstream

STEP 1.5: VAF Quality Control
├── Input: step1_original_data.csv
├── Outputs:
│   ├── filtered_data/ALL_MUTATIONS_VAF_FILTERED.csv ⭐ INPUT PARA STEP 2
│   ├── filter_report/ (3 tablas)
│   └── summary/ (3 tablas)
└── ⭐ Este es el INPUT principal para Step 2

STEP 2: Statistical Comparisons
├── Input: step1_5_vaf_qc/tables/filtered_data/ALL_MUTATIONS_VAF_FILTERED.csv
├── Outputs:
│   ├── statistical_results/ (2 tablas completas)
│   └── summary/ (3 tablas interpretativas propuestas)
└── ⭐ Resultados finales para publicación
```

---

## ✅ Plan de Implementación

### Fase 1: Reorganización de Estructura (Sin Cambiar Funcionalidad)

1. ✅ Crear nuevos subdirectorios en `outputs/`
2. ✅ Mover tablas existentes a nuevas ubicaciones
3. ✅ Actualizar reglas Snakemake con nuevos paths
4. ✅ Verificar que todo funciona igual

### Fase 2: Generar Tablas Faltantes

1. ✅ Crear script para `S2_significant_mutations.csv`
2. ✅ Crear script para `S2_top_effect_sizes.csv`
3. ✅ Crear script para `S2_seed_region_significant.csv`
4. ✅ Agregar reglas Snakemake para nuevas tablas

### Fase 3: Documentación

1. ✅ Crear `README_TABLES.md` para cada paso
2. ✅ Actualizar `README.md` principal con nueva estructura
3. ✅ Crear diagrama de flujo de datos

### Fase 4: Actualización de Viewers HTML

1. ✅ Actualizar paths en viewers HTML
2. ✅ Agregar secciones para nuevas tablas
3. ✅ Mejorar organización visual en viewers

---

## 📊 Matriz de Preguntas vs Tablas

| Pregunta Biológica | Tabla(s) que Responde | Paso | Interpretación |
|-------------------|----------------------|------|---------------|
| ¿Hay más G>T en seed que en non-seed? | `S1_F_seed_vs_nonseed.csv` | Step 1 | `fraction_snvs` en seed vs non-seed |
| ¿Qué posiciones tienen más mutaciones G>T? | `S1_B_gt_counts_by_position.csv` | Step 1 | `total_GT_count`, `n_SNVs` por posición |
| ¿Hay diferencias significativas ALS vs Control? | `S2_statistical_comparisons.csv` | Step 2 | `p_adjusted < 0.05`, `significant == TRUE` |
| ¿Cuáles son las mutaciones más importantes? | `S2_significant_mutations.csv` ⭐ | Step 2 | Ordenadas por `fold_change` o `effect_size` |
| ¿Qué proporción de datos se perdió con VAF filter? | `S1.5_filter_report.csv` | Step 1.5 | `pct_removed` |
| ¿Hay enrichment de G>T significativo en seed en ALS? | `S2_seed_region_significant.csv` ⭐ | Step 2 | Mutaciones significativas filtradas por pos 2-7 |

---

## 🎯 Próximos Pasos

1. **Revisar esta propuesta** - ¿Tiene sentido? ¿Falta algo?
2. **Decidir si implementar** - ¿Proceder con reorganización?
3. **Crear scripts para tablas faltantes** - Si se aprueba
4. **Actualizar reglas Snakemake** - Con nueva estructura
5. **Probar y validar** - Que todo sigue funcionando

---

**¿Quieres que proceda con la implementación de esta organización mejorada?**

