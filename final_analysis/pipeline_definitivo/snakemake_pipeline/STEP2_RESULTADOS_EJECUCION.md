# ✅ STEP 2: Resultados de Ejecución

**Fecha:** 2025-11-02 20:28  
**Status:** ✅ Ejecución exitosa

---

## 📊 RESUMEN DE RESULTADOS

### Datos Analizados

- **Total SNVs analizados:** 5,448
- **Muestras ALS:** 313
- **Muestras Control:** 102
- **Total muestras:** 415

---

## 🔍 HALLAZGOS ESTADÍSTICOS

### Significancia (FDR < 0.05)

#### Test t (Paramétrico)
- **Significativos:** 23 SNVs
- **Porcentaje:** 0.4%

#### Test de Wilcoxon (No Paramétrico)
- **Significativos:** 265 SNVs
- **Porcentaje:** 4.9%

#### Combinado (cualquier test)
- **Significativos:** 269 SNVs
- **Porcentaje:** 4.9%

### Volcano Plot (Fold Change + Significancia)

#### Upregulated (ALS > Control)
- **Con log2FC > 0.58 y FDR < 0.05:** 19 SNVs
- **Interpretación:** Mayor expresión en ALS

#### Downregulated (ALS < Control)
- **Con |log2FC| > 0.58 y FDR < 0.05:** 92 SNVs
- **Interpretación:** Mayor expresión en Control

---

## 📈 ANÁLISIS DE EFFECT SIZE

### Estadísticos de Cohen's d

- **Mean Cohen's d:** -0.012
  - Interpretación: Efecto promedio muy pequeño (negligible)
  - Dirección: Control > ALS (promedio)

- **Median Cohen's d:** 0.065
  - Interpretación: Mediana muestra efecto pequeño

### Clasificación por Tamaño de Efecto

| Categoría | Threshold | Cantidad | Porcentaje |
|-----------|-----------|----------|------------|
| **Large** | \|d\| ≥ 0.8 | 0 | 0% |
| **Medium** | 0.5 ≤ \|d\| < 0.8 | 4 | 0.07% |
| **Small** | 0.2 ≤ \|d\| < 0.5 | 919 | 16.9% |
| **Negligible** | \|d\| < 0.2 | ~4,525 | 83.1% |

---

## 🔬 TOP 10 SNVs MÁS SIGNIFICATIVOS

Basado en Wilcoxon FDR:

1. **hsa-miR-503-5p | 23:GT**
   - log2FC: -1.15 (Control > ALS)
   - FDR: 3.44e-06
   - ALS mean: 0.077
   - Control mean: 0.170

2. **hsa-miR-93-5p | 22:AT**
   - log2FC: -0.597
   - FDR: 5.54e-06

3. **hsa-miR-503-5p | 21:CA**
   - log2FC: -1.09
   - FDR: 7.96e-06

4. **hsa-miR-877-5p | 20:GT**
   - log2FC: -1.96 (mayor diferencia)
   - FDR: 8.20e-06

5. **hsa-miR-339-5p | 22:CA**
   - log2FC: -0.592
   - FDR: 3.67e-05

6-10. Ver tabla completa en `outputs/step2/tables/step2_statistical_comparisons.csv`

---

## 📁 ARCHIVOS GENERADOS

### Tablas CSV

1. **`outputs/step2/tables/step2_statistical_comparisons.csv`** (1.1 MB)
   - Comparaciones completas para todos los SNVs
   - Columnas: miRNA_name, pos.mut, ALS_mean, Control_mean, fold_change, 
     log2_fold_change, t_test_pvalue, wilcoxon_pvalue, t_test_fdr, 
     wilcoxon_fdr, significant flags

2. **`outputs/step2/tables/step2_effect_sizes.csv`** (909 KB)
   - Effect sizes (Cohen's d) para todos los SNVs
   - Incluye categorización y intervalos de confianza

### Figuras PNG

1. **`outputs/step2/figures/step2_volcano_plot.png`** (532 KB)
   - Volcano plot profesional
   - Categorización por significancia y fold change
   - Colores: Red (upregulated), Blue (downregulated), Orange (sig, low FC)

2. **`outputs/step2/figures/step2_effect_size_distribution.png`** (139 KB)
   - Histograma de distribución de Cohen's d
   - Categorización visual por tamaño de efecto

### Viewer HTML

- **`viewers/step2.html`**
  - Viewer interactivo con estadísticas resumidas
  - Visualización de volcano plot y effect size plot
  - Resumen de resultados

### Logs

- `outputs/step2/logs/statistical_comparisons.log`
- `outputs/step2/logs/volcano_plot.log`
- `outputs/step2/logs/effect_size.log`
- `outputs/step2/logs/viewer_step2.log`

---

## 💡 INTERPRETACIÓN DE RESULTADOS

### Hallazgo Principal

**Control muestra MAYOR expresión que ALS en la mayoría de SNVs significativos**

- 92 SNVs downregulated (ALS < Control)
- 19 SNVs upregulated (ALS > Control)
- Ratio: ~4.8:1 (Control > ALS)

### Posibles Explicaciones

1. **Técnicas:**
   - Diferencias en profundidad de secuenciación
   - Batch effects entre estudios
   - Protocolos diferentes de extracción/preparación

2. **Biológicas:**
   - Mayor variabilidad natural en controles
   - Filtros de calidad más estrictos en ALS
   - Normalización necesaria (library size)

3. **Estadísticas:**
   - Effect sizes pequeños (mayoría negligible)
   - Significancia estadística no implica efecto biológico grande
   - Puede requerir normalización o corrección por covariables

---

## ✅ PRÓXIMOS PASOS SUGERIDOS

1. **Normalización:**
   - Normalizar por library size
   - Corrección por batch effect
   - Usar proporciones en vez de valores absolutos

2. **Análisis Adicionales:**
   - PCA para visualizar separación de grupos
   - Clustering jerárquico
   - Análisis de enriquecimiento funcional

3. **Validación:**
   - Replicación en cohorte independiente
   - Validación experimental de top hits

---

**Pipeline Step 2 ejecutado exitosamente! 🎉**

