# 📚 EXPLICACIÓN COMPLETA: ¿Qué se hizo y cómo funciona?

## 🎯 ¿Qué es Snakemake?

**Snakemake** es un sistema de workflow que automatiza análisis científicos. En lugar de ejecutar scripts manualmente uno por uno, defines **reglas** que especifican:
- **Qué inputs necesita** (archivos de datos)
- **Qué outputs genera** (figuras, tablas)
- **Cómo generarlos** (qué script R ejecutar)

**Ventaja**: Snakemake ejecuta solo lo necesario, en el orden correcto, y sabe qué está actualizado.

---

## 🔄 ¿Qué se hizo? Transformación de Pipeline Manual → Automatizado

### ANTES (Pipeline Manual):
```
Tu ejecutabas:
1. Rscript script1.R
2. Rscript script2.R
3. Rscript script3.R
...
(tenías que recordar el orden, rutas, dependencias)
```

### AHORA (Pipeline Snakemake):
```
Ejecutas:
snakemake -j 1

Snakemake:
1. Lee las reglas (qué necesita cada script)
2. Calcula el orden correcto
3. Ejecuta solo lo necesario
4. Verifica que los outputs se generaron
```

---

## 📁 Estructura Creada

### 1. **Snakefile** (Orquestador Principal)
```
Snakefile
├── Carga config/config.yaml
├── Incluye reglas de step1.smk
├── Incluye reglas de step1_5.smk
└── Define qué se ejecuta por defecto (rule all)
```

**Ejemplo del Snakefile:**
```python
configfile: "config/config.yaml"  # Carga configuración
include: "rules/step1.smk"       # Incluye reglas del Step 1
include: "rules/step1_5.smk"     # Incluye reglas del Step 1.5

rule all:
    input:
        rules.all_step1.output,        # Todos los outputs de Step 1
        rules.all_step1_5.output      # Todos los outputs de Step 1.5
```

---

### 2. **Reglas** (`rules/*.smk`)

Cada regla define **UNA tarea** del pipeline. Por ejemplo:

**Regla para Panel B (Step 1):**
```python
rule panel_b_gt_count_by_position:
    input:
        data = "ruta/al/dato.csv",           # ← Input necesario
        functions = "scripts/utils/functions.R"
    output:
        figure = "outputs/step1/figures/panelB.png",  # ← Output que genera
        table = "outputs/step1/tables/panelB.csv"
    script:
        "scripts/step1/01_panel_b.R"         # ← Script R que ejecuta
```

**Lo que hace Snakemake:**
1. Verifica si existe `outputs/step1/figures/panelB.png`
2. Si NO existe (o si el input cambió), ejecuta el script R
3. Si SÍ existe y está actualizado, lo omite (no lo vuelve a generar)

---

### 3. **Scripts R Adaptados** (`scripts/step1/*.R`)

**Antes (manual):**
```r
# Rutas hardcodeadas
data <- read.csv("/Users/cesaresparza/.../datos.csv")
output_fig <- "/Users/cesaresparza/.../figura.png"
```

**Ahora (Snakemake):**
```r
# Snakemake pasa las rutas automáticamente
input_file <- snakemake@input[["data"]]
output_fig <- snakemake@output[["figure"]]

data <- read.csv(input_file)
# ... análisis ...
ggsave(output_fig, plot, ...)
```

**Ventaja**: Mismo script, pero ahora recibe las rutas automáticamente.

---

### 4. **Configuración Centralizada** (`config/config.yaml`)

**Antes**: Rutas hardcodeadas en cada script.

**Ahora**: Todo en un solo archivo:
```yaml
paths:
  data:
    processed_clean: "/ruta/a/datos/procesados.csv"
    step1_original: "/ruta/a/datos/originales.csv"
  
analysis:
  vaf_filter_threshold: 0.5
  colors:
    gt: "#D62728"  # Rojo para G>T
```

**Ventaja**: Cambias las rutas una vez, todo el pipeline se actualiza.

---

