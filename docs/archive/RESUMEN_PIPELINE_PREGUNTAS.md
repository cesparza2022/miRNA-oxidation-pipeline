# 📊 Resumen Ejecutivo: Pipeline, Preguntas y Tablas

**Pipeline:** ALS miRNA Oxidation Analysis  
**Fecha:** 2025-11-02

---

## 🎯 Visión General: Flujo del Pipeline

```
INPUT DATA
    ↓
┌─────────────────────────────────────────────────────────┐
│ STEP 1: Análisis Exploratorio                          │
│ ❓ Pregunta: ¿Cómo se ven los datos antes de filtros?   │
│ 📊 Output: 6 figuras + 6 tablas resumen                 │
└─────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────┐
│ STEP 1.5: Control de Calidad VAF                        │
│ ❓ Pregunta: ¿Qué artefactos técnicos debemos remover?   │
│ 📊 Output: 11 figuras + 7 tablas                        │
│ ⭐ Genera: ALL_MUTATIONS_VAF_FILTERED.csv (INPUT Step 2)│
└─────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────┐
│ STEP 2: Comparaciones Estadísticas (ALS vs Control)     │
│ ❓ Pregunta: ¿Hay diferencias significativas?            │
│ 📊 Output: 2 figuras + 2 tablas                         │
│ ⭐ Resultados finales para interpretación               │
└─────────────────────────────────────────────────────────┘
```

---

## 📋 Preguntas Biológicas por Paso

### 🔬 STEP 1: Análisis Exploratorio

**Objetivo:** Caracterizar el dataset inicial sin filtros

| Panel | Pregunta Biológica | Tabla que Responde | Interpretación Clave |
|-------|-------------------|-------------------|---------------------|
| **B** | ¿Cuántos SNVs G>T hay por posición? | `S1_B_gt_counts_by_position.csv` | Hotspots de mutación G>T |
| **C** | ¿Qué tipos de mutaciones G>X ocurren? | `S1_C_gx_spectrum_by_position.csv` | Espectro mutacional (G>A, G>T, G>C) |
| **D** | ¿Qué fracción de mutaciones ocurren en cada posición? | `S1_D_positional_fractions.csv` | Posiciones críticas |
| **E** | ¿Hay relación entre contenido G y mutaciones G>T? | `S1_E_gcontent_landscape.csv` | Validación mecanicista |
| **F** | ⭐ **¿Hay más G>T en seed que en non-seed?** | `S1_F_seed_vs_nonseed.csv` | **Pregunta clave:** Seed enrichment |
| **G** | ¿Qué proporción de G>X es específicamente G>T? | `S1_G_gt_specificity.csv` | Especificidad de oxidación |

**Pregunta Central del Step 1:**  
🎯 **"¿Cuáles son los patrones generales de mutación G>T antes de aplicar filtros de calidad?"**

---

### 🔍 STEP 1.5: Control de Calidad VAF

**Objetivo:** Filtrar artefactos técnicos (VAF ≥ 0.5)

| Análisis | Pregunta | Tabla que Responde | Uso |
|---------|---------|-------------------|-----|
| **Filtro VAF** | ¿Cuántos artefactos se remueven? | `S1.5_filter_report.csv` | Cuantificar pérdida de datos |
| **Por Tipo** | ¿Qué tipos de mutaciones se filtran más? | `S1.5_stats_by_type.csv` | Entender qué se pierde |
| **Por miRNA** | ¿Qué miRNAs se ven más afectados? | `S1.5_stats_by_mirna.csv` | Identificar miRNAs problemáticos |
| **Métricas** | ¿Cómo cambian las métricas después del filtro? | `S1.5_sample_metrics.csv`, `S1.5_position_metrics.csv` | Validar calidad post-filtro |
| **⭐ DATOS FILTRADOS** | **¿Cuáles son los datos limpios para Step 2?** | **`ALL_MUTATIONS_VAF_FILTERED.csv`** | **INPUT para comparaciones** |

**Pregunta Central del Step 1.5:**  
🎯 **"¿Qué datos son confiables (VAF < 0.5) para análisis downstream?"**

---

### 📊 STEP 2: Comparaciones Estadísticas

**Objetivo:** Identificar diferencias significativas entre ALS y Control

| Análisis | Pregunta | Tabla que Responde | Interpretación |
|---------|---------|-------------------|---------------|
| **Tests Estadísticos** | ⭐ **¿Hay diferencias significativas ALS vs Control?** | `S2_statistical_comparisons.csv` | `p_adjusted < 0.05`, `significant == TRUE` |
| **Tamaño de Efecto** | ¿Cuál es la magnitud de las diferencias? | `S2_effect_sizes.csv` | `cohens_d`, `effect_size_category` |
| **⭐ Significativos** | **¿Cuáles son las mutaciones más importantes?** | **`S2_significant_mutations.csv`** ⚠️ **PROPUESTA** | Ordenadas por `fold_change` |
| **⭐ Top Efectos** | **¿Cuáles son los top 50 efectos?** | **`S2_top_effect_sizes.csv`** ⚠️ **PROPUESTA** | Top por `cohens_d` |
| **⭐ Seed Significativos** | **¿Hay enrichment en seed región?** | **`S2_seed_region_significant.csv`** ⚠️ **PROPUESTA** | Significativos en pos 2-7 |

**Pregunta Central del Step 2:**  
🎯 **"¿Qué mutaciones G>T son significativamente diferentes entre ALS y Control?"**

**Pregunta Específica Clave:**  
🎯 **"¿Hay más mutaciones G>T significativas en la región seed en ALS comparado con Control?"**

---

## 📊 Inventario Completo de Tablas

### Step 1: 6 Tablas Resumen

| Tabla | Filas Típicas | Columnas Clave | Propósito |
|-------|--------------|---------------|-----------|
| `S1_B_gt_counts_by_position.csv` | 23 (posiciones) | `position`, `total_GT_count`, `n_SNVs`, `n_miRNAs` | Conteos G>T por posición |
| `S1_C_gx_spectrum_by_position.csv` | ~69 (23 pos × 3 tipos) | `position`, `mutation_type`, `n`, `percentage` | Espectro G>X completo |
| `S1_D_positional_fractions.csv` | 23 (posiciones) | `position`, `snv_count`, `fraction`, `region` | Fracciones posicionales |
| `S1_E_gcontent_landscape.csv` | 23 (posiciones) | `Position`, `total_G_copies`, `GT_counts_at_position` | Contenido G por posición |
| `S1_F_seed_vs_nonseed.csv` | 2 (regiones) | `region`, `total_snvs`, `fraction_snvs`, `fraction_counts` | Comparación seed/non-seed |
| `S1_G_gt_specificity.csv` | 2 (categorías) | `category`, `total`, `percentage` | Especificidad G>T |

