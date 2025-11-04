# 📊 Análisis Completo del Repositorio en GitHub

**Repositorio:** https://github.com/cesparza2022/als-mirna-oxidation-pipeline  
**Fecha de análisis:** 2025-11-01

---

## 📁 Estructura del Repositorio

### 🎯 Archivos Principales

```
als-mirna-oxidation-pipeline/
├── README.md                    # ⭐ README principal (formato GitHub estándar)
├── README_SIMPLE.md            # 📖 Guía rápida para usuarios
├── Snakefile                    # 🐍 Orquestador principal del pipeline
├── run.sh                       # 🚀 Script wrapper simple
│
├── config/
│   ├── config.yaml.example      # ⚙️ Template de configuración
│   └── config.yaml              # ❌ NO se sube (rutas personales)
│
├── scripts/                     # 📜 Scripts R de análisis
│   ├── step1/                   # Paso 1: Análisis exploratorio
│   │   ├── 01_panel_b_gt_count_by_position.R
│   │   ├── 02_panel_c_gx_spectrum.R
│   │   ├── 03_panel_d_positional_fraction.R
│   │   ├── 04_panel_e_gcontent.R
│   │   ├── 05_panel_f_seed_vs_nonseed.R
│   │   └── 06_panel_g_gt_specificity.R
│   │
│   ├── step1_5/                 # Paso 1.5: Control calidad VAF
│   │   ├── 01_apply_vaf_filter.R
│   │   └── 02_generate_diagnostic_figures.R
│   │
│   └── utils/                    # Utilidades compartidas
│       ├── functions_common.R
│       ├── build_step1_viewer.R
│       └── build_step1_5_viewer.R
│
├── rules/                       # 🐍 Reglas Snakemake
│   ├── step1.smk               # Reglas para Step 1
│   ├── step1_5.smk             # Reglas para Step 1.5
│   └── viewers.smk             # Reglas para generar viewers HTML
│
├── envs/                        # 🌍 Ambientes Conda
│   ├── r_base.yaml
│   └── r_analysis.yaml
│
└── documentation/               # 📚 Documentación (varios .md)
```

---

## 🔄 Cómo Funciona el Pipeline

### Flujo General

```
INPUT: CSV con datos procesados
  ↓
Snakefile (orquestador principal)
  ↓
├──→ rules/step1.smk
│     ├──→ Panel B: G>T count by position
│     ├──→ Panel C: G>X spectrum
│     ├──→ Panel D: Positional fraction
│     ├──→ Panel E: G-content
│     ├──→ Panel F: Seed vs Non-seed
│     └──→ Panel G: G>T specificity
│     ↓
│     outputs/step1/figures/ (6 PNGs)
│     outputs/step1/tables/ (6 CSVs)
│     ↓
│     viewers/step1.html (generado automáticamente)
│
├──→ rules/step1_5.smk
│     ├──→ Regla 1: Aplicar filtro VAF
│     │     └──→ outputs/step1_5/tables/ALL_MUTATIONS_VAF_FILTERED.csv
│     └──→ Regla 2: Generar figuras diagnósticas
│           └──→ outputs/step1_5/figures/ (11 PNGs)
│     ↓
│     viewers/step1_5.html (generado automáticamente)
│
└──→ rules/step2.smk (futuro)
      └──→ Comparaciones grupo vs grupo
```

---

## 📊 Step 1: Análisis Exploratorio

### Scripts y sus Funciones

**Panel B** (`01_panel_b_gt_count_by_position.R`):
- **Input**: `processed_clean.csv`
- **Qué hace**: Cuenta G>T por posición
- **Output**: Figura PNG + tabla CSV

**Panel C** (`02_panel_c_gx_spectrum.R`):
- **Input**: `raw_data.txt` (archivo original)
- **Qué hace**: Espectro de mutaciones G>X (G>C, G>A, G>T)
- **Output**: Stacked bar chart por posición

**Panel D** (`03_panel_d_positional_fraction.R`):
- **Input**: `raw_data.txt`
- **Qué hace**: Fracción posicional de mutaciones
- **Output**: Gráfica de fracciones por posición

**Panel E** (`04_panel_e_gcontent.R`):
- **Input**: `processed_clean.csv`
- **Qué hace**: Contenido de G por posición
- **Output**: Landscape de G-content

**Panel F** (`05_panel_f_seed_vs_nonseed.R`):
- **Input**: `processed_clean.csv`
- **Qué hace**: Comparación seed vs non-seed
- **Output**: Comparación estadística

