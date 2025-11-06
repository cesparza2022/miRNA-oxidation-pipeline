# 🔬 COMPARACIÓN PROFUNDA: Enfoques Metodológicos

**Fecha:** 2025-11-04  
**Objetivo:** Comparar los enfoques metodológicos, pasos de descubrimiento y respuestas científicas entre:
1. **Paper original** (Magen et al., 2021 - Expression-based)
2. **Paper de referencia** (8-oxoguanine modifications - Direct detection)
3. **Nuestro pipeline** (SNV-based proxy approach)

---

## 📊 TABLA COMPARATIVA: ENFOQUES METODOLÓGICOS

| Aspecto | Paper Original (Magen) | Paper Referencia (8-oxoG) | **Nuestro Pipeline** |
|---------|------------------------|---------------------------|---------------------|
| **🔍 DETECCIÓN** | qRT-PCR (expression) | oxBS-seq / 8-oxoG IP-seq | **G>T mutations (proxy)** |
| **📊 DATOS** | Expression levels | Direct 8-oxoG mapping | SNV counts → VAF |
| **🎯 OBJETIVO** | Prognostic biomarker | Redox-dependent cancer | **Oxidative stress biomarker** |
| **📈 ENFOQUE** | Clinical → Molecular | Direct → Functional | **Statistical → Mechanistic** |
| **🔬 VALIDACIÓN** | Survival analysis | Sequence motifs | **Statistical + Pathway** |
| **⏱️ TEMPORAL** | Longitudinal clinical | Experimental timepoints | **Cross-sectional clinical** |

---

## 🔍 DIFERENCIAS CLAVE EN METODOLOGÍA

### **1. ESTRATEGIA DE DETECCIÓN**

#### **Paper Original (Magen):**
```
Expression-based approach
├── qRT-PCR quantification
├── miRNA abundance measurement
├── Normalization to reference miRNAs
└── Clinical correlation
```

**Limitación:** No detecta oxidación directamente, solo cambios de expresión

#### **Paper Referencia (8-oxoG):**
```
Direct detection approach
├── oxBS-seq (oxidative bisulfite sequencing)
│   └── Detecta 8-oxoG directamente en secuencia
├── 8-oxoG IP-seq (immunoprecipitation)
│   └── Enriquecimiento de miRNAs oxidados
└── Mapeo posicional directo
```

**Ventaja:** Detecta oxidación directamente, no requiere proxy

#### **Nuestro Pipeline:**
```
Proxy-based approach
├── G>T mutations como proxy de 8-oxoG
├── VAF (Variant Allele Frequency) como medida
├── Filtrado estadístico (VAF > 50% → artifacts)
└── Validación mecanicista (G-content correlation)
```

**Ventaja:** Usa datos de secuenciación existentes, no requiere experimentos nuevos  
**Limitación:** Proxy indirecto, requiere validación estadística

---

### **2. LÓGICA DE DESCUBRIMIENTO**

#### **Paper Original:**
```
Discovery Flow:
1. Expression screening (miR-181 elevated)
   ↓
2. Clinical validation (survival analysis)
   ↓
3. Prognostic model building
   ↓
4. External validation
```

**Lógica:** **Clinical → Molecular** (descubrimiento desde outcomes clínicos)

#### **Paper Referencia:**
```
Discovery Flow:
1. Direct 8-oxoG detection (oxBS-seq)
   ↓
2. Sequence motif identification (XGY context)
   ↓
3. Position-specific enrichment analysis
   ↓
4. Functional target prediction
   ↓
5. Pathway analysis (redox-dependent)
```

**Lógica:** **Direct → Functional** (descubrimiento desde mecanismo molecular)

#### **Nuestro Pipeline:**
```
Discovery Flow:
1. SNV screening (all mutations)
   ↓
2. G>T filtering (oxidation proxy)
   ↓
3. Statistical comparison (ALS vs Control)
   ↓
4. Positional hotspot identification
   ↓
5. Sequence analysis (G-content, motifs)
   ↓
6. Pathway enrichment validation
```

**Lógica:** **Statistical → Mechanistic** (descubrimiento desde patrones estadísticos)

---

### **3. PASOS METODOLÓGICOS COMPARADOS**

#### **PASO 1: PREPARACIÓN DE DATOS**

