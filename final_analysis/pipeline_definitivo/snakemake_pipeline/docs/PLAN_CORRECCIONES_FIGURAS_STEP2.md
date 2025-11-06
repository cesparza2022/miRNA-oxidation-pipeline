# Plan de Correcciones - Figuras Step 2

**Fecha:** 2025-11-05  
**Objetivo:** Mejorar visualización y usar umbrales ajustables en lugar de "tops" arbitrarios

---

## Resumen de Correcciones

### 1. **Figure 2.4: Heatmap - Top 50 miRNAs** ✅ **COMPLETADO**
**Problemas identificados:**
- ❌ Usa "top 50" arbitrario → debe usar **umbrales ajustables**
- ❌ Escala de colores incorrecta → debe ser **blanco a rojo** para VAF (oxidación)
- ❌ Leyenda no se entiende bien

**Correcciones implementadas:**
1. ✅ Reemplazado filtro "top 50" por sistema de umbrales configurable (usando `config.yaml` y `filter_mirnas_for_heatmap()`)
2. ✅ Cambiada escala de colores a gradient blanco → rojo para VAF (`colorRampPalette` blanco→rojo)
3. ✅ Títulos y subtítulos actualizados para reflejar filtrado por umbrales
4. ✅ Sección de interpretación muestra criterios de filtrado utilizados

**Archivos modificados:**
- `scripts/step2_figures/original_scripts/generate_FIG_2.4_HEATMAP_RAW.R` ✅
- `config/config.yaml` (ya tiene `heatmap_filtering` section)

**Estado: COMPLETADO (2025-11-05)**
- **Filtrado biológico implementado:** El script ahora carga `config.yaml` y `functions_common.R`, y utiliza `filter_mirnas_for_heatmap()` para filtrar miRNAs basándose en expresión (RPM), VAF, seed region y significancia estadística (configurable).
- **Escala de colores:** Cambiada de `viridis` `plasma` a `colorRampPalette(c("white", "#FFE5E5", "#FF9999", "#FF6666", "#FF3333", "#D62728"))` para VAF (blanco→rojo, oxidación).
- **Título actualizado:** Refleja el número de miRNAs filtrados y los criterios utilizados.
- **Fallback:** Si `config.yaml` o `functions_common.R` no están disponibles, usa filtrado básico (G>T en seed region).

---

### 2. **Figure 2.5: Heatmap Z-score**
**Problemas identificados:**
- ❌ Escala de colores incorrecta → debe ser **azul a rojo** para z-scores

**Correcciones:**
1. Cambiar escala de colores a gradient azul → rojo (centrado en 0)
2. Ya tiene umbrales configurables (verificar implementación)

**Archivos a modificar:**
- `scripts/step2_figures/original_scripts/generate_FIG_2.5_ZSCORE_ALL301.R` o similar
- Verificar que use umbrales de `config.yaml`

---

### 3. **Figure 2.8: Clustering Analysis** ⚠️ **ELIMINADA**
**Razón de eliminación:**
- ✅ **Redundante con FIG_2.16:** Ambas hacen clustering jerárquico de muestras usando SNVs G>T
- ✅ **FIG_2.16 es más completa:** Usa TODOS los SNVs G>T (sin filtros de expresión)
- ✅ **FIG_2.8 usaba subset:** Filtrado biológico resultaba en menos SNVs
- 💡 **Decisión:** Mantener solo FIG_2.16 (más informativa y completa)

**Estado:**
- ❌ **ELIMINADA del pipeline** (2025-11-05)
- ❌ **ELIMINADA del viewer HTML**
- ❌ **Comentada en scripts** (run_all_step2_figures.R, step2_figures.smk)
- ✅ **Mantenida FIG_2.16:** Clustering con TODOS los SNVs G>T

**Archivos afectados:**
- `scripts/step2_figures/run_all_step2_figures.R` - Script comentado
- `rules/step2_figures.smk` - Output comentado
- `scripts/utils/create_step2_viewer.py` - Figura comentada
- `viewers/step2_EMBED.html` - Regenerado sin FIG_2.8

---

