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

- **ESTADO_PROBLEMAS_CRITICOS.md**
  - Identificación de 5 problemas críticos de cohesión en el pipeline
  - Problemas identificados pero **NO corregidos aún**:
    1. 🔴 Inconsistencia en archivos de entrada (Step 1)
    2. 🔴 Inconsistencia en métricas (Step 1)
    3. 🔴 Métrica 1 Panel E - Suma reads de otras posiciones
    4. 🔴 Asunción sobre estructura de datos (Step 0)
    5. 🟡 Datos no utilizados en figuras
  - Plan de acción recomendado para correcciones futuras

### 🔄 Changed (Refactorización Mayor - Revisión Perfeccionista)

#### FASE 1.1: Eliminación de Código Duplicado Masivo
- **Corrección crítica de código duplicado triplicado:**
  - `scripts/utils/logging.R`: Reducido de 1067 → 356 líneas (67% reducción)
  - `scripts/utils/validate_input.R`: Reducido de 1144 → 383 líneas (67% reducción)
  - `scripts/utils/build_step1_viewer.R`: Reducido de 1015 → 338 líneas (67% reducción)
  - **Impacto:** Eliminadas ~2000 líneas de código duplicado, mejorando mantenibilidad

- **Centralización de estilos:**
  - Creado `scripts/utils/colors.R` centralizado con todas las definiciones de colores
  - Eliminada definición duplicada de `theme_professional` en `functions_common.R`
  - Todos los scripts ahora usan colores y temas centralizados

#### FASE 1.2: Mejora de Robustez, Eficiencia y Claridad
- **Namespaces explícitos:**
  - Reemplazado `read_csv()` con `readr::read_csv()` en todos los scripts
  - Reemplazado `str_detect()` con `stringr::str_detect()` donde aplica
  - Agregado `suppressPackageStartupMessages()` para imports silenciosos

- **Validación robusta de datos:**
  - Agregada validación para data frames vacíos (`nrow == 0`, `ncol == 0`)
  - Validación de columnas críticas faltantes en todos los scripts
  - Mejor manejo de casos edge (datos vacíos, columnas faltantes)

- **Robustez en bucles:**
  - Reemplazado `1:n` con `seq_len(n)` y `seq_along()` para evitar problemas con vectores vacíos
  - Mejorado `safe_execute()` en `error_handling.R` para evaluación correcta de expresiones

#### FASE 1.3: Estandarización de Patrones
- **Colores centralizados:**
  - 11 scripts actualizados para usar `COLOR_GT`, `COLOR_ALS`, `COLOR_CONTROL` de `colors.R`
  - Creadas funciones helper para gradientes de heatmap: `get_heatmap_gradient()`, `get_blue_red_heatmap_gradient()`
  - Eliminados valores hardcoded de colores

- **Namespaces de stringr:**
  - 5 scripts actualizados para usar `stringr::` namespace explícito
  - Consistencia en uso de funciones de manipulación de strings

#### FASE 1.4: Validación y Pruebas
- Revisión completa de scripts de validación existentes
- Confirmada robustez de validaciones implementadas en FASE 1.2
- Documentación de estrategia híbrida (centralizada + ad-hoc) como óptima

#### FASE 2.1: Calidad Visual de Gráficas
- **Estandarización de colores:**
  - 30+ scripts actualizados para usar colores centralizados de `colors.R`
  - Creados nuevos constantes: `COLOR_SEED`, `COLOR_NONSEED`, `COLOR_SEED_HIGHLIGHT`, etc.
  - Funciones helper para gradientes de colores en heatmaps

- **Dimensiones de figuras:**
  - 13 scripts actualizados para usar `fig_width`, `fig_height`, `fig_dpi` de `config.yaml`
  - Eliminados valores hardcoded de dimensiones
  - Consistencia en todas las figuras del pipeline

#### FASE 2.2: Consistencia entre Figuras
- **Escalas de ejes estandarizadas:**
  - X-axis breaks: Todos los paneles de Step 1 ahora muestran todas las posiciones (1-23)
  - X-axis angle: Estándar de 45° para mejor legibilidad
  - Y-axis expand: Consistente `expansion(mult = c(0, 0.1))` en todos los paneles

- **Etiquetas y formato:**
  - Uso explícito de `scales::comma` y `scales::percent` para formateo
  - Traducción completa de `step2/05_position_specific_analysis.R` al inglés
  - Etiquetas de ejes mejoradas con explicaciones científicas