**Panel G** (`06_panel_g_gt_specificity.R`):
- **Input**: `processed_clean.csv`
- **Qué hace**: Especificidad de G>T vs otras transiciones G
- **Output**: Análisis de especificidad

---

## 🔬 Step 1.5: Control de Calidad VAF

### Regla 1: Aplicar Filtro VAF (`01_apply_vaf_filter.R`)

**Input**: `step1_original_data.csv` (necesita SNV + total counts)

**Qué hace**:
1. Carga datos con columnas de SNV y totales
2. Calcula VAF para cada mutación en cada muestra
3. Filtra valores con VAF >= 0.5 (artefactos técnicos)
4. Genera reportes de filtrado

**Outputs**:
- `ALL_MUTATIONS_VAF_FILTERED.csv` (datos filtrados)
- `vaf_filter_report.csv` (qué se filtró)
- `vaf_statistics_by_type.csv` (estadísticas por tipo)
- `vaf_statistics_by_mirna.csv` (estadísticas por miRNA)

**Tiempo**: ~2 minutos (optimizado, vectorizado)

---

### Regla 2: Figuras Diagnósticas (`02_generate_diagnostic_figures.R`)

**Input**: Datos filtrados de Regla 1

**Qué hace**: Genera 11 figuras diagnósticas

**Outputs**:
- 4 figuras de QC (distribución VAF, impacto del filtro, etc.)
- 7 figuras diagnósticas (heatmaps, violines, bubble plots, etc.)

**Tiempo**: ~2-3 minutos

---

## 🔄 Flujo de Datos Detallado

### Inputs del Pipeline

1. **`processed_clean.csv`**
   - Formato: miRNA name, pos:mut, columnas de muestra
   - Usado por: Step 1 (Paneles B, E, F, G)
   - Origen: Datos ya procesados (split-collapse)

2. **`raw_data.txt`** (miRNA_count.Q33.txt)
   - Formato original
   - Usado por: Step 1 (Paneles C, D)
   - Procesado con `load_and_process_raw_data()`

3. **`step1_original_data.csv`**
   - Necesita columnas SNV + totales
   - Usado por: Step 1.5 (VAF filtering)

---

### Procesamiento

**Step 1 - Paneles independientes:**
- Pueden ejecutarse en paralelo (`snakemake -j 4`)
- Cada panel genera su figura + tabla
- Viewer HTML se genera al final

**Step 1.5 - Secuencial:**
- Regla 1 primero (filtro VAF)
- Regla 2 después (usa datos filtrados)
- Viewer HTML se genera al final

---

## 🐍 Cómo Funciona Snakemake

### Conceptos Clave

1. **Rules (Reglas)**: Define qué archivos se generan y cómo
2. **Inputs**: Archivos necesarios para generar outputs
3. **Outputs**: Archivos que se generan
4. **Scripts**: Scripts R que hacen el trabajo
5. **Dependencies**: Snakemake maneja automáticamente las dependencias

### Ejemplo de Regla

```python
rule panel_b_gt_count_by_position:
    input:
        data = INPUT_DATA_CLEAN,
        script = "scripts/step1/01_panel_b_gt_count_by_position.R",
        functions = "scripts/utils/functions_common.R"
    output:
        figure = "outputs/step1/figures/step1_panelB_gt_count_by_position.png",
        table = "outputs/step1/tables/TABLE_1.B_gt_counts_by_position.csv"
    script: "scripts/step1/01_panel_b_gt_count_by_position.R"
```

**Cómo funciona**:
1. Snakemake ve que necesita el `output`
2. Verifica si el `input` existe
3. Si el output no existe o input es más nuevo, ejecuta el `script`
4. El script R usa `snakemake@input` y `snakemake@output` para acceder a rutas

---

## ⚙️ Configuración

### config/config.yaml.example

Template que los usuarios copian a `config/config.yaml`:

```yaml
paths:
  data:
    raw: "/path/to/raw/data"
    processed_clean: "/path/to/processed/data"
    step1_original: "/path/to/original/data"

analysis:
  vaf_filter_threshold: 0.5
  
resources:
  threads: 4
```

**Por qué .example**:
- Cada usuario tiene sus propias rutas
- `config.yaml` real está en `.gitignore` (no se sube)
- Usuario copia template y edita sus rutas

---

## 🎯 Ejecución

