# ⚙️ UMBRALES CONFIGURABLES DEL PIPELINE

**Versión:** 1.0  
**Fecha:** 2025-11-03  
**Propósito:** Documentar todos los umbrales configurables para que el pipeline funcione con diferentes datasets

---

## 📋 RESUMEN DE UMBRALES

Todos los umbrales están definidos en `config/config.yaml` y **NO deben estar hardcodeados** en los scripts.

---

## 🔧 UMBRALES PRINCIPALES

### **1. VAF Filtering (Step 1.5)**

**Parámetro:** `analysis.vaf_filter_threshold`

**Valor por defecto:** `0.5` (50%)

**Ubicación en config:**
```yaml
analysis:
  vaf_filter_threshold: 0.5  # Filter VAFs > 50%
```

**Uso:** Filtra mutaciones con VAF > este umbral para eliminar artefactos técnicos.

**¿Qué ajustar?**
- **Dataset con alta calidad:** Puedes bajar a `0.3` o `0.4`
- **Dataset con ruido:** Sube a `0.6` o `0.7`

---

### **2. Significance Threshold (FDR) - ALPHA**

**Parámetro:** `analysis.alpha`

**Valor por defecto:** `0.05`

**Ubicación en config:**
```yaml
analysis:
  alpha: 0.05  # Significance threshold (FDR)
```

**Uso:** Usado en:
- Step 2: Identificar mutaciones significativas (t-test, Wilcoxon)
- Step 3: Filtrar G>T mutations significativas en seed region
- Step 4: Identificar biomarkers significativos

**¿Qué ajustar?**
- **Análisis más estricto:** `0.01` o `0.001`
- **Análisis más exploratorio:** `0.1` o `0.2`

**⚠️ IMPORTANTE:** Este es el umbral más crítico para la reproducibilidad.

---

### **3. Log2 Fold Change Threshold**

**Parámetro:** `analysis.log2fc_threshold`

**Valor por defecto:** `0.0` (para Step 3), `0.58` (para Step 2)

**Ubicación en config:**
```yaml
analysis:
  log2fc_threshold: 0.0  # Step 3: solo mayor en ALS (0.0)
                          # Step 2: 0.58 = 1.5x fold change
```

**Uso:**
- **Step 2:** Filtrar mutaciones con `|log2FC| > threshold` para volcano plots
- **Step 3:** Filtrar mutaciones con `log2FC > threshold` (solo mayor en ALS)

**¿Qué ajustar?**
- **Step 3:** Mantener en `0.0` para solo mayor oxidación en ALS
- **Step 2:** 
  - `0.0` = cualquier cambio
  - `0.58` = 1.5x fold change (actual)
  - `1.0` = 2x fold change (más estricto)

---

### **4. Seed Region (miRNA)**

**Parámetros:** `analysis.seed_region.start` y `analysis.seed_region.end`

**Valores por defecto:** `start: 2`, `end: 8`

**Ubicación en config:**
```yaml
analysis:
  seed_region:
    start: 2  # Start position of seed region
    end: 8    # End position of seed region
```

**Uso:** Define qué posiciones del miRNA se consideran "seed region" para Step 3.

**¿Qué ajustar?**
- **Por defecto:** 2-8 (estándar para miRNAs)
- **Si tu dataset usa otra definición:** Ajusta según tu referencia

**⚠️ IMPORTANTE:** Este es un parámetro biológico. No cambies a menos que tengas una razón específica.

---

### **5. Pathway Enrichment Threshold**

**Parámetro:** `analysis.pathway_enrichment.padjust_threshold`

**Valor por defecto:** `0.1`

**Ubicación en config:**
```yaml
analysis:
  pathway_enrichment:
    padjust_threshold: 0.1  # p.adjust threshold for showing pathways
```

**Uso:** Filtra qué vías se muestran en los heatmaps de Step 3 (más leniente que `alpha`).

**¿Qué ajustar?**
- **Más estricto:** `0.05` (solo vías muy significativas)
- **Más exploratorio:** `0.2` o `0.3` (más vías, pero menos confianza)

---

## 📊 DÓNDE SE USAN LOS UMBRALES

### **Step 1.5: VAF Quality Control**
- ✅ `vaf_filter_threshold` - Usado en `scripts/step1_5/01_vaf_quality_control.R`

### **Step 2: Statistical Comparisons**
- ✅ `alpha` - Usado en:
  - `scripts/step2/01_statistical_comparisons.R`
  - `scripts/step2/02_volcano_plots.R`
  - `scripts/step2/04_generate_summary_tables.R`
