# 🔬 EXPLICACIÓN DETALLADA: STEP 3 - Análisis Funcional

**Fecha:** 2025-11-03  
**Propósito:** Explicar QUÉ, CÓMO y POR QUÉ de cada componente del Step 3

---

## 🎯 OBJETIVO GENERAL

**Pregunta científica:** ¿Qué implicaciones biológicas tiene la oxidación de miRNAs en ALS?

**Respuesta:** Identificar qué genes, vías y procesos biológicos están afectados cuando los miRNAs se oxidan (G>T mutations en seed region).

---

## 📊 ESTRUCTURA DEL STEP 3

El Step 3 tiene **3 scripts principales** que se ejecutan en secuencia:

```
Step 2 (Statistical Results)
    ↓
[01] Functional Target Analysis
    ↓ (genera tablas de targets)
[02] Pathway Enrichment Analysis
    ↓ (genera tablas de enriquecimiento)
[03] Complex Functional Visualization
    ↓ (combina todo en figuras)
```

---

## 🔬 SCRIPT 1: `01_functional_target_analysis.R`

### **¿QUÉ HACE?**

Analiza los **targets** (genes diana) de los miRNAs oxidados y su impacto en genes relevantes para ALS.

### **¿CÓMO LO HACE?**

1. **Input:** Tabla de comparaciones estadísticas de Step 2
   - Filtra G>T mutations significativas en seed region (posiciones 2-8)
   - Solo considera mutations con mayor oxidación en ALS (log2FC > 0)

2. **Procesamiento:**
   ```
   Para cada miRNA oxidado:
   - Identifica la posición de la mutación
   - Estima impacto funcional (log2FC × -log10(p-value))
   - Categoriza impacto: Critical (pos 2-3), High (pos 4-5), Moderate (pos 6-8)
   - Predice targets afectados (canonical vs oxidized)
   ```

3. **Outputs generados:**
   - `S3_target_analysis.csv`: Análisis detallado de cada miRNA-target pair
   - `S3_als_relevant_genes.csv`: Genes ALS afectados por cada miRNA
   - `S3_target_comparison.csv`: Comparación targets canonical vs oxidized

### **¿POR QUÉ ES IMPORTANTE?**

- **Sin esto:** Solo sabes que hay oxidación, pero no qué genes están afectados
- **Con esto:** Puedes identificar genes específicos que podrían estar mal regulados
- **Ejemplo:** Si miR-16-5p se oxida en posición 3, puede perder su capacidad de regular SOD1 (gen ALS crítico)

### **LIMITACIÓN ACTUAL:**

⚠️ **Nota importante:** Actualmente usa una **simulación** de targets. Para producción, necesitarías:
- Integrar con **TargetScan** (predicción de targets)
- Integrar con **miRDB** (base de datos de targets validadas)
- Usar **multiMiR** (R package que integra múltiples bases de datos)

**Pero la estructura está lista para integrar datos reales.**

---

## 🔬 SCRIPT 2: `02_pathway_enrichment_analysis.R`

### **¿QUÉ HACE?**

Identifica qué **vías biológicas** (pathways) están enriquecidas en los genes diana de los miRNAs oxidados.

### **¿CÓMO LO HACE?**

1. **Input:** Tabla de targets del Script 1

2. **Procesamiento:**
   ```
   Para cada conjunto de genes diana:
   - Identifica vías GO (Gene Ontology)
   - Identifica vías KEGG
   - Calcula enriquecimiento (RichFactor = observed/expected)
   - Aplica corrección múltiple (FDR)
   ```

3. **Outputs generados:**
   - `S3_go_enrichment.csv`: Enriquecimiento GO Biological Process
   - `S3_kegg_enrichment.csv`: Enriquecimiento KEGG Pathways
   - `S3_als_pathways.csv`: Vías específicas de ALS (filtradas)
   - `step3_pathway_enrichment_heatmap.png`: **Heatmap visual** de enriquecimiento

### **¿POR QUÉ ES IMPORTANTE?**