### 5. **Environment Conda** (`environment.yaml`)

Define todas las dependencias (R, paquetes R, Python, Snakemake):

```yaml
name: als_mirna_pipeline
dependencies:
  - python=3.10
  - snakemake=7.32
  - r-base=4.3.2
  - r-tidyverse
  - r-ggplot2
  ...
```

**Ventaja**: Otro usuario puede recrear el ambiente exacto con:
```bash
conda env create -f environment.yaml
```

---

## 🔄 Flujo de Ejecución (Ejemplo: Step 1)

### Cuando ejecutas `snakemake -j 1`:

1. **Snakemake lee `Snakefile`**
   - Carga `config.yaml`
   - Incluye `rules/step1.smk`

2. **Snakemake construye el "grafo de dependencias"**
   ```
   all_step1 necesita:
     ├─ panelB.png (requiere datos + script panelB.R)
     ├─ panelC.png (requiere datos + script panelC.R)
     └─ panelD.png (requiere datos + script panelD.R)
     ...
   ```

3. **Snakemake decide qué ejecutar**
   - Si `panelB.png` NO existe → ejecuta `panelB.R`
   - Si `panelB.png` existe pero es más viejo que los inputs → re-ejecuta
   - Si está actualizado → omite (ahorra tiempo)

4. **Snakemake ejecuta en paralelo (si es posible)**
   - `panelB` y `panelC` pueden ejecutarse simultáneamente (no dependen uno del otro)
   - Pero `panelC` NO puede ejecutarse antes de cargar los datos

5. **Snakemake verifica outputs**
   - Si algún script falla, Snakemake se detiene
   - Si todo funciona, marca `all_step1` como completado

---

## 📊 Ejemplo Real: Paso 1.5

### Reglas definidas:

**Regla 1: `apply_vaf_filter`**
```python
Input:  step1_original_data.csv
Output: ALL_MUTATIONS_VAF_FILTERED.csv
        vaf_filter_report.csv
        vaf_statistics_by_type.csv
        vaf_statistics_by_mirna.csv
Script: 01_apply_vaf_filter.R
```

**Regla 2: `generate_diagnostic_figures`**
```python
Input:  (depende de Regla 1) → necesita los 4 CSVs de arriba
Output: 11 figuras PNG + 3 tablas CSV
Script: 02_generate_diagnostic_figures.R
```

**Regla 3: `all_step1_5`** (agregador)
```python
Input:  Todas las salidas de Regla 1 + Regla 2
Output: (ninguno nuevo, solo verifica que todo existe)
```

**Ejecución:**
```
snakemake -j 1 all_step1_5
  ↓
1. Ejecuta apply_vaf_filter → genera 4 CSVs
  ↓
2. Ejecuta generate_diagnostic_figures → genera 11 PNGs + 3 CSVs
  ↓
3. Verifica que todos los outputs existen → ✅ COMPLETO
```

---

## 🎯 Ventajas del Pipeline Automatizado

1. **Reproducible**: Otro usuario puede ejecutar exactamente lo mismo
2. **Eficiente**: Solo ejecuta lo que falta o cambió
3. **Orden correcto**: Respeta dependencias automáticamente
4. **Configurable**: Rutas y parámetros en un solo lugar
5. **Escalable**: Fácil agregar nuevos pasos (solo agregar reglas)

---

## 🚀 Cómo se Usa Ahora

```bash
# 1. Crear ambiente (una vez)
conda env create -f environment.yaml
conda activate als_mirna_pipeline

# 2. Configurar rutas (una vez)
# Editar config/config.yaml

# 3. Ejecutar (siempre)
snakemake -j 1              # Todo el pipeline
snakemake -j 1 all_step1    # Solo Step 1
snakemake -n                # Ver qué se ejecutaría (dry-run)
```

---

## 📝 Resumen de Archivos Creados/Modificados

