# 📊 Análisis del Pipeline: Pasos, Preguntas y Tablas

**Fecha:** 2025-11-02  
**Pipeline:** ALS miRNA Oxidation Analysis Pipeline

---

## 📋 Resumen Ejecutivo

Este documento analiza:
1. **Qué hacemos en cada paso** del pipeline
2. **Qué preguntas respondemos** con cada análisis
3. **Qué tablas generamos** y su contenido
4. **Propuesta de organización mejorada** de outputs

---

## 🔬 STEP 1: Análisis Exploratorio Inicial

### 🎯 Objetivo
Caracterizar el dataset inicial y entender los patrones de mutación G>T antes de filtros.

### ❓ Preguntas que Responde

1. **Panel B - G>T Count by Position**
   - ❓ ¿Cuántos SNVs G>T hay por posición?
   - ❓ ¿Hay posiciones con más mutaciones G>T?
   - ❓ ¿Cuál es la distribución de G>T a lo largo de las posiciones?

2. **Panel C - G>X Mutation Spectrum**
   - ❓ ¿Qué tipos de mutaciones G>X ocurren?
   - ❓ ¿Cuál es el espectro mutacional completo (G>A, G>T, G>C)?
   - ❓ ¿Hay diferencias en el espectro por posición?

3. **Panel D - Positional Fraction**
   - ❓ ¿Qué fracción de todas las mutaciones ocurren en cada posición?
   - ❓ ¿Hay posiciones con proporciones desproporcionadamente altas de mutaciones?

4. **Panel E - G-Content Landscape**
   - ❓ ¿Cuántos G hay por posición en los miRNAs?
   - ❓ ¿Hay relación entre cantidad de G y mutaciones G>T?

5. **Panel F - Seed vs Non-seed**
   - ❓ ¿Hay más mutaciones G>T en la región seed (pos 2-7) vs resto?
   - ❓ ¿Qué proporción de SNVs y counts ocurren en seed vs non-seed?

6. **Panel G - G>T Specificity**
   - ❓ ¿Qué proporción de las mutaciones G son G>T vs otras transversiones G?
   - ❓ ¿Hay posiciones donde G>T es más específico?

### 📊 Tablas Generadas (Step 1)

| Tabla | Descripción | Columnas Principales |
|-------|-------------|---------------------|
| `TABLE_1.B_gt_counts_by_position.csv` | Conteos de SNVs G>T por posición | `position`, `total_gt_snvs`, `total_counts`, `mean_counts_per_snv` |
| `TABLE_1.C_gx_spectrum_by_position.csv` | Espectro G>X por posición | `position`, `mutation_type`, `snv_count`, `proportion` |
| `TABLE_1.D_positional_fractions.csv` | Fracciones de mutaciones por posición | `position`, `total_snvs`, `fraction_of_all_snvs`, `total_counts`, `fraction_of_all_counts` |
| `TABLE_1.E_gcontent_landscape.csv` | Contenido de G por posición | `position`, `n_mirnas_with_g`, `total_g_content`, `mean_g_per_mirna` |
| `TABLE_1.F_seed_vs_nonseed.csv` | Comparación seed vs non-seed | `region`, `total_snvs`, `total_counts`, `fraction_snvs`, `fraction_counts` |
| `TABLE_1.G_gt_specificity.csv` | Especificidad G>T vs otras G>X | `position`, `gt_count`, `g_transversion_count`, `gt_fraction` |

### 📈 Figuras Generadas (Step 1)

1. **Panel B**: Gráfico de barras de conteos G>T por posición
2. **Panel C**: Stacked bar chart de espectro G>X por posición
3. **Panel D**: Gráfico de fracciones posicionales
4. **Panel E**: Heatmap/landscape de contenido G
5. **Panel F**: Gráfico comparativo seed vs non-seed
6. **Panel G**: Gráfico de especificidad G>T

---

## 🔍 STEP 1.5: Control de Calidad VAF

### 🎯 Objetivo
Filtrar artefactos técnicos calculando VAF y removiendo mutaciones con VAF ≥ 0.5 (probablemente errores técnicos).

### ❓ Preguntas que Responde

1. **Filtrado VAF**
   - ❓ ¿Cuántas mutaciones tienen VAF ≥ 0.5 (artefactos técnicos)?
   - ❓ ¿Qué proporción de datos se pierde con el filtro?
   - ❓ ¿Qué tipos de mutaciones se filtran más?

2. **Caracterización Post-Filtro**
   - ❓ ¿Cómo cambian los patrones después del filtro VAF?
   - ❓ ¿Qué miRNAs se ven más afectados por el filtro?
   - ❓ ¿Cuáles son las métricas por muestra después del filtro?

3. **Diagnóstico Visual**
   - ❓ ¿Cómo es la distribución de VAF?
   - ❓ ¿Cuál es el impacto del filtro en diferentes métricas?
   - ❓ ¿Cómo se ven los patrones antes vs después del filtro?

### 📊 Tablas Generadas (Step 1.5)

| Tabla | Descripción | Columnas Principales |
|-------|-------------|---------------------|
| `ALL_MUTATIONS_VAF_FILTERED.csv` | **Datos filtrados principales** (usa esto para Step 2) | `miRNA name`, `pos:mut`, `VAF`, `Sample_SNV`, `Sample (PM+1MM+2MM)`, ... |
| `vaf_filter_report.csv` | **Reporte del filtro** | `metric`, `before_filter`, `after_filter`, `removed`, `pct_removed` |
| `vaf_statistics_by_type.csv` | Estadísticas por tipo de mutación | `mutation_type`, `n_before`, `n_after`, `n_removed`, `pct_removed` |
| `vaf_statistics_by_mirna.csv` | Estadísticas por miRNA | `miRNA_name`, `n_mutations_before`, `n_mutations_after`, `n_removed` |
| `sample_metrics_vaf_filtered.csv` | Métricas por muestra después del filtro | `sample`, `total_snvs`, `total_counts`, `mean_vaf`, `n_mutations` |
| `position_metrics_vaf_filtered.csv` | Métricas por posición después del filtro | `position`, `total_snvs`, `total_counts`, `mean_vaf` |
| `mutation_type_summary_vaf_filtered.csv` | Resumen por tipo de mutación | `mutation_type`, `total_snvs`, `total_counts`, `n_positions` |

