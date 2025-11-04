# 📊 Tablas Generadas en Step 1: Análisis Exploratorio

**Última actualización:** 2025-11-02  
**Ubicación:** `outputs/step1/tables/summary/`

---

## 📋 Resumen

Step 1 genera **6 tablas resumen** organizadas en el subdirectorio `summary/`. Estas tablas caracterizan el dataset inicial **antes** de aplicar filtros VAF.

**Nota:** Step 1 **NO genera datos intermedios** para uso downstream. Solo genera tablas resumen estadísticas.

---

## 📊 Tablas por Análisis

### Panel B: G>T Count by Position

**Archivo:** `S1_B_gt_counts_by_position.csv`

**Descripción:** Conteos absolutos de SNVs G>T por posición (1-23)

**Columnas:**
- `position`: Posición en miRNA (1-23)
- `total_GT_count`: Suma total de counts G>T en esa posición (across all samples)
- `n_SNVs`: Número de SNVs únicos G>T en esa posición
- `n_miRNAs`: Número de miRNAs únicos con G>T en esa posición

**Uso:**
- Identificar hotspots de mutación G>T
- Ver distribución de G>T a lo largo de posiciones
- **Pregunta que responde:** ¿Cuántos SNVs G>T hay por posición?

**Ejemplo:**
```csv
position,total_GT_count,n_SNVs,n_miRNAs
6,19.55,94,94
7,10.40,96,96
```

---

### Panel C: G>X Mutation Spectrum by Position

**Archivo:** `S1_C_gx_spectrum_by_position.csv`

**Descripción:** Espectro completo de mutaciones G>X por posición (G>A, G>T, G>C)

**Columnas:**
- `position`: Posición en miRNA (1-23)
- `mutation_type`: Tipo de mutación (G>A, G>T, G>C)
- `n`: Número de SNVs de ese tipo en esa posición
- `percentage`: Porcentaje de ese tipo respecto a todas las G>X en esa posición
- `total_gx_at_pos`: Total de mutaciones G>X en esa posición
- `position_label`: Etiqueta de posición (character)

**Uso:**
- Ver espectro mutacional completo
- Comparar proporciones de G>A vs G>T vs G>C por posición
- **Pregunta que responde:** ¿Qué tipos de mutaciones G>X ocurren?

**Ejemplo:**
```csv
position,mutation_type,n,percentage,total_gx_at_pos
1,G>A,64,64,100
1,G>C,17,17,100
1,G>T,19,19,100
```

---

### Panel D: Positional Fractions

**Archivo:** `S1_D_positional_fractions.csv`

**Descripción:** Fracciones de todas las mutaciones que ocurren en cada posición

**Columnas:**
- `position`: Posición en miRNA (1-23)
- `snv_count`: Número total de SNVs en esa posición (todos los tipos)
- `fraction`: Fracción de todos los SNVs que ocurren en esa posición
- `position_label`: Etiqueta de posición (character)
- `region`: Región (Seed o Non-Seed)

**Uso:**
- Identificar posiciones con proporciones desproporcionadamente altas
- Comparar seed vs non-seed regions
- **Pregunta que responde:** ¿Qué fracción de mutaciones ocurren en cada posición?

**Ejemplo:**
```csv
position,snv_count,fraction,position_label,region
6,2586,2.42,6,Seed
7,2113,1.97,7,Seed
```

---

### Panel E: G-Content Landscape

**Archivo:** `S1_E_gcontent_landscape.csv`

**Descripción:** Contenido de G por posición y relación con mutaciones G>T

**Columnas:**
- `Position`: Posición en miRNA (1-23)
- `total_G_copies`: Total de copias de G en esa posición (sum across all miRNAs)
- `GT_counts_at_position`: Total de counts G>T en esa posición
- `n_unique_miRNAs`: Número de miRNAs únicos con datos en esa posición
- `is_seed`: Si la posición está en seed region (TRUE/FALSE)

**Uso:**
- Validación mecanicista: ¿Hay relación entre cantidad de G y mutaciones G>T?
- Entender landscape de contenido G
- **Pregunta que responde:** ¿Hay relación entre contenido G y mutaciones G>T?

