# 📚 GLOSARIO COMPLETO: STEP 3 - Análisis Funcional

**Versión:** 1.0  
**Fecha:** 2025-11-03  
**Propósito:** Documentación completa de qué datos se usan, cómo se procesan y qué preguntas responden las figuras

---

## 📊 DATOS DE ENTRADA

### **Archivo Principal:**
- **Input:** `results/step2/final/tables/statistical_results/S2_statistical_comparisons.csv`

### **Filtros Aplicados:**
```r
# 1. Solo mutaciones G>T
filter(str_detect(pos.mut, ":GT$"))

# 2. Solo significativas (FDR < 0.05)
filter(t_test_fdr < 0.05 | wilcoxon_fdr < 0.05)

# 3. Solo con mayor oxidación en ALS (log2FC > 0)
filter(log2_fold_change > 0)

# 4. Solo en seed region (posiciones 2-8)
mutate(position = as.numeric(str_extract(pos.mut, "^\\d+")))
filter(position >= 2 & position <= 8)
```

### **Resultado del Filtrado:**
- **Total de SNVs analizados:** ~68,968 (del Step 2)
- **G>T mutations significativas en seed:** 260
- **miRNAs únicos afectados:** 68

---

## 🔬 SCRIPT 1: Functional Target Analysis

### **¿Qué Datos Usa?**

**Input:**
- `S2_statistical_comparisons.csv` con columnas:
  - `miRNA_name`: Nombre del miRNA (ej: "hsa-miR-219a-2-3p")
  - `pos.mut`: Posición y mutación (ej: "7:GT")
  - `ALS_mean`: Media de oxidación en grupo ALS
  - `Control_mean`: Media de oxidación en grupo Control
  - `log2_fold_change`: Log2 fold change (ALS/Control)
  - `t_test_fdr`: FDR-adjusted p-value (t-test)

**Procesamiento:**
```r
# 1. Extrae posición de la mutación
position = as.numeric(str_extract(pos.mut, "^\\d+"))

# 2. Calcula Functional Impact Score
functional_impact_score = abs(log2_fold_change) × (-log10(t_test_fdr + 1e-10))

# 3. Categoriza impacto por posición
binding_impact = case_when(
  position <= 3 ~ "Critical",    # Posiciones 2-3: más críticas
  position <= 5 ~ "High",         # Posiciones 4-5: alto impacto
  TRUE ~ "Moderate"               # Posiciones 6-8: impacto moderado
)
```

**Outputs Generados:**

#### **1. S3_target_analysis.csv**
**Columnas:**
- `miRNA_name`: Nombre del miRNA
- `pos.mut`: Posición y mutación
- `position`: Posición numérica (2-8)
- `ALS_mean`: Media en grupo ALS
- `Control_mean`: Media en grupo Control
- `log2_fold_change`: Fold change en log2
- `t_test_fdr`: FDR-adjusted p-value
- `canonical_targets`: Targets canónicos (simulado)
- `oxidized_targets`: Targets oxidados (simulado)
- `binding_impact`: Critical/High/Moderate
- `functional_impact_score`: Score calculado

**Ejemplo de fila:**
```
miRNA_name: hsa-miR-219a-2-3p
pos.mut: 7:GT
position: 7
ALS_mean: 181.88
Control_mean: 2.40
log2_fold_change: 6.25
functional_impact_score: 26.68
binding_impact: Moderate
```

#### **2. S3_als_relevant_genes.csv**
**Columnas:**
- `miRNA_name`: Nombre del miRNA
- `pos.mut`: Posición y mutación
- `position`: Posición numérica
- `functional_impact_score`: Score de impacto funcional
- `potential_als_targets`: Genes ALS potencialmente afectados
- `als_genes_count`: Número de genes ALS afectados

**Genes ALS Incluidos (23 genes):**
```
SOD1, TARDBP, FUS, C9ORF72, OPTN, UBQLN2, PFN1, DCTN1,
VCP, MATR3, CHCHD10, TBK1, NEK1, C21orf2, CCNF, TIA1,
TUBA4A, ANXA11, KIF5A, ERBB4, HSPB1, NEFH, CHMP2B
```

