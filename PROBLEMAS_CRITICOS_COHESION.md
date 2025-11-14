# 🔴 PROBLEMAS CRÍTICOS DE COHESIÓN IDENTIFICADOS

**Fecha:** 2025-11-14  
**Nivel:** Revisión perfeccionista y exhaustiva  
**Enfoque:** Lógica de datos y coherencia entre figuras

---

## 🚨 PROBLEMA CRÍTICO #1: INCONSISTENCIA EN ARCHIVOS DE ENTRADA (STEP 1)

### **Descripción:**
Step 1 usa **DOS archivos diferentes** sin justificación clara:

**Archivo 1: `processed_clean.csv`**
- Usado por: Paneles B, E, F, G
- Formato: CSV con columnas `miRNA_name`, `pos.mut`, y columnas de muestras
- Estructura: Una fila por SNV (ya separado)

**Archivo 2: `raw_data` (TSV)**
- Usado por: Paneles C, D
- Formato: TSV con columnas `miRNA name`, `pos:mut` (formato con espacios y dos puntos)
- Estructura: Múltiples SNVs por fila separados por comas (necesita `separate_rows`)

### **Impacto:**
1. **Inconsistencia de datos:** ¿Son los mismos datos? ¿Hay diferencias?
2. **Procesamiento diferente:** `processed_clean` ya está procesado, `raw_data` necesita procesamiento
3. **Formato diferente:** Nombres de columnas diferentes (`miRNA_name` vs `miRNA name`, `pos.mut` vs `pos:mut`)
4. **Comparabilidad:** ¿Los resultados de Paneles C y D son comparables con B, E, F, G?

### **Preguntas críticas:**
- ¿Por qué Panel C (G>X Spectrum) usa `raw_data` pero Panel B (G>T Count) usa `processed_clean`?
- ¿Son los mismos datos o hay diferencias en el procesamiento?
- ¿Deberían todos los paneles usar el mismo archivo para consistencia?

### **Recomendación:**
1. **Verificar:** Comparar `processed_clean` y `raw_data` para confirmar que contienen los mismos datos
2. **Documentar:** Si son diferentes, explicar por qué
3. **Unificar:** Si son iguales, usar el mismo archivo para todos los paneles

---

## 🚨 PROBLEMA CRÍTICO #2: INCONSISTENCIA EN MÉTRICAS (STEP 1)

### **Descripción:**
Step 1 mezcla **dos tipos de métricas** sin consistencia:

**Métrica tipo 1: Suma de reads**
- Panel B: `total_GT_count` = suma de reads G>T por posición
- Panel E: `total_G_copies`, `GT_counts_at_position` = suma de reads
- Panel F: `total_mutations` = suma de reads por región
- Panel G: `total` = suma de reads por tipo de mutación

**Métrica tipo 2: Cuenta de SNVs únicos**
- Panel C: `count()` = cuenta de SNVs únicos G>X por posición
- Panel D: `count()` = cuenta de SNVs únicos (todas las mutaciones) por posición

### **Impacto:**
1. **No comparables:** Panel C muestra porcentajes basados en SNVs únicos, Panel G muestra porcentajes basados en suma de reads
2. **Confusión:** No está claro por qué algunos paneles usan una métrica y otros otra
3. **Inconsistencia:** Step 0 distingue claramente entre reads y SNVs, Step 1 no

### **Ejemplo de inconsistencia:**
- **Panel C:** "G>T represents X% of all G>X mutations" → Basado en **cuenta de SNVs únicos**
- **Panel G:** "Percentage of G mutation reads that are G>T" → Basado en **suma de reads**
- **¿Son comparables?** No, porque usan métricas diferentes

### **Recomendación:**
1. **Decidir:** ¿Todos los paneles deben usar la misma métrica?
2. **Documentar:** Si usan métricas diferentes, explicar por qué
3. **Aclarar:** Títulos y captions deben especificar claramente qué métrica se usa

---

## 🚨 PROBLEMA CRÍTICO #3: MÉTRICA 1 DEL PANEL E (G-CONTENT LANDSCAPE)

### **Descripción:**
La Métrica 1 (`total_G_copies`) suma **TODOS los reads del miRNA**, no solo de esa posición específica.

