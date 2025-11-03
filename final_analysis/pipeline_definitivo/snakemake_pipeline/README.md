# 🧬 ALS miRNA Oxidation Analysis Pipeline

[![Snakemake](https://img.shields.io/badge/Snakemake-7.0+-green.svg)](https://snakemake.github.io)
[![R](https://img.shields.io/badge/R-4.3+-blue.svg)](https://www.r-project.org)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Reproducible Snakemake pipeline for analyzing G>T oxidation patterns in miRNAs associated with ALS.

## 🚀 Quick Start

### Opción 1: Setup Automático (Recomendado)

```bash
# 1. Clone repository
git clone https://github.com/cesparza2022/als-mirna-oxidation-pipeline.git
cd als-mirna-oxidation-pipeline/final_analysis/pipeline_definitivo/snakemake_pipeline

# 2. Ejecutar script de setup automático
bash setup.sh --mamba  # Usa mamba (más rápido) o --conda para conda

# 3. Activar ambiente
conda activate als_mirna_pipeline

# 4. Configurar datos
cp config/config.yaml.example config/config.yaml
nano config/config.yaml  # Actualiza las rutas a tus datos

# 5. Probar pipeline (dry-run)
snakemake -n

# 6. Ejecutar pipeline
snakemake -j 4
```

### Opción 2: Setup Manual

```bash
# 1. Clone repository
git clone https://github.com/cesparza2022/als-mirna-oxidation-pipeline.git
cd als-mirna-oxidation-pipeline/final_analysis/pipeline_definitivo/snakemake_pipeline

# 2. Crear ambiente conda/mamba
conda env create -f environment.yaml
# O con mamba (más rápido):
# mamba env create -f environment.yaml

# 3. Activar ambiente
conda activate als_mirna_pipeline

# 4. Configurar datos
cp config/config.yaml.example config/config.yaml
nano config/config.yaml  # Actualiza las rutas a tus datos

# 5. Ejecutar pipeline
snakemake -j 4
```

**📚 Para instrucciones detalladas, consulta [SETUP.md](SETUP.md)**

## 📋 Requirements

### Software Requerido

- **Conda** (Miniconda o Anaconda) o **Mamba** - [Instalar Miniconda](https://docs.conda.io/en/latest/miniconda.html)
  - Mamba es más rápido y recomendado: [Instalar Mamba](https://mamba.readthedocs.io/en/latest/installation.html)

### Dependencias del Pipeline (instaladas automáticamente)

- **Python** 3.10+
- **Snakemake** 7.32+
- **R** 4.3.2+ (instalado via conda)
- **Paquetes R:** ggplot2, dplyr, pheatmap, patchwork, ggrepel, viridis, y más

**Nota:** Todas las dependencias se instalan automáticamente al crear el ambiente conda/mamba.

## 📊 Input Format

The pipeline expects a CSV file with the following structure:

```csv
miRNA name,pos:mut,Sample1_SNV,Sample1 (PM+1MM+2MM),Sample2_SNV,...
hsa-miR-1-1,1:G>T,5,100,3,80,...
hsa-miR-1-1,2:G>A,2,95,1,75,...
```

**Required columns:**
- `miRNA name`: miRNA identifier
- `pos:mut`: Position and mutation (format: `position:mutation`)
- Sample columns: `SampleName_SNV` and `SampleName (PM+1MM+2MM)` pairs

## 📈 Pipeline Steps

### Step 1: Exploratory Analysis
- Dataset characterization
- G>T positional patterns
- Mutation spectrum analysis
- Seed region analysis

**Outputs:**
- 6 figures (PNG)
- 6 tables (CSV)
- HTML viewer

### Step 1.5: VAF Quality Control
- VAF calculation and filtering
- Technical artifact removal
- Diagnostic visualizations

**Outputs:**
- 11 figures (PNG)
- 7 tables (CSV)
- HTML viewer

### Step 2: Group Comparisons *(Coming Soon)*
- ALS vs Control comparisons
- Statistical testing
- Effect size calculations

## 🎯 Usage

### Basic Usage
```bash
# Run complete pipeline
snakemake -j 4

# Run only Step 1
snakemake -j 4 all_step1

# Run only Step 1.5
snakemake -j 1 all_step1_5

# Dry-run (see what would execute)
snakemake -j 4 -n
```

### Using the wrapper script
```bash
# Make executable (first time)
chmod +x run.sh

# Run with input file
./run.sh /path/to/your/data.csv
```

## 📁 Project Structure

```
snakemake_pipeline/
├── README.md                 # This file
├── Snakefile                 # Main pipeline orchestrator
├── run.sh                    # Simple execution wrapper
├── config/
│   ├── config.yaml.example   # Configuration template
│   └── config.yaml           # Your configuration (create from example)
├── scripts/                  # R analysis scripts
│   ├── step1/               # Step 1 analysis scripts
│   ├── step1_5/             # Step 1.5 VAF QC scripts
│   └── utils/                # Shared utilities
├── rules/                    # Snakemake rule files
│   ├── step1.smk
│   ├── step1_5.smk
│   └── viewers.smk
├── envs/                     # Conda environment files
│   ├── r_base.yaml
│   └── r_analysis.yaml
└── outputs/                  # Generated outputs (gitignored)
    ├── step1/
    ├── step1_5/
    └── step2/
```

## ⚙️ Configuration

Edit `config/config.yaml` to specify:

- **Input data paths**: Location of your data files
- **Output directories**: Where to save results
- **Analysis parameters**: VAF thresholds, significance levels, etc.
- **Visualization settings**: Colors, figure dimensions, etc.

See `config/config.yaml.example` for detailed documentation.

## 📚 Documentation

### Para Empezar
* **⚡ Inicio Rápido**: `QUICK_START.md` - Empieza aquí (5 minutos)
* **🛠️ Setup Completo**: `SETUP.md` - Guía detallada de instalación
* **📖 Guía Paso a Paso**: `GUIA_USO_PASO_A_PASO.md`

### Documentación Técnica
* **📊 Estado de Viewers**: `ESTADO_VIEWERS.md`
* **👁️ Guía de Viewers**: `GUIA_VIEWERS.md`
* **⚙️ Optimizaciones**: `OPTIMIZACIONES_RENDIMIENTO.md`
* **📈 Análisis de Estado**: `ANALISIS_OBJETIVO_vs_REALIDAD.md`

## 🔧 Troubleshooting

### Error: "File not found"
- Verify paths in `config/config.yaml`
- Use absolute paths or paths relative to `snakemake_dir`

### Error: "R package not found"
- Activate conda environment: `conda activate als_mirna_pipeline`
- Reinstall: `conda env update -f environment.yaml --prune`

### Error: "Snakemake not found"

* Verifica que el ambiente esté activado: `conda activate als_mirna_pipeline`
* Si aún no está instalado:
  ```bash
  conda install -c bioconda -c conda-forge snakemake
  # o con mamba (más rápido):
  mamba install -c bioconda -c conda-forge snakemake
  ```

### Error: "Conda/Mamba not found"

**Instalar Miniconda (recomendado):**
* **macOS**: `curl -O https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.sh && bash Miniconda3-latest-MacOSX-arm64.sh`
* **Linux**: `wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && bash Miniconda3-latest-Linux-x86_64.sh`
* Reinicia tu terminal después de la instalación

**Instalar Mamba (opcional, más rápido):**
```bash
conda install mamba -n base -c conda-forge
```

### Verificar Instalación

```bash
# Ejecutar script de verificación
bash setup.sh --check

# O manualmente
conda activate als_mirna_pipeline
snakemake --version
R --version
Rscript -e "library(ggplot2); library(dplyr); cat('✅ OK\n')"
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-analysis`)
3. Commit your changes (`git commit -am 'Add new analysis'`)
4. Push to the branch (`git push origin feature/new-analysis`)
5. Open a Pull Request

## 📄 License

[Add your license here]

## 🙏 Citation

If you use this pipeline in your research, please cite:

```
[Citation information to be added]
```

## 📧 Contact

[Add contact information]

---

**Version:** 1.0.0  
**Last Updated:** 2025-11-01
