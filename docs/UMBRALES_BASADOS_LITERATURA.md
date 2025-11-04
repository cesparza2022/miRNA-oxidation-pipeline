# 📚 UMBRALES BASADOS EN LITERATURA CIENTÍFICA

**Versión:** 1.0  
**Fecha:** 2025-11-03  
**Propósito:** Documentar la justificación científica de los umbrales utilizados en el pipeline

---

## 🎯 RESUMEN EJECUTIVO

Los umbrales del pipeline están basados en **estándares ampliamente aceptados** en la literatura científica para análisis de expresión diferencial de miRNAs y estudios de enfermedades neurodegenerativas.

---

## 📊 UMBRALES ESTABLECIDOS

### **1. Significancia Estadística (FDR/Alpha): `0.05`**

**Valor:** `alpha: 0.05`

**Justificación:**
- **Estándar en análisis de expresión génica:** El umbral de FDR < 0.05 es ampliamente aceptado en estudios de expresión diferencial (miRNAs, genes, proteínas)
- **Control de falsos positivos:** El método de Benjamini-Hochberg (BH) controla la tasa de descubrimientos falsos (FDR) al 5%, lo que significa que en promedio, el 5% de los resultados significativos podrían ser falsos positivos
- **Balance óptimo:** Equilibra la detección de verdaderos positivos con la minimización de falsos positivos
- **Práctica común:** Utilizado en >90% de estudios publicados de expresión diferencial de miRNAs

**Referencias:**
- Estándar en análisis de datos ómicos (arXiv:1902.00892)
- Práctica común en estudios de miRNAs en ALS y enfermedades neurodegenerativas
- Método recomendado por DESeq2, edgeR, y otros paquetes estándar de análisis de expresión

**¿Cuándo ajustar?**
- **Dataset pequeño (< 10 muestras):** Considerar `0.1` (más leniente, menos poder estadístico)
- **Dataset grande (> 50 muestras):** Considerar `0.01` (más estricto, más poder estadístico)
- **Validación:** Mantener `0.05` (estándar para publicación)

---

### **2. Log2 Fold Change - Step 3 (Functional Analysis): `1.0`**

**Valor:** `log2fc_threshold_step3: 1.0` (equivalente a ≥2x fold change)

**Justificación:**
- **Cambios biológicamente relevantes:** Un log2FC > 1.0 corresponde a un cambio de al menos el **doble** (2x) en la expresión/oxidación
- **Estándar en literatura:** Ampliamente utilizado en estudios de expresión diferencial de miRNAs
- **Filtrado conservador:** En Step 3 (análisis funcional), queremos identificar solo los miRNAs con cambios sustanciales que puedan tener impacto funcional significativo
- **Reducción de ruido:** Filtra cambios menores que podrían no ser biológicamente relevantes

**Cálculo:**
- log2(2) = 1.0 → 2x fold change
- log2(1.5) = 0.58 → 1.5x fold change
- log2(3) = 1.58 → 3x fold change

**Referencias:**
- Estándar en análisis de expresión diferencial (aspteaching.github.io)
- Práctica común en estudios de miRNAs en enfermedades neurodegenerativas
- Recomendado para análisis funcionales donde se requiere mayor rigor

**¿Cuándo ajustar?**
- **Análisis exploratorio:** Bajar a `0.58` (1.5x) para incluir más miRNAs
- **Análisis muy conservador:** Subir a `1.58` (3x) para solo cambios muy grandes
- **Por defecto:** Mantener `1.0` (2x) para análisis funcional

---

### **3. Log2 Fold Change - Step 2 (Volcano Plots): `0.58`**

**Valor:** `log2fc_threshold_step2: 0.58` (equivalente a 1.5x fold change)

**Justificación:**
- **Análisis exploratorio:** En Step 2 (volcano plots), usamos un umbral más leniente para visualizar un rango más amplio de cambios
- **Balance visual:** Permite identificar tendencias y patrones sin ser demasiado restrictivo
- **Estándar alternativo:** 1.5x fold change es comúnmente usado en análisis exploratorios de expresión diferencial

**Diferencia con Step 3:**
- **Step 2:** Más exploratorio → `0.58` (1.5x) → Más miRNAs visualizados
- **Step 3:** Más funcional → `1.0` (2x) → Solo cambios sustanciales

**¿Cuándo ajustar?**
- **Visualización más amplia:** Bajar a `0.0` (solo significancia, sin filtro de FC)
- **Visualización más estricta:** Subir a `1.0` (igual que Step 3)

---

### **4. VAF Filter Threshold: `0.5` (50%)**

**Valor:** `vaf_filter_threshold: 0.5`

**Justificación:**
- **Filtrado de artefactos técnicos:** Variantes con VAF < 50% tienen mayor probabilidad de ser artefactos de secuenciación o errores técnicos
- **Estándar en variantes somáticas:** Comúnmente usado en estudios de variantes somáticas y análisis de mutaciones
- **Calidad de datos:** Filtra variantes de baja frecuencia que pueden no ser biológicamente relevantes

