# 🎬 ¿Cómo funciona Snakemake? Vista Visual

## 📁 ¿Es un archivo o varios?

**ES VARIOS ARCHIVOS trabajando juntos:**

```
snakemake_pipeline/
│
├── 🐍 Snakefile              ← PRINCIPAL: Orquestador (1 archivo)
│
├── 📋 rules/                  ← REGLAS: Definen qué hacer (3 archivos)
│   ├── step1.smk             ← Reglas del Step 1
│   ├── step1_5.smk           ← Reglas del Step 1.5
│   └── viewers.smk           ← Reglas para viewers HTML
│
├── 📝 scripts/                ← SCRIPTS R: El trabajo real (8 archivos)
│   ├── step1/*.R             ← 6 scripts
│   └── step1_5/*.R           ← 2 scripts
│
├── ⚙️ config/                ← CONFIGURACIÓN: Parámetros (1 archivo)
│   └── config.yaml
│
└── 📊 outputs/                ← SALIDAS: Todo lo generado
    ├── step1/
    │   ├── figures/          ← 6 PNGs
    │   └── tables/            ← 6 CSVs
    └── step1_5/
        ├── figures/          ← 11 PNGs
        └── tables/           ← 7 CSVs
```

---

## 🔄 ¿Cómo funciona? Flujo Visual

### 1️⃣ TÚ EJECUTAS:
```bash
$ snakemake -j 1
```

### 2️⃣ SNAKEMAKE LEE (en orden):
```
Snakefile
  ↓
Lee: config/config.yaml (rutas, parámetros)
  ↓
Incluye: rules/step1.smk
Incluye: rules/step1_5.smk
Incluye: rules/viewers.smk
  ↓
Construye: "Grafo de dependencias"
```

### 3️⃣ SNAKEMAKE CALCULA:
```
¿Qué necesito generar?
├─ outputs/step1/figures/panelB.png (¿existe? ¿está actualizado?)
├─ outputs/step1/figures/panelC.png (¿existe? ¿está actualizado?)
├─ outputs/step1_5/figures/QC_FIG1.png (¿existe? ¿está actualizado?)
└─ ... (todas las salidas)

Si NO existe o está desactualizado → Lo ejecuto
Si SÍ existe y está actualizado → Lo omito (ahorra tiempo)
```

### 4️⃣ SNAKEMAKE EJECUTA (si es necesario):

**Ejemplo: Panel B**
```
Snakemake ejecuta:
  → Rscript scripts/step1/01_panel_b.R
  ↓
Script R lee:
  → snakemake@input[["data"]] = ruta al CSV
  → snakemake@output[["figure"]] = donde guardar PNG
  ↓
Script genera:
  → outputs/step1/figures/panelB.png
  → outputs/step1/tables/TABLE_1.B.csv
  ↓
✅ Panel B completado
```

### 5️⃣ OUTPUTS CREADOS:

**Estructura final:**
```
outputs/
├── step1/
│   ├── figures/
│   │   ├── step1_panelB_gt_count_by_position.png  (generado)
│   │   ├── step1_panelC_gx_spectrum.png           (generado)
│   │   ├── step1_panelD_positional_fraction.png   (generado)
│   │   ├── step1_panelE_gcontent.png              (generado)
│   │   ├── step1_panelF_seed_interaction.png      (generado)
│   │   └── step1_panelG_gt_specificity.png        (generado)
│   └── tables/
│       ├── TABLE_1.B_gt_counts_by_position.csv
│       ├── TABLE_1.C_gx_spectrum_by_position.csv
│       ├── TABLE_1.D_positional_fractions.csv
│       ├── TABLE_1.E_gcontent_landscape.csv
│       ├── TABLE_1.F_seed_vs_nonseed.csv
│       └── TABLE_1.G_gt_specificity.csv
│
├── step1_5/
│   ├── figures/
│   │   ├── QC_FIG1_VAF_DISTRIBUTION.png
│   │   ├── QC_FIG2_FILTER_IMPACT.png
│   │   ├── QC_FIG3_AFFECTED_MIRNAS.png
│   │   ├── QC_FIG4_BEFORE_AFTER.png
│   │   ├── STEP1.5_FIG1_HEATMAP_SNVS.png
│   │   ├── STEP1.5_FIG2_HEATMAP_COUNTS.png
│   │   ├── STEP1.5_FIG3_G_TRANSVERSIONS_SNVS.png
│   │   ├── STEP1.5_FIG4_G_TRANSVERSIONS_COUNTS.png
│   │   ├── STEP1.5_FIG5_BUBBLE_PLOT.png
│   │   ├── STEP1.5_FIG6_VIOLIN_DISTRIBUTIONS.png
│   │   └── STEP1.5_FIG7_FOLD_CHANGE.png
│   └── tables/
│       ├── ALL_MUTATIONS_VAF_FILTERED.csv
│       ├── vaf_filter_report.csv
│       ├── vaf_statistics_by_type.csv
│       ├── vaf_statistics_by_mirna.csv
│       ├── sample_metrics_vaf_filtered.csv
│       ├── position_metrics_vaf_filtered.csv
│       └── mutation_type_summary_vaf_filtered.csv
│
└── viewers/
    ├── step1.html        (viewer HTML con todas las figuras embebidas)
    └── step1_5.html      (viewer HTML con todas las figuras embebidas)
```