### Nuevos archivos Snakemake:
- ✅ `Snakefile` - Orquestador principal
- ✅ `rules/step1.smk` - Reglas del Step 1
- ✅ `rules/step1_5.smk` - Reglas del Step 1.5
- ✅ `rules/viewers.smk` - Reglas para generar viewers HTML
- ✅ `config/config.yaml` - Configuración centralizada
- ✅ `environment.yaml` - Ambiente conda completo
- ✅ `.gitignore` - Para GitHub
- ✅ `README.md` - Instrucciones de uso

### Scripts R adaptados:
- ✅ `scripts/step1/*.R` - 6 scripts adaptados
- ✅ `scripts/step1_5/*.R` - 2 scripts adaptados
- ✅ `scripts/utils/*.R` - Funciones comunes y builders de viewers

### Estructura de outputs:
- ✅ `outputs/step1/` - Figuras, tablas, logs del Step 1
- ✅ `outputs/step1_5/` - Figuras, tablas, logs del Step 1.5
- ✅ `viewers/` - Viewers HTML generados automáticamente

---

## 🎓 Conclusión

**Lo que tenías**: Scripts R independientes que ejecutabas manualmente.

**Lo que tienes ahora**: Un pipeline automatizado que:
- Se ejecuta con un comando
- Maneja dependencias automáticamente
- Es reproducible y portable
- Está listo para GitHub
- Puede usarse como herramienta por otros usuarios

**Complejidad agregada**: Mínima (solo aprendes la sintaxis de Snakemake)
**Beneficio obtenido**: Máximo (automatización completa)


## 🎯 ¿Qué es Snakemake?

**Snakemake** es un sistema de workflow que automatiza análisis científicos. En lugar de ejecutar scripts manualmente uno por uno, defines **reglas** que especifican:
- **Qué inputs necesita** (archivos de datos)
- **Qué outputs genera** (figuras, tablas)
- **Cómo generarlos** (qué script R ejecutar)

**Ventaja**: Snakemake ejecuta solo lo necesario, en el orden correcto, y sabe qué está actualizado.

---

## 🔄 ¿Qué se hizo? Transformación de Pipeline Manual → Automatizado

### ANTES (Pipeline Manual):
```
Tu ejecutabas:
1. Rscript script1.R
2. Rscript script2.R
3. Rscript script3.R
...
(tenías que recordar el orden, rutas, dependencias)
```

### AHORA (Pipeline Snakemake):
```
Ejecutas:
snakemake -j 1

Snakemake:
1. Lee las reglas (qué necesita cada script)
2. Calcula el orden correcto
3. Ejecuta solo lo necesario
4. Verifica que los outputs se generaron
```

---

## 📁 Estructura Creada

### 1. **Snakefile** (Orquestador Principal)
```
Snakefile
├── Carga config/config.yaml
├── Incluye reglas de step1.smk
├── Incluye reglas de step1_5.smk
└── Define qué se ejecuta por defecto (rule all)
```

**Ejemplo del Snakefile:**
```python
configfile: "config/config.yaml"  # Carga configuración
include: "rules/step1.smk"       # Incluye reglas del Step 1
include: "rules/step1_5.smk"     # Incluye reglas del Step 1.5

rule all:
    input:
        rules.all_step1.output,        # Todos los outputs de Step 1
        rules.all_step1_5.output      # Todos los outputs de Step 1.5
```

---

### 2. **Reglas** (`rules/*.smk`)

Cada regla define **UNA tarea** del pipeline. Por ejemplo:

**Regla para Panel B (Step 1):**
```python
rule panel_b_gt_count_by_position:
    input:
        data = "ruta/al/dato.csv",           # ← Input necesario
        functions = "scripts/utils/functions.R"
    output:
        figure = "outputs/step1/figures/panelB.png",  # ← Output que genera
        table = "outputs/step1/tables/panelB.csv"
    script:
        "scripts/step1/01_panel_b.R"         # ← Script R que ejecuta
```

**Lo que hace Snakemake:**
1. Verifica si existe `outputs/step1/figures/panelB.png`
2. Si NO existe (o si el input cambió), ejecuta el script R
3. Si SÍ existe y está actualizado, lo omite (no lo vuelve a generar)