### Opción 1: Snakemake Directo

```bash
# Pipeline completo
snakemake -j 4

# Solo Step 1
snakemake -j 4 all_step1

# Solo Step 1.5
snakemake -j 1 all_step1_5

# Ver qué se ejecutaría (sin ejecutar)
snakemake -j 4 -n
```

### Opción 2: Script Wrapper

```bash
./run.sh /path/to/input.csv
```

---

## 📈 Outputs Generados

### Step 1
- **6 figuras PNG**: Paneles B, C, D, E, F, G
- **6 tablas CSV**: Estadísticas de cada panel
- **1 viewer HTML**: Visualización interactiva

### Step 1.5
- **11 figuras PNG**: QC + diagnósticas
- **7 tablas CSV**: Datos filtrados + estadísticas
- **1 viewer HTML**: Visualización interactiva

**Total**: 17 figuras + 13 tablas + 2 viewers HTML

---

## 🔍 Puntos Clave del Diseño

### 1. Modularidad
- Cada panel es un script independiente
- Fácil agregar nuevos análisis
- Fácil modificar existentes sin afectar otros

### 2. Reproducibilidad
- Snakemake maneja dependencias automáticamente
- Mismo input → mismo output
- Logs guardados para debugging

### 3. Optimización
- Paralelización (`-j 4`)
- Scripts vectorizados (Step 1.5 optimizado)
- Solo regenera lo necesario

### 4. Portabilidad
- Configuración separada de código
- Rutas relativas donde es posible
- Ambientes conda para dependencias

---

## 🚧 Estado Actual

### ✅ Completado

- **Step 1**: 100% funcional (6 paneles)
- **Step 1.5**: 100% funcional (2 reglas)
- **Viewers HTML**: Generación automática
- **Documentación**: Completa
- **Optimización**: Implementada

### 📋 Pendiente

- **Step 2**: Estructura lista, contenido por completar
- **Auto-configuración**: run.sh necesita actualizar config.yaml automáticamente
- **Validación de input**: Script para validar formato antes de ejecutar

---

## 💡 Mejoras Futuras

1. **Input único**: Un solo archivo CSV en lugar de 3
2. **Auto-detección**: Pipeline detecta tipo de archivo
3. **Metadata opcional**: Step 2 con grupos opcionales
4. **Tests automatizados**: Validar que todo funciona
5. **CI/CD**: GitHub Actions para testing automático

---

## 📚 Archivos de Documentación en el Repo

- `README.md` - Principal (para GitHub)
- `README_SIMPLE.md` - Guía rápida
- `GUIA_USO_PASO_A_PASO.md` - Guía detallada
- `OPTIMIZACIONES_RENDIMIENTO.md` - Optimizaciones implementadas
- `ANALISIS_OBJETIVO_vs_REALIDAD.md` - Análisis de gaps
- `PREPARACION_GITHUB.md` - Guía de preparación
- Varios otros docs de desarrollo

---

**Última actualización**: 2025-11-01  
**Versión del pipeline**: 1.0.0


**Repositorio:** https://github.com/cesparza2022/als-mirna-oxidation-pipeline  
**Fecha de análisis:** 2025-11-01

---

## 📁 Estructura del Repositorio

### 🎯 Archivos Principales

```
als-mirna-oxidation-pipeline/
├── README.md                    # ⭐ README principal (formato GitHub estándar)
├── README_SIMPLE.md            # 📖 Guía rápida para usuarios
├── Snakefile                    # 🐍 Orquestador principal del pipeline
├── run.sh                       # 🚀 Script wrapper simple
│
├── config/
│   ├── config.yaml.example      # ⚙️ Template de configuración
│   └── config.yaml              # ❌ NO se sube (rutas personales)
│
├── scripts/                     # 📜 Scripts R de análisis
│   ├── step1/                   # Paso 1: Análisis exploratorio
│   │   ├── 01_panel_b_gt_count_by_position.R
│   │   ├── 02_panel_c_gx_spectrum.R
│   │   ├── 03_panel_d_positional_fraction.R
│   │   ├── 04_panel_e_gcontent.R
│   │   ├── 05_panel_f_seed_vs_nonseed.R
│   │   └── 06_panel_g_gt_specificity.R
│   │
│   ├── step1_5/                 # Paso 1.5: Control calidad VAF
│   │   ├── 01_apply_vaf_filter.R
│   │   └── 02_generate_diagnostic_figures.R
│   │
│   └── utils/                    # Utilidades compartidas
│       ├── functions_common.R
│       ├── build_step1_viewer.R
│       └── build_step1_5_viewer.R
│
├── rules/                       # 🐍 Reglas Snakemake
│   ├── step1.smk               # Reglas para Step 1
│   ├── step1_5.smk             # Reglas para Step 1.5
│   └── viewers.smk             # Reglas para generar viewers HTML
│
├── envs/                        # 🌍 Ambientes Conda
│   ├── r_base.yaml
│   └── r_analysis.yaml
│
└── documentation/               # 📚 Documentación (varios .md)
```