### Step 1.5: 7 Tablas

| Tabla | Filas Típicas | Columnas Clave | Propósito |
|-------|--------------|---------------|-----------|
| ⭐ **`ALL_MUTATIONS_VAF_FILTERED.csv`** | ~100,000+ | `miRNA name`, `pos:mut`, `VAF`, `Sample_SNV`, ... | **Datos filtrados (INPUT Step 2)** |
| `S1.5_filter_report.csv` | 1-10 | `metric`, `before_filter`, `after_filter`, `pct_removed` | Reporte del filtro |
| `S1.5_stats_by_type.csv` | ~10-20 | `Mutation_Type`, `N_Filtered`, `Mean_VAF` | Estadísticas por tipo |
| `S1.5_stats_by_mirna.csv` | ~1,000+ | `miRNA`, `N_Filtered`, `Mean_VAF` | Estadísticas por miRNA |
| `S1.5_sample_metrics.csv` | ~800+ | `Sample`, `Mutation_Type`, `N_SNVs`, `Total_Counts` | Métricas por muestra |
| `S1.5_position_metrics.csv` | ~230+ | `Position`, `Mutation_Type`, `N_SNVs`, `Total_Counts` | Métricas por posición |
| `S1.5_mutation_type_summary.csv` | ~10-20 | `Mutation_Type`, `Mean_SNVs`, `Mean_Counts` | Resumen por tipo |

### Step 2: 2 Tablas Actuales + 3 Propuestas

| Tabla | Filas Típicas | Columnas Clave | Propósito |
|-------|--------------|---------------|-----------|
| `S2_statistical_comparisons.csv` | ~5,000+ | `SNV_id`, `ALS_mean`, `Control_mean`, `fold_change`, `p_adjusted`, `significant` | **Resultados completos** |
| `S2_effect_sizes.csv` | ~5,000+ | `miRNA_name`, `pos.mut`, `cohens_d`, `effect_size_category` | Tamaños de efecto |
| ⚠️ **`S2_significant_mutations.csv`** | ~50-500 | `SNV_id`, `fold_change`, `p_adjusted`, `effect_size` | **PROPUESTA:** Solo significativos |
| ⚠️ **`S2_top_effect_sizes.csv`** | 50 | `SNV_id`, `cohens_d`, `fold_change` | **PROPUESTA:** Top 50 efectos |
| ⚠️ **`S2_seed_region_significant.csv`** | ~10-100 | `SNV_id`, `position`, `fold_change`, `effect_size` | **PROPUESTA:** Significativos en seed |

---

## 🔄 Flujo de Datos Entre Pasos

```
┌─────────────────────────────────────────────────────────────┐
│ INPUT FILES                                                  │
├─────────────────────────────────────────────────────────────┤
│ • final_processed_data_CLEAN.csv  → Step 1                  │
│ • step1_original_data.csv        → Step 1.5                 │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ STEP 1: Exploratory Analysis                                │
├─────────────────────────────────────────────────────────────┤
│ Input:  final_processed_data_CLEAN.csv                     │
│ Output: 6 summary tables (NO datos intermedios)             │
│         • Solo resúmenes estadísticos                       │
│         • No se usan directamente en Step 2                 │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ STEP 1.5: VAF Quality Control                               │
├─────────────────────────────────────────────────────────────┤
│ Input:  step1_original_data.csv (necesita SNV + total)     │
│ Output: ALL_MUTATIONS_VAF_FILTERED.csv ⭐                   │
│         (Este es el INPUT para Step 2)                      │
│         + 6 tablas de reporte y métricas                    │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ STEP 2: Statistical Comparisons                            │
├─────────────────────────────────────────────────────────────┤
│ Input:  ALL_MUTATIONS_VAF_FILTERED.csv (de Step 1.5)       │
│ Output: S2_statistical_comparisons.csv ⭐                   │
│         S2_effect_sizes.csv                                 │
│         + 3 tablas propuestas (significativos, top, seed)   │
└─────────────────────────────────────────────────────────────┘
```

---

## 🗂️ Problemas Actuales en la Organización

### ❌ Problemas Identificados

1. **Nomenclatura Inconsistente**
   - `TABLE_1.B_...` vs `step2_...`
   - Difícil ordenar y encontrar tablas

2. **No Está Claro el Flujo de Datos**
   - ¿Cuál tabla de Step 1.5 usar en Step 2?
   - Datos filtrados mezclados con reportes

3. **Falta Información Interpretativa**
   - No hay tabla de "mutaciones significativas" resumida
   - No hay tabla de "top efectos"
   - No hay tabla específica para seed region

4. **Subdirectorios No Organizados**
   - Todas las tablas en un solo `tables/`
   - Difícil distinguir entre datos intermedios y resultados finales

5. **Falta Documentación**
   - No hay README explicando qué es cada tabla
   - No está claro qué columnas tiene cada tabla

---

## ✅ Solución Propuesta: Organización Mejorada

### Estructura Propuesta

```
outputs/
│
├── step1_exploratory/
│   ├── figures/         # 6 figuras
│   ├── tables/
│   │   └── summary/      # 6 tablas resumen (S1_ prefix)
│   ├── viewer/
│   └── logs/
│
├── step1_5_vaf_qc/
│   ├── figures/
│   │   ├── qc/          # 4 figuras QC
│   │   └── diagnostic/  # 7 figuras diagnósticas
│   ├── tables/
│   │   ├── filtered_data/     ⭐ INPUT para Step 2
│   │   ├── filter_report/     # 3 tablas de reporte
│   │   └── summary/           # 3 tablas de métricas
│   ├── viewer/
│   └── logs/
│
└── step2_comparisons/
    ├── figures/         # 2 figuras
    ├── tables/
    │   ├── statistical_results/  # 2 tablas completas
    │   └── summary/              # 3 tablas interpretativas ⭐ PROPUESTAS
    ├── viewer/
    └── logs/
```

### Ventajas

1. ✅ **Prefijos consistentes:** `S1_`, `S1.5_`, `S2_`
2. ✅ **Separación clara:** `filtered_data/`, `summary/`, `statistical_results/`
3. ✅ **Marcadores visuales:** ⭐ para tablas clave
4. ✅ **Documentación:** README_TABLES.md en cada paso
5. ✅ **Tablas interpretativas:** Resúmenes fáciles de usar

