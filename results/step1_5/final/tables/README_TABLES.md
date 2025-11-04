# 📊 Tablas Generadas en Step 1.5: Control de Calidad VAF

**Última actualización:** 2025-11-02  
**Ubicación:** `outputs/step1_5/tables/`

---

## 📋 Resumen

Step 1.5 genera **7 tablas** organizadas en 3 subdirectorios:

- `filtered_data/`: Datos filtrados (⭐ INPUT para Step 2)
- `filter_report/`: Reportes del filtro VAF aplicado
- `summary/`: Métricas resumen post-filtro

---

## 📊 Tablas por Categoría

### 🔵 filtered_data/ (Datos Filtrados)

#### ⭐ ALL_MUTATIONS_VAF_FILTERED.csv

**Descripción:** **Datos principales filtrados - Este es el INPUT para Step 2**

**Filtro aplicado:** VAF < 0.5 (remueve artefactos técnicos)

**Columnas:**
- `miRNA name`: Nombre del miRNA
- `pos:mut`: Posición y mutación (formato: `position:mutation`)
- `VAF`: Variant Allele Frequency (SNV_count / Total_count)
- `SampleName_SNV`: Counts SNV por muestra (solo valores con VAF < 0.5)
- `SampleName (PM+1MM+2MM)`: Total counts por muestra
- ... (columnas para cada muestra)

**Uso:**
- ⭐ **INPUT principal para Step 2** (comparaciones ALS vs Control)
- Datos limpios listos para análisis estadístico
- NAs en columnas SNV indican valores filtrados (VAF >= 0.5)

**Formato:**
```csv
miRNA name,pos:mut,VAF,Sample1_SNV,Sample1 (PM+1MM+2MM),...
hsa-let-7a-5p,6:G>T,0.023,5,220,...
hsa-let-7a-5p,7:G>T,0.045,12,267,...
```

---

### 📋 filter_report/ (Reportes del Filtro)

#### S1.5_filter_report.csv

**Descripción:** Reporte general del filtro VAF

**Columnas:**
- `metric`: Métrica reportada (ej: "Total_SNVs", "Filtered_SNVs", "Remaining_SNVs")
- `before_filter`: Valor antes del filtro
- `after_filter`: Valor después del filtro
- `removed`: Valores removidos
- `pct_removed`: Porcentaje removido

**Uso:**
- Entender impacto del filtro
- Cuantificar pérdida de datos
- Validar que el filtro funciona correctamente

**Ejemplo:**
```csv
metric,before_filter,after_filter,removed,pct_removed
Total_SNVs,500000,475000,25000,5.0
```

---

#### S1.5_stats_by_type.csv

**Descripción:** Estadísticas de filtro por tipo de mutación

**Columnas:**
- `Mutation_Type`: Tipo de mutación (AC, AG, GT, etc.)
- `N_Filtered`: Número de eventos filtrados de ese tipo
- `Mean_VAF`: VAF promedio de los eventos filtrados
- `Min_VAF`: VAF mínimo filtrado
- `Max_VAF`: VAF máximo filtrado

**Uso:**
- Identificar qué tipos de mutaciones se filtran más
- Entender si algún tipo tiene VAFs sistemáticamente altos
- Validar que el filtro no es sesgado hacia tipos específicos

**Ejemplo:**
```csv
Mutation_Type,N_Filtered,Mean_VAF,Min_VAF,Max_VAF
PM,170978,0.95,0.5,1.0
GT,5000,0.65,0.5,0.99
```

---

#### S1.5_stats_by_mirna.csv

**Descripción:** Estadísticas de filtro por miRNA

**Columnas:**
- `miRNA`: Nombre del miRNA
- `N_Filtered`: Número de eventos filtrados en ese miRNA
- `Mean_VAF`: VAF promedio de los eventos filtrados
- `Samples_Affected`: Número de muestras afectadas

**Uso:**
- Identificar miRNAs problemáticos (muchos eventos filtrados)
- Entender impacto por miRNA
- Detectar miRNAs con patrones anómalos

**Ejemplo:**
```csv
miRNA,N_Filtered,Mean_VAF,Samples_Affected
hsa-miR-27b-3p,416,0.88,415
hsa-let-7a-5p,415,0.98,415
```