---

## 🔄 Cómo Funciona el Pipeline

### Flujo General

```
INPUT: CSV con datos procesados
  ↓
Snakefile (orquestador principal)
  ↓
├──→ rules/step1.smk
│     ├──→ Panel B: G>T count by position
│     ├──→ Panel C: G>X spectrum
│     ├──→ Panel D: Positional fraction
│     ├──→ Panel E: G-content
│     ├──→ Panel F: Seed vs Non-seed
│     └──→ Panel G: G>T specificity
│     ↓
│     outputs/step1/figures/ (6 PNGs)
│     outputs/step1/tables/ (6 CSVs)
│     ↓
│     viewers/step1.html (generado automáticamente)
│
├──→ rules/step1_5.smk
│     ├──→ Regla 1: Aplicar filtro VAF
│     │     └──→ outputs/step1_5/tables/ALL_MUTATIONS_VAF_FILTERED.csv
│     └──→ Regla 2: Generar figuras diagnósticas
│           └──→ outputs/step1_5/figures/ (11 PNGs)
│     ↓
│     viewers/step1_5.html (generado automáticamente)
│
└──→ rules/step2.smk (futuro)
      └──→ Comparaciones grupo vs grupo
```

---

## 📊 Step 1: Análisis Exploratorio

### Scripts y sus Funciones

**Panel B** (`01_panel_b_gt_count_by_position.R`):
- **Input**: `processed_clean.csv`
- **Qué hace**: Cuenta G>T por posición
- **Output**: Figura PNG + tabla CSV

**Panel C** (`02_panel_c_gx_spectrum.R`):
- **Input**: `raw_data.txt` (archivo original)
- **Qué hace**: Espectro de mutaciones G>X (G>C, G>A, G>T)
- **Output**: Stacked bar chart por posición

**Panel D** (`03_panel_d_positional_fraction.R`):
- **Input**: `raw_data.txt`
- **Qué hace**: Fracción posicional de mutaciones
- **Output**: Gráfica de fracciones por posición

**Panel E** (`04_panel_e_gcontent.R`):
- **Input**: `processed_clean.csv`
- **Qué hace**: Contenido de G por posición
- **Output**: Landscape de G-content

**Panel F** (`05_panel_f_seed_vs_nonseed.R`):
- **Input**: `processed_clean.csv`
- **Qué hace**: Comparación seed vs non-seed
- **Output**: Comparación estadística

**Panel G** (`06_panel_g_gt_specificity.R`):
- **Input**: `processed_clean.csv`
- **Qué hace**: Especificidad de G>T vs otras transiciones G
- **Output**: Análisis de especificidad

---

## 🔬 Step 1.5: Control de Calidad VAF

### Regla 1: Aplicar Filtro VAF (`01_apply_vaf_filter.R`)

**Input**: `step1_original_data.csv` (necesita SNV + total counts)

**Qué hace**:
1. Carga datos con columnas de SNV y totales
2. Calcula VAF para cada mutación en cada muestra
3. Filtra valores con VAF >= 0.5 (artefactos técnicos)
4. Genera reportes de filtrado

**Outputs**:
- `ALL_MUTATIONS_VAF_FILTERED.csv` (datos filtrados)
- `vaf_filter_report.csv` (qué se filtró)
- `vaf_statistics_by_type.csv` (estadísticas por tipo)
- `vaf_statistics_by_mirna.csv` (estadísticas por miRNA)

**Tiempo**: ~2 minutos (optimizado, vectorizado)

---

### Regla 2: Figuras Diagnósticas (`02_generate_diagnostic_figures.R`)

**Input**: Datos filtrados de Regla 1

**Qué hace**: Genera 11 figuras diagnósticas

**Outputs**:
- 4 figuras de QC (distribución VAF, impacto del filtro, etc.)
- 7 figuras diagnósticas (heatmaps, violines, bubble plots, etc.)