### 4. **Figure 2.12: Enrichment Analysis**
**Problemas identificados:**
- ❌ Panel A: "Top 20 miRNAs" → usar **umbrales**
- ❌ Panel B: "Top 10 miRNA Families" → usar **umbrales**
- ❓ Panel D: ¿Qué es "N samples"?

**Correcciones:**
1. Panel A: Reemplazar "top 20" por umbrales configurables (G>T burden, significancia, etc.)
2. Panel B: Reemplazar "top 10" por umbrales configurables
3. Panel D: Investigar y clarificar qué significa "N samples" (probablemente número de muestras donde el miRNA es significativo)

**Archivos a modificar:**
- `scripts/step2_figures/original_scripts/generate_FIG_2.12_ENRICHMENT.R`

---

### 5. **Figure 2.16: Hierarchical Clustering - ALL G>T SNVs**
**Problemas identificados:**
- ❌ Conteo incorrecto: dice "830 samples" → debe ser **415 samples**
  - Las otras 415 columnas son totales (no deben contarse como muestras)
- ❌ Falta indicar número de miRNAs
- ❌ Escala de colores incorrecta → debe ser **blanco a rojo** para VAF
- ❌ Muestra nombres de muestras → no poner nombres (muy largos)

**Correcciones:**
1. Corregir detección de columnas de muestras (excluir columnas de totales)
2. Añadir conteo de miRNAs en el título
3. Cambiar escala de colores a blanco → rojo
4. Ocultar nombres de muestras (`show_colnames = FALSE`)

**Archivos a modificar:**
- `scripts/step2/06_hierarchical_clustering_all_gt.R`

---

### 6. **Figure 2.17: Hierarchical Clustering - SEED REGION G>T SNVs**
**Problemas identificados:**
- ❌ Mismos problemas que Figura 2.16

**Correcciones:**
- Aplicar mismas correcciones que Figura 2.16

**Archivos a modificar:**
- `scripts/step2/07_hierarchical_clustering_seed_gt.R`

---

## Umbrales Configurables en `config.yaml`

Ya existe una sección `heatmap_filtering` en `config.yaml`. Verificar que incluya:

```yaml
heatmap_filtering:
  min_rpm_mean: null  # o valor como 1.0
  min_mean_vaf: 0.0
  min_samples_with_vaf: 1
  require_seed_gt: true
  require_significance: false
  min_log2_fold_change: null
```

**Añadir nuevos umbrales para:**
- Enrichment analysis (Panel A y B de Fig 2.12)
- Clustering analysis (Fig 2.8)

---

## Orden de Implementación

1. **Paso 1:** Corregir detección de muestras (415, no 830) - Figuras 2.16 y 2.17
2. **Paso 2:** Cambiar escalas de colores (blanco→rojo para VAF, azul→rojo para z-scores)
3. **Paso 3:** Implementar umbrales configurables en lugar de "tops" arbitrarios
4. **Paso 4:** Mejorar leyendas y títulos
5. **Paso 5:** Ocultar nombres de muestras en clustering heatmaps
6. **Paso 6:** Investigar y clarificar "N samples" en Fig 2.12 Panel D

---

## Paleta de Colores Estándar

- **VAF (Oxidación):** Blanco (`#FFFFFF`) → Rojo (`#D62728`)
- **Z-scores:** Azul (`#2166AC`) → Blanco (`#FFFFFF`) → Rojo (`#D62728`) [centrado en 0]
- **ALS:** `#D62728` (rojo)
- **Control:** `#2E86AB` (azul) o `#666666` (gris)

---

## Notas Importantes

- **Figura 2.8 es crítica:** Es el primer filtro para validar que el dataset sea valioso
- **Todas las figuras deben ser reproducibles** usando los umbrales en `config.yaml`
- **Mantener compatibilidad** con datos existentes (usar fallbacks si umbrales no están definidos)
- **Documentar cambios** en scripts y actualizar viewer HTML

---

## Verificación Post-Corrección

1. ✅ Verificar que todas las figuras usen umbrales configurables
2. ✅ Verificar escalas de colores correctas
3. ✅ Verificar conteo correcto de muestras (415)
4. ✅ Verificar que nombres de muestras no aparezcan en clustering
5. ✅ Verificar que número de miRNAs se muestre en clustering
6. ✅ Regenerar viewer HTML con todas las correcciones

