# 📖 User Guide: miRNA Oxidation Analysis Pipeline

**Version:** 1.0.0  
**Last Updated:** 2025-01-21

---

## Table of Contents

1. [Introduction](#introduction)
2. [Installation](#installation)
3. [Configuration](#configuration)
4. [Running the Pipeline](#running-the-pipeline)
5. [Understanding Outputs](#understanding-outputs)
6. [Troubleshooting](#troubleshooting)
7. [Advanced Usage](#advanced-usage)

---

## Introduction

This pipeline analyzes G>T oxidation patterns in microRNAs (miRNAs), which are biomarkers of oxidative stress. The pipeline is designed for comparative analysis between two groups (e.g., disease vs control).

### What This Pipeline Does

1. **Quality Control**: Filters technical artifacts (VAF ≥ 0.5)
2. **Statistical Analysis**: Compares groups with proper statistical tests
3. **Position-Specific Analysis**: Analyzes each position individually (1-24)
4. **Functional Analysis**: Predicts targets and identifies enriched pathways
5. **Biomarker Analysis**: Evaluates diagnostic potential (ROC curves)
6. **Family Analysis**: Analyzes oxidation patterns by miRNA families
7. **Expression Correlation**: Examines relationship between expression and oxidation
8. **Clustering**: Groups miRNAs with similar oxidation patterns

---

## Installation

### Step 1: Install Conda/Mamba

**If you don't have Conda:**
```bash
# Download and install Miniconda
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh
```

**Or install Mamba (faster, recommended):**
```bash
# After installing Conda, install Mamba
conda install mamba -n base -c conda-forge
```

### Step 2: Clone Repository

```bash
git clone https://github.com/cesparza2022/miRNA-oxidation-pipeline.git
cd miRNA-oxidation-pipeline
```

### Step 3: Set Up Environment

**Option A: Automated Setup (Recommended)**
```bash
bash setup.sh --mamba  # Use --conda if you don't have mamba
```

**Option B: Manual Setup**
```bash
conda env create -f environment.yml
# Or with mamba:
# mamba env create -f environment.yml
```

### Step 4: Activate Environment

```bash
conda activate mirna_oxidation_pipeline
```

---

## Configuration

### Step 1: Create Configuration File

```bash
cp config/config.yaml.example config/config.yaml
```

### Step 2: Edit Configuration

Open `config/config.yaml` and update the following:

```yaml
paths:
  data:
    # Update this path to your data file
    raw: "/path/to/your/miRNA_count.Q33.txt"
    processed_clean: "/path/to/your/processed_data.csv"
    step1_original: "/path/to/your/original_data.csv"
    
    # Optional: Metadata file for flexible group assignment
    metadata: "/path/to/your/sample_metadata.tsv"  # Or null
```

### Step 3: Configure Analysis Parameters (Optional)

```yaml
analysis:
  # VAF filtering threshold (VAFs >= this value are filtered)
  vaf_filter_threshold: 0.5
  
  # Statistical parameters
  alpha: 0.05  # Significance threshold
  fdr_method: "BH"  # FDR correction method
  
  # Seed region definition
  seed_region:
    start: 2
    end: 8
```

### Step 4: Create Metadata File (Optional but Recommended)

Create `sample_metadata.tsv`:

```tsv
sample_id	group	batch	age	sex
Sample1-ALS	Disease	Batch1	65	M
Sample2-ALS	Disease	Batch1	58	F
Sample3-control	Control	Batch1	62	F
Sample4-control	Control	Batch1	55	M
```

**Required columns:**
- `sample_id`: Must exactly match column names in your data CSV
- `group`: Group name (e.g., "Disease", "Control", "ALS", "Parkinson")

**Optional columns:**
- `batch`: Batch identifier (for batch effect analysis)
- `age`: Age (for confounder analysis)
- `sex`: Sex (M/F or Male/Female, for confounder analysis)

**See:** [sample_metadata_template.tsv](sample_metadata_template.tsv) for a complete template.

---

## Running the Pipeline

### Basic Usage

```bash
# Activate environment first
conda activate mirna_oxidation_pipeline

# Run complete pipeline
snakemake -j 4

# -j 4 means use 4 CPU cores (adjust to your system)
```

### Running Individual Steps

```bash
# Step 1: Exploratory Analysis
snakemake -j 4 all_step1

# Step 1.5: VAF Quality Control
snakemake -j 1 all_step1_5

# Step 2: Statistical Comparisons (includes position-specific analysis)
snakemake -j 4 all_step2

# REORDERED: Logical flow - structure discovery before functional interpretation
# Step 7: Clustering Analysis (discovers groups with similar patterns)
snakemake -j 4 all_step7

# Step 5: Family Analysis (compares clusters with biological families)
snakemake -j 4 all_step5

# Step 6: Expression-Oxidation Correlation (examines expression relationships)
snakemake -j 4 all_step6

# Step 3: Functional Analysis (functional implications with context)
snakemake -j 4 all_step3

# Step 4: Biomarker Analysis (integrates all previous insights) - LAST
snakemake -j 4 all_step4
```

### Dry Run (Preview)

```bash
# See what would execute without actually running
snakemake -j 4 -n
```

### Using Wrapper Script

```bash
# Make executable (first time)
chmod +x run.sh

# Run with input file
./run.sh /path/to/your/data.csv
```

---

## Understanding Outputs

### Output Structure

```
results/
├── step1/final/
│   ├── figures/      # Exploratory analysis figures
│   └── tables/        # Summary statistics
├── step1_5/final/
│   ├── figures/      # VAF QC diagnostic figures
│   └── tables/        # Filtered data
├── step2/final/
│   ├── figures/      # Statistical comparison figures
│   │   ├── step2_volcano_plot.png
│   │   ├── step2_effect_size_distribution.png
│   │   ├── step2_position_specific_distribution.png  # NEW
│   │   └── step2_batch_effect_pca_before.png
│   └── tables/
│       ├── statistical_results/
│       │   ├── S2_statistical_comparisons.csv
│       │   ├── S2_effect_sizes.csv
│       │   └── S2_position_specific_statistics.csv  # NEW
│       └── summary/
│           ├── S2_significant_mutations.csv
│           └── S2_seed_region_significant.csv
├── step3/final/      # Functional analysis
├── step4/final/      # Biomarker analysis
├── step5/final/      # Family analysis
├── step6/final/      # Expression correlation
└── step7/final/      # Clustering analysis
```

### Key Output Files

#### Step 2: Statistical Results

**`S2_statistical_comparisons.csv`**
- Contains all G>T mutations with statistical test results
- Columns: miRNA_name, pos.mut, group1_mean, group2_mean, log2_fold_change, t_test_fdr, wilcoxon_fdr, significant

**`S2_position_specific_statistics.csv`** (NEW)
- Position-by-position analysis (positions 1-24)
- Columns: position, positional_fraction_group1, positional_fraction_group2, pvalue_fdr, significant
- Shows which positions have significant differences between groups

**`step2_position_specific_distribution.png`** (NEW)
- Bar chart showing positional fraction for each position
- Seed region (2-8) highlighted with gray background
- Asterisks (*) indicate significant positions (p_adj < 0.05)

#### Step 3: Functional Analysis

**`S3_target_analysis.csv`**
- Predicted targets for oxidized miRNAs
- Columns: miRNA_name, target_gene, binding_score, etc.

**`S3_go_enrichment.csv`**
- GO term enrichment results
- Columns: GO_term, pvalue, FDR, enrichment_ratio

#### Step 4: Biomarker Analysis

**`S4_roc_analysis.csv`**
- ROC curve results for individual miRNAs
- Columns: miRNA_name, AUC, sensitivity, specificity

**`S4_biomarker_signatures.csv`**
- Multi-miRNA diagnostic signatures
- Columns: signature_id, miRNAs, AUC, sensitivity, specificity

---

## Troubleshooting

### Common Issues

#### 1. "File not found" Error

**Problem:** Pipeline can't find input data file.

**Solution:**
```bash
# Check that path in config.yaml is correct
cat config/config.yaml | grep -A 5 "paths:"

# Verify file exists
ls -lh /path/to/your/data.csv
```

#### 2. "No groups found" Error

**Problem:** Pipeline can't identify sample groups.

**Solution:**
- **If using metadata file:** Check that `sample_id` column matches column names in data CSV exactly
- **If using pattern matching:** Ensure sample names contain "ALS" or "control" (case-insensitive)

#### 3. "Environment not found" Error

**Problem:** Conda environment not activated.

**Solution:**
```bash
conda activate mirna_oxidation_pipeline
```

#### 4. Low Signal Warnings

**Problem:** Pipeline detects low signal (few significant results).

**Possible causes:**
- Small sample size (need at least 10 samples per group)
- High VAF filter rate (>90% of data filtered)
- Incorrect group assignments

**Solution:**
- Check data quality in Step 1.5 outputs
- Verify group assignments in metadata file
- Consider adjusting significance thresholds (if scientifically justified)

#### 5. Memory Issues

**Problem:** Pipeline runs out of memory.

**Solution:**
```bash
# Reduce number of parallel jobs
snakemake -j 1  # Use only 1 core

# Or run steps individually
snakemake -j 1 all_step1
snakemake -j 1 all_step1_5
# etc.
```

---

## Advanced Usage

### Custom Group Names

The pipeline supports any group names through the metadata file:

```tsv
sample_id	group
PD-001	Parkinson
PD-002	Parkinson
Healthy-001	Healthy
Healthy-002	Healthy
```

The pipeline will automatically adapt:
- Column names: `Parkinson_mean`, `Healthy_mean`
- Figure labels: "Parkinson vs Healthy"
- Colors: Applied to Parkinson and Healthy groups

**See:** [Flexible Group System Documentation](FLEXIBLE_GROUP_SYSTEM.md) for details.

### Adjusting Statistical Thresholds

Edit `config/config.yaml`:

```yaml
analysis:
  alpha: 0.05  # Significance threshold (default: 0.05)
  fdr_method: "BH"  # FDR method (default: "BH")
  
  # Log2FC thresholds (configurable per step)
  log2fc_threshold_step2: 0.58  # Step 2 threshold
  log2fc_threshold_step3: 1.0   # Step 3 threshold
```

### Seed Region Definition

You can customize the seed region:

```yaml
analysis:
  seed_region:
    start: 2  # Default: 2
    end: 8    # Default: 8
```

### Position Range

Customize the position range analyzed:

```yaml
analysis:
  position_range: [1, 24]  # Default: positions 1-24
```

### Batch Effect Correction

Enable batch effect correction:

```yaml
analysis:
  batch_correction:
    method: "combat"  # Options: "none", "mean_centering", "combat", "limma"
    pvalue_threshold: 0.05
```

**Note:** Requires batch information in metadata file.

---

## Getting Help

### Documentation

- **README.md**: Main documentation
- **docs/**: Detailed documentation for specific topics
- **COMPREHENSIVE_PIPELINE_REVIEW.md**: Complete pipeline review

### Issues

If you encounter problems:
1. Check the troubleshooting section above
2. Review the log files in `results/*/logs/`
3. Check the validation reports in `results/validation/`
4. Open an issue on GitHub with:
   - Error message
   - Log file contents
   - Configuration file (remove sensitive paths)

---

## Best Practices

1. **Always use metadata file** for group assignment (more reliable than pattern matching)
2. **Check Step 1.5 outputs** before proceeding to ensure data quality
3. **Review Step 2 outputs** to understand statistical results before downstream analysis
4. **Save configuration files** for reproducibility
5. **Keep log files** for troubleshooting

---

**Last Updated:** 2025-01-21  
**Document Version:** 1.0.0