---

### 📊 summary/ (Métricas Resumen)

#### S1.5_sample_metrics.csv

**Descripción:** Métricas por muestra después del filtro VAF

**Columnas:**
- `Sample`: ID de la muestra
- `Mutation_Type`: Tipo de mutación
- `N_SNVs`: Número de SNVs únicos
- `Total_Counts`: Total de counts
- `Mean_Count`: Count promedio por SNV
- `SD_Count`: Desviación estándar de counts
- `Max_Count`: Count máximo

**Uso:**
- Caracterizar cada muestra después del filtro
- Comparar muestras
- Validar calidad post-filtro

**Ejemplo:**
```csv
Sample,Mutation_Type,N_SNVs,Total_Counts,Mean_Count,SD_Count,Max_Count
Magen-ALS-enrolment-bloodplasma-SRR13934201,GT,74,1918,25.92,48.76,197
```

---

#### S1.5_position_metrics.csv

**Descripción:** Métricas por posición después del filtro VAF

**Columnas:**
- `Position`: Posición en miRNA (1-23)
- `Mutation_Type`: Tipo de mutación
- `N_SNVs`: Número de SNVs únicos en esa posición
- `Total_Counts`: Total de counts en esa posición
- `Mean_Count`: Count promedio
- `SD_Count`: Desviación estándar

**Uso:**
- Caracterizar patrones posicionales post-filtro
- Identificar posiciones con más datos
- Validar que el filtro no elimina patrones importantes

---

#### S1.5_mutation_type_summary.csv

**Descripción:** Resumen por tipo de mutación después del filtro

**Columnas:**
- `Mutation_Type`: Tipo de mutación
- `Mean_SNVs`: Promedio de SNVs (por muestra o posición)
- `SD_SNVs`: Desviación estándar
- `Mean_Counts`: Promedio de counts
- `N_Samples`: Número de muestras (si aplica)
- `Is_GT`: Si es mutación G>T (TRUE/FALSE)
- `Category`: Categoría (G>T, Other mutations, etc.)

**Uso:**
- Resumen general por tipo de mutación
- Comparar diferentes tipos
- Validar distribución post-filtro

---

## 🔗 Flujo de Datos

```
INPUT: step1_original_data.csv (necesita SNV + Total columns)
  ↓
[VAF Filter: VAF >= 0.5 → REMOVE]
  ↓
OUTPUT: ALL_MUTATIONS_VAF_FILTERED.csv ⭐
  ↓
Step 2 (Statistical Comparisons) - usa este archivo como input
```

**Nota:** El archivo `ALL_MUTATIONS_VAF_FILTERED.csv` en `filtered_data/` es el **único input** para Step 2.

---

## 📌 Notas Importantes

- ⭐ = Tabla usada como input en pasos siguientes
- 🔒 = Tabla final (no se modifica)
- 📊 = Tabla resumen (puede regenerarse)
- **VAF Threshold:** 0.5 (configurable en `config.yaml`)
- **NAs en datos filtrados:** Valores con VAF >= 0.5 se convierten en NA

---

## 🎯 Preguntas que Responde Step 1.5

| Pregunta | Tabla | Métrica Clave |
|---------|-------|---------------|
| ¿Cuántos artefactos se remueven? | `S1.5_filter_report.csv` | `pct_removed` |
| ¿Qué tipos de mutaciones se filtran más? | `S1.5_stats_by_type.csv` | `N_Filtered`, `Mean_VAF` |
| ¿Qué miRNAs se ven más afectados? | `S1.5_stats_by_mirna.csv` | `N_Filtered`, `Samples_Affected` |
| ⭐ **¿Cuáles son los datos limpios para Step 2?** | **`ALL_MUTATIONS_VAF_FILTERED.csv`** | Todos los datos con VAF < 0.5 |

---

## 📈 Interpretación Típica

**Impacto del Filtro:** Si `pct_removed` > 20%, hay muchos artefactos técnicos.

**Tipos Problemáticos:** Si `PM` (Perfect Match) tiene `N_Filtered` muy alto, hay muchos artefactos de alineamiento.