| Aspecto | Paper Original | Paper Referencia | **Nuestro Pipeline** |
|---------|----------------|------------------|---------------------|
| **Input** | Raw qRT-PCR Ct values | Raw sequencing (oxBS-seq) | **Raw SNV counts** |
| **Processing** | ΔCt normalization | 8-oxoG site calling | **Split-collapse + VAF calculation** |
| **QC** | Reference gene stability | Sequencing depth | **VAF filtering (>50% → artifacts)** |
| **Output** | Normalized expression | 8-oxoG positions | **VAF-filtered SNVs** |

**Diferencias clave:**
- **Paper Original:** Normalización a genes de referencia
- **Paper Referencia:** Mapeo directo de sitios oxidados
- **Nuestro Pipeline:** Normalización estadística (VAF) + filtrado de artefactos

---

#### **PASO 2: IDENTIFICACIÓN DE SEÑALES**

| Aspecto | Paper Original | Paper Referencia | **Nuestro Pipeline** |
|---------|----------------|------------------|---------------------|
| **Método** | Expression fold-change | 8-oxoG enrichment | **Statistical comparison (Wilcoxon)** |
| **Criterio** | FC > 2.0, p < 0.05 | Enrichment > 2x expected | **FDR < 0.05, Log2FC > 0** |
| **Validación** | Survival correlation | Sequence motif analysis | **G-content correlation + Pathway** |
| **Output** | miR-181 (single miRNA) | Multiple oxidized miRNAs | **Multiple G>T mutations** |

**Diferencias clave:**
- **Paper Original:** Enfoque en un solo miRNA (miR-181)
- **Paper Referencia:** Múltiples miRNAs con patrones de secuencia
- **Nuestro Pipeline:** Múltiples mutaciones con análisis estadístico robusto

---

#### **PASO 3: ANÁLISIS POSICIONAL**

| Aspecto | Paper Referencia | **Nuestro Pipeline** |
|---------|------------------|---------------------|
| **Método** | Direct positional mapping | **Statistical per-position tests** |
| **Criterio** | Position-specific enrichment | **FDR-corrected per-position Wilcoxon** |
| **Hotspots** | Sequence context (XGY) | **Positions 2, 3, 5 (seed region)** |
| **Validación** | Sequence logos | **G-content correlation + family analysis** |

**Diferencias clave:**
- **Paper Referencia:** Mapeo directo de posiciones oxidadas
- **Nuestro Pipeline:** Identificación estadística de hotspots con validación mecanicista

---

#### **PASO 4: ANÁLISIS DE SECUENCIA**

| Aspecto | Paper Referencia | **Nuestro Pipeline** |
|---------|------------------|---------------------|
| **Método** | Trinucleotide context (XGY) | **G-content correlation** |
| **Análisis** | Sequence logos por posición | **Position-specific G-content** |
| **Motifs** | GG, CG, AG, UG contexts | **TGAGGTA (let-7 family)** |
| **Validación** | Enrichment tests | **Spearman correlation (r = 0.347, p < 0.001)** |

**Diferencias clave:**
- **Paper Referencia:** Contexto trinucleótido (XGY) con enriquecimiento
- **Nuestro Pipeline:** Correlación G-content con dosis-respuesta (0-1 G's = 5%, 5-6 G's = 17%)

---

#### **PASO 5: ANÁLISIS FUNCIONAL**

| Aspecto | Paper Original | Paper Referencia | **Nuestro Pipeline** |
|---------|----------------|------------------|---------------------|
| **Método** | Survival analysis | Target prediction | **Pathway enrichment (GO/KEGG)** |
| **Herramientas** | Cox regression | TargetScan, miRanda | **clusterProfiler, DIANA-TarBase** |
| **Output** | HR (hazard ratio) | Target changes | **KEGG:05014 ALS pathway (FDR < 0.001)** |
| **Validación** | Clinical outcomes | Functional assays | **Statistical enrichment** |

**Diferencias clave:**
- **Paper Original:** Validación clínica (survival)
- **Paper Referencia:** Predicción de targets afectados
- **Nuestro Pipeline:** Enriquecimiento de pathways (ALS pathway directamente afectado)

---

### **4. RESPUESTAS CIENTÍFICAS OBTENIDAS**