- **Sin esto:** Sabes qué genes están afectados, pero no el contexto biológico
- **Con esto:** Puedes decir "la oxidación afecta vías de autofagia, proteostasis, y RNA processing"
- **Ejemplo:** Si múltiples miRNAs oxidados apuntan a genes de autofagia, sugiere que la autofagia está desregulada en ALS

### **LIMITACIÓN ACTUAL:**

⚠️ **Nota importante:** Actualmente genera datos **simulados** pero realistas. Para producción, necesitarías:
- Usar **clusterProfiler** (R package para enriquecimiento)
- Usar **enrichR** (múltiples bases de datos)
- O usar **g:Profiler** (comprehensivo)

**Pero la estructura y visualización están listas para datos reales.**

---

## 🎨 SCRIPT 3: `03_complex_functional_visualization.R`

### **¿QUÉ HACE?**

Crea una **figura compleja multi-panel** que integra toda la información funcional en una visualización comprehensiva.

### **¿CÓMO LO HACE?**

#### **Panel A: Top Enriched Pathways (Barplot)**

**Qué muestra:**
- Top 15 vías más enriquecidas (GO + KEGG combinadas)
- Ordenadas por significancia (-log10 p.adj)
- Color gradient por RichFactor (intensidad de enriquecimiento)

**Por qué es importante:**
- Da una visión rápida de qué procesos biológicos están más afectados
- Permite identificar patrones (¿todas las vías son de autofagia? ¿RNA processing?)

**Diseño:**
```r
ggplot(top_pathways, aes(x = reorder(Pathway, -log10(p.adj)), 
                        y = -log10(p.adj), 
                        fill = RichFactor)) +
  geom_bar(stat = "identity") +
  coord_flip()  # Horizontal para legibilidad
```

---

#### **Panel B: Impact on ALS-Relevant Genes (Bubble Plot)**

**Qué muestra:**
- Top 15 miRNAs con mayor impacto funcional
- Eje Y: Functional Impact Score
- Tamaño de burbuja: Número de genes ALS afectados
- Color: Posición promedio en seed region

**Por qué es importante:**
- Identifica qué miRNAs tienen mayor impacto en genes ALS conocidos
- Muestra relación entre posición (color) e impacto (tamaño)
- Permite priorizar miRNAs para validación experimental

**Diseño:**
```r
ggplot(als_summary, aes(x = miRNA, y = impact, 
                       size = n_als_genes, 
                       color = avg_position)) +
  geom_point() +
  coord_flip()
```

---

#### **Panel C: Target Comparison (Grouped Barplot)**

**Qué muestra:**
- Top 15 miRNAs más afectados
- Comparación: Targets canónicos vs Targets oxidados
- Muestra pérdida/ganancia de targets

**Por qué es importante:**
- Demuestra que la oxidación **cambia** la especificidad de targets
- Cuantifica cuántos targets se pierden/ganan
- Sugiere potencial de "gain-of-function" o "loss-of-function"

**Diseño:**
```r
ggplot(target_comp_long, aes(x = miRNA, y = n_targets, 
                            fill = Target_Type)) +
  geom_bar(stat = "identity", position = "dodge")
```

---

#### **Panel D: Position-Specific Functional Impact (Barplot + Points)**

**Qué muestra:**
- Impacto funcional acumulado por posición (1-23)
- Seed region shaded (posiciones 2-8)
- Puntos superpuestos: tamaño = número de mutaciones

**Por qué es importante:**
- Identifica **hotspots funcionales** (posiciones con mayor impacto)
- Muestra si el seed region tiene mayor impacto funcional
- Permite identificar posiciones críticas para experimentos

**Diseño:**
```r
ggplot(position_impact, aes(x = position, y = total_impact)) +
  annotate("rect", ...) +  # Seed region background
  geom_bar(fill = COLOR_GT) +
  geom_point(aes(size = n_mutations))  # Overlay points
```

---

### **¿POR QUÉ UNA FIGURA MULTI-PANEL?**

