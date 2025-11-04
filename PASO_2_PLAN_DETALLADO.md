# 📋 PASO 2: PLAN DETALLADO - Migrar Paso 1.5 a Snakemake

**Fecha:** 2025-01-30  
**Estado:** ⏳ Planificando

---

## 📊 ANÁLISIS DE SCRIPTS

### **Script 1: `01_apply_vaf_filter.R`**

**Inputs:**
- `step1_original_data.csv` (ruta absoluta hardcodeada)
- Requiere columnas de SNV counts y total counts

**Outputs:**
- `ALL_MUTATIONS_VAF_FILTERED.csv` (dataset filtrado)
- `vaf_filter_report.csv` (reporte de filtrado)
- `vaf_statistics_by_type.csv` (estadísticas por tipo)
- `vaf_statistics_by_mirna.csv` (estadísticas por miRNA)

**Lógica:**
1. Carga datos originales
2. Calcula VAF para cada SNV en cada muestra
3. Filtra valores con VAF >= 0.5 (los marca como NA/Nan)
4. Genera reportes de estadísticas

**Adaptaciones necesarias:**
- Cambiar ruta hardcodeada por parámetro de Snakemake
- Outputs a `outputs/step1_5/tables/`

---

### **Script 2: `02_generate_diagnostic_figures.R`**

**Inputs:**
- `ALL_MUTATIONS_VAF_FILTERED.csv` (del Script 1)
- `vaf_filter_report.csv` (del Script 1)
- `vaf_statistics_by_type.csv` (del Script 1)
- `vaf_statistics_by_mirna.csv` (del Script 1)

**Outputs:**
- **11 figuras PNG:**
  - QC_FIG1_VAF_DISTRIBUTION.png
  - QC_FIG2_FILTER_IMPACT.png
  - QC_FIG3_AFFECTED_MIRNAS.png
  - QC_FIG4_BEFORE_AFTER.png
  - STEP1.5_FIG1_HEATMAP_SNVS.png
  - STEP1.5_FIG2_HEATMAP_COUNTS.png
  - STEP1.5_FIG3_G_TRANSVERSIONS_SNVS.png
  - STEP1.5_FIG4_G_TRANSVERSIONS_COUNTS.png
  - STEP1.5_FIG5_BUBBLE_PLOT.png
  - STEP1.5_FIG6_VIOLIN_DISTRIBUTIONS.png
  - STEP1.5_FIG7_FOLD_CHANGE.png
- **3 tablas CSV:**
  - sample_metrics_vaf_filtered.csv
  - position_metrics_vaf_filtered.csv
  - mutation_type_summary_vaf_filtered.csv

**Lógica:**
1. Carga datos filtrados
2. Genera 4 figuras de QC
3. Genera 7 figuras diagnósticas
4. Exporta tablas de métricas

**Adaptaciones necesarias:**
- Inputs deben venir de outputs del Script 1
- Outputs a `outputs/step1_5/figures/` y `outputs/step1_5/tables/`

---

## 📝 PLAN DE TAREAS (Paso a Paso)

### **MENSAJE 1: Preparación y Análisis** (Solo lectura/análisis)

**Tarea 1.1:** Verificar estructura de datos de entrada
- [ ] Verificar que existe `step1_original_data.csv`
- [ ] Verificar estructura de columnas (SNV vs Total)
- [ ] Documentar dependencias

**Tarea 1.2:** Identificar todas las rutas hardcodeadas
- [ ] Script 1: Ruta a `step1_original_data.csv`
- [ ] Script 2: Rutas a tablas del Script 1
- [ ] Todas las rutas de output

**Tarea 1.3:** Identificar dependencias entre scripts
- [ ] Script 2 depende completamente de Script 1
- [ ] Orden de ejecución: Script 1 → Script 2

**Resultado:** Documento con todas las dependencias y rutas

---

### **MENSAJE 2: Adaptar Scripts** (Escritura)

**Tarea 2.1:** Adaptar `01_apply_vaf_filter.R`
- [ ] Cambiar rutas hardcodeadas por `snakemake@input` y `snakemake@output`
- [ ] Usar parámetros de Snakemake para paths
- [ ] Guardar como `scripts/step1_5/01_apply_vaf_filter.R`
- [ ] Verificar que usa funciones comunes si es necesario