### 📈 Figuras Generadas (Step 1.5)

**QC Figures (4):**
- QC_FIG1: Distribución de VAF
- QC_FIG2: Impacto del filtro
- QC_FIG3: miRNAs afectados
- QC_FIG4: Antes vs Después

**Diagnostic Figures (7):**
- STEP1.5_FIG1: Heatmap de SNVs
- STEP1.5_FIG2: Heatmap de counts
- STEP1.5_FIG3: G transversiones (SNVs)
- STEP1.5_FIG4: G transversiones (counts)
- STEP1.5_FIG5: Bubble plot
- STEP1.5_FIG6: Distribuciones violin
- STEP1.5_FIG7: Fold change

---

## 📊 STEP 2: Comparaciones Estadísticas (ALS vs Control)

### 🎯 Objetivo
Comparar grupos ALS vs Control para identificar diferencias significativas.

### ❓ Preguntas que Responde

1. **Comparaciones Estadísticas**
   - ❓ ¿Hay diferencias significativas entre ALS y Control?
   - ❓ ¿Qué posiciones/mutaciones son significativamente diferentes?
   - ❓ ¿Cuál es el tamaño del efecto de las diferencias?

2. **Visualización de Significancia**
   - ❓ ¿Cómo visualizamos las diferencias significativas? (Volcano plot)
   - ❓ ¿Cuáles son las mutaciones más importantes? (effect size)

3. **Interpretación Biológica**
   - ❓ ¿Qué mutaciones tienen mayor efecto en ALS?
   - ❓ ¿Hay patrones específicos en posiciones clave (seed, etc.)?

### 📊 Tablas Generadas (Step 2)

| Tabla | Descripción | Columnas Principales |
|-------|-------------|---------------------|
| `step2_statistical_comparisons.csv` | **Resultados de tests estadísticos** | `mutation`, `position`, `als_mean`, `control_mean`, `fold_change`, `p_value`, `p_adjusted`, `significant` |
| `step2_effect_sizes.csv` | Tamaños de efecto | `mutation`, `position`, `effect_size`, `effect_size_category`, `interpretation` |

### 📈 Figuras Generadas (Step 2)

1. **Volcano Plot**: Significancia vs fold change
2. **Effect Size Distribution**: Distribución de tamaños de efecto

---

## 🗂️ Organización Actual de Outputs

```
outputs/
├── step1/
│   ├── figures/          # 6 PNG
│   ├── tables/           # 6 CSV
│   └── logs/             # 6 log files
├── step1_5/
│   ├── figures/          # 11 PNG
│   ├── tables/           # 7 CSV
│   ├── data/             # Datos filtrados (1 CSV)
│   └── logs/             # 2 log files
└── step2/
    ├── figures/          # 2 PNG
    ├── tables/           # 2 CSV
    └── logs/             # 3 log files
```

**Problemas identificados:**
1. ❌ Tablas no están claramente categorizadas (intermedias vs finales)
2. ❌ No hay separación entre tablas "raw" y tablas "resumen"
3. ❌ No está claro cuál tabla usar para análisis downstream
4. ❌ Nombres de tablas inconsistentes (TABLE_1.X vs step2_)
5. ❌ Datos filtrados de Step 1.5 mezclados con tablas resumen

---

## 💡 Propuesta de Organización Mejorada

### Estructura Propuesta

```
outputs/
├── step1_exploratory/
│   ├── figures/
│   │   ├── panel_B_gt_counts_by_position.png
│   │   ├── panel_C_gx_spectrum.png
│   │   ├── panel_D_positional_fraction.png
│   │   ├── panel_E_gcontent_landscape.png
│   │   ├── panel_F_seed_vs_nonseed.png
│   │   └── panel_G_gt_specificity.png
│   ├── tables/
│   │   ├── raw_data/           # Datos procesados intermedios
│   │   │   └── (ninguna - Step 1 no genera datos intermedios)
│   │   ├── summary/            # Tablas resumen por análisis
│   │   │   ├── S1_B_gt_counts_by_position.csv
│   │   │   ├── S1_C_gx_spectrum_by_position.csv
│   │   │   ├── S1_D_positional_fractions.csv
│   │   │   ├── S1_E_gcontent_landscape.csv
│   │   │   ├── S1_F_seed_vs_nonseed.csv
│   │   │   └── S1_G_gt_specificity.csv
│   │   └── README_TABLES.md    # Documentación de tablas
│   ├── viewer/
│   │   └── step1.html          # Viewer HTML consolidado
│   └── logs/
│
├── step1_5_vaf_qc/
│   ├── figures/
│   │   ├── qc/
│   │   │   ├── QC_FIG1_VAF_DISTRIBUTION.png
│   │   │   ├── QC_FIG2_FILTER_IMPACT.png
│   │   │   ├── QC_FIG3_AFFECTED_MIRNAS.png
│   │   │   └── QC_FIG4_BEFORE_AFTER.png
│   │   └── diagnostic/
│   │       ├── STEP1.5_FIG1_HEATMAP_SNVS.png
│   │       ├── STEP1.5_FIG2_HEATMAP_COUNTS.png
│   │       ├── STEP1.5_FIG3_G_TRANSVERSIONS_SNVS.png
│   │       ├── STEP1.5_FIG4_G_TRANSVERSIONS_COUNTS.png
│   │       ├── STEP1.5_FIG5_BUBBLE_PLOT.png
│   │       ├── STEP1.5_FIG6_VIOLIN_DISTRIBUTIONS.png
│   │       └── STEP1.5_FIG7_FOLD_CHANGE.png
│   ├── tables/
│   │   ├── filtered_data/      # Datos filtrados (INPUT para Step 2)
│   │   │   └── ALL_MUTATIONS_VAF_FILTERED.csv  ⭐ USAR ESTO EN STEP 2
│   │   ├── filter_report/       # Reportes del filtro
│   │   │   ├── S1.5_filter_report.csv
│   │   │   ├── S1.5_stats_by_type.csv
│   │   │   └── S1.5_stats_by_mirna.csv
│   │   ├── summary/             # Métricas resumen
│   │   │   ├── S1.5_sample_metrics.csv
│   │   │   ├── S1.5_position_metrics.csv
│   │   │   └── S1.5_mutation_type_summary.csv
│   │   └── README_TABLES.md
│   ├── viewer/
│   │   └── step1_5.html
│   └── logs/
│
└── step2_comparisons/
    ├── figures/
    │   ├── S2_volcano_plot.png
    │   └── S2_effect_size_distribution.png
    ├── tables/
    │   ├── statistical_results/  # Resultados de tests
    │   │   ├── S2_statistical_comparisons.csv  ⭐ RESULTADOS PRINCIPALES
    │   │   └── S2_effect_sizes.csv
    │   ├── summary/              # Resúmenes interpretativos
    │   │   └── S2_significant_mutations.csv  # (nuevo: solo significativos)
    │   └── README_TABLES.md
    ├── viewer/
    │   └── step2.html
    └── logs/
```

