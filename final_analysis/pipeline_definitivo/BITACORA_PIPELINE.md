# 📋 BITÁCORA DE CAMBIOS DEL PIPELINE

Registro cronológico de modificaciones, mejoras y ajustes realizados en el pipeline de análisis G>T.

---

## 2025-11-04 - Implementación de Step 8: Sequence-Based Analysis (Paper Reference Methods)

### Cambios realizados:

✅ **Nuevo Step 8 creado:**
- Creado `step8/` con estructura completa: `scripts/`, `results/` (tables, figures, logs)
- Implementado análisis de contexto trinucleótido (XGY) - enriquecimiento de contextos GG, CG, AG, UG
- Implementado sequence logos por posición (hotspots: posiciones 2, 3, 5)
- Implementado análisis temporal (acumulación de G>T en timepoints, si disponibles)
- Agregado a `rules/step8.smk` y `Snakefile` (comentado por defecto, opcional)

✅ **Scripts creados:**
- `scripts/step8/01_trinucleotide_context.R`: Análisis de contexto XGY con tests de enriquecimiento
- `scripts/step8/02_position_specific_logos.R`: Generación de sequence logos usando `ggseqlogo`
- `scripts/step8/03_temporal_patterns.R`: Análisis de acumulación temporal

✅ **Mejoras en Step 6:**
- Agregado `scripts/step6/03_direct_target_prediction.R`: Comparación directa de targets canónicos vs oxidados
- Actualizado `rules/step6.smk` con nueva regla `step6_direct_target_prediction`
- Nuevas salidas: 3 tablas + 1 figura de comparación de targets

✅ **Configuración actualizada:**
- Agregado `step8` a `config.yaml` (paths y scripts)
- Agregado `step8` a `Snakefile` (opcional, comentado por defecto)
- Actualizado `README.md` del pipeline con Step 8

✅ **Documentación actualizada:**
- Actualizado `README.md` con descripción de Step 8
- Actualizado `BITACORA_PIPELINE.md` (esta entrada)
- Creado `PLAN_AGREGAR_ANALISIS_PAPER_REFERENCIA.md` con plan de implementación
- Actualizado `COMPARACION_ENFOQUES_METODOLOGICOS.md` (marcando análisis implementados)

### Motivo del cambio:
- Agregar métodos del paper de referencia: "Widespread 8-oxoguanine modifications of miRNA seeds..."
- Implementar análisis de contexto trinucleótido para validar mecanismo de oxidación
- Generar sequence logos para identificar motivos conservados
- Mejorar Step 6 con predicción directa de targets (comparación canónicos vs oxidados)

### Impacto:
- **Nuevos outputs Step 8:**
  - 4 figuras: trinucleotide context, logos (pos 2, 3, 5), temporal patterns
  - 3 tablas: enrichment, context summary, temporal accumulation
- **Nuevos outputs Step 6:**
  - 1 figura: target comparison (canonical vs oxidized)
  - 3 tablas: canonical targets, oxidized targets, detailed comparison
- **Dependencias:** Step 8 requiere Step 1.5 (VAF-filtered data) y Step 2 (statistical results)

### Uso:
```bash
# Ejecutar Step 8 (opcional)
snakemake -j 1 all_step8

# O incluir en pipeline completo (descomentar en Snakefile)
```

### Notas:
- Step 8 es opcional por defecto (comentado en Snakefile)
- Sequence logos requieren `ggseqlogo` y `Biostrings` (instalados automáticamente)
- Target prediction usa simulación (en producción, usar TargetScan/miRDB)
- Análisis temporal requiere timepoints en nombres de muestras (patrón: T0, T6, etc.)

---

## 2025-01-28 - Consolidación y Automatización del Pipeline

### Cambios en Paso 2:

✅ **Estructura estandarizada:**
- Migrado a `step2/` con estructura: `scripts/`, `viewers/`, `outputs/` (figures, figures_clean, tables, logs)
- Creado `run_step2.R` como orquestador principal
- Creado `scripts/build_step2_viewers.R` para generación automática de viewers HTML

✅ **Viewers embebidos:**
- Creado `STEP2_EMBED.html` con todas las imágenes embebidas (base64) para garantizar visibilidad
- Mantenido `STEP2.html` con rutas relativas como alternativa

✅ **Golden copies de density heatmaps:**
- Identificadas y registradas las versiones correctas de 2.13, 2.14, 2.15
- Fuente canónica: `pipeline_2/HTML_VIEWERS_FINALES/figures_paso2_CLEAN/FIG_2.13/14/15_*.png`
- Sincronización automática al ejecutar `run_step2.R` → `step2/outputs/figures_clean/`

✅ **Documentación:**
- Actualizado `ORGANIZACION_PIPELINE.md` con estructura completa de los 3 pasos
- Creado `BITACORA_PIPELINE.md` (este archivo) para registro de cambios