**Datos Limpios:** `ALL_MUTATIONS_VAF_FILTERED.csv` contiene solo mutaciones con VAF < 0.5, listas para análisis estadístico.


**Última actualización:** 2025-11-02  
**Ubicación:** `outputs/step1_5/tables/`

---

## 📋 Resumen

Step 1.5 genera **7 tablas** organizadas en 3 subdirectorios:

- `filtered_data/`: Datos filtrados (⭐ INPUT para Step 2)
- `filter_report/`: Reportes del filtro VAF aplicado
- `summary/`: Métricas resumen post-filtro

---

## 📊 Tablas por Categoría

### 🔵 filtered_data/ (Datos Filtrados)

#### ⭐ ALL_MUTATIONS_VAF_FILTERED.csv

**Descripción:** **Datos principales filtrados - Este es el INPUT para Step 2**

**Filtro aplicado:** VAF < 0.5 (remueve artefactos técnicos)

**Columnas:**
- `miRNA name`: Nombre del miRNA
- `pos:mut`: Posición y mutación (formato: `position:mutation`)
- `VAF`: Variant Allele Frequency (SNV_count / Total_count)
- `SampleName_SNV`: Counts SNV por muestra (solo valores con VAF < 0.5)
- `SampleName (PM+1MM+2MM)`: Total counts por muestra
- ... (columnas para cada muestra)

**Uso:**
- ⭐ **INPUT principal para Step 2** (comparaciones ALS vs Control)
- Datos limpios listos para análisis estadístico
- NAs en columnas SNV indican valores filtrados (VAF >= 0.5)

**Formato:**
```csv
miRNA name,pos:mut,VAF,Sample1_SNV,Sample1 (PM+1MM+2MM),...
hsa-let-7a-5p,6:G>T,0.023,5,220,...
hsa-let-7a-5p,7:G>T,0.045,12,267,...
```

---

### 📋 filter_report/ (Reportes del Filtro)

#### S1.5_filter_report.csv

**Descripción:** Reporte general del filtro VAF

**Columnas:**
- `metric`: Métrica reportada (ej: "Total_SNVs", "Filtered_SNVs", "Remaining_SNVs")
- `before_filter`: Valor antes del filtro
- `after_filter`: Valor después del filtro
- `removed`: Valores removidos
- `pct_removed`: Porcentaje removido

**Uso:**
- Entender impacto del filtro
- Cuantificar pérdida de datos
- Validar que el filtro funciona correctamente

**Ejemplo:**
```csv
metric,before_filter,after_filter,removed,pct_removed
Total_SNVs,500000,475000,25000,5.0
```

---

#### S1.5_stats_by_type.csv

**Descripción:** Estadísticas de filtro por tipo de mutación

**Columnas:**
- `Mutation_Type`: Tipo de mutación (AC, AG, GT, etc.)
- `N_Filtered`: Número de eventos filtrados de ese tipo
- `Mean_VAF`: VAF promedio de los eventos filtrados
- `Min_VAF`: VAF mínimo filtrado
- `Max_VAF`: VAF máximo filtrado

**Uso:**
- Identificar qué tipos de mutaciones se filtran más
- Entender si algún tipo tiene VAFs sistemáticamente altos
- Validar que el filtro no es sesgado hacia tipos específicos

**Ejemplo:**
```csv
Mutation_Type,N_Filtered,Mean_VAF,Min_VAF,Max_VAF
PM,170978,0.95,0.5,1.0
GT,5000,0.65,0.5,0.99
```

---

#### S1.5_stats_by_mirna.csv

**Descripción:** Estadísticas de filtro por miRNA

**Columnas:**
- `miRNA`: Nombre del miRNA
- `N_Filtered`: Número de eventos filtrados en ese miRNA
- `Mean_VAF`: VAF promedio de los eventos filtrados
- `Samples_Affected`: Número de muestras afectadas

**Uso:**
- Identificar miRNAs problemáticos (muchos eventos filtrados)
- Entender impacto por miRNA
- Detectar miRNAs con patrones anómalos

**Ejemplo:**
```csv
miRNA,N_Filtered,Mean_VAF,Samples_Affected
hsa-miR-27b-3p,416,0.88,415
hsa-let-7a-5p,415,0.98,415
```

---

