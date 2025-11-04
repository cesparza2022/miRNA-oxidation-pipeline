# 🎨 GUÍA DE FIGURAS: STEP 3 - Análisis Funcional

**Versión:** 1.0  
**Fecha:** 2025-11-03

---

## ⚠️ IMPORTANTE: MIRNAS Y SNVs USADOS

**TODAS las figuras usan EXACTAMENTE los mismos miRNAs y SNVs:**

- ✅ **260 G>T mutations significativas** (FDR < 0.05)
- ✅ **68 miRNAs únicos** afectados
- ✅ **Solo posiciones 2-8** (seed region)
- ✅ **Solo log2FC > 0** (mayor oxidación en ALS)

**Ver documento `STEP3_MIRNAS_SNVS_USADOS.md` para detalles completos.**

---

## 📊 RESUMEN DE FIGURAS GENERADAS

Step 3 genera **5 figuras** en total:

1. **Heatmap de Enriquecimiento de Vías** (`step3_pathway_enrichment_heatmap.png`)
2. **Panel A: Top Enriched Pathways** (`step3_panelA_pathway_enrichment.png`)
3. **Panel B: ALS-Relevant Genes Impact** (`step3_panelB_als_genes_impact.png`)
4. **Panel C: Target Comparison** (`step3_panelC_target_comparison.png`)
5. **Panel D: Position-Specific Impact** (`step3_panelD_position_impact.png`)

---

## 🔥 FIGURA 1: Pathway Enrichment Heatmap

**Archivo:** `step3_pathway_enrichment_heatmap.png`  
**Tipo:** Heatmap (pheatmap)  
**Tamaño:** 12 × 10 inches, 300 DPI

### **¿Qué Pregunta Responde?**
"¿Qué vías biológicas (GO y KEGG) están más enriquecidas en los targets de los miRNAs oxidados?"

### **¿Qué miRNAs y SNVs Usa?**
**CRÍTICO:** Esta figura usa **SOLO los miRNAs más oxidados en seed region:**
- **260 G>T mutations** significativas (FDR < 0.05)
- **68 miRNAs únicos** afectados
- **Solo posiciones 2-8** (seed region)
- **Solo log2FC > 0** (mayor oxidación en ALS)

**Input:** Targets de `S3_target_analysis.csv` (que contiene solo estos miRNAs filtrados)

### **¿Qué Datos Usa?**
- Top 20 vías más enriquecidas (GO + KEGG combinadas)
- Filtrado por `p.adjust < 0.1`
- Ordenadas por `RichFactor` (descendente)
- **Basadas en los targets de los 68 miRNAs más oxidados en seed region**