**Tarea 2.2:** Adaptar `02_generate_diagnostic_figures.R`
- [ ] Cambiar inputs para usar outputs del Script 1
- [ ] Cambiar rutas de output
- [ ] Guardar como `scripts/step1_5/02_generate_diagnostic_figures.R`
- [ ] Verificar dependencias de funciones

**Resultado:** 2 scripts adaptados listos para Snakemake

---

### **MENSAJE 3: Crear Reglas Snakemake** (Escritura)

**Tarea 3.1:** Crear `rules/step1_5.smk`
- [ ] Regla `apply_vaf_filter` (Script 1)
  - Input: `step1_original_data.csv`
  - Outputs: 4 tablas CSV
- [ ] Regla `generate_diagnostic_figures` (Script 2)
  - Inputs: 4 tablas del Script 1
  - Outputs: 11 figuras PNG + 3 tablas CSV
- [ ] Regla agregadora `all_step1_5`
  - Input: Todas las figuras

**Tarea 3.2:** Actualizar `config/config.yaml`
- [ ] Agregar ruta a `step1_original_data.csv`
- [ ] Agregar configuración de outputs para step1_5

**Tarea 3.3:** Integrar en `Snakefile` principal
- [ ] Agregar `include: "rules/step1_5.smk"`
- [ ] Actualizar regla `all` para incluir `all_step1_5`

**Resultado:** Reglas Snakemake creadas e integradas

---

### **MENSAJE 4: Crear Viewer HTML** (Escritura)

**Tarea 4.1:** Crear `scripts/utils/build_step1_5_viewer.R`
- [ ] Basado en `build_step1_viewer.R`
- [ ] Incluir las 11 figuras
- [ ] Agregar descripciones de cada figura
- [ ] Embeddar imágenes en base64

**Tarea 4.2:** Agregar regla en `rules/viewers.smk`
- [ ] Regla `generate_step1_5_viewer`
- [ ] Inputs: Las 11 figuras
- [ ] Output: `viewers/step1_5.html`

**Tarea 4.3:** Actualizar regla `all` en `Snakefile`
- [ ] Incluir `generate_step1_5_viewer` en outputs

**Resultado:** Viewer HTML configurado (aún no generado)

---

### **MENSAJE 5: Probar y Verificar** (Ejecución)

**Tarea 5.1:** Dry-run completo
- [ ] `snakemake -n all_step1_5`
- [ ] Verificar que todas las dependencias están correctas
- [ ] Corregir errores si los hay

**Tarea 5.2:** Ejecutar Script 1 solo
- [ ] `snakemake -j 1 apply_vaf_filter`
- [ ] Verificar que genera las 4 tablas
- [ ] Revisar logs por errores

**Tarea 5.3:** Ejecutar Script 2 solo
- [ ] `snakemake -j 1 generate_diagnostic_figures`
- [ ] Verificar que genera las 11 figuras
- [ ] Revisar logs por errores

**Tarea 5.4:** Ejecutar todo Paso 1.5
- [ ] `snakemake -j 1 all_step1_5 generate_step1_5_viewer`
- [ ] Verificar todos los outputs
- [ ] Abrir viewer HTML y verificar

**Resultado:** Paso 1.5 completamente funcional en Snakemake

---

## 🔗 DEPENDENCIAS IDENTIFICADAS

### Inputs Externos:
- `step1_original_data.csv` (debe estar en config.yaml)

### Dependencias Internas:
- Script 2 → Script 1 (4 tablas)

### Outputs:
- **Tablas:** 7 total (4 del Script 1 + 3 del Script 2)
- **Figuras:** 11 total (4 QC + 7 diagnóstico)
- **Viewer:** 1 HTML

---

## 📊 RESUMEN

**Scripts a adaptar:** 2  
**Reglas a crear:** 3 (2 principales + 1 agregadora)  
**Viewer:** 1 HTML  
**Tiempo estimado:** ~1 hora (en 5 mensajes)  
**Complejidad:** Media (Script 1 es más complejo por cálculo de VAF)

---

## 🎯 PRÓXIMO MENSAJE

**Empezar con MENSAJE 1:** Preparación y Análisis
- Verificar datos de entrada
- Mapear todas las rutas
- Documentar dependencias

