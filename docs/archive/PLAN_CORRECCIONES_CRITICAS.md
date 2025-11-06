# 🔧 Plan de Acción: Correcciones Críticas del Pipeline

**Fecha:** 2025-11-04  
**Prioridad:** CRÍTICA  
**Objetivo:** Corregir problemas de portabilidad, consistencia y robustez del pipeline

---

## 📊 Resumen de Problemas Identificados

### 🔴 CRÍTICOS (Bloquean uso en otras máquinas)
1. **Config.yaml con paths absolutos hardcodeados**
2. **Inconsistencia outputs/ vs results/**
3. **Dependencias entre steps no explícitas**
4. **Config.yaml no versionado correctamente**

### 🟡 ALTOS (Afectan robustez y mantenibilidad)
5. **Calidad de datos: -Inf en summary**
6. **Documentación excesiva y redundante (179 archivos .md)**
7. **Manejo de errores inconsistente**
8. **Contaminación de results/ con otros proyectos**

### 🟢 MEDIOS (Mejoras de calidad)
9. **Falta validación de inputs**
10. **Metadata pipeline_info incompleta**
11. **Ordenamiento lógico vs numérico confuso**

---

## 🎯 FASE 1: CORRECCIONES CRÍTICAS (Prioridad 1)

### Tarea 1.1: Hacer config.yaml portable
**Estimación:** 30 min  
**Archivos afectados:** `config/config.yaml`, `config/config.yaml.example`

**Acciones:**
1. ✅ Crear `config/config.yaml.example` con paths relativos y placeholders
2. ✅ Documentar cómo configurar paths (relativos desde snakemake_dir)
3. ✅ Actualizar README.md con instrucciones de configuración
4. ✅ Agregar validación de paths en script de setup

**Ejemplo de cambio:**
```yaml
# ANTES (config.yaml):
paths:
  project_root: "/Users/cesaresparza/New_Desktop/UCSD/8OG/..."
  raw: "/Users/cesaresparza/New_Desktop/UCSD/8OG/organized/02_data/..."

# DESPUÉS (config.yaml.example):
paths:
  project_root: "../.."  # Relativo desde snakemake_pipeline/
  snakemake_dir: "."  # Directorio actual
  data:
    raw: "../../organized/02_data/Magen_ALS-bloodplasma/miRNA_count.Q33.txt"
    # O usar variable de entorno:
    # raw: "${DATA_DIR}/miRNA_count.Q33.txt"
```

---

### Tarea 1.2: Unificar estructura outputs/ vs results/
**Estimación:** 45 min  
**Archivos afectados:** `config/config.yaml`, `rules/*.smk`, `scripts/utils/functions_common.R`

**Acciones:**
1. ✅ Decidir: ¿usar `outputs/` o `results/`?
   - **RECOMENDACIÓN:** Usar `results/` (ya está implementado)
2. ✅ Actualizar `config.yaml` para usar `results/`:
   ```yaml
   outputs:
     step1: "results/step1"
     step1_5: "results/step1_5"
     ...
   ```
3. ✅ Verificar que todas las reglas usen paths de config
4. ✅ Actualizar scripts R que lean paths del config

**Verificación:**
```bash
# Buscar referencias hardcodeadas a "outputs/"
grep -r "outputs/" rules/ scripts/ --exclude-dir=.snakemake
# Debe retornar solo referencias a config["paths"]["outputs"]
```

---

### Tarea 1.3: Agregar dependencias explícitas entre steps
**Estimación:** 1 hora  
**Archivos afectados:** `rules/step2.smk`, `rules/step3.smk`, `rules/step4.smk`, `rules/step5.smk`, `rules/step6.smk`, `rules/step7.smk`

**Acciones:**
1. ✅ Modificar `rule all_step2` para depender de `all_step1_5`:
   ```python
   rule all_step2:
       input:
           rules.all_step1_5.output,  # ← DEPENDENCIA EXPLÍCITA
           ...
   ```

2. ✅ Modificar `rule all_step3` para depender de `all_step2`
3. ✅ Modificar `rule all_step4` para depender de `all_step3`
4. ✅ Modificar `rule all_step5` para depender de `all_step2` (usa datos de step2)
5. ✅ Modificar `rule all_step6` para depender de `all_step2` (usa datos de step2)
6. ✅ Modificar `rule all_step7` para depender de `all_step2` (usa datos de step2)

**Orden de dependencias:**
```
Step 1 → Step 1.5 → Step 2
                    ↓
        ┌───────────┼───────────┐
        ↓           ↓           ↓
      Step 3    Step 5      Step 6
        ↓           ↓           ↓
      Step 4    (indep)    (indep)
```

**Verificación:**
```bash
# Dry-run debe mostrar orden correcto
snakemake -n all_step3
# Debe indicar que step2 se ejecutará primero
```

---

### Tarea 1.4: Crear/actualizar config.yaml.example
**Estimación:** 20 min  
**Archivos afectados:** `config/config.yaml.example`

**Acciones:**
1. ✅ Copiar estructura de `config.yaml` pero con paths relativos
2. ✅ Agregar comentarios explicativos para cada sección
3. ✅ Incluir ejemplos de configuración para diferentes escenarios:
   - Datos locales
   - Datos en otra ubicación
   - Uso de variables de entorno
4. ✅ Agregar validación en setup script

**Estructura:**
```yaml
# ============================================================================
# CONFIGURACIÓN DEL PIPELINE
# ============================================================================
# Copia este archivo a config.yaml y edita los paths según tu sistema
#
# IMPORTANTE: Usa paths RELATIVOS desde snakemake_pipeline/
# O usa variables de entorno: ${HOME}/data/file.csv
# ============================================================================

project:
  name: "miRNA Oxidation Analysis"
  version: "1.0.0"
  description: "..."

paths:
  # Paths relativos desde snakemake_pipeline/
  project_root: "../.."  # Ajusta según tu estructura
  snakemake_dir: "."  # Siempre "." (directorio actual)
  
  data:
    # Ejemplo: datos en ../organized/02_data/
    raw: "../../organized/02_data/Magen_ALS-bloodplasma/miRNA_count.Q33.txt"
    
    # O usar variable de entorno:
    # raw: "${DATA_DIR}/miRNA_count.Q33.txt"
    
    processed_clean: "../../organized/02_data/Magen_ALS-bloodplasma/miRNA_count.Q33.txt"
    step1_original: "../../organized/02_data/Magen_ALS-bloodplasma/miRNA_count.Q33.txt"
    
    # Metadata opcional (null = pattern matching)
    metadata: null
```

---

## 🎯 FASE 2: CORRECCIONES ALTAS (Prioridad 2)

### Tarea 2.1: Filtrar -Inf/Inf en summary_statistics.json
**Estimación:** 30 min  
**Archivos afectados:** `scripts/utils/generate_summary_report.R`

**Acciones:**
1. ✅ Agregar filtro de -Inf/Inf antes de generar top findings:
   ```r
   # Filtrar valores infinitos
   top_findings <- top_findings %>%
     filter(!is.infinite(log2_fold_change)) %>%
     filter(!is.na(log2_fold_change))
   ```

2. ✅ Agregar contador de casos filtrados:
   ```r
   filtered_count <- sum(is.infinite(data$log2_fold_change))
   if (filtered_count > 0) {
     cat(sprintf("⚠️  Warning: Filtered %d cases with infinite log2FC\n", filtered_count))
   }
   ```

3. ✅ Documentar en el summary por qué se filtraron

**Verificación:**
```bash
# Verificar que summary_statistics.json no tenga -Inf
grep -i "inf" results/summary/summary_statistics.json
# No debe retornar nada
```

---

### Tarea 2.2: Limpiar results/ de proyectos ajenos
**Estimación:** 15 min  
**Acciones:**
1. ✅ Identificar directorios que NO pertenecen al pipeline:
   ```bash
   # Directorios a mover/eliminar:
   results/ALS-treatments/
   results/ALS-trial/
   results/GDC-LGG-miRNA/
   results/PE/
   results/PE_IP/
   results/cont_IP/
   results/SOD1_paper1/
   ```

2. ✅ Mover a ubicación temporal o eliminar:
   ```bash
   mkdir -p ../old_results_backup
   mv results/ALS-treatments ../old_results_backup/
   # ... etc
   ```

3. ✅ Actualizar `.gitignore` si es necesario

---

### Tarea 2.3: Consolidar documentación
**Estimación:** 2 horas  
**Archivos afectados:** `*.md` en raíz, `docs/`

**Acciones:**
1. ✅ Crear estructura en `docs/`:
   ```
   docs/
   ├── README.md              # Índice de documentación
   ├── INSTALLATION.md        # Guía de instalación
   ├── CONFIGURATION.md       # Guía de configuración
   ├── USAGE.md               # Guía de uso
   ├── DEVELOPMENT.md         # Guía para desarrolladores
   ├── TROUBLESHOOTING.md     # Solución de problemas
   └── ARCHITECTURE.md        # Arquitectura del pipeline
   ```

2. ✅ Consolidar contenido de archivos duplicados:
   - `REVISION_*.md` → `docs/DEVELOPMENT.md`
   - `FASE*_IMPLEMENTACION_COMPLETADA.md` → `docs/ARCHITECTURE.md`
   - `IMPLEMENTACION_*.md` → `docs/ARCHITECTURE.md`
   - `PLAN_*.md` → `docs/DEVELOPMENT.md`

3. ✅ Eliminar archivos obsoletos (después de consolidar)
4. ✅ Actualizar `.gitignore` para ignorar archivos de desarrollo temporal

**Criterios para mantener archivos:**
- ✅ Mantener: `README.md`, `QUICK_START.md`, `docs/**/*.md`
- ❌ Eliminar: `*COMPLETADO*.md`, `*FASE*.md`, `*IMPLEMENTACION*.md`, `*PLAN*.md` (después de consolidar)

---

### Tarea 2.4: Estandarizar manejo de errores
**Estimación:** 3 horas  
**Archivos afectados:** `scripts/**/*.R`

**Acciones:**
1. ✅ Crear función estándar en `scripts/utils/error_handling.R`:
   ```r
   handle_pipeline_error <- function(error, context, log_file = NULL) {
     error_msg <- sprintf("[%s] %s: %s", 
                         format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
                         context,
                         error$message)
     
     # Log to file if provided
     if (!is.null(log_file)) {
       write(error_msg, log_file, append = TRUE)
     }
     
     # Print to console
     cat(sprintf("❌ ERROR: %s\n", error_msg))
     
     # Stop with informative message
     stop(error_msg, call. = FALSE)
   }
   ```

2. ✅ Actualizar todos los scripts para usar esta función:
   ```r
   data <- tryCatch({
     load_data(...)
   }, error = function(e) {
     handle_pipeline_error(e, context = "Step 1 - Data Loading", log_file = log_file)
   })
   ```

3. ✅ Agregar validación de inputs en cada script:
   ```r
   # Validar que archivo existe
   if (!file.exists(input_file)) {
     stop(sprintf("Input file not found: %s", input_file))
   }
   ```

---

## 🎯 FASE 3: MEJORAS DE CALIDAD (Prioridad 3)

### Tarea 3.1: Agregar validación de inputs al inicio
**Estimación:** 1 hora  
**Archivos afectados:** `rules/validation.smk`, `scripts/utils/validate_input.R`

**Acciones:**
1. ✅ Crear regla `validate_inputs` que se ejecute primero:
   ```python
   rule validate_inputs:
       input:
           config = CONFIG_FILE,
           raw_data = config["paths"]["data"]["raw"]
       output:
           "results/validation/inputs_validated.txt"
       script:
           "scripts/utils/validate_input.R"
   ```

2. ✅ Hacer que `rule all` dependa de `validate_inputs`:
   ```python
   rule all:
       input:
           rules.validate_inputs.output,  # ← PRIMERO
           rules.create_output_structure.output,
           ...
   ```

3. ✅ Validar:
   - Archivos de datos existen
   - Formato de datos es correcto
   - Columnas requeridas están presentes
   - Metadata (si existe) es válida

---

### Tarea 3.2: Actualizar metadata pipeline_info
**Estimación:** 30 min  
**Archivos afectados:** `scripts/utils/generate_pipeline_info.R`

**Acciones:**
1. ✅ Detectar todos los steps implementados automáticamente:
   ```r
   # Detectar steps con outputs
   steps_implemented <- c()
   for (step in c("step1", "step1_5", "step2", "step3", "step4", "step5", "step6", "step7")) {
     step_dir <- file.path(snakemake_dir, "results", step, "final")
     if (file.exists(step_dir) && file.info(step_dir)$isdir) {
       # Verificar que tiene outputs
       if (length(list.files(step_dir, recursive = TRUE)) > 0) {
         steps_implemented <- c(steps_implemented, step)
       }
     }
   }
   ```

2. ✅ Actualizar `execution_info.yaml` con todos los steps detectados

---

### Tarea 3.3: Documentar ordenamiento lógico
**Estimación:** 20 min  
**Archivos afectados:** `README.md`, `docs/ARCHITECTURE.md`

**Acciones:**
1. ✅ Agregar sección en README explicando el flujo:
   ```markdown
   ## Pipeline Flow
   
   The pipeline executes steps in this logical order:
   
   1. **Step 1**: Exploratory analysis
   2. **Step 1.5**: VAF quality control
   3. **Step 2**: Statistical comparisons (foundation for all downstream)
   4. **Step 7**: Clustering (discovers groups)
   5. **Step 5**: Family analysis (compares with biological families)
   6. **Step 6**: Expression correlation
   7. **Step 3**: Functional analysis (with context from steps above)
   8. **Step 4**: Biomarker analysis (integrates all insights)
   
   Note: Steps 3-7 can run in parallel after Step 2, but the logical order
   above reflects the analysis flow.
   ```

2. ✅ Agregar diagrama visual del flujo

---

## 📋 Checklist de Implementación

### FASE 1: Críticas (Día 1)
- [ ] Tarea 1.1: Hacer config.yaml portable
- [ ] Tarea 1.2: Unificar outputs/ vs results/
- [ ] Tarea 1.3: Agregar dependencias explícitas
- [ ] Tarea 1.4: Crear config.yaml.example

### FASE 2: Altas (Día 2)
- [ ] Tarea 2.1: Filtrar -Inf/Inf en summary
- [ ] Tarea 2.2: Limpiar results/ de proyectos ajenos
- [ ] Tarea 2.3: Consolidar documentación
- [ ] Tarea 2.4: Estandarizar manejo de errores

### FASE 3: Medias (Día 3)
- [ ] Tarea 3.1: Agregar validación de inputs
- [ ] Tarea 3.2: Actualizar metadata pipeline_info
- [ ] Tarea 3.3: Documentar ordenamiento lógico

---

## 🧪 Plan de Pruebas

Después de cada fase, ejecutar:

1. **Prueba de portabilidad:**
   ```bash
   # En otra máquina/directorio:
   cp config/config.yaml.example config/config.yaml
   # Editar paths
   snakemake -n  # Dry-run debe funcionar
   ```

2. **Prueba de dependencias:**
   ```bash
   snakemake -n all_step3
   # Debe mostrar que step2 se ejecutará primero
   ```

3. **Prueba de validación:**
   ```bash
   snakemake validate_inputs
   # Debe validar todos los inputs
   ```

4. **Prueba completa:**
   ```bash
   snakemake -j 4
   # Pipeline completo debe ejecutarse sin errores
   ```

---

## 📝 Notas de Implementación

- **Orden de ejecución:** FASE 1 primero (bloquea todo lo demás)
- **Testing:** Probar después de cada tarea, no esperar al final
- **Commits:** Hacer commit después de cada tarea completada
- **Documentación:** Actualizar README.md mientras se implementa

---

**Última actualización:** 2025-11-04

