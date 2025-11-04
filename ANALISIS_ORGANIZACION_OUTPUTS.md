# 🔍 Análisis Comparativo: Organización de Outputs en Pipelines Bioinformáticos

**Fecha:** 2025-11-02  
**Propósito:** Analizar cómo otros pipelines organizan outputs y proponer mejoras

---

## 📚 Referencias: Pipelines Estándar

### 1. **nf-core Pipelines** (Estándar de oro en bioinformática)

**Estructura típica:**
```
results/
├── pipeline_info/
│   ├── execution_report.html       # Reporte consolidado
│   ├── execution_timeline.html     # Timeline de ejecución
│   ├── execution_trace.txt         # Trace completo
│   └── software_versions.yml        # Versiones de software
├── software_versions/              # Versiones por herramienta
├── summary/                        # Resúmenes consolidados
│   ├── summary_vcf.html
│   └── summary_multiqc.html
├── [modulo_1]/                     # Outputs por módulo
│   ├── *.vcf
│   ├── *.tbi
│   └── *.log
└── [modulo_2]/
    └── ...
```

**Características clave:**
- ✅ **Un directorio `results/` consolidado** (no múltiples `outputs/`)
- ✅ **`pipeline_info/`** con metadata y reportes HTML automáticos
- ✅ **`summary/`** con reportes consolidados (MultiQC, HTML viewers)
- ✅ **Software versioning** automático
- ✅ **Nombres de módulos claros** (ej: `variant_calling/`, `quality_control/`)
- ✅ **HTML reports** auto-generados con links a todos los outputs

---

### 2. **GATK Best Practices Pipeline**

**Estructura típica:**
```
outputs/
├── intermediate/                    # Archivos intermedios
│   ├── aligned/
│   ├── deduped/
│   └── recalibrated/
├── final/                          # Outputs finales
│   ├── variants/
│   │   ├── raw/
│   │   ├── filtered/
│   │   └── annotated/
│   └── metrics/
├── reports/                        # Reportes consolidados
│   ├── QC_summary.html
│   └── variant_summary.tsv
└── logs/                           # Logs consolidados
    └── pipeline.log
```

**Características clave:**
- ✅ **Separación `intermediate/` vs `final/`**
- ✅ **`reports/`** con reportes HTML consolidados
- ✅ **Subdivisión por tipo** (`raw/`, `filtered/`, `annotated/`)
- ✅ **Logs consolidados** en un solo lugar

---

### 3. **RNA-seq Differential Expression Pipelines**

**Estructura típica:**
```
results/
├── 01_qc/                          # Quality control
│   ├── fastqc/
│   ├── multiqc_report.html
│   └── qc_summary.tsv
├── 02_quantification/               # Cuantificación
│   ├── counts/
│   ├── normalized/
│   └── summary.tsv
├── 03_differential/                 # Análisis diferencial
│   ├── comparisons/
│   │   ├── GroupA_vs_GroupB/
│   │   │   ├── results.tsv
│   │   │   ├── volcano.pdf
│   │   │   └── heatmap.pdf
│   │   └── summary_significant.tsv
│   └── summary_all_comparisons.tsv
├── 04_enrichment/                  # Enrichment analysis
│   └── ...
└── report.html                     # Reporte principal consolidado
```

**Características clave:**
- ✅ **Números de paso** (`01_`, `02_`, `03_`) para orden claro
- ✅ **Subdirectorios por comparación** cuando hay múltiples grupos
- ✅ **Reporte HTML principal** (`report.html`) que consolida todo
- ✅ **Separación clara** entre QC, quantification, analysis

---

## 🔍 Análisis de Nuestra Estructura Actual

### ✅ Lo que Hacemos Bien:
1. ✅ Separación por pasos (`step1/`, `step1_5/`, `step2/`)
2. ✅ Separación por tipo (`figures/`, `tables/`, `logs/`)
3. ✅ Nomenclatura consistente (`S1_`, `S1.5_`, `S2_`)
4. ✅ README_TABLES.md para documentación

### ⚠️ Lo que Podemos Mejorar:

#### 1. **Falta Directorio `results/` Consolidado**
**Problema:** Tenemos `outputs/step1/`, `outputs/step1_5/`, `outputs/step2/` pero no un directorio consolidado al nivel superior.

**Solución propuesta:**
```
results/                            # ← NUEVO directorio consolidado
├── step1/
├── step1_5/
├── step2/
├── pipeline_info/                  # ← NUEVO: metadata y reportes
│   ├── execution_report.html
│   ├── software_versions.yml
│   └── pipeline_summary.json
└── summary/                        # ← NUEVO: reportes consolidados
    ├── summary_report.html         # HTML viewer consolidado de TODO
    └── summary_tables.csv          # Tabla resumen de resultados clave
```

---