### Mejoras Clave

1. **✅ Nombres consistentes**: `S1_`, `S1.5_`, `S2_` prefix
2. **✅ Separación clara**: `filtered_data/`, `filter_report/`, `summary/`, `statistical_results/`
3. **✅ Identificación de inputs clave**: ⭐ marca tablas que se usan en pasos siguientes
4. **✅ Subdirectorios por tipo**: `qc/` vs `diagnostic/` en figuras
5. **✅ README_TABLES.md**: Documentación de cada tabla en cada paso

---

## 📝 Propuesta de README_TABLES.md por Paso

### Template para cada README_TABLES.md:

```markdown
# Tablas Generadas en [STEP NAME]

## 📋 Resumen

Este paso genera [N] tablas organizadas en subdirectorios:

- `filtered_data/`: Datos procesados para uso downstream
- `filter_report/`: Reportes de filtros aplicados
- `summary/`: Métricas resumen por muestra/posición/tipo
- `statistical_results/`: Resultados de tests estadísticos

## 📊 Tablas por Categoría

### [Categoría 1]

| Archivo | Descripción | Columnas Clave | Uso |
|---------|-------------|---------------|-----|
| `archivo.csv` | Descripción | `col1`, `col2` | Input para Step X |

### [Categoría 2]

...

## 🔗 Flujo de Datos

```
Input → [Procesamiento] → Output
Step X → filtered_data/archivo.csv → Step Y
```

## 📌 Notas Importantes

- ⭐ = Tabla usada como input en pasos siguientes
- 🔒 = Tabla final (no se modifica)
- 📊 = Tabla resumen (puede regenerarse)
```

---

## 🎯 Próximos Pasos para Implementar

1. **Reorganizar estructura de outputs** (mantener compatibilidad)
2. **Crear README_TABLES.md** para cada paso
3. **Actualizar reglas Snakemake** con nuevos paths
4. **Generar tabla de "significant mutations"** en Step 2
5. **Actualizar viewers HTML** con nueva organización
6. **Documentar flujo de datos** entre pasos

---

**¿Continuar con la implementación de esta organización mejorada?**


**Fecha:** 2025-11-02  
**Pipeline:** ALS miRNA Oxidation Analysis Pipeline

---

## 📋 Resumen Ejecutivo

Este documento analiza:
1. **Qué hacemos en cada paso** del pipeline
2. **Qué preguntas respondemos** con cada análisis
3. **Qué tablas generamos** y su contenido
4. **Propuesta de organización mejorada** de outputs

---

## 🔬 STEP 1: Análisis Exploratorio Inicial

### 🎯 Objetivo
Caracterizar el dataset inicial y entender los patrones de mutación G>T antes de filtros.

### ❓ Preguntas que Responde

1. **Panel B - G>T Count by Position**
   - ❓ ¿Cuántos SNVs G>T hay por posición?
   - ❓ ¿Hay posiciones con más mutaciones G>T?
   - ❓ ¿Cuál es la distribución de G>T a lo largo de las posiciones?

2. **Panel C - G>X Mutation Spectrum**
   - ❓ ¿Qué tipos de mutaciones G>X ocurren?
   - ❓ ¿Cuál es el espectro mutacional completo (G>A, G>T, G>C)?
   - ❓ ¿Hay diferencias en el espectro por posición?

3. **Panel D - Positional Fraction**
   - ❓ ¿Qué fracción de todas las mutaciones ocurren en cada posición?
   - ❓ ¿Hay posiciones con proporciones desproporcionadamente altas de mutaciones?

4. **Panel E - G-Content Landscape**
   - ❓ ¿Cuántos G hay por posición en los miRNAs?
   - ❓ ¿Hay relación entre cantidad de G y mutaciones G>T?

5. **Panel F - Seed vs Non-seed**
   - ❓ ¿Hay más mutaciones G>T en la región seed (pos 2-7) vs resto?
   - ❓ ¿Qué proporción de SNVs y counts ocurren en seed vs non-seed?

