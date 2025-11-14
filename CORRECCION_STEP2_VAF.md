# Corrección Crítica: Step 2 - Cálculo de VAF para Figuras Detalladas

## Problema Identificado

Los scripts detallados de Step 2 (FIG_2.1 a FIG_2.15) esperan valores de VAF (Variant Allele Frequency) como entrada, pero estaban recibiendo `ALL_MUTATIONS_VAF_FILTERED.csv` que solo contiene columnas de SNV counts, sin columnas Total. Sin las columnas Total, no es posible calcular VAF (VAF = SNV_Count / Total_Count).

### Impacto

- Los scripts interpretaban SNV counts como VAF directamente
- Las figuras mostraban valores incorrectos (counts en lugar de VAF)
- Los análisis estadísticos y visualizaciones estaban sesgados

## Solución Implementada

### 1. Modificación de `run_all_step2_figures.R`

El script ahora:
- Detecta si el archivo de entrada tiene columnas Total (patrón `(PM+1MM+2MM)`)
- Si las encuentra, calcula VAF para cada muestra: `VAF = SNV_Count / Total_Count`
- Filtra valores con VAF >= 0.5 (artefactos técnicos) estableciéndolos como NA
- Reemplaza las columnas SNV con los valores VAF calculados
- Elimina las columnas Total (los scripts ya tienen VAF directamente)

### 2. Actualización de `rules/step2_figures.smk`

- Cambiado el input principal de `INPUT_DATA_VAF_FILTERED` a `INPUT_DATA_PRIMARY` (que apunta a `processed_clean.csv`)
- `processed_clean.csv` contiene tanto columnas SNV como Total, permitiendo el cálculo correcto de VAF
- `ALL_MUTATIONS_VAF_FILTERED.csv` ahora es el fallback (con advertencia si no hay columnas Total)

## Archivos Modificados

1. `scripts/step2_figures/run_all_step2_figures.R`
   - Agregada lógica para detectar columnas Total
   - Agregado cálculo de VAF vectorizado
   - Agregado filtrado de VAF >= 0.5
   - Reemplazo de SNV counts con VAF values

2. `rules/step2_figures.smk`
   - Cambiado `INPUT_DATA_VAF_FILTERED` a `INPUT_DATA_PRIMARY`
   - Actualizado comentario explicando por qué usamos `processed_clean.csv`
   - Actualizado todas las reglas que usan estos inputs

3. `scripts/step2_figures/original_scripts/generate_FIG_2.13-15_DENSITY.R`
   - Corregido combinación de heatmaps para FIG_2.15
   - ALS y Control tienen diferente número de columnas (23 vs 21), no se pueden combinar con `+` o `%v%`
   - Implementado fallback usando `grid.layout` para layout lado a lado

## Flujo de Datos Corregido

```
processed_clean.csv (SNV + Total columns)
    ↓
run_all_step2_figures.R
    ↓
    Detecta columnas Total
    ↓
    Calcula VAF = SNV_Count / Total_Count
    ↓
    Filtra VAF >= 0.5 → NA
    ↓
    Reemplaza SNV columns con VAF values
    ↓
final_processed_data_CLEAN.csv (VAF values, no counts)
    ↓
Scripts detallados (FIG_2.1-2.15)
    ↓
Figuras correctas con VAF
```

## Verificación

Para verificar que la corrección funciona:

1. Ejecutar Step 2: `snakemake -j 1 all_step2_figures`
2. Revisar el log de `run_all_step2_figures.R`:
   - Debe mostrar: "Found X SNV columns and Y Total columns"
   - Debe mostrar: "VAF calculated and filtered (VAF >= 0.5 set to NA)"
3. Verificar que las figuras muestren valores entre 0 y 0.5 (rango válido de VAF)
4. Verificar que FIG_2.15 se genere correctamente (usando layout lado a lado)

## Estado de Ejecución

✅ **Ejecutado exitosamente el 2025-11-14**
- 15 figuras generadas correctamente
- FIG_2.15 generado usando layout lado a lado (fallback)
- VAF calculado correctamente desde `processed_clean.csv`

## Notas Importantes

- Los scripts de clustering (`06_hierarchical_clustering_all_gt.R` y `07_hierarchical_clustering_seed_gt.R`) también necesitan VAF, pero ya tienen lógica para calcularlo desde SNV + Total columns. Esta corrección asegura que reciban datos con columnas Total disponibles.

- El filtro VAF >= 0.5 se aplica aquí para mantener consistencia con Step 1.5, aunque `processed_clean.csv` no está pre-filtrado.

- Si `processed_clean.csv` no está disponible, el script usará `ALL_MUTATIONS_VAF_FILTERED.csv` pero mostrará una advertencia indicando que no se pueden calcular VAF correctamente.