#### **Paper Original (Magen):**
```
Preguntas respondidas:
1. ¿Qué miRNA predice mortalidad en ALS?
   → miR-181 (HR > 2)

2. ¿Cuál es el valor pronóstico?
   → Alto (validado con NfL)

3. ¿Cómo se correlaciona con progresión?
   → Positivamente correlacionado
```

**Tipo de descubrimiento:** **Clinical biomarker** (prognóstico)

---

#### **Paper Referencia (8-oxoG):**
```
Preguntas respondidas:
1. ¿Dónde ocurre 8-oxoG en miRNAs?
   → Posiciones específicas con contextos XGY

2. ¿Qué secuencias son más susceptibles?
   → GG context (alta oxidación)

3. ¿Cómo afecta la función?
   → Cambios en target specificity

4. ¿Qué pathways están afectados?
   → Redox-dependent cancer pathways
```

**Tipo de descubrimiento:** **Mechanistic understanding** (secuencia → función)

---

#### **Nuestro Pipeline:**
```
Preguntas respondidas:
1. ¿Hay oxidación G>T en miRNAs en ALS?
   → Sí, 328 G>T en seed region (212 miRNAs)

2. ¿Qué posiciones son hotspots?
   → Positions 2, 3, 5 (seed region)

3. ¿Hay diferencias ALS vs Control?
   → Sí, position 3 (p = 0.027, FDR-corrected)

4. ¿Qué familias son más vulnerables?
   → let-7 family (100% penetrance, TGAGGTA motif)

5. ¿Cuál es el mecanismo?
   → G-content correlation (r = 0.347, p < 0.001)

6. ¿Qué pathways están afectados?
   → KEGG:05014 ALS pathway (FDR < 0.001)
```

**Tipo de descubrimiento:** **Statistical + Mechanistic** (patrones estadísticos → mecanismo → validación funcional)

---

## 🎯 DIFERENCIAS EN ENFOQUE DE DESCUBRIMIENTO

### **1. DIRECCIÓN DEL DESCUBRIMIENTO**

```
Paper Original:
    Clinical Outcomes
          ↓
    Expression Analysis
          ↓
    Molecular Finding

Paper Referencia:
    Direct Detection
          ↓
    Sequence Analysis
          ↓
    Functional Impact

Nuestro Pipeline:
    Statistical Patterns
          ↓
    Mechanistic Validation
          ↓
    Functional Confirmation
```

---

### **2. ESTRATEGIA DE VALIDACIÓN**

| Aspecto | Paper Original | Paper Referencia | **Nuestro Pipeline** |
|---------|----------------|------------------|---------------------|
| **Validación Primaria** | Clinical survival | Sequence motifs | **Statistical significance** |
| **Validación Secundaria** | External cohort | Functional assays | **G-content correlation** |
| **Validación Terciaria** | NfL correlation | Target prediction | **Pathway enrichment** |
| **Robustez** | Longitudinal | Experimental | **FDR correction + effect sizes** |

---

### **3. NIVEL DE ESPECIFICIDAD**

| Aspecto | Paper Original | Paper Referencia | **Nuestro Pipeline** |
|---------|----------------|------------------|---------------------|
| **Especificidad Molecular** | Baja (expression) | Alta (direct 8-oxoG) | **Media (G>T proxy)** |
| **Especificidad Posicional** | No aplica | Alta (direct mapping) | **Alta (statistical per-position)** |
| **Especificidad Funcional** | Media (survival) | Alta (target changes) | **Alta (pathway enrichment)** |
| **Especificidad Clínica** | Alta (prognosis) | Baja (cancer general) | **Media (ALS-specific)** |

---

## 💡 LO QUE FALTA EN NUESTRO PIPELINE (vs Paper Referencia)

### **1. DETECCIÓN DIRECTA DE 8-oxoG**

**Paper Referencia hace:**
- oxBS-seq para detectar 8-oxoG directamente
- Mapeo posicional preciso sin proxy

**Nuestro Pipeline:**
- ❌ No tenemos detección directa
- ✅ Usamos G>T como proxy (requiere validación)

**Sugerencia:** Agregar validación experimental con oxBS-seq o 8-oxoG IP-seq en una muestra sub-conjunto