### Figuras del Paso 2 (15 total):
- 2.1-2.12: Generadas por scripts individuales → `step2/outputs/figures/`
- 2.13-2.15: Sincronizadas desde golden copies → `step2/outputs/figures_clean/`

### Próximos pasos sugeridos:
- [x] Migrar Paso 1 a estructura `step1/` estandarizada ✅ **COMPLETADO 2025-01-30**
- [x] Migrar Paso 1.5 a estructura `step1_5/` estandarizada ✅ **COMPLETADO 2025-01-30**
- [x] Crear `run_pipeline_completo.R` que ejecute todos los pasos en secuencia ✅ **COMPLETADO 2025-01-30**

---

## 2025-01-30 - Creación del Runner Maestro

### Cambios realizados:

✅ **Runner maestro creado:**
- `run_pipeline_completo.R` creado en la raíz del pipeline
- Ejecuta Paso 1 → Paso 1.5 → Paso 2 en secuencia
- Muestra tiempos de ejecución para cada paso
- Resumen final con ubicación de viewers

✅ **Funcionalidad:**
- Detecta automáticamente la raíz del pipeline
- Manejo de errores por paso (si uno falla, continúa con los siguientes)
- Muestra progreso y tiempos de ejecución
- Lista viewers HTML generados al final

### Uso:
```bash
Rscript run_pipeline_completo.R
```

### Nota:
- Cada paso se ejecuta independientemente
- Los errores en un paso no detienen el pipeline completo
- Los viewers HTML se listan al finalizar

---

## 2025-01-30 - Estandarización Paso 1.5

### Cambios realizados:

✅ **Estructura estandarizada:**
- Creado `step1_5/` con estructura idéntica a `step1/` y `step2/`
- Directorios: `scripts/`, `viewers/`, `outputs/` (figures, tables, logs)
- Scripts copiados desde `01.5_vaf_quality_control/` y adaptados

✅ **Scripts adaptados:**
- `01_apply_vaf_filter.R`: Rutas actualizadas, outputs a `outputs/tables/`
- `02_generate_diagnostic_figures.R`: Rutas actualizadas, figuras a `outputs/figures/`
- Input: Calculado dinámicamente desde estructura relativa
- Outputs: Redirigidos a estructura estandarizada

✅ **Orquestador creado:**
- `run_step1_5.R` creado (similar a `run_step1.R`)
- Ejecuta ambos scripts en orden
- Genera logs en `outputs/logs/`

✅ **Documentación:**
- Creado `step1_5/README.md` con guía de uso
- Actualizado `BITACORA_PIPELINE.md`

### Scripts migrados:
- `01_apply_vaf_filter.R` → Aplica filtro VAF >= 0.5
- `02_generate_diagnostic_figures.R` → Genera 11 figuras (4 QC + 7 diagnóstico)

### Nota:
- `01.5_vaf_quality_control/` se mantiene como referencia/backup
- Viewer HTML copiado a `step1_5/viewers/STEP1_5.html`
- Figuras y tablas existentes copiadas a `step1_5/outputs/` como referencia inicial

---

## 2025-01-30 - Estandarización Paso 1

### Cambios realizados:

✅ **Estructura estandarizada:**
- Creado `step1/` con estructura idéntica a `step2/`
- Directorios: `scripts/`, `viewers/`, `outputs/` (figures, tables, logs)
- Scripts copiados desde `STEP1_ORGANIZED/scripts/` y adaptados

✅ **Scripts adaptados:**
- Rutas actualizadas para usar estructura relativa desde `step1/scripts/`
- Salidas redirigidas a `step1/outputs/figures/` y `step1/outputs/tables/`
- Datos de entrada referencian rutas absolutas calculadas dinámicamente

✅ **Orquestador creado:**
- `run_step1.R` creado (similar a `run_step2.R`)
- Ejecuta todos los scripts en orden
- Genera logs en `outputs/logs/`

✅ **Documentación:**
- Creado `step1/README.md` con guía de uso
- Actualizado `BITACORA_PIPELINE.md`

### Scripts migrados:
- `02_gt_count_by_position.R` → Panel B
- `03_gx_spectrum.R` → Panel C
- `04_positional_fraction.R` → Panel D
- `05_gcontent_FINAL_VERSION.R` → Panel E (renombrado a `05_gcontent.R`)
- `06_seed_vs_nonseed.R` → Panel F
- `07_gt_specificity.R` → Panel G

### Nota:
- `STEP1_ORGANIZED/` se mantiene como referencia/backup
- Viewer HTML copiado a `step1/viewers/STEP1.html`
- Figuras y tablas existentes copiadas a `step1/outputs/` como referencia inicial

---

## Formato para nuevas entradas:

### YYYY-MM-DD - Título del cambio

**Qué se modificó:**
- Cambio específico 1
- Cambio específico 2

**Por qué:**
- Razón del cambio

**Impacto:**
- Qué scripts/viewers/outputs se vieron afectados

---

**Nota:** Agregar nuevas entradas al principio del archivo, manteniendo orden cronológico descendente.

