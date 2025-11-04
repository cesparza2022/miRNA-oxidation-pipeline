# ✅ Validación de Datos y Formato del Pipeline

**Fecha:** 2025-01-21  
**Estado:** ✅ **DATOS COMPATIBLES Y LISTOS PARA EJECUCIÓN**

---

## 📊 Datos Disponibles

### Archivo Actual
- **Ubicación:** `results/step1_5/final/tables/filtered_data/ALL_MUTATIONS_VAF_FILTERED.csv`
- **Tamaño:** 168.77 MB
- **Formato:** CSV con headers

### Estructura de Datos

**Columnas:**
- **Total:** 832 columnas
- **Metadata:** 2 columnas (`miRNA name`, `pos:mut`)
- **Muestras:** 830 columnas de muestras

**Muestras Identificadas:**
- ✅ **ALS:** 626 muestras (75.4%)
- ✅ **Control:** 204 muestras (24.6%)
- ✅ **Sin clasificar:** 0 muestras (100% de clasificación exitosa)

### Ejemplos de Nombres de Muestras

**Muestras ALS:**
```
Magen-ALS-enrolment-bloodplasma-SRR13934430
Magen-ALS-enrolment-bloodplasma-SRR13934402
Magen-ALS-enrolment-bloodplasma-SRR13934219
```

**Muestras Control:**
```
Magen-control-control-bloodplasma-SRR14631747
Magen-control-control-bloodplasma-SRR14631738
Magen-control-control-bloodplasma-SRR14631805
```

---

## 🔍 Patrones de Parsing

### Cómo el Pipeline Identifica los Grupos

**Función:** `extract_sample_groups()` en `scripts/utils/group_comparison.R`

**Patrones Usados:**
1. **ALS:** Busca `"ALS"` en el nombre de la columna (case-insensitive)
   - ✅ Detecta: `Magen-ALS-enrolment-...`
   - ✅ Detecta: `Sample_ALS_1`
   - ✅ Detecta: `patient-als-001`

2. **Control:** Busca `"control"`, `"Control"`, o `"CTRL"` (case-insensitive)
   - ✅ Detecta: `Magen-control-control-...`
   - ✅ Detecta: `Sample_Control_1`
   - ✅ Detecta: `CTRL_001`

**Lógica:**
```r
group = case_when(
  str_detect(sample_id, regex("ALS", ignore_case = TRUE)) ~ "ALS",
  str_detect(sample_id, regex("control|Control|CTRL", ignore_case = TRUE)) ~ "Control",
  TRUE ~ NA_character_  # Excluidas del análisis
)
```

### Validación con Datos Actuales

**Resultado del Parsing:**
- ✅ 626 muestras clasificadas como ALS
- ✅ 204 muestras clasificadas como Control
- ✅ 0 muestras sin clasificar (todas las muestras tienen un patrón reconocido)

**Conclusión:** Los datos actuales son **100% compatibles** con los patrones del pipeline.

---

## 📐 Formato de Input

### Columnas Requeridas

**Metadata (obligatorias):**
- `miRNA name` o `miRNA_name`: Identificador del miRNA
- `pos:mut` o `pos.mut`: Posición y tipo de mutación

**Muestras (obligatorias):**
- Mínimo 2 columnas de muestras
- Mínimo 2 muestras en cada grupo (ALS y Control)

### Formatos Soportados

**✅ CSV (`.csv`):** Formato principal
**✅ TSV (`.tsv`):** Formato alternativo

**Detectado automáticamente:**
```r
if (str_ends(input_file, ".csv")) {
  data <- read_csv(input_file)
} else {
  data <- read_tsv(input_file)
}
```

### Valores de Datos

**Aceptados:**
- ✅ Enteros: `0`, `1`, `50`, `100` (counts)
- ✅ NA: Valores faltantes (manejados correctamente)
- ⚠️ Decimales: Soportados pero pueden ser redondeados

**Ejemplo de Fila:**
```csv
hsa-let-7a-2-3p,PM,0,1,2,0,NA,5,...
```

---

## 🎨 Generación de Gráficas y Tablas

### Patrones en Gráficas

**Colores:**
- ALS: `#D62728` (rojo) - configurable en `config.yaml`
- Control: `grey60` - configurable en `config.yaml`

**Etiquetas:**
- "ALS" y "Control" (vienen de los grupos parseados, NO hardcoded)

**Flexibilidad:**
- ✅ Colores configurables en `config.yaml`
- ✅ Dimensiones de figuras configurables
- ✅ Etiquetas dinámicas (basadas en nombres de grupos)

### Patrones en Tablas

