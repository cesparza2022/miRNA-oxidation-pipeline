# 🧬 miRNA Oxidation Analysis Pipeline

[![Snakemake](https://img.shields.io/badge/Snakemake-7.0+-green.svg)](https://snakemake.github.io)
[![R](https://img.shields.io/badge/R-4.3+-blue.svg)](https://www.r-project.org)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A comprehensive, reproducible Snakemake pipeline for analyzing G>T oxidation patterns in microRNAs (miRNAs), with applications in neurodegenerative disease research (e.g., ALS).

## 🎯 Overview

This pipeline analyzes 8-oxoguanine (8-oxoG) damage in miRNAs, identified through G>T mutations, which are biomarkers of oxidative stress. The pipeline performs a comprehensive analysis in a logical sequence:

- **Step 0 - Overview**: Initial dataset characterization without G>T bias, providing general statistics on miRNAs, samples, and SNVs
- **Step 1 - Exploratory Analysis**: G>T-specific exploratory analysis with positional patterns and mutation spectrum
- **Step 1.5 - Quality Control**: VAF filtering to remove technical artifacts (VAF ≥ 0.5)
- **Step 2 - Statistical Comparisons**: Group comparisons with assumption validation, batch effect analysis, and confounder assessment
- **Step 3 - Clustering Analysis**: Identification of miRNA groups with similar oxidation patterns (data-driven structure discovery)
- **Step 4 - Functional Analysis**: Target prediction and pathway enrichment, interpreting the clusters discovered in Step 3
- **Step 5 - Family Analysis**: Comparison of data-driven clusters (Step 3) with biological miRNA families
- **Step 6 - Expression Correlation**: Relationship between miRNA expression levels and oxidation patterns
- **Step 7 - Biomarker Analysis**: ROC curves, AUC calculation, and multi-miRNA diagnostic signatures (final clinical application)

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

# (Optional) Generate processed inputs from raw counts
Rscript scripts/preprocess_data.R /path/to/miRNA_count.Q33.txt data/processed
# This creates the processed files referenced in config.yaml (processed_clean.csv, step1_original_data.csv)

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

# (Optional) Generate processed inputs from raw counts
Rscript scripts/preprocess_data.R /path/to/miRNA_count.Q33.txt data/processed

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

**See:** The `config/config.yaml.example` file for detailed format specifications and examples.

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

**Note:** The pipeline automatically detects groups from column names or metadata files. See `sample_metadata_template.tsv` for metadata file format.

## 📈 Pipeline Steps

### Step 0: Dataset Overview
- Initial characterization without G>T bias
- General statistics on miRNAs, samples, and SNVs
- Distribution analysis by mutation type
- Dataset coverage analysis (fraction of miRNAs/samples with SNVs)
- Proportional representation and ratio analysis
- Pie charts and summary tables

**Outputs:**
- 8 figures (PNG, 300 DPI)
- 5 tables (CSV)

**Purpose:** Provides an unbiased initial view of the dataset before focusing on G>T mutations.

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
- **Basic**: 5 figures (batch effect PCA, group balance, volcano, effect size, position-specific)
- **Detailed**: 16 additional figures (VAF distributions, heatmaps, clustering, enrichment, etc.)
- **Total**: 21 figures (PNG, 300 DPI)
- Statistical results tables (CSV)

### Step 3: Clustering Analysis
- Hierarchical clustering of miRNAs with similar oxidation patterns
- Identifies data-driven structure in the dataset
- Uses Ward.D2 linkage and correlation distance
- **This step discovers structure that is interpreted in Steps 4 and 5**

**Outputs:**
- 2 figures (cluster heatmap, cluster dendrogram)
- 2 tables (cluster assignments, summary)

**Dependencies:** Requires Step 2 (statistical comparisons)  
**Used by:** Steps 4 and 5 use cluster assignments for interpretation

### Step 4: Functional Analysis
- Target prediction for oxidized miRNAs
- GO and KEGG pathway enrichment
- Disease-relevant genes impact (ALS pathways)
- **Interprets the structure discovered in Step 3 (clustering)**

**Outputs:**
- 7 figures (target network, GO enrichment, KEGG enrichment, ALS pathways, pathway heatmap, biomarker signature heatmap, ROC curves)
- 6 tables (targets, ALS genes, GO/KEGG enrichment, pathways)

**Dependencies:** Requires Step 3 (cluster assignments) and Step 2 (statistical results)

### Step 5: miRNA Family Analysis
- Family identification and grouping
- Family-level oxidation patterns
- **Compares data-driven clusters (Step 3) with biological miRNA families**
- Group comparison by family

**Outputs:**
- 2 figures (family comparison, family heatmap)
- 2 tables (family summary, family comparison)

**Dependencies:** Requires Step 3 (cluster assignments)

### Step 6: Expression vs Oxidation Correlation Analysis
- Correlation between miRNA expression levels (RPM) and G>T oxidation patterns
- Expression category analysis
- Focuses on significant G>T mutations in seed region (positions 2-8)
- **Independent analysis that does not require clustering**

**Outputs:**
- 2 figures (expression vs oxidation scatter, expression groups comparison)
- 2 tables (correlation results, expression summary)

**Dependencies:** Requires Step 2 (statistical results) and Step 1.5 (VAF filtered data)

### Step 7: Biomarker Analysis
- ROC curve analysis for individual miRNAs
- AUC calculation and ranking
- Multi-miRNA diagnostic signatures (combined scores)
- **Final clinical application step**, integrating insights from previous steps
- Evaluates diagnostic potential of oxidation patterns

**Outputs:**
- 2 figures (ROC curves, biomarker signature heatmap)
- 2 tables (ROC analysis, biomarker signatures)

**Dependencies:** Requires Step 2 (statistical results) and Step 1.5 (VAF filtered data)

## 📁 Output Structure

```
results/
├── step0/final/
│   ├── figures/      # 8 PNG figures (overview)
│   └── tables/        # 5 CSV tables (summary statistics)
├── step1/final/
│   ├── figures/      # 6 PNG figures
│   └── tables/        # 6 CSV tables
├── step1_5/final/
│   ├── figures/      # 11 PNG figures
│   └── tables/        # Filtered data and reports
├── step2/final/
│   ├── figures/      # 21 PNG figures (5 basic + 16 detailed analysis)
│   └── tables/        # Statistical results
├── step3/final/
│   ├── figures/      # 2 PNG figures (clustering: heatmap, dendrogram)
│   └── tables/
│       └── clusters/  # Cluster assignments and summary
├── step4/final/
│   ├── figures/      # 7 PNG figures (functional analysis)
│   └── tables/
│       └── functional/  # Targets, GO/KEGG, pathways
├── step5/final/
│   ├── figures/      # 2 PNG figures (family analysis)
│   └── tables/        # Family summary and comparison
├── step6/final/
│   ├── figures/      # 2 PNG figures (expression-oxidation correlation)
│   └── tables/
│       └── correlation/  # Correlation results
├── step7/final/
│   ├── figures/      # 2 PNG figures (biomarker analysis)
│   └── tables/
│       └── biomarkers/  # ROC analysis and signatures
├── summary/          # Consolidated summary reports
└── validation/        # Validation reports
```

## 🎯 Usage

### Basic Usage

```bash
# Run complete pipeline
snakemake -j 4

# Run only Step 0 (Overview)
snakemake -j 1 all_step0

# Run only Step 1
snakemake -j 4 all_step1

# Run only Step 1.5
snakemake -j 1 all_step1_5

# Run only Step 2
snakemake -j 4 all_step2

# Run Steps 3-7 (logical sequence)
snakemake -j 4 all_step3 all_step4 all_step5 all_step6 all_step7

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
* **[README.md](README.md)** - Complete pipeline documentation (this file)

### Configuration and Data Format
* **Configuration**: See `config/config.yaml.example` for detailed configuration options
* **Data Format**: Input data should have `miRNA name` (or `miRNA_name`), `pos:mut` (or `pos.mut`), and sample columns in pairs (`SampleName_SNV` and `SampleName (PM+1MM+2MM)`)
* **Metadata Format**: See `sample_metadata_template.tsv` for metadata file format (optional but recommended for flexible group assignment)

### Release Information
* **[RESUMEN_REVISION_v1.0.1.md](RESUMEN_REVISION_v1.0.1.md)** - Executive summary of improvements in version 1.0.1
* **[CHANGELOG.md](CHANGELOG.md)** - Detailed change history
* **[RELEASE_NOTES_v1.0.1.md](RELEASE_NOTES_v1.0.1.md)** - Release notes for version 1.0.1
* **[ESTADO_PROBLEMAS_CRITICOS.md](ESTADO_PROBLEMAS_CRITICOS.md)** - Status of critical cohesion issues (all resolved ✅)
* **[HALLAZGOS_REVISION_PERFECCIONISTA.md](HALLAZGOS_REVISION_PERFECCIONISTA.md)** - Detailed findings from comprehensive code review (PHASES 1-5)

### Technical Notes
* **Statistical Methods**: The pipeline uses parametric (t-test) and non-parametric (Wilcoxon) tests based on data assumptions. FDR correction (Benjamini-Hochberg) is applied for multiple comparisons.
* **Batch Effect Analysis**: PCA and statistical testing are performed to detect batch effects (see Step 2 outputs).
* **Confounder Analysis**: Age, sex, and other confounders are analyzed and can be adjusted for in statistical models.

## 🔧 Troubleshooting

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

See `environment.yml` for detailed version requirements and dependencies.

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
**Pipeline Version:** 1.0.1

---

## 🆕 Latest Changes (v1.0.1)

This version includes a significant refactoring focused on improving code quality, visual consistency, and maintainability. See [RESUMEN_REVISION_v1.0.1.md](RESUMEN_REVISION_v1.0.1.md) for a complete summary or [RELEASE_NOTES_v1.0.1.md](RELEASE_NOTES_v1.0.1.md) for technical details.

### Critical Fixes
- 🔴 **Fixed:** Correct VAF calculation in Step 2 detailed figures
- 🔴 **Fixed:** Heatmap combination for FIG_2.15
- 🔧 **Fixed:** ggplot2 3.4+ compatibility (`size` → `linewidth`)

### Code Refactoring
- ✨ **Eliminated ~2000 lines of duplicated code** in utility scripts
- ✨ **Centralized styling:** Unified colors and themes in `colors.R` and `theme_professional.R`
- ✨ **Robustness improvements:** Input validation, error handling, and explicit namespaces
- ✨ **Visual standardization:** Consistent dimensions, colors, and themes across all visualizations
- ✨ **Code quality:** Improved comments, roxygen2 documentation, and code organization

### Improvements
- ✨ **Improved:** Visual consistency (G>T highlighted in red)
- 📚 **Added:** Comprehensive documentation (CHANGELOG, RELEASE_NOTES, HALLAZGOS)

**See [RESUMEN_REVISION_v1.0.1.md](RESUMEN_REVISION_v1.0.1.md) for executive summary or [HALLAZGOS_REVISION_PERFECCIONISTA.md](HALLAZGOS_REVISION_PERFECCIONISTA.md) for detailed findings.**

### Critical Cohesion Issues - All Resolved ✅
All 5 critical cohesion issues identified have been addressed:
- ✅ Unified input files in Step 1 (all panels use `processed_clean.csv`)
- ✅ Clarified metric usage (different metrics are intentional and appropriate)
- ✅ Fixed Panel E Metric 1 (now sums only position-specific reads)
- ✅ Removed unused calculations
- ✅ Documented data structure assumptions in Step 0

See [ESTADO_PROBLEMAS_CRITICOS.md](ESTADO_PROBLEMAS_CRITICOS.md) for detailed status.

---

**Previous Version:** 1.0.0 (2025-01-21)