6. **Panel G - G>T Specificity**
   - ❓ ¿Qué proporción de las mutaciones G son G>T vs otras transversiones G?
   - ❓ ¿Hay posiciones donde G>T es más específico?

### 📊 Tablas Generadas (Step 1)

| Tabla | Descripción | Columnas Principales |
|-------|-------------|---------------------|
| `TABLE_1.B_gt_counts_by_position.csv` | Conteos de SNVs G>T por posición | `position`, `total_gt_snvs`, `total_counts`, `mean_counts_per_snv` |
| `TABLE_1.C_gx_spectrum_by_position.csv` | Espectro G>X por posición | `position`, `mutation_type`, `snv_count`, `proportion` |
| `TABLE_1.D_positional_fractions.csv` | Fracciones de mutaciones por posición | `position`, `total_snvs`, `fraction_of_all_snvs`, `total_counts`, `fraction_of_all_counts` |
| `TABLE_1.E_gcontent_landscape.csv` | Contenido de G por posición | `position`, `n_mirnas_with_g`, `total_g_content`, `mean_g_per_mirna` |
| `TABLE_1.F_seed_vs_nonseed.csv` | Comparación seed vs non-seed | `region`, `total_snvs`, `total_counts`, `fraction_snvs`, `fraction_counts` |
| `TABLE_1.G_gt_specificity.csv` | Especificidad G>T vs otras G>X | `position`, `gt_count`, `g_transversion_count`, `gt_fraction` |

### 📈 Figuras Generadas (Step 1)

1. **Panel B**: Gráfico de barras de conteos G>T por posición
2. **Panel C**: Stacked bar chart de espectro G>X por posición
3. **Panel D**: Gráfico de fracciones posicionales
4. **Panel E**: Heatmap/landscape de contenido G
5. **Panel F**: Gráfico comparativo seed vs non-seed
6. **Panel G**: Gráfico de especificidad G>T

---

## 🔍 STEP 1.5: Control de Calidad VAF

### 🎯 Objetivo
Filtrar artefactos técnicos calculando VAF y removiendo mutaciones con VAF ≥ 0.5 (probablemente errores técnicos).

### ❓ Preguntas que Responde

1. **Filtrado VAF**
   - ❓ ¿Cuántas mutaciones tienen VAF ≥ 0.5 (artefactos técnicos)?
   - ❓ ¿Qué proporción de datos se pierde con el filtro?
   - ❓ ¿Qué tipos de mutaciones se filtran más?

2. **Caracterización Post-Filtro**
   - ❓ ¿Cómo cambian los patrones después del filtro VAF?
   - ❓ ¿Qué miRNAs se ven más afectados por el filtro?
   - ❓ ¿Cuáles son las métricas por muestra después del filtro?

3. **Diagnóstico Visual**
   - ❓ ¿Cómo es la distribución de VAF?
   - ❓ ¿Cuál es el impacto del filtro en diferentes métricas?
   - ❓ ¿Cómo se ven los patrones antes vs después del filtro?

### 📊 Tablas Generadas (Step 1.5)

| Tabla | Descripción | Columnas Principales |
|-------|-------------|---------------------|
| `ALL_MUTATIONS_VAF_FILTERED.csv` | **Datos filtrados principales** (usa esto para Step 2) | `miRNA name`, `pos:mut`, `VAF`, `Sample_SNV`, `Sample (PM+1MM+2MM)`, ... |
| `vaf_filter_report.csv` | **Reporte del filtro** | `metric`, `before_filter`, `after_filter`, `removed`, `pct_removed` |
| `vaf_statistics_by_type.csv` | Estadísticas por tipo de mutación | `mutation_type`, `n_before`, `n_after`, `n_removed`, `pct_removed` |
| `vaf_statistics_by_mirna.csv` | Estadísticas por miRNA | `miRNA_name`, `n_mutations_before`, `n_mutations_after`, `n_removed` |
| `sample_metrics_vaf_filtered.csv` | Métricas por muestra después del filtro | `sample`, `total_snvs`, `total_counts`, `mean_vaf`, `n_mutations` |
| `position_metrics_vaf_filtered.csv` | Métricas por posición después del filtro | `position`, `total_snvs`, `total_counts`, `mean_vaf` |
| `mutation_type_summary_vaf_filtered.csv` | Resumen por tipo de mutación | `mutation_type`, `total_snvs`, `total_counts`, `n_positions` |

### 📈 Figuras Generadas (Step 1.5)

**QC Figures (4):**
- QC_FIG1: Distribución de VAF
- QC_FIG2: Impacto del filtro
- QC_FIG3: miRNAs afectados
- QC_FIG4: Antes vs Después

**Diagnostic Figures (7):**
- STEP1.5_FIG1: Heatmap de SNVs
- STEP1.5_FIG2: Heatmap de counts
- STEP1.5_FIG3: G transversiones (SNVs)
- STEP1.5_FIG4: G transversiones (counts)
- STEP1.5_FIG5: Bubble plot
- STEP1.5_FIG6: Distribuciones violin
- STEP1.5_FIG7: Fold change

---

## 📊 STEP 2: Comparaciones Estadísticas (ALS vs Control)

### 🎯 Objetivo
Comparar grupos ALS vs Control para identificar diferencias significativas.

### ❓ Preguntas que Responde

1. **Comparaciones Estadísticas**
   - ❓ ¿Hay diferencias significativas entre ALS y Control?
   - ❓ ¿Qué posiciones/mutaciones son significativamente diferentes?
   - ❓ ¿Cuál es el tamaño del efecto de las diferencias?

2. **Visualización de Significancia**
   - ❓ ¿Cómo visualizamos las diferencias significativas? (Volcano plot)
   - ❓ ¿Cuáles son las mutaciones más importantes? (effect size)

