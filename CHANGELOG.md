# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.1] - 2025-01-21

### 🔴 Fixed (Crítico)

#### Step 2 - Cálculo de VAF
- **Corrección crítica del cálculo de VAF en figuras detalladas**
  - Los scripts de Step 2 (FIG_2.1 a FIG_2.15) esperaban valores VAF como entrada, pero recibían solo SNV counts
  - **Problema:** Las figuras mostraban valores incorrectos (counts en lugar de VAF)
  - **Solución implementada:**
    - Detección automática de columnas Total (patrón `(PM+1MM+2MM)`)
    - Cálculo correcto de VAF: `VAF = SNV_Count / Total_Count`
    - Filtrado de VAF >= 0.5 (artefactos técnicos) → NA
    - Reemplazo de columnas SNV con valores VAF calculados
    - Eliminación de columnas Total (los scripts ya tienen VAF directamente)
  - **Archivos afectados:**
    - `scripts/step2_figures/run_all_step2_figures.R` - Lógica principal de cálculo VAF
    - `rules/step2_figures.smk` - Cambio de input de `VAF_FILTERED` a `PRIMARY` (processed_clean.csv)
  - **Impacto:** Sin esta corrección, todos los análisis de Step 2 estaban usando métricas incorrectas

#### Step 2 - Combinación de Heatmaps FIG_2.15
- **Corrección de combinación de heatmaps para FIG_2.15**
  - **Problema:** ALS y Control tienen diferente número de columnas (23 vs 21), no se pueden combinar con `+` o `%v%`
  - **Solución:** Implementado fallback usando `grid.layout` para layout lado a lado
  - **Archivo afectado:** `scripts/step2_figures/original_scripts/generate_FIG_2.13-15_DENSITY.R`
  - **Impacto:** FIG_2.15 ahora se genera correctamente

### 🔧 Fixed (Compatibilidad)

#### Compatibilidad ggplot2 3.4+
- **Actualización de parámetros deprecated**
  - Reemplazado `size` por `linewidth` en funciones de ggplot2
  - Afecta: `geom_tile()`, `geom_hline()`, `geom_vline()`, etc.
  - **Archivos afectados:**
    - `scripts/step0/01_generate_overview.R`
    - `scripts/step1/01_panel_b_gt_count_by_position.R`
    - `scripts/step1/02_panel_c_gx_spectrum.R`
    - `scripts/step1/03_panel_d_positional_fraction.R`
    - `scripts/step1/04_panel_e_gcontent.R`
    - `scripts/step1/05_panel_f_seed_vs_nonseed.R`
    - `scripts/step1/06_panel_g_gt_specificity.R`
    - `scripts/step1_5/02_generate_diagnostic_figures.R`
    - `scripts/step2/03_effect_size_analysis.R`
    - `scripts/step2/05_position_specific_analysis.R`
    - `scripts/step5/02_family_comparison_visualization.R`
  - **Impacto:** Evita warnings/errores en ggplot2 3.4+ y asegura compatibilidad futura

#### Mejoras menores de compatibilidad
- Corregido `outlier.size = 0.5` → `outlier.size = 1.0` para mejor visibilidad
- Ajustes menores en linewidth para mejor visualización

### ✨ Added (Mejoras)

#### Mejoras Visuales
- **Destacar G>T en rojo para consistencia**
  - Panel QC FIGURE 2 ahora destaca G>T mutations en rojo
  - Consistencia con estándar de visualización en todo el pipeline
  - **Archivo afectado:** `scripts/step1_5/02_generate_diagnostic_figures.R`

#### Documentación Mejorada
- **Documentación de aproximaciones en cálculos**
  - Agregados captions explicando que algunos valores son aproximaciones
  - Clarificación en QC FIGURE 4 sobre aproximación de valores originales
  - **Archivo afectado:** `scripts/step1_5/02_generate_diagnostic_figures.R`

### 📚 Added (Documentación)

#### Nuevos Documentos de Análisis
- **COMPARACION_LOCAL_vs_GITHUB.md**
  - Comparación detallada entre versión local y GitHub
  - Resumen de todos los cambios y su importancia
  - Plan de acción recomendado

- **CORRECCION_STEP2_VAF.md**
  - Documentación detallada de la corrección crítica del cálculo de VAF
  - Explicación del problema, solución, y verificación
  - Flujo de datos corregido

- **PROBLEMAS_CRITICOS_COHESION.md**
  - Identificación de 5 problemas críticos de cohesión en el pipeline
  - Problemas identificados pero **NO corregidos aún**:
    1. 🔴 Inconsistencia en archivos de entrada (Step 1)
    2. 🔴 Inconsistencia en métricas (Step 1)
    3. 🔴 Métrica 1 Panel E - Suma reads de otras posiciones
    4. 🔴 Asunción sobre estructura de datos (Step 0)
    5. 🟡 Datos no utilizados en figuras
  - Plan de acción recomendado para correcciones futuras

### 🔄 Changed (Refactorización Menor)

- Mejoras en comentarios y documentación interna
- Pequeños ajustes en lógica de visualizaciones
- Mejoras en mensajes de log y salida

---

## [1.0.0] - 2025-01-21

### Initial Release
- Pipeline completo funcional (Steps 0-7)
- Revisión exhaustiva completa de todos los scripts
- Documentación completa
- Sistema flexible de grupos
- Análisis estadístico robusto con validación de suposiciones
- Análisis de efectos de batch y confundidores

---

## Notas de Versión

### Versión 1.0.1
- **Fecha de lanzamiento:** 2025-01-21
- **Tipo de release:** Bugfix y mejoras
- **Compatibilidad:** Requiere ggplot2 3.4+ para mejor experiencia (pero compatible con versiones anteriores)
- **Cambios breaking:** Ninguno
- **Recomendación:** Actualizar inmediatamente debido a corrección crítica de VAF

### Versión 1.0.0
- **Fecha de lanzamiento:** 2025-01-21
- **Tipo de release:** Estable
- **Estado:** Pipeline completo y funcional

---

## Próximas Correcciones Identificadas

Los siguientes problemas críticos han sido identificados pero aún no corregidos (ver `PROBLEMAS_CRITICOS_COHESION.md`):

1. 🔴 **Inconsistencia en archivos de entrada (Step 1)**
   - Diferentes paneles usan diferentes archivos (`processed_clean.csv` vs `raw_data.tsv`)
   - Necesita unificación y documentación

2. 🔴 **Inconsistencia en métricas (Step 1)**
   - Mezcla de suma de reads vs cuenta de SNVs únicos
   - Necesita decisión sobre métrica consistente

3. 🔴 **Métrica 1 Panel E (G-Content Landscape)**
   - Suma reads de otras posiciones, no solo de la posición específica
   - Necesita corrección de lógica o clarificación en caption

4. 🔴 **Asunción sobre estructura de datos (Step 0)**
   - No verificado qué contiene `counts_matrix` exactamente
   - Necesita validación y documentación

5. 🟡 **Datos no utilizados en figuras**
   - Cálculos innecesarios que confunden
   - Puede optimizarse en versión futura

---

**Formato del changelog:** Basado en [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)