**Ventajas:**
1. **Información densa:** 4 paneles = 4 preguntas diferentes respondidas
2. **Cohesión visual:** Todo relacionado en una sola figura
3. **Publicación-ready:** Revistas valoran figuras comprehensivas
4. **Narrativa:** Cuenta una historia completa (pathways → genes → targets → posiciones)

**Comparación con alternativas:**
- ❌ 4 figuras separadas: Pierdes conexión visual
- ❌ 1 figura simple: Pierdes detalle
- ✅ 4 paneles integrados: Balance perfecto

---

## 🎨 DECISIONES DE DISEÑO

### **Colores:**
- `COLOR_GT` (#D62728) para ALS/oxidación (consistente con pipeline)
- `COLOR_CONTROL` (grey60) para controles/canónicos
- Gradientes para continuidad (RichFactor, posición)

### **Layout:**
- `patchwork` para combinar paneles: `(A | B) / (C | D)`
- Tamaño: 14 × 12 inches (permite detalle sin comprometer legibilidad)
- DPI: 300 (publicación-quality)

### **Anotaciones:**
- Seed region shaded en Panel D (consistente con Step 1)
- Subtítulos informativos en cada panel
- Título principal comprehensivo
- Caption con estadísticas clave

---

## 🔧 FLUJO DE DATOS

```
Step 2 (Statistical Results)
    ↓
    S2_statistical_comparisons.csv
    ├─ miRNA_name
    ├─ pos.mut
    ├─ log2_fold_change
    ├─ t_test_fdr
    └─ ...
    ↓
[Script 1] Functional Target Analysis
    ↓
    S3_target_analysis.csv
    ├─ miRNA_name
    ├─ position
    ├─ functional_impact_score
    └─ binding_impact
    ↓
[Script 2] Pathway Enrichment
    ↓
    S3_go_enrichment.csv
    ├─ GO_ID
    ├─ Description
    ├─ RichFactor
    └─ p.adjust
    ↓
[Script 3] Complex Visualization
    ↓
    step3_complex_functional_analysis.png (4 paneles)
```

---

## ⚠️ LIMITACIONES Y MEJORAS FUTURAS

### **Limitaciones actuales:**

1. **Target Prediction:** Simulado (necesita TargetScan/miRDB)
2. **Pathway Enrichment:** Simulado (necesita clusterProfiler)
3. **ALS Genes:** Lista manual (necesita base de datos actualizada)

### **Mejoras futuras:**

1. **Integrar TargetScan:**
   ```r
   library(multiMiR)
   targets <- get_multimir(mirna = "hsa-miR-16-5p", 
                          target = "all", 
                          table = "predicted")
   ```

2. **Enriquecimiento real:**
   ```r
   library(clusterProfiler)
   go_enrich <- enrichGO(gene = target_genes,
                         OrgDb = org.Hs.eg.db,
                         ont = "BP")
   ```

3. **Base de datos ALS genes:**
   - Usar DisGeNET
   - Usar ALSoD (ALS Online Database)
   - Integrar con literatura

---

## 📊 RESULTADOS ESPERADOS

### **Tablas (6):**
1. `S3_target_analysis.csv` - Análisis de targets
2. `S3_als_relevant_genes.csv` - Genes ALS afectados
3. `S3_target_comparison.csv` - Comparación canonical vs oxidized
4. `S3_go_enrichment.csv` - Enriquecimiento GO
5. `S3_kegg_enrichment.csv` - Enriquecimiento KEGG
6. `S3_als_pathways.csv` - Vías específicas ALS

### **Figuras (2):**
1. `step3_pathway_enrichment_heatmap.png` - Heatmap de vías
2. `step3_complex_functional_analysis.png` - **4 paneles integrados**

---

## ✅ VALIDACIÓN

**Para verificar que funciona:**
1. ✅ Dry-run muestra que se ejecutará correctamente
2. ⏳ Ejecutar y verificar que genera todas las tablas
3. ⏳ Verificar que las figuras se generan correctamente
4. ⏳ Revisar visualmente las figuras para calidad

---

**Última actualización:** 2025-11-03

