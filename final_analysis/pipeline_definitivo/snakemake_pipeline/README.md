# 🧬 miRNA Oxidation Analysis Pipeline

[![Snakemake](https://img.shields.io/badge/Snakemake-7.0+-green.svg)](https://snakemake.github.io)
[![R](https://img.shields.io/badge/R-4.3+-blue.svg)](https://www.r-project.org)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A comprehensive, reproducible Snakemake pipeline for analyzing G>T oxidation patterns in microRNAs (miRNAs), with applications in neurodegenerative disease research (e.g., ALS).

## 🎯 Overview

This pipeline analyzes 8-oxoguanine (8-oxoG) damage in miRNAs, identified through G>T mutations, which are biomarkers of oxidative stress. The pipeline performs:

- **Quality Control**: VAF filtering to remove technical artifacts
- **Statistical Analysis**: Group comparisons with assumption validation
- **Position-Specific Analysis**: Individual position analysis (1-24)
- **Clustering Analysis**: Identification of miRNA groups with similar oxidation patterns
- **Family Analysis**: miRNA family-level oxidation patterns
- **Expression Correlation**: Relationship between expression and oxidation
- **Functional Analysis**: Target prediction and pathway enrichment
- **Biomarker Analysis**: ROC curves and diagnostic signatures (integrates all analyses)

## 🚀 Quick Start

### Prerequisites

- **Conda** (Miniconda or Anaconda) or **Mamba** - [Install Miniconda](https://docs.conda.io/en/latest/miniconda.html)
  - Mamba is faster and recommended: [Install Mamba](https://mamba.readthedocs.io/en/latest/installation.html)

### Installation

#### Option 1: Automated Setup (Recommended)

```bash
# 1. Clone repository
git clone https://github.com/cesparza2022/miRNA-oxidation-pipeline.git
cd miRNA-oxidation-pipeline

# 2. Run automated setup script
bash setup.sh --mamba  # Use mamba (faster) or --conda for conda

# 3. Activate environment
conda activate mirna_oxidation_pipeline

# 4. Configure data (edit path to your CSV file)
cp config/config.yaml.example config/config.yaml
nano config/config.yaml  # Update the path to your data file

# 5. Run pipeline
snakemake -j 4

# ✅ Done! Results are in results/
```

#### Option 2: Manual Setup

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

## 📊 Input Data Format

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

**See:** [Data Format Documentation](docs/DATA_FORMAT_AND_FLEXIBILITY.md) for detailed format specifications.

### 🎯 Flexible Group Assignment

The pipeline supports **any group names** (not just "ALS" and "Control") through a metadata file:

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

**See:** [Flexible Group System Documentation](docs/FLEXIBLE_GROUP_SYSTEM.md) for details.

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
- Technical artifact removal (VAF ≥ 0.5)
- Diagnostic visualizations

**Outputs:**
- 11 figures (PNG, 300 DPI)
- 7 tables (CSV)

### Step 2: Statistical Comparisons
- **Statistical assumptions validation** (normality, variance homogeneity)
- **Batch effect analysis** (PCA, statistical testing, correction)
- **Confounder analysis** (group balance assessment: age, sex)
- Group comparisons (t-test, Wilcoxon) with automatic test selection
- Effect size calculations
- Volcano plots
- **Position-specific analysis** (NEW: Step 2.5)

**Outputs:**
- 4 figures (PNG, 300 DPI)
- Statistical results tables (CSV)

### Step 3: Clustering Analysis (Structure Discovery)
- Hierarchical clustering of miRNAs
- Cluster identification (k=6)
- Pattern-based grouping
- Discovers groups with similar oxidation patterns
- **Runs FIRST after Step 2** to provide structure for subsequent analyses

**Outputs:**
- 2 figures (PNG, 300 DPI)
- 2 tables (CSV)

### Step 4: miRNA Family Analysis
- Family identification and grouping
- Family-level oxidation patterns
- Group comparison by family
- Compares data-driven clusters (from Step 3) with biological families
- **Runs after Step 3**, in parallel with Steps 5 and 6

**Outputs:**
- 2 figures (PNG, 300 DPI)
- 2 tables (CSV)

### Step 5: Expression vs Oxidation Correlation
- Correlation between RPM and G>T mutations
- Expression category analysis
- Examines relationship between expression and oxidation
- Can use clustering context from Step 3
- **Runs after Step 3**, in parallel with Steps 4 and 6

**Outputs:**
- 2 figures (PNG, 300 DPI)
- 2 tables (CSV)

### Step 6: Functional Analysis
- Target prediction for oxidized miRNAs
- **Direct target prediction**: Comparison of canonical vs oxidized miRNA targets ⭐ NEW
- GO and KEGG pathway enrichment
- Disease-relevant genes impact
- Analyzes functional implications with clustering context from Step 3
- **Runs after Step 3**, in parallel with Steps 4 and 5

**Outputs:**
- 6 figures (PNG, 300 DPI) ⭐ Updated: +1 target comparison figure
- 9 tables (CSV) ⭐ Updated: +3 target prediction tables

### Step 7: Biomarker Analysis (Final Integration)
- ROC curve analysis
- AUC calculation
- Multi-miRNA diagnostic signatures
- Integrates all previous analyses (statistical, clustering, families, expression, functional)
- **Runs LAST**, after Step 6 completes

**Outputs:**
- 2 figures (PNG, 300 DPI)
- 2 tables (CSV)

### Step 8: Sequence-Based Analysis (Paper Reference Methods) ⭐ NEW
- **Trinucleotide context analysis (XGY)**: Enrichment of GG, CG, AG, UG contexts around G>T mutations
- **Position-specific sequence logos**: Sequence conservation patterns at hotspot positions (2, 3, 5)
- **Temporal pattern analysis**: Accumulation of G>T mutations over time (if timepoints available)
- Implements methods from reference paper: "Widespread 8-oxoguanine modifications of miRNA seeds..."
- **Optional step** - can be enabled in Snakefile

**Outputs:**
- 4 figures (PNG, 300 DPI)
- 3 tables (CSV)

**Note:** Step 3 (Clustering) runs FIRST after Step 2 to discover data structure. Then Steps 4, 5, and 6 run in parallel using clustering results. Step 7 depends on Step 6 and runs last. Step 8 is optional and can run after Step 7.

## 📁 Output Structure

```
results/
├── step1/final/
│   ├── figures/      # 6 PNG figures
│   └── tables/        # 6 CSV tables
├── step1_5/final/
│   ├── figures/      # 11 PNG figures
│   └── tables/        # Filtered data and reports
├── step2/final/
│   ├── figures/      # 4 PNG figures (including position-specific)
│   └── tables/        # Statistical results
├── step3/final/
│   ├── figures/      # Clustering analysis figures
│   └── tables/        # Clustering analysis tables
├── step4/final/
│   ├── figures/      # Family analysis figures
│   └── tables/        # Family analysis tables
├── step5/final/
│   ├── figures/      # Expression-oxidation correlation figures
│   └── tables/        # Expression-oxidation correlation tables
├── step6/final/
│   ├── figures/      # Functional analysis figures
│   └── tables/        # Functional analysis tables
├── step7/final/
│   ├── figures/      # Biomarker analysis figures
│   └── tables/        # Biomarker analysis tables
├── step8/final/
│   ├── figures/      # Sequence-based analysis figures (logos, contexts)
│   └── tables/        # Sequence-based analysis tables
├── summary/          # Consolidated summary reports
└── validation/        # Validation reports
```

## 🎯 Usage

### Basic Usage

```bash
# Run complete pipeline
snakemake -j 4

# Run only Step 1
snakemake -j 4 all_step1

# Run only Step 1.5
snakemake -j 1 all_step1_5

# Run only Step 2
snakemake -j 4 all_step2

# Run Step 8 (sequence-based analysis - optional)
snakemake -j 1 all_step8

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

### Configuration

Edit `config/config.yaml` to customize:

- **Data paths**: Input data files, metadata file
- **Analysis parameters**: VAF thresholds, significance levels, etc.
- **Visualization settings**: Colors, figure dimensions, etc.

See `config/config.yaml.example` for detailed documentation.

## 📚 Documentation

### Getting Started
* **[Quick Start Guide](QUICK_START.md)** - Get running in 5 minutes
* **[User Guide](docs/USER_GUIDE.md)** - Comprehensive usage instructions
* **[Pipeline Overview](docs/PIPELINE_OVERVIEW.md)** - Scientific background and step descriptions
* **[Documentation Index](docs/INDEX.md)** - Complete documentation index

### Core Documentation
* **🔄 Flexible Group System**: [docs/FLEXIBLE_GROUP_SYSTEM.md](docs/FLEXIBLE_GROUP_SYSTEM.md) - How to use any group names via metadata file
* **🔧 How It Works**: [docs/HOW_IT_WORKS.md](docs/HOW_IT_WORKS.md) - Technical explanation of the flexible group system
* **📊 Data Format**: [docs/DATA_FORMAT_AND_FLEXIBILITY.md](docs/DATA_FORMAT_AND_FLEXIBILITY.md) - Input data format and parsing details
* **📊 Statistical Methodology**: [docs/METHODOLOGY.md](docs/METHODOLOGY.md) - Comprehensive documentation of statistical methods, assumptions validation, batch effects, and confounders

### Reference Documents
* **🧪 Testing Plan**: [TESTING_PLAN.md](TESTING_PLAN.md) - Step-by-step testing plan
* **🔧 Software Versions**: [SOFTWARE_VERSIONS.md](SOFTWARE_VERSIONS.md) - All software and package versions
* **🔬 Critical Expert Review**: [CRITICAL_EXPERT_REVIEW.md](CRITICAL_EXPERT_REVIEW.md) - Expert bioinformatics and statistical review
* **📋 Comprehensive Review**: [COMPREHENSIVE_PIPELINE_REVIEW.md](COMPREHENSIVE_PIPELINE_REVIEW.md) - Complete pipeline review with missing elements identified

## 🔧 Troubleshooting

### Error: "Configuration validation failed"
- Run `Rscript scripts/utils/validate_config.R config/config.yaml` to see detailed errors
- Check that all paths in `config/config.yaml` are correct
- Verify that input data files exist
- See `config/config.yaml.example` for reference format

### Error: "Package validation failed"
- Run `Rscript scripts/utils/validate_package_versions.R` to see missing packages
- Recreate conda environment: `conda env create -f environment.yml`
- Or install missing packages manually: `conda install -c conda-forge -c bioconda r-<package-name>`

### Error: "File not found"
- Verify paths in `config/config.yaml`
- Check that input data file exists
- Ensure metadata file path is correct (if using)

### Error: "No groups found"
- Check metadata file format (must have `sample_id` and `group` columns)
- Verify sample names match between data and metadata
- If using pattern matching, ensure sample names contain group identifiers

### Error: "Environment not found"
- Activate conda environment: `conda activate mirna_oxidation_pipeline`
- Or recreate environment: `conda env create -f environment.yml`

### Low Signal Warnings
- If you see "LOW SIGNAL DETECTED" warnings, check:
  - Data quality (VAF filter rate should be <90%)
  - Sample sizes (at least 10 samples per group recommended)
  - Group assignments (verify metadata file)

## 🧪 Requirements

### Required Software

- **Conda** (Miniconda or Anaconda) or **Mamba**
- **Python** 3.10+
- **Snakemake** 7.32+
- **R** 4.3.2+ (installed via conda)

### Pipeline Dependencies (installed automatically)

All dependencies are installed automatically when creating the conda/mamba environment from `environment.yml`.

**R packages:** ggplot2, dplyr, pheatmap, patchwork, ggrepel, viridis, and more

See [SOFTWARE_VERSIONS.md](SOFTWARE_VERSIONS.md) for detailed version requirements.

## 📖 Citation

If you use this pipeline in your research, please cite:

```bibtex
@software{miRNA_oxidation_pipeline,
  title = {miRNA Oxidation Analysis Pipeline},
  author = {Esparza, Cesar},
  year = {2025},
  url = {https://github.com/cesparza2022/miRNA-oxidation-pipeline}
}
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Snakemake workflow management system
- R statistical computing environment
- All package developers and maintainers

---

**Last Updated:** 2025-01-21  
**Pipeline Version:** 1.0.0