**Columnas Generadas:**
- `ALS_mean`, `ALS_sd`, `ALS_n` - estadísticas del grupo ALS
- `Control_mean`, `Control_sd`, `Control_n` - estadísticas del grupo Control
- `fold_change`, `log2_fold_change` - calculados
- `t_test_pvalue`, `wilcoxon_pvalue` - p-values
- `t_test_fdr`, `wilcoxon_fdr` - FDR corregidos
- `significant` - boolean basado en umbrales

**Flexibilidad:**
- ✅ Nombres de columnas dinámicos (basados en nombres de grupos)
- ✅ Si cambias los nombres de grupos, las columnas reflejan eso

---

## 🔧 Flexibilidad del Pipeline

### ✅ Altamente Flexible

1. **Nombres de Columnas:**
   - Metadata: Acepta variaciones (`miRNA name` o `miRNA_name`)
   - Muestras: Cualquier nombre (mientras tenga el patrón)

2. **Formato de Archivo:**
   - CSV o TSV
   - Detectado automáticamente

3. **Valores:**
   - Enteros, NA, decimales (con warnings)

4. **Configuración:**
   - Colores: `config.yaml`
   - Dimensiones: `config.yaml`
   - Umbrales: `config.yaml`

### ⚠️ Parcialmente Flexible

1. **Patrones de Grupos:**
   - Hardcoded: `"ALS"` y `"control|Control|CTRL"`
   - **Puede personalizarse** modificando scripts
   - **No configurable** vía `config.yaml` (actualmente)

2. **Información de Batch:**
   - Puede inferir de nombres de muestras
   - Puede usar archivo de metadata (si se proporciona)
   - Si no hay, crea batches dummy para demostración

### ❌ No Flexible (Hardcoded)

1. **Asunción de Dos Grupos:**
   - Pipeline asume comparación ALS vs Control
   - No soporta múltiples grupos directamente

2. **Nombres de Columnas de Metadata:**
   - Espera: `miRNA name`/`miRNA_name`, `pos:mut`/`pos.mut`
   - Si usas otros nombres, necesitas renombrarlos primero

---

## 🧪 Prueba de Compatibilidad

### Validación Realizada

**✅ Estructura de Archivo:**
- CSV válido con headers
- Metadata columns presentes
- Sample columns presentes

**✅ Parsing de Grupos:**
- 626 muestras ALS identificadas
- 204 muestras Control identificadas
- 0 muestras sin clasificar
- **Tasa de éxito: 100%**

**✅ Formato de Datos:**
- Valores son enteros (como strings, se convierten automáticamente)
- NA values presentes y manejables
- Estructura compatible con `read_csv()`

**✅ Validación de Requisitos:**
- Mínimo 2 grupos: ✅ (ALS y Control)
- Mínimo 2 muestras por grupo: ✅ (626 ALS, 204 Control)
- Metadata columns presentes: ✅

---

## 📝 Resumen para el Usuario

### ¿Puedo usar estos datos?

**✅ SÍ - Los datos son completamente compatibles:**

1. **Formato:** CSV con estructura correcta
2. **Grupos:** 100% de muestras clasificadas correctamente
3. **Metadata:** Columnas en formato esperado
4. **Valores:** Enteros válidos

### ¿Qué necesito saber?

1. **Patrones de Nombres:**
   - Asegúrate que nombres de muestras contengan "ALS" o "control"
   - O personaliza los patrones en los scripts

2. **Metadata Columns:**
   - Usa `miRNA name` (o `miRNA_name`)
   - Usa `pos:mut` (o `pos.mut`)

3. **Archivo de Metadata (Opcional):**
   - Si tienes batch, age, sex: proporciona archivo TSV
   - Si no: el pipeline funciona pero con análisis limitado

### ¿Puedo cambiar los nombres de grupos?

**Sí, pero requiere modificar scripts:**
- Actualmente: "ALS" y "Control" están hardcoded
- Para cambiar: Modifica `extract_sample_groups()` en scripts
- O renombra tus columnas para que contengan los patrones

---

## 🚀 Próximos Pasos

1. **Ejecutar Pipeline:**
   ```bash
   conda activate mirna_oxidation_pipeline
   snakemake -j 4 all_step2
   ```

2. **Verificar Outputs:**
   - Reportes en `results/step2/final/logs/`
   - Tablas en `results/step2/final/tables/statistical_results/`
   - Figuras en `results/step2/final/figures/`

3. **Revisar Resultados:**
   - Verificar que grupos se identificaron correctamente
   - Verificar que estadísticas tienen sentido
   - Verificar que figuras muestran datos correctos

---

**✅ CONCLUSIÓN: Los datos actuales son 100% compatibles y listos para ejecución.**