### **Lógica actual:**
```r
# Paso 1: Identificar miRNAs con G en cada posición
mirnas_with_G_by_pos <- data %>%
  filter(str_detect(pos.mut, "^\\d+:G[TCAG]")) %>%
  mutate(Position = as.numeric(str_extract(pos.mut, "^\\d+"))) %>%
  select(Position, miRNA_name) %>%
  distinct()

# Paso 2: Sumar TODOS los reads del miRNA (no solo de esa posición)
total_copies_by_position <- mirnas_with_G_by_pos %>%
  left_join(
    data %>% 
      group_by(miRNA_name) %>%
      summarise(total_miRNA_counts = sum(across(all_of(sample_cols)), na.rm = TRUE)),  # ⚠️ Suma TODOS los reads
    by = "miRNA_name"
  ) %>%
  group_by(Position) %>%
  summarise(total_G_copies = sum(total_miRNA_counts, na.rm = TRUE))  # ⚠️ Suma total por posición
```

### **Problema:**
Si un miRNA tiene G en posición 5 y también en posición 10:
- Los reads de posición 10 se incluyen en `total_G_copies` de posición 5
- Los reads de posición 5 se incluyen en `total_G_copies` de posición 10
- Esto **duplica** o **infla** los valores

### **Ejemplo:**
- miRNA X tiene G en posición 5 (100 reads) y posición 10 (50 reads)
- `total_miRNA_counts` = 150 reads (suma de ambas posiciones)
- `total_G_copies` para posición 5 = 150 (incluye reads de posición 10) ❌
- `total_G_copies` para posición 10 = 150 (incluye reads de posición 5) ❌

### **Impacto:**
1. **Valores inflados:** `total_G_copies` no representa solo los reads de esa posición
2. **Interpretación incorrecta:** El eje Y no muestra "Total copies of miRNAs with G at that position" sino "Total copies of miRNAs that have G at that position (sumando todos sus reads)"
3. **Confusión:** El caption dice "Total miRNA copies with G" pero no especifica que incluye reads de otras posiciones

### **Recomendación:**
1. **Opción A:** Cambiar la lógica para sumar solo los reads de esa posición específica
2. **Opción B:** Aclarar en el caption que `total_G_copies` incluye todos los reads del miRNA, no solo de esa posición
3. **Opción C:** Cambiar el nombre de la métrica para reflejar mejor lo que representa

---

## 🚨 PROBLEMA CRÍTICO #4: DATOS NO UTILIZADOS EN FIGURAS

### **Descripción:**
Varias figuras calculan métricas que **no se usan** en la visualización.

### **Ejemplos:**

**Panel B (Step 1):**
```r
position_counts <- gt_data %>%
  # ... código ...
  summarise(
    total_GT_count = sum(total_count, na.rm = TRUE),  # ✅ Usado en figura
    n_SNVs = n(),  # ❌ Calculado pero NO usado en figura
    n_miRNAs = n_distinct(miRNA_name)  # ❌ Calculado pero NO usado en figura
  )
```
- **Problema:** Calcula `n_SNVs` y `n_miRNAs` pero solo muestra `total_GT_count`
- **Impacto:** Cálculo innecesario, confusión sobre qué métrica se está mostrando

**Panel F (Step 1):**
```r
summary_tbl <- snv %>%
  group_by(region) %>%
  summarise(
    total_mutations = sum(total_row_count, na.rm = TRUE),  # ✅ Usado en figura
    n_SNVs = n(),  # ❌ Calculado pero NO usado en figura
    .groups = 'drop'
  )
```
- **Problema:** Calcula `n_SNVs` pero solo muestra `total_mutations`
- **Impacto:** Cálculo innecesario, confusión

**Step 0 Figura 4:**
```r
mirna_summary <- tibble(
  miRNA_name = names(row_indices),
  n_snvs = lengths(row_indices),  # ✅ Usado en figura
  total_read_counts = vapply(...),  # ❌ Calculado pero NO usado en figura
  n_samples_with_snv = vapply(...)  # ❌ Calculado pero NO usado en figura
)
```
- **Problema:** Calcula `total_read_counts` y `n_samples_with_snv` pero solo muestra `n_snvs`
- **Impacto:** Cálculo innecesario

