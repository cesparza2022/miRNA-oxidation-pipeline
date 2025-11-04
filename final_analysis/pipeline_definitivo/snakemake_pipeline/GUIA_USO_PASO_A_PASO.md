# 📖 GUÍA DE USO - Pipeline Paso a Paso

## 🚀 Cómo Ejecutar el Pipeline

### Opción 1: Pipeline Completo (todo junto)
```bash
cd snakemake_pipeline
snakemake -j 4
```
**Tiempo**: ~5-7 minutos
**Resultado**: Step 1 + Step 1.5 completos

---

### Opción 2: Paso por Paso (recomendado para verificar)

#### 📊 Paso 1: Análisis Exploratorio

**Ejecutar todo Step 1:**
```bash
snakemake -j 4 all_step1
```

**O ejecutar panel por panel:**
```bash
# Panel B
snakemake -j 1 outputs/step1/figures/step1_panelB_gt_count_by_position.png

# Panel C
snakemake -j 1 outputs/step1/figures/step1_panelC_gx_spectrum.png

# Panel D
snakemake -j 1 outputs/step1/figures/step1_panelD_positional_fraction.png

# Panel E
snakemake -j 1 outputs/step1/figures/step1_panelE_gcontent.png

# Panel F
snakemake -j 1 outputs/step1/figures/step1_panelF_seed_interaction.png

# Panel G
snakemake -j 1 outputs/step1/figures/step1_panelG_gt_specificity.png
```

---

#### 📊 Paso 1.5: Control de Calidad VAF

**Ejecutar todo Step 1.5:**
```bash
snakemake -j 1 all_step1_5
```

**O ejecutar regla por regla:**

**Regla 1: Aplicar filtro VAF**
```bash
snakemake -j 1 outputs/step1_5/tables/ALL_MUTATIONS_VAF_FILTERED.csv
```
**Tiempo**: ~2 minutos
**Genera**: 4 tablas CSV

**Regla 2: Generar figuras diagnósticas**
```bash
snakemake -j 1 outputs/step1_5/figures/QC_FIG1_VAF_DISTRIBUTION.png
```
**Tiempo**: ~2-3 minutos
**Genera**: 11 figuras PNG + 3 tablas CSV

---

#### 📊 Verificar Outputs Generados

**Step 1:**
```bash
ls -lh outputs/step1/figures/*.png
ls -lh outputs/step1/tables/*.csv
```

**Step 1.5:**
```bash
ls -lh outputs/step1_5/figures/*.png
ls -lh outputs/step1_5/tables/*.csv
```

---

#### 📊 Ver Viewer HTML

**Step 1:**
```bash
open viewers/step1.html
```

**Step 1.5:**
```bash
open viewers/step1_5.html
```

---

## 🔍 Comandos Útiles

### Ver qué se ejecutaría (sin ejecutar)
```bash
snakemake -j 4 -n
```

### Limpiar outputs y re-ejecutar
```bash
snakemake --delete-all-output
snakemake -j 4
```

### Ejecutar solo un paso específico
```bash
# Solo Step 1
snakemake -j 4 all_step1

# Solo Step 1.5
snakemake -j 1 all_step1_5
```

### Ver logs de ejecución
```bash
# Logs de Step 1
tail -20 outputs/step1/logs/panel_b.log

# Logs de Step 1.5
tail -20 outputs/step1_5/logs/apply_vaf_filter.log
```

---

## 📋 Flujo Recomendado para Principiantes

1. **Primera vez: Ejecutar todo**
   ```bash
   cd snakemake_pipeline
   snakemake -j 4
   ```

2. **Verificar que funcionó**
   ```bash
   # Ver figuras
   ls outputs/step1/figures/
   ls outputs/step1_5/figures/
   
   # Ver viewers
   open viewers/step1.html
   open viewers/step1_5.html
   ```

3. **Si necesitas re-ejecutar algo específico**
   ```bash
   # Eliminar solo un output
   rm outputs/step1/figures/step1_panelB_gt_count_by_position.png
   
   # Regenerarlo
   snakemake -j 1 outputs/step1/figures/step1_panelB_gt_count_by_position.png
   ```

---

## ⚙️ Configuración

**Rutas de datos** (editar si es necesario):
```bash
nano config/config.yaml
```

**Cambiar número de cores para paralelización:**
```bash
# Ver cores disponibles
sysctl -n hw.ncpu

# Usar más cores (si tienes)
snakemake -j 8  # Si tienes 8 cores
```

---

## ❓ Troubleshooting

### Error: "No se encuentra el archivo"
- Verifica rutas en `config/config.yaml`
- Usa rutas absolutas o relativas desde el directorio del proyecto

### Error: "Paquete R no encontrado"
- Activa el ambiente: `conda activate als_mirna_pipeline`
- O instala: `conda env create -f environment.yaml`

### Error: "Snakemake no encontrado"
- Instala: `pip install snakemake`
- O: `conda install -c bioconda snakemake`

---

## 📊 Resumen de Comandos Más Usados

```bash
# Pipeline completo (recomendado)
snakemake -j 4

# Solo Step 1
snakemake -j 4 all_step1

# Solo Step 1.5
snakemake -j 1 all_step1_5

# Ver qué se ejecutaría
snakemake -j 4 -n

# Limpiar todo y empezar de nuevo
snakemake --delete-all-output && snakemake -j 4
```