**Lógica de Asignación:**
- miRNAs con "miR-16|miR-15|let-7" → Primeros 5 genes
- miRNAs con "miR-1|miR-206" → Genes 6-10
- Otros → "Multiple" (todos los genes)

#### **3. S3_target_comparison.csv**
**Columnas:**
- `miRNA_name`: Nombre del miRNA
- `n_mutations`: Número de mutaciones por miRNA
- `positions`: Posiciones afectadas (ej: "6,7,8")
- `avg_log2FC`: Log2 fold change promedio
- `max_impact_position`: Posición con mayor impacto
- `canonical_targets_estimate`: Número estimado de targets canónicos
- `oxidized_targets_estimate`: Número estimado de targets oxidados
- `gained_targets_estimate`: Número estimado de targets ganados
- `net_target_change`: Cambio neto (oxidized - canonical)

---

## 🔬 SCRIPT 2: Pathway Enrichment Analysis

### **¿Qué Datos Usa?**

**Input:**
- `S3_target_analysis.csv` (del Script 1)

**Procesamiento:**
1. **GO Enrichment:** Genera datos simulados pero realistas de enriquecimiento GO
2. **KEGG Enrichment:** Genera datos de enriquecimiento KEGG
3. **Filtrado:** Identifica vías específicas de ALS

**Outputs Generados:**

#### **1. S3_go_enrichment.csv**
**Columnas:**
- `GO_ID`: ID del término GO (ej: "GO:0007399")
- `Description`: Descripción del término
- `GeneRatio`: Ratio de genes observados
- `BgRatio`: Ratio de genes en el background
- `pvalue`: p-value sin ajustar
- `p.adjust`: p-value ajustado (FDR)
- `qvalue`: q-value
- `Count`: Número de genes en el término
- `RichFactor`: Factor de enriquecimiento (GeneRatio / BgRatio)
- `Significance`: ***/**/*/ns según p.adjust

**Top 3 GO Terms Típicos:**
1. "nervous system development" (RichFactor ~10.7)
2. "mRNA processing" (RichFactor ~7.2)
3. "autophagy" (RichFactor ~1.5)

#### **2. S3_kegg_enrichment.csv**
**Columnas:**
- `Pathway_ID`: ID KEGG (ej: "KEGG:05014")
- `Pathway_Name`: Nombre de la vía
- `GeneRatio`, `BgRatio`, `pvalue`, `p.adjust`, etc. (igual que GO)

**Vías ALS Relevantes Incluidas:**
- Amyotrophic lateral sclerosis (KEGG:05014)
- Protein processing in endoplasmic reticulum
- Autophagy
- Apoptosis
- RNA transport
- RNA degradation
- Ubiquitin mediated proteolysis
- Axon guidance
- Neurotrophin signaling pathway
- MAPK signaling pathway

#### **3. S3_als_pathways.csv**
**Subconjunto de KEGG filtrado por:**
- Vías relacionadas con ALS
- Vías de autofagia/apoptosis
- Vías de procesamiento de proteínas

---

## 🎨 SCRIPT 3: Complex Functional Visualization

### **FIGURA A: Pathway Enrichment Barplot**

**Archivo:** `step3_panelA_pathway_enrichment.png`

**¿Qué Pregunta Responde?**
- "¿Qué vías biológicas están más enriquecidas en los targets de los miRNAs oxidados?"

**¿Qué Datos Usa?**
- `S3_go_enrichment.csv` (top 10 GO terms)
- `S3_kegg_enrichment.csv` (top 10 KEGG pathways)
- Combinados y ordenados por `p.adjust`
- Top 15 vías más significativas

**¿Qué Muestra?**
- Eje X: Nombre de la vía (truncado a 50 caracteres)
- Eje Y: -Log10(p.adjust) - significancia
- Color: RichFactor (intensidad de enriquecimiento)
- Orden: De más significativa a menos