---

## 📋 Tablas Propuestas para Step 2

### 1. `S2_significant_mutations.csv`

**Propósito:** Solo mutaciones con `p_adjusted < 0.05`

**Columnas:**
```csv
SNV_id,miRNA_name,position,mutation_type,ALS_mean,Control_mean,
fold_change,log2_fold_change,p_adjusted,cohens_d,effect_size_category,
is_seed_region,is_gt_mutation
```

**Uso:** Interpretación rápida de resultados

### 2. `S2_top_effect_sizes.csv`

**Propósito:** Top 50 mutaciones por `cohens_d` absoluto

**Columnas:**
```csv
rank,SNV_id,miRNA_name,position,mutation_type,cohens_d,fold_change,
p_adjusted,interpretation
```

**Uso:** Identificar las mutaciones con mayor impacto

### 3. `S2_seed_region_significant.csv`

**Propósito:** Solo mutaciones significativas en seed (pos 2-7)

**Columnas:**
```csv
SNV_id,miRNA_name,position,mutation_type,ALS_mean,Control_mean,
fold_change,p_adjusted,cohens_d,is_gt_mutation
```

**Uso:** Responder pregunta clave sobre enrichment en seed

---

## 🎯 Matriz de Preguntas vs Respuestas

| Pregunta Biológica | Paso | Tabla(s) | Métrica Clave | Interpretación |
|-------------------|------|----------|---------------|---------------|
| **¿Hay más G>T en seed que en non-seed?** | Step 1 | `S1_F_seed_vs_nonseed.csv` | `fraction_snvs` (seed vs non-seed) | Si `fraction_snvs` en seed > non-seed → enrichment |
| **¿Qué posiciones tienen más mutaciones G>T?** | Step 1 | `S1_B_gt_counts_by_position.csv` | `total_GT_count`, `n_SNVs` | Identificar hotspots (pos 6, 7 típicamente altos) |
| **¿Cuántos artefactos técnicos se remueven?** | Step 1.5 | `S1.5_filter_report.csv` | `pct_removed` | Si > 20% removido → muchos artefactos |
| **¿Hay diferencias significativas ALS vs Control?** | Step 2 | `S2_statistical_comparisons.csv` | `p_adjusted < 0.05` | Número de `significant == TRUE` |
| **⭐ ¿Qué mutaciones son las más importantes?** | Step 2 | `S2_significant_mutations.csv` ⚠️ | `fold_change`, `effect_size` | Ordenadas por importancia |
| **⭐ ¿Hay enrichment en seed región en ALS?** | Step 2 | `S2_seed_region_significant.csv` ⚠️ | `position` en 2-7, `significant == TRUE` | Contar significativos en seed vs otros |

---

## 🚀 Plan de Acción

### Fase 1: Documentación (✅ COMPLETADA)
- ✅ Análisis de pasos y preguntas
- ✅ Propuesta de organización
- ✅ Identificación de tablas faltantes

### Fase 2: Implementación (Pendiente)

1. **Reorganizar estructura de outputs**
   - Crear nuevos subdirectorios
   - Mover tablas existentes
   - Actualizar paths en Snakemake

2. **Generar tablas faltantes en Step 2**
   - Script para `S2_significant_mutations.csv`
   - Script para `S2_top_effect_sizes.csv`
   - Script para `S2_seed_region_significant.csv`

3. **Crear README_TABLES.md** para cada paso
   - Documentar columnas
   - Explicar propósito
   - Mapear preguntas → tablas

4. **Actualizar reglas Snakemake**
   - Nuevos paths
   - Nuevas reglas para tablas propuestas

### Fase 3: Validación
- Probar que todo funciona
- Actualizar viewers HTML
- Validar flujo de datos

---

## 📌 Decisiones Pendientes

1. **¿Implementar la reorganización ahora?**
   - ✅ Ventaja: Mejor organización a largo plazo
   - ⚠️ Consideración: Requiere actualizar paths en scripts

2. **¿Generar las 3 tablas propuestas para Step 2?**
   - ✅ Ventaja: Facilita interpretación
   - ⚠️ Consideración: Agrega tiempo de ejecución

3. **¿Crear README_TABLES.md para cada paso?**
   - ✅ Ventaja: Documentación completa
   - ⚠️ Consideración: Mantenimiento futuro

---

**¿Quieres que proceda con la implementación de estas mejoras?**


**Pipeline:** ALS miRNA Oxidation Analysis  
**Fecha:** 2025-11-02

---

## 🎯 Visión General: Flujo del Pipeline

```
INPUT DATA
    ↓
┌─────────────────────────────────────────────────────────┐
│ STEP 1: Análisis Exploratorio                          │
│ ❓ Pregunta: ¿Cómo se ven los datos antes de filtros?   │
│ 📊 Output: 6 figuras + 6 tablas resumen                 │
└─────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────┐
│ STEP 1.5: Control de Calidad VAF                        │
│ ❓ Pregunta: ¿Qué artefactos técnicos debemos remover?   │
│ 📊 Output: 11 figuras + 7 tablas                        │
│ ⭐ Genera: ALL_MUTATIONS_VAF_FILTERED.csv (INPUT Step 2)│
└─────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────┐
│ STEP 2: Comparaciones Estadísticas (ALS vs Control)     │
│ ❓ Pregunta: ¿Hay diferencias significativas?            │
│ 📊 Output: 2 figuras + 2 tablas                         │
│ ⭐ Resultados finales para interpretación               │
└─────────────────────────────────────────────────────────┘
```

---

## 📋 Preguntas Biológicas por Paso

### 🔬 STEP 1: Análisis Exploratorio

**Objetivo:** Caracterizar el dataset inicial sin filtros

| Panel | Pregunta Biológica | Tabla que Responde | Interpretación Clave |
|-------|-------------------|-------------------|---------------------|
| **B** | ¿Cuántos SNVs G>T hay por posición? | `S1_B_gt_counts_by_position.csv` | Hotspots de mutación G>T |
| **C** | ¿Qué tipos de mutaciones G>X ocurren? | `S1_C_gx_spectrum_by_position.csv` | Espectro mutacional (G>A, G>T, G>C) |
| **D** | ¿Qué fracción de mutaciones ocurren en cada posición? | `S1_D_positional_fractions.csv` | Posiciones críticas |
| **E** | ¿Hay relación entre contenido G y mutaciones G>T? | `S1_E_gcontent_landscape.csv` | Validación mecanicista |
| **F** | ⭐ **¿Hay más G>T en seed que en non-seed?** | `S1_F_seed_vs_nonseed.csv` | **Pregunta clave:** Seed enrichment |
| **G** | ¿Qué proporción de G>X es específicamente G>T? | `S1_G_gt_specificity.csv` | Especificidad de oxidación |