**Tiempo**: ~2-3 minutos

---

## 🔄 Flujo de Datos Detallado

### Inputs del Pipeline

1. **`processed_clean.csv`**
   - Formato: miRNA name, pos:mut, columnas de muestra
   - Usado por: Step 1 (Paneles B, E, F, G)
   - Origen: Datos ya procesados (split-collapse)

2. **`raw_data.txt`** (miRNA_count.Q33.txt)
   - Formato original
   - Usado por: Step 1 (Paneles C, D)
   - Procesado con `load_and_process_raw_data()`

3. **`step1_original_data.csv`**
   - Necesita columnas SNV + totales
   - Usado por: Step 1.5 (VAF filtering)

---

### Procesamiento

**Step 1 - Paneles independientes:**
- Pueden ejecutarse en paralelo (`snakemake -j 4`)
- Cada panel genera su figura + tabla
- Viewer HTML se genera al final

**Step 1.5 - Secuencial:**
- Regla 1 primero (filtro VAF)
- Regla 2 después (usa datos filtrados)
- Viewer HTML se genera al final

---

## 🐍 Cómo Funciona Snakemake

### Conceptos Clave

1. **Rules (Reglas)**: Define qué archivos se generan y cómo
2. **Inputs**: Archivos necesarios para generar outputs
3. **Outputs**: Archivos que se generan
4. **Scripts**: Scripts R que hacen el trabajo
5. **Dependencies**: Snakemake maneja automáticamente las dependencias

### Ejemplo de Regla

```python
rule panel_b_gt_count_by_position:
    input:
        data = INPUT_DATA_CLEAN,
        script = "scripts/step1/01_panel_b_gt_count_by_position.R",
        functions = "scripts/utils/functions_common.R"
    output:
        figure = "outputs/step1/figures/step1_panelB_gt_count_by_position.png",
        table = "outputs/step1/tables/TABLE_1.B_gt_counts_by_position.csv"
    script: "scripts/step1/01_panel_b_gt_count_by_position.R"
```

**Cómo funciona**:
1. Snakemake ve que necesita el `output`
2. Verifica si el `input` existe
3. Si el output no existe o input es más nuevo, ejecuta el `script`
4. El script R usa `snakemake@input` y `snakemake@output` para acceder a rutas

---

## ⚙️ Configuración

### config/config.yaml.example

Template que los usuarios copian a `config/config.yaml`:

```yaml
paths:
  data:
    raw: "/path/to/raw/data"
    processed_clean: "/path/to/processed/data"
    step1_original: "/path/to/original/data"

analysis:
  vaf_filter_threshold: 0.5
  
resources:
  threads: 4
```

**Por qué .example**:
- Cada usuario tiene sus propias rutas
- `config.yaml` real está en `.gitignore` (no se sube)
- Usuario copia template y edita sus rutas

---

## 🎯 Ejecución

### Opción 1: Snakemake Directo

```bash
# Pipeline completo
snakemake -j 4

# Solo Step 1
snakemake -j 4 all_step1

# Solo Step 1.5
snakemake -j 1 all_step1_5

# Ver qué se ejecutaría (sin ejecutar)
snakemake -j 4 -n
```

### Opción 2: Script Wrapper

```bash
./run.sh /path/to/input.csv
```

---

## 📈 Outputs Generados

### Step 1
- **6 figuras PNG**: Paneles B, C, D, E, F, G
- **6 tablas CSV**: Estadísticas de cada panel
- **1 viewer HTML**: Visualización interactiva

### Step 1.5
- **11 figuras PNG**: QC + diagnósticas
- **7 tablas CSV**: Datos filtrados + estadísticas
- **1 viewer HTML**: Visualización interactiva

**Total**: 17 figuras + 13 tablas + 2 viewers HTML

---

## 🔍 Puntos Clave del Diseño

### 1. Modularidad
- Cada panel es un script independiente
- Fácil agregar nuevos análisis
- Fácil modificar existentes sin afectar otros

### 2. Reproducibilidad
- Snakemake maneja dependencias automáticamente
- Mismo input → mismo output
- Logs guardados para debugging

### 3. Optimización
- Paralelización (`-j 4`)
- Scripts vectorizados (Step 1.5 optimizado)
- Solo regenera lo necesario

### 4. Portabilidad
- Configuración separada de código
- Rutas relativas donde es posible
- Ambientes conda para dependencias

