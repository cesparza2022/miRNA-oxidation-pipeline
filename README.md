# 🧬 miRNA Oxidation Analysis Pipeline

[![Snakemake](https://img.shields.io/badge/Snakemake-7.0+-green.svg)](https://snakemake.github.io)
[![R](https://img.shields.io/badge/R-4.3+-blue.svg)](https://www.r-project.org)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Reproducible Snakemake pipeline for analyzing G>T oxidation patterns in miRNAs.

## 🚀 Quick Start

### Option 1: Automated Setup (Recommended) ⚡

```bash
# 1. Clone repository
git clone https://github.com/cesparza2022/miRNA-oxidation-pipeline.git
cd miRNA-oxidation-pipeline

# 2. Run automated setup script
bash setup.sh --mamba  # Use mamba (faster) or --conda for conda

# 3. Activate environment
conda activate mirna_oxidation_pipeline

# 4. Configure data (edit path to your CSV file)
nano config/config.yaml  # Update the path to your data file

# 5. Run pipeline (everything is generated automatically)
snakemake -j 4

# ✅ Done! Results are in results/
```

**📁 Automatic Output Structure:**
```
results/
├── step1/final/figures/      # 6 PNG figures
├── step1/final/tables/        # 6 CSV tables
├── step1_5/final/figures/    # 11 PNG figures
├── step1_5/final/tables/     # Filtered data and reports
├── step2/final/figures/      # 2 PNG figures
├── step2/final/tables/       # Statistical results
├── step3/final/figures/      # Functional analysis figures
├── step3/final/tables/       # Functional analysis tables
├── step4/final/figures/      # Biomarker analysis figures
├── step4/final/tables/       # Biomarker analysis tables
├── step5/final/figures/      # Family analysis figures
├── step5/final/tables/       # Family analysis tables
├── step6/final/figures/      # Expression-oxidation correlation figures
├── step6/final/tables/       # Expression-oxidation correlation tables
├── step7/final/figures/      # Clustering analysis figures
├── step7/final/tables/       # Clustering analysis tables
├── summary/                  # Consolidated report
└── validation/               # Validation reports
```

### Option 2: Manual Setup

```bash
# 1. Clone repository
git clone https://github.com/cesparza2022/miRNA-oxidation-pipeline.git
cd miRNA-oxidation-pipeline

# 2. Create conda/mamba environment
conda env create -f environment.yml
# Or with mamba (faster):
# mamba env create -f environment.yml

# 3. Activate environment
conda activate mirna_oxidation_pipeline

# 4. Configure data
cp config/config.yaml.example config/config.yaml
nano config/config.yaml  # Update paths to your data

# 5. Run pipeline
snakemake -j 4
```

## 📋 Requirements

### Required Software

- **Conda** (Miniconda or Anaconda) or **Mamba** - [Install Miniconda](https://docs.conda.io/en/latest/miniconda.html)
  - Mamba is faster and recommended: [Install Mamba](https://mamba.readthedocs.io/en/latest/installation.html)

### Pipeline Dependencies (installed automatically)

- **Python** 3.10+
- **Snakemake** 7.32+
- **R** 4.3.2+ (installed via conda)
- **R packages:** ggplot2, dplyr, pheatmap, patchwork, ggrepel, viridis, and more

**Note:** All dependencies are installed automatically when creating the conda/mamba environment.

## 📊 Input Format

The pipeline expects a CSV file with the following structure:

```csv
miRNA name,pos:mut,Sample1_SNV,Sample1 (PM+1MM+2MM),Sample2_SNV,...
hsa-miR-1-1,1:G>T,5,100,3,80,...
hsa-miR-1-1,2:G>A,2,95,1,75,...
```

**Required columns:**
- `miRNA name` (or `miRNA_name`): miRNA identifier
- `pos:mut` (or `pos.mut`): Position and mutation (format: `position:mutation`)
- Sample columns: `SampleName_SNV` and `SampleName (PM+1MM+2MM)` pairs

### 🎯 Flexible Group Assignment

The pipeline supports **any group names** (not just "ALS" and "Control") through a metadata file system:

**Option 1: Metadata File (Recommended)**
```yaml
# config.yaml
paths:
  data:
    metadata: "sample_metadata.tsv"
```

```tsv
# sample_metadata.tsv
sample_id	group	batch	age	sex
Sample1	Disease	Batch1	65	M
Sample2	Control	Batch1	62	F
```

**Option 2: Pattern Matching (Fallback)**
- If no metadata file provided, pipeline uses pattern matching
- Searches for "ALS" → Disease group
- Searches for "control" → Control group
- Works automatically with existing data

**See:** [Flexible Group System Documentation](docs/FLEXIBLE_GROUP_SYSTEM.md) for details

## 📈 Pipeline Steps

### Step 1: Exploratory Analysis
- Dataset characterization
- G>T positional patterns
- Mutation spectrum analysis
- Seed region analysis

**Outputs:**
- 6 figures (PNG, 300 DPI)
- 6 tables (CSV)

### Step 1.5: VAF Quality Control
- VAF calculation and filtering
- Technical artifact removal
- Diagnostic visualizations

**Outputs:**
- 11 figures (PNG, 300 DPI)
- 7 tables (CSV)

### Step 2: Statistical Comparisons
- **Statistical assumptions validation** (normality, variance homogeneity)
- **Batch effect analysis** (PCA, statistical testing, correction)
- **Confounder analysis** (group balance assessment: age, sex)
- ALS vs Control comparisons
- Statistical testing (t-test, Wilcoxon) with automatic test selection
- Effect size calculations
- Volcano plots

**Outputs:**
- 2 figures (PNG, 300 DPI)
- Statistical results tables (CSV)

### Step 3: Functional Analysis
- Target prediction for oxidized miRNAs
- GO and KEGG pathway enrichment
- ALS-relevant genes impact

**Outputs:**
- 5 figures (PNG, 300 DPI)
- 6 tables (CSV)

### Step 4: Biomarker Analysis
- ROC curve analysis
- AUC calculation
- Multi-miRNA diagnostic signatures

**Outputs:**
- 2 figures (PNG, 300 DPI)
- 2 tables (CSV)

### Step 5: miRNA Family Analysis
- Family identification and grouping
- Family-level oxidation patterns
- ALS vs Control comparison by family

**Outputs:**
- 2 figures (PNG, 300 DPI)
- 2 tables (CSV)

### Step 6: Expression vs Oxidation Correlation
- Correlation between RPM and G>T mutations
- Expression category analysis

**Outputs:**
- 2 figures (PNG, 300 DPI)
- 2 tables (CSV)

### Step 7: Clustering Analysis
- Hierarchical clustering of miRNAs
- Cluster identification (k=6)
- Pattern-based grouping

**Outputs:**
- 2 figures (PNG, 300 DPI)
- 2 tables (CSV)

## 📦 Environment Setup

### Quick Setup (Recommended)
```bash
# 1. Create conda environment from environment.yml
conda env create -f environment.yml

# 2. Activate environment
conda activate mirna_oxidation_pipeline

# 3. Verify installation
R --version  # Should show R 4.3.2+
snakemake --version  # Should show >=7.0
```

See [SOFTWARE_VERSIONS.md](SOFTWARE_VERSIONS.md) for detailed version requirements.

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
├── setup.sh                  # ⚡ Automated setup script
├── config/
│   ├── config.yaml.example   # Configuration template
│   └── config.yaml           # Your configuration (edit with your data path)
├── scripts/                  # R analysis scripts
│   ├── step1/               # Step 1 analysis scripts
│   ├── step1_5/             # Step 1.5 VAF QC scripts
│   ├── step2/               # Step 2 statistical scripts
│   ├── step3/               # Step 3 functional analysis scripts
│   ├── step4/               # Step 4 biomarker analysis scripts
│   ├── step5/               # Step 5 family analysis scripts
│   ├── step6/               # Step 6 expression-oxidation correlation scripts
│   ├── step7/               # Step 7 clustering analysis scripts
│   └── utils/                # Shared utilities & validations
├── rules/                    # Snakemake rule files
│   ├── output_structure.smk  # ⚡ Auto-creates output directories
│   ├── step1.smk
│   ├── step1_5.smk
│   ├── step2.smk
│   ├── step3.smk
│   ├── step4.smk
│   ├── step5.smk
│   ├── step6.smk
│   ├── step7.smk
│   ├── pipeline_info.smk     # Pipeline metadata generation
│   ├── summary.smk           # Consolidated summary reports
│   └── validation.smk       # Output validation
├── envs/                     # Conda environment files
│   ├── r_base.yaml
│   └── r_analysis.yaml
└── results/                  # 📊 Generated outputs (auto-organized)
    ├── step1/final/         # Figures + Tables
    ├── step1_5/final/       # Figures + Tables
    ├── step2/final/         # Figures + Tables
    ├── step3/final/         # Figures + Tables
    ├── step4/final/         # Figures + Tables
    ├── step5/final/         # Figures + Tables
    ├── step6/final/         # Figures + Tables
    ├── step7/final/         # Figures + Tables
    ├── summary/             # Consolidated summaries
    └── validation/          # Validation reports
```

**📊 Output Organization:**
- **Figures**: Automatically organized by step in `results/stepX/final/figures/`
- **Tables**: Automatically organized by step in `results/stepX/final/tables/`
- **All directories created automatically** - no manual setup needed!

## ⚙️ Configuration

Edit `config/config.yaml` to specify:

- **Input data paths**: Location of your data files
- **Output directories**: Where to save results
- **Analysis parameters**: VAF thresholds, significance levels, etc.
- **Visualization settings**: Colors, figure dimensions, etc.

See `config/config.yaml.example` for detailed documentation.

## 📚 Documentation

### Essential Documentation
* **🔄 Flexible Group System**: [docs/FLEXIBLE_GROUP_SYSTEM.md](docs/FLEXIBLE_GROUP_SYSTEM.md) - How to use any group names (not just ALS/Control) via metadata file
* **🔧 How It Works**: [docs/HOW_IT_WORKS.md](docs/HOW_IT_WORKS.md) - Technical explanation of the flexible group system
* **📊 Data Format**: [docs/DATA_FORMAT_AND_FLEXIBILITY.md](docs/DATA_FORMAT_AND_FLEXIBILITY.md) - Input data format and parsing details
* **📊 Statistical Methodology**: [docs/METHODOLOGY.md](docs/METHODOLOGY.md) - Comprehensive documentation of statistical methods, assumptions validation, batch effects, and confounders
* **🧪 Testing Plan**: [TESTING_PLAN.md](TESTING_PLAN.md) - Step-by-step testing plan for validating Phase 1 critical corrections
* **🔧 Software Versions**: [SOFTWARE_VERSIONS.md](SOFTWARE_VERSIONS.md) - All software and package versions
* **🔬 Critical Expert Review**: [CRITICAL_EXPERT_REVIEW.md](CRITICAL_EXPERT_REVIEW.md) - Expert bioinformatics and statistical review

## 🔧 Troubleshooting

### Error: "File not found"
- Verify paths in `config/config.yaml`
- Use absolute paths or paths relative to `snakemake_dir`

### Error: "R package not found"
- Activate conda environment: `conda activate mirna_oxidation_pipeline`
- Reinstall: `conda env update -f environment.yml --prune`

### Error: "Snakemake not found"

* Verify that the environment is activated: `conda activate mirna_oxidation_pipeline`
* If still not installed:
  ```bash
  conda install -c bioconda -c conda-forge snakemake
  # or with mamba (faster):
  mamba install -c bioconda -c conda-forge snakemake
  ```

### Error: "Conda/Mamba not found"

**Install Miniconda (recommended):**
* **macOS**: `curl -O https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.sh && bash Miniconda3-latest-MacOSX-arm64.sh`
* **Linux**: `wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && bash Miniconda3-latest-Linux-x86_64.sh`
* Restart your terminal after installation

**Install Mamba (optional, faster):**
```bash
conda install mamba -n base -c conda-forge
```

### Verify Installation

```bash
# Run verification script
bash setup.sh --check

# Or manually
conda activate mirna_oxidation_pipeline
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