**Pregunta Central del Step 1:**  
🎯 **"¿Cuáles son los patrones generales de mutación G>T antes de aplicar filtros de calidad?"**

---

### 🔍 STEP 1.5: Control de Calidad VAF

**Objetivo:** Filtrar artefactos técnicos (VAF ≥ 0.5)

| Análisis | Pregunta | Tabla que Responde | Uso |
|---------|---------|-------------------|-----|
| **Filtro VAF** | ¿Cuántos artefactos se remueven? | `S1.5_filter_report.csv` | Cuantificar pérdida de datos |
| **Por Tipo** | ¿Qué tipos de mutaciones se filtran más? | `S1.5_stats_by_type.csv` | Entender qué se pierde |
| **Por miRNA** | ¿Qué miRNAs se ven más afectados? | `S1.5_stats_by_mirna.csv` | Identificar miRNAs problemáticos |
| **Métricas** | ¿Cómo cambian las métricas después del filtro? | `S1.5_sample_metrics.csv`, `S1.5_position_metrics.csv` | Validar calidad post-filtro |
| **⭐ DATOS FILTRADOS** | **¿Cuáles son los datos limpios para Step 2?** | **`ALL_MUTATIONS_VAF_FILTERED.csv`** | **INPUT para comparaciones** |

**Pregunta Central del Step 1.5:**  
🎯 **"¿Qué datos son confiables (VAF < 0.5) para análisis downstream?"**

---

### 📊 STEP 2: Comparaciones Estadísticas

**Objetivo:** Identificar diferencias significativas entre ALS y Control

| Análisis | Pregunta | Tabla que Responde | Interpretación |
|---------|---------|-------------------|---------------|
| **Tests Estadísticos** | ⭐ **¿Hay diferencias significativas ALS vs Control?** | `S2_statistical_comparisons.csv` | `p_adjusted < 0.05`, `significant == TRUE` |
| **Tamaño de Efecto** | ¿Cuál es la magnitud de las diferencias? | `S2_effect_sizes.csv` | `cohens_d`, `effect_size_category` |
| **⭐ Significativos** | **¿Cuáles son las mutaciones más importantes?** | **`S2_significant_mutations.csv`** ⚠️ **PROPUESTA** | Ordenadas por `fold_change` |
| **⭐ Top Efectos** | **¿Cuáles son los top 50 efectos?** | **`S2_top_effect_sizes.csv`** ⚠️ **PROPUESTA** | Top por `cohens_d` |
| **⭐ Seed Significativos** | **¿Hay enrichment en seed región?** | **`S2_seed_region_significant.csv`** ⚠️ **PROPUESTA** | Significativos en pos 2-7 |

**Pregunta Central del Step 2:**  
🎯 **"¿Qué mutaciones G>T son significativamente diferentes entre ALS y Control?"**

**Pregunta Específica Clave:**  
🎯 **"¿Hay más mutaciones G>T significativas en la región seed en ALS comparado con Control?"**

---

## 📊 Inventario Completo de Tablas

### Step 1: 6 Tablas Resumen

| Tabla | Filas Típicas | Columnas Clave | Propósito |
|-------|--------------|---------------|-----------|
| `S1_B_gt_counts_by_position.csv` | 23 (posiciones) | `position`, `total_GT_count`, `n_SNVs`, `n_miRNAs` | Conteos G>T por posición |
| `S1_C_gx_spectrum_by_position.csv` | ~69 (23 pos × 3 tipos) | `position`, `mutation_type`, `n`, `percentage` | Espectro G>X completo |
| `S1_D_positional_fractions.csv` | 23 (posiciones) | `position`, `snv_count`, `fraction`, `region` | Fracciones posicionales |
| `S1_E_gcontent_landscape.csv` | 23 (posiciones) | `Position`, `total_G_copies`, `GT_counts_at_position` | Contenido G por posición |
| `S1_F_seed_vs_nonseed.csv` | 2 (regiones) | `region`, `total_snvs`, `fraction_snvs`, `fraction_counts` | Comparación seed/non-seed |
| `S1_G_gt_specificity.csv` | 2 (categorías) | `category`, `total`, `percentage` | Especificidad G>T |

### Step 1.5: 7 Tablas

| Tabla | Filas Típicas | Columnas Clave | Propósito |
|-------|--------------|---------------|-----------|
| ⭐ **`ALL_MUTATIONS_VAF_FILTERED.csv`** | ~100,000+ | `miRNA name`, `pos:mut`, `VAF`, `Sample_SNV`, ... | **Datos filtrados (INPUT Step 2)** |
| `S1.5_filter_report.csv` | 1-10 | `metric`, `before_filter`, `after_filter`, `pct_removed` | Reporte del filtro |
| `S1.5_stats_by_type.csv` | ~10-20 | `Mutation_Type`, `N_Filtered`, `Mean_VAF` | Estadísticas por tipo |
| `S1.5_stats_by_mirna.csv` | ~1,000+ | `miRNA`, `N_Filtered`, `Mean_VAF` | Estadísticas por miRNA |
| `S1.5_sample_metrics.csv` | ~800+ | `Sample`, `Mutation_Type`, `N_SNVs`, `Total_Counts` | Métricas por muestra |
| `S1.5_position_metrics.csv` | ~230+ | `Position`, `Mutation_Type`, `N_SNVs`, `Total_Counts` | Métricas por posición |
| `S1.5_mutation_type_summary.csv` | ~10-20 | `Mutation_Type`, `Mean_SNVs`, `Mean_Counts` | Resumen por tipo |

### Step 2: 2 Tablas Actuales + 3 Propuestas

