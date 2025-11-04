# 📊 Tablas Generadas en Step 2: Comparaciones Estadísticas (ALS vs Control)

**Última actualización:** 2025-11-02  
**Ubicación:** `outputs/step2/tables/`

---

## 📋 Resumen

Step 2 genera **5 tablas** organizadas en 2 subdirectorios:

- `statistical_results/`: Resultados completos de tests estadísticos (2 tablas)
- `summary/`: Tablas interpretativas resumen (3 tablas) ⭐

---

## 📊 Tablas por Categoría

### 📊 statistical_results/ (Resultados Completos)

#### S2_statistical_comparisons.csv

**Descripción:** Resultados completos de todas las comparaciones estadísticas

**Tests realizados:**
- t-test (paramétrico)
- Wilcoxon rank-sum test (no paramétrico)
- FDR correction (Benjamini-Hochberg)

**Columnas:**
- `SNV_id`: ID único (formato: `miRNA_name|pos:mut`)
- `miRNA_name`: Nombre del miRNA
- `pos.mut`: Posición y mutación
- `ALS_mean`: Media en grupo ALS
- `ALS_sd`: Desviación estándar en ALS
- `ALS_n`: Número de muestras ALS
- `Control_mean`: Media en grupo Control
- `Control_sd`: Desviación estándar en Control
- `Control_n`: Número de muestras Control
- `fold_change`: Fold change (ALS / Control)
- `log2_fold_change`: Log2 fold change
- `t_test_pvalue`: p-value del t-test
- `wilcoxon_pvalue`: p-value del Wilcoxon test
- `t_test_fdr`: FDR-adjusted p-value (t-test)
- `wilcoxon_fdr`: FDR-adjusted p-value (Wilcoxon)
- `t_test_significant`: TRUE si t-test significativo (FDR < 0.05)
- `wilcoxon_significant`: TRUE si Wilcoxon significativo (FDR < 0.05)
- `significant`: TRUE si cualquiera de los tests es significativo

**Uso:**
- Análisis completo de todas las mutaciones
- Identificar mutaciones significativas (`significant == TRUE`)
- Comparar resultados de diferentes tests

**Ejemplo:**
```csv
SNV_id,miRNA_name,pos.mut,ALS_mean,Control_mean,fold_change,log2_fold_change,
t_test_pvalue,wilcoxon_pvalue,t_test_fdr,wilcoxon_fdr,t_test_significant,
wilcoxon_significant,significant
hsa-let-7a-5p|6:GT,hsa-let-7a-5p,6:GT,0.0012,0.0008,1.5,0.585,
0.023,0.015,0.045,0.032,TRUE,TRUE,TRUE
```

---

#### S2_effect_sizes.csv