---

### 3. **Scripts R Adaptados** (`scripts/step1/*.R`)

**Antes (manual):**
```r
# Rutas hardcodeadas
data <- read.csv("/Users/cesaresparza/.../datos.csv")
output_fig <- "/Users/cesaresparza/.../figura.png"
```

**Ahora (Snakemake):**
```r
# Snakemake pasa las rutas automáticamente
input_file <- snakemake@input[["data"]]
output_fig <- snakemake@output[["figure"]]

data <- read.csv(input_file)
# ... análisis ...
ggsave(output_fig, plot, ...)
```

**Ventaja**: Mismo script, pero ahora recibe las rutas automáticamente.

---

### 4. **Configuración Centralizada** (`config/config.yaml`)

**Antes**: Rutas hardcodeadas en cada script.

**Ahora**: Todo en un solo archivo:
```yaml
paths:
  data:
    processed_clean: "/ruta/a/datos/procesados.csv"
    step1_original: "/ruta/a/datos/originales.csv"
  
analysis:
  vaf_filter_threshold: 0.5
  colors:
    gt: "#D62728"  # Rojo para G>T
```

**Ventaja**: Cambias las rutas una vez, todo el pipeline se actualiza.

---

### 5. **Environment Conda** (`environment.yaml`)

Define todas las dependencias (R, paquetes R, Python, Snakemake):

```yaml
name: als_mirna_pipeline
dependencies:
  - python=3.10
  - snakemake=7.32
  - r-base=4.3.2
  - r-tidyverse
  - r-ggplot2
  ...
```

**Ventaja**: Otro usuario puede recrear el ambiente exacto con:
```bash
conda env create -f environment.yaml
```

---

## 🔄 Flujo de Ejecución (Ejemplo: Step 1)

### Cuando ejecutas `snakemake -j 1`:

1. **Snakemake lee `Snakefile`**
   - Carga `config.yaml`
   - Incluye `rules/step1.smk`

2. **Snakemake construye el "grafo de dependencias"**
   ```
   all_step1 necesita:
     ├─ panelB.png (requiere datos + script panelB.R)
     ├─ panelC.png (requiere datos + script panelC.R)
     └─ panelD.png (requiere datos + script panelD.R)
     ...
   ```

3. **Snakemake decide qué ejecutar**
   - Si `panelB.png` NO existe → ejecuta `panelB.R`
   - Si `panelB.png` existe pero es más viejo que los inputs → re-ejecuta
   - Si está actualizado → omite (ahorra tiempo)

4. **Snakemake ejecuta en paralelo (si es posible)**
   - `panelB` y `panelC` pueden ejecutarse simultáneamente (no dependen uno del otro)
   - Pero `panelC` NO puede ejecutarse antes de cargar los datos

5. **Snakemake verifica outputs**
   - Si algún script falla, Snakemake se detiene
   - Si todo funciona, marca `all_step1` como completado

---

## 📊 Ejemplo Real: Paso 1.5

### Reglas definidas:

**Regla 1: `apply_vaf_filter`**
```python
Input:  step1_original_data.csv
Output: ALL_MUTATIONS_VAF_FILTERED.csv
        vaf_filter_report.csv
        vaf_statistics_by_type.csv
        vaf_statistics_by_mirna.csv
Script: 01_apply_vaf_filter.R
```

**Regla 2: `generate_diagnostic_figures`**
```python
Input:  (depende de Regla 1) → necesita los 4 CSVs de arriba
Output: 11 figuras PNG + 3 tablas CSV
Script: 02_generate_diagnostic_figures.R
```

**Regla 3: `all_step1_5`** (agregador)
```python
Input:  Todas las salidas de Regla 1 + Regla 2
Output: (ninguno nuevo, solo verifica que todo existe)
```

**Ejecución:**
```
snakemake -j 1 all_step1_5
  ↓
1. Ejecuta apply_vaf_filter → genera 4 CSVs
  ↓
2. Ejecuta generate_diagnostic_figures → genera 11 PNGs + 3 CSVs
  ↓
3. Verifica que todos los outputs existen → ✅ COMPLETO
```

