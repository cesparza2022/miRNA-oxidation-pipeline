# 📊 COMPARACIÓN: Versión Local vs GitHub

**Fecha:** 2025-01-21  
**Branch:** main  
**Estado:** Sincronizado en commits, pero con cambios locales no commiteados

---

## 🔄 ESTADO GENERAL

### ✅ **Sincronización de Commits**
- ✅ Local y GitHub están sincronizados (mismo commit `cc4b729`)
- ✅ No hay commits remotos pendientes de pull
- ✅ No hay commits locales pendientes de push

### 📝 **Cambios Locales No Commiteados**
- **15 archivos modificados** (principalmente scripts R y reglas Snakemake)
- **2 archivos nuevos** (documentación de problemas identificados)
- **229 líneas agregadas, 96 líneas eliminadas** (neto: +133 líneas)

---

## 📋 ARCHIVOS MODIFICADOS (15)

### **1. Reglas Snakemake (2 archivos)**
- `rules/step1.smk` - 8 cambios menores
- `rules/step2_figures.smk` - 28 cambios (corrección crítica de VAF)

### **2. Scripts Step 0 (1 archivo)**
- `scripts/step0/01_generate_overview.R` - 26 cambios (mejoras menores)

### **3. Scripts Step 1 (6 archivos)**
- `scripts/step1/01_panel_b_gt_count_by_position.R` - 13 cambios
- `scripts/step1/02_panel_c_gx_spectrum.R` - 30 cambios
- `scripts/step1/03_panel_d_positional_fraction.R` - 22 cambios
- `scripts/step1/04_panel_e_gcontent.R` - 26 cambios
- `scripts/step1/05_panel_f_seed_vs_nonseed.R` - 12 cambios
- `scripts/step1/06_panel_g_gt_specificity.R` - 4 cambios

### **4. Scripts Step 1.5 (1 archivo)**
- `scripts/step1_5/02_generate_diagnostic_figures.R` - 34 cambios
  - ✅ Corrección: `size` → `linewidth` (compatibilidad ggplot2)
  - ✅ Mejora: Destacar G>T en rojo para consistencia
  - ✅ Documentación: Explicar aproximaciones en cálculos

### **5. Scripts Step 2 (2 archivos)**
- `scripts/step2/03_effect_size_analysis.R` - 4 cambios menores
- `scripts/step2/05_position_specific_analysis.R` - 2 cambios menores

### **6. Scripts Step 2 Figures (2 archivos)**
- `scripts/step2_figures/run_all_step2_figures.R` - 76 cambios
  - 🔴 **CORRECCIÓN CRÍTICA:** Cálculo de VAF desde columnas Total
  - ✅ Detecta columnas Total automáticamente
  - ✅ Calcula VAF = SNV_Count / Total_Count
  - ✅ Filtra VAF >= 0.5 (artefactos técnicos)
  - ✅ Reemplaza SNV counts con valores VAF
  
- `scripts/step2_figures/original_scripts/generate_FIG_2.13-15_DENSITY.R` - 34 cambios
  - ✅ Corrección: Combinación de heatmaps para FIG_2.15
  - ✅ Fallback usando `grid.layout` cuando no se pueden combinar directamente

### **7. Scripts Step 5 (1 archivo)**
- `scripts/step5/02_family_comparison_visualization.R` - 6 cambios menores

---

## 📄 ARCHIVOS NUEVOS (2)

### **1. PROBLEMAS_CRITICOS_COHESION.md**
**Descripción:** Documento identificando 5 problemas críticos de cohesión:
1. 🔴 Inconsistencia en archivos de entrada (Step 1) - Dos archivos diferentes sin justificación
2. 🔴 Inconsistencia en métricas (Step 1) - Mezcla reads y SNVs sin consistencia
3. 🔴 Métrica 1 Panel E - Suma reads de otras posiciones
4. 🔴 Asunción sobre estructura de datos (Step 0) - No verificado qué contiene `counts_matrix`
5. 🟡 Datos no utilizados - Cálculos innecesarios que confunden

**Estado:** Problemas identificados pero **NO corregidos aún**

### **2. CORRECCION_STEP2_VAF.md**
**Descripción:** Documentación de la corrección crítica del cálculo de VAF en Step 2:
- Problema: Scripts esperaban VAF pero recibían solo SNV counts
- Solución: Cálculo automático de VAF desde columnas Total
- Estado: ✅ **Corrección implementada y funcionando**

---

## 🔍 TIPO DE CAMBIOS

### **🔴 Correcciones Críticas (DEBEN guardarse)**
1. ✅ **Cálculo de VAF en Step 2** (`run_all_step2_figures.R`)
   - Sin esto, las figuras de Step 2 muestran valores incorrectos
   - **Impacto:** ALTO - Sin esto, resultados son incorrectos

2. ✅ **Compatibilidad ggplot2** (`size` → `linewidth`)
   - Necesario para versiones modernas de ggplot2
   - **Impacto:** MEDIO - Puede causar errores en ggplot2 3.4+

### **🟡 Mejoras y Consistencia (DEBERÍAN guardarse)**
3. ✅ **Mejoras visuales** (destacar G>T en rojo)
   - Consistencia visual en figuras
   - **Impacto:** BAJO - Mejora calidad pero no afecta funcionalidad