**Ejemplo:**
```csv
Position,total_G_copies,GT_counts_at_position,n_unique_miRNAs,is_seed
2,85.71,0.11,44,TRUE
6,450.22,19.55,94,TRUE
```

---

### Panel F: Seed vs Non-seed Comparison ⭐

**Archivo:** `S1_F_seed_vs_nonseed.csv`

**Descripción:** Comparación de mutaciones entre región seed (pos 2-7) y non-seed

**Columnas:**
- `region`: Región (Seed o Non-Seed)
- `total_snvs`: Total de SNVs en esa región
- `total_counts`: Total de counts en esa región
- `fraction_snvs`: Fracción de SNVs que ocurren en esa región (de todos los SNVs)
- `fraction_counts`: Fracción de counts que ocurren en esa región

**Uso:**
- **Pregunta clave:** ¿Hay más mutaciones G>T en seed vs non-seed?
- Comparar enrichment en seed region
- Validar hipótesis biológica principal

**Ejemplo:**
```csv
region,total_snvs,total_counts,fraction_snvs,fraction_counts
Seed,45000,1200000,0.42,0.38
Non-Seed,62000,1950000,0.58,0.62
```

---

### Panel G: G>T Specificity

**Archivo:** `S1_G_gt_specificity.csv`

**Descripción:** Especificidad de G>T vs otras transversiones G (G>C)

**Columnas:**
- `category`: Categoría (G>T o Other G transversions)
- `total`: Total de counts en esa categoría
- `percentage`: Porcentaje de todas las mutaciones G que son de esa categoría

**Uso:**
- Ver qué proporción de mutaciones G son específicamente G>T
- Comparar G>T vs G>C (otras transversiones)
- **Pregunta que responde:** ¿Qué proporción de G>X es específicamente G>T?

**Ejemplo:**
```csv
category,total,percentage
G>T,150000,65.5
Other G transversions,79000,34.5
```

---

## 🔗 Flujo de Datos

```
INPUT: final_processed_data_CLEAN.csv
  ↓
Step 1 Processing (6 panels)
  ↓
OUTPUT: 6 summary tables (NO datos intermedios)
  ↓
Step 1.5 (VAF filtering) - usa step1_original_data.csv (diferente input)
```

**Nota:** Las tablas de Step 1 son solo resúmenes. No se usan directamente como input para Step 2.

---

## 📌 Notas Importantes

- ⭐ = Tabla que responde pregunta biológica clave
- 🔒 = Tabla final (no se modifica después de generarse)
- 📊 = Tabla resumen (puede regenerarse con nuevos datos)
- **NO hay datos intermedios:** Step 1 solo genera resúmenes, no datos para downstream

---

## 🎯 Preguntas que Responde Step 1

| Pregunta | Tabla | Métrica Clave |
|---------|-------|---------------|
| ¿Cuántos G>T por posición? | `S1_B_gt_counts_by_position.csv` | `total_GT_count`, `n_SNVs` |
| ¿Qué tipos de mutaciones G>X? | `S1_C_gx_spectrum_by_position.csv` | `mutation_type`, `percentage` |
| ¿Qué fracción por posición? | `S1_D_positional_fractions.csv` | `fraction` |
| ¿Hay relación G-content vs mutaciones? | `S1_E_gcontent_landscape.csv` | `total_G_copies`, `GT_counts_at_position` |
| ⭐ ¿Más G>T en seed vs non-seed? | `S1_F_seed_vs_nonseed.csv` | `fraction_snvs` (Seed) |
| ¿Qué proporción de G>X es G>T? | `S1_G_gt_specificity.csv` | `percentage` (G>T) |

---

## 📈 Interpretación Típica

**Hotspots G>T:** Posiciones 6 y 7 típicamente muestran los `total_GT_count` más altos.

**Seed Enrichment:** Si `fraction_snvs` en Seed > Non-Seed, hay enrichment de mutaciones en seed region.

