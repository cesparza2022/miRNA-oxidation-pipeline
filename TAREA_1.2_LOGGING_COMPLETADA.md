# ✅ TAREA 1.2: Manejo de Errores Estandarizado - COMPLETADA

**Fecha:** 2025-11-02  
**Estado:** Sistema de logging implementado y probado

---

## 📋 RESUMEN

Se ha implementado un sistema completo de logging y manejo de errores estandarizado para el pipeline. El sistema proporciona logging estructurado, manejo de errores consistente, y mejor trazabilidad.

---

## ✅ LO IMPLEMENTADO

### 1. **Sistema de Logging** (`scripts/utils/logging.R`)

**Funciones principales:**

#### Logging Functions:
- `log_info()` - Mensajes informativos
- `log_warning()` - Advertencias
- `log_error()` - Errores (no fatales)
- `log_success()` - Operaciones exitosas
- `log_debug()` - Mensajes de debug (solo si log level = DEBUG)

#### Error Handling:
- `handle_error()` - Manejo estandarizado de errores
  - Logging automático
  - Stack trace opcional
  - Cleanup functions
  - Exit codes configurables

#### Section Separators:
- `log_section()` - Separadores para secciones principales
- `log_subsection()` - Separadores para subsections

#### Utilities:
- `initialize_logging()` - Inicializa logging para job de Snakemake
- `safe_execute()` - Wrapper para ejecución segura con error handling
- `get_timestamp()` - Timestamps consistentes

**Características:**
- ✅ Logging estructurado con timestamps
- ✅ Contexto opcional para cada mensaje
- ✅ Niveles de log configurables (DEBUG, INFO, WARNING, ERROR, FATAL)
- ✅ Escritura automática a archivos de log
- ✅ Formato legible con emojis en consola
- ✅ Integración con Snakemake (log files automáticos)

---

### 2. **Integración en Panel B**

**Antes:**
```r
cat("📋 Parameters:\n")
cat("   Input:", input_file, "\n")
data <- load_processed_data(input_file)
```

**Ahora:**
```r
log_section("PANEL B: G>T Count by Position")
log_info(paste("Input file:", input_file))

data <- tryCatch({
  result <- load_processed_data(input_file)
  log_success(paste("Data loaded:", nrow(result), "rows"))
  result
}, error = function(e) {
  handle_error(e, context = "Panel B - Data Loading", exit_code = 1)
})
```

**Beneficios:**
- ✅ Mensajes estructurados con timestamps
- ✅ Logging automático a archivo
- ✅ Error handling con stack trace
- ✅ Más fácil debuggear problemas

---

### 3. **Carga Automática**

**En `functions_common.R`:**
- ✅ Carga automática de `logging.R`
- ✅ Método robusto que funciona con Rscript y Snakemake
- ✅ No falla si logging no está disponible (graceful degradation)

---

## 🎯 CARACTERÍSTICAS DEL SISTEMA

### Niveles de Log

Configurables vía variable de entorno:
```bash
export PIPELINE_LOG_LEVEL=0  # DEBUG (más verboso)
export PIPELINE_LOG_LEVEL=1  # INFO (default)
export PIPELINE_LOG_LEVEL=2  # WARNING
export PIPELINE_LOG_LEVEL=3  # ERROR
export PIPELINE_LOG_LEVEL=4  # FATAL (menos verboso)
```

### Formato de Logs

**Consola:**
```
2025-11-02 20:00:15 [INFO] [Panel B] Input file: /path/to/data.csv
2025-11-02 20:00:16 [SUCCESS] [Panel B] Data loaded: 15,234 rows, 417 columns
```

**Archivo de Log:**
```
═══════════════════════════════════════════════════════════════════
PIPELINE EXECUTION LOG
Context: Panel B
Started: 2025-11-02 20:00:15
═══════════════════════════════════════════════════════════════════

2025-11-02 20:00:15 [INFO] [Panel B] Input file: /path/to/data.csv
2025-11-02 20:00:16 [SUCCESS] [Panel B] Data loaded: 15,234 rows, 417 columns
```

---

### Manejo de Errores

**Ejemplo:**
```r
data <- tryCatch({
  load_processed_data(input_file)
}, error = function(e) {
  handle_error(
    e,
    context = "Panel B - Data Loading",
    exit_code = 1,
    log_file = log_file,
    cleanup = function() {
      # Cleanup code here
    }
  )
})
```

**Output en consola:**
```
═══════════════════════════════════════════════════════════════════
❌ ERROR OCCURRED
═══════════════════════════════════════════════════════════════════

Context: Panel B - Data Loading
Time: 2025-11-02 20:00:16
Error: Input file not found: /path/to/data.csv

Call stack:
  1: load_processed_data(...)
  2: validate_input(...)
```