**Sin ejecutar nada todavía** - solo planificar.


**Fecha:** 2025-01-30  
**Estado:** ⏳ Planificando

---

## 📊 ANÁLISIS DE SCRIPTS

### **Script 1: `01_apply_vaf_filter.R`**

**Inputs:**
- `step1_original_data.csv` (ruta absoluta hardcodeada)
- Requiere columnas de SNV counts y total counts

**Outputs:**
- `ALL_MUTATIONS_VAF_FILTERED.csv` (dataset filtrado)
- `vaf_filter_report.csv` (reporte de filtrado)
- `vaf_statistics_by_type.csv` (estadísticas por tipo)
- `vaf_statistics_by_mirna.csv` (estadísticas por miRNA)

**Lógica:**
1. Carga datos originales
2. Calcula VAF para cada SNV en cada muestra
3. Filtra valores con VAF >= 0.5 (los marca como NA/Nan)
4. Genera reportes de estadísticas

**Adaptaciones necesarias:**
- Cambiar ruta hardcodeada por parámetro de Snakemake
- Outputs a `outputs/step1_5/tables/`

---

### **Script 2: `02_generate_diagnostic_figures.R`**

**Inputs:**
- `ALL_MUTATIONS_VAF_FILTERED.csv` (del Script 1)
- `vaf_filter_report.csv` (del Script 1)
- `vaf_statistics_by_type.csv` (del Script 1)
- `vaf_statistics_by_mirna.csv` (del Script 1)

**Outputs:**
- **11 figuras PNG:**
  - QC_FIG1_VAF_DISTRIBUTION.png
  - QC_FIG2_FILTER_IMPACT.png
  - QC_FIG3_AFFECTED_MIRNAS.png
  - QC_FIG4_BEFORE_AFTER.png
  - STEP1.5_FIG1_HEATMAP_SNVS.png
  - STEP1.5_FIG2_HEATMAP_COUNTS.png
  - STEP1.5_FIG3_G_TRANSVERSIONS_SNVS.png
  - STEP1.5_FIG4_G_TRANSVERSIONS_COUNTS.png
  - STEP1.5_FIG5_BUBBLE_PLOT.png
  - STEP1.5_FIG6_VIOLIN_DISTRIBUTIONS.png
  - STEP1.5_FIG7_FOLD_CHANGE.png
- **3 tablas CSV:**
  - sample_metrics_vaf_filtered.csv
  - position_metrics_vaf_filtered.csv
  - mutation_type_summary_vaf_filtered.csv

**Lógica:**
1. Carga datos filtrados
2. Genera 4 figuras de QC
3. Genera 7 figuras diagnósticas
4. Exporta tablas de métricas

**Adaptaciones necesarias:**
- Inputs deben venir de outputs del Script 1
- Outputs a `outputs/step1_5/figures/` y `outputs/step1_5/tables/`

---

## 📝 PLAN DE TAREAS (Paso a Paso)

### **MENSAJE 1: Preparación y Análisis** (Solo lectura/análisis)

**Tarea 1.1:** Verificar estructura de datos de entrada
- [ ] Verificar que existe `step1_original_data.csv`
- [ ] Verificar estructura de columnas (SNV vs Total)
- [ ] Documentar dependencias

**Tarea 1.2:** Identificar todas las rutas hardcodeadas
- [ ] Script 1: Ruta a `step1_original_data.csv`
- [ ] Script 2: Rutas a tablas del Script 1
- [ ] Todas las rutas de output

**Tarea 1.3:** Identificar dependencias entre scripts
- [ ] Script 2 depende completamente de Script 1
- [ ] Orden de ejecución: Script 1 → Script 2

**Resultado:** Documento con todas las dependencias y rutas

---

### **MENSAJE 2: Adaptar Scripts** (Escritura)

**Tarea 2.1:** Adaptar `01_apply_vaf_filter.R`
- [ ] Cambiar rutas hardcodeadas por `snakemake@input` y `snakemake@output`
- [ ] Usar parámetros de Snakemake para paths
- [ ] Guardar como `scripts/step1_5/01_apply_vaf_filter.R`
- [ ] Verificar que usa funciones comunes si es necesario

