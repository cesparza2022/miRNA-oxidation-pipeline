# 📋 MENSAJE 1: Análisis y Preparación (Solo Lectura)

**Fecha:** 2025-01-30  
**Objetivo:** Mapear todas las dependencias y rutas sin modificar nada

---

## 🔍 HALLAZGOS

### **Script 1: `01_apply_vaf_filter.R`**

**Ruta de entrada (hardcodeada):**
```r
input_file <- file.path(root, "UCSD", "8OG", "final_analysis", "tercer_intento", "step_by_step_analysis", "step1_original_data.csv")
```

**Rutas de salida (relativas):**
- `../outputs/tables/ALL_MUTATIONS_VAF_FILTERED.csv`
- `../outputs/tables/vaf_filter_report.csv`
- `../outputs/tables/vaf_statistics_by_type.csv`
- `../outputs/tables/vaf_statistics_by_mirna.csv`

**Dependencias:**
- Requiere paquetes: `dplyr`, `tidyr`, `readr`
- No usa funciones comunes (independiente)

**Lógica clave:**
1. Calcula VAF = count_SNV / count_Total
2. Si VAF >= 0.5 → marca como NA/Nan
3. Genera reportes estadísticos

---

### **Script 2: `02_generate_diagnostic_figures.R`**

**Rutas de entrada (relativas):**
- `../outputs/tables/ALL_MUTATIONS_VAF_FILTERED.csv` ← **Depende de Script 1**
- `../outputs/tables/vaf_filter_report.csv` ← **Depende de Script 1**
- `../outputs/tables/vaf_statistics_by_type.csv` ← **Depende de Script 1**
- `../outputs/tables/vaf_statistics_by_mirna.csv` ← **Depende de Script 1**

**Rutas de salida:**
- **11 figuras PNG:** `../outputs/figures/*.png`
- **3 tablas CSV:** `../outputs/tables/*_vaf_filtered.csv`

**Dependencias:**
- Requiere paquetes: `ggplot2`, `dplyr`, `tidyr`, `patchwork`, `tibble`, `scales`
- Depende completamente de outputs del Script 1

**Figuras generadas:**
1. QC_FIG1_VAF_DISTRIBUTION.png
2. QC_FIG2_FILTER_IMPACT.png
3. QC_FIG3_AFFECTED_MIRNAS.png
4. QC_FIG4_BEFORE_AFTER.png
5. STEP1.5_FIG1_HEATMAP_SNVS.png
6. STEP1.5_FIG2_HEATMAP_COUNTS.png
7. STEP1.5_FIG3_G_TRANSVERSIONS_SNVS.png
8. STEP1.5_FIG4_G_TRANSVERSIONS_COUNTS.png
9. STEP1.5_FIG5_BUBBLE_PLOT.png
10. STEP1.5_FIG6_VIOLIN_DISTRIBUTIONS.png
11. STEP1.5_FIG7_FOLD_CHANGE.png

---

## 📊 MAPA DE DEPENDENCIAS

```
step1_original_data.csv (INPUT EXTERNO)
    │
    ▼
[Script 1: apply_vaf_filter]
    │
    ├─► ALL_MUTATIONS_VAF_FILTERED.csv
    ├─► vaf_filter_report.csv
    ├─► vaf_statistics_by_type.csv
    └─► vaf_statistics_by_mirna.csv
    │
    ▼ (todos los outputs son inputs del Script 2)
    │
[Script 2: generate_diagnostic_figures]
    │
    ├─► 11 figuras PNG
    └─► 3 tablas CSV adicionales
```

---

## 🔧 ADAPTACIONES NECESARIAS

### Para Script 1:
1. ✅ Cambiar ruta hardcodeada → `snakemake@input["data"]`
2. ✅ Cambiar outputs → `snakemake@output["filtered_data"]`, etc.
3. ✅ Usar parámetros de Snakemake para paths

### Para Script 2:
1. ✅ Cambiar inputs → usar outputs del Script 1 como inputs
2. ✅ Cambiar rutas de output → `snakemake@output`
3. ✅ Asegurar que Script 1 se ejecute primero

---

## 📝 NOTAS PARA CONFIG.YAML

**Agregar al config:**
```yaml
paths:
  data:
    step1_original: "/path/to/step1_original_data.csv"  # Ruta absoluta
```

**Outputs esperados:**
- `outputs/step1_5/tables/` → 7 tablas
- `outputs/step1_5/figures/` → 11 figuras
- `viewers/step1_5.html` → 1 viewer

---

## ✅ MENSAJE 1 COMPLETADO

**Resultado:** Análisis completo de dependencias y rutas  
**Próximo:** MENSAJE 2 - Adaptar scripts (sin ejecutar todavía)