### 📊 summary/ (Métricas Resumen)

#### S1.5_sample_metrics.csv

**Descripción:** Métricas por muestra después del filtro VAF

**Columnas:**
- `Sample`: ID de la muestra
- `Mutation_Type`: Tipo de mutación
- `N_SNVs`: Número de SNVs únicos
- `Total_Counts`: Total de counts
- `Mean_Count`: Count promedio por SNV
- `SD_Count`: Desviación estándar de counts
- `Max_Count`: Count máximo

**Uso:**
- Caracterizar cada muestra después del filtro
- Comparar muestras
- Validar calidad post-filtro

**Ejemplo:**
```csv
Sample,Mutation_Type,N_SNVs,Total_Counts,Mean_Count,SD_Count,Max_Count
Magen-ALS-enrolment-bloodplasma-SRR13934201,GT,74,1918,25.92,48.76,197
```

---

#### S1.5_position_metrics.csv

**Descripción:** Métricas por posición después del filtro VAF

**Columnas:**
- `Position`: Posición en miRNA (1-23)
- `Mutation_Type`: Tipo de mutación
- `N_SNVs`: Número de SNVs únicos en esa posición
- `Total_Counts`: Total de counts en esa posición
- `Mean_Count`: Count promedio
- `SD_Count`: Desviación estándar

**Uso:**
- Caracterizar patrones posicionales post-filtro
- Identificar posiciones con más datos
- Validar que el filtro no elimina patrones importantes

---

#### S1.5_mutation_type_summary.csv

**Descripción:** Resumen por tipo de mutación después del filtro

**Columnas:**
- `Mutation_Type`: Tipo de mutación
- `Mean_SNVs`: Promedio de SNVs (por muestra o posición)
- `SD_SNVs`: Desviación estándar
- `Mean_Counts`: Promedio de counts
- `N_Samples`: Número de muestras (si aplica)
- `Is_GT`: Si es mutación G>T (TRUE/FALSE)
- `Category`: Categoría (G>T, Other mutations, etc.)

**Uso:**
- Resumen general por tipo de mutación
- Comparar diferentes tipos
- Validar distribución post-filtro

---

## 🔗 Flujo de Datos

```
INPUT: step1_original_data.csv (necesita SNV + Total columns)
  ↓
[VAF Filter: VAF >= 0.5 → REMOVE]
  ↓
OUTPUT: ALL_MUTATIONS_VAF_FILTERED.csv ⭐
  ↓
Step 2 (Statistical Comparisons) - usa este archivo como input
```

**Nota:** El archivo `ALL_MUTATIONS_VAF_FILTERED.csv` en `filtered_data/` es el **único input** para Step 2.

---

## 📌 Notas Importantes

- ⭐ = Tabla usada como input en pasos siguientes
- 🔒 = Tabla final (no se modifica)
- 📊 = Tabla resumen (puede regenerarse)
- **VAF Threshold:** 0.5 (configurable en `config.yaml`)
- **NAs en datos filtrados:** Valores con VAF >= 0.5 se convierten en NA

---

## 🎯 Preguntas que Responde Step 1.5

| Pregunta | Tabla | Métrica Clave |
|---------|-------|---------------|
| ¿Cuántos artefactos se remueven? | `S1.5_filter_report.csv` | `pct_removed` |
| ¿Qué tipos de mutaciones se filtran más? | `S1.5_stats_by_type.csv` | `N_Filtered`, `Mean_VAF` |
| ¿Qué miRNAs se ven más afectados? | `S1.5_stats_by_mirna.csv` | `N_Filtered`, `Samples_Affected` |
| ⭐ **¿Cuáles son los datos limpios para Step 2?** | **`ALL_MUTATIONS_VAF_FILTERED.csv`** | Todos los datos con VAF < 0.5 |

---

## 📈 Interpretación Típica

**Impacto del Filtro:** Si `pct_removed` > 20%, hay muchos artefactos técnicos.

**Tipos Problemáticos:** Si `PM` (Perfect Match) tiene `N_Filtered` muy alto, hay muchos artefactos de alineamiento.

**Datos Limpios:** `ALL_MUTATIONS_VAF_FILTERED.csv` contiene solo mutaciones con VAF < 0.5, listas para análisis estadístico.