---

## 🚧 Estado Actual

### ✅ Completado

- **Step 1**: 100% funcional (6 paneles)
- **Step 1.5**: 100% funcional (2 reglas)
- **Viewers HTML**: Generación automática
- **Documentación**: Completa
- **Optimización**: Implementada

### 📋 Pendiente

- **Step 2**: Estructura lista, contenido por completar
- **Auto-configuración**: run.sh necesita actualizar config.yaml automáticamente
- **Validación de input**: Script para validar formato antes de ejecutar

---

## 💡 Mejoras Futuras

1. **Input único**: Un solo archivo CSV en lugar de 3
2. **Auto-detección**: Pipeline detecta tipo de archivo
3. **Metadata opcional**: Step 2 con grupos opcionales
4. **Tests automatizados**: Validar que todo funciona
5. **CI/CD**: GitHub Actions para testing automático

---

## 📚 Archivos de Documentación en el Repo

- `README.md` - Principal (para GitHub)
- `README_SIMPLE.md` - Guía rápida
- `GUIA_USO_PASO_A_PASO.md` - Guía detallada
- `OPTIMIZACIONES_RENDIMIENTO.md` - Optimizaciones implementadas
- `ANALISIS_OBJETIVO_vs_REALIDAD.md` - Análisis de gaps
- `PREPARACION_GITHUB.md` - Guía de preparación
- Varios otros docs de desarrollo

---

**Última actualización**: 2025-11-01  
**Versión del pipeline**: 1.0.0


**Repositorio:** https://github.com/cesparza2022/als-mirna-oxidation-pipeline  
**Fecha de análisis:** 2025-11-01

---

## 📁 Estructura del Repositorio

### 🎯 Archivos Principales

```
als-mirna-oxidation-pipeline/
├── README.md                    # ⭐ README principal (formato GitHub estándar)
├── README_SIMPLE.md            # 📖 Guía rápida para usuarios
├── Snakefile                    # 🐍 Orquestador principal del pipeline
├── run.sh                       # 🚀 Script wrapper simple
│
├── config/
│   ├── config.yaml.example      # ⚙️ Template de configuración
│   └── config.yaml              # ❌ NO se sube (rutas personales)
│
├── scripts/                     # 📜 Scripts R de análisis
│   ├── step1/                   # Paso 1: Análisis exploratorio
│   │   ├── 01_panel_b_gt_count_by_position.R
│   │   ├── 02_panel_c_gx_spectrum.R
│   │   ├── 03_panel_d_positional_fraction.R
│   │   ├── 04_panel_e_gcontent.R
│   │   ├── 05_panel_f_seed_vs_nonseed.R
│   │   └── 06_panel_g_gt_specificity.R
│   │
│   ├── step1_5/                 # Paso 1.5: Control calidad VAF
│   │   ├── 01_apply_vaf_filter.R
│   │   └── 02_generate_diagnostic_figures.R
│   │
│   └── utils/                    # Utilidades compartidas
│       ├── functions_common.R
│       ├── build_step1_viewer.R
│       └── build_step1_5_viewer.R
│
├── rules/                       # 🐍 Reglas Snakemake
│   ├── step1.smk               # Reglas para Step 1
│   ├── step1_5.smk             # Reglas para Step 1.5
│   └── viewers.smk             # Reglas para generar viewers HTML
│
├── envs/                        # 🌍 Ambientes Conda
│   ├── r_base.yaml
│   └── r_analysis.yaml
│
└── documentation/               # 📚 Documentación (varios .md)
```

---

## 🔄 Cómo Funciona el Pipeline

### Flujo General

```
INPUT: CSV con datos procesados
  ↓
Snakefile (orquestador principal)
  ↓
├──→ rules/step1.smk
│     ├──→ Panel B: G>T count by position
│     ├──→ Panel C: G>X spectrum
│     ├──→ Panel D: Positional fraction
│     ├──→ Panel E: G-content
│     ├──→ Panel F: Seed vs Non-seed
│     └──→ Panel G: G>T specificity
│     ↓
│     outputs/step1/figures/ (6 PNGs)
│     outputs/step1/tables/ (6 CSVs)
│     ↓
│     viewers/step1.html (generado automáticamente)
│
├──→ rules/step1_5.smk
│     ├──→ Regla 1: Aplicar filtro VAF
│     │     └──→ outputs/step1_5/tables/ALL_MUTATIONS_VAF_FILTERED.csv
│     └──→ Regla 2: Generar figuras diagnósticas
│           └──→ outputs/step1_5/figures/ (11 PNGs)
│     ↓
│     viewers/step1_5.html (generado automáticamente)
│
└──→ rules/step2.smk (futuro)
      └──→ Comparaciones grupo vs grupo
```

