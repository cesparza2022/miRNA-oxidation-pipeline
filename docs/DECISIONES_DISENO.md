# 📐 DECISIONES DE DISEÑO DEL PIPELINE

**Versión:** 1.0  
**Fecha:** 2025-01-21  
**Propósito:** Documentar decisiones arquitectónicas y de diseño del pipeline

---

## 🎯 DECISIONES DE UMBRALES (Thresholds)

### ¿Por qué diferentes log2fc_threshold en diferentes steps?

**Decisión:** Usar umbrales diferentes según el propósito del step:
- **Step 2:** `log2fc_threshold_step2: 0.58` (1.5x fold change)
- **Step 3:** `log2fc_threshold_step3: 1.0` (2x fold change)
- **Step 6:** `log2fc_threshold_step6: 1.0` (2x fold change)

**Justificación:**
1. **Step 2 (Volcano Plots) - Exploratorio:**
   - Propósito: Visualización exploratoria de todos los cambios
   - Umbral más leniente permite ver más patrones y tendencias
   - 1.5x fold change es común en análisis exploratorios
   - No requiere filtrado estricto, solo visualización

2. **Step 3 (Clustering) - Estructural:**
   - Propósito: Identificar grupos de miRNAs con patrones similares
   - Umbral más estricto asegura que solo miRNAs con cambios sustanciales formen clusters
   - 2x fold change es biológicamente más relevante
   - Evita ruido en la agrupación

3. **Step 6 (Functional Analysis) - Funcional:**
   - Propósito: Análisis de impacto funcional y enriquecimiento
   - Umbral más estricto asegura que solo cambios biológicamente relevantes se analicen
   - 2x fold change es estándar para análisis funcionales
   - Reduce falsos positivos en enriquecimiento funcional

**Referencia:** Ver `docs/UMBRALES_BASADOS_LITERATURA.md` para justificación científica completa.

---

## 🏗️ DECISIONES ARQUITECTÓNICAS

### ¿Por qué Step 5 no usa clusters actualmente?

**Decisión:** Step 5 (Expression vs Oxidation Correlation) no incluye `INPUT_STEP3_CLUSTERS` como input.

**Justificación:**
1. **Análisis independiente:** La correlación expresión-oxidación es independiente de la estructura de clusters
2. **Simplicidad:** Mantener el análisis de correlación simple y directo
3. **Flexibilidad futura:** La estructura permite agregar análisis por cluster en futuras versiones sin romper compatibilidad

**Nota:** Step 5 SÍ depende de Step 3 en `all_step5` (orden de ejecución), pero no usa los outputs de clustering directamente.

---

### ¿Por qué Step 7 no integra Steps 3-5 actualmente?

**Decisión:** Step 7 (Biomarker Analysis) actualmente solo usa Steps 1.5, 2, y depende de Step 6.

**Justificación:**
1. **Enfoque actual:** El análisis de biomarkers se basa principalmente en resultados estadísticos (Step 2) y análisis funcional (Step 6)
2. **Validez estadística:** Los resultados de Step 2 son suficientes para identificar biomarkers robustos
3. **Futura extensión:** La arquitectura permite agregar integración de clusters, familias y expresión en futuras versiones

**Nota:** Documentado en `rules/step7.smk` y `scripts/step7/01_biomarker_roc_analysis.R` con notas sobre futuras integraciones.

---

## 🔧 DECISIONES TÉCNICAS

### ¿Por qué usar `getwd()` como fallback en functions_common.R?

**Decisión:** Usar `snakemake@config` cuando está disponible, `getwd()` como fallback.

**Justificación:**
1. **Contexto Snakemake:** Snakemake siempre establece el working directory al pipeline root
2. **Compatibilidad:** Permite ejecutar scripts directamente con Rscript para testing
3. **Robustez:** Múltiples métodos de detección de paths aseguran que funcione en diferentes contextos

**Implementación:** Ver `scripts/utils/functions_common.R` líneas 16-24, 43-51, etc.

---

### ¿Por qué validar archivos antes de leer?

**Decisión:** Validar existencia de archivos con `file.exists()` antes de `read_csv()`.

**Justificación:**
1. **Mensajes de error claros:** Identifica problemas de paths inmediatamente
2. **Debugging más fácil:** El error indica exactamente qué archivo falta
3. **Prevención de fallos silenciosos:** Evita que el script falle en pasos posteriores con datos faltantes

**Implementación:** Patrón aplicado en todos los scripts de visualización (steps 3-7).

---

### ¿Por qué validar outputs después de generar?

**Decisión:** Validar que archivos de salida se generaron correctamente después de `ggsave()` o `png()`.

**Justificación:**
1. **Detección temprana de errores:** Identifica fallos en generación de figuras inmediatamente
2. **Validación de tamaño:** Verifica que el archivo tiene tamaño mínimo razonable (no corrupto)
3. **Garantía de calidad:** Asegura que el pipeline produce outputs válidos

**Implementación:** Función `validate_output_file()` en `scripts/utils/functions_common.R` aplicada después de cada `ggsave()`.

---

## 📊 DECISIONES DE ORGANIZACIÓN

### ¿Por qué estructura de directorios step1/, step2/, etc.?

**Decisión:** Cada step tiene su propio directorio con subdirectorios `scripts/`, `viewers/`, `outputs/`.

**Justificación:**
1. **Modularidad:** Cada step es independiente y puede ejecutarse por separado
2. **Escalabilidad:** Fácil agregar nuevos steps sin afectar existentes
3. **Claridad:** Estructura intuitiva que refleja el flujo del pipeline
4. **Snakemake:** Compatible con estructura de Snakemake

**Referencia:** Ver `ORGANIZACION_PIPELINE.md` para estructura completa.

---

## 🔄 DECISIONES DE FLUJO

### ¿Por qué Step 3 corre antes de Steps 4-6?

**Decisión:** Step 3 (Clustering) corre primero, Steps 4-6 corren en paralelo después.

**Justificación:**
1. **Dependencias:** Steps 4, 5, 6 requieren resultados de Step 2 pero no de Step 3
2. **Paralelización:** Steps 4-6 son independientes entre sí, pueden correr en paralelo
3. **Eficiencia:** Maximiza uso de recursos computacionales
4. **Clustering temprano:** Step 3 corre temprano para descubrir estructura de datos antes de análisis más complejos

**Orden de ejecución:**
```
Step 1 → Step 1.5 → Step 2 → Step 3 → [Step 4, Step 5, Step 6 en paralelo] → Step 7
```

---

## 📝 NOTAS DE DISEÑO

### Convenciones de Nomenclatura

- **Scripts:** `01_<description>_analysis.R`, `02_<description>_visualization.R`
- **Outputs:** `S<step>_<description>.csv`, `step<step>_panel<letter>.png`
- **Funciones:** `snake_case` para funciones utilitarias
- **Variables:** `snake_case` para variables locales

### Manejo de Errores

- **Consistencia:** Todos los scripts usan `tryCatch()` alrededor de operaciones críticas
- **Logging:** Todos los errores se registran con contexto específico
- **Mensajes:** Errores incluyen nombres de archivos y contextos para debugging fácil

### Validación

- **Inputs:** Validación de existencia antes de leer
- **Outputs:** Validación de existencia y tamaño después de generar
- **Datos:** Validación de columnas esperadas en funciones de carga

---

**Fin del Documento de Decisiones de Diseño**