**Última actualización:** 2025-11-02  
**Ubicación:** `outputs/step1_5/tables/`

---

## 📋 Resumen

Step 1.5 genera **7 tablas** organizadas en 3 subdirectorios:

- `filtered_data/`: Datos filtrados (⭐ INPUT para Step 2)
- `filter_report/`: Reportes del filtro VAF aplicado
- `summary/`: Métricas resumen post-filtro

---

## 📊 Tablas por Categoría

### 🔵 filtered_data/ (Datos Filtrados)

#### ⭐ ALL_MUTATIONS_VAF_FILTERED.csv

**Descripción:** **Datos principales filtrados - Este es el INPUT para Step 2**

**Filtro aplicado:** VAF < 0.5 (remueve artefactos técnicos)

**Columnas:**
- `miRNA name`: Nombre del miRNA
- `pos:mut`: Posición y mutación (formato: `position:mutation`)
- `VAF`: Variant Allele Frequency (SNV_count / Total_count)
- `SampleName_SNV`: Counts SNV por muestra (solo valores con VAF < 0.5)
- `SampleName (PM+1MM+2MM)`: Total counts por muestra
- ... (columnas para cada muestra)

**Uso:**
- ⭐ **INPUT principal para Step 2** (comparaciones ALS vs Control)
- Datos limpios listos para análisis estadístico
- NAs en columnas SNV indican valores filtrados (VAF >= 0.5)

**Formato:**
```csv
miRNA name,pos:mut,VAF,Sample1_SNV,Sample1 (PM+1MM+2MM),...
hsa-let-7a-5p,6:G>T,0.023,5,220,...
hsa-let-7a-5p,7:G>T,0.045,12,267,...
```

---

### 📋 filter_report/ (Reportes del Filtro)

#### S1.5_filter_report.csv

**Descripción:** Reporte general del filtro VAF

**Columnas:**
- `metric`: Métrica reportada (ej: "Total_SNVs", "Filtered_SNVs", "Remaining_SNVs")
- `before_filter`: Valor antes del filtro
- `after_filter`: Valor después del filtro
- `removed`: Valores removidos
- `pct_removed`: Porcentaje removido

**Uso:**
- Entender impacto del filtro
- Cuantificar pérdida de datos
- Validar que el filtro funciona correctamente

**Ejemplo:**
```csv
metric,before_filter,after_filter,removed,pct_removed
Total_SNVs,500000,475000,25000,5.0
```

---

#### S1.5_stats_by_type.csv

**Descripción:** Estadísticas de filtro por tipo de mutación

**Columnas:**
- `Mutation_Type`: Tipo de mutación (AC, AG, GT, etc.)
- `N_Filtered`: Número de eventos filtrados de ese tipo
- `Mean_VAF`: VAF promedio de los eventos filtrados
- `Min_VAF`: VAF mínimo filtrado
- `Max_VAF`: VAF máximo filtrado

**Uso:**
- Identificar qué tipos de mutaciones se filtran más
- Entender si algún tipo tiene VAFs sistemáticamente altos
- Validar que el filtro no es sesgado hacia tipos específicos

**Ejemplo:**
```csv
Mutation_Type,N_Filtered,Mean_VAF,Min_VAF,Max_VAF
PM,170978,0.95,0.5,1.0
GT,5000,0.65,0.5,0.99
```

---

#### S1.5_stats_by_mirna.csv

**Descripción:** Estadísticas de filtro por miRNA

**Columnas:**
- `miRNA`: Nombre del miRNA
- `N_Filtered`: Número de eventos filtrados en ese miRNA
- `Mean_VAF`: VAF promedio de los eventos filtrados
- `Samples_Affected`: Número de muestras afectadas

**Uso:**
- Identificar miRNAs problemáticos (muchos eventos filtrados)
- Entender impacto por miRNA
- Detectar miRNAs con patrones anómalos

**Ejemplo:**
```csv
miRNA,N_Filtered,Mean_VAF,Samples_Affected
hsa-miR-27b-3p,416,0.88,415
hsa-let-7a-5p,415,0.98,415
```

---

### 📊 summary/ (Métricas Resumen)

