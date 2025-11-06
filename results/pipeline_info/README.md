# 📋 Pipeline Info & Metadata

**FASE 2 Implementation** - Pipeline execution metadata for reproducibility

---

## 📄 Files Generated Automatically

### 1. `execution_info.yaml`
**Purpose:** Complete execution information

**Contents:**
- Pipeline name, version, description
- Execution date, time, status
- Parameters used (VAF threshold, alpha, FDR method, etc.)
- Input file paths
- Output directories and counts (figures, tables, logs)

**Example:**
```yaml
pipeline:
  name: ALS miRNA Oxidation Analysis
  version: 1.0.0
execution:
  date: '2025-11-03'
  status: completed
  steps_completed: [step1, step1_5, step2]
parameters:
  vaf_threshold: 0.5
  alpha: 0.05
```

---

### 2. `software_versions.yml`
**Purpose:** Software and package versions used

**Contents:**
- R version
- Snakemake version
- Platform information
- R package versions (tidyverse, ggplot2, dplyr, etc.)

**Use case:** Ensures reproducibility by documenting exact versions

---

### 3. `config_used.yaml`
**Purpose:** Copy of the configuration file used in this execution

**Contents:**
- Complete configuration snapshot
- All paths and parameters at execution time

**Use case:** Reproducibility - know exactly what config was used

---

### 4. `provenance.json`
**Purpose:** Data lineage tracking

**Contents:**
- Input → Output mapping
- Which inputs were used for each step
- File existence verification

**Use case:** Understand data flow through the pipeline

---

## 🔄 Generation

**Automatic:** These files are generated automatically by Snakemake after pipeline execution via the `generate_pipeline_info` rule.

**Manual:** Can be generated manually:
```bash
Rscript scripts/utils/generate_pipeline_info.R config/config.yaml results/pipeline_info .
```

---

## 📤 GitHub Repository

**Status:** ✅ **These files SHOULD be committed to GitHub**

- Small file sizes (< 5KB each)
- Essential for reproducibility
- No sensitive data
- Useful for collaboration

**Already configured in `.gitignore`:**
- `results/pipeline_info/` is explicitly allowed
- Individual YAML/JSON files will be tracked

---

## 🔗 Related Files

- [INDEX.md](../INDEX.md) - Main results index with links to pipeline_info
- [Config Template](../../config/config.yaml.example) - Template for configuration
- [FASE 2 Documentation](../../FASE2_IMPLEMENTACION_COMPLETADA.md) - Implementation details

---

**For questions about metadata or reproducibility, refer to the main pipeline documentation.**

