# 🧪 Guía de Pruebas Simplificada - Phase 1

**Fecha:** 2025-01-21  
**Para:** Pruebas del usuario

---

## ✅ Estado Pre-Testing

**Validación completada:**
- ✅ Scripts nuevos existen y están correctos
- ✅ Config.yaml tiene las nuevas secciones
- ✅ Datos disponibles (168 MB de datos VAF-filtered)
- ✅ Snakemake puede resolver dependencias
- ⚠️ **Necesitas activar conda environment** para ejecutar

---

## 🚀 Pasos para Probar

### 1. Activar Ambiente Conda

```bash
cd /Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/pipeline_definitivo/snakemake_pipeline

# Activar ambiente
conda activate mirna_oxidation_pipeline
# O si usas mamba:
# mamba activate mirna_oxidation_pipeline
```

### 2. Verificar Ambiente

```bash
# Verificar que R packages están disponibles
Rscript -e "library(tidyverse); library(ggplot2); cat('✅ Packages OK\n')"
```

**Si da error:** El ambiente no está correctamente configurado. Revisa `environment.yml`.

### 3. Ejecutar Pruebas (en orden)

#### Prueba 1: Batch Effect Analysis (5-10 min)

```bash
snakemake -j 1 step2_batch_effect_analysis
```

**Verificar outputs:**
```bash
# Ver reporte
cat results/step2/final/logs/batch_effect_report.txt

# Verificar que se generó el PCA plot
ls -lh results/step2/final/figures/step2_batch_effect_pca_before.png

# Verificar datos corregidos
ls -lh results/step2/final/tables/statistical_results/S2_batch_corrected_data.csv
```

**✅ Éxito si:**
- Reporte se generó sin errores
- PCA plot existe
- Datos corregidos tienen la misma estructura que los datos originales

---

#### Prueba 2: Confounder Analysis (5-10 min)

```bash
snakemake -j 1 step2_confounder_analysis
```

**Verificar outputs:**
```bash
# Ver reporte
cat results/step2/final/logs/confounder_analysis_report.txt

# Verificar balance plot
ls -lh results/step2/final/figures/step2_group_balance.png

# Verificar tabla de balance
ls -lh results/step2/final/tables/statistical_results/S2_group_balance.json
```

**✅ Éxito si:**
- Reporte se generó (puede decir "no metadata available" - esto es OK)
- Balance plot existe (o reporte explica por qué no se generó)
- Tabla de balance existe

**⚠️ Nota:** Si no hay metadata con age/sex, el reporte dirá "No metadata available" pero el pipeline seguirá funcionando.

---

#### Prueba 3: Statistical Comparisons con Assumptions (10-15 min)

```bash
snakemake -j 1 step2_statistical_comparisons
```

**Verificar outputs:**
```bash
# Ver reporte de assumptions
cat results/step2/final/logs/statistical_assumptions_report.txt

# Verificar tabla de resultados
head -20 results/step2/final/tables/statistical_results/S2_statistical_comparisons.csv

# Verificar que tiene las columnas correctas
head -1 results/step2/final/tables/statistical_results/S2_statistical_comparisons.csv | tr ',' '\n' | grep -E "pvalue|fdr|significant"
```

**✅ Éxito si:**
- Reporte de assumptions se generó
- Tabla tiene columnas: `t_test_pvalue`, `t_test_fdr`, `wilcoxon_pvalue`, `wilcoxon_fdr`, `significant`
- p-values están en rango [0, 1]

---

#### Prueba 4: Todo Step 2 Completo (15-20 min)

```bash
snakemake -j 4 all_step2
```

**Verificar todos los outputs:**
```bash
# Listar todos los archivos generados
find results/step2/final -type f | sort

# Deberías ver:
# - figures/step2_batch_effect_pca_before.png
# - figures/step2_group_balance.png
# - figures/step2_volcano_plot.png
# - tables/statistical_results/S2_batch_corrected_data.csv
# - tables/statistical_results/S2_group_balance.json
# - tables/statistical_results/S2_statistical_comparisons.csv
# - logs/batch_effect_report.txt
# - logs/confounder_analysis_report.txt
# - logs/statistical_assumptions_report.txt
```

**✅ Éxito si:**
- Todos los archivos se generaron
- No hay errores críticos en los logs
- Los reportes son legibles

---

## 🔍 Validación Rápida de Calidad

```bash
# Verificar que p-values están en rango válido
Rscript -e "
library(tidyverse);
results <- read_csv('results/step2/final/tables/statistical_results/S2_statistical_comparisons.csv');
cat('P-values válidos:', all(results\$t_test_pvalue >= 0 & results\$t_test_pvalue <= 1, na.rm=TRUE), '\n');
cat('FDR válidos:', all(results\$t_test_fdr >= 0 & results\$t_test_fdr <= 1, na.rm=TRUE), '\n');
cat('✅ Validación de calidad OK\n')
"
```

---

## 🐛 Troubleshooting

### Error: "tidyverse not available"
**Solución:** Activa el ambiente conda:
```bash
conda activate mirna_oxidation_pipeline
```

### Error: "File not found" en Step 2.1
**Solución:** Ejecuta primero Step 2.0:
```bash
snakemake -j 1 step2_batch_effect_analysis
snakemake -j 1 step2_confounder_analysis
snakemake -j 1 step2_statistical_comparisons
```

### Warning: "No batches detected"
**Esto es normal** si tus datos no tienen estructura de batches. El pipeline continuará usando datos originales.

### Warning: "No metadata available"
**Esto es normal** si no tienes archivo de metadata. El pipeline continuará pero el análisis de confounders será limitado.

---

## 📊 Qué Esperar

### Reportes Generados

1. **batch_effect_report.txt:**
   - Número de batches detectados
   - Batch effect significativo (sí/no)
   - Recomendaciones

2. **confounder_analysis_report.txt:**
   - Distribución de age/sex (si disponible)
   - Balance assessment
   - Recomendaciones

3. **statistical_assumptions_report.txt:**
   - Resultados de tests de normalidad
   - Resultados de tests de homogeneidad de varianza
   - Test recomendado (paramétrico/no-paramétrico)

### Figuras Generadas

- `step2_batch_effect_pca_before.png`: PCA plot antes de corrección de batch
- `step2_group_balance.png`: Plot de balance de grupos (si metadata disponible)
- `step2_volcano_plot.png`: Volcano plot de diferencias
- `step2_effect_size_distribution.png`: Distribución de effect sizes

---

## ✅ Checklist Final

Después de ejecutar todas las pruebas, verifica:

- [ ] Batch effect analysis completó sin errores
- [ ] Confounder analysis completó sin errores
- [ ] Statistical comparisons completó sin errores
- [ ] Todos los reportes se generaron
- [ ] Todas las figuras se generaron
- [ ] Tablas tienen estructura correcta
- [ ] p-values están en rango [0, 1]
- [ ] Logs no tienen errores críticos

---

## 📝 Reportar Resultados

Si encuentras algún problema, documenta:

1. **Comando que falló:**
   ```bash
   snakemake -j 1 step2_XXX
   ```

2. **Error completo:**
   ```bash
   # Copiar salida completa del error
   ```

3. **Logs relevantes:**
   ```bash
   cat results/step2/final/logs/XXX.log
   ```

4. **Archivos generados:**
   ```bash
   ls -lh results/step2/final/tables/statistical_results/
   ls -lh results/step2/final/figures/
   ```

---

**¡Listo para probar!** 🚀

Si algo falla, revisa los logs y compárteme el error para ayudarte a resolverlo.