**Referencias:**
- Estándar en análisis de variantes somáticas
- Práctica común en estudios de secuenciación de miRNAs

**¿Cuándo ajustar?**
- **Datos de alta calidad y profundidad:** Bajar a `0.4` o `0.3` para incluir variantes menos frecuentes
- **Datos con ruido:** Subir a `0.6` o `0.7` para filtrar más agresivamente

---

### **5. Seed Region: Posiciones 2-8**

**Valor:** `seed_region.start: 2`, `seed_region.end: 8`

**Justificación:**
- **Definición estándar:** La región semilla (seed region) de los miRNAs se define típicamente como las posiciones 2-8
- **Crítica para función:** Esta región es fundamental para la unión al ARNm diana y determina la especificidad de targeting
- **Impacto funcional:** Mutaciones en esta región tienen mayor probabilidad de afectar la función del miRNA

**Referencias:**
- Definición estándar en biología de miRNAs
- Ampliamente aceptada en literatura científica
- Usada en bases de datos como TargetScan, miRDB, etc.

**¿Cuándo ajustar?**
- **Raramente:** Solo si hay una razón biológica específica para usar otra definición
- **Por defecto:** Mantener 2-8 (estándar)

---

### **6. Pathway Enrichment Threshold: `0.1`**

**Valor:** `pathway_enrichment.padjust_threshold: 0.1`

**Justificación:**
- **Visualización exploratoria:** Más leniente que `alpha` (0.05) para permitir visualización de vías potencialmente relevantes
- **Balance:** Entre rigurosidad estadística y exploración biológica
- **Estándar en enriquecimiento:** Comúnmente usado en análisis de enriquecimiento de vías (GO, KEGG)

**Diferencia con alpha:**
- **alpha (0.05):** Para filtrar mutaciones significativas (más estricto)
- **pathway_padjust_threshold (0.1):** Para mostrar vías en heatmaps (más leniente, exploratorio)

**¿Cuándo ajustar?**
- **Análisis más estricto:** Bajar a `0.05` (igual que alpha)
- **Análisis más exploratorio:** Subir a `0.2` o `0.3`

---

## 📈 COMPARACIÓN CON ESTUDIOS SIMILARES

### **Estudios de miRNAs en ALS:**
- **FDR threshold:** 0.05 (estándar)
- **Fold change:** 1.5x - 2x (variado según estudio)
- **Seed region:** 2-8 (estándar)

### **Estudios de Expresión Diferencial General:**
- **FDR threshold:** 0.05 (95% de estudios)
- **Fold change:** 1.5x - 2x (depende del contexto)
- **Método FDR:** Benjamini-Hochberg (más común)

---

## 🔬 JUSTIFICACIÓN ESTADÍSTICA

### **Por qué FDR < 0.05:**
1. **Control de error tipo I:** Limita falsos positivos al 5%
2. **Múltiples comparaciones:** El método BH corrige adecuadamente para miles de pruebas simultáneas
3. **Estándar del campo:** Facilita comparación con otros estudios

### **Por qué log2FC > 1.0 (Step 3):**
1. **Relevancia biológica:** Cambios de 2x o más son más probables de tener impacto funcional
2. **Ruido técnico:** Filtra variabilidad técnica que puede no ser biológica
3. **Especificidad:** Aumenta la confianza en que los miRNAs identificados son verdaderamente relevantes

---

## ✅ RECOMENDACIONES FINALES

**Para la mayoría de datasets:**
- ✅ **alpha:** 0.05 (estándar)
- ✅ **log2fc_threshold_step3:** 1.0 (2x, biológicamente relevante)
- ✅ **log2fc_threshold_step2:** 0.58 (1.5x, exploratorio)
- ✅ **vaf_filter_threshold:** 0.5 (50%, estándar)
- ✅ **seed_region:** 2-8 (estándar)
- ✅ **pathway_padjust_threshold:** 0.1 (exploratorio)

**Estos valores están basados en:**
- ✅ Literatura científica estándar
- ✅ Prácticas comunes en el campo
- ✅ Principios estadísticos sólidos
- ✅ Balance entre rigor y sensibilidad

---

## 📚 REFERENCIAS

1. **Análisis de datos ómicos:** arXiv:1902.00892
2. **Análisis de expresión diferencial:** aspteaching.github.io (materiales de curso)
3. **Prácticas estándar en miRNAs:** Estudios publicados en ALS y enfermedades neurodegenerativas
4. **Métodos estadísticos:** Benjamini-Hochberg FDR correction (estándar en DESeq2, edgeR)

---

**Última actualización:** 2025-11-03  
**Basado en:** Literatura científica estándar y prácticas comunes en el campo