**Step 0 Figura 5:**
```r
mutation_summary <- tibble(
  mutation = mutation_counts$mutation,
  total_read_counts = row_total_counts,  # ❌ Calculado pero NO usado en esta figura
  # ...
) %>%
  summarise(
    n_snvs = n(),  # ✅ Usado en figura
    total_read_counts = sum(total_read_counts, na.rm = TRUE),  # ❌ Calculado pero NO usado en esta figura
  )
```
- **Problema:** Calcula `total_read_counts` pero solo muestra `n_snvs`
- **Nota:** `total_read_counts` se usa en Figuras 6 y 7, así que este cálculo es necesario

### **Impacto:**
1. **Cálculos innecesarios:** Desperdicio de recursos
2. **Confusión:** No está claro qué métrica se está mostrando
3. **Inconsistencia:** Algunas figuras calculan métricas que no usan

### **Recomendación:**
1. **Eliminar:** Si una métrica no se usa, no calcularla
2. **O usar:** Si se calcula, usarla en la visualización (ej: mostrar ambas métricas)

---

## 🚨 PROBLEMA CRÍTICO #5: ASUNCIÓN SOBRE ESTRUCTURA DE DATOS (STEP 0)

### **Descripción:**
Step 0 asume que `counts_matrix` contiene **solo SNV counts**, pero no está verificado.

### **Lógica actual:**
```r
count_cols <- names(processed)[
  !(names(processed) %in% required_cols) &
    !str_detect(names(processed), "^VAF_")
]

counts_matrix <- as.matrix(processed[count_cols])
counts_matrix[is.na(counts_matrix)] <- 0

# Asume que counts_matrix contiene solo SNV counts
total_read_counts = colSums(counts_matrix, na.rm = TRUE)  # ¿Es correcto?
n_snvs_detected = colSums(counts_matrix > 0, na.rm = TRUE)  # ¿Es correcto?
```

### **Preguntas críticas:**
1. ¿`processed_clean.csv` contiene solo SNV counts o también total counts?
2. ¿Hay columnas que mezclan ambos tipos de datos?
3. ¿Cómo se generó `processed_clean.csv`? ¿Qué procesamiento se aplicó?

### **Impacto:**
- Si `counts_matrix` contiene total counts, entonces:
  - `total_read_counts` sería incorrecto (sería suma de total counts, no SNV counts)
  - `n_snvs_detected` sería incorrecto (contaría filas con total counts > 0, no SNV counts > 0)

### **Recomendación:**
1. **Verificar:** Revisar cómo se genera `processed_clean.csv`
2. **Documentar:** Especificar qué contiene cada columna
3. **Validar:** Agregar validación para asegurar que `counts_matrix` contiene solo SNV counts

---

## 📊 RESUMEN DE PROBLEMAS POR PRIORIDAD

### **🔴 CRÍTICO (Debe corregirse):**
1. **Inconsistencia en archivos de entrada (Step 1)** - Diferentes archivos sin justificación
2. **Inconsistencia en métricas (Step 1)** - Mezcla reads y SNVs sin consistencia
3. **Métrica 1 Panel E** - Suma reads de otras posiciones
4. **Asunción sobre estructura de datos (Step 0)** - No verificado qué contiene `counts_matrix`

### **🟡 IMPORTANTE (Debería corregirse):**
5. **Datos no utilizados** - Cálculos innecesarios que confunden

---

## 🎯 PLAN DE ACCIÓN RECOMENDADO

### **Fase 1: Verificación (URGENTE)**
1. Verificar qué contiene `processed_clean.csv` (¿solo SNV counts o también total counts?)
2. Comparar `processed_clean` y `raw_data` para confirmar si son los mismos datos
3. Documentar cómo se generan ambos archivos

### **Fase 2: Corrección (CRÍTICO)**
1. Unificar archivos de entrada en Step 1 (usar el mismo archivo para todos los paneles)
2. Decidir métrica consistente para Step 1 (reads vs SNVs)
3. Corregir Métrica 1 del Panel E (sumar solo reads de esa posición o aclarar en caption)
4. Agregar validación para `counts_matrix` en Step 0

### **Fase 3: Optimización (IMPORTANTE)**
1. Eliminar cálculos innecesarios
2. Asegurar que todas las figuras especifiquen claramente qué métrica usan

---

**Próximo paso:** Verificar la estructura real de los datos para confirmar estos problemas