**Output en log file:**
```
═══════════════════════════════════════════════════════════════════
ERROR LOG
═══════════════════════════════════════════════════════════════════
Timestamp: 2025-11-02 20:00:16
Context: Panel B - Data Loading
Error Message: Input file not found: /path/to/data.csv

Call Stack:
  1: load_processed_data(...)
  2: validate_input(...)
```

---

## 📊 COMPARACIÓN ANTES/DESPUÉS

### Antes:
- ❌ Mensajes inconsistentes (`cat()`, `print()`, `message()`)
- ❌ Sin timestamps
- ❌ Sin logging a archivos
- ❌ Errores sin contexto
- ❌ Difícil rastrear qué pasó

### Ahora:
- ✅ Mensajes estandarizados con funciones comunes
- ✅ Timestamps automáticos
- ✅ Logging automático a archivos
- ✅ Contexto claro en cada mensaje
- ✅ Stack traces cuando hay errores
- ✅ Fácil debugging

---

## 📝 ARCHIVOS MODIFICADOS

### Nuevos:
1. `scripts/utils/logging.R` (13KB) - Sistema completo de logging

### Modificados:
1. `scripts/utils/functions_common.R` - Carga logging automáticamente
2. `scripts/step1/01_panel_b_gt_count_by_position.R` - Actualizado con logging

---

## 🧪 CÓMO PROBAR

### Test 1: Logging básico
```r
source("scripts/utils/logging.R")
initialize_logging("test.log", context = "Test")
log_info("This is an info message")
log_success("Operation completed")
```

### Test 2: Error handling
```r
tryCatch({
  stop("Test error")
}, error = function(e) {
  handle_error(e, context = "Test")
})
```

### Test 3: En Snakemake
```bash
snakemake panel_b_gt_count_by_position
# Check: outputs/step1/logs/panel_b.log
```

---

## 🎯 PRÓXIMOS PASOS

### Para completar Tarea 1.2:

1. ✅ Sistema de logging creado
2. ✅ Integrado en Panel B (ejemplo)
3. ⏳ Actualizar resto de scripts de Step 1 (opcional, puede hacerse gradualmente)
4. ⏳ Actualizar scripts de Step 1.5 (opcional)

**Nota:** Panel B sirve como ejemplo. Los demás scripts pueden actualizarse gradualmente o según necesidad.

---

## 📚 DOCUMENTACIÓN

### Uso Básico:

```r
# Inicializar logging
initialize_logging(log_file, context = "My Script")

# Usar logging
log_section("Starting Analysis")
log_info("Processing data...")
log_success("Data processed successfully")

# Manejo de errores
tryCatch({
  # código
}, error = function(e) {
  handle_error(e, context = "Analysis")
})
```

### Integración con Snakemake:

```r
# En script de Snakemake
log_file <- snakemake@log[[1]]
initialize_logging(log_file, context = "Panel X")
```

---

**Estado:** ✅ TAREA 1.2 - Sistema de Logging COMPLETADO  
**Siguiente:** Opcional - actualizar resto de scripts, o continuar con otras tareas


**Fecha:** 2025-11-02  
**Estado:** Sistema de logging implementado y probado

---

## 📋 RESUMEN

Se ha implementado un sistema completo de logging y manejo de errores estandarizado para el pipeline. El sistema proporciona logging estructurado, manejo de errores consistente, y mejor trazabilidad.

---

## ✅ LO IMPLEMENTADO

### 1. **Sistema de Logging** (`scripts/utils/logging.R`)

**Funciones principales:**

#### Logging Functions:
- `log_info()` - Mensajes informativos
- `log_warning()` - Advertencias
- `log_error()` - Errores (no fatales)
- `log_success()` - Operaciones exitosas
- `log_debug()` - Mensajes de debug (solo si log level = DEBUG)

#### Error Handling:
- `handle_error()` - Manejo estandarizado de errores
  - Logging automático
  - Stack trace opcional
  - Cleanup functions
  - Exit codes configurables

#### Section Separators:
- `log_section()` - Separadores para secciones principales
- `log_subsection()` - Separadores para subsections

#### Utilities:
- `initialize_logging()` - Inicializa logging para job de Snakemake
- `safe_execute()` - Wrapper para ejecución segura con error handling
- `get_timestamp()` - Timestamps consistentes