---

## 🎯 Ventajas del Pipeline Automatizado

1. **Reproducible**: Otro usuario puede ejecutar exactamente lo mismo
2. **Eficiente**: Solo ejecuta lo que falta o cambió
3. **Orden correcto**: Respeta dependencias automáticamente
4. **Configurable**: Rutas y parámetros en un solo lugar
5. **Escalable**: Fácil agregar nuevos pasos (solo agregar reglas)

---

## 🚀 Cómo se Usa Ahora

```bash
# 1. Crear ambiente (una vez)
conda env create -f environment.yaml
conda activate als_mirna_pipeline

# 2. Configurar rutas (una vez)
# Editar config/config.yaml

# 3. Ejecutar (siempre)
snakemake -j 1              # Todo el pipeline
snakemake -j 1 all_step1    # Solo Step 1
snakemake -n                # Ver qué se ejecutaría (dry-run)
```

---

## 📝 Resumen de Archivos Creados/Modificados

### Nuevos archivos Snakemake:
- ✅ `Snakefile` - Orquestador principal
- ✅ `rules/step1.smk` - Reglas del Step 1
- ✅ `rules/step1_5.smk` - Reglas del Step 1.5
- ✅ `rules/viewers.smk` - Reglas para generar viewers HTML
- ✅ `config/config.yaml` - Configuración centralizada
- ✅ `environment.yaml` - Ambiente conda completo
- ✅ `.gitignore` - Para GitHub
- ✅ `README.md` - Instrucciones de uso

### Scripts R adaptados:
- ✅ `scripts/step1/*.R` - 6 scripts adaptados
- ✅ `scripts/step1_5/*.R` - 2 scripts adaptados
- ✅ `scripts/utils/*.R` - Funciones comunes y builders de viewers

### Estructura de outputs:
- ✅ `outputs/step1/` - Figuras, tablas, logs del Step 1
- ✅ `outputs/step1_5/` - Figuras, tablas, logs del Step 1.5
- ✅ `viewers/` - Viewers HTML generados automáticamente

---

## 🎓 Conclusión

**Lo que tenías**: Scripts R independientes que ejecutabas manualmente.

**Lo que tienes ahora**: Un pipeline automatizado que:
- Se ejecuta con un comando
- Maneja dependencias automáticamente
- Es reproducible y portable
- Está listo para GitHub
- Puede usarse como herramienta por otros usuarios

**Complejidad agregada**: Mínima (solo aprendes la sintaxis de Snakemake)
**Beneficio obtenido**: Máximo (automatización completa)


## 🎯 ¿Qué es Snakemake?

**Snakemake** es un sistema de workflow que automatiza análisis científicos. En lugar de ejecutar scripts manualmente uno por uno, defines **reglas** que especifican:
- **Qué inputs necesita** (archivos de datos)
- **Qué outputs genera** (figuras, tablas)
- **Cómo generarlos** (qué script R ejecutar)

**Ventaja**: Snakemake ejecuta solo lo necesario, en el orden correcto, y sabe qué está actualizado.

---

## 🔄 ¿Qué se hizo? Transformación de Pipeline Manual → Automatizado

### ANTES (Pipeline Manual):
```
Tu ejecutabas:
1. Rscript script1.R
2. Rscript script2.R
3. Rscript script3.R
...
(tenías que recordar el orden, rutas, dependencias)
```

### AHORA (Pipeline Snakemake):
```
Ejecutas:
snakemake -j 1

Snakemake:
1. Lee las reglas (qué necesita cada script)
2. Calcula el orden correcto
3. Ejecuta solo lo necesario
4. Verifica que los outputs se generaron
```

---

## 📁 Estructura Creada

### 1. **Snakefile** (Orquestador Principal)
```
Snakefile
├── Carga config/config.yaml
├── Incluye reglas de step1.smk
├── Incluye reglas de step1_5.smk
└── Define qué se ejecuta por defecto (rule all)
```

