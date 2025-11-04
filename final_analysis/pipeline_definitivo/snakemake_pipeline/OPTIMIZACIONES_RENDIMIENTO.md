# 🚀 Optimizaciones de Rendimiento - Pipeline Snakemake

## 🔍 Problemas Identificados

### 1. **Loop doble anidado ineficiente** (CRÍTICO)
- **Archivo**: `scripts/step1_5/01_apply_vaf_filter.R`
- **Línea 76**: Loop `for (i in 1:nrow())` con loop interno `for (snv_col in snv_cols)`
- **Impacto**: Procesa ~69,000 filas × ~400 columnas = **27 millones de iteraciones**
- **Tiempo estimado**: 10-15 minutos

### 2. **Carga repetida de archivos grandes**
- Paneles C y D cargan el mismo archivo raw (278M) por separado
- Cada ejecución lee desde disco completo
- **Impacto**: ~30-60 segundos por panel

### 3. **Falta de paralelización**
- Estamos usando `snakemake -j 1` (un solo core)
- Paneles independientes (B, C, D, E, F, G) podrían ejecutarse en paralelo
- **Impacto**: Si tenemos 4 cores, podríamos ser 4x más rápidos

---

## 💡 Soluciones (Orden de Impacto)

### ✅ SOLUCIÓN 1: Paralelización (RÁPIDA - 0 minutos)
**Impacto**: Reducción de tiempo en Step 1 de ~6 minutos a ~2 minutos (con 4 cores)

```bash
# En lugar de:
snakemake -j 1

# Usa:
snakemake -j 4  # o más según tus cores
```

**Ventajas**:
- Inmediato (solo cambiar comando)
- No requiere cambios en código
- Paneles independientes se ejecutan simultáneamente

---

### ⚡ SOLUCIÓN 2: Optimizar Step 1.5 Regla 1 (CRÍTICA - 10 minutos)
**Impacto**: Reducción de tiempo de ~10-15 min a ~1-2 min (10x más rápido)

**Problema**: Loop doble anidado (línea 76-105)

**Solución**: Vectorizar con `dplyr` o `data.table`

**Antes**:
```r
for (i in 1:nrow(data_with_info)) {
  for (snv_col in snv_cols) {
    # calcular VAF y filtrar...
  }
}
```

**Después** (vectorizado):
```r
# Pivot a formato largo una vez
long_data <- data_with_info %>%
  pivot_longer(...) %>%
  mutate(vaf = snv_count / total_count) %>%
  mutate(snv_count = ifelse(vaf >= 0.5, NA, snv_count)) %>%
  pivot_wider(...)
```

**Tiempo de implementación**: ~10 minutos
**Reducción de tiempo**: 10-15x más rápido

---

### 📦 SOLUCIÓN 3: Optimizar carga de datos (MEDIA - 5 minutos)
**Impacto**: Reducción de tiempo de carga de 30-60s a 5-10s

**Cambio**: Reemplazar `read.csv()` por `data.table::fread()`

```r
# Antes:
data <- read.csv(input_file)

# Después:
library(data.table)
data <- fread(input_file, data.table = FALSE)
```

**Tiempo de implementación**: ~5 minutos
**Reducción**: 5-10x más rápido en carga de archivos grandes

---

### 🔄 SOLUCIÓN 4: Cache de datos procesados (COMPLEJA - 20 minutos)
**Impacto**: Eliminar cargas repetidas del mismo archivo

**Idea**: Procesar raw data una vez, guardar resultado intermedio, reutilizar

**Implementación**: Crear regla intermedia que procesa raw data una vez

---

## 🎯 Plan de Acción Recomendado

### Fase 1: Inmediata (5 minutos)
1. ✅ Usar paralelización: `snakemake -j 4`

### Fase 2: Corto plazo (15 minutos)
1. ⚡ Optimizar Step 1.5 Regla 1 (vectorizar loops)
2. 📦 Optimizar carga de datos (fread en lugar de read.csv)

### Fase 3: Largo plazo (opcional)
1. 🔄 Implementar cache de datos procesados

---

## 📊 Impacto Esperado

**Tiempo actual estimado**:
- Step 1: ~6-8 minutos (sin paralelización)
- Step 1.5 Regla 1: ~10-15 minutos (loop ineficiente)
- Step 1.5 Regla 2: ~2-3 minutos
- **Total**: ~20-26 minutos

**Tiempo después de optimizaciones**:
- Step 1: ~2 minutos (con -j 4)
- Step 1.5 Regla 1: ~1-2 minutos (vectorizado)
- Step 1.5 Regla 2: ~2-3 minutos
- **Total**: ~5-7 minutos

**Reducción**: ~75% más rápido (4x)

---

## 🚀 ¿Empezamos con la paralelización?

La solución más rápida es simplemente usar más cores. ¿Quieres que probemos?

```bash
snakemake -j 4 all_step1  # Ejecuta Step 1 con 4 cores en paralelo
```

