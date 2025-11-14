# 🎉 Release Notes v1.0.1

**Fecha:** 2025-01-21  
**Tipo:** Bugfix y Mejoras  
**Prioridad:** 🔴 **Actualización Crítica Recomendada**

---

## 📋 Resumen Ejecutivo

Esta versión incluye una **corrección crítica** del cálculo de VAF en Step 2 que afectaba todos los análisis estadísticos y visualizaciones de ese paso. También incluye mejoras de compatibilidad con ggplot2 3.4+ y mejoras visuales.

### ⚠️ **ACTUALIZACIÓN RECOMENDADA INMEDIATAMENTE**

Si estás usando el pipeline para análisis de datos, debes actualizar a esta versión porque:
- **Corrección crítica:** Los resultados de Step 2 estaban usando métricas incorrectas (counts en lugar de VAF)
- Sin esta corrección, todas las figuras y análisis estadísticos de Step 2 son incorrectos

---

## 🔴 Correcciones Críticas

### 1. Cálculo de VAF en Step 2 (Crítico)

**Problema:**
- Los scripts detallados de Step 2 esperaban valores VAF (Variant Allele Frequency) como entrada
- Estaban recibiendo solo SNV counts, sin columnas Total
- **Resultado:** Las figuras mostraban valores incorrectos (counts en lugar de VAF)
- **Impacto:** Todos los análisis estadísticos y visualizaciones de Step 2 estaban usando métricas incorrectas

**Solución:**
- Detección automática de columnas Total en `processed_clean.csv`
- Cálculo correcto: `VAF = SNV_Count / Total_Count`
- Filtrado automático de VAF >= 0.5 (artefactos técnicos) → NA
- Reemplazo de SNV counts con valores VAF calculados
- Los scripts ahora reciben VAF directamente, como esperaban

**Archivos modificados:**
- `scripts/step2_figures/run_all_step2_figures.R` - Lógica principal
- `rules/step2_figures.smk` - Cambio de input a `processed_clean.csv`

**Cómo verificar:**
1. Ejecutar Step 2: `snakemake -j 1 all_step2_figures`
2. Revisar log: Debe mostrar "VAF calculated and filtered"
3. Verificar figuras: Deben mostrar valores entre 0 y 0.5 (rango válido de VAF)

### 2. Combinación de Heatmaps FIG_2.15

**Problema:**
- ALS y Control tienen diferente número de columnas (23 vs 21)
- No se pueden combinar directamente con `+` o `%v%` en patchwork

**Solución:**
- Implementado fallback usando `grid.layout` para layout lado a lado
- FIG_2.15 ahora se genera correctamente

**Archivo modificado:**
- `scripts/step2_figures/original_scripts/generate_FIG_2.13-15_DENSITY.R`

---

## 🔧 Correcciones de Compatibilidad

### Compatibilidad ggplot2 3.4+

**Problema:**
- ggplot2 3.4+ deprecó el parámetro `size` en favor de `linewidth`
- El código usaba `size` en `geom_tile()`, `geom_hline()`, etc.

**Solución:**
- Reemplazado `size` por `linewidth` en todos los scripts afectados
- Compatible con versiones anteriores y futuras de ggplot2

**Archivos modificados:** 11 scripts en total
- Steps 0, 1, 1.5, 2, 5

---

## ✨ Mejoras

### Mejoras Visuales
- **Destacar G>T en rojo** en QC FIGURE 2 para consistencia con estándar del pipeline
- Mejor visibilidad de outliers (`outlier.size` aumentado a 1.0)

### Documentación Mejorada
- Captions explicando aproximaciones en cálculos
- Clarificación en QC FIGURE 4 sobre valores aproximados

---

## 📚 Nueva Documentación

### 1. COMPARACION_LOCAL_vs_GITHUB.md
- Comparación detallada entre versiones local y remota
- Resumen de cambios y su importancia
- Plan de acción recomendado

### 2. CORRECCION_STEP2_VAF.md
- Documentación técnica detallada de la corrección de VAF
- Explicación del problema y solución
- Flujo de datos corregido

### 3. PROBLEMAS_CRITICOS_COHESION.md
- Identificación de 5 problemas críticos pendientes
- Guía para correcciones futuras
- Plan de acción recomendado

---

## 🔄 Cambios Técnicos Detallados

### Archivos Modificados (18 archivos)

#### Correcciones Críticas (3 archivos)
1. `scripts/step2_figures/run_all_step2_figures.R` - Cálculo VAF
2. `scripts/step2_figures/original_scripts/generate_FIG_2.13-15_DENSITY.R` - Layout heatmaps
3. `rules/step2_figures.smk` - Input configuration

#### Compatibilidad ggplot2 (11 archivos)
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

#### Otros cambios menores (4 archivos)
- `rules/step1.smk` - Ajustes menores

### Estadísticas
- **Líneas agregadas:** +831
- **Líneas eliminadas:** -96
- **Neto:** +735 líneas
- **Archivos nuevos:** 3 (documentación)

---

## ⚙️ Instalación y Actualización

### Si ya tienes el pipeline instalado:

```bash
cd miRNA-oxidation-pipeline
git pull origin main
```

### Si es una nueva instalación:

```bash
git clone https://github.com/cesparza2022/miRNA-oxidation-pipeline.git
cd miRNA-oxidation-pipeline
bash setup.sh --mamba  # o --conda
```

### Verificación después de actualizar:

```bash
# Verificar que los cambios están presentes
git log --oneline -3

# Debe mostrar:
# 7d6ea94 fix: Correcciones críticas VAF Step 2 y mejoras de compatibilidad
```

---

## ⚠️ Notas Importantes

### Si ya ejecutaste Step 2 con la versión anterior:

1. **Re-ejecutar Step 2** con esta versión:
   ```bash
   snakemake -j 1 all_step2_figures --forceall
   ```

2. **Revisar los resultados:**
   - Las figuras deben mostrar valores entre 0 y 0.5 (VAF)
   - Los análisis estadísticos deben ser diferentes (ahora correctos)

### Problemas Conocidos Pendientes:

Ver `PROBLEMAS_CRITICOS_COHESION.md` para lista completa de problemas identificados pero aún no corregidos:
- Inconsistencia en archivos de entrada (Step 1)
- Inconsistencia en métricas (Step 1)
- Métrica 1 Panel E (suma incorrecta)
- Asunción sobre estructura de datos (Step 0)

Estos problemas serán corregidos en versiones futuras.

---

## 🙏 Agradecimientos

Gracias a la revisión exhaustiva que identificó estos problemas críticos, especialmente:
- Revisión de lógica de cálculos
- Identificación de incompatibilidades con ggplot2
- Documentación de problemas pendientes

---

## 📞 Soporte

Si encuentras problemas después de actualizar:
1. Revisar `CORRECCION_STEP2_VAF.md` para detalles técnicos
2. Revisar logs en `results/step2/final/logs/`
3. Verificar que `processed_clean.csv` tiene columnas Total

---

**Última actualización:** 2025-01-21  
**Commit:** 7d6ea94