3. **Interpretación Biológica**
   - ❓ ¿Qué mutaciones tienen mayor efecto en ALS?
   - ❓ ¿Hay patrones específicos en posiciones clave (seed, etc.)?

### 📊 Tablas Generadas (Step 2)

| Tabla | Descripción | Columnas Principales |
|-------|-------------|---------------------|
| `step2_statistical_comparisons.csv` | **Resultados de tests estadísticos** | `mutation`, `position`, `als_mean`, `control_mean`, `fold_change`, `p_value`, `p_adjusted`, `significant` |
| `step2_effect_sizes.csv` | Tamaños de efecto | `mutation`, `position`, `effect_size`, `effect_size_category`, `interpretation` |

### 📈 Figuras Generadas (Step 2)

1. **Volcano Plot**: Significancia vs fold change
2. **Effect Size Distribution**: Distribución de tamaños de efecto

---

## 🗂️ Organización Actual de Outputs

```
outputs/
├── step1/
│   ├── figures/          # 6 PNG
│   ├── tables/           # 6 CSV
│   └── logs/             # 6 log files
├── step1_5/
│   ├── figures/          # 11 PNG
│   ├── tables/           # 7 CSV
│   ├── data/             # Datos filtrados (1 CSV)
│   └── logs/             # 2 log files
└── step2/
    ├── figures/          # 2 PNG
    ├── tables/           # 2 CSV
    └── logs/             # 3 log files
```

**Problemas identificados:**
1. ❌ Tablas no están claramente categorizadas (intermedias vs finales)
2. ❌ No hay separación entre tablas "raw" y tablas "resumen"
3. ❌ No está claro cuál tabla usar para análisis downstream
4. ❌ Nombres de tablas inconsistentes (TABLE_1.X vs step2_)
5. ❌ Datos filtrados de Step 1.5 mezclados con tablas resumen

---

## 💡 Propuesta de Organización Mejorada

### Estructura Propuesta

```
outputs/
├── step1_exploratory/
│   ├── figures/
│   │   ├── panel_B_gt_counts_by_position.png
│   │   ├── panel_C_gx_spectrum.png
│   │   ├── panel_D_positional_fraction.png
│   │   ├── panel_E_gcontent_landscape.png
│   │   ├── panel_F_seed_vs_nonseed.png
│   │   └── panel_G_gt_specificity.png
│   ├── tables/
│   │   ├── raw_data/           # Datos procesados intermedios
│   │   │   └── (ninguna - Step 1 no genera datos intermedios)
│   │   ├── summary/            # Tablas resumen por análisis
│   │   │   ├── S1_B_gt_counts_by_position.csv
│   │   │   ├── S1_C_gx_spectrum_by_position.csv
│   │   │   ├── S1_D_positional_fractions.csv
│   │   │   ├── S1_E_gcontent_landscape.csv
│   │   │   ├── S1_F_seed_vs_nonseed.csv
│   │   │   └── S1_G_gt_specificity.csv
│   │   └── README_TABLES.md    # Documentación de tablas
│   ├── viewer/
│   │   └── step1.html          # Viewer HTML consolidado
│   └── logs/
│
├── step1_5_vaf_qc/
│   ├── figures/
│   │   ├── qc/
│   │   │   ├── QC_FIG1_VAF_DISTRIBUTION.png
│   │   │   ├── QC_FIG2_FILTER_IMPACT.png
│   │   │   ├── QC_FIG3_AFFECTED_MIRNAS.png
│   │   │   └── QC_FIG4_BEFORE_AFTER.png
│   │   └── diagnostic/
│   │       ├── STEP1.5_FIG1_HEATMAP_SNVS.png
│   │       ├── STEP1.5_FIG2_HEATMAP_COUNTS.png
│   │       ├── STEP1.5_FIG3_G_TRANSVERSIONS_SNVS.png
│   │       ├── STEP1.5_FIG4_G_TRANSVERSIONS_COUNTS.png
│   │       ├── STEP1.5_FIG5_BUBBLE_PLOT.png
│   │       ├── STEP1.5_FIG6_VIOLIN_DISTRIBUTIONS.png
│   │       └── STEP1.5_FIG7_FOLD_CHANGE.png
│   ├── tables/
│   │   ├── filtered_data/      # Datos filtrados (INPUT para Step 2)
│   │   │   └── ALL_MUTATIONS_VAF_FILTERED.csv  ⭐ USAR ESTO EN STEP 2
│   │   ├── filter_report/       # Reportes del filtro
│   │   │   ├── S1.5_filter_report.csv
│   │   │   ├── S1.5_stats_by_type.csv
│   │   │   └── S1.5_stats_by_mirna.csv
│   │   ├── summary/             # Métricas resumen
│   │   │   ├── S1.5_sample_metrics.csv
│   │   │   ├── S1.5_position_metrics.csv
│   │   │   └── S1.5_mutation_type_summary.csv
│   │   └── README_TABLES.md
│   ├── viewer/
│   │   └── step1_5.html
│   └── logs/
│
└── step2_comparisons/
    ├── figures/
    │   ├── S2_volcano_plot.png
    │   └── S2_effect_size_distribution.png
    ├── tables/
    │   ├── statistical_results/  # Resultados de tests
    │   │   ├── S2_statistical_comparisons.csv  ⭐ RESULTADOS PRINCIPALES
    │   │   └── S2_effect_sizes.csv
    │   ├── summary/              # Resúmenes interpretativos
    │   │   └── S2_significant_mutations.csv  # (nuevo: solo significativos)
    │   └── README_TABLES.md
    ├── viewer/
    │   └── step2.html
    └── logs/
```

### Mejoras Clave

