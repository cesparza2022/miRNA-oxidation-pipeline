# 📁 Organización de Outputs del Pipeline

**Fecha:** 2025-11-03  
**Propósito:** Documentar qué outputs se trackean en Git y cuáles se ignoran

---

## 🎯 Principio General

**Git trackea:** Código fuente, configuración, documentación, metadatos, reportes resumidos  
**Git ignora:** Datos grandes, figuras PNG, tablas CSV grandes, viewers HTML, logs

---

## 📊 Organización de Directorios

### `results/` - Outputs Generados

```
results/
├── step1/final/
│   ├── figures/          ❌ IGNORADO (PNG grandes)
│   ├── tables/            ❌ IGNORADO (CSV grandes)
│   └── logs/              ❌ IGNORADO
├── step1_5/final/
│   ├── figures/          ❌ IGNORADO
│   ├── tables/            ❌ IGNORADO
│   └── logs/              ❌ IGNORADO
├── step2/final/
│   ├── figures/          ❌ IGNORADO
│   ├── tables/            ❌ IGNORADO
│   └── logs/              ❌ IGNORADO
├── pipeline_info/         ✅ TRACKEADO
│   ├── execution_info.yaml
│   ├── software_versions.yml
│   ├── config_used.yaml
│   └── provenance.json
└── summary/               ✅ TRACKEADO
    ├── summary_report.html
    ├── summary_statistics.json
    └── key_findings.md
```

### `viewers/` - Viewers HTML

```
viewers/
├── step1.html            ❌ IGNORADO (generado automáticamente, ~1.4MB)
├── step1_5.html          ❌ IGNORADO (generado automáticamente)
└── step2.html            ❌ IGNORADO (generado automáticamente)
```

---

## ✅ ¿Qué se Trackea en Git?

### 1. **Metadatos de Ejecución** (`results/pipeline_info/`)

**Por qué trackear:**
- Reproducibilidad
- Información de versiones de software
- Configuración usada
- Fecha/hora de ejecución

**Archivos:**
- `execution_info.yaml` - Info de ejecución
- `software_versions.yml` - Versiones de R, Snakemake, paquetes
- `config_used.yaml` - Configuración usada (sin paths sensibles)
- `provenance.json` - Proveniencia de datos

### 2. **Reportes Consolidados** (`results/summary/`)

**Por qué trackear:**
- Resúmenes ejecutivos
- Estadísticas clave
- Hallazgos principales

**Archivos:**
- `summary_report.html` - Reporte HTML consolidado
- `summary_statistics.json` - Estadísticas en JSON
- `key_findings.md` - Hallazgos clave

---

## ❌ ¿Qué se Ignora?

### 1. **Figuras PNG** (`*.png`)

**Razón:** Archivos grandes (100KB - 2MB cada uno)  
**Cantidad:** ~38 figuras  
**Tamaño total:** ~193MB

**Ejemplos:**
- `results/step1/final/figures/step1_panelB_gt_count_by_position.png`
- `results/step1_5/final/figures/QC_FIG1_VAF_DISTRIBUTION.png`
- `results/step2/final/figures/step2_volcano_plot.png`

**Alternativa:** Se pueden regenerar ejecutando el pipeline

### 2. **Tablas CSV** (`*.csv` en results/)

**Razón:** Datos grandes, pueden regenerarse  
**Excepciones:** Templates y schemas se trackean

**Ignorados:**
- `results/step1/final/tables/summary/*.csv`
- `results/step1_5/final/tables/filtered_data/*.csv`
- `results/step2/final/tables/statistical_results/*.csv`

### 3. **Viewers HTML** (`viewers/*.html`)

**Razón:** Generados automáticamente, grandes (~1.4MB cada uno)  
**Tamaño total:** ~14MB

**Nota:** Se generan automáticamente con `snakemake generate_step*_viewer`

### 4. **Logs** (`*.log`, `logs/`)

**Razón:** Archivos temporales, información de debug  
**Ubicación:** `results/*/final/logs/`