| Tabla | Filas Típicas | Columnas Clave | Propósito |
|-------|--------------|---------------|-----------|
| `S2_statistical_comparisons.csv` | ~5,000+ | `SNV_id`, `ALS_mean`, `Control_mean`, `fold_change`, `p_adjusted`, `significant` | **Resultados completos** |
| `S2_effect_sizes.csv` | ~5,000+ | `miRNA_name`, `pos.mut`, `cohens_d`, `effect_size_category` | Tamaños de efecto |
| ⚠️ **`S2_significant_mutations.csv`** | ~50-500 | `SNV_id`, `fold_change`, `p_adjusted`, `effect_size` | **PROPUESTA:** Solo significativos |
| ⚠️ **`S2_top_effect_sizes.csv`** | 50 | `SNV_id`, `cohens_d`, `fold_change` | **PROPUESTA:** Top 50 efectos |
| ⚠️ **`S2_seed_region_significant.csv`** | ~10-100 | `SNV_id`, `position`, `fold_change`, `effect_size` | **PROPUESTA:** Significativos en seed |

---

## 🔄 Flujo de Datos Entre Pasos

```
┌─────────────────────────────────────────────────────────────┐
│ INPUT FILES                                                  │
├─────────────────────────────────────────────────────────────┤
│ • final_processed_data_CLEAN.csv  → Step 1                  │
│ • step1_original_data.csv        → Step 1.5                 │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ STEP 1: Exploratory Analysis                                │
├─────────────────────────────────────────────────────────────┤
│ Input:  final_processed_data_CLEAN.csv                     │
│ Output: 6 summary tables (NO datos intermedios)             │
│         • Solo resúmenes estadísticos                       │
│         • No se usan directamente en Step 2                 │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ STEP 1.5: VAF Quality Control                               │
├─────────────────────────────────────────────────────────────┤
│ Input:  step1_original_data.csv (necesita SNV + total)     │
│ Output: ALL_MUTATIONS_VAF_FILTERED.csv ⭐                   │
│         (Este es el INPUT para Step 2)                      │
│         + 6 tablas de reporte y métricas                    │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ STEP 2: Statistical Comparisons                            │
├─────────────────────────────────────────────────────────────┤
│ Input:  ALL_MUTATIONS_VAF_FILTERED.csv (de Step 1.5)       │
│ Output: S2_statistical_comparisons.csv ⭐                   │
│         S2_effect_sizes.csv                                 │
│         + 3 tablas propuestas (significativos, top, seed)   │
└─────────────────────────────────────────────────────────────┘
```

---

## 🗂️ Problemas Actuales en la Organización

### ❌ Problemas Identificados

1. **Nomenclatura Inconsistente**
   - `TABLE_1.B_...` vs `step2_...`
   - Difícil ordenar y encontrar tablas

2. **No Está Claro el Flujo de Datos**
   - ¿Cuál tabla de Step 1.5 usar en Step 2?
   - Datos filtrados mezclados con reportes

3. **Falta Información Interpretativa**
   - No hay tabla de "mutaciones significativas" resumida
   - No hay tabla de "top efectos"
   - No hay tabla específica para seed region

4. **Subdirectorios No Organizados**
   - Todas las tablas en un solo `tables/`
   - Difícil distinguir entre datos intermedios y resultados finales

5. **Falta Documentación**
   - No hay README explicando qué es cada tabla
   - No está claro qué columnas tiene cada tabla

---

## ✅ Solución Propuesta: Organización Mejorada

### Estructura Propuesta

```
outputs/
│
├── step1_exploratory/
│   ├── figures/         # 6 figuras
│   ├── tables/
│   │   └── summary/      # 6 tablas resumen (S1_ prefix)
│   ├── viewer/
│   └── logs/
│
├── step1_5_vaf_qc/
│   ├── figures/
│   │   ├── qc/          # 4 figuras QC
│   │   └── diagnostic/  # 7 figuras diagnósticas
│   ├── tables/
│   │   ├── filtered_data/     ⭐ INPUT para Step 2
│   │   ├── filter_report/     # 3 tablas de reporte
│   │   └── summary/           # 3 tablas de métricas
│   ├── viewer/
│   └── logs/
│
└── step2_comparisons/
    ├── figures/         # 2 figuras
    ├── tables/
    │   ├── statistical_results/  # 2 tablas completas
    │   └── summary/              # 3 tablas interpretativas ⭐ PROPUESTAS
    ├── viewer/
    └── logs/
```

### Ventajas

1. ✅ **Prefijos consistentes:** `S1_`, `S1.5_`, `S2_`
2. ✅ **Separación clara:** `filtered_data/`, `summary/`, `statistical_results/`
3. ✅ **Marcadores visuales:** ⭐ para tablas clave
4. ✅ **Documentación:** README_TABLES.md en cada paso
5. ✅ **Tablas interpretativas:** Resúmenes fáciles de usar

---

## 📋 Tablas Propuestas para Step 2

### 1. `S2_significant_mutations.csv`

**Propósito:** Solo mutaciones con `p_adjusted < 0.05`

**Columnas:**
```csv
SNV_id,miRNA_name,position,mutation_type,ALS_mean,Control_mean,
fold_change,log2_fold_change,p_adjusted,cohens_d,effect_size_category,
is_seed_region,is_gt_mutation
```

**Uso:** Interpretación rápida de resultados

### 2. `S2_top_effect_sizes.csv`

**Propósito:** Top 50 mutaciones por `cohens_d` absoluto

**Columnas:**
```csv
rank,SNV_id,miRNA_name,position,mutation_type,cohens_d,fold_change,
p_adjusted,interpretation
```

**Uso:** Identificar las mutaciones con mayor impacto

### 3. `S2_seed_region_significant.csv`

**Propósito:** Solo mutaciones significativas en seed (pos 2-7)

**Columnas:**
```csv
SNV_id,miRNA_name,position,mutation_type,ALS_mean,Control_mean,
fold_change,p_adjusted,cohens_d,is_gt_mutation
```

**Uso:** Responder pregunta clave sobre enrichment en seed

---

## 🎯 Matriz de Preguntas vs Respuestas

| Pregunta Biológica | Paso | Tabla(s) | Métrica Clave | Interpretación |
|-------------------|------|----------|---------------|---------------|
| **¿Hay más G>T en seed que en non-seed?** | Step 1 | `S1_F_seed_vs_nonseed.csv` | `fraction_snvs` (seed vs non-seed) | Si `fraction_snvs` en seed > non-seed → enrichment |
| **¿Qué posiciones tienen más mutaciones G>T?** | Step 1 | `S1_B_gt_counts_by_position.csv` | `total_GT_count`, `n_SNVs` | Identificar hotspots (pos 6, 7 típicamente altos) |
| **¿Cuántos artefactos técnicos se remueven?** | Step 1.5 | `S1.5_filter_report.csv` | `pct_removed` | Si > 20% removido → muchos artefactos |
| **¿Hay diferencias significativas ALS vs Control?** | Step 2 | `S2_statistical_comparisons.csv` | `p_adjusted < 0.05` | Número de `significant == TRUE` |
| **⭐ ¿Qué mutaciones son las más importantes?** | Step 2 | `S2_significant_mutations.csv` ⚠️ | `fold_change`, `effect_size` | Ordenadas por importancia |
| **⭐ ¿Hay enrichment en seed región en ALS?** | Step 2 | `S2_seed_region_significant.csv` ⚠️ | `position` en 2-7, `significant == TRUE` | Contar significativos en seed vs otros |