1. **✅ Nombres consistentes**: `S1_`, `S1.5_`, `S2_` prefix
2. **✅ Separación clara**: `filtered_data/`, `filter_report/`, `summary/`, `statistical_results/`
3. **✅ Identificación de inputs clave**: ⭐ marca tablas que se usan en pasos siguientes
4. **✅ Subdirectorios por tipo**: `qc/` vs `diagnostic/` en figuras
5. **✅ README_TABLES.md**: Documentación de cada tabla en cada paso

---

## 📝 Propuesta de README_TABLES.md por Paso

### Template para cada README_TABLES.md:

```markdown
# Tablas Generadas en [STEP NAME]

## 📋 Resumen

Este paso genera [N] tablas organizadas en subdirectorios:

- `filtered_data/`: Datos procesados para uso downstream
- `filter_report/`: Reportes de filtros aplicados
- `summary/`: Métricas resumen por muestra/posición/tipo
- `statistical_results/`: Resultados de tests estadísticos

## 📊 Tablas por Categoría

### [Categoría 1]

| Archivo | Descripción | Columnas Clave | Uso |
|---------|-------------|---------------|-----|
| `archivo.csv` | Descripción | `col1`, `col2` | Input para Step X |

### [Categoría 2]

...

## 🔗 Flujo de Datos

```
Input → [Procesamiento] → Output
Step X → filtered_data/archivo.csv → Step Y
```

## 📌 Notas Importantes

- ⭐ = Tabla usada como input en pasos siguientes
- 🔒 = Tabla final (no se modifica)
- 📊 = Tabla resumen (puede regenerarse)
```

---

## 🎯 Próximos Pasos para Implementar

1. **Reorganizar estructura de outputs** (mantener compatibilidad)
2. **Crear README_TABLES.md** para cada paso
3. **Actualizar reglas Snakemake** con nuevos paths
4. **Generar tabla de "significant mutations"** en Step 2
5. **Actualizar viewers HTML** con nueva organización
6. **Documentar flujo de datos** entre pasos

---

**¿Continuar con la implementación de esta organización mejorada?**


**Fecha:** 2025-11-02  
**Pipeline:** ALS miRNA Oxidation Analysis Pipeline

---

## 📋 Resumen Ejecutivo

Este documento analiza:
1. **Qué hacemos en cada paso** del pipeline
2. **Qué preguntas respondemos** con cada análisis
3. **Qué tablas generamos** y su contenido
4. **Propuesta de organización mejorada** de outputs

---

## 🔬 STEP 1: Análisis Exploratorio Inicial

### 🎯 Objetivo
Caracterizar el dataset inicial y entender los patrones de mutación G>T antes de filtros.

### ❓ Preguntas que Responde

1. **Panel B - G>T Count by Position**
   - ❓ ¿Cuántos SNVs G>T hay por posición?
   - ❓ ¿Hay posiciones con más mutaciones G>T?
   - ❓ ¿Cuál es la distribución de G>T a lo largo de las posiciones?

2. **Panel C - G>X Mutation Spectrum**
   - ❓ ¿Qué tipos de mutaciones G>X ocurren?
   - ❓ ¿Cuál es el espectro mutacional completo (G>A, G>T, G>C)?
   - ❓ ¿Hay diferencias en el espectro por posición?

3. **Panel D - Positional Fraction**
   - ❓ ¿Qué fracción de todas las mutaciones ocurren en cada posición?
   - ❓ ¿Hay posiciones con proporciones desproporcionadamente altas de mutaciones?

4. **Panel E - G-Content Landscape**
   - ❓ ¿Cuántos G hay por posición en los miRNAs?
   - ❓ ¿Hay relación entre cantidad de G y mutaciones G>T?

5. **Panel F - Seed vs Non-seed**
   - ❓ ¿Hay más mutaciones G>T en la región seed (pos 2-7) vs resto?
   - ❓ ¿Qué proporción de SNVs y counts ocurren en seed vs non-seed?

6. **Panel G - G>T Specificity**
   - ❓ ¿Qué proporción de las mutaciones G son G>T vs otras transversiones G?
   - ❓ ¿Hay posiciones donde G>T es más específico?

### 📊 Tablas Generadas (Step 1)

| Tabla | Descripción | Columnas Principales |
|-------|-------------|---------------------|
| `TABLE_1.B_gt_counts_by_position.csv` | Conteos de SNVs G>T por posición | `position`, `total_gt_snvs`, `total_counts`, `mean_counts_per_snv` |
| `TABLE_1.C_gx_spectrum_by_position.csv` | Espectro G>X por posición | `position`, `mutation_type`, `snv_count`, `proportion` |
| `TABLE_1.D_positional_fractions.csv` | Fracciones de mutaciones por posición | `position`, `total_snvs`, `fraction_of_all_snvs`, `total_counts`, `fraction_of_all_counts` |
| `TABLE_1.E_gcontent_landscape.csv` | Contenido de G por posición | `position`, `n_mirnas_with_g`, `total_g_content`, `mean_g_per_mirna` |
| `TABLE_1.F_seed_vs_nonseed.csv` | Comparación seed vs non-seed | `region`, `total_snvs`, `total_counts`, `fraction_snvs`, `fraction_counts` |
| `TABLE_1.G_gt_specificity.csv` | Especificidad G>T vs otras G>X | `position`, `gt_count`, `g_transversion_count`, `gt_fraction` |

### 📈 Figuras Generadas (Step 1)

1. **Panel B**: Gráfico de barras de conteos G>T por posición
2. **Panel C**: Stacked bar chart de espectro G>X por posición
3. **Panel D**: Gráfico de fracciones posicionales
4. **Panel E**: Heatmap/landscape de contenido G
5. **Panel F**: Gráfico comparativo seed vs non-seed
6. **Panel G**: Gráfico de especificidad G>T

---

## 🔍 STEP 1.5: Control de Calidad VAF