### 5. **Datos de Input** (`*.csv`, `*.txt` en raíz)

**Razón:** Archivos grandes con datos sensibles  
**Excepciones:** Templates, schemas, examples

---

## 🔧 Configuración en `.gitignore`

### Archivo Principal: `final_analysis/pipeline_definitivo/.gitignore`

```gitignore
# Results: Ignore large outputs, but allow metadata
snakemake_pipeline/results/
!snakemake_pipeline/results/pipeline_info/
!snakemake_pipeline/results/pipeline_info/**
!snakemake_pipeline/results/summary/
!snakemake_pipeline/results/summary/**
!snakemake_pipeline/results/INDEX.md

# Figures and PDFs
figures/
*.png
*.pdf

# HTML viewers (auto-generated)
viewers/*.html

# Logs
*.log
logs/

# Data files (except examples, templates, schemas)
*.csv
*.tsv
*.xlsx
*.xls
!*example*
!*template*
!*schema*
```

**Explicación:**
- `snakemake_pipeline/results/` - Ignora todo el directorio
- `!snakemake_pipeline/results/pipeline_info/` - **NO ignorar** pipeline_info
- `!snakemake_pipeline/results/pipeline_info/**` - **NO ignorar** contenido de pipeline_info
- `!snakemake_pipeline/results/summary/` - **NO ignorar** summary

---

## 📦 Tamaños Aproximados

| Componente | Tamaño | Trackeado? |
|------------|--------|------------|
| `results/` (total) | ~193MB | Parcial (solo metadata) |
| `viewers/` | ~14MB | ❌ No |
| Figuras PNG | ~193MB | ❌ No |
| Tablas CSV | ~50MB | ❌ No |
| Metadatos | ~100KB | ✅ Sí |
| Reportes | ~500KB | ✅ Sí |

---

## 🔄 Workflow Recomendado

### 1. **Desarrollo Local**

```bash
# Generar outputs localmente
snakemake -j 4

# Ver resultados (no se trackean)
open viewers/step1.html
ls -lh results/step1/final/figures/
```

### 2. **Antes de Commit**

```bash
# Verificar qué se trackea
git status

# Verificar que metadata se trackea
git ls-files results/pipeline_info/
git ls-files results/summary/
```

### 3. **Push a GitHub**

```bash
# Solo se suben:
# - Código fuente (scripts, rules)
# - Configuración (config.yaml.example)
# - Documentación (README, guías)
# - Metadatos (pipeline_info/)
# - Reportes (summary/)
```

---

## 📝 Notas Importantes

### ✅ Ventajas de esta Organización

1. **Repositorio ligero:** No pesa 200MB+ de figuras
2. **Reproducible:** Todo se puede regenerar con `snakemake`
3. **Trazable:** Metadata permite saber qué se ejecutó y cuándo
4. **Mantenible:** Código y docs separados de outputs

### ⚠️ Consideraciones

1. **Para colaboradores:**
   - Deben ejecutar el pipeline para generar outputs
   - Pueden usar los metadatos para entender ejecuciones previas

2. **Para publicación:**
   - Las figuras se pueden subir a figshare/zenodo
   - Los datos procesados se pueden compartir por separado

3. **Para CI/CD:**
   - Los metadatos permiten validar ejecuciones
   - Los reportes pueden generar artefactos

---

## 🚀 Comandos Útiles

### Verificar qué se trackea

```bash
# Ver archivos trackeados en results/
git ls-files results/

# Ver qué archivos están siendo ignorados
git status --ignored | grep results/
```

### Forzar tracking de un archivo específico

```bash
# Ejemplo: si quisiéramos trackear una figura específica (no recomendado)
git add -f results/step1/final/figures/step1_panelB_gt_count_by_position.png
```

### Regenerar outputs para verificar

```bash
# Limpiar y regenerar
snakemake -F -j 4

# Verificar que outputs se generaron
ls -lh results/step1/final/figures/
```

---

**Última actualización:** 2025-11-03