**Estadísticas en Subtítulo:**
- Número de GO terms significativos (p.adj < 0.05)
- Número de KEGG pathways significativos
- Max RichFactor encontrado

**Ejemplo de Vías Mostradas:**
1. "nervous system development" (-log10 p.adj ~3.4)
2. "mRNA processing" (-log10 p.adj ~2.7)
3. "autophagy" (-log10 p.adj ~2.1)

---

### **FIGURA B: ALS-Relevant Genes Impact**

**Archivo:** `step3_panelB_als_genes_impact.png`

**¿Qué Pregunta Responde?**
- "¿Qué miRNAs tienen mayor impacto funcional en genes relevantes para ALS?"

**¿Qué Datos Usa?**
- `S3_als_relevant_genes.csv`
- Agrupado por `miRNA_name`
- Calcula:
  - `total_impact`: Suma de functional_impact_score
  - `n_als_genes`: Suma de als_genes_count
  - `avg_position`: Posición promedio
  - `n_mutations`: Número de mutaciones

**Top 20 miRNAs mostrados**

**¿Qué Muestra?**
- Eje X: Nombre del miRNA
- Eje Y: Functional Impact Score (total acumulado)
- Tamaño de burbuja: Número de genes ALS afectados
- Color: Posición promedio en seed region (azul = posiciones altas, rojo = posiciones bajas)

**Interpretación:**
- Burbujas grandes = más genes ALS afectados
- Posiciones rojas = mutaciones en posiciones más críticas (2-3)
- Alto en Y = mayor impacto funcional total

**Ejemplo:**
- hsa-miR-219a-2-3p: Impact = 26.7, ALS genes = 23, Position = 6.5

---

### **FIGURA C: Target Comparison**

**Archivo:** `step3_panelC_target_comparison.png`

**¿Qué Pregunta Responde?**
- "¿Cuántos targets se pierden cuando un miRNA se oxida comparado con su forma canónica?"

**¿Qué Datos Usa?**
- `S3_target_comparison.csv`
- Top 15 miRNAs (ordenados por `avg_log2FC`)
- Transformación a formato largo (pivot_longer):
  - `canonical_targets_estimate` → "Canonical"
  - `oxidized_targets_estimate` → "Oxidized (G>T)"

**¿Qué Muestra?**
- Eje X: Nombre del miRNA
- Eje Y: Número de targets predichos
- Dos barras por miRNA: Canonical (gris) vs Oxidized (rojo)
- Posición: "dodge" (lado a lado)

**Estadísticas en Subtítulo:**
- Promedio de targets canónicos
- Promedio de targets oxidados
- Promedio de pérdida (canonical - oxidized)

**Interpretación:**
- Si la barra roja es más baja que la gris = pérdida de targets
- Diferencia grande = alto impacto funcional

---

### **FIGURA D: Position-Specific Impact**

**Archivo:** `step3_panelD_position_impact.png`

**¿Qué Pregunta Responde?**
- "¿En qué posiciones del miRNA tiene mayor impacto funcional la oxidación?"

**¿Qué Datos Usa?**
- `S3_target_analysis.csv`
- Agrupado por `position` (1-23)
- Calcula:
  - `n_mutations`: Número de mutaciones por posición
  - `total_impact`: Suma de functional_impact_score por posición
  - `avg_impact`: Impacto promedio
  - `n_unique_mirnas`: miRNAs únicos afectados

**¿Qué Muestra?**
- Eje X: Posición en miRNA (1-23)
- Eje Y: Total Functional Impact Score (acumulado)
- Barras: Impacto total por posición (color rojo)
- Puntos superpuestos: Tamaño = número de mutaciones
- Región sombreada: Seed region (posiciones 2-8)

**Estadísticas en Subtítulo:**
- Ratio de impacto seed vs non-seed
- Número de posiciones en seed region

**Interpretación:**
- Barras altas = mayor impacto funcional acumulado
- Puntos grandes = más mutaciones en esa posición
- Seed region typically tiene mayor impacto