**G-Content Validation:** Si `total_G_copies` se correlaciona con `GT_counts_at_position`, valida relación mecanicista.


**Última actualización:** 2025-11-02  
**Ubicación:** `outputs/step1/tables/summary/`

---

## 📋 Resumen

Step 1 genera **6 tablas resumen** organizadas en el subdirectorio `summary/`. Estas tablas caracterizan el dataset inicial **antes** de aplicar filtros VAF.

**Nota:** Step 1 **NO genera datos intermedios** para uso downstream. Solo genera tablas resumen estadísticas.

---

## 📊 Tablas por Análisis

### Panel B: G>T Count by Position

**Archivo:** `S1_B_gt_counts_by_position.csv`

**Descripción:** Conteos absolutos de SNVs G>T por posición (1-23)

**Columnas:**
- `position`: Posición en miRNA (1-23)
- `total_GT_count`: Suma total de counts G>T en esa posición (across all samples)
- `n_SNVs`: Número de SNVs únicos G>T en esa posición
- `n_miRNAs`: Número de miRNAs únicos con G>T en esa posición

**Uso:**
- Identificar hotspots de mutación G>T
- Ver distribución de G>T a lo largo de posiciones
- **Pregunta que responde:** ¿Cuántos SNVs G>T hay por posición?

**Ejemplo:**
```csv
position,total_GT_count,n_SNVs,n_miRNAs
6,19.55,94,94
7,10.40,96,96
```

---

### Panel C: G>X Mutation Spectrum by Position

**Archivo:** `S1_C_gx_spectrum_by_position.csv`

**Descripción:** Espectro completo de mutaciones G>X por posición (G>A, G>T, G>C)

**Columnas:**
- `position`: Posición en miRNA (1-23)
- `mutation_type`: Tipo de mutación (G>A, G>T, G>C)
- `n`: Número de SNVs de ese tipo en esa posición
- `percentage`: Porcentaje de ese tipo respecto a todas las G>X en esa posición
- `total_gx_at_pos`: Total de mutaciones G>X en esa posición
- `position_label`: Etiqueta de posición (character)

**Uso:**
- Ver espectro mutacional completo
- Comparar proporciones de G>A vs G>T vs G>C por posición
- **Pregunta que responde:** ¿Qué tipos de mutaciones G>X ocurren?

**Ejemplo:**
```csv
position,mutation_type,n,percentage,total_gx_at_pos
1,G>A,64,64,100
1,G>C,17,17,100
1,G>T,19,19,100
```

---

### Panel D: Positional Fractions

**Archivo:** `S1_D_positional_fractions.csv`

**Descripción:** Fracciones de todas las mutaciones que ocurren en cada posición

**Columnas:**
- `position`: Posición en miRNA (1-23)
- `snv_count`: Número total de SNVs en esa posición (todos los tipos)
- `fraction`: Fracción de todos los SNVs que ocurren en esa posición
- `position_label`: Etiqueta de posición (character)
- `region`: Región (Seed o Non-Seed)

**Uso:**
- Identificar posiciones con proporciones desproporcionadamente altas
- Comparar seed vs non-seed regions
- **Pregunta que responde:** ¿Qué fracción de mutaciones ocurren en cada posición?

**Ejemplo:**
```csv
position,snv_count,fraction,position_label,region
6,2586,2.42,6,Seed
7,2113,1.97,7,Seed
```

---

### Panel E: G-Content Landscape

**Archivo:** `S1_E_gcontent_landscape.csv`

**Descripción:** Contenido de G por posición y relación con mutaciones G>T

**Columnas:**
- `Position`: Posición en miRNA (1-23)
- `total_G_copies`: Total de copias de G en esa posición (sum across all miRNAs)
- `GT_counts_at_position`: Total de counts G>T en esa posición
- `n_unique_miRNAs`: Número de miRNAs únicos con datos en esa posición
- `is_seed`: Si la posición está en seed region (TRUE/FALSE)

**Uso:**
- Validación mecanicista: ¿Hay relación entre cantidad de G y mutaciones G>T?
- Entender landscape de contenido G
- **Pregunta que responde:** ¿Hay relación entre contenido G y mutaciones G>T?