**Tarea 2.2:** Adaptar `02_generate_diagnostic_figures.R`
- [ ] Cambiar inputs para usar outputs del Script 1
- [ ] Cambiar rutas de output
- [ ] Guardar como `scripts/step1_5/02_generate_diagnostic_figures.R`
- [ ] Verificar dependencias de funciones

**Resultado:** 2 scripts adaptados listos para Snakemake

---

### **MENSAJE 3: Crear Reglas Snakemake** (Escritura)

**Tarea 3.1:** Crear `rules/step1_5.smk`
- [ ] Regla `apply_vaf_filter` (Script 1)
  - Input: `step1_original_data.csv`
  - Outputs: 4 tablas CSV
- [ ] Regla `generate_diagnostic_figures` (Script 2)
  - Inputs: 4 tablas del Script 1
  - Outputs: 11 figuras PNG + 3 tablas CSV
- [ ] Regla agregadora `all_step1_5`
  - Input: Todas las figuras

**Tarea 3.2:** Actualizar `config/config.yaml`
- [ ] Agregar ruta a `step1_original_data.csv`
- [ ] Agregar configuración de outputs para step1_5

**Tarea 3.3:** Integrar en `Snakefile` principal
- [ ] Agregar `include: "rules/step1_5.smk"`
- [ ] Actualizar regla `all` para incluir `all_step1_5`

**Resultado:** Reglas Snakemake creadas e integradas

---

### **MENSAJE 4: Crear Viewer HTML** (Escritura)

**Tarea 4.1:** Crear `scripts/utils/build_step1_5_viewer.R`
- [ ] Basado en `build_step1_viewer.R`
- [ ] Incluir las 11 figuras
- [ ] Agregar descripciones de cada figura
- [ ] Embeddar imágenes en base64

**Tarea 4.2:** Agregar regla en `rules/viewers.smk`
- [ ] Regla `generate_step1_5_viewer`
- [ ] Inputs: Las 11 figuras
- [ ] Output: `viewers/step1_5.html`

**Tarea 4.3:** Actualizar regla `all` en `Snakefile`
- [ ] Incluir `generate_step1_5_viewer` en outputs

**Resultado:** Viewer HTML configurado (aún no generado)

---

### **MENSAJE 5: Probar y Verificar** (Ejecución)

**Tarea 5.1:** Dry-run completo
- [ ] `snakemake -n all_step1_5`
- [ ] Verificar que todas las dependencias están correctas
- [ ] Corregir errores si los hay

**Tarea 5.2:** Ejecutar Script 1 solo
- [ ] `snakemake -j 1 apply_vaf_filter`
- [ ] Verificar que genera las 4 tablas
- [ ] Revisar logs por errores

**Tarea 5.3:** Ejecutar Script 2 solo
- [ ] `snakemake -j 1 generate_diagnostic_figures`
- [ ] Verificar que genera las 11 figuras
- [ ] Revisar logs por errores

**Tarea 5.4:** Ejecutar todo Paso 1.5
- [ ] `snakemake -j 1 all_step1_5 generate_step1_5_viewer`
- [ ] Verificar todos los outputs
- [ ] Abrir viewer HTML y verificar

**Resultado:** Paso 1.5 completamente funcional en Snakemake

---

## 🔗 DEPENDENCIAS IDENTIFICADAS

### Inputs Externos:
- `step1_original_data.csv` (debe estar en config.yaml)

### Dependencias Internas:
- Script 2 → Script 1 (4 tablas)

### Outputs:
- **Tablas:** 7 total (4 del Script 1 + 3 del Script 2)
- **Figuras:** 11 total (4 QC + 7 diagnóstico)
- **Viewer:** 1 HTML

---

## 📊 RESUMEN

**Scripts a adaptar:** 2  
**Reglas a crear:** 3 (2 principales + 1 agregadora)  
**Viewer:** 1 HTML  
**Tiempo estimado:** ~1 hora (en 5 mensajes)  
**Complejidad:** Media (Script 1 es más complejo por cálculo de VAF)

---

## 🎯 PRÓXIMO MENSAJE

**Empezar con MENSAJE 1:** Preparación y Análisis
- Verificar datos de entrada
- Mapear todas las rutas
- Documentar dependencias

