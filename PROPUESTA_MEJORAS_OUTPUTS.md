# 💡 Propuesta: Mejoras a la Organización de Outputs

**Fecha:** 2025-11-02  
**Basado en:** Análisis comparativo de pipelines bioinformáticos estándar

---

## 🎯 Objetivo

Mejorar la organización de outputs siguiendo mejores prácticas de pipelines bioinformáticos (nf-core, GATK, RNA-seq pipelines).

---

## 📊 Comparación Rápida

### ❌ Estructura Actual
```
outputs/
├── step1/figures/, tables/, logs/
├── step1_5/figures/, tables/, logs/
└── step2/figures/, tables/, logs/
```

**Problemas:**
- ❌ No hay consolidación a nivel superior
- ❌ No hay metadata/provenance
- ❌ No hay reporte HTML principal consolidado
- ❌ Mezcla intermediate/final
- ❌ No hay índice navegable

### ✅ Estructura Propuesta
```
results/                            # ← Consolidado
├── pipeline_info/                  # ← Metadata automática
├── step1/
│   ├── intermediate/               # ← Separación clara
│   └── final/
├── step1_5/
│   ├── intermediate/
│   └── final/
├── step2/
│   ├── comparisons/ALS_vs_Control/ # ← Por comparación
│   └── summary_all/
├── summary/                        # ← Reportes consolidados
│   └── summary_report.html         # ← HTML principal
└── INDEX.md                        # ← Índice navegable
```

---

## 🚀 Implementación Propuesta: 3 Fases

### FASE 1: Reorganización Estructural (Esencial) ⭐

**Cambios:**
1. Crear `results/` y mover `outputs/` → `results/`
2. Separar `intermediate/` y `final/` en cada step
3. Crear `results/INDEX.md` básico

**Impacto:** Alto | Esfuerzo: Bajo | Prioridad: ⭐⭐⭐

---

### FASE 2: Metadata y Provenance (Reproducibilidad) ⭐⭐

**Cambios:**
1. Crear `results/pipeline_info/`:
   - `execution_report.html` (Snakemake automático)
   - `software_versions.yml` (script)
   - `config_used.yaml` (copia de config)
   - `provenance.json` (tracking básico)

**Impacto:** Alto | Esfuerzo: Medio | Prioridad: ⭐⭐

---

### FASE 3: Reportes Consolidados (Usabilidad) ⭐⭐⭐

**Cambios:**
1. Crear `results/summary/`:
   - `summary_report.html` (HTML principal con TODO)
   - `summary_statistics.json` (estadísticas clave)
   - `key_findings.md` (hallazgos)

**Impacto:** Muy Alto | Esfuerzo: Alto | Prioridad: ⭐⭐⭐

---

## 📋 Detalles por Fase

### FASE 1: Estructura Básica Mejorada

```
results/
├── INDEX.md                        # ← NUEVO: Índice navegable
│   # Quick Navigation
│   - [Summary Report](summary/summary_report.html)
│   - [Step 1 Results](step1/final/)
│   - [Step 2 Key Findings](step2/comparisons/ALS_vs_Control/summary/)
│   
├── step1/
│   ├── intermediate/               # ← NUEVO
│   │   └── [datos intermedios - pueden borrarse]
│   └── final/                      # ← NUEVO
│       ├── figures/
│       ├── tables/
│       └── viewer.html
│
├── step1_5/
│   ├── intermediate/
│   └── final/
│       ├── figures/
│       ├── tables/
│       └── viewer.html
│
└── step2/
    ├── intermediate/
    └── final/
        ├── comparisons/
        │   └── ALS_vs_Control/      # ← NUEVO: Por comparación
        │       ├── statistical_results/
        │       ├── summary/
        │       └── figures/
        └── viewer.html
```

**Scripts necesarios:**
- Script para mover/renombrar directorios
- Script para crear `INDEX.md` básico
- Actualizar paths en reglas Snakemake

---

### FASE 2: Metadata y Provenance