**Ejemplo:**
```csv
Position,total_G_copies,GT_counts_at_position,n_unique_miRNAs,is_seed
2,85.71,0.11,44,TRUE
6,450.22,19.55,94,TRUE
```

---

### Panel F: Seed vs Non-seed Comparison ⭐

**Archivo:** `S1_F_seed_vs_nonseed.csv`

**Descripción:** Comparación de mutaciones entre región seed (pos 2-7) y non-seed

**Columnas:**
- `region`: Región (Seed o Non-Seed)
- `total_snvs`: Total de SNVs en esa región
- `total_counts`: Total de counts en esa región
- `fraction_snvs`: Fracción de SNVs que ocurren en esa región (de todos los SNVs)
- `fraction_counts`: Fracción de counts que ocurren en esa región

**Uso:**
- **Pregunta clave:** ¿Hay más mutaciones G>T en seed vs non-seed?
- Comparar enrichment en seed region
- Validar hipótesis biológica principal

**Ejemplo:**
```csv
region,total_snvs,total_counts,fraction_snvs,fraction_counts
Seed,45000,1200000,0.42,0.38
Non-Seed,62000,1950000,0.58,0.62
```

---

### Panel G: G>T Specificity

**Archivo:** `S1_G_gt_specificity.csv`

**Descripción:** Especificidad de G>T vs otras transversiones G (G>C)

**Columnas:**
- `category`: Categoría (G>T o Other G transversions)
- `total`: Total de counts en esa categoría
- `percentage`: Porcentaje de todas las mutaciones G que son de esa categoría

**Uso:**
- Ver qué proporción de mutaciones G son específicamente G>T
- Comparar G>T vs G>C (otras transversiones)
- **Pregunta que responde:** ¿Qué proporción de G>X es específicamente G>T?

**Ejemplo:**
```csv
category,total,percentage
G>T,150000,65.5
Other G transversions,79000,34.5
```

---

## 🔗 Flujo de Datos

```
INPUT: final_processed_data_CLEAN.csv
  ↓
Step 1 Processing (6 panels)
  ↓
OUTPUT: 6 summary tables (NO datos intermedios)
  ↓
Step 1.5 (VAF filtering) - usa step1_original_data.csv (diferente input)
```

**Nota:** Las tablas de Step 1 son solo resúmenes. No se usan directamente como input para Step 2.

---

## 📌 Notas Importantes

- ⭐ = Tabla que responde pregunta biológica clave
- 🔒 = Tabla final (no se modifica después de generarse)
- 📊 = Tabla resumen (puede regenerarse con nuevos datos)
- **NO hay datos intermedios:** Step 1 solo genera resúmenes, no datos para downstream

---

## 🎯 Preguntas que Responde Step 1

| Pregunta | Tabla | Métrica Clave |
|---------|-------|---------------|
| ¿Cuántos G>T por posición? | `S1_B_gt_counts_by_position.csv` | `total_GT_count`, `n_SNVs` |
| ¿Qué tipos de mutaciones G>X? | `S1_C_gx_spectrum_by_position.csv` | `mutation_type`, `percentage` |
| ¿Qué fracción por posición? | `S1_D_positional_fractions.csv` | `fraction` |
| ¿Hay relación G-content vs mutaciones? | `S1_E_gcontent_landscape.csv` | `total_G_copies`, `GT_counts_at_position` |
| ⭐ ¿Más G>T en seed vs non-seed? | `S1_F_seed_vs_nonseed.csv` | `fraction_snvs` (Seed) |
| ¿Qué proporción de G>X es G>T? | `S1_G_gt_specificity.csv` | `percentage` (G>T) |

---

## 📈 Interpretación Típica

**Hotspots G>T:** Posiciones 6 y 7 típicamente muestran los `total_GT_count` más altos.

**Seed Enrichment:** Si `fraction_snvs` en Seed > Non-Seed, hay enrichment de mutaciones en seed region.

**G-Content Validation:** Si `total_G_copies` se correlaciona con `GT_counts_at_position`, valida relación mecanicista.