---

## 📊 Step 1: Análisis Exploratorio

### Scripts y sus Funciones

**Panel B** (`01_panel_b_gt_count_by_position.R`):
- **Input**: `processed_clean.csv`
- **Qué hace**: Cuenta G>T por posición
- **Output**: Figura PNG + tabla CSV

**Panel C** (`02_panel_c_gx_spectrum.R`):
- **Input**: `raw_data.txt` (archivo original)
- **Qué hace**: Espectro de mutaciones G>X (G>C, G>A, G>T)
- **Output**: Stacked bar chart por posición

**Panel D** (`03_panel_d_positional_fraction.R`):
- **Input**: `raw_data.txt`
- **Qué hace**: Fracción posicional de mutaciones
- **Output**: Gráfica de fracciones por posición

**Panel E** (`04_panel_e_gcontent.R`):
- **Input**: `processed_clean.csv`
- **Qué hace**: Contenido de G por posición
- **Output**: Landscape de G-content

**Panel F** (`05_panel_f_seed_vs_nonseed.R`):
- **Input**: `processed_clean.csv`
- **Qué hace**: Comparación seed vs non-seed
- **Output**: Comparación estadística

**Panel G** (`06_panel_g_gt_specificity.R`):
- **Input**: `processed_clean.csv`
- **Qué hace**: Especificidad de G>T vs otras transiciones G
- **Output**: Análisis de especificidad

---

## 🔬 Step 1.5: Control de Calidad VAF

### Regla 1: Aplicar Filtro VAF (`01_apply_vaf_filter.R`)

**Input**: `step1_original_data.csv` (necesita SNV + total counts)

**Qué hace**:
1. Carga datos con columnas de SNV y totales
2. Calcula VAF para cada mutación en cada muestra
3. Filtra valores con VAF >= 0.5 (artefactos técnicos)
4. Genera reportes de filtrado

**Outputs**:
- `ALL_MUTATIONS_VAF_FILTERED.csv` (datos filtrados)
- `vaf_filter_report.csv` (qué se filtró)
- `vaf_statistics_by_type.csv` (estadísticas por tipo)
- `vaf_statistics_by_mirna.csv` (estadísticas por miRNA)

**Tiempo**: ~2 minutos (optimizado, vectorizado)

---

### Regla 2: Figuras Diagnósticas (`02_generate_diagnostic_figures.R`)

**Input**: Datos filtrados de Regla 1

**Qué hace**: Genera 11 figuras diagnósticas

**Outputs**:
- 4 figuras de QC (distribución VAF, impacto del filtro, etc.)
- 7 figuras diagnósticas (heatmaps, violines, bubble plots, etc.)

**Tiempo**: ~2-3 minutos

---

## 🔄 Flujo de Datos Detallado

### Inputs del Pipeline

1. **`processed_clean.csv`**
   - Formato: miRNA name, pos:mut, columnas de muestra
   - Usado por: Step 1 (Paneles B, E, F, G)
   - Origen: Datos ya procesados (split-collapse)

2. **`raw_data.txt`** (miRNA_count.Q33.txt)
   - Formato original
   - Usado por: Step 1 (Paneles C, D)
   - Procesado con `load_and_process_raw_data()`

3. **`step1_original_data.csv`**
   - Necesita columnas SNV + totales
   - Usado por: Step 1.5 (VAF filtering)

---

### Procesamiento

**Step 1 - Paneles independientes:**
- Pueden ejecutarse en paralelo (`snakemake -j 4`)
- Cada panel genera su figura + tabla
- Viewer HTML se genera al final

**Step 1.5 - Secuencial:**
- Regla 1 primero (filtro VAF)
- Regla 2 después (usa datos filtrados)
- Viewer HTML se genera al final

---

## 🐍 Cómo Funciona Snakemake

### Conceptos Clave

1. **Rules (Reglas)**: Define qué archivos se generan y cómo
2. **Inputs**: Archivos necesarios para generar outputs
3. **Outputs**: Archivos que se generan
4. **Scripts**: Scripts R que hacen el trabajo
5. **Dependencies**: Snakemake maneja automáticamente las dependencias

