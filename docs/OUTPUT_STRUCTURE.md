# 📊 Estructura de Output - Guía de Usuario

**Repositorio:** https://github.com/cesparza2022/als-mirna-oxidation-pipeline

---

## 🎯 Organización Automática

El pipeline **crea automáticamente** todas las carpetas necesarias. No necesitas crear nada manualmente.

### Estructura Completa

```
results/
│
├── 📊 step1/                    # Paso 1: Análisis Exploratorio
│   ├── final/
│   │   ├── figures/            # 6 figuras PNG
│   │   │   ├── step1_panelB_gt_count_by_position.png
│   │   │   ├── step1_panelC_gx_spectrum.png
│   │   │   ├── step1_panelD_positional_fraction.png
│   │   │   ├── step1_panelE_gcontent.png
│   │   │   ├── step1_panelF_seed_interaction.png
│   │   │   └── step1_panelG_gt_specificity.png
│   │   ├── tables/
│   │   │   └── summary/        # 6 tablas CSV
│   │   │       ├── S1_B_gt_counts_by_position.csv
│   │   │       ├── S1_C_gx_spectrum_by_position.csv
│   │   │       ├── S1_D_positional_fractions.csv
│   │   │       ├── S1_E_gcontent_landscape.csv
│   │   │       ├── S1_F_seed_vs_nonseed.csv
│   │   │       └── S1_G_gt_specificity.csv
│   │   └── logs/               # Logs de ejecución
│   └── intermediate/           # Archivos intermedios (debugging)
│
├── 📊 step1_5/                  # Paso 1.5: Control de Calidad VAF
│   ├── final/
│   │   ├── figures/            # 11 figuras PNG
│   │   │   ├── QC_FIG1_VAF_DISTRIBUTION.png
│   │   │   ├── QC_FIG2_FILTER_IMPACT.png
│   │   │   ├── QC_FIG3_AFFECTED_MIRNAS.png
│   │   │   ├── QC_FIG4_BEFORE_AFTER.png
│   │   │   ├── STEP1.5_FIG1_HEATMAP_SNVS.png
│   │   │   ├── STEP1.5_FIG2_HEATMAP_COUNTS.png
│   │   │   ├── STEP1.5_FIG3_G_TRANSVERSIONS_SNVS.png
│   │   │   ├── STEP1.5_FIG4_G_TRANSVERSIONS_COUNTS.png
│   │   │   ├── STEP1.5_FIG5_BUBBLE_PLOT.png
│   │   │   ├── STEP1.5_FIG6_VIOLIN_DISTRIBUTIONS.png
│   │   │   └── STEP1.5_FIG7_FOLD_CHANGE.png
│   │   ├── tables/
│   │   │   ├── filtered_data/
│   │   │   │   └── ALL_MUTATIONS_VAF_FILTERED.csv  # ⭐ Principal
│   │   │   ├── filter_report/   # Reportes de filtrado
│   │   │   └── statistics/      # Estadísticas QC
│   │   └── logs/
│   └── intermediate/
│
├── 📊 step2/                    # Paso 2: Comparaciones Estadísticas
│   ├── final/
│   │   ├── figures/            # 2 figuras PNG
│   │   │   ├── step2_volcano_plot.png
│   │   │   └── step2_effect_size_distribution.png
│   │   ├── figures_clean/      # Versiones limpias
│   │   ├── tables/
│   │   │   ├── statistical_results/
│   │   │   │   └── step2_statistical_comparisons.csv  # ⭐ Principal
│   │   │   └── summary/
│   │   │       └── step2_effect_sizes.csv
│   │   └── logs/
│   └── intermediate/
│
├── 📄 pipeline_info/            # Metadatos del pipeline
│   ├── execution_info.yaml
│   ├── software_versions.yml
│   ├── config_used.yaml
│   └── provenance.json
│
├── 📋 summary/                  # Reportes consolidados
│   ├── summary_report.html     # ⭐ Reporte principal
│   ├── summary_statistics.json
│   └── key_findings.md
│
├── ✅ validation/               # Reportes de validación
│   ├── step1_validation.txt
│   ├── step1_5_validation.txt
│   ├── step2_validation.txt
│   └── final_validation_report.txt
│
└── 🌐 viewers/                  # Viewers HTML interactivos
    ├── step1_viewer.html        # ⭐ Viewer Step 1
    ├── step1_5_viewer.html     # ⭐ Viewer Step 1.5
    └── step2_viewer.html        # ⭐ Viewer Step 2
```

---

## 🚀 Acceso Rápido

### Ver Resultados Principales

```bash
# Viewers HTML (recomendado - más fácil de ver)
open viewers/step1_viewer.html
open viewers/step1_5_viewer.html
open viewers/step2_viewer.html
open summary/summary_report.html

# O explorar manualmente
ls results/step1/final/figures/
ls results/step1_5/final/tables/filtered_data/
ls results/step2/final/tables/statistical_results/
```

### Buscar Archivos Específicos

```bash
# Todas las figuras
find results -name "*.png" -type f

# Todas las tablas
find results -name "*.csv" -type f

# Figuras de un paso específico
ls results/step1/final/figures/
ls results/step1_5/final/figures/
ls results/step2/final/figures/
```

---

## ✅ Todo Automático

**No necesitas crear nada manualmente:**
- ✅ Todas las carpetas se crean automáticamente
- ✅ Estructura organizada por pasos
- ✅ Figuras y tablas separadas claramente
- ✅ Listo para usar inmediatamente

---

**Última actualización:** 2025-11-03