**Última actualización:** 2025-11-02  
**Ubicación:** `outputs/step1/tables/summary/`

---

## 📋 Resumen

Step 1 genera **6 tablas resumen** organizadas en el subdirectorio `summary/`. Estas tablas caracterizan el dataset inicial **antes** de aplicar filtros VAF.

**Nota:** Step 1 **NO genera datos intermedios** para uso downstream. Solo genera tablas resumen estadísticas.

---

## 📊 Tablas por Análisis

### Panel B: G>T Count by Position

**Archivo:** `S1_B_gt_counts_by_position.csv`

**Descripción:** Conteos absolutos de SNVs G>T por posición (1-23)

**Columnas:**
- `position`: Posición en miRNA (1-23)
- `total_GT_count`: Suma total de counts G>T en esa posición (across all samples)
- `n_SNVs`: Número de SNVs únicos G>T en esa posición
- `n_miRNAs`: Número de miRNAs únicos con G>T en esa posición

**Uso:**
- Identificar hotspots de mutación G>T
- Ver distribución de G>T a lo largo de posiciones
- **Pregunta que responde:** ¿Cuántos SNVs G>T hay por posición?

**Ejemplo:**
```csv
position,total_GT_count,n_SNVs,n_miRNAs
6,19.55,94,94
7,10.40,96,96
```

---

### Panel C: G>X Mutation Spectrum by Position

**Archivo:** `S1_C_gx_spectrum_by_position.csv`

**Descripción:** Espectro completo de mutaciones G>X por posición (G>A, G>T, G>C)

**Columnas:**
- `position`: Posición en miRNA (1-23)
- `mutation_type`: Tipo de mutación (G>A, G>T, G>C)
- `n`: Número de SNVs de ese tipo en esa posición
- `percentage`: Porcentaje de ese tipo respecto a todas las G>X en esa posición
- `total_gx_at_pos`: Total de mutaciones G>X en esa posición
- `position_label`: Etiqueta de posición (character)

**Uso:**
- Ver espectro mutacional completo
- Comparar proporciones de G>A vs G>T vs G>C por posición
- **Pregunta que responde:** ¿Qué tipos de mutaciones G>X ocurren?

**Ejemplo:**
```csv
position,mutation_type,n,percentage,total_gx_at_pos
1,G>A,64,64,100
1,G>C,17,17,100
1,G>T,19,19,100
```

---

### Panel D: Positional Fractions

**Archivo:** `S1_D_positional_fractions.csv`

**Descripción:** Fracciones de todas las mutaciones que ocurren en cada posición

**Columnas:**
- `position`: Posición en miRNA (1-23)
- `snv_count`: Número total de SNVs en esa posición (todos los tipos)
- `fraction`: Fracción de todos los SNVs que ocurren en esa posición
- `position_label`: Etiqueta de posición (character)
- `region`: Región (Seed o Non-Seed)

**Uso:**
- Identificar posiciones con proporciones desproporcionadamente altas
- Comparar seed vs non-seed regions
- **Pregunta que responde:** ¿Qué fracción de mutaciones ocurren en cada posición?

**Ejemplo:**
```csv
position,snv_count,fraction,position_label,region
6,2586,2.42,6,Seed
7,2113,1.97,7,Seed
```

---

### Panel E: G-Content Landscape

**Archivo:** `S1_E_gcontent_landscape.csv`

**Descripción:** Contenido de G por posición y relación con mutaciones G>T

**Columnas:**
- `Position`: Posición en miRNA (1-23)
- `total_G_copies`: Total de copias de G en esa posición (sum across all miRNAs)
- `GT_counts_at_position`: Total de counts G>T en esa posición
- `n_unique_miRNAs`: Número de miRNAs únicos con datos en esa posición
- `is_seed`: Si la posición está en seed region (TRUE/FALSE)

**Uso:**
- Validación mecanicista: ¿Hay relación entre cantidad de G y mutaciones G>T?
- Entender landscape de contenido G
- **Pregunta que responde:** ¿Hay relación entre contenido G y mutaciones G>T?

