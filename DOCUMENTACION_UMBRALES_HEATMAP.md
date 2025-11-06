# 📊 DOCUMENTACIÓN: Umbrales Configurables para Heatmaps (Figuras 2.4 y 2.5)

**Fecha:** 2025-11-04  
**Estado:** ✅ Implementado

---

## 🎯 OBJETIVO

Reemplazar el enfoque hardcoded de "top 50" o "all 301" miRNAs en los heatmaps por un sistema de **umbrales configurables** basado en criterios biológicos y estadísticos.

---

## 📋 UMBRALES IMPLEMENTADOS

### 1. **RPM (Reads Per Million) - Expresión**
```yaml
min_rpm_mean: null  # null = deshabilitado, o valor como 1.0, 0.5, etc.
min_rpm_median: null  # Alternativa: usar mediana en lugar de media
```

**Justificación:**
- Basado en literatura: RPM > 1 es común para filtrar miRNAs de baja expresión
- miRNAs con muy baja expresión pueden tener artefactos de secuenciación
- Valores típicos: 0.5 (conservador), 1.0 (estándar), 2.0 (estricto)

**Referencias:**
- Análisis previos del proyecto usan RPM > 1
- Estándar en análisis de expresión de miRNAs

---

### 2. **VAF (Variant Allele Frequency) - Detección**
```yaml
min_mean_vaf: 0.0  # VAF promedio mínimo
min_samples_with_vaf: 1  # Mínimo de muestras donde VAF > 0
max_vaf_threshold: 0.5  # Máximo VAF (ya filtrado en Step 1.5)
```

**Justificación:**
- `min_mean_vaf`: Filtra ruido de baja frecuencia (ej: 0.001, 0.01)
- `min_samples_with_vaf`: Asegura que el miRNA sea detectado en múltiples muestras
- Valores sugeridos:
  - Conservador: `min_mean_vaf: 0.001`, `min_samples_with_vaf: 1`
  - Estándar: `min_mean_vaf: 0.01`, `min_samples_with_vaf: 3`
  - Estricto: `min_mean_vaf: 0.05`, `min_samples_with_vaf: 5`

---

### 3. **Seed Region - Requisito**
```yaml
require_seed_gt: true  # Requerir G>T en seed region
seed_positions: [2, 3, 4, 5, 6, 7, 8]  # Posiciones de seed
```

**Justificación:**
- Región seed (2-8) es crítica para reconocimiento de targets
- Mutaciones G>T en seed tienen mayor impacto funcional
- Estándar: Bartel et al., Cell 2009; TargetScan

---

### 4. **Significancia Estadística (Opcional)**
```yaml
require_significance: false  # Requerir significancia estadística
significance_method: "fdr"  # "fdr" o "pvalue"
```

**Justificación:**
- Filtra solo miRNAs con diferencias significativas entre grupos
- `fdr`: Más conservador (FDR < alpha)
- `pvalue`: Menos conservador (p-value < alpha)
- Útil para análisis enfocados en biomarcadores

---

### 5. **Rango de Posiciones (Opcional)**
```yaml
position_range: null  # null = todas las posiciones
# O específico: [2, 8] para solo seed, [1, 23] para todas
```

**Justificación:**
- Permite enfocar análisis en regiones específicas
- Seed only: `[2, 8]`
- All positions: `null` o `[1, 23]`

---

### 6. **Log2 Fold Change (Opcional)**
```yaml
min_log2_fold_change: null  # Mínimo |log2FC| requerido
```

**Justificación:**
- Filtra solo miRNAs con cambios grandes entre grupos
- Valores sugeridos:
  - Conservador: `0.58` (1.5x fold change)
  - Estándar: `1.0` (2x fold change)
  - Estricto: `1.58` (3x fold change)

---

## 🔧 IMPLEMENTACIÓN

### Función de Filtrado

La función `filter_mirnas_for_heatmap()` está en:
- `scripts/utils/functions_common.R`

**Uso:**
```r
filtered_mirnas <- filter_mirnas_for_heatmap(
  data = data,
  metadata = metadata,
  config = config,
  sample_cols = sample_cols,
  statistical_results = statistical_results,  # Opcional
  rpm_data = rpm_data  # Opcional
)
```

### Configuración

Los umbrales se configuran en:
- `config/config.yaml` → `analysis.heatmap_filtering`

---

## 📊 EJEMPLOS DE CONFIGURACIÓN

### Configuración Conservadora (Más miRNAs)
```yaml
heatmap_filtering:
  min_rpm_mean: null  # Sin filtro RPM
  min_mean_vaf: 0.0  # Sin filtro VAF mínimo
  min_samples_with_vaf: 1  # Detectado en al menos 1 muestra
  require_seed_gt: true
  require_significance: false
```

### Configuración Estándar (Recomendada)
```yaml
heatmap_filtering:
  min_rpm_mean: 1.0  # RPM > 1
  min_mean_vaf: 0.01  # VAF promedio > 0.01
  min_samples_with_vaf: 3  # Detectado en al menos 3 muestras
  require_seed_gt: true
  require_significance: false
```

### Configuración Estricta (Biomarcadores)
```yaml
heatmap_filtering:
  min_rpm_mean: 2.0  # RPM > 2
  min_mean_vaf: 0.05  # VAF promedio > 0.05
  min_samples_with_vaf: 5  # Detectado en al menos 5 muestras
  require_seed_gt: true
  require_significance: true  # Solo significativos
  significance_method: "fdr"
  min_log2_fold_change: 1.0  # Log2FC >= 1.0
```

---

## ⚠️ NOTAS IMPORTANTES

1. **Todos los filtros son AND**: Un miRNA debe pasar TODOS los filtros activos
2. **RPM es opcional**: Si `min_rpm_mean` es `null`, se omite el filtro RPM
3. **Significancia es opcional**: Si `require_significance: false`, se omite
4. **Orden de aplicación**: Los filtros se aplican en secuencia (1-6)
5. **Retrocompatibilidad**: Si no se especifica configuración, se usa comportamiento por defecto

---

## 📝 PRÓXIMOS PASOS

1. ✅ Configuración agregada a `config.yaml`
2. ✅ Función de filtrado implementada
3. ⏳ Modificar scripts de Figuras 2.4 y 2.5 para usar la función
4. ⏳ Probar con diferentes configuraciones
5. ⏳ Documentar resultados en bitácora

---

## 🔗 REFERENCIAS

- Bartel et al., Cell 2009: Seed region definition
- TargetScan: miRNA seed region analysis
- Análisis previos del proyecto: RPM thresholds, VAF filtering