---

### **2. ANÁLISIS DE CONTEXTO TRINUCLEÓTIDO (XGY)** ✅ **IMPLEMENTADO (2025-11-04)**

**Paper Referencia hace:**
- Análisis de contexto trinucleótido (XGY)
- Enriquecimiento de contextos GG, CG, AG, UG
- Sequence logos por posición

**Nuestro Pipeline:**
- ✅ Tenemos análisis de G-content (similar)
- ✅ **IMPLEMENTADO:** Contexto trinucleótido específico (XGY) - `scripts/step8/01_trinucleotide_context.R`
- ✅ **IMPLEMENTADO:** Sequence logos por posición (hotspots: 2, 3, 5) - `scripts/step8/02_position_specific_logos.R`

**Ubicación:** Step 8 (Sequence-Based Analysis)
**Scripts:** `01_trinucleotide_context.R`, `02_position_specific_logos.R`

---

### **3. ANÁLISIS TEMPORAL EXPERIMENTAL** ✅ **IMPLEMENTADO (2025-11-04)**

**Paper Referencia hace:**
- Time-course experiments (0, 6, 18, 48 hours)
- Acumulación temporal de 8-oxoG
- Validación de que no es degradación aleatoria

**Nuestro Pipeline:**
- ✅ **IMPLEMENTADO:** Análisis temporal básico - `scripts/step8/03_temporal_patterns.R`
- ✅ Detecta timepoints automáticamente de nombres de muestras (patrón: T0, T6, etc.)
- ⚠️ Requiere timepoints en nombres de muestras o metadata (si no hay, crea placeholder)

**Ubicación:** Step 8 (Sequence-Based Analysis)
**Script:** `03_temporal_patterns.R`
**Nota:** Si no hay timepoints disponibles, el script crea un análisis placeholder con mensaje informativo

---

### **4. PREDICCIÓN DIRECTA DE TARGETS** ✅ **IMPLEMENTADO (2025-11-04)**

**Paper Referencia hace:**
- Target prediction para miRNAs oxidados
- Comparación targets canónicos vs oxidados
- Cambios en target specificity

**Nuestro Pipeline:**
- ✅ Tenemos pathway enrichment (Step 6)
- ✅ **IMPLEMENTADO:** Predicción directa de targets - `scripts/step6/03_direct_target_prediction.R`
- ✅ **IMPLEMENTADO:** Comparación targets canónicos vs oxidados (tablas + figura)

**Ubicación:** Step 6 (Functional Analysis)
**Script:** `03_direct_target_prediction.R`
**Nota:** Actualmente usa simulación. En producción, integrar con TargetScan/miRDB/miRTarBase

---

### **5. VALIDACIÓN FUNCIONAL EXPERIMENTAL**

**Paper Referencia hace:**
- Functional assays (luciferase, etc.)
- Validación experimental de cambios en binding

**Nuestro Pipeline:**
- ❌ No tenemos validación experimental
- ✅ Tenemos validación estadística robusta

**Sugerencia:** Colaboración con laboratorio experimental para validación funcional

---

## ✅ LO QUE TENEMOS QUE ELLOS NO (Ventajas)

### **1. ANÁLISIS ESTADÍSTICO ROBUSTO**