---

## 🎨 ¿Cómo se ve el Viewer HTML?

**El viewer HTML es un archivo único que contiene:**

1. **Navegación lateral** - Lista de todas las figuras
2. **Figuras embebidas** - Cada PNG convertido a base64 (no necesitas los PNGs separados)
3. **Tablas interactivas** - Links a las tablas CSV
4. **Descripciones** - Qué muestra cada figura

**Ventaja**: Puedes compartir solo el HTML y la persona ve todo sin necesitar los PNGs.

---

## 📊 Ejemplo Real de Salida en Terminal

Cuando ejecutas `snakemake -j 1`, ves algo como:

```
Building DAG of jobs...
Using shell: /bin/bash
Provided cores: 1

Job stats:
job                            count
---------------------------  -------
panel_b_gt_count_by_position     1
panel_c_gx_spectrum              1
panel_d_positional_fraction      1
panel_e_gcontent                 1
panel_f_seed_vs_nonseed          1
panel_g_gt_specificity           1
apply_vaf_filter                 1
generate_diagnostic_figures      1
generate_step1_viewer            1
generate_step1_5_viewer          1
all                              1
total                           11

Select jobs to execute...

[Sat Nov  1 12:45:36 2025]
rule panel_b_gt_count_by_position:
    input: data.csv, functions.R
    output: outputs/step1/figures/panelB.png
    log: outputs/step1/logs/panel_b.log
    
═══════════════════════════════════════════════════════════
  PANEL B: G>T Count by Position
═══════════════════════════════════════════════════════════
📋 Parameters:
   Input: /ruta/al/data.csv
   Output figure: outputs/step1/figures/panelB.png
📊 Processing G>T mutations...
   ✅ G>T mutations found: 1234 SNVs
💾 Saving outputs...
   ✅ outputs/step1/figures/panelB.png
   ✅ outputs/step1/tables/TABLE_1.B.csv

[Sat Nov  1 12:45:40 2025]
Finished jobid: 1 (Rule: panel_b_gt_count_by_position)

[Sat Nov  1 12:45:40 2025]
rule panel_c_gx_spectrum:
    ...
    ✅ COMPLETED

...

11 of 11 steps (100%) done
```

---

## 🎯 Resumen: ¿Qué hace Snakemake?

**EN UNA FRASE:**
Snakemake lee las reglas, calcula qué necesita ejecutar, ejecuta los scripts R en el orden correcto, y genera todos los outputs (figuras, tablas, viewers HTML).

**LO QUE TÚ HACES:**
```bash
snakemake -j 1
```

**LO QUE SNAKEMAKE HACE:**
1. Lee Snakefile + reglas
2. Calcula dependencias
3. Ejecuta scripts R (solo lo necesario)
4. Genera outputs
5. Crea viewers HTML

**LO QUE OBTIENES:**
- 17 figuras PNG (6 + 11)
- 13 tablas CSV (6 + 7)
- 2 viewers HTML (con todo embebido)

---

## 💡 Analogía Simple

**Snakemake es como un "jefe de proyecto" que:**

1. **Lee el plan** (Snakefile + reglas) → sabe qué hacer
2. **Verifica el estado** → ¿qué está hecho? ¿qué falta?
3. **Asigna tareas** → ejecuta scripts R en el orden correcto
4. **Verifica resultados** → ¿se generaron los outputs?
5. **Reporta progreso** → muestra qué se completó

**Tú solo das la orden inicial:** `snakemake -j 1`

**Snakemake hace todo lo demás automáticamente.**