4. ✅ **Documentación mejorada** (explicar aproximaciones)
   - Claridad en interpretación de resultados
   - **Impacto:** BAJO - Mejora entendimiento pero no afecta funcionalidad

### **📝 Documentación (DEBE guardarse)**
5. ✅ **PROBLEMAS_CRITICOS_COHESION.md**
   - Identifica problemas que deben resolverse
   - **Impacto:** ALTO - Guía para correcciones futuras

6. ✅ **CORRECCION_STEP2_VAF.md**
   - Documenta corrección importante
   - **Impacto:** MEDIO - Documentación útil para futuro

---

## 🎯 RECOMENDACIONES

### **✅ DEBES HACER COMMIT DE:**

#### **Prioridad 1 (Crítico):**
1. ✅ `scripts/step2_figures/run_all_step2_figures.R`
   - Corrección crítica del cálculo de VAF
   - Sin esto, Step 2 produce resultados incorrectos

2. ✅ `scripts/step2_figures/original_scripts/generate_FIG_2.13-15_DENSITY.R`
   - Corrección de combinación de heatmaps
   - Necesario para generar FIG_2.15 correctamente

3. ✅ `rules/step2_figures.smk`
   - Cambio de input para permitir cálculo de VAF
   - Necesario para que funcione la corrección anterior

#### **Prioridad 2 (Importante):**
4. ✅ Todos los cambios de `size` → `linewidth` (compatibilidad ggplot2)
   - Evita errores en versiones modernas de ggplot2
   - Archivos afectados:
     - `scripts/step1_5/02_generate_diagnostic_figures.R`
     - Otros scripts con `geom_tile()`, `geom_hline()`, etc.

#### **Prioridad 3 (Mejoras):**
5. ✅ Mejoras visuales y documentación
   - Destacar G>T en rojo
   - Documentación de aproximaciones

6. ✅ Archivos de documentación nuevos
   - `PROBLEMAS_CRITICOS_COHESION.md`
   - `CORRECCION_STEP2_VAF.md`

---

## ⚠️ ADVERTENCIAS

### **Problemas Identificados PERO NO Corregidos:**
El archivo `PROBLEMAS_CRITICOS_COHESION.md` identifica 5 problemas críticos que **NO** están corregidos en estos cambios:

1. 🔴 Inconsistencia en archivos de entrada (Step 1)
2. 🔴 Inconsistencia en métricas (Step 1)
3. 🔴 Métrica 1 Panel E (suma reads incorrectamente)
4. 🔴 Asunción sobre estructura de datos (Step 0)
5. 🟡 Datos no utilizados

**Recomendación:** Estos problemas deben corregirse en un commit futuro, pero los cambios actuales son mejoras válidas que deben guardarse.

---

## 📊 ESTADÍSTICAS DE CAMBIOS

```
Archivos modificados:  15
Líneas agregadas:      229
Líneas eliminadas:     96
Neto:                  +133 líneas
Archivos nuevos:       2

Cambios por tipo:
- Correcciones críticas:    3 archivos
- Compatibilidad:           6 archivos
- Mejoras visuales:         3 archivos
- Correcciones menores:     3 archivos
```

---

## ✅ PLAN DE ACCIÓN RECOMENDADO

### **Opción A: Commit Completo (RECOMENDADO)**
```bash
cd miRNA-oxidation-pipeline
git add -A
git commit -m "fix: Correcciones críticas VAF Step 2 y mejoras de compatibilidad

- fix(critical): Cálculo correcto de VAF en run_all_step2_figures.R
- fix(critical): Corrección combinación heatmaps FIG_2.15
- fix: Compatibilidad ggplot2 (size -> linewidth)
- feat: Mejoras visuales (destacar G>T en rojo)
- docs: Documentar aproximaciones y correcciones
- docs: Identificar problemas críticos de cohesión (pendientes)"
git push origin main
```

### **Opción B: Commit Separado por Tipo**
```bash
# 1. Correcciones críticas primero
git add scripts/step2_figures/run_all_step2_figures.R \
        scripts/step2_figures/original_scripts/generate_FIG_2.13-15_DENSITY.R \
        rules/step2_figures.smk
git commit -m "fix(critical): Corrección cálculo VAF en Step 2 figures"

# 2. Compatibilidad ggplot2
git add scripts/step1_5/02_generate_diagnostic_figures.R \
        scripts/step1/*.R \
        scripts/step0/*.R \
        scripts/step2/*.R \
        scripts/step5/*.R
git commit -m "fix: Compatibilidad ggplot2 (size -> linewidth)"

# 3. Documentación
git add PROBLEMAS_CRITICOS_COHESION.md CORRECCION_STEP2_VAF.md
git commit -m "docs: Documentar correcciones y problemas identificados"
```

### **Opción C: Revisar Cada Cambio Individualmente**
Revisar cada archivo modificado antes de commit:
```bash
git diff HEAD <archivo>
# Revisar y decidir si incluir
```

---

## 🔍 PRÓXIMOS PASOS SUGERIDOS

1. ✅ **Hacer commit de cambios actuales** (especialmente correcciones críticas)
2. ⚠️ **Corregir problemas críticos identificados** en `PROBLEMAS_CRITICOS_COHESION.md`
3. 🧪 **Probar pipeline** con cambios aplicados para verificar que todo funciona
4. 📝 **Actualizar documentación** si hay cambios significativos

---

**Última actualización:** 2025-01-21