### 🎯 Objetivo
Filtrar artefactos técnicos calculando VAF y removiendo mutaciones con VAF ≥ 0.5 (probablemente errores técnicos).

### ❓ Preguntas que Responde

1. **Filtrado VAF**
   - ❓ ¿Cuántas mutaciones tienen VAF ≥ 0.5 (artefactos técnicos)?
   - ❓ ¿Qué proporción de datos se pierde con el filtro?
   - ❓ ¿Qué tipos de mutaciones se filtran más?

2. **Caracterización Post-Filtro**
   - ❓ ¿Cómo cambian los patrones después del filtro VAF?
   - ❓ ¿Qué miRNAs se ven más afectados por el filtro?
   - ❓ ¿Cuáles son las métricas por muestra después del filtro?

3. **Diagnóstico Visual**
   - ❓ ¿Cómo es la distribución de VAF?
   - ❓ ¿Cuál es el impacto del filtro en diferentes métricas?
   - ❓ ¿Cómo se ven los patrones antes vs después del filtro?

### 📊 Tablas Generadas (Step 1.5)

| Tabla | Descripción | Columnas Principales |
|-------|-------------|---------------------|
| `ALL_MUTATIONS_VAF_FILTERED.csv` | **Datos filtrados principales** (usa esto para Step 2) | `miRNA name`, `pos:mut`, `VAF`, `Sample_SNV`, `Sample (PM+1MM+2MM)`, ... |
| `vaf_filter_report.csv` | **Reporte del filtro** | `metric`, `before_filter`, `after_filter`, `removed`, `pct_removed` |
| `vaf_statistics_by_type.csv` | Estadísticas por tipo de mutación | `mutation_type`, `n_before`, `n_after`, `n_removed`, `pct_removed` |
| `vaf_statistics_by_mirna.csv` | Estadísticas por miRNA | `miRNA_name`, `n_mutations_before`, `n_mutations_after`, `n_removed` |
| `sample_metrics_vaf_filtered.csv` | Métricas por muestra después del filtro | `sample`, `total_snvs`, `total_counts`, `mean_vaf`, `n_mutations` |
| `position_metrics_vaf_filtered.csv` | Métricas por posición después del filtro | `position`, `total_snvs`, `total_counts`, `mean_vaf` |
| `mutation_type_summary_vaf_filtered.csv` | Resumen por tipo de mutación | `mutation_type`, `total_snvs`, `total_counts`, `n_positions` |

### 📈 Figuras Generadas (Step 1.5)

**QC Figures (4):**
- QC_FIG1: Distribución de VAF
- QC_FIG2: Impacto del filtro
- QC_FIG3: miRNAs afectados
- QC_FIG4: Antes vs Después

**Diagnostic Figures (7):**
- STEP1.5_FIG1: Heatmap de SNVs
- STEP1.5_FIG2: Heatmap de counts
- STEP1.5_FIG3: G transversiones (SNVs)
- STEP1.5_FIG4: G transversiones (counts)
- STEP1.5_FIG5: Bubble plot
- STEP1.5_FIG6: Distribuciones violin
- STEP1.5_FIG7: Fold change

---

## 📊 STEP 2: Comparaciones Estadísticas (ALS vs Control)

### 🎯 Objetivo
Comparar grupos ALS vs Control para identificar diferencias significativas.

### ❓ Preguntas que Responde

1. **Comparaciones Estadísticas**
   - ❓ ¿Hay diferencias significativas entre ALS y Control?
   - ❓ ¿Qué posiciones/mutaciones son significativamente diferentes?
   - ❓ ¿Cuál es el tamaño del efecto de las diferencias?

2. **Visualización de Significancia**
   - ❓ ¿Cómo visualizamos las diferencias significativas? (Volcano plot)
   - ❓ ¿Cuáles son las mutaciones más importantes? (effect size)

3. **Interpretación Biológica**
   - ❓ ¿Qué mutaciones tienen mayor efecto en ALS?
   - ❓ ¿Hay patrones específicos en posiciones clave (seed, etc.)?

### 📊 Tablas Generadas (Step 2)

| Tabla | Descripción | Columnas Principales |
|-------|-------------|---------------------|
| `step2_statistical_comparisons.csv` | **Resultados de tests estadísticos** | `mutation`, `position`, `als_mean`, `control_mean`, `fold_change`, `p_value`, `p_adjusted`, `significant` |
| `step2_effect_sizes.csv` | Tamaños de efecto | `mutation`, `position`, `effect_size`, `effect_size_category`, `interpretation` |

### 📈 Figuras Generadas (Step 2)

1. **Volcano Plot**: Significancia vs fold change
2. **Effect Size Distribution**: Distribución de tamaños de efecto

---

## 🗂️ Organización Actual de Outputs

```
outputs/
├── step1/
│   ├── figures/          # 6 PNG
│   ├── tables/           # 6 CSV
│   └── logs/             # 6 log files
├── step1_5/
│   ├── figures/          # 11 PNG
│   ├── tables/           # 7 CSV
│   ├── data/             # Datos filtrados (1 CSV)
│   └── logs/             # 2 log files
└── step2/
    ├── figures/          # 2 PNG
    ├── tables/           # 2 CSV
    └── logs/             # 3 log files
```

**Problemas identificados:**
1. ❌ Tablas no están claramente categorizadas (intermedias vs finales)
2. ❌ No hay separación entre tablas "raw" y tablas "resumen"
3. ❌ No está claro cuál tabla usar para análisis downstream
4. ❌ Nombres de tablas inconsistentes (TABLE_1.X vs step2_)
5. ❌ Datos filtrados de Step 1.5 mezclados con tablas resumen

---

## 💡 Propuesta de Organización Mejorada

### Estructura Propuesta