#### 2. **Falta Separación Intermediate vs Final**
**Problema:** Mezclamos outputs intermedios con finales.

**Solución propuesta:**
```
results/step1/
├── intermediate/                   # ← NUEVO: datos intermedios
│   └── processed_data_*.csv
└── final/                          # ← NUEVO: outputs finales
    ├── figures/
    └── tables/
```

---

#### 3. **Falta Reporte HTML Consolidado Principal**
**Problema:** Tenemos viewers individuales por paso, pero no un reporte principal que consolide TODO.

**Solución propuesta:**
```
results/
├── summary/
│   ├── summary_report.html         # ← NUEVO: Reporte HTML principal
│   │   - Links a todas las figuras
│   │   - Tablas consolidadas
│   │   - Estadísticas resumen
│   │   - Timeline de ejecución
│   └── summary_statistics.json     # ← NUEVO: Estadísticas clave
```

---

#### 4. **Falta Metadata y Provenance**
**Problema:** No registramos qué versión del pipeline, parámetros usados, fechas, etc.

**Solución propuesta:**
```
results/pipeline_info/
├── execution_report.html           # Reporte de ejecución
├── software_versions.yml          # Versiones de R, paquetes, etc.
├── config_used.yaml                # Configuración usada (copia)
├── execution_timeline.txt          # Timeline de ejecución
└── provenance.json                 # Provenance: inputs → outputs
```

---

#### 5. **Falta Organización por Análisis/Comparación**
**Problema:** En Step 2, tenemos comparaciones ALS vs Control, pero no está claro.

**Solución propuesta:**
```
results/step2/
├── comparisons/
│   └── ALS_vs_Control/             # ← NUEVO: por comparación
│       ├── statistical_results/
│       ├── summary/
│       └── figures/
└── summary_all_comparisons/        # Si hay múltiples comparaciones
```

---

#### 6. **Falta Índice/Navegación Rápida**
**Problema:** No hay un archivo índice que apunte a outputs clave.

**Solución propuesta:**
```
results/
├── INDEX.md                         # ← NUEVO: Índice de outputs importantes
│   - Links a figuras clave
│   - Links a tablas interpretativas
│   - Resumen de resultados
└── ...
```

---

## 🎯 Propuesta de Mejora: Estructura Mejorada

```
results/                            # Directorio consolidado
├── pipeline_info/                  # ⭐ NUEVO: Metadata y reportes de pipeline
│   ├── execution_report.html       # Reporte HTML de ejecución
│   ├── software_versions.yml       # Versiones de software
│   ├── config_used.yaml            # Configuración usada
│   ├── execution_timeline.txt      # Timeline
│   ├── provenance.json             # Provenance tracking
│   └── pipeline_summary.json       # Resumen en JSON
│
├── step1/                          # Exploratory Analysis
│   ├── intermediate/               # ⭐ NUEVO: Datos intermedios
│   │   └── processed_data_*.csv
│   ├── final/                      # ⭐ NUEVO: Outputs finales
│   │   ├── figures/
│   │   │   └── *.png
│   │   └── tables/
│   │       └── summary/
│   │           └── S1_*.csv
│   ├── logs/
│   └── viewer.html                 # Viewer Step 1
│
├── step1_5/                        # VAF Quality Control
│   ├── intermediate/
│   │   └── filtered_*.csv
│   ├── final/
│   │   ├── figures/
│   │   │   ├── qc/                 # QC figures
│   │   │   └── diagnostic/         # Diagnostic figures
│   │   └── tables/
│   │       ├── filtered_data/      # ⭐ Input para Step 2
│   │       ├── filter_report/
│   │       └── summary/
│   ├── logs/
│   └── viewer.html                 # Viewer Step 1.5
│
├── step2/                          # Statistical Comparisons
│   ├── comparisons/                # ⭐ NUEVO: Por comparación
│   │   └── ALS_vs_Control/
│   │       ├── statistical_results/
│   │       │   ├── S2_statistical_comparisons.csv
│   │       │   └── S2_effect_sizes.csv
│   │       ├── summary/            # ⭐ Tablas interpretativas
│   │       │   ├── S2_significant_mutations.csv
│   │       │   ├── S2_top_effect_sizes.csv
│   │       │   └── S2_seed_region_significant.csv
│   │       ├── figures/
│   │       │   └── *.png
│   │       └── comparison_summary.html  # ⭐ Reporte por comparación
│   ├── summary_all/                # ⭐ NUEVO: Resumen todas las comparaciones
│   │   └── all_comparisons_summary.csv
│   ├── logs/
│   └── viewer.html                 # Viewer Step 2
│
├── summary/                        # ⭐ NUEVO: Reportes consolidados
│   ├── summary_report.html         # ⭐ Reporte HTML principal (TODO)
│   ├── summary_statistics.json     # Estadísticas clave
│   ├── key_findings.md             # Hallazgos clave
│   └── pipeline_metrics.tsv        # Métricas del pipeline
│
└── INDEX.md                        # ⭐ NUEVO: Índice navegable
    - Links a outputs clave
    - Quick start guide
    - Resumen ejecutivo
```