---

## 🚀 Plan de Acción

### Fase 1: Documentación (✅ COMPLETADA)
- ✅ Análisis de pasos y preguntas
- ✅ Propuesta de organización
- ✅ Identificación de tablas faltantes

### Fase 2: Implementación (Pendiente)

1. **Reorganizar estructura de outputs**
   - Crear nuevos subdirectorios
   - Mover tablas existentes
   - Actualizar paths en Snakemake

2. **Generar tablas faltantes en Step 2**
   - Script para `S2_significant_mutations.csv`
   - Script para `S2_top_effect_sizes.csv`
   - Script para `S2_seed_region_significant.csv`

3. **Crear README_TABLES.md** para cada paso
   - Documentar columnas
   - Explicar propósito
   - Mapear preguntas → tablas

4. **Actualizar reglas Snakemake**
   - Nuevos paths
   - Nuevas reglas para tablas propuestas

### Fase 3: Validación
- Probar que todo funciona
- Actualizar viewers HTML
- Validar flujo de datos

---

## 📌 Decisiones Pendientes

1. **¿Implementar la reorganización ahora?**
   - ✅ Ventaja: Mejor organización a largo plazo
   - ⚠️ Consideración: Requiere actualizar paths en scripts

2. **¿Generar las 3 tablas propuestas para Step 2?**
   - ✅ Ventaja: Facilita interpretación
   - ⚠️ Consideración: Agrega tiempo de ejecución

3. **¿Crear README_TABLES.md para cada paso?**
   - ✅ Ventaja: Documentación completa
   - ⚠️ Consideración: Mantenimiento futuro

---

**¿Quieres que proceda con la implementación de estas mejoras?**


**Pipeline:** ALS miRNA Oxidation Analysis  
**Fecha:** 2025-11-02

---

## 🎯 Visión General: Flujo del Pipeline

```
INPUT DATA
    ↓
┌─────────────────────────────────────────────────────────┐
│ STEP 1: Análisis Exploratorio                          │
│ ❓ Pregunta: ¿Cómo se ven los datos antes de filtros?   │
│ 📊 Output: 6 figuras + 6 tablas resumen                 │
└─────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────┐
│ STEP 1.5: Control de Calidad VAF                        │
│ ❓ Pregunta: ¿Qué artefactos técnicos debemos remover?   │
│ 📊 Output: 11 figuras + 7 tablas                        │
│ ⭐ Genera: ALL_MUTATIONS_VAF_FILTERED.csv (INPUT Step 2)│
└─────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────┐
│ STEP 2: Comparaciones Estadísticas (ALS vs Control)     │
│ ❓ Pregunta: ¿Hay diferencias significativas?            │
│ 📊 Output: 2 figuras + 2 tablas                         │
│ ⭐ Resultados finales para interpretación               │
└─────────────────────────────────────────────────────────┘
```

---

## 📋 Preguntas Biológicas por Paso

### 🔬 STEP 1: Análisis Exploratorio

**Objetivo:** Caracterizar el dataset inicial sin filtros

| Panel | Pregunta Biológica | Tabla que Responde | Interpretación Clave |
|-------|-------------------|-------------------|---------------------|
| **B** | ¿Cuántos SNVs G>T hay por posición? | `S1_B_gt_counts_by_position.csv` | Hotspots de mutación G>T |
| **C** | ¿Qué tipos de mutaciones G>X ocurren? | `S1_C_gx_spectrum_by_position.csv` | Espectro mutacional (G>A, G>T, G>C) |
| **D** | ¿Qué fracción de mutaciones ocurren en cada posición? | `S1_D_positional_fractions.csv` | Posiciones críticas |
| **E** | ¿Hay relación entre contenido G y mutaciones G>T? | `S1_E_gcontent_landscape.csv` | Validación mecanicista |
| **F** | ⭐ **¿Hay más G>T en seed que en non-seed?** | `S1_F_seed_vs_nonseed.csv` | **Pregunta clave:** Seed enrichment |
| **G** | ¿Qué proporción de G>X es específicamente G>T? | `S1_G_gt_specificity.csv` | Especificidad de oxidación |

**Pregunta Central del Step 1:**  
🎯 **"¿Cuáles son los patrones generales de mutación G>T antes de aplicar filtros de calidad?"**

---

### 🔍 STEP 1.5: Control de Calidad VAF

**Objetivo:** Filtrar artefactos técnicos (VAF ≥ 0.5)

| Análisis | Pregunta | Tabla que Responde | Uso |
|---------|---------|-------------------|-----|
| **Filtro VAF** | ¿Cuántos artefactos se remueven? | `S1.5_filter_report.csv` | Cuantificar pérdida de datos |
| **Por Tipo** | ¿Qué tipos de mutaciones se filtran más? | `S1.5_stats_by_type.csv` | Entender qué se pierde |
| **Por miRNA** | ¿Qué miRNAs se ven más afectados? | `S1.5_stats_by_mirna.csv` | Identificar miRNAs problemáticos |
| **Métricas** | ¿Cómo cambian las métricas después del filtro? | `S1.5_sample_metrics.csv`, `S1.5_position_metrics.csv` | Validar calidad post-filtro |
| **⭐ DATOS FILTRADOS** | **¿Cuáles son los datos limpios para Step 2?** | **`ALL_MUTATIONS_VAF_FILTERED.csv`** | **INPUT para comparaciones** |

**Pregunta Central del Step 1.5:**  
🎯 **"¿Qué datos son confiables (VAF < 0.5) para análisis downstream?"**

---

### 📊 STEP 2: Comparaciones Estadísticas

**Objetivo:** Identificar diferencias significativas entre ALS y Control