**Ejemplo:**
```csv
Position,total_G_copies,GT_counts_at_position,n_unique_miRNAs,is_seed
2,85.71,0.11,44,TRUE
6,450.22,19.55,94,TRUE
```

---

### Panel F: Seed vs Non-seed Comparison ⭐

**Archivo:** `S1_F_seed_vs_nonseed.csv`

**Descripción:** Comparación de mutaciones entre región seed (pos 2-7) y non-seed

**Columnas:**
- `region`: Región (Seed o Non-Seed)
- `total_snvs`: Total de SNVs en esa región
- `total_counts`: Total de counts en esa región
- `fraction_snvs`: Fracción de SNVs que ocurren en esa región (de todos los SNVs)
- `fraction_counts`: Fracción de counts que ocurren en esa región

**Uso:**
- **Pregunta clave:** ¿Hay más mutaciones G>T en seed vs non-seed?
- Comparar enrichment en seed region
- Validar hipótesis biológica principal

**Ejemplo:**
```csv
region,total_snvs,total_counts,fraction_snvs,fraction_counts
Seed,45000,1200000,0.42,0.38
Non-Seed,62000,1950000,0.58,0.62
```

---

### Panel G: G>T Specificity

**Archivo:** `S1_G_gt_specificity.csv`

**Descripción:** Especificidad de G>T vs otras transversiones G (G>C)

**Columnas:**
- `category`: Categoría (G>T o Other G transversions)
- `total`: Total de counts en esa categoría
- `percentage`: Porcentaje de todas las mutaciones G que son de esa categoría

**Uso:**
- Ver qué proporción de mutaciones G son específicamente G>T
- Comparar G>T vs G>C (otras transversiones)
- **Pregunta que responde:** ¿Qué proporción de G>X es específicamente G>T?

**Ejemplo:**
```csv
category,total,percentage
G>T,150000,65.5
Other G transversions,79000,34.5
```

---

## 🔗 Flujo de Datos

```
INPUT: final_processed_data_CLEAN.csv
  ↓
Step 1 Processing (6 panels)
  ↓
OUTPUT: 6 summary tables (NO datos intermedios)
  ↓
Step 1.5 (VAF filtering) - usa step1_original_data.csv (diferente input)
```

**Nota:** Las tablas de Step 1 son solo resúmenes. No se usan directamente como input para Step 2.

---

## 📌 Notas Importantes

- ⭐ = Tabla que responde pregunta biológica clave
- 🔒 = Tabla final (no se modifica después de generarse)
- 📊 = Tabla resumen (puede regenerarse con nuevos datos)
- **NO hay datos intermedios:** Step 1 solo genera resúmenes, no datos para downstream

---

## 🎯 Preguntas que Responde Step 1

| Pregunta | Tabla | Métrica Clave |
|---------|-------|---------------|
| ¿Cuántos G>T por posición? | `S1_B_gt_counts_by_position.csv` | `total_GT_count`, `n_SNVs` |
| ¿Qué tipos de mutaciones G>X? | `S1_C_gx_spectrum_by_position.csv` | `mutation_type`, `percentage` |
| ¿Qué fracción por posición? | `S1_D_positional_fractions.csv` | `fraction` |
| ¿Hay relación G-content vs mutaciones? | `S1_E_gcontent_landscape.csv` | `total_G_copies`, `GT_counts_at_position` |
| ⭐ ¿Más G>T en seed vs non-seed? | `S1_F_seed_vs_nonseed.csv` | `fraction_snvs` (Seed) |
| ¿Qué proporción de G>X es G>T? | `S1_G_gt_specificity.csv` | `percentage` (G>T) |

---

## 📈 Interpretación Típica

**Hotspots G>T:** Posiciones 6 y 7 típicamente muestran los `total_GT_count` más altos.

**Seed Enrichment:** Si `fraction_snvs` en Seed > Non-Seed, hay enrichment de mutaciones en seed region.

**G-Content Validation:** Si `total_G_copies` se correlaciona con `GT_counts_at_position`, valida relación mecanicista.