### Ejemplo de Regla

```python
rule panel_b_gt_count_by_position:
    input:
        data = INPUT_DATA_CLEAN,
        script = "scripts/step1/01_panel_b_gt_count_by_position.R",
        functions = "scripts/utils/functions_common.R"
    output:
        figure = "outputs/step1/figures/step1_panelB_gt_count_by_position.png",
        table = "outputs/step1/tables/TABLE_1.B_gt_counts_by_position.csv"
    script: "scripts/step1/01_panel_b_gt_count_by_position.R"
```

**Cómo funciona**:
1. Snakemake ve que necesita el `output`
2. Verifica si el `input` existe
3. Si el output no existe o input es más nuevo, ejecuta el `script`
4. El script R usa `snakemake@input` y `snakemake@output` para acceder a rutas

---

## ⚙️ Configuración

### config/config.yaml.example

Template que los usuarios copian a `config/config.yaml`:

```yaml
paths:
  data:
    raw: "/path/to/raw/data"
    processed_clean: "/path/to/processed/data"
    step1_original: "/path/to/original/data"

analysis:
  vaf_filter_threshold: 0.5
  
resources:
  threads: 4
```

**Por qué .example**:
- Cada usuario tiene sus propias rutas
- `config.yaml` real está en `.gitignore` (no se sube)
- Usuario copia template y edita sus rutas

---

## 🎯 Ejecución

### Opción 1: Snakemake Directo

```bash
# Pipeline completo
snakemake -j 4

# Solo Step 1
snakemake -j 4 all_step1

# Solo Step 1.5
snakemake -j 1 all_step1_5

# Ver qué se ejecutaría (sin ejecutar)
snakemake -j 4 -n
```

### Opción 2: Script Wrapper

```bash
./run.sh /path/to/input.csv
```

---

## 📈 Outputs Generados

### Step 1
- **6 figuras PNG**: Paneles B, C, D, E, F, G
- **6 tablas CSV**: Estadísticas de cada panel
- **1 viewer HTML**: Visualización interactiva

### Step 1.5
- **11 figuras PNG**: QC + diagnósticas
- **7 tablas CSV**: Datos filtrados + estadísticas
- **1 viewer HTML**: Visualización interactiva

**Total**: 17 figuras + 13 tablas + 2 viewers HTML

---

## 🔍 Puntos Clave del Diseño

### 1. Modularidad
- Cada panel es un script independiente
- Fácil agregar nuevos análisis
- Fácil modificar existentes sin afectar otros

### 2. Reproducibilidad
- Snakemake maneja dependencias automáticamente
- Mismo input → mismo output
- Logs guardados para debugging

### 3. Optimización
- Paralelización (`-j 4`)
- Scripts vectorizados (Step 1.5 optimizado)
- Solo regenera lo necesario

### 4. Portabilidad
- Configuración separada de código
- Rutas relativas donde es posible
- Ambientes conda para dependencias

---

## 🚧 Estado Actual

### ✅ Completado

- **Step 1**: 100% funcional (6 paneles)
- **Step 1.5**: 100% funcional (2 reglas)
- **Viewers HTML**: Generación automática
- **Documentación**: Completa
- **Optimización**: Implementada

### 📋 Pendiente

- **Step 2**: Estructura lista, contenido por completar
- **Auto-configuración**: run.sh necesita actualizar config.yaml automáticamente
- **Validación de input**: Script para validar formato antes de ejecutar

---

## 💡 Mejoras Futuras

1. **Input único**: Un solo archivo CSV en lugar de 3
2. **Auto-detección**: Pipeline detecta tipo de archivo
3. **Metadata opcional**: Step 2 con grupos opcionales
4. **Tests automatizados**: Validar que todo funciona
5. **CI/CD**: GitHub Actions para testing automático

---

## 📚 Archivos de Documentación en el Repo

- `README.md` - Principal (para GitHub)
- `README_SIMPLE.md` - Guía rápida
- `GUIA_USO_PASO_A_PASO.md` - Guía detallada
- `OPTIMIZACIONES_RENDIMIENTO.md` - Optimizaciones implementadas
- `ANALISIS_OBJETIVO_vs_REALIDAD.md` - Análisis de gaps
- `PREPARACION_GITHUB.md` - Guía de preparación
- Varios otros docs de desarrollo

---

**Última actualización**: 2025-11-01  
**Versión del pipeline**: 1.0.0