| Análisis | Pregunta | Tabla que Responde | Interpretación |
|---------|---------|-------------------|---------------|
| **Tests Estadísticos** | ⭐ **¿Hay diferencias significativas ALS vs Control?** | `S2_statistical_comparisons.csv` | `p_adjusted < 0.05`, `significant == TRUE` |
| **Tamaño de Efecto** | ¿Cuál es la magnitud de las diferencias? | `S2_effect_sizes.csv` | `cohens_d`, `effect_size_category` |
| **⭐ Significativos** | **¿Cuáles son las mutaciones más importantes?** | **`S2_significant_mutations.csv`** ⚠️ **PROPUESTA** | Ordenadas por `fold_change` |
| **⭐ Top Efectos** | **¿Cuáles son los top 50 efectos?** | **`S2_top_effect_sizes.csv`** ⚠️ **PROPUESTA** | Top por `cohens_d` |
| **⭐ Seed Significativos** | **¿Hay enrichment en seed región?** | **`S2_seed_region_significant.csv`** ⚠️ **PROPUESTA** | Significativos en pos 2-7 |

**Pregunta Central del Step 2:**  
🎯 **"¿Qué mutaciones G>T son significativamente diferentes entre ALS y Control?"**

**Pregunta Específica Clave:**  
🎯 **"¿Hay más mutaciones G>T significativas en la región seed en ALS comparado con Control?"**

---

## 📊 Inventario Completo de Tablas

### Step 1: 6 Tablas Resumen

| Tabla | Filas Típicas | Columnas Clave | Propósito |
|-------|--------------|---------------|-----------|
| `S1_B_gt_counts_by_position.csv` | 23 (posiciones) | `position`, `total_GT_count`, `n_SNVs`, `n_miRNAs` | Conteos G>T por posición |
| `S1_C_gx_spectrum_by_position.csv` | ~69 (23 pos × 3 tipos) | `position`, `mutation_type`, `n`, `percentage` | Espectro G>X completo |
| `S1_D_positional_fractions.csv` | 23 (posiciones) | `position`, `snv_count`, `fraction`, `region` | Fracciones posicionales |
| `S1_E_gcontent_landscape.csv` | 23 (posiciones) | `Position`, `total_G_copies`, `GT_counts_at_position` | Contenido G por posición |
| `S1_F_seed_vs_nonseed.csv` | 2 (regiones) | `region`, `total_snvs`, `fraction_snvs`, `fraction_counts` | Comparación seed/non-seed |
| `S1_G_gt_specificity.csv` | 2 (categorías) | `category`, `total`, `percentage` | Especificidad G>T |

### Step 1.5: 7 Tablas

| Tabla | Filas Típicas | Columnas Clave | Propósito |
|-------|--------------|---------------|-----------|
| ⭐ **`ALL_MUTATIONS_VAF_FILTERED.csv`** | ~100,000+ | `miRNA name`, `pos:mut`, `VAF`, `Sample_SNV`, ... | **Datos filtrados (INPUT Step 2)** |
| `S1.5_filter_report.csv` | 1-10 | `metric`, `before_filter`, `after_filter`, `pct_removed` | Reporte del filtro |
| `S1.5_stats_by_type.csv` | ~10-20 | `Mutation_Type`, `N_Filtered`, `Mean_VAF` | Estadísticas por tipo |
| `S1.5_stats_by_mirna.csv` | ~1,000+ | `miRNA`, `N_Filtered`, `Mean_VAF` | Estadísticas por miRNA |
| `S1.5_sample_metrics.csv` | ~800+ | `Sample`, `Mutation_Type`, `N_SNVs`, `Total_Counts` | Métricas por muestra |
| `S1.5_position_metrics.csv` | ~230+ | `Position`, `Mutation_Type`, `N_SNVs`, `Total_Counts` | Métricas por posición |
| `S1.5_mutation_type_summary.csv` | ~10-20 | `Mutation_Type`, `Mean_SNVs`, `Mean_Counts` | Resumen por tipo |

### Step 2: 2 Tablas Actuales + 3 Propuestas

| Tabla | Filas Típicas | Columnas Clave | Propósito |
|-------|--------------|---------------|-----------|
| `S2_statistical_comparisons.csv` | ~5,000+ | `SNV_id`, `ALS_mean`, `Control_mean`, `fold_change`, `p_adjusted`, `significant` | **Resultados completos** |
| `S2_effect_sizes.csv` | ~5,000+ | `miRNA_name`, `pos.mut`, `cohens_d`, `effect_size_category` | Tamaños de efecto |
| ⚠️ **`S2_significant_mutations.csv`** | ~50-500 | `SNV_id`, `fold_change`, `p_adjusted`, `effect_size` | **PROPUESTA:** Solo significativos |
| ⚠️ **`S2_top_effect_sizes.csv`** | 50 | `SNV_id`, `cohens_d`, `fold_change` | **PROPUESTA:** Top 50 efectos |
| ⚠️ **`S2_seed_region_significant.csv`** | ~10-100 | `SNV_id`, `position`, `fold_change`, `effect_size` | **PROPUESTA:** Significativos en seed |

---

## 🔄 Flujo de Datos Entre Pasos

```
┌─────────────────────────────────────────────────────────────┐
│ INPUT FILES                                                  │
├─────────────────────────────────────────────────────────────┤
│ • final_processed_data_CLEAN.csv  → Step 1                  │
│ • step1_original_data.csv        → Step 1.5                 │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ STEP 1: Exploratory Analysis                                │
├─────────────────────────────────────────────────────────────┤
│ Input:  final_processed_data_CLEAN.csv                     │
│ Output: 6 summary tables (NO datos intermedios)             │
│         • Solo resúmenes estadísticos                       │
│         • No se usan directamente en Step 2                 │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ STEP 1.5: VAF Quality Control                               │
├─────────────────────────────────────────────────────────────┤
│ Input:  step1_original_data.csv (necesita SNV + total)     │
│ Output: ALL_MUTATIONS_VAF_FILTERED.csv ⭐                   │
│         (Este es el INPUT para Step 2)                      │
│         + 6 tablas de reporte y métricas                    │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ STEP 2: Statistical Comparisons                            │
├─────────────────────────────────────────────────────────────┤
│ Input:  ALL_MUTATIONS_VAF_FILTERED.csv (de Step 1.5)       │
│ Output: S2_statistical_comparisons.csv ⭐                   │
│         S2_effect_sizes.csv                                 │
│         + 3 tablas propuestas (significativos, top, seed)   │
└─────────────────────────────────────────────────────────────┘
```

---

## 🗂️ Problemas Actuales en la Organización

### ❌ Problemas Identificados

1. **Nomenclatura Inconsistente**
   - `TABLE_1.B_...` vs `step2_...`
   - Difícil ordenar y encontrar tablas