---

## 📋 RESUMEN DE MUTACIONES Y miRNAs ANALIZADOS

### **Top 10 miRNAs con Mayor Impacto Funcional:**

1. **hsa-miR-219a-2-3p**
   - Mutaciones: 7:GT, 6:TC,13:GT
   - Functional Impact Score: 26.68
   - Posición: 6-7 (Moderate)
   - Genes ALS: 23 (Multiple)

2. **hsa-miR-196a-5p**
   - Mutaciones: 8:TC,22:GT, 7:GT, 6:AG,22:GT, 8:TA,22:GT
   - Functional Impact Score: 26.12
   - Posición: 6-8 (Moderate)
   - Genes ALS: 23 (Multiple)

3. **hsa-miR-9-3p**
   - Mutaciones: 6:GT
   - Functional Impact Score: 23.21
   - Posición: 6 (Moderate)
   - Genes ALS: 23 (Multiple)

4. **hsa-miR-127-3p**
   - Mutaciones: 4:GT, 6:TC,20:GT
   - Functional Impact Score: 21.66
   - Posición: 4, 6 (High/Moderate)
   - Genes ALS: 23 (Multiple)

### **Distribución por Posición:**

| Posición | N Mutaciones | Impacto Total | miRNAs Únicos |
|----------|--------------|---------------|---------------|
| 2        | X            | Y             | Z             |
| 3        | X            | Y             | Z             |
| ...      | ...          | ...           | ...           |
| 8        | X            | Y             | Z             |

*(Los valores exactos se generan en cada ejecución)*

---

## 🔍 GLOSARIO DE TÉRMINOS

### **Functional Impact Score:**
- **Fórmula:** `abs(log2_fold_change) × (-log10(t_test_fdr + 1e-10))`
- **Interpretación:** Mide la magnitud del cambio (log2FC) ponderado por la significancia estadística
- **Unidades:** Adimensional (mayor = mayor impacto)
- **Ejemplo:** log2FC = 6.25, p.adj = 5.34e-5 → Score = 26.68

### **Binding Impact:**
- **Critical:** Posiciones 2-3 (más críticas para unión a targets)
- **High:** Posiciones 4-5 (alto impacto)
- **Moderate:** Posiciones 6-8 (impacto moderado)

### **RichFactor:**
- **Fórmula:** `GeneRatio / BgRatio`
- **Interpretación:** Cuántas veces más enriquecido que el esperado
- **Ejemplo:** RichFactor = 10.7 → 10.7x más enriquecido que el background

### **Seed Region:**
- **Definición:** Posiciones 2-8 del miRNA
- **Importancia:** Región más crítica para reconocimiento de targets
- **Color en figuras:** Sombreado azul claro (#e3f2fd)

### **Canonical vs Oxidized Targets:**
- **Canonical:** Targets predichos para la secuencia canónica del miRNA
- **Oxidized:** Targets predichos para la secuencia con G>T mutation
- **Diferencia:** Muestra pérdida/ganancia de especificidad

---

## ⚠️ NOTAS IMPORTANTES

### **Limitaciones Actuales:**

1. **Target Prediction:** Actualmente simulado
   - En producción: usar TargetScan, miRDB, multiMiR

2. **Pathway Enrichment:** Actualmente simulado
   - En producción: usar clusterProfiler, enrichR, g:Profiler

3. **ALS Genes:** Lista manual de 23 genes
   - En producción: usar DisGeNET, ALSoD, bases de datos actualizadas

### **Datos Reales vs Simulados:**

- ✅ **Reales:**
  - miRNAs afectados
  - Posiciones de mutaciones
  - Log2 fold changes
  - p-values y FDR
  - Functional Impact Scores

- ⚠️ **Simulados (estructura lista para reemplazar):**
  - Predicción de targets
  - Enriquecimiento de vías (valores exactos)
  - Asignación genes ALS a miRNAs

---

**Última actualización:** 2025-11-03  
**Versión:** 1.0

