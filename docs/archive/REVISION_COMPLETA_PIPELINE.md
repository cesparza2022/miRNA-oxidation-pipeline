# 🔍 Revisión Completa del Pipeline Snakemake

**Fecha de revisión:** 2025-01-XX  
**Pipeline:** ALS miRNA Oxidation Analysis  
**Versión:** 1.0.0

---

## 📋 Índice

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Estructura del Pipeline](#estructura-del-pipeline)
3. [Flujo de Ejecución](#flujo-de-ejecución)
4. [Componentes Principales](#componentes-principales)
5. [Configuración](#configuración)
6. [Validación y Pruebas](#validación-y-pruebas)
7. [Troubleshooting](#troubleshooting)

---

## 🎯 Resumen Ejecutivo

### ¿Qué hace este pipeline?

Este pipeline de Snakemake analiza patrones de **oxidación G>T en miRNAs de pacientes con ALS**. Específicamente:

- **Objetivo:** Identificar y cuantificar mutaciones G>T que son marcadores de daño por 8-oxo-guanosina (8-oxoG)
- **Método:** Análisis reproducible usando Snakemake + R
- **Datos:** Datos de miRNA con conteos de SNVs y totales por muestra

### Estado Actual

✅ **Pipeline funcional** - Todas las reglas validadas  
✅ **Estructura modular** - Pasos independientes y reproducibles  
✅ **Documentación completa** - README y guías de uso  
⚠️ **Nota:** Algunos archivos de configuración tienen contenido duplicado (no crítico)

---

## 🏗️ Estructura del Pipeline

```
snakemake_pipeline/
├── Snakefile                    # Orquestador principal
├── config/
│   ├── config.yaml              # Configuración (crear desde .example)
│   └── config.yaml.example      # Plantilla de configuración
├── rules/                       # Reglas de Snakemake por paso
│   ├── step1.smk                # Análisis exploratorio
│   ├── step1_5.smk              # Control de calidad VAF
│   ├── step2.smk                # Comparaciones estadísticas
│   ├── viewers.smk              # Generación de viewers HTML
│   ├── pipeline_info.smk        # Metadatos de ejecución
│   └── summary.smk              # Reportes consolidados
├── scripts/                     # Scripts R de análisis
│   ├── step1/                   # 6 scripts para Step 1
│   ├── step1_5/                 # 2 scripts para Step 1.5
│   ├── step2/                   # 4 scripts para Step 2
│   └── utils/                   # Utilidades compartidas
├── results/                     # Resultados (gitignored parcialmente)
│   ├── step1/final/             # Outputs Step 1
│   ├── step1_5/final/           # Outputs Step 1.5
│   ├── step2/final/             # Outputs Step 2
│   ├── pipeline_info/          # Metadatos (tracked)
│   └── summary/                # Reportes (tracked)
└── viewers/                     # Viewers HTML generados
```

---

## 🔄 Flujo de Ejecución

### Flujo Principal (3 Pasos Secuenciales)

```
┌─────────────────────────────────────────────────────────┐
│                    STEP 1                               │
│        Análisis Exploratorio                            │
│  • 6 paneles de figuras (B-G)                          │
│  • 6 tablas de resumen                                 │
│  • Caracterización del dataset                         │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│                   STEP 1.5                              │
│        Control de Calidad VAF                          │
│  • Filtrado de artefactos técnicos (VAF >= 0.5)       │
│  • 11 figuras diagnósticas                             │
│  • 7 tablas de reporte                                 │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│                    STEP 2                               │
│    Comparaciones Estadísticas (ALS vs Control)         │
│  • Tests estadísticos                                  │
│  • Volcano plots                                       │
│  • Análisis de tamaño de efecto                       │
└─────────────────────────────────────────────────────────┘
```

### Componentes Adicionales

- **Viewers HTML:** Se generan después de cada paso
- **Pipeline Info:** Metadatos de ejecución (FASE 2)
- **Summary Reports:** Reportes consolidados (FASE 3)

---

## 📦 Componentes Principales

### 1. **Snakefile** (Orquestador Principal)

**Ubicación:** `Snakefile`

**Función:**
- Carga la configuración (`config.yaml`)
- Incluye todas las reglas de los pasos
- Define el target por defecto (`rule all`)

**Targets disponibles:**
- `snakemake` o `snakemake all` - Ejecuta todo el pipeline
- `snakemake all_step1` - Solo Step 1
- `snakemake all_step1_5` - Solo Step 1.5
- `snakemake all_step2` - Solo Step 2

### 2. **Step 1: Análisis Exploratorio**

**Archivos:**
- `rules/step1.smk` - Definición de reglas
- `scripts/step1/*.R` - 6 scripts R (uno por panel)

**Reglas:**
1. `panel_b_gt_count_by_position` - Conteo de G>T por posición
2. `panel_c_gx_spectrum` - Espectro de mutaciones G>X
3. `panel_d_positional_fraction` - Fracción posicional
4. `panel_e_gcontent` - Paisaje de contenido G
5. `panel_f_seed_vs_nonseed` - Comparación seed vs no-seed
6. `panel_g_gt_specificity` - Especificidad G>T

**Outputs:**
- 6 figuras PNG (`results/step1/final/figures/`)
- 6 tablas CSV (`results/step1/final/tables/summary/`)
- Viewer HTML (`viewers/step1.html`)

### 3. **Step 1.5: Control de Calidad VAF**

**Archivos:**
- `rules/step1_5.smk` - Definición de reglas
- `scripts/step1_5/01_apply_vaf_filter.R` - Filtrado VAF
- `scripts/step1_5/02_generate_diagnostic_figures.R` - Figuras diagnósticas

**Reglas:**
1. `apply_vaf_filter` - Aplica filtro VAF (>= 0.5)
   - **Input:** Datos originales con SNV + total counts
   - **Outputs:** 
     - `ALL_MUTATIONS_VAF_FILTERED.csv` - Datos filtrados
     - `S1.5_filter_report.csv` - Reporte del filtro
     - `S1.5_stats_by_type.csv` - Estadísticas por tipo
     - `S1.5_stats_by_mirna.csv` - Estadísticas por miRNA

2. `generate_diagnostic_figures` - Genera 11 figuras
   - **4 figuras QC:**
     - VAF distribution
     - Filter impact
     - Affected miRNAs
     - Before/after comparison
   - **7 figuras diagnósticas:**
     - Heatmaps (SNVs, counts)
     - G transversions (SNVs, counts)
     - Bubble plot
     - Violin distributions
     - Fold change

**Outputs:**
- 11 figuras PNG
- 7 tablas CSV
- Viewer HTML (`viewers/step1_5.html`)

### 4. **Step 2: Comparaciones Estadísticas**

**Archivos:**
- `rules/step2.smk` - Definición de reglas
- `scripts/step2/*.R` - 4 scripts R

**Reglas:**
1. `step2_statistical_comparisons` - Comparaciones ALS vs Control
2. `step2_volcano_plot` - Volcano plot de resultados
3. `step2_effect_size` - Análisis de tamaño de efecto
4. `step2_generate_summary_tables` - Tablas de resumen interpretativas

**Inputs:**
- Datos VAF filtrados de Step 1.5 (preferido)
- Fallback: Datos procesados clean si no hay VAF filtrado

**Outputs:**
- Tablas de resultados estadísticos
- Volcano plots
- Análisis de tamaño de efecto
- Viewer HTML (`viewers/step2.html`)

### 5. **Scripts Utilitarios**

**Ubicación:** `scripts/utils/`

**Archivos clave:**
- `functions_common.R` - Funciones compartidas (carga datos, validación)
- `logging.R` - Sistema de logging
- `validate_input.R` - Validación de inputs
- `group_comparison.R` - Funciones para comparaciones de grupos
- `generate_pipeline_info.R` - Genera metadatos (FASE 2)
- `generate_summary_report.R` - Genera reportes (FASE 3)
- `build_step*_viewer.R` - Generadores de viewers HTML

---

## ⚙️ Configuración

### Archivo de Configuración

**Ubicación:** `config/config.yaml` (crear desde `config.yaml.example`)

**Secciones principales:**

#### 1. **Paths (Rutas)**

```yaml
paths:
  project_root: "/path/to/project"
  snakemake_dir: "/path/to/snakemake_pipeline"
  
  data:
    raw: "/path/to/miRNA_count.Q33.txt"              # Datos raw (para Step 1, panels C y D)
    processed_clean: "/path/to/processed_data.csv"   # Datos procesados (Step 1, otros paneles)
    step1_original: "/path/to/step1_original_data.csv"  # Datos originales (Step 1.5)
  
  outputs:
    step1: "results/step1/final"
    step1_5: "results/step1_5/final"
    step2: "results/step2/final"
```

#### 2. **Análisis (Parámetros)**

```yaml
analysis:
  vaf_filter_threshold: 0.5      # Umbral VAF (>= 0.5 se filtra)
  alpha: 0.05                     # Nivel de significancia
  fdr_method: "BH"                # Método FDR (Benjamini-Hochberg)
  
  colors:
    gt: "#D62728"                 # Color para G>T (rojo)
    control: "grey60"             # Color para control
    als: "#D62728"                # Color para ALS
  
  figure:
    dpi: 300
    width: 10
    height: 8
    units: "in"
```

#### 3. **Recursos**

```yaml
resources:
  threads: 4                      # Número de threads
  memory_gb: 8                    # Memoria requerida
```

---

## ✅ Validación y Pruebas

### 1. **Validar Sintaxis del Pipeline**

```bash
cd snakemake_pipeline
snakemake -n  # Dry-run (no ejecuta, solo valida)
```

**Qué valida:**
- Sintaxis de reglas Snakemake
- Nombres de reglas únicos (no duplicados)
- Rutas de inputs/outputs
- Referencias entre reglas

### 2. **Verificar Configuración**

```bash
# Verificar que config.yaml existe
ls -la config/config.yaml

# Verificar rutas en config.yaml
cat config/config.yaml | grep -E "(raw:|processed_clean:|step1_original:)"
```

### 3. **Validar Scripts R**

```bash
# Probar carga de funciones comunes
Rscript -e "source('scripts/utils/functions_common.R'); cat('✅ OK\n')"

# Validar un script específico (syntax check)
Rscript --check scripts/step1/01_panel_b_gt_count_by_position.R
```

### 4. **Probar un Paso Específico**

```bash
# Solo Step 1 (más rápido para probar)
snakemake -j 1 all_step1

# Solo Step 1.5
snakemake -j 1 all_step1_5

# Solo Step 2 (requiere Step 1.5 completo)
snakemake -j 1 all_step2
```

### 5. **Verificar Outputs Generados**

```bash
# Verificar figuras Step 1
ls -lh results/step1/final/figures/

# Verificar tablas Step 1
ls -lh results/step1/final/tables/summary/

# Verificar viewers
ls -lh viewers/*.html
```

---

## 🔧 Troubleshooting

### Problema: "The name X is already used by another rule"

**Causa:** Reglas duplicadas en archivos `.smk`

**Solución:**
- Ya corregido: `step1_5.smk`, `step2.smk`, `viewers.smk`
- Verificar: `snakemake -n` debe pasar sin errores

### Problema: "File not found" en inputs

**Causa:** Rutas incorrectas en `config.yaml`

**Solución:**
```bash
# Verificar que los archivos existen
cat config/config.yaml | grep -E "(raw:|processed_clean:|step1_original:)" | \
  sed 's/.*: "\(.*\)"/\1/' | xargs -I {} ls -lh {}
```

### Problema: "R package not found"

**Causa:** Paquetes R faltantes

**Solución:**
```bash
# Instalar paquetes requeridos
Rscript -e "install.packages(c('tidyverse', 'ggplot2', 'pheatmap', 'patchwork', 'ggrepel', 'viridis', 'yaml', 'jsonlite'))"
```

### Problema: Script R falla silenciosamente

**Solución:**
```bash
# Ejecutar script directamente para ver errores
Rscript scripts/step1/01_panel_b_gt_count_by_position.R

# Ver logs de Snakemake
cat results/step1/final/logs/panel_b.log
```

### Problema: Outputs no se generan

**Verificaciones:**
1. ¿El dry-run funciona? `snakemake -n`
2. ¿Los inputs existen? Verificar rutas en `config.yaml`
3. ¿Hay espacio en disco? `df -h .`
4. ¿Los permisos son correctos? `ls -la results/`

---

## 📊 Resumen de Outputs por Paso

### Step 1
- **6 figuras PNG** - Paneles B-G
- **6 tablas CSV** - Resúmenes numéricos
- **1 viewer HTML** - Visualización interactiva

### Step 1.5
- **11 figuras PNG** - 4 QC + 7 diagnósticas
- **7 tablas CSV** - Datos filtrados + reportes + resúmenes
- **1 viewer HTML** - Visualización interactiva

### Step 2
- **2 figuras PNG** - Volcano plot + efecto tamaño
- **5 tablas CSV** - Comparaciones + efectos + resúmenes
- **1 viewer HTML** - Visualización interactiva

### Metadatos (FASE 2)
- `execution_info.yaml` - Información de ejecución
- `software_versions.yml` - Versiones de software
- `config_used.yaml` - Configuración usada
- `provenance.json` - Proveniencia de datos

### Reportes (FASE 3)
- `summary_report.html` - Reporte consolidado HTML
- `summary_statistics.json` - Estadísticas en JSON
- `key_findings.md` - Hallazgos clave en Markdown

---

## 🎓 Cómo Usar el Pipeline

### Setup Inicial

```bash
# 1. Copiar configuración
cp config/config.yaml.example config/config.yaml

# 2. Editar configuración
nano config/config.yaml  # Actualizar rutas a datos

# 3. Validar
snakemake -n
```

### Ejecución Básica

```bash
# Ejecutar todo
snakemake -j 4

# Solo un paso
snakemake -j 1 all_step1

# Con más información
snakemake -j 4 --printshellcmds
```

### Re-ejecutar Después de Cambios

```bash
# Forzar re-ejecución de todo
snakemake -j 4 -F

# Forzar re-ejecución de un paso
snakemake -j 1 -F all_step1
```

---

## 📝 Notas Finales

### ✅ Fortalezas del Pipeline

1. **Modular:** Cada paso es independiente
2. **Reproducible:** Snakemake garantiza reproducibilidad
3. **Documentado:** README y guías completas
4. **Validado:** Dry-run pasa sin errores
5. **Trazable:** Metadatos y logs de ejecución

### ⚠️ Puntos de Atención

1. **Configuración:** Requiere actualizar rutas en `config.yaml`
2. **Dependencias R:** Algunos scripts requieren paquetes específicos
3. **Espacio en disco:** Figuras PNG pueden ser grandes
4. **Tiempo de ejecución:** Pipeline completo puede tardar varios minutos

### 🔄 Mejoras Futuras Sugeridas

1. Eliminar contenido duplicado en `config.yaml.example`
2. Agregar tests unitarios para scripts R
3. Implementar caching para pasos costosos
4. Agregar validación automática de inputs

---

**Última actualización:** 2025-01-XX  
**Mantenido por:** [Tu nombre]  
**Contacto:** [Email]