2. **No Está Claro el Flujo de Datos**
   - ¿Cuál tabla de Step 1.5 usar en Step 2?
   - Datos filtrados mezclados con reportes

3. **Falta Información Interpretativa**
   - No hay tabla de "mutaciones significativas" resumida
   - No hay tabla de "top efectos"
   - No hay tabla específica para seed region

4. **Subdirectorios No Organizados**
   - Todas las tablas en un solo `tables/`
   - Difícil distinguir entre datos intermedios y resultados finales

5. **Falta Documentación**
   - No hay README explicando qué es cada tabla
   - No está claro qué columnas tiene cada tabla

---

## ✅ Solución Propuesta: Organización Mejorada

### Estructura Propuesta

```
outputs/
│
├── step1_exploratory/
│   ├── figures/         # 6 figuras
│   ├── tables/
│   │   └── summary/      # 6 tablas resumen (S1_ prefix)
│   ├── viewer/
│   └── logs/
│
├── step1_5_vaf_qc/
│   ├── figures/
│   │   ├── qc/          # 4 figuras QC
│   │   └── diagnostic/  # 7 figuras diagnósticas
│   ├── tables/
│   │   ├── filtered_data/     ⭐ INPUT para Step 2
│   │   ├── filter_report/     # 3 tablas de reporte
│   │   └── summary/           # 3 tablas de métricas
│   ├── viewer/
│   └── logs/
│
└── step2_comparisons/
    ├── figures/         # 2 figuras
    ├── tables/
    │   ├── statistical_results/  # 2 tablas completas
    │   └── summary/              # 3 tablas interpretativas ⭐ PROPUESTAS
    ├── viewer/
    └── logs/
```

### Ventajas

1. ✅ **Prefijos consistentes:** `S1_`, `S1.5_`, `S2_`
2. ✅ **Separación clara:** `filtered_data/`, `summary/`, `statistical_results/`
3. ✅ **Marcadores visuales:** ⭐ para tablas clave
4. ✅ **Documentación:** README_TABLES.md en cada paso
5. ✅ **Tablas interpretativas:** Resúmenes fáciles de usar

---

## 📋 Tablas Propuestas para Step 2

### 1. `S2_significant_mutations.csv`

**Propósito:** Solo mutaciones con `p_adjusted < 0.05`

**Columnas:**
```csv
SNV_id,miRNA_name,position,mutation_type,ALS_mean,Control_mean,
fold_change,log2_fold_change,p_adjusted,cohens_d,effect_size_category,
is_seed_region,is_gt_mutation
```

**Uso:** Interpretación rápida de resultados

### 2. `S2_top_effect_sizes.csv`

**Propósito:** Top 50 mutaciones por `cohens_d` absoluto

**Columnas:**
```csv
rank,SNV_id,miRNA_name,position,mutation_type,cohens_d,fold_change,
p_adjusted,interpretation
```

**Uso:** Identificar las mutaciones con mayor impacto

### 3. `S2_seed_region_significant.csv`

**Propósito:** Solo mutaciones significativas en seed (pos 2-7)

**Columnas:**
```csv
SNV_id,miRNA_name,position,mutation_type,ALS_mean,Control_mean,
fold_change,p_adjusted,cohens_d,is_gt_mutation
```

**Uso:** Responder pregunta clave sobre enrichment en seed

---

## 🎯 Matriz de Preguntas vs Respuestas

| Pregunta Biológica | Paso | Tabla(s) | Métrica Clave | Interpretación |
|-------------------|------|----------|---------------|---------------|
| **¿Hay más G>T en seed que en non-seed?** | Step 1 | `S1_F_seed_vs_nonseed.csv` | `fraction_snvs` (seed vs non-seed) | Si `fraction_snvs` en seed > non-seed → enrichment |
| **¿Qué posiciones tienen más mutaciones G>T?** | Step 1 | `S1_B_gt_counts_by_position.csv` | `total_GT_count`, `n_SNVs` | Identificar hotspots (pos 6, 7 típicamente altos) |
| **¿Cuántos artefactos técnicos se remueven?** | Step 1.5 | `S1.5_filter_report.csv` | `pct_removed` | Si > 20% removido → muchos artefactos |
| **¿Hay diferencias significativas ALS vs Control?** | Step 2 | `S2_statistical_comparisons.csv` | `p_adjusted < 0.05` | Número de `significant == TRUE` |
| **⭐ ¿Qué mutaciones son las más importantes?** | Step 2 | `S2_significant_mutations.csv` ⚠️ | `fold_change`, `effect_size` | Ordenadas por importancia |
| **⭐ ¿Hay enrichment en seed región en ALS?** | Step 2 | `S2_seed_region_significant.csv` ⚠️ | `position` en 2-7, `significant == TRUE` | Contar significativos en seed vs otros |

---

## 🚀 Plan de Acción

### Fase 1: Documentación (✅ COMPLETADA)
- ✅ Análisis de pasos y preguntas
- ✅ Propuesta de organización
- ✅ Identificación de tablas faltantes

### Fase 2: Implementación (Pendiente)

1. **Reorganizar estructura de outputs**
   - Crear nuevos subdirectorios
   - Mover tablas existentes
   - Actualizar paths en Snakemake

2. **Generar tablas faltantes en Step 2**
   - Script para `S2_significant_mutations.csv`
   - Script para `S2_top_effect_sizes.csv`
   - Script para `S2_seed_region_significant.csv`

3. **Crear README_TABLES.md** para cada paso
   - Documentar columnas
   - Explicar propósito
   - Mapear preguntas → tablas

4. **Actualizar reglas Snakemake**
   - Nuevos paths
   - Nuevas reglas para tablas propuestas

### Fase 3: Validación
- Probar que todo funciona
- Actualizar viewers HTML
- Validar flujo de datos

---

## 📌 Decisiones Pendientes

1. **¿Implementar la reorganización ahora?**
   - ✅ Ventaja: Mejor organización a largo plazo
   - ⚠️ Consideración: Requiere actualizar paths en scripts

2. **¿Generar las 3 tablas propuestas para Step 2?**
   - ✅ Ventaja: Facilita interpretación
   - ⚠️ Consideración: Agrega tiempo de ejecución

3. **¿Crear README_TABLES.md para cada paso?**
   - ✅ Ventaja: Documentación completa
   - ⚠️ Consideración: Mantenimiento futuro

---

**¿Quieres que proceda con la implementación de estas mejoras?**