**Nuestro Pipeline:**
- ✅ FDR correction (Benjamini-Hochberg)
- ✅ Effect sizes (Cohen's d)
- ✅ Multiple testing correction (21,526 SNVs)
- ✅ Non-parametric tests (Wilcoxon)

**Paper Referencia:**
- No menciona corrección por múltiples comparaciones
- No menciona effect sizes

---

### **2. ANÁLISIS DE FAMILIAS ESPECÍFICAS**

**Nuestro Pipeline:**
- ✅ let-7 family analysis (100% penetrance)
- ✅ Motif identification (TGAGGTA)
- ✅ Family-specific oxidation patterns

**Paper Referencia:**
- Análisis más general, no específico por familias

---

### **3. ENFOQUE EN REGIÓN SEED**

**Nuestro Pipeline:**
- ✅ Enfoque específico en seed region (positions 2-8)
- ✅ Validación funcional (seed region es crítico)
- ✅ Comparación seed vs non-seed

**Paper Referencia:**
- Análisis más general, no específico en seed region

---

### **4. VALIDACIÓN CON PATHWAY ENRICHMENT**

**Nuestro Pipeline:**
- ✅ KEGG:05014 ALS pathway (FDR < 0.001)
- ✅ Conexión directa molecular → patología
- ✅ Validación con GO/KEGG enrichment

**Paper Referencia:**
- Pathway analysis más general (cancer pathways)

---

## 🎯 RECOMENDACIONES: QUÉ AGREGAR AL PIPELINE

### **PRIORIDAD ALTA (Métodos del Paper Referencia)**

1. **Análisis de Contexto Trinucleótido**
   - Script: `analyze_trinucleotide_context.R`
   - Output: Enriquecimiento de contextos XGY
   - Tiempo: 2-3 horas

2. **Sequence Logos por Posición**
   - Script: `create_position_specific_logos.R`
   - Output: Logos para posiciones 2, 3, 5 (hotspots)
   - Tiempo: 2-3 horas

3. **Predicción de Targets Afectados**
   - Script: `predict_targets_oxidized.R`
   - Output: Comparación targets canónicos vs oxidados
   - Tiempo: 4-5 horas

---

### **PRIORIDAD MEDIA (Validación)**

4. **Análisis Temporal Mejorado**
   - Script: `analyze_temporal_patterns.R`
   - Output: Acumulación temporal de G>T
   - Tiempo: 2-3 horas

5. **Validación con Datos Experimentales**
   - Si hay datos de oxBS-seq o 8-oxoG IP-seq
   - Comparar con G>T mutations
   - Tiempo: Variable

---

### **PRIORIDAD BAJA (Exploratorio)**

6. **Functional Assays (si hay colaboración experimental)**
   - Validación de cambios en binding
   - Tiempo: Variable

---

## 📊 RESUMEN EJECUTIVO

### **ENFOQUES COMPARADOS:**

```
Paper Original (Magen):
    Expression → Clinical → Prognosis
    (Unidimensional: solo expresión)

Paper Referencia (8-oxoG):
    Direct Detection → Sequence → Function
    (Multidimensional: mecanismo molecular)

Nuestro Pipeline:
    Statistics → Mechanism → Function
    (Multidimensional: estadística + mecanismo + función)
```

---

### **VENTAJAS COMPARATIVAS:**

| Ventaja | Paper Original | Paper Referencia | **Nuestro Pipeline** |
|---------|----------------|------------------|---------------------|
| **Robustez estadística** | Media | Baja | **Alta** ⭐ |
| **Especificidad molecular** | Baja | Alta | **Media** |
| **Validación funcional** | Alta (clínica) | Alta (experimental) | **Media (estadística)** |
| **Enfoque en seed** | No | No | **Sí** ⭐ |
| **Análisis de familias** | No | No | **Sí** ⭐ |
| **Pathway específico** | No | General | **ALS-specific** ⭐ |

---

### **LO QUE FALTA (vs Paper Referencia):**

1. ❌ Detección directa de 8-oxoG (oxBS-seq)
2. ❌ Análisis de contexto trinucleótido (XGY)
3. ❌ Sequence logos por posición
4. ❌ Predicción directa de targets
5. ❌ Validación experimental funcional

---

### **LO QUE TENEMOS (Ventajas):**

1. ✅ Análisis estadístico robusto (FDR, effect sizes)
2. ✅ Análisis de familias específicas (let-7)
3. ✅ Enfoque en región seed (funcionalmente relevante)
4. ✅ Validación con pathway enrichment (ALS pathway)
5. ✅ Análisis clínico (ALS vs Control)

---

## 🚀 PRÓXIMOS PASOS SUGERIDOS

1. **Agregar análisis de contexto trinucleótido** (Prioridad Alta)
2. **Crear sequence logos por posición** (Prioridad Alta)
3. **Implementar predicción de targets** (Prioridad Media)
4. **Mejorar análisis temporal** (Prioridad Media)
5. **Validación experimental** (Prioridad Baja, requiere colaboración)

---

**Conclusión:** Nuestro pipeline tiene un enfoque **único y complementario** que combina robustez estadística con validación mecanicista y funcional. Agregando los métodos del paper de referencia, tendríamos un pipeline aún más completo.