**Características:**
- ✅ Logging estructurado con timestamps
- ✅ Contexto opcional para cada mensaje
- ✅ Niveles de log configurables (DEBUG, INFO, WARNING, ERROR, FATAL)
- ✅ Escritura automática a archivos de log
- ✅ Formato legible con emojis en consola
- ✅ Integración con Snakemake (log files automáticos)

---

### 2. **Integración en Panel B**

**Antes:**
```r
cat("📋 Parameters:\n")
cat("   Input:", input_file, "\n")
data <- load_processed_data(input_file)
```

**Ahora:**
```r
log_section("PANEL B: G>T Count by Position")
log_info(paste("Input file:", input_file))

data <- tryCatch({
  result <- load_processed_data(input_file)
  log_success(paste("Data loaded:", nrow(result), "rows"))
  result
}, error = function(e) {
  handle_error(e, context = "Panel B - Data Loading", exit_code = 1)
})
```

**Beneficios:**
- ✅ Mensajes estructurados con timestamps
- ✅ Logging automático a archivo
- ✅ Error handling con stack trace
- ✅ Más fácil debuggear problemas

---

### 3. **Carga Automática**

**En `functions_common.R`:**
- ✅ Carga automática de `logging.R`
- ✅ Método robusto que funciona con Rscript y Snakemake
- ✅ No falla si logging no está disponible (graceful degradation)

---

## 🎯 CARACTERÍSTICAS DEL SISTEMA

### Niveles de Log

Configurables vía variable de entorno:
```bash
export PIPELINE_LOG_LEVEL=0  # DEBUG (más verboso)
export PIPELINE_LOG_LEVEL=1  # INFO (default)
export PIPELINE_LOG_LEVEL=2  # WARNING
export PIPELINE_LOG_LEVEL=3  # ERROR
export PIPELINE_LOG_LEVEL=4  # FATAL (menos verboso)
```

### Formato de Logs

**Consola:**
```
2025-11-02 20:00:15 [INFO] [Panel B] Input file: /path/to/data.csv
2025-11-02 20:00:16 [SUCCESS] [Panel B] Data loaded: 15,234 rows, 417 columns
```

**Archivo de Log:**
```
═══════════════════════════════════════════════════════════════════
PIPELINE EXECUTION LOG
Context: Panel B
Started: 2025-11-02 20:00:15
═══════════════════════════════════════════════════════════════════

2025-11-02 20:00:15 [INFO] [Panel B] Input file: /path/to/data.csv
2025-11-02 20:00:16 [SUCCESS] [Panel B] Data loaded: 15,234 rows, 417 columns
```

---

### Manejo de Errores

**Ejemplo:**
```r
data <- tryCatch({
  load_processed_data(input_file)
}, error = function(e) {
  handle_error(
    e,
    context = "Panel B - Data Loading",
    exit_code = 1,
    log_file = log_file,
    cleanup = function() {
      # Cleanup code here
    }
  )
})
```

**Output en consola:**
```
═══════════════════════════════════════════════════════════════════
❌ ERROR OCCURRED
═══════════════════════════════════════════════════════════════════

Context: Panel B - Data Loading
Time: 2025-11-02 20:00:16
Error: Input file not found: /path/to/data.csv

Call stack:
  1: load_processed_data(...)
  2: validate_input(...)
```

**Output en log file:**
```
═══════════════════════════════════════════════════════════════════
ERROR LOG
═══════════════════════════════════════════════════════════════════
Timestamp: 2025-11-02 20:00:16
Context: Panel B - Data Loading
Error Message: Input file not found: /path/to/data.csv

Call Stack:
  1: load_processed_data(...)
  2: validate_input(...)
```

---

## 📊 COMPARACIÓN ANTES/DESPUÉS

### Antes:
- ❌ Mensajes inconsistentes (`cat()`, `print()`, `message()`)
- ❌ Sin timestamps
- ❌ Sin logging a archivos
- ❌ Errores sin contexto
- ❌ Difícil rastrear qué pasó

### Ahora:
- ✅ Mensajes estandarizados con funciones comunes
- ✅ Timestamps automáticos
- ✅ Logging automático a archivos
- ✅ Contexto claro en cada mensaje
- ✅ Stack traces cuando hay errores
- ✅ Fácil debugging

---

## 📝 ARCHIVOS MODIFICADOS

### Nuevos:
1. `scripts/utils/logging.R` (13KB) - Sistema completo de logging

### Modificados:
1. `scripts/utils/functions_common.R` - Carga logging automáticamente
2. `scripts/step1/01_panel_b_gt_count_by_position.R` - Actualizado con logging

---

## 🧪 CÓMO PROBAR

### Test 1: Logging básico
```r
source("scripts/utils/logging.R")
initialize_logging("test.log", context = "Test")
log_info("This is an info message")
log_success("Operation completed")
```