#### S1.5_sample_metrics.csv

**Descripción:** Métricas por muestra después del filtro VAF

**Columnas:**
- `Sample`: ID de la muestra
- `Mutation_Type`: Tipo de mutación
- `N_SNVs`: Número de SNVs únicos
- `Total_Counts`: Total de counts
- `Mean_Count`: Count promedio por SNV
- `SD_Count`: Desviación estándar de counts
- `Max_Count`: Count máximo

**Uso:**
- Caracterizar cada muestra después del filtro
- Comparar muestras
- Validar calidad post-filtro

**Ejemplo:**
```csv
Sample,Mutation_Type,N_SNVs,Total_Counts,Mean_Count,SD_Count,Max_Count
Magen-ALS-enrolment-bloodplasma-SRR13934201,GT,74,1918,25.92,48.76,197
```

---

#### S1.5_position_metrics.csv

**Descripción:** Métricas por posición después del filtro VAF

**Columnas:**
- `Position`: Posición en miRNA (1-23)
- `Mutation_Type`: Tipo de mutación
- `N_SNVs`: Número de SNVs únicos en esa posición
- `Total_Counts`: Total de counts en esa posición
- `Mean_Count`: Count promedio
- `SD_Count`: Desviación estándar

**Uso:**
- Caracterizar patrones posicionales post-filtro
- Identificar posiciones con más datos
- Validar que el filtro no elimina patrones importantes

---

#### S1.5_mutation_type_summary.csv

**Descripción:** Resumen por tipo de mutación después del filtro

**Columnas:**
- `Mutation_Type`: Tipo de mutación
- `Mean_SNVs`: Promedio de SNVs (por muestra o posición)
- `SD_SNVs`: Desviación estándar
- `Mean_Counts`: Promedio de counts
- `N_Samples`: Número de muestras (si aplica)
- `Is_GT`: Si es mutación G>T (TRUE/FALSE)
- `Category`: Categoría (G>T, Other mutations, etc.)

**Uso:**
- Resumen general por tipo de mutación
- Comparar diferentes tipos
- Validar distribución post-filtro

---

## 🔗 Flujo de Datos

```
INPUT: step1_original_data.csv (necesita SNV + Total columns)
  ↓
[VAF Filter: VAF >= 0.5 → REMOVE]
  ↓
OUTPUT: ALL_MUTATIONS_VAF_FILTERED.csv ⭐
  ↓
Step 2 (Statistical Comparisons) - usa este archivo como input
```

**Nota:** El archivo `ALL_MUTATIONS_VAF_FILTERED.csv` en `filtered_data/` es el **único input** para Step 2.

---

## 📌 Notas Importantes

- ⭐ = Tabla usada como input en pasos siguientes
- 🔒 = Tabla final (no se modifica)
- 📊 = Tabla resumen (puede regenerarse)
- **VAF Threshold:** 0.5 (configurable en `config.yaml`)
- **NAs en datos filtrados:** Valores con VAF >= 0.5 se convierten en NA

---

## 🎯 Preguntas que Responde Step 1.5

| Pregunta | Tabla | Métrica Clave |
|---------|-------|---------------|
| ¿Cuántos artefactos se remueven? | `S1.5_filter_report.csv` | `pct_removed` |
| ¿Qué tipos de mutaciones se filtran más? | `S1.5_stats_by_type.csv` | `N_Filtered`, `Mean_VAF` |
| ¿Qué miRNAs se ven más afectados? | `S1.5_stats_by_mirna.csv` | `N_Filtered`, `Samples_Affected` |
| ⭐ **¿Cuáles son los datos limpios para Step 2?** | **`ALL_MUTATIONS_VAF_FILTERED.csv`** | Todos los datos con VAF < 0.5 |

---

## 📈 Interpretación Típica

**Impacto del Filtro:** Si `pct_removed` > 20%, hay muchos artefactos técnicos.

**Tipos Problemáticos:** Si `PM` (Perfect Match) tiene `N_Filtered` muy alto, hay muchos artefactos de alineamiento.

**Datos Limpios:** `ALL_MUTATIONS_VAF_FILTERED.csv` contiene solo mutaciones con VAF < 0.5, listas para análisis estadístico.