---

## 🔑 Nuevas Características Propuestas

### 1. **`results/pipeline_info/`** - Metadata Automática
- ✅ `execution_report.html` - Generado automáticamente por Snakemake
- ✅ `software_versions.yml` - Versiones de R, paquetes
- ✅ `config_used.yaml` - Copia de configuración usada
- ✅ `provenance.json` - Tracking: input → processing → output

### 2. **`results/summary/`** - Reportes Consolidados
- ✅ `summary_report.html` - HTML principal con:
  - Links a todas las figuras
  - Tablas consolidadas
  - Estadísticas resumen
  - Timeline visual
- ✅ `summary_statistics.json` - Estadísticas clave en formato estructurado
- ✅ `key_findings.md` - Hallazgos clave en markdown

### 3. **Separación Intermediate/Final**
- ✅ `intermediate/` - Datos intermedios (pueden borrarse después)
- ✅ `final/` - Solo outputs finales (se guardan siempre)

### 4. **Organización por Comparación** (Step 2)
- ✅ `comparisons/ALS_vs_Control/` - Si hay múltiples comparaciones en el futuro

### 5. **Índice Navegable**
- ✅ `INDEX.md` - Punto de entrada con links a outputs importantes

---

## 📋 Comparación: Antes vs Después

| Aspecto | Estructura Actual | Estructura Propuesta | Mejora |
|---------|------------------|---------------------|--------|
| **Consolidación** | `outputs/step1/`, `outputs/step1_5/` | `results/` con todo | ✅ Más claro |
| **Metadata** | ❌ No existe | ✅ `pipeline_info/` | ✅ Reproducibilidad |
| **Reporte Principal** | Viewers individuales | ✅ `summary/summary_report.html` | ✅ Visión consolidada |
| **Intermediate/Final** | ❌ Mezclados | ✅ Separados | ✅ Claridad |
| **Índice** | ❌ No existe | ✅ `INDEX.md` | ✅ Navegación fácil |
| **Provenance** | ❌ No trackeado | ✅ `provenance.json` | ✅ Rastreabilidad |
| **Organización Step 2** | Todo en un directorio | ✅ Por comparación | ✅ Escalable |

---

## 🚀 Plan de Implementación Sugerido

### Fase 1: Reorganización Estructural (Básica)
1. ✅ Crear directorio `results/` y mover `outputs/` → `results/`
2. ✅ Separar `intermediate/` y `final/` en cada step
3. ✅ Crear `results/INDEX.md` con links clave

### Fase 2: Metadata y Provenance (Intermedia)
4. ✅ Generar `pipeline_info/execution_report.html` (Snakemake lo hace automático)
5. ✅ Crear script para generar `software_versions.yml`
6. ✅ Implementar `provenance.json` básico

### Fase 3: Reportes Consolidados (Avanzada)
7. ✅ Crear `summary/summary_report.html` que consolide todo
8. ✅ Generar `summary_statistics.json`
9. ✅ Crear `key_findings.md`

### Fase 4: Organización por Comparación (Si aplica)
10. ✅ Reorganizar Step 2 en `comparisons/ALS_vs_Control/`
11. ✅ Crear `comparison_summary.html` por comparación

---

## 💡 Elementos Adicionales que Podríamos Agregar

### 1. **Quality Metrics Consolidados**
```
results/quality_metrics/
├── data_quality_summary.tsv       # Resumen calidad de datos
├── qc_passed_samples.txt          # Muestras que pasaron QC
└── qc_failed_samples.txt          # Muestras que fallaron QC
```

### 2. **Performance Metrics**
```
results/pipeline_info/
└── performance_metrics.json       # Tiempos, memoria, recursos usados
```

### 3. **Validation Results** (Si hay validación)
```
results/validation/
├── cross_validation_results.tsv
└── validation_report.html
```

### 4. **Archive/Versioning**
```
results/archive/
└── v1.0.0/                        # Versión específica de resultados
    └── [misma estructura]
```

---

## 🎯 Próximos Pasos Recomendados

1. **Revisar propuesta** y decidir qué elementos implementar
2. **Priorizar:** ¿Qué es más importante ahora?
   - Metadata básica (Fase 1)
   - Reporte consolidado (Fase 3)
   - Separación intermediate/final (Fase 1)
3. **Implementar gradualmente** siguiendo el plan de fases
4. **Documentar** cambios en `CHANGELOG.md`

---

**¿Qué opinas? ¿Qué elementos de esta propuesta te parecen más importantes?**