### Test 2: Error handling
```r
tryCatch({
  stop("Test error")
}, error = function(e) {
  handle_error(e, context = "Test")
})
```

### Test 3: En Snakemake
```bash
snakemake panel_b_gt_count_by_position
# Check: outputs/step1/logs/panel_b.log
```

---

## 🎯 PRÓXIMOS PASOS

### Para completar Tarea 1.2:

1. ✅ Sistema de logging creado
2. ✅ Integrado en Panel B (ejemplo)
3. ⏳ Actualizar resto de scripts de Step 1 (opcional, puede hacerse gradualmente)
4. ⏳ Actualizar scripts de Step 1.5 (opcional)

**Nota:** Panel B sirve como ejemplo. Los demás scripts pueden actualizarse gradualmente o según necesidad.

---

## 📚 DOCUMENTACIÓN

### Uso Básico:

```r
# Inicializar logging
initialize_logging(log_file, context = "My Script")

# Usar logging
log_section("Starting Analysis")
log_info("Processing data...")
log_success("Data processed successfully")

# Manejo de errores
tryCatch({
  # código
}, error = function(e) {
  handle_error(e, context = "Analysis")
})
```

### Integración con Snakemake:

```r
# En script de Snakemake
log_file <- snakemake@log[[1]]
initialize_logging(log_file, context = "Panel X")
```

---

**Estado:** ✅ TAREA 1.2 - Sistema de Logging COMPLETADO  
**Siguiente:** Opcional - actualizar resto de scripts, o continuar con otras tareas


**Fecha:** 2025-11-02  
**Estado:** Sistema de logging implementado y probado

---

## 📋 RESUMEN

Se ha implementado un sistema completo de logging y manejo de errores estandarizado para el pipeline. El sistema proporciona logging estructurado, manejo de errores consistente, y mejor trazabilidad.

---

## ✅ LO IMPLEMENTADO

### 1. **Sistema de Logging** (`scripts/utils/logging.R`)

**Funciones principales:**

#### Logging Functions:
- `log_info()` - Mensajes informativos
- `log_warning()` - Advertencias
- `log_error()` - Errores (no fatales)
- `log_success()` - Operaciones exitosas
- `log_debug()` - Mensajes de debug (solo si log level = DEBUG)

#### Error Handling:
- `handle_error()` - Manejo estandarizado de errores
  - Logging automático
  - Stack trace opcional
  - Cleanup functions
  - Exit codes configurables

#### Section Separators:
- `log_section()` - Separadores para secciones principales
- `log_subsection()` - Separadores para subsections

#### Utilities:
- `initialize_logging()` - Inicializa logging para job de Snakemake
- `safe_execute()` - Wrapper para ejecución segura con error handling
- `get_timestamp()` - Timestamps consistentes

**Características:**
- ✅ Logging estructurado con timestamps
- ✅ Contexto opcional para cada mensaje
- ✅ Niveles de log configurables (DEBUG, INFO, WARNING, ERROR, FATAL)
- ✅ Escritura automática a archivos de log
- ✅ Formato legible con emojis en consola
- ✅ Integración con Snakemake (log files automáticos)

---

### 2. **Integración en Panel B**

**Antes:**
```r
cat("📋 Parameters:\n")
cat("   Input:", input_file, "\n")
data <- load_processed_data(input_file)
```

**Ahora:**
```r
log_section("PANEL B: G>T Count by Position")
log_info(paste("Input file:", input_file))

data <- tryCatch({
  result <- load_processed_data(input_file)
  log_success(paste("Data loaded:", nrow(result), "rows"))
  result
}, error = function(e) {
  handle_error(e, context = "Panel B - Data Loading", exit_code = 1)
})
```

**Beneficios:**
- ✅ Mensajes estructurados con timestamps
- ✅ Logging automático a archivo
- ✅ Error handling con stack trace
- ✅ Más fácil debuggear problemas

---

### 3. **Carga Automática**

**En `functions_common.R`:**
- ✅ Carga automática de `logging.R`
- ✅ Método robusto que funciona con Rscript y Snakemake
- ✅ No falla si logging no está disponible (graceful degradation)

---

## 🎯 CARACTERÍSTICAS DEL SISTEMA

### Niveles de Log

Configurables vía variable de entorno:
```bash
export PIPELINE_LOG_LEVEL=0  # DEBUG (más verboso)
export PIPELINE_LOG_LEVEL=1  # INFO (default)
export PIPELINE_LOG_LEVEL=2  # WARNING
export PIPELINE_LOG_LEVEL=3  # ERROR
export PIPELINE_LOG_LEVEL=4  # FATAL (menos verboso)
```