**Ejemplo del Snakefile:**
```python
configfile: "config/config.yaml"  # Carga configuración
include: "rules/step1.smk"       # Incluye reglas del Step 1
include: "rules/step1_5.smk"     # Incluye reglas del Step 1.5

rule all:
    input:
        rules.all_step1.output,        # Todos los outputs de Step 1
        rules.all_step1_5.output      # Todos los outputs de Step 1.5
```

---

### 2. **Reglas** (`rules/*.smk`)

Cada regla define **UNA tarea** del pipeline. Por ejemplo:

**Regla para Panel B (Step 1):**
```python
rule panel_b_gt_count_by_position:
    input:
        data = "ruta/al/dato.csv",           # ← Input necesario
        functions = "scripts/utils/functions.R"
    output:
        figure = "outputs/step1/figures/panelB.png",  # ← Output que genera
        table = "outputs/step1/tables/panelB.csv"
    script:
        "scripts/step1/01_panel_b.R"         # ← Script R que ejecuta
```

**Lo que hace Snakemake:**
1. Verifica si existe `outputs/step1/figures/panelB.png`
2. Si NO existe (o si el input cambió), ejecuta el script R
3. Si SÍ existe y está actualizado, lo omite (no lo vuelve a generar)

---

### 3. **Scripts R Adaptados** (`scripts/step1/*.R`)

**Antes (manual):**
```r
# Rutas hardcodeadas
data <- read.csv("/Users/cesaresparza/.../datos.csv")
output_fig <- "/Users/cesaresparza/.../figura.png"
```

**Ahora (Snakemake):**
```r
# Snakemake pasa las rutas automáticamente
input_file <- snakemake@input[["data"]]
output_fig <- snakemake@output[["figure"]]

data <- read.csv(input_file)
# ... análisis ...
ggsave(output_fig, plot, ...)
```

**Ventaja**: Mismo script, pero ahora recibe las rutas automáticamente.

---

### 4. **Configuración Centralizada** (`config/config.yaml`)

**Antes**: Rutas hardcodeadas en cada script.

**Ahora**: Todo en un solo archivo:
```yaml
paths:
  data:
    processed_clean: "/ruta/a/datos/procesados.csv"
    step1_original: "/ruta/a/datos/originales.csv"
  
analysis:
  vaf_filter_threshold: 0.5
  colors:
    gt: "#D62728"  # Rojo para G>T
```

**Ventaja**: Cambias las rutas una vez, todo el pipeline se actualiza.

---

### 5. **Environment Conda** (`environment.yaml`)

Define todas las dependencias (R, paquetes R, Python, Snakemake):

```yaml
name: als_mirna_pipeline
dependencies:
  - python=3.10
  - snakemake=7.32
  - r-base=4.3.2
  - r-tidyverse
  - r-ggplot2
  ...
```

**Ventaja**: Otro usuario puede recrear el ambiente exacto con:
```bash
conda env create -f environment.yaml
```

---

## 🔄 Flujo de Ejecución (Ejemplo: Step 1)

### Cuando ejecutas `snakemake -j 1`:

1. **Snakemake lee `Snakefile`**
   - Carga `config.yaml`
   - Incluye `rules/step1.smk`

2. **Snakemake construye el "grafo de dependencias"**
   ```
   all_step1 necesita:
     ├─ panelB.png (requiere datos + script panelB.R)
     ├─ panelC.png (requiere datos + script panelC.R)
     └─ panelD.png (requiere datos + script panelD.R)
     ...
   ```

3. **Snakemake decide qué ejecutar**
   - Si `panelB.png` NO existe → ejecuta `panelB.R`
   - Si `panelB.png` existe pero es más viejo que los inputs → re-ejecuta
   - Si está actualizado → omite (ahorra tiempo)

4. **Snakemake ejecuta en paralelo (si es posible)**
   - `panelB` y `panelC` pueden ejecutarse simultáneamente (no dependen uno del otro)
   - Pero `panelC` NO puede ejecutarse antes de cargar los datos