```
outputs/
├── step1_exploratory/
│   ├── figures/
│   │   ├── panel_B_gt_counts_by_position.png
│   │   ├── panel_C_gx_spectrum.png
│   │   ├── panel_D_positional_fraction.png
│   │   ├── panel_E_gcontent_landscape.png
│   │   ├── panel_F_seed_vs_nonseed.png
│   │   └── panel_G_gt_specificity.png
│   ├── tables/
│   │   ├── raw_data/           # Datos procesados intermedios
│   │   │   └── (ninguna - Step 1 no genera datos intermedios)
│   │   ├── summary/            # Tablas resumen por análisis
│   │   │   ├── S1_B_gt_counts_by_position.csv
│   │   │   ├── S1_C_gx_spectrum_by_position.csv
│   │   │   ├── S1_D_positional_fractions.csv
│   │   │   ├── S1_E_gcontent_landscape.csv
│   │   │   ├── S1_F_seed_vs_nonseed.csv
│   │   │   └── S1_G_gt_specificity.csv
│   │   └── README_TABLES.md    # Documentación de tablas
│   ├── viewer/
│   │   └── step1.html          # Viewer HTML consolidado
│   └── logs/
│
├── step1_5_vaf_qc/
│   ├── figures/
│   │   ├── qc/
│   │   │   ├── QC_FIG1_VAF_DISTRIBUTION.png
│   │   │   ├── QC_FIG2_FILTER_IMPACT.png
│   │   │   ├── QC_FIG3_AFFECTED_MIRNAS.png
│   │   │   └── QC_FIG4_BEFORE_AFTER.png
│   │   └── diagnostic/
│   │       ├── STEP1.5_FIG1_HEATMAP_SNVS.png
│   │       ├── STEP1.5_FIG2_HEATMAP_COUNTS.png
│   │       ├── STEP1.5_FIG3_G_TRANSVERSIONS_SNVS.png
│   │       ├── STEP1.5_FIG4_G_TRANSVERSIONS_COUNTS.png
│   │       ├── STEP1.5_FIG5_BUBBLE_PLOT.png
│   │       ├── STEP1.5_FIG6_VIOLIN_DISTRIBUTIONS.png
│   │       └── STEP1.5_FIG7_FOLD_CHANGE.png
│   ├── tables/
│   │   ├── filtered_data/      # Datos filtrados (INPUT para Step 2)
│   │   │   └── ALL_MUTATIONS_VAF_FILTERED.csv  ⭐ USAR ESTO EN STEP 2
│   │   ├── filter_report/       # Reportes del filtro
│   │   │   ├── S1.5_filter_report.csv
│   │   │   ├── S1.5_stats_by_type.csv
│   │   │   └── S1.5_stats_by_mirna.csv
│   │   ├── summary/             # Métricas resumen
│   │   │   ├── S1.5_sample_metrics.csv
│   │   │   ├── S1.5_position_metrics.csv
│   │   │   └── S1.5_mutation_type_summary.csv
│   │   └── README_TABLES.md
│   ├── viewer/
│   │   └── step1_5.html
│   └── logs/
│
└── step2_comparisons/
    ├── figures/
    │   ├── S2_volcano_plot.png
    │   └── S2_effect_size_distribution.png
    ├── tables/
    │   ├── statistical_results/  # Resultados de tests
    │   │   ├── S2_statistical_comparisons.csv  ⭐ RESULTADOS PRINCIPALES
    │   │   └── S2_effect_sizes.csv
    │   ├── summary/              # Resúmenes interpretativos
    │   │   └── S2_significant_mutations.csv  # (nuevo: solo significativos)
    │   └── README_TABLES.md
    ├── viewer/
    │   └── step2.html
    └── logs/
```

### Mejoras Clave

1. **✅ Nombres consistentes**: `S1_`, `S1.5_`, `S2_` prefix
2. **✅ Separación clara**: `filtered_data/`, `filter_report/`, `summary/`, `statistical_results/`
3. **✅ Identificación de inputs clave**: ⭐ marca tablas que se usan en pasos siguientes
4. **✅ Subdirectorios por tipo**: `qc/` vs `diagnostic/` en figuras
5. **✅ README_TABLES.md**: Documentación de cada tabla en cada paso

---

## 📝 Propuesta de README_TABLES.md por Paso

### Template para cada README_TABLES.md:

```markdown
# Tablas Generadas en [STEP NAME]

## 📋 Resumen

Este paso genera [N] tablas organizadas en subdirectorios:

- `filtered_data/`: Datos procesados para uso downstream
- `filter_report/`: Reportes de filtros aplicados
- `summary/`: Métricas resumen por muestra/posición/tipo
- `statistical_results/`: Resultados de tests estadísticos

## 📊 Tablas por Categoría

### [Categoría 1]

| Archivo | Descripción | Columnas Clave | Uso |
|---------|-------------|---------------|-----|
| `archivo.csv` | Descripción | `col1`, `col2` | Input para Step X |

### [Categoría 2]

...

## 🔗 Flujo de Datos

```
Input → [Procesamiento] → Output
Step X → filtered_data/archivo.csv → Step Y
```

## 📌 Notas Importantes

- ⭐ = Tabla usada como input en pasos siguientes
- 🔒 = Tabla final (no se modifica)
- 📊 = Tabla resumen (puede regenerarse)
```

---

## 🎯 Próximos Pasos para Implementar

1. **Reorganizar estructura de outputs** (mantener compatibilidad)
2. **Crear README_TABLES.md** para cada paso
3. **Actualizar reglas Snakemake** con nuevos paths
4. **Generar tabla de "significant mutations"** en Step 2
5. **Actualizar viewers HTML** con nueva organización
6. **Documentar flujo de datos** entre pasos

---

**¿Continuar con la implementación de esta organización mejorada?**