**Sin ejecutar nada todavía** - solo planificar.


**Fecha:** 2025-01-30  
**Estado:** ⏳ Planificando

---

## 📊 ANÁLISIS DE SCRIPTS

### **Script 1: `01_apply_vaf_filter.R`**

**Inputs:**
- `step1_original_data.csv` (ruta absoluta hardcodeada)
- Requiere columnas de SNV counts y total counts

**Outputs:**
- `ALL_MUTATIONS_VAF_FILTERED.csv` (dataset filtrado)
- `vaf_filter_report.csv` (reporte de filtrado)
- `vaf_statistics_by_type.csv` (estadísticas por tipo)
- `vaf_statistics_by_mirna.csv` (estadísticas por miRNA)

**Lógica:**
1. Carga datos originales
2. Calcula VAF para cada SNV en cada muestra
3. Filtra valores con VAF >= 0.5 (los marca como NA/Nan)
4. Genera reportes de estadísticas

**Adaptaciones necesarias:**
- Cambiar ruta hardcodeada por parámetro de Snakemake
- Outputs a `outputs/step1_5/tables/`

---

### **Script 2: `02_generate_diagnostic_figures.R`**

**Inputs:**
- `ALL_MUTATIONS_VAF_FILTERED.csv` (del Script 1)
- `vaf_filter_report.csv` (del Script 1)
- `vaf_statistics_by_type.csv` (del Script 1)
- `vaf_statistics_by_mirna.csv` (del Script 1)

**Outputs:**
- **11 figuras PNG:**
  - QC_FIG1_VAF_DISTRIBUTION.png
  - QC_FIG2_FILTER_IMPACT.png
  - QC_FIG3_AFFECTED_MIRNAS.png
  - QC_FIG4_BEFORE_AFTER.png
  - STEP1.5_FIG1_HEATMAP_SNVS.png
  - STEP1.5_FIG2_HEATMAP_COUNTS.png
  - STEP1.5_FIG3_G_TRANSVERSIONS_SNVS.png
  - STEP1.5_FIG4_G_TRANSVERSIONS_COUNTS.png
  - STEP1.5_FIG5_BUBBLE_PLOT.png
  - STEP1.5_FIG6_VIOLIN_DISTRIBUTIONS.png
  - STEP1.5_FIG7_FOLD_CHANGE.png
- **3 tablas CSV:**
  - sample_metrics_vaf_filtered.csv
  - position_metrics_vaf_filtered.csv
  - mutation_type_summary_vaf_filtered.csv

**Lógica:**
1. Carga datos filtrados
2. Genera 4 figuras de QC
3. Genera 7 figuras diagnósticas
4. Exporta tablas de métricas

**Adaptaciones necesarias:**
- Inputs deben venir de outputs del Script 1
- Outputs a `outputs/step1_5/figures/` y `outputs/step1_5/tables/`

---

## 📝 PLAN DE TAREAS (Paso a Paso)

### **MENSAJE 1: Preparación y Análisis** (Solo lectura/análisis)

**Tarea 1.1:** Verificar estructura de datos de entrada
- [ ] Verificar que existe `step1_original_data.csv`
- [ ] Verificar estructura de columnas (SNV vs Total)
- [ ] Documentar dependencias

**Tarea 1.2:** Identificar todas las rutas hardcodeadas
- [ ] Script 1: Ruta a `step1_original_data.csv`
- [ ] Script 2: Rutas a tablas del Script 1
- [ ] Todas las rutas de output

**Tarea 1.3:** Identificar dependencias entre scripts
- [ ] Script 2 depende completamente de Script 1
- [ ] Orden de ejecución: Script 1 → Script 2

**Resultado:** Documento con todas las dependencias y rutas

---

### **MENSAJE 2: Adaptar Scripts** (Escritura)

**Tarea 2.1:** Adaptar `01_apply_vaf_filter.R`
- [ ] Cambiar rutas hardcodeadas por `snakemake@input` y `snakemake@output`
- [ ] Usar parámetros de Snakemake para paths
- [ ] Guardar como `scripts/step1_5/01_apply_vaf_filter.R`
- [ ] Verificar que usa funciones comunes si es necesario