5. **Snakemake verifica outputs**
   - Si algún script falla, Snakemake se detiene
   - Si todo funciona, marca `all_step1` como completado

---

## 📊 Ejemplo Real: Paso 1.5

### Reglas definidas:

**Regla 1: `apply_vaf_filter`**
```python
Input:  step1_original_data.csv
Output: ALL_MUTATIONS_VAF_FILTERED.csv
        vaf_filter_report.csv
        vaf_statistics_by_type.csv
        vaf_statistics_by_mirna.csv
Script: 01_apply_vaf_filter.R
```

**Regla 2: `generate_diagnostic_figures`**
```python
Input:  (depende de Regla 1) → necesita los 4 CSVs de arriba
Output: 11 figuras PNG + 3 tablas CSV
Script: 02_generate_diagnostic_figures.R
```

**Regla 3: `all_step1_5`** (agregador)
```python
Input:  Todas las salidas de Regla 1 + Regla 2
Output: (ninguno nuevo, solo verifica que todo existe)
```

**Ejecución:**
```
snakemake -j 1 all_step1_5
  ↓
1. Ejecuta apply_vaf_filter → genera 4 CSVs
  ↓
2. Ejecuta generate_diagnostic_figures → genera 11 PNGs + 3 CSVs
  ↓
3. Verifica que todos los outputs existen → ✅ COMPLETO
```

---

## 🎯 Ventajas del Pipeline Automatizado

1. **Reproducible**: Otro usuario puede ejecutar exactamente lo mismo
2. **Eficiente**: Solo ejecuta lo que falta o cambió
3. **Orden correcto**: Respeta dependencias automáticamente
4. **Configurable**: Rutas y parámetros en un solo lugar
5. **Escalable**: Fácil agregar nuevos pasos (solo agregar reglas)

---

## 🚀 Cómo se Usa Ahora

```bash
# 1. Crear ambiente (una vez)
conda env create -f environment.yaml
conda activate als_mirna_pipeline

# 2. Configurar rutas (una vez)
# Editar config/config.yaml

# 3. Ejecutar (siempre)
snakemake -j 1              # Todo el pipeline
snakemake -j 1 all_step1    # Solo Step 1
snakemake -n                # Ver qué se ejecutaría (dry-run)
```

---

## 📝 Resumen de Archivos Creados/Modificados

### Nuevos archivos Snakemake:
- ✅ `Snakefile` - Orquestador principal
- ✅ `rules/step1.smk` - Reglas del Step 1
- ✅ `rules/step1_5.smk` - Reglas del Step 1.5
- ✅ `rules/viewers.smk` - Reglas para generar viewers HTML
- ✅ `config/config.yaml` - Configuración centralizada
- ✅ `environment.yaml` - Ambiente conda completo
- ✅ `.gitignore` - Para GitHub
- ✅ `README.md` - Instrucciones de uso

### Scripts R adaptados:
- ✅ `scripts/step1/*.R` - 6 scripts adaptados
- ✅ `scripts/step1_5/*.R` - 2 scripts adaptados
- ✅ `scripts/utils/*.R` - Funciones comunes y builders de viewers

### Estructura de outputs:
- ✅ `outputs/step1/` - Figuras, tablas, logs del Step 1
- ✅ `outputs/step1_5/` - Figuras, tablas, logs del Step 1.5
- ✅ `viewers/` - Viewers HTML generados automáticamente

---

## 🎓 Conclusión

**Lo que tenías**: Scripts R independientes que ejecutabas manualmente.

**Lo que tienes ahora**: Un pipeline automatizado que:
- Se ejecuta con un comando
- Maneja dependencias automáticamente
- Es reproducible y portable
- Está listo para GitHub
- Puede usarse como herramienta por otros usuarios

**Complejidad agregada**: Mínima (solo aprendes la sintaxis de Snakemake)
**Beneficio obtenido**: Máximo (automatización completa)

