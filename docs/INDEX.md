# 📚 Documentation Index

Complete documentation for the miRNA Oxidation Analysis Pipeline.

---

## 🚀 Getting Started

1. **[Quick Start Guide](../QUICK_START.md)** - Get running in 5 minutes
2. **[README.md](../README.md)** - Main documentation and overview
3. **[User Guide](USER_GUIDE.md)** - Comprehensive usage instructions

---

## 📖 Core Documentation

### For Users

- **[User Guide](USER_GUIDE.md)** - Complete step-by-step usage guide
  - Installation instructions
  - Configuration guide
  - Running the pipeline
  - Understanding outputs
  - Troubleshooting

- **[Pipeline Overview](PIPELINE_OVERVIEW.md)** - Scientific background and methodology
  - Scientific concepts
  - Step-by-step descriptions
  - Data flow explanation
  - Output interpretation

### For Developers

- **[How It Works](HOW_IT_WORKS.md)** - Technical implementation details
  - Flexible group system architecture
  - Technical flow diagrams
  - Integration points

- **[Flexible Group System](FLEXIBLE_GROUP_SYSTEM.md)** - Group assignment system
  - Metadata file format
  - Pattern matching fallback
  - Configuration options

---

## 📊 Data and Configuration

- **[Data Format and Flexibility](DATA_FORMAT_AND_FLEXIBILITY.md)** - Input data specifications
  - Required columns
  - Sample naming conventions
  - Format flexibility

- **[Statistical Methodology](METHODOLOGY.md)** - Statistical methods documentation
  - Assumption validation
  - Batch effect analysis
  - Confounder analysis
  - Test selection

---

## 🔬 Advanced Topics

- **[Output Structure](OUTPUT_STRUCTURE.md)** - Output organization
  - File locations
  - Output formats
  - File naming conventions

- **[Thresholds Based on Literature](UMBRALES_BASADOS_LITERATURA.md)** - Scientific justification for thresholds

- **[Configurable Thresholds](UMBRALES_CONFIGURABLES.md)** - How to customize thresholds

---

## 📋 Reference Documents

- **[Software Versions](../SOFTWARE_VERSIONS.md)** - All software and package versions
- **[Testing Plan](../TESTING_PLAN.md)** - Testing procedures
- **[Critical Expert Review](../CRITICAL_EXPERT_REVIEW.md)** - Expert bioinformatics review
- **[Comprehensive Pipeline Review](../COMPREHENSIVE_PIPELINE_REVIEW.md)** - Complete pipeline analysis

---

## 🎯 Quick Reference

### Common Tasks

**Installation:**
```bash
git clone https://github.com/cesparza2022/miRNA-oxidation-pipeline.git
cd miRNA-oxidation-pipeline
bash setup.sh --mamba
conda activate mirna_oxidation_pipeline
```

**Configuration:**
```bash
cp config/config.yaml.example config/config.yaml
nano config/config.yaml  # Edit paths
```

**Run Pipeline:**
```bash
snakemake -j 4  # Run all steps
```

**Run Specific Step:**
```bash
snakemake -j 4 all_step2  # Step 2 only
```

### Key Files

- `config/config.yaml` - Main configuration file
- `sample_metadata_template.tsv` - Metadata file template
- `environment.yml` - Conda environment definition
- `Snakefile` - Main pipeline orchestrator

### Key Outputs

- `results/step2/final/figures/step2_position_specific_distribution.png` - Position-specific analysis
- `results/step2/final/tables/statistical_results/S2_statistical_comparisons.csv` - Statistical results
- `results/step4/final/tables/biomarkers/S4_roc_analysis.csv` - Biomarker analysis

---

## 📞 Getting Help

1. **Check documentation** - Start with [User Guide](USER_GUIDE.md)
2. **Review troubleshooting** - See [User Guide - Troubleshooting](USER_GUIDE.md#troubleshooting)
3. **Check log files** - Located in `results/*/logs/`
4. **Open GitHub issue** - Include error messages and log files

---

**Last Updated:** 2025-01-21