**Descripción:** Tamaños de efecto calculados (Cohen's d)

**Columnas:**
- `miRNA_name`: Nombre del miRNA
- `pos.mut`: Posición y mutación
- `ALS_mean`: Media en grupo ALS
- `Control_mean`: Media en grupo Control
- `log2_fold_change`: Log2 fold change
- `cohens_d`: Cohen's d (tamaño de efecto)
- `effect_size_category`: Categoría (Negligible, Small, Medium, Large)
- `cohens_d_ci_lower`: Límite inferior del 95% CI
- `cohens_d_ci_upper`: Límite superior del 95% CI

**Interpretación de Cohen's d:**
- `|d| >= 0.8`: Large effect
- `|d| >= 0.5`: Medium effect
- `|d| >= 0.2`: Small effect
- `|d| < 0.2`: Negligible effect

**Uso:**
- Identificar mutaciones con mayor impacto biológico
- Entender magnitud de diferencias (más allá de significancia)
- Priorizar mutaciones para interpretación

---

### ⭐ summary/ (Tablas Interpretativas)

#### S2_significant_mutations.csv

**Descripción:** Solo mutaciones significativas (p_adj < 0.05), ordenadas por efecto

**Filtro:** `p_adjusted < 0.05` (o `t_test_fdr < 0.05` o `wilcoxon_fdr < 0.05`)

**Columnas:**
- `SNV_id`: ID único
- `miRNA_name`: Nombre del miRNA
- `position`: Posición numérica
- `mutation_type`: Tipo de mutación (GT, GA, etc.)
- `ALS_mean`: Media en ALS
- `Control_mean`: Media en Control
- `fold_change`: Fold change
- `log2_fold_change`: Log2 fold change
- `p_value`: p-value raw
- `p_adjusted`: p-value ajustado (FDR)
- `cohens_d`: Tamaño de efecto
- `effect_size_category`: Categoría de efecto
- `is_seed_region`: TRUE si posición 2-7
- `is_gt_mutation`: TRUE si es mutación G>T
- `significant`: TRUE (todas en esta tabla son significativas)

**Uso:**
- ⭐ **Interpretación rápida de resultados**
- Identificar mutaciones biológicamente relevantes
- Priorizar para análisis downstream

**Ordenamiento:** Por `abs(cohens_d)` o `abs(fold_change)` descendente

---

#### S2_top_effect_sizes.csv

**Descripción:** Top 50 mutaciones por tamaño de efecto (abs(Cohen's d))

**Columnas:**
- `rank`: Ranking (1-50)
- `SNV_id`: ID único
- `miRNA_name`: Nombre del miRNA
- `position`: Posición numérica
- `mutation_type`: Tipo de mutación
- `ALS_mean`: Media en ALS
- `Control_mean`: Media en Control
- `fold_change`: Fold change
- `log2_fold_change`: Log2 fold change
- `cohens_d`: Cohen's d
- `effect_size_category`: Categoría
- `p_adjusted`: p-value ajustado
- `significant`: TRUE si significativo
- `interpretation`: Interpretación textual del efecto

**Uso:**
- Identificar las mutaciones con mayor impacto
- Resumen ejecutivo para presentaciones
- Priorizar validación experimental

**Nota:** Incluye tanto significativas como no-significativas (ordenadas por efecto)

---

#### S2_seed_region_significant.csv ⭐

**Descripción:** Solo mutaciones significativas en región seed (pos 2-7)

**Filtros:**
- `position` entre 2 y 7
- `p_adjusted < 0.05`

**Columnas:**
- `SNV_id`: ID único
- `miRNA_name`: Nombre del miRNA
- `position`: Posición numérica (2-7)
- `mutation_type`: Tipo de mutación
- `ALS_mean`: Media en ALS
- `Control_mean`: Media en Control
- `fold_change`: Fold change
- `log2_fold_change`: Log2 fold change
- `p_value`: p-value raw
- `p_adjusted`: p-value ajustado
- `cohens_d`: Tamaño de efecto
- `effect_size_category`: Categoría
- `is_gt_mutation`: TRUE si es G>T

**Uso:**
- ⭐ **Pregunta clave:** ¿Hay enrichment de mutaciones significativas en seed región?
- Validar hipótesis biológica principal
- Interpretación específica de seed region

**Ordenamiento:** Por `abs(cohens_d)` o `abs(fold_change)` descendente

---

## 🔗 Flujo de Datos

```
INPUT: ALL_MUTATIONS_VAF_FILTERED.csv (de Step 1.5)
  ↓
[Separar muestras en grupos: ALS vs Control]
  ↓
[Tests estadísticos: t-test, Wilcoxon, FDR correction]
  ↓
OUTPUT: S2_statistical_comparisons.csv
  ↓
[Calcular effect sizes: Cohen's d]
  ↓
OUTPUT: S2_effect_sizes.csv
  ↓
[Generar tablas interpretativas]
  ↓
OUTPUT: S2_significant_mutations.csv
       S2_top_effect_sizes.csv
       S2_seed_region_significant.csv
```

---

## 📌 Notas Importantes

- ⭐ = Tabla interpretativa (más fácil de usar)
- 🔒 = Tabla final (resultados completos)
- 📊 = Tabla resumen (puede regenerarse)
- **Significance Threshold:** 0.05 (FDR-adjusted, configurable en `config.yaml`)
- **Effect Size Thresholds:** Cohen's d: Small ≥ 0.2, Medium ≥ 0.5, Large ≥ 0.8

---

## 🎯 Preguntas que Responde Step 2

| Pregunta | Tabla | Métrica Clave |
|---------|-------|---------------|
| ⭐ **¿Hay diferencias significativas ALS vs Control?** | `S2_statistical_comparisons.csv` | `p_adjusted < 0.05`, `significant == TRUE` |
| ¿Cuál es el tamaño del efecto? | `S2_effect_sizes.csv` | `cohens_d`, `effect_size_category` |
| ⭐ **¿Cuáles son las mutaciones más importantes?** | `S2_significant_mutations.csv` | Ordenadas por `cohens_d` o `fold_change` |
| ⭐ **¿Hay enrichment en seed región?** | `S2_seed_region_significant.csv` | Mutaciones significativas en pos 2-7 |

---

## 📈 Interpretación Típica

**Significativas:** `S2_significant_mutations.csv` lista todas las mutaciones con `p_adjusted < 0.05`.

**Top Efectos:** `S2_top_effect_sizes.csv` identifica las 50 mutaciones con mayor impacto biológico (independientemente de significancia).

**Seed Enrichment:** Si `S2_seed_region_significant.csv` tiene muchas mutaciones G>T, especialmente en posiciones 2-7, sugiere enrichment en seed región.

**Fold Change:** `log2_fold_change > 0.58` (1.5x) sugiere diferencias biológicamente relevantes además de significancia estadística.

---

## 🔍 Cómo Usar las Tablas

### Para Interpretación Rápida:
1. Lee `S2_significant_mutations.csv` - solo significativas
2. Filtra por `is_gt_mutation == TRUE` - solo G>T
3. Ordena por `abs(cohens_d)` descendente - mayores efectos

### Para Validación de Hipótesis:
1. Lee `S2_seed_region_significant.csv` - significativas en seed
2. Cuenta cuántas son G>T (`is_gt_mutation == TRUE`)
3. Compara con significativas fuera de seed

### Para Presentaciones:
1. Usa `S2_top_effect_sizes.csv` - Top 50 efectos
2. Filtra por `significant == TRUE` si solo quieres significativas
3. Muestra fold changes y effect sizes


**Última actualización:** 2025-11-02  
**Ubicación:** `outputs/step2/tables/`

---

## 📋 Resumen

Step 2 genera **5 tablas** organizadas en 2 subdirectorios:

- `statistical_results/`: Resultados completos de tests estadísticos (2 tablas)
- `summary/`: Tablas interpretativas resumen (3 tablas) ⭐

---

## 📊 Tablas por Categoría

### 📊 statistical_results/ (Resultados Completos)

#### S2_statistical_comparisons.csv

**Descripción:** Resultados completos de todas las comparaciones estadísticas

**Tests realizados:**
- t-test (paramétrico)
- Wilcoxon rank-sum test (no paramétrico)
- FDR correction (Benjamini-Hochberg)

**Columnas:**
- `SNV_id`: ID único (formato: `miRNA_name|pos:mut`)
- `miRNA_name`: Nombre del miRNA
- `pos.mut`: Posición y mutación
- `ALS_mean`: Media en grupo ALS
- `ALS_sd`: Desviación estándar en ALS
- `ALS_n`: Número de muestras ALS
- `Control_mean`: Media en grupo Control
- `Control_sd`: Desviación estándar en Control
- `Control_n`: Número de muestras Control
- `fold_change`: Fold change (ALS / Control)
- `log2_fold_change`: Log2 fold change
- `t_test_pvalue`: p-value del t-test
- `wilcoxon_pvalue`: p-value del Wilcoxon test
- `t_test_fdr`: FDR-adjusted p-value (t-test)
- `wilcoxon_fdr`: FDR-adjusted p-value (Wilcoxon)
- `t_test_significant`: TRUE si t-test significativo (FDR < 0.05)
- `wilcoxon_significant`: TRUE si Wilcoxon significativo (FDR < 0.05)
- `significant`: TRUE si cualquiera de los tests es significativo

**Uso:**
- Análisis completo de todas las mutaciones
- Identificar mutaciones significativas (`significant == TRUE`)
- Comparar resultados de diferentes tests

**Ejemplo:**
```csv
SNV_id,miRNA_name,pos.mut,ALS_mean,Control_mean,fold_change,log2_fold_change,
t_test_pvalue,wilcoxon_pvalue,t_test_fdr,wilcoxon_fdr,t_test_significant,
wilcoxon_significant,significant
hsa-let-7a-5p|6:GT,hsa-let-7a-5p,6:GT,0.0012,0.0008,1.5,0.585,
0.023,0.015,0.045,0.032,TRUE,TRUE,TRUE
```

---

#### S2_effect_sizes.csv

**Descripción:** Tamaños de efecto calculados (Cohen's d)

**Columnas:**
- `miRNA_name`: Nombre del miRNA
- `pos.mut`: Posición y mutación
- `ALS_mean`: Media en grupo ALS
- `Control_mean`: Media en grupo Control
- `log2_fold_change`: Log2 fold change
- `cohens_d`: Cohen's d (tamaño de efecto)
- `effect_size_category`: Categoría (Negligible, Small, Medium, Large)
- `cohens_d_ci_lower`: Límite inferior del 95% CI
- `cohens_d_ci_upper`: Límite superior del 95% CI

**Interpretación de Cohen's d:**
- `|d| >= 0.8`: Large effect
- `|d| >= 0.5`: Medium effect
- `|d| >= 0.2`: Small effect
- `|d| < 0.2`: Negligible effect

**Uso:**
- Identificar mutaciones con mayor impacto biológico
- Entender magnitud de diferencias (más allá de significancia)
- Priorizar mutaciones para interpretación

---

### ⭐ summary/ (Tablas Interpretativas)

#### S2_significant_mutations.csv

**Descripción:** Solo mutaciones significativas (p_adj < 0.05), ordenadas por efecto

**Filtro:** `p_adjusted < 0.05` (o `t_test_fdr < 0.05` o `wilcoxon_fdr < 0.05`)

**Columnas:**
- `SNV_id`: ID único
- `miRNA_name`: Nombre del miRNA
- `position`: Posición numérica
- `mutation_type`: Tipo de mutación (GT, GA, etc.)
- `ALS_mean`: Media en ALS
- `Control_mean`: Media en Control
- `fold_change`: Fold change
- `log2_fold_change`: Log2 fold change
- `p_value`: p-value raw
- `p_adjusted`: p-value ajustado (FDR)
- `cohens_d`: Tamaño de efecto
- `effect_size_category`: Categoría de efecto
- `is_seed_region`: TRUE si posición 2-7
- `is_gt_mutation`: TRUE si es mutación G>T
- `significant`: TRUE (todas en esta tabla son significativas)

**Uso:**
- ⭐ **Interpretación rápida de resultados**
- Identificar mutaciones biológicamente relevantes
- Priorizar para análisis downstream

**Ordenamiento:** Por `abs(cohens_d)` o `abs(fold_change)` descendente

---

#### S2_top_effect_sizes.csv

**Descripción:** Top 50 mutaciones por tamaño de efecto (abs(Cohen's d))

**Columnas:**
- `rank`: Ranking (1-50)
- `SNV_id`: ID único
- `miRNA_name`: Nombre del miRNA
- `position`: Posición numérica
- `mutation_type`: Tipo de mutación
- `ALS_mean`: Media en ALS
- `Control_mean`: Media en Control
- `fold_change`: Fold change
- `log2_fold_change`: Log2 fold change
- `cohens_d`: Cohen's d
- `effect_size_category`: Categoría
- `p_adjusted`: p-value ajustado
- `significant`: TRUE si significativo
- `interpretation`: Interpretación textual del efecto

**Uso:**
- Identificar las mutaciones con mayor impacto
- Resumen ejecutivo para presentaciones
- Priorizar validación experimental

**Nota:** Incluye tanto significativas como no-significativas (ordenadas por efecto)

---

#### S2_seed_region_significant.csv ⭐

**Descripción:** Solo mutaciones significativas en región seed (pos 2-7)

**Filtros:**
- `position` entre 2 y 7
- `p_adjusted < 0.05`

**Columnas:**
- `SNV_id`: ID único
- `miRNA_name`: Nombre del miRNA
- `position`: Posición numérica (2-7)
- `mutation_type`: Tipo de mutación
- `ALS_mean`: Media en ALS
- `Control_mean`: Media en Control
- `fold_change`: Fold change
- `log2_fold_change`: Log2 fold change
- `p_value`: p-value raw
- `p_adjusted`: p-value ajustado
- `cohens_d`: Tamaño de efecto
- `effect_size_category`: Categoría
- `is_gt_mutation`: TRUE si es G>T

**Uso:**
- ⭐ **Pregunta clave:** ¿Hay enrichment de mutaciones significativas en seed región?
- Validar hipótesis biológica principal
- Interpretación específica de seed region

**Ordenamiento:** Por `abs(cohens_d)` o `abs(fold_change)` descendente

---

## 🔗 Flujo de Datos

```
INPUT: ALL_MUTATIONS_VAF_FILTERED.csv (de Step 1.5)
  ↓
[Separar muestras en grupos: ALS vs Control]
  ↓
[Tests estadísticos: t-test, Wilcoxon, FDR correction]
  ↓
OUTPUT: S2_statistical_comparisons.csv
  ↓
[Calcular effect sizes: Cohen's d]
  ↓
OUTPUT: S2_effect_sizes.csv
  ↓
[Generar tablas interpretativas]
  ↓
OUTPUT: S2_significant_mutations.csv
       S2_top_effect_sizes.csv
       S2_seed_region_significant.csv
```

---

## 📌 Notas Importantes

- ⭐ = Tabla interpretativa (más fácil de usar)
- 🔒 = Tabla final (resultados completos)
- 📊 = Tabla resumen (puede regenerarse)
- **Significance Threshold:** 0.05 (FDR-adjusted, configurable en `config.yaml`)
- **Effect Size Thresholds:** Cohen's d: Small ≥ 0.2, Medium ≥ 0.5, Large ≥ 0.8

---

## 🎯 Preguntas que Responde Step 2

| Pregunta | Tabla | Métrica Clave |
|---------|-------|---------------|
| ⭐ **¿Hay diferencias significativas ALS vs Control?** | `S2_statistical_comparisons.csv` | `p_adjusted < 0.05`, `significant == TRUE` |
| ¿Cuál es el tamaño del efecto? | `S2_effect_sizes.csv` | `cohens_d`, `effect_size_category` |
| ⭐ **¿Cuáles son las mutaciones más importantes?** | `S2_significant_mutations.csv` | Ordenadas por `cohens_d` o `fold_change` |
| ⭐ **¿Hay enrichment en seed región?** | `S2_seed_region_significant.csv` | Mutaciones significativas en pos 2-7 |

---

## 📈 Interpretación Típica

**Significativas:** `S2_significant_mutations.csv` lista todas las mutaciones con `p_adjusted < 0.05`.

**Top Efectos:** `S2_top_effect_sizes.csv` identifica las 50 mutaciones con mayor impacto biológico (independientemente de significancia).

**Seed Enrichment:** Si `S2_seed_region_significant.csv` tiene muchas mutaciones G>T, especialmente en posiciones 2-7, sugiere enrichment en seed región.

**Fold Change:** `log2_fold_change > 0.58` (1.5x) sugiere diferencias biológicamente relevantes además de significancia estadística.

---

## 🔍 Cómo Usar las Tablas

### Para Interpretación Rápida:
1. Lee `S2_significant_mutations.csv` - solo significativas
2. Filtra por `is_gt_mutation == TRUE` - solo G>T
3. Ordena por `abs(cohens_d)` descendente - mayores efectos

### Para Validación de Hipótesis:
1. Lee `S2_seed_region_significant.csv` - significativas en seed
2. Cuenta cuántas son G>T (`is_gt_mutation == TRUE`)
3. Compara con significativas fuera de seed

### Para Presentaciones:
1. Usa `S2_top_effect_sizes.csv` - Top 50 efectos
2. Filtra por `significant == TRUE` si solo quieres significativas
3. Muestra fold changes y effect sizes


**Última actualización:** 2025-11-02  
**Ubicación:** `outputs/step2/tables/`

---

## 📋 Resumen

Step 2 genera **5 tablas** organizadas en 2 subdirectorios:

- `statistical_results/`: Resultados completos de tests estadísticos (2 tablas)
- `summary/`: Tablas interpretativas resumen (3 tablas) ⭐

---

## 📊 Tablas por Categoría

### 📊 statistical_results/ (Resultados Completos)

#### S2_statistical_comparisons.csv

**Descripción:** Resultados completos de todas las comparaciones estadísticas

**Tests realizados:**
- t-test (paramétrico)
- Wilcoxon rank-sum test (no paramétrico)
- FDR correction (Benjamini-Hochberg)

**Columnas:**
- `SNV_id`: ID único (formato: `miRNA_name|pos:mut`)
- `miRNA_name`: Nombre del miRNA
- `pos.mut`: Posición y mutación
- `ALS_mean`: Media en grupo ALS
- `ALS_sd`: Desviación estándar en ALS
- `ALS_n`: Número de muestras ALS
- `Control_mean`: Media en grupo Control
- `Control_sd`: Desviación estándar en Control
- `Control_n`: Número de muestras Control
- `fold_change`: Fold change (ALS / Control)
- `log2_fold_change`: Log2 fold change
- `t_test_pvalue`: p-value del t-test
- `wilcoxon_pvalue`: p-value del Wilcoxon test
- `t_test_fdr`: FDR-adjusted p-value (t-test)
- `wilcoxon_fdr`: FDR-adjusted p-value (Wilcoxon)
- `t_test_significant`: TRUE si t-test significativo (FDR < 0.05)
- `wilcoxon_significant`: TRUE si Wilcoxon significativo (FDR < 0.05)
- `significant`: TRUE si cualquiera de los tests es significativo

**Uso:**
- Análisis completo de todas las mutaciones
- Identificar mutaciones significativas (`significant == TRUE`)
- Comparar resultados de diferentes tests

**Ejemplo:**
```csv
SNV_id,miRNA_name,pos.mut,ALS_mean,Control_mean,fold_change,log2_fold_change,
t_test_pvalue,wilcoxon_pvalue,t_test_fdr,wilcoxon_fdr,t_test_significant,
wilcoxon_significant,significant
hsa-let-7a-5p|6:GT,hsa-let-7a-5p,6:GT,0.0012,0.0008,1.5,0.585,
0.023,0.015,0.045,0.032,TRUE,TRUE,TRUE
```

---

#### S2_effect_sizes.csv

**Descripción:** Tamaños de efecto calculados (Cohen's d)

**Columnas:**
- `miRNA_name`: Nombre del miRNA
- `pos.mut`: Posición y mutación
- `ALS_mean`: Media en grupo ALS
- `Control_mean`: Media en grupo Control
- `log2_fold_change`: Log2 fold change
- `cohens_d`: Cohen's d (tamaño de efecto)
- `effect_size_category`: Categoría (Negligible, Small, Medium, Large)
- `cohens_d_ci_lower`: Límite inferior del 95% CI
- `cohens_d_ci_upper`: Límite superior del 95% CI

**Interpretación de Cohen's d:**
- `|d| >= 0.8`: Large effect
- `|d| >= 0.5`: Medium effect
- `|d| >= 0.2`: Small effect
- `|d| < 0.2`: Negligible effect

**Uso:**
- Identificar mutaciones con mayor impacto biológico
- Entender magnitud de diferencias (más allá de significancia)
- Priorizar mutaciones para interpretación

---

### ⭐ summary/ (Tablas Interpretativas)

#### S2_significant_mutations.csv

**Descripción:** Solo mutaciones significativas (p_adj < 0.05), ordenadas por efecto

**Filtro:** `p_adjusted < 0.05` (o `t_test_fdr < 0.05` o `wilcoxon_fdr < 0.05`)

**Columnas:**
- `SNV_id`: ID único
- `miRNA_name`: Nombre del miRNA
- `position`: Posición numérica
- `mutation_type`: Tipo de mutación (GT, GA, etc.)
- `ALS_mean`: Media en ALS
- `Control_mean`: Media en Control
- `fold_change`: Fold change
- `log2_fold_change`: Log2 fold change
- `p_value`: p-value raw
- `p_adjusted`: p-value ajustado (FDR)
- `cohens_d`: Tamaño de efecto
- `effect_size_category`: Categoría de efecto
- `is_seed_region`: TRUE si posición 2-7
- `is_gt_mutation`: TRUE si es mutación G>T
- `significant`: TRUE (todas en esta tabla son significativas)

**Uso:**
- ⭐ **Interpretación rápida de resultados**
- Identificar mutaciones biológicamente relevantes
- Priorizar para análisis downstream

**Ordenamiento:** Por `abs(cohens_d)` o `abs(fold_change)` descendente

---

#### S2_top_effect_sizes.csv

**Descripción:** Top 50 mutaciones por tamaño de efecto (abs(Cohen's d))

**Columnas:**
- `rank`: Ranking (1-50)
- `SNV_id`: ID único
- `miRNA_name`: Nombre del miRNA
- `position`: Posición numérica
- `mutation_type`: Tipo de mutación
- `ALS_mean`: Media en ALS
- `Control_mean`: Media en Control
- `fold_change`: Fold change
- `log2_fold_change`: Log2 fold change
- `cohens_d`: Cohen's d
- `effect_size_category`: Categoría
- `p_adjusted`: p-value ajustado
- `significant`: TRUE si significativo
- `interpretation`: Interpretación textual del efecto

**Uso:**
- Identificar las mutaciones con mayor impacto
- Resumen ejecutivo para presentaciones
- Priorizar validación experimental

**Nota:** Incluye tanto significativas como no-significativas (ordenadas por efecto)

---

#### S2_seed_region_significant.csv ⭐

**Descripción:** Solo mutaciones significativas en región seed (pos 2-7)

**Filtros:**
- `position` entre 2 y 7
- `p_adjusted < 0.05`

**Columnas:**
- `SNV_id`: ID único
- `miRNA_name`: Nombre del miRNA
- `position`: Posición numérica (2-7)
- `mutation_type`: Tipo de mutación
- `ALS_mean`: Media en ALS
- `Control_mean`: Media en Control
- `fold_change`: Fold change
- `log2_fold_change`: Log2 fold change
- `p_value`: p-value raw
- `p_adjusted`: p-value ajustado
- `cohens_d`: Tamaño de efecto
- `effect_size_category`: Categoría
- `is_gt_mutation`: TRUE si es G>T

**Uso:**
- ⭐ **Pregunta clave:** ¿Hay enrichment de mutaciones significativas en seed región?
- Validar hipótesis biológica principal
- Interpretación específica de seed region

**Ordenamiento:** Por `abs(cohens_d)` o `abs(fold_change)` descendente

---

## 🔗 Flujo de Datos

```
INPUT: ALL_MUTATIONS_VAF_FILTERED.csv (de Step 1.5)
  ↓
[Separar muestras en grupos: ALS vs Control]
  ↓
[Tests estadísticos: t-test, Wilcoxon, FDR correction]
  ↓
OUTPUT: S2_statistical_comparisons.csv
  ↓
[Calcular effect sizes: Cohen's d]
  ↓
OUTPUT: S2_effect_sizes.csv
  ↓
[Generar tablas interpretativas]
  ↓
OUTPUT: S2_significant_mutations.csv
       S2_top_effect_sizes.csv
       S2_seed_region_significant.csv
```

---

## 📌 Notas Importantes

- ⭐ = Tabla interpretativa (más fácil de usar)
- 🔒 = Tabla final (resultados completos)
- 📊 = Tabla resumen (puede regenerarse)
- **Significance Threshold:** 0.05 (FDR-adjusted, configurable en `config.yaml`)
- **Effect Size Thresholds:** Cohen's d: Small ≥ 0.2, Medium ≥ 0.5, Large ≥ 0.8

---

## 🎯 Preguntas que Responde Step 2

| Pregunta | Tabla | Métrica Clave |
|---------|-------|---------------|
| ⭐ **¿Hay diferencias significativas ALS vs Control?** | `S2_statistical_comparisons.csv` | `p_adjusted < 0.05`, `significant == TRUE` |
| ¿Cuál es el tamaño del efecto? | `S2_effect_sizes.csv` | `cohens_d`, `effect_size_category` |
| ⭐ **¿Cuáles son las mutaciones más importantes?** | `S2_significant_mutations.csv` | Ordenadas por `cohens_d` o `fold_change` |
| ⭐ **¿Hay enrichment en seed región?** | `S2_seed_region_significant.csv` | Mutaciones significativas en pos 2-7 |

---

## 📈 Interpretación Típica

**Significativas:** `S2_significant_mutations.csv` lista todas las mutaciones con `p_adjusted < 0.05`.

**Top Efectos:** `S2_top_effect_sizes.csv` identifica las 50 mutaciones con mayor impacto biológico (independientemente de significancia).

**Seed Enrichment:** Si `S2_seed_region_significant.csv` tiene muchas mutaciones G>T, especialmente en posiciones 2-7, sugiere enrichment en seed región.

**Fold Change:** `log2_fold_change > 0.58` (1.5x) sugiere diferencias biológicamente relevantes además de significancia estadística.

---

## 🔍 Cómo Usar las Tablas

### Para Interpretación Rápida:
1. Lee `S2_significant_mutations.csv` - solo significativas
2. Filtra por `is_gt_mutation == TRUE` - solo G>T
3. Ordena por `abs(cohens_d)` descendente - mayores efectos

### Para Validación de Hipótesis:
1. Lee `S2_seed_region_significant.csv` - significativas en seed
2. Cuenta cuántas son G>T (`is_gt_mutation == TRUE`)
3. Compara con significativas fuera de seed

### Para Presentaciones:
1. Usa `S2_top_effect_sizes.csv` - Top 50 efectos
2. Filtra por `significant == TRUE` si solo quieres significativas
3. Muestra fold changes y effect sizes

