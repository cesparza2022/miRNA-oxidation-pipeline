# 📊 Organización Automática del Output

**Fecha:** 2025-11-03  
**Estado:** ✅ **Implementado y Automatizado**

---

## 🎯 Objetivo

**Hacer el pipeline completamente automático:**
1. ✅ Descargar el repositorio
2. ✅ Ejecutar `setup.sh`
3. ✅ Editar `config/config.yaml` con tu archivo de datos
4. ✅ Ejecutar `snakemake -j 4`
5. ✅ **¡Todo se genera automáticamente!**

---

## 📁 Estructura de Output Automática

### Creación Automática de Directorios

El pipeline **crea automáticamente** todas las carpetas necesarias:

```
results/
├── step1/
│   ├── final/
│   │   ├── figures/          ✅ Auto-creado
│   │   ├── tables/
│   │   │   └── summary/      ✅ Auto-creado
│   │   └── logs/             ✅ Auto-creado
│   └── intermediate/         ✅ Auto-creado
│
├── step1_5/
│   ├── final/
│   │   ├── figures/          ✅ Auto-creado
│   │   ├── tables/
│   │   │   ├── filtered_data/    ✅ Auto-creado
│   │   │   ├── filter_report/    ✅ Auto-creado
│   │   │   └── statistics/       ✅ Auto-creado
│   │   └── logs/             ✅ Auto-creado
│   └── intermediate/         ✅ Auto-creado
│
├── step2/
│   ├── final/
│   │   ├── figures/          ✅ Auto-creado
│   │   ├── figures_clean/    ✅ Auto-creado
│   │   ├── tables/
│   │   │   ├── statistical_results/  ✅ Auto-creado
│   │   │   └── summary/              ✅ Auto-creado
│   │   └── logs/             ✅ Auto-creado
│   └── intermediate/         ✅ Auto-creado
│
├── pipeline_info/            ✅ Auto-creado
├── summary/                  ✅ Auto-creado
├── validation/               ✅ Auto-creado
└── viewers/                  ✅ Auto-creado
```

---

## 🔧 Implementación

### 1. Script de Setup Automático

**Archivo:** `setup.sh`

**Funcionalidad:**
- ✅ Detecta conda/mamba automáticamente
- ✅ Crea ambiente conda/mamba
- ✅ Crea estructura de directorios
- ✅ Crea `config.yaml` desde ejemplo
- ✅ Todo listo para usar

**Uso:**
```bash
bash setup.sh --mamba  # Recomendado (más rápido)
# o
bash setup.sh --conda
```

### 2. Regla de Snakemake para Estructura

**Archivo:** `rules/output_structure.smk`

**Funcionalidad:**
- ✅ Crea todos los directorios necesarios
- ✅ Se ejecuta automáticamente antes de cualquier paso
- ✅ Fallback manual si Rscript no está disponible

**Integración:**
- Incluido en `Snakefile`
- Dependencia de `rule all`
- Se ejecuta al inicio del pipeline

### 3. Script R para Crear Estructura

**Archivo:** `scripts/utils/create_output_structure.R`

**Funcionalidad:**
- ✅ Crea estructura completa de directorios
- ✅ Reporta qué se creó
- ✅ Usado por setup.sh y regla de Snakemake

---

## 📊 Organización por Pasos

### Step 1: Exploratory Analysis

**Ubicación:** `results/step1/final/`

**Figuras:**
```
results/step1/final/figures/
├── step1_panelB_gt_count_by_position.png
├── step1_panelC_gx_spectrum.png
├── step1_panelD_positional_fraction.png
├── step1_panelE_gcontent.png
├── step1_panelF_seed_interaction.png
└── step1_panelG_gt_specificity.png
```

**Tablas:**
```
results/step1/final/tables/summary/
├── S1_B_gt_counts_by_position.csv
├── S1_C_gx_spectrum_by_position.csv
├── S1_D_positional_fractions.csv
├── S1_E_gcontent_landscape.csv
├── S1_F_seed_vs_nonseed.csv
└── S1_G_gt_specificity.csv
```

---

### Step 1.5: VAF Quality Control

**Ubicación:** `results/step1_5/final/`