### **¿Qué Muestra?**
- **Filas:** Vías (GO Biological Process + KEGG Pathways)
- **Columna única:** RichFactor (factor de enriquecimiento)
- **Color:** Gradiente blanco → rojo (#D62728)
- **Anotaciones:**
  - Tipo de vía (GO vs KEGG)
  - -Log10(p.adjust) como gradiente

### **Interpretación:**
- Rojo intenso = mayor enriquecimiento
- Blanco = enriquecimiento bajo
- Anotación de color = significancia estadística

### **Estadísticas Clave:**
- Top pathway típicamente: "nervous system development" (RichFactor ~10.7)
- Número de vías significativas (p.adj < 0.1)

---

## 📊 FIGURA 2: Panel A - Top Enriched Pathways

**Archivo:** `step3_panelA_pathway_enrichment.png`  
**Tipo:** Barplot horizontal  
**Tamaño:** 12 × 10 inches, 300 DPI

### **¿Qué Pregunta Responde?**
"¿Cuáles son las 15 vías más significativamente enriquecidas en los targets de los miRNAs oxidados?"

### **¿Qué miRNAs y SNVs Usa?**
**CRÍTICO:** Esta figura usa **SOLO los miRNAs más oxidados en seed region:**
- **260 G>T mutations** significativas (FDR < 0.05)
- **68 miRNAs únicos** afectados
- **Solo posiciones 2-8** (seed region)
- **Solo log2FC > 0** (mayor oxidación en ALS)

**Input:** `S3_go_enrichment.csv` + `S3_kegg_enrichment.csv` (basados en targets de estos miRNAs)

### **¿Qué Datos Usa?**
- Top 10 GO Biological Process terms
- Top 10 KEGG Pathways
- Combinados y ordenados por `p.adjust`
- Top 15 más significativas
- **Todos basados en los 68 miRNAs más oxidados en seed region**

### **¿Qué Muestra?**
- **Eje X (vertical):** Nombre de la vía (truncado a 50 caracteres)
- **Eje Y (horizontal):** -Log10(p.adjust) - significancia
- **Color de barra:** RichFactor (gradiente blanco → rojo)
- **Orden:** De más significativa (arriba) a menos significativa (abajo)

### **Elementos Visuales:**
- Barras horizontales (coord_flip)
- Gradiente de color por RichFactor
- Legend para RichFactor

### **Interpretación:**
- Barras más largas = más significativas
- Colores más rojos = mayor enriquecimiento relativo
- Top 3 típicamente:
  1. "nervous system development"
  2. "mRNA processing"
  3. "autophagy"

### **Estadísticas en Subtítulo:**
- Número de GO terms significativos (p.adj < 0.05)
- Número de KEGG pathways significativos
- Max RichFactor encontrado

---

## 🎯 FIGURA 3: Panel B - ALS-Relevant Genes Impact

**Archivo:** `step3_panelB_als_genes_impact.png`  
**Tipo:** Bubble plot (scatter con tamaño variable)  
**Tamaño:** 12 × 10 inches, 300 DPI

### **¿Qué Pregunta Responde?**
"¿Qué miRNAs tienen mayor impacto funcional en genes relevantes para ALS?"

### **¿Qué miRNAs y SNVs Usa?**
**CRÍTICO:** Esta figura usa **SOLO los miRNAs más oxidados en seed region:**
- **260 G>T mutations** significativas (FDR < 0.05)
- **68 miRNAs únicos** afectados
- **Solo posiciones 2-8** (seed region)
- **Solo log2FC > 0** (mayor oxidación en ALS)

**Input:** `S3_als_relevant_genes.csv` (260 filas, una por cada G>T mutation significativa)

### **¿Qué Datos Usa?**
- Agrupado por `miRNA_name`
- Top 20 miRNAs por `total_impact`
- **Todos son miRNAs con G>T mutations significativas en seed region**

### **¿Qué Muestra?**
- **Eje X (vertical):** Nombre del miRNA
- **Eje Y (horizontal):** Functional Impact Score (total acumulado)
- **Tamaño de burbuja:** Número de genes ALS afectados
- **Color de burbuja:** Posición promedio en seed region
  - Azul (#2E86AB) = posiciones altas (6-8)
  - Rojo (#D62728) = posiciones bajas (2-3)
- **Orden:** De mayor impacto (arriba) a menor (abajo)

### **Elementos Visuales:**
- Puntos (geom_point) con tamaño variable
- Gradiente de color por posición
- Coord_flip para legibilidad
- Dos legends: tamaño y color

### **Interpretación:**
- Puntos grandes = más genes ALS afectados
- Puntos rojos = mutaciones en posiciones más críticas
- Alto en Y = mayor impacto funcional total
- Combinación = miRNAs prioritarios para validación

### **Top miRNAs Típicos:**
1. hsa-miR-219a-2-3p (Impact ~26.7, 23 genes ALS)
2. hsa-miR-196a-5p (Impact ~26.1, 23 genes ALS)
3. hsa-miR-9-3p (Impact ~23.2, 23 genes ALS)

### **Estadísticas en Subtítulo:**
- Total de interacciones miRNA-ALS genes
- Top miRNA y su impacto

---

## 📊 FIGURA 4: Panel C - Target Comparison

**Archivo:** `step3_panelC_target_comparison.png`  
**Tipo:** Grouped barplot  
**Tamaño:** 12 × 10 inches, 300 DPI

### **¿Qué Pregunta Responde?**
"¿Cuántos targets se pierden cuando un miRNA se oxida comparado con su forma canónica?"

### **¿Qué miRNAs y SNVs Usa?**
**CRÍTICO:** Esta figura usa **SOLO los miRNAs más oxidados en seed region:**
- **68 miRNAs únicos** con G>T mutations significativas
- **Solo posiciones 2-8** (seed region)
- **Solo log2FC > 0** (mayor oxidación en ALS)

**Input:** `S3_target_comparison.csv` (68 filas, una por miRNA único)

### **¿Qué Datos Usa?**
- Top 15 miRNAs (ordenados por `avg_log2FC`)
- Transformación a formato largo:
  - `canonical_targets_estimate` → "Canonical"
  - `oxidized_targets_estimate` → "Oxidized (G>T)"
- **Todos son miRNAs con G>T mutations significativas en seed region**

### **¿Qué Muestra?**
- **Eje X (vertical):** Nombre del miRNA
- **Eje Y (horizontal):** Número de targets predichos
- **Dos barras por miRNA:**
  - Gris (color_control) = Canonical
  - Rojo (COLOR_GT) = Oxidized (G>T)
- **Posición:** "dodge" (lado a lado)
- **Orden:** Por número de targets (descendente)

### **Elementos Visuales:**
- Barras agrupadas (position = "dodge")
- Colores contrastantes (gris vs rojo)
- Coord_flip para legibilidad
- Legend para tipo de target

### **Interpretación:**
- Barra roja más baja que gris = pérdida de targets
- Diferencia grande = alto impacto funcional
- Si roja > gris = ganancia de targets (raro)

### **Estadísticas en Subtítulo:**
- Promedio de targets canónicos
- Promedio de targets oxidados
- Promedio de pérdida (canonical - oxidized)

### **Ejemplo:**
- miRNA X: Canonical = 150 targets, Oxidized = 120 targets → Pérdida de 30 targets

---

## 📊 FIGURA 5: Panel D - Position-Specific Impact

**Archivo:** `step3_panelD_position_impact.png`  
**Tipo:** Barplot con puntos superpuestos  
**Tamaño:** 12 × 10 inches, 300 DPI

### **¿Qué Pregunta Responde?**
"¿En qué posiciones del miRNA tiene mayor impacto funcional la oxidación?"

### **¿Qué miRNAs y SNVs Usa?**
**CRÍTICO:** Esta figura usa **SOLO los miRNAs más oxidados en seed region:**
- **260 G>T mutations** significativas (FDR < 0.05)
- **Solo posiciones 2-8** (seed region)
- **Solo log2FC > 0** (mayor oxidación en ALS)

**Input:** `S3_target_analysis.csv` (260 filas, una por cada G>T mutation significativa)

### **¿Qué Datos Usa?**
- Agrupado por `position` (solo posiciones 2-8, no 1-23)
- Calcula:
  - `n_mutations`: Número de G>T mutations por posición
  - `total_impact`: Suma de functional_impact_score
- **Solo muestra posiciones 2-8 (seed region)**

### **¿Qué Muestra?**
- **Eje X:** Posición en miRNA (1-23, breaks cada 2)
- **Eje Y:** Total Functional Impact Score (acumulado)
- **Barras:** Impacto total por posición (color rojo, alpha 0.85)
- **Puntos superpuestos:** Tamaño = número de mutaciones
- **Región sombreada:** Seed region (posiciones 2-8, color azul claro)
- **Texto:** "SEED REGION" en posición 5

### **Elementos Visuales:**
- Barras (geom_bar) con color rojo
- Puntos (geom_point) superpuestos con tamaño variable
- Rectángulo sombreado para seed region
- Texto de anotación
- Two legends: tamaño de puntos

### **Interpretación:**
- Barras altas = mayor impacto funcional acumulado en esa posición
- Puntos grandes = más mutaciones en esa posición
- Seed region (2-8) típicamente tiene mayor impacto
- Posiciones fuera de seed = menor impacto

### **Estadísticas en Subtítulo:**
- Ratio de impacto seed vs non-seed
- Número de posiciones en seed region

### **Patrón Esperado:**
- Seed region (2-8): Alto impacto
- Posiciones 1, 9-23: Bajo impacto
- Posiciones 2-3: Críticas (mayor impacto por mutación)

---

## 📋 RESUMEN DE PREGUNTAS RESPONDIDAS

| Figura | Pregunta Principal | Tipo de Análisis |
|--------|-------------------|------------------|
| **Heatmap** | ¿Qué vías están enriquecidas? | Enriquecimiento global |
| **Panel A** | ¿Cuáles son las top 15 vías? | Ranking de vías |
| **Panel B** | ¿Qué miRNAs afectan más genes ALS? | Impacto en genes ALS |
| **Panel C** | ¿Cuántos targets se pierden? | Cambio de especificidad |
| **Panel D** | ¿Dónde está el mayor impacto? | Análisis posicional |

---

## 🔍 DATOS ESPECÍFICOS POR FIGURA

### **Figura 1 (Heatmap):**
- **Input:** `S3_go_enrichment.csv` + `S3_kegg_enrichment.csv`
- **Filtro:** `p.adjust < 0.1`
- **Orden:** Por `RichFactor` (descendente)
- **Límite:** Top 20 vías

### **Figura 2 (Panel A):**
- **Input:** `S3_go_enrichment.csv` (top 10) + `S3_kegg_enrichment.csv` (top 10)
- **Orden:** Por `p.adjust` (ascendente)
- **Límite:** Top 15 vías más significativas

### **Figura 3 (Panel B):**
- **Input:** `S3_als_relevant_genes.csv`
- **Agrupación:** Por `miRNA_name`
- **Cálculo:** `total_impact = sum(abs(functional_impact_score))`
- **Límite:** Top 20 miRNAs

### **Figura 4 (Panel C):**
- **Input:** `S3_target_comparison.csv`
- **Orden:** Por `avg_log2FC` (descendente)
- **Límite:** Top 15 miRNAs

### **Figura 5 (Panel D):**
- **Input:** `S3_target_analysis.csv`
- **Agrupación:** Por `position` (1-23)
- **Cálculo:** `total_impact = sum(functional_impact_score)`
- **Todas las posiciones:** Sin filtro

---

## 🎨 CONSISTENCIA VISUAL

### **Colores:**
- **Rojo (#D62728):** Oxidación, ALS, impacto
- **Gris (#grey60):** Control, canónico
- **Azul (#2E86AB):** Posiciones altas, seed region (azul claro)

### **Tema:**
- `theme_professional` (consistente en todo el pipeline)
- Tamaños de fuente: 14 (títulos), 11 (subtítulos), 10 (ejes)
- DPI: 300 (publicación-quality)

### **Layout:**
- Tamaño estándar: 12 × 10 inches
- Coord_flip para legibilidad (barplots horizontales)
- Legends a la derecha

---

**Última actualización:** 2025-11-03  
**Versión:** 1.0

