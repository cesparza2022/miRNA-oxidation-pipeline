# 📋 Pipeline Results Index

**Pipeline:** ALS miRNA Oxidation Analysis  
**Version:** 1.0.0  
**Last Updated:** 2025-11-03

---

## 🚀 Quick Navigation

### 📊 Summary
- [📋 Summary Report](summary/summary_report.html) ⭐ **NEW in FASE 3** - Consolidated HTML report
- [📊 Summary Statistics](summary/summary_statistics.json) - Key metrics in JSON
- [🔑 Key Findings](summary/key_findings.md) - Executive summary
- [Pipeline Info & Metadata](pipeline_info/) ⭐ FASE 2
  - [Execution Info](pipeline_info/execution_info.yaml)
  - [Software Versions](pipeline_info/software_versions.yml)
  - [Config Used](pipeline_info/config_used.yaml)
  - [Provenance](pipeline_info/provenance.json)
- [Key Findings](#key-findings)

### 📁 Results by Step

#### Step 1: Exploratory Analysis
- [**Figures**](step1/final/figures/) - Exploratory visualizations
- [**Tables**](step1/final/tables/) - Summary tables
- [**Logs**](step1/final/logs/) - Execution logs

#### Step 1.5: VAF Quality Control
- [**Figures**](step1_5/final/figures/) - QC and diagnostic figures
- [**Tables**](step1_5/final/tables/) - Filter reports and filtered data
- [**Logs**](step1_5/final/logs/) - Execution logs
- [**Filtered Data**](step1_5/final/tables/ALL_MUTATIONS_VAF_FILTERED.csv) - ⭐ **Input for Step 2**

#### Step 2: Statistical Comparisons
- [**Figures**](step2/final/figures/) - Statistical plots (volcano, effect sizes)
- [**Tables**](step2/final/tables/) - Statistical results
  - [Statistical Comparisons](step2/final/tables/step2_statistical_comparisons.csv)
  - [Effect Sizes](step2/final/tables/step2_effect_sizes.csv)
- [**Logs**](step2/final/logs/) - Execution logs

---

## 📊 Pipeline Summary

### Step 1: Exploratory Analysis
**Purpose:** Dataset characterization and initial exploration

**Outputs:**
- 6 exploratory figures (PNG, 300 DPI)
- 5 summary tables (CSV)
- Dataset statistics

**Key Metrics:**
- Total SNVs in dataset
- G>T mutation patterns
- Seed region analysis
- Mutation spectrum

### Step 1.5: VAF Quality Control
**Purpose:** Filter mutations based on VAF threshold

**Outputs:**
- 11 diagnostic figures (QC + analysis)
- 8 summary tables (filter reports, filtered data)
- Filtered dataset for Step 2

**Key Metrics:**
- Total mutations filtered
- Filter impact on dataset
- VAF distribution statistics

**⭐ Output for Next Step:**
- `step1_5/final/tables/ALL_MUTATIONS_VAF_FILTERED.csv` → Used as input for Step 2

### Step 2: Statistical Comparisons
**Purpose:** Statistical analysis ALS vs Control

**Outputs:**
- 2+ statistical figures (volcano plots, effect sizes)
- Statistical results tables
- Summary tables (significant mutations, top effect sizes)

**Key Metrics:**
- Significant mutations (FDR < 0.05)
- Effect sizes
- Seed region enrichment

---

## 🔍 Finding Specific Results

### Looking for a specific figure?
1. Navigate to the step directory (e.g., `step1/final/figures/`)
2. Check the README_TABLES.md in each step's `tables/` directory for table descriptions

### Looking for statistical results?
- **Significant mutations:** `step2/final/tables/step2_statistical_comparisons.csv`
- **Effect sizes:** `step2/final/tables/step2_effect_sizes.csv`

### Looking for filtered data?
- **VAF-filtered mutations:** `step1_5/final/tables/ALL_MUTATIONS_VAF_FILTERED.csv`

### Looking for logs?
- Each step has a `logs/` directory with execution logs

---

## 📁 Directory Structure

```
results/
├── step1/
│   ├── intermediate/          # Intermediate files (debugging)
│   └── final/                 # Final outputs
│       ├── figures/           # PNG figures
│       ├── tables/            # CSV tables
│       └── logs/              # Execution logs
├── step1_5/
│   ├── intermediate/
│   └── final/
│       ├── figures/           # QC and diagnostic figures
│       ├── tables/            # Filter reports and filtered data
│       ├── data/              # Additional data files
│       └── logs/
└── step2/
    ├── intermediate/
    └── final/
        ├── figures/           # Statistical plots
        ├── figures_clean/     # Clean versions (if available)
        ├── tables/            # Statistical results
        └── logs/
```

---

## 📝 Notes

- **Intermediate files:** Files in `intermediate/` directories are used for debugging and can be safely deleted after pipeline completion
- **Final files:** Files in `final/` directories are the main outputs to keep
- **Table documentation:** Each step's `tables/` directory contains a `README_TABLES.md` with detailed descriptions

---

## 🔗 External Links

- [Pipeline Documentation](../README.md)
- [Configuration File](../config/config.yaml)
- [Snakemake Rules](../rules/)

---

**For questions or issues, please refer to the main pipeline documentation.**