```
results/pipeline_info/
├── execution_report.html           # Snakemake lo genera automáticamente
├── software_versions.yml           # ← Script para generar
│   r_version: "4.3.2"
│   packages:
│     - ggplot2: "3.4.0"
│     - dplyr: "1.1.0"
├── config_used.yaml                # ← Copia de config/config.yaml
├── execution_timeline.txt          # ← Snakemake timeline
└── provenance.json                 # ← Script para generar
    {
      "pipeline_version": "1.0.0",
      "execution_date": "2025-11-02",
      "inputs": {
        "raw_data": "path/to/raw.csv",
        "config": "path/to/config.yaml"
      },
      "outputs": {
        "step1_figures": "results/step1/final/figures/",
        "step2_summary": "results/step2/final/summary/"
      }
    }
```

**Scripts necesarios:**
- `scripts/utils/generate_software_versions.R`
- `scripts/utils/generate_provenance.R`
- Integrar en regla Snakemake final

---

### FASE 3: Reportes Consolidados

```
results/summary/
├── summary_report.html             # ← Script para generar
│   # HTML consolidado con:
│   - Sección por step
│   - Links a todas las figuras
│   - Tablas consolidadas
│   - Estadísticas resumen
│   - Timeline visual
│
├── summary_statistics.json         # ← Script para generar
│   {
│     "step1": {
│       "total_mutations": 500000,
│       "gt_mutations": 150000,
│       "seed_region_gt": 45000
│     },
│     "step2": {
│       "significant_mutations": 1250,
│       "seed_significant": 342,
│       "top_effect_size": 2.3
│     }
│   }
│
└── key_findings.md                 # ← Manual o semi-automático
    # Hallazgos Clave
    
    ## Step 1: Exploratory Analysis
    - Total G>T mutations: 150,000
    - Seed region enrichment: 2.5x
    
    ## Step 2: Statistical Comparisons
    - Significant mutations (FDR < 0.05): 1,250
    - Seed region significant: 342 (27%)
    ...
```

**Scripts necesarios:**
- `scripts/utils/generate_summary_report.R`
- `scripts/utils/collect_statistics.R`
- Integrar en regla Snakemake final `all_pipeline`

---

## 🎯 Recomendación: Empezar con FASE 1

**Razones:**
1. ✅ Impacto alto, esfuerzo bajo
2. ✅ Mejora inmediata en organización
3. ✅ Base para fases siguientes
4. ✅ No rompe funcionalidad existente

**Plan:**
1. Crear estructura `results/` (renombrar `outputs/` → `results/`)
2. Agregar `intermediate/` y `final/` en cada step
3. Crear `INDEX.md` básico
4. Actualizar paths en reglas Snakemake
5. Actualizar documentación

---

## 💭 Elementos Opcionales Adicionales

### Si hay Múltiples Comparaciones (Futuro):
```
results/step2/comparisons/
├── ALS_vs_Control/
├── ALS_subtype1_vs_subtype2/
└── summary_all_comparisons/
```

### Si hay Validación:
```
results/validation/
├── cross_validation_results.tsv
└── validation_report.html
```

### Si hay Archive/Versioning:
```
results/archive/
└── v1.0.0/
    └── [misma estructura]
```

---

## 📊 Matriz de Decisión

| Elemento | Impacto | Esfuerzo | Prioridad | ¿Implementar? |
|----------|---------|----------|-----------|--------------|
| `results/` consolidado | Alto | Bajo | ⭐⭐⭐ | ✅ SÍ |
| `intermediate/` vs `final/` | Medio | Bajo | ⭐⭐ | ✅ SÍ |
| `INDEX.md` | Alto | Muy Bajo | ⭐⭐⭐ | ✅ SÍ |
| `pipeline_info/` | Alto | Medio | ⭐⭐ | ⏳ FASE 2 |
| `summary/summary_report.html` | Muy Alto | Alto | ⭐⭐⭐ | ⏳ FASE 3 |
| Organización por comparación | Medio | Bajo | ⭐⭐ | ⏳ Si aplica |

---

## ✅ Checklist de Implementación (FASE 1)

- [ ] Renombrar `outputs/` → `results/`
- [ ] Crear `results/step*/intermediate/` y `results/step*/final/`
- [ ] Mover outputs actuales a `final/`
- [ ] Actualizar paths en `rules/*.smk`
- [ ] Crear `results/INDEX.md` básico
- [ ] Actualizar `README.md` con nueva estructura
- [ ] Probar que todo funciona con dry-run
- [ ] Actualizar documentación

---

**¿Empezamos con FASE 1 o prefieres revisar otras propuestas primero?**