**Figuras:**
```
results/step1_5/final/figures/
├── QC_FIG1_VAF_DISTRIBUTION.png
├── QC_FIG2_FILTER_IMPACT.png
├── QC_FIG3_AFFECTED_MIRNAS.png
├── QC_FIG4_BEFORE_AFTER.png
├── STEP1.5_FIG1_HEATMAP_SNVS.png
├── STEP1.5_FIG2_HEATMAP_COUNTS.png
├── STEP1.5_FIG3_G_TRANSVERSIONS_SNVS.png
├── STEP1.5_FIG4_G_TRANSVERSIONS_COUNTS.png
├── STEP1.5_FIG5_BUBBLE_PLOT.png
├── STEP1.5_FIG6_VIOLIN_DISTRIBUTIONS.png
└── STEP1.5_FIG7_FOLD_CHANGE.png
```

**Tablas:**
```
results/step1_5/final/tables/
├── filtered_data/
│   └── ALL_MUTATIONS_VAF_FILTERED.csv  # ⭐ Datos filtrados (principal)
├── filter_report/
│   └── ... (reportes de filtrado)
└── statistics/
    └── ... (estadísticas QC)
```

---

### Step 2: Statistical Comparisons

**Ubicación:** `results/step2/final/`

**Figuras:**
```
results/step2/final/figures/
├── step2_volcano_plot.png
└── step2_effect_size_distribution.png
```

**Tablas:**
```
results/step2/final/tables/
├── statistical_results/
│   └── step2_statistical_comparisons.csv  # ⭐ Resultados principales
└── summary/
    └── step2_effect_sizes.csv
```

---

## 🎯 Acceso Rápido a Resultados

### Viewers HTML

**Ubicación:** `viewers/` o `results/viewers/`

```bash
# Abrir en navegador
open viewers/step1_viewer.html      # Step 1 completo
open viewers/step1_5_viewer.html    # Step 1.5 completo
open viewers/step2_viewer.html      # Step 2 completo
open summary/summary_report.html    # Resumen consolidado
```

### Buscar Archivos

```bash
# Todas las figuras
find results -name "*.png" -type f

# Todas las tablas
find results -name "*.csv" -type f

# Figuras de un paso específico
ls results/step1/final/figures/
ls results/step1_5/final/figures/
ls results/step2/final/figures/

# Tablas de un paso específico
ls results/step1/final/tables/summary/
ls results/step1_5/final/tables/filtered_data/
ls results/step2/final/tables/statistical_results/
```

---

## 🚀 Flujo de Uso Completo

### 1. Setup (Una vez)

```bash
# Clonar repositorio
git clone https://github.com/cesparza2022/als-mirna-oxidation-pipeline.git
cd als-mirna-oxidation-pipeline/final_analysis/pipeline_definitivo/snakemake_pipeline

# Setup automático
bash setup.sh --mamba

# Activar ambiente
conda activate als_mirna_pipeline

# Configurar datos (editar ruta a tu archivo CSV)
nano config/config.yaml
```

### 2. Ejecutar Pipeline

```bash
# Ejecutar todo
snakemake -j 4

# ✅ ¡Listo! Todo generado automáticamente en results/
```

### 3. Ver Resultados

```bash
# Abrir viewers
open viewers/step1_viewer.html
open summary/summary_report.html

# O explorar manualmente
ls results/step1/final/figures/
ls results/step1/final/tables/summary/
```

---

## ✅ Ventajas de esta Organización

1. **Automático**: No necesitas crear carpetas manualmente
2. **Organizado**: Cada paso tiene su carpeta clara
3. **Consistente**: Misma estructura siempre
4. **Fácil de navegar**: Figuras y tablas separadas por paso
5. **Completo**: Incluye logs, validaciones, y metadatos

---

## 📝 Notas

- **Intermediate files**: Se guardan en `stepX/intermediate/` para debugging
- **Logs**: Contienen detalles de ejecución en `stepX/final/logs/`
- **Validaciones**: Se ejecutan automáticamente y reportes en `results/validation/`
- **Todo se crea automáticamente**: No necesitas crear nada manualmente

---

**Última actualización:** 2025-11-03  
**Estado:** ✅ **Completamente Automatizado**

