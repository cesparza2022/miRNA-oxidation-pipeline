# 🚀 ALS miRNA Oxidation Analysis Pipeline

Pipeline simple y directo para análisis de oxidación G>T en miRNAs. Input → Outputs con un solo comando.

## 📋 Formato de Input

El pipeline espera un archivo CSV con el siguiente formato:

```
miRNA name,pos:mut,Magen_001_SNV,Magen_001 (PM+1MM+2MM),Magen_002_SNV,...
hsa-miR-1-1,1:G>T,5,100,3,80,...
hsa-miR-1-1,2:G>A,2,95,1,75,...
```

**Columnas requeridas:**
- `miRNA name`: Nombre del miRNA
- `pos:mut`: Posición y mutación (formato: `posicion:mutacion`)
- Columnas de muestra: `Magen_XXX_SNV` y `Magen_XXX (PM+1MM+2MM)`

## 🚀 Uso Básico

### Opción 1: Script Simple (Recomendado)
```bash
./run.sh /ruta/a/tu/datos/miRNA_count.Q33.txt
```

### Opción 2: Snakemake Directo
```bash
# 1. Edita config/config.yaml con la ruta a tu archivo
# 2. Ejecuta:
snakemake -j 4
```

## 📊 Outputs

El pipeline genera automáticamente:

- **Figuras**: `outputs/step1/figures/` y `outputs/step1_5/figures/`
- **Tablas**: `outputs/step1/tables/` y `outputs/step1_5/tables/`
- **Viewers HTML**: `viewers/step1.html` y `viewers/step1_5.html`

## ⚙️ Configuración

Edita `config/config.yaml` para ajustar:
- Rutas a archivos de datos
- Umbrales de filtrado VAF
- Parámetros de visualización

## 📦 Instalación

```bash
# 1. Clonar repositorio
git clone <repo-url>
cd snakemake_pipeline

# 2. Crear ambiente conda (opcional pero recomendado)
conda env create -f environment.yaml
conda activate als_mirna_pipeline

# 3. Instalar Snakemake si no lo tienes
pip install snakemake

# 4. Ejecutar
./run.sh tu_datos.csv
```

## 🎯 Ejemplos

```bash
# Pipeline completo con datos personalizados
./run.sh /path/to/miRNA_count.Q33.txt

# Pipeline completo con configuración por defecto
./run.sh

# Solo Step 1 (análisis exploratorio)
snakemake -j 4 all_step1

# Solo Step 1.5 (control de calidad VAF)
snakemake -j 1 all_step1_5

# Ver qué se ejecutaría (sin ejecutar)
snakemake -j 4 -n
```

## 📈 Estructura de Outputs

```
outputs/
├── step1/
│   ├── figures/      # 6 paneles exploratorios
│   ├── tables/       # 6 tablas CSV
│   └── logs/         # Logs de ejecución
├── step1_5/
│   ├── figures/      # 11 figuras de QC
│   ├── tables/       # 7 tablas CSV (incluyendo datos filtrados)
│   └── logs/
└── step2/
    └── ...

viewers/
├── step1.html        # Viewer interactivo Step 1
└── step1_5.html      # Viewer interactivo Step 1.5
```

## 🔧 Troubleshooting

**Error: "Archivo no encontrado"**
- Verifica que la ruta al archivo CSV es correcta
- Usa rutas absolutas si es necesario

**Error: "Snakemake no encontrado"**
```bash
pip install snakemake
```

**Error: "R no encontrado"**
```bash
# macOS
brew install r

# Linux
sudo apt-get install r-base
```

## 📚 Más Información

- Guía detallada: `GUIA_USO_PASO_A_PASO.md`
- Optimizaciones: `OPTIMIZACIONES_RENDIMIENTO.md`
- Configuración avanzada: `config/config.yaml`

---

**Versión:** 1.0.0  
**Formato Input:** CSV con columnas miRNA name, pos:mut, y columnas de muestra  
**Output:** Figuras PNG, tablas CSV, viewers HTML