- ✅ `log2fc_threshold` - Usado en `scripts/step2/02_volcano_plots.R`

### **Step 3: Functional Analysis**
- ✅ `alpha` - Usado en `scripts/step3/01_functional_target_analysis.R`
- ✅ `log2fc_threshold` - Usado en `scripts/step3/01_functional_target_analysis.R`
- ✅ `seed_region.start` - Usado en `scripts/step3/01_functional_target_analysis.R` y `03_complex_functional_visualization.R`
- ✅ `seed_region.end` - Usado en `scripts/step3/01_functional_target_analysis.R` y `03_complex_functional_visualization.R`
- ✅ `pathway_enrichment.padjust_threshold` - Usado en `scripts/step3/02_pathway_enrichment_analysis.R`

### **Step 4: Biomarker Analysis**
- ✅ `alpha` - Usado en `scripts/step4/01_biomarker_roc_analysis.R`

---

## ✅ VERIFICACIÓN DE HARDCODING

**Ningún script debe tener valores hardcodeados como:**
- ❌ `p.adjust < 0.05` (debe usar `alpha`)
- ❌ `log2_fold_change > 0` (debe usar `log2fc_threshold`)
- ❌ `position >= 2 & position <= 8` (debe usar `seed_region.start` y `seed_region.end`)
- ❌ `p.adjust < 0.1` (debe usar `pathway_enrichment.padjust_threshold`)

**Todos deben leer del config:**
```r
alpha <- if (!is.null(config$analysis$alpha)) config$analysis$alpha else 0.05
```

---

## 🔍 CÓMO VERIFICAR QUE FUNCIONA CON OTROS DATASETS

### **1. Verificar que los umbrales son razonables:**

```bash
# Ver el config actual
cat config/config.yaml | grep -A 20 "analysis:"
```

### **2. Ajustar según tu dataset:**

```yaml
analysis:
  alpha: 0.01  # Más estricto para dataset pequeño
  log2fc_threshold: 0.0  # Step 3: solo mayor en ALS
  vaf_filter_threshold: 0.4  # Más leniente si calidad alta
```

### **3. Ejecutar y verificar:**

```bash
snakemake -j 1 all_step3 -n  # Dry-run
snakemake -j 1 all_step3     # Ejecutar
```

### **4. Revisar logs para ver qué umbrales se usaron:**

```bash
grep "threshold\|alpha" results/step3/final/logs/*.log
```

---

## 📝 EJEMPLOS DE CONFIGURACIÓN PARA DIFERENTES ESCENARIOS

### **Dataset Pequeño (< 20 muestras):**
```yaml
analysis:
  alpha: 0.1  # Más leniente (menos poder estadístico)
  log2fc_threshold: 0.0  # Cualquier cambio
  vaf_filter_threshold: 0.6  # Más estricto (menos ruido)
```

### **Dataset Grande (> 100 muestras):**
```yaml
analysis:
  alpha: 0.01  # Más estricto (más poder estadístico)
  log2fc_threshold: 0.58  # 1.5x fold change mínimo
  vaf_filter_threshold: 0.4  # Más leniente
```

### **Dataset con Alta Calidad (validación técnica):**
```yaml
analysis:
  alpha: 0.05  # Estándar
  log2fc_threshold: 0.0  # Step 3: solo mayor en ALS
  vaf_filter_threshold: 0.3  # Más leniente (alta calidad)
```

---

## ⚠️ NOTAS IMPORTANTES

1. **No cambies `seed_region` a menos que sea necesario:** Es un parámetro biológico estándar.

2. **`alpha` vs `pathway_enrichment.padjust_threshold`:**
   - `alpha` (0.05): Para filtrar mutaciones significativas (Step 2, 3, 4)
   - `pathway_enrichment.padjust_threshold` (0.1): Para mostrar vías en heatmaps (más leniente)

3. **`log2fc_threshold` tiene dos usos:**
   - **Step 2:** `|log2FC| > threshold` (valor absoluto, ambos lados)
   - **Step 3:** `log2FC > threshold` (solo mayor en ALS)

4. **Todos los umbrales se registran en los logs:** Revisa los logs para ver qué valores se usaron.

---

## 🔄 ÚLTIMA ACTUALIZACIÓN

**Fecha:** 2025-11-03  
**Verificado:** ✅ Todos los umbrales están en config.yaml y se leen correctamente en los scripts