**Tarea 2.2:** Adaptar `02_generate_diagnostic_figures.R`
- [ ] Cambiar inputs para usar outputs del Script 1
- [ ] Cambiar rutas de output
- [ ] Guardar como `scripts/step1_5/02_generate_diagnostic_figures.R`
- [ ] Verificar dependencias de funciones

**Resultado:** 2 scripts adaptados listos para Snakemake

---

### **MENSAJE 3: Crear Reglas Snakemake** (Escritura)

**Tarea 3.1:** Crear `rules/step1_5.smk`
- [ ] Regla `apply_vaf_filter` (Script 1)
  - Input: `step1_original_data.csv`
  - Outputs: 4 tablas CSV
- [ ] Regla `generate_diagnostic_figures` (Script 2)
  - Inputs: 4 tablas del Script 1
  - Outputs: 11 figuras PNG + 3 tablas CSV
- [ ] Regla agregadora `all_step1_5`
  - Input: Todas las figuras

**Tarea 3.2:** Actualizar `config/config.yaml`
- [ ] Agregar ruta a `step1_original_data.csv`
- [ ] Agregar configuración de outputs para step1_5

**Tarea 3.3:** Integrar en `Snakefile` principal
- [ ] Agregar `include: "rules/step1_5.smk"`
- [ ] Actualizar regla `all` para incluir `all_step1_5`

**Resultado:** Reglas Snakemake creadas e integradas

---

### **MENSAJE 4: Crear Viewer HTML** (Escritura)

**Tarea 4.1:** Crear `scripts/utils/build_step1_5_viewer.R`
- [ ] Basado en `build_step1_viewer.R`
- [ ] Incluir las 11 figuras
- [ ] Agregar descripciones de cada figura
- [ ] Embeddar imágenes en base64

**Tarea 4.2:** Agregar regla en `rules/viewers.smk`
- [ ] Regla `generate_step1_5_viewer`
- [ ] Inputs: Las 11 figuras
- [ ] Output: `viewers/step1_5.html`

**Tarea 4.3:** Actualizar regla `all` en `Snakefile`
- [ ] Incluir `generate_step1_5_viewer` en outputs

**Resultado:** Viewer HTML configurado (aún no generado)

---

### **MENSAJE 5: Probar y Verificar** (Ejecución)

**Tarea 5.1:** Dry-run completo
- [ ] `snakemake -n all_step1_5`
- [ ] Verificar que todas las dependencias están correctas
- [ ] Corregir errores si los hay

**Tarea 5.2:** Ejecutar Script 1 solo
- [ ] `snakemake -j 1 apply_vaf_filter`
- [ ] Verificar que genera las 4 tablas
- [ ] Revisar logs por errores

**Tarea 5.3:** Ejecutar Script 2 solo
- [ ] `snakemake -j 1 generate_diagnostic_figures`
- [ ] Verificar que genera las 11 figuras
- [ ] Revisar logs por errores

**Tarea 5.4:** Ejecutar todo Paso 1.5
- [ ] `snakemake -j 1 all_step1_5 generate_step1_5_viewer`
- [ ] Verificar todos los outputs
- [ ] Abrir viewer HTML y verificar

**Resultado:** Paso 1.5 completamente funcional en Snakemake

---

## 🔗 DEPENDENCIAS IDENTIFICADAS

### Inputs Externos:
- `step1_original_data.csv` (debe estar en config.yaml)

### Dependencias Internas:
- Script 2 → Script 1 (4 tablas)

### Outputs:
- **Tablas:** 7 total (4 del Script 1 + 3 del Script 2)
- **Figuras:** 11 total (4 QC + 7 diagnóstico)
- **Viewer:** 1 HTML

---

## 📊 RESUMEN

**Scripts a adaptar:** 2  
**Reglas a crear:** 3 (2 principales + 1 agregadora)  
**Viewer:** 1 HTML  
**Tiempo estimado:** ~1 hora (en 5 mensajes)  
**Complejidad:** Media (Script 1 es más complejo por cálculo de VAF)

---

## 🎯 PRÓXIMO MENSAJE

**Empezar con MENSAJE 1:** Preparación y Análisis
- Verificar datos de entrada
- Mapear todas las rutas
- Documentar dependencias

**Sin ejecutar nada todavía** - solo planificar.