### Formato de Logs

**Consola:**
```
2025-11-02 20:00:15 [INFO] [Panel B] Input file: /path/to/data.csv
2025-11-02 20:00:16 [SUCCESS] [Panel B] Data loaded: 15,234 rows, 417 columns
```

**Archivo de Log:**
```
═══════════════════════════════════════════════════════════════════
PIPELINE EXECUTION LOG
Context: Panel B
Started: 2025-11-02 20:00:15
═══════════════════════════════════════════════════════════════════

2025-11-02 20:00:15 [INFO] [Panel B] Input file: /path/to/data.csv
2025-11-02 20:00:16 [SUCCESS] [Panel B] Data loaded: 15,234 rows, 417 columns
```

---

### Manejo de Errores

**Ejemplo:**
```r
data <- tryCatch({
  load_processed_data(input_file)
}, error = function(e) {
  handle_error(
    e,
    context = "Panel B - Data Loading",
    exit_code = 1,
    log_file = log_file,
    cleanup = function() {
      # Cleanup code here
    }
  )
})
```

**Output en consola:**
```
═══════════════════════════════════════════════════════════════════
❌ ERROR OCCURRED
═══════════════════════════════════════════════════════════════════

Context: Panel B - Data Loading
Time: 2025-11-02 20:00:16
Error: Input file not found: /path/to/data.csv

Call stack:
  1: load_processed_data(...)
  2: validate_input(...)
```

**Output en log file:**
```
═══════════════════════════════════════════════════════════════════
ERROR LOG
═══════════════════════════════════════════════════════════════════
Timestamp: 2025-11-02 20:00:16
Context: Panel B - Data Loading
Error Message: Input file not found: /path/to/data.csv

Call Stack:
  1: load_processed_data(...)
  2: validate_input(...)
```

---

## 📊 COMPARACIÓN ANTES/DESPUÉS

### Antes:
- ❌ Mensajes inconsistentes (`cat()`, `print()`, `message()`)
- ❌ Sin timestamps
- ❌ Sin logging a archivos
- ❌ Errores sin contexto
- ❌ Difícil rastrear qué pasó

### Ahora:
- ✅ Mensajes estandarizados con funciones comunes
- ✅ Timestamps automáticos
- ✅ Logging automático a archivos
- ✅ Contexto claro en cada mensaje
- ✅ Stack traces cuando hay errores
- ✅ Fácil debugging

---

## 📝 ARCHIVOS MODIFICADOS

### Nuevos:
1. `scripts/utils/logging.R` (13KB) - Sistema completo de logging

### Modificados:
1. `scripts/utils/functions_common.R` - Carga logging automáticamente
2. `scripts/step1/01_panel_b_gt_count_by_position.R` - Actualizado con logging

---

## 🧪 CÓMO PROBAR

### Test 1: Logging básico
```r
source("scripts/utils/logging.R")
initialize_logging("test.log", context = "Test")
log_info("This is an info message")
log_success("Operation completed")
```

### Test 2: Error handling
```r
tryCatch({
  stop("Test error")
}, error = function(e) {
  handle_error(e, context = "Test")
})
```

### Test 3: En Snakemake
```bash
snakemake panel_b_gt_count_by_position
# Check: outputs/step1/logs/panel_b.log
```

---

## 🎯 PRÓXIMOS PASOS

### Para completar Tarea 1.2:

1. ✅ Sistema de logging creado
2. ✅ Integrado en Panel B (ejemplo)
3. ⏳ Actualizar resto de scripts de Step 1 (opcional, puede hacerse gradualmente)
4. ⏳ Actualizar scripts de Step 1.5 (opcional)

**Nota:** Panel B sirve como ejemplo. Los demás scripts pueden actualizarse gradualmente o según necesidad.

---

## 📚 DOCUMENTACIÓN

### Uso Básico:

```r
# Inicializar logging
initialize_logging(log_file, context = "My Script")

# Usar logging
log_section("Starting Analysis")
log_info("Processing data...")
log_success("Data processed successfully")

# Manejo de errores
tryCatch({
  # código
}, error = function(e) {
  handle_error(e, context = "Analysis")
})
```

### Integración con Snakemake:

```r
# En script de Snakemake
log_file <- snakemake@log[[1]]
initialize_logging(log_file, context = "Panel X")
```

---

**Estado:** ✅ TAREA 1.2 - Sistema de Logging COMPLETADO  
**Siguiente:** Opcional - actualizar resto de scripts, o continuar con otras tareas