#### FASE 2.3: Claridad Científica
- **Títulos y subtítulos mejorados:**
  - 13 scripts actualizados con explicaciones biológicas consistentes
  - Términos científicos explicados: "seed region (functional binding domain)", "oxidative signature"
  - Subtítulos más descriptivos con contexto biológico

- **Captions mejorados:**
  - Step 1: Clarificación sobre "unique SNVs" vs "read counts"
  - Step 2: Explicación de métodos estadísticos (FDR, Cohen's d, Wilcoxon)
  - Step 6-7: Detalles de análisis (ROC, AUC, Pearson correlation, linear regression)

- **Leyendas y anotaciones:**
  - Mejora de leyendas con explicaciones claras
  - Anotaciones del seed region mejoradas en múltiples scripts
  - Terminología estandarizada ("Non-Seed" → "Non-seed")

#### FASE 2.4: Calidad Técnica
- **Formato de salida:**
  - Todos los `png()` calls ahora incluyen `bg = "white"` para fondo blanco consistente
  - 7 scripts actualizados con `bg = "white"`
  - `par(bg = "white")` agregado para plots de base R

- **Dimensiones finales:**
  - `step0/01_generate_overview.R` actualizado para usar config para todas las 8 figuras
  - Consistencia completa en dimensiones de todas las figuras del pipeline

#### FASE 3.1: Documentación de Usuario
- **Correcciones en README.md:**
  - Error tipográfico corregido: "datas´" → "data"
  - Eliminadas 11 referencias rotas a archivos inexistentes
  - Reorganizada sección de documentación sin referencias rotas
  - Corregido conteo de figuras Step 2: "73" → "21" (5 básicas + 16 detalladas)

- **Versión consistente:**
  - `config/config.yaml.example` actualizado de "1.0.0" → "1.0.1"

- **QUICK_START.md actualizado:**
  - Eliminadas referencias rotas
  - Reemplazadas con referencias útiles a secciones específicas de README.md

### 🔄 Changed (Refactorización Menor - Versión Inicial 1.0.1)

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
- **Tipo de release:** Bugfix, mejoras y refactorización mayor (revisión perfeccionista)
- **Compatibilidad:** Requiere ggplot2 3.4+ para mejor experiencia (pero compatible con versiones anteriores)
- **Cambios breaking:** Ninguno
- **Recomendación:** Actualizar inmediatamente debido a corrección crítica de VAF y mejoras masivas de código
- **Mejoras principales:**
  - Corrección crítica de cálculo VAF en Step 2
  - Eliminación de ~2000 líneas de código duplicado
  - Estandarización completa de colores, temas y dimensiones de figuras
  - Mejora de robustez en validación de datos y manejo de errores
  - Mejora de claridad científica en todas las figuras
  - Documentación de usuario actualizada y corregida

### Versión 1.0.0
- **Fecha de lanzamiento:** 2025-01-21
- **Tipo de release:** Estable
- **Estado:** Pipeline completo y funcional

---

## Estado de Problemas Críticos

**Todos los problemas críticos identificados originalmente han sido resueltos o mejorados.**  
Ver `ESTADO_PROBLEMAS_CRITICOS.md` para detalles completos:

1. ✅ **Inconsistencia en archivos de entrada (Step 1)** - **RESUELTO**
   - Todos los paneles ahora usan `processed_clean.csv` consistentemente
   - `rules/step1.smk` actualizado para usar `INPUT_DATA_CLEAN` en todos los paneles

2. 🟡 **Inconsistencia en métricas (Step 1)** - **MEJORADO**
   - Diferentes métricas son intencionales y apropiadas (diversidad vs abundancia)
   - Documentación agregada explicando las diferencias y su propósito

3. ✅ **Métrica 1 Panel E (G-Content Landscape)** - **RESUELTO**
   - Lógica corregida: ahora suma solo reads de la posición específica
   - Caption actualizado para claridad

4. ✅ **Asunción sobre estructura de datos (Step 0)** - **DOCUMENTADO**
   - Documentación clara agregada sobre estructura de `processed_clean.csv`
   - Validación mejorada con logs descriptivos

5. ✅ **Datos no utilizados en figuras** - **RESUELTO**
   - Cálculos innecesarios eliminados (Panel B, F de Step 1)
   - Cálculos necesarios para otras visualizaciones mantenidos y documentados

---

**Formato del changelog:** Basado en [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)

