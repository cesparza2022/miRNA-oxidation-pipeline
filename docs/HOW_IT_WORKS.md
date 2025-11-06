# 🔧 How the Flexible Group System Works

**Date:** 2025-01-21  
**Purpose:** Technical explanation of how the flexible group assignment system works internally

---

## 🎯 Overview

The pipeline now supports **any group names** (not just "ALS" and "Control") through a flexible metadata file system. This document explains the technical implementation and how everything connects.

---

## 📊 Architecture

### Components

1. **`scripts/utils/group_comparison.R`** - Core utilities for group detection
2. **Metadata file** (optional) - TSV file with sample groups
3. **Pattern matching** (fallback) - Regex patterns on column names
4. **Dynamic column generation** - Scripts adapt to detected groups

---

## 🔄 Complete Flow Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    User Input                            │
│  ┌─────────────────┐      ┌──────────────────┐         │
│  │ Data CSV File   │      │ Metadata File    │         │
│  │ (with samples)  │      │ (optional)        │         │
│  └─────────────────┘      └──────────────────┘         │
└─────────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│         extract_sample_groups() Function                 │
│                                                          │
│  IF metadata_file provided AND exists:                  │
│    └─> Load from metadata file (Priority 1)            │
│  ELSE:                                                   │
│    └─> Pattern matching on column names (Priority 2)     │
│                                                          │
│  Returns: groups_df (sample_id, group, ...)              │
└─────────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│         Each R Script (Step 2, 3, 4, 5, 7)              │
│                                                          │
│  1. Load group_comparison.R utilities                    │
│  2. Call extract_sample_groups()                         │
│  3. Get unique_groups = sort(unique(groups_df$group))   │
│  4. Extract group1_name, group2_name                     │
│  5. Generate column names dynamically:                  │
│     - {group1_name}_mean, {group2_name}_mean             │
│  6. Create tables/figures with dynamic names             │
└─────────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│                    Output                                │
│  ┌─────────────────┐      ┌──────────────────┐           │
│  │ Tables:         │      │ Figures:         │           │
│  │ - Group1_mean  │      │ - Labels:        │           │
│  │ - Group2_mean  │      │   Group1 vs       │           │
│  │ - log2FC       │      │   Group2         │           │
│  │ - p_values     │      │ - Colors:         │           │
│  │                 │      │   From config    │           │
│  └─────────────────┘      └──────────────────┘           │
└─────────────────────────────────────────────────────────┘
```

---

## 🔍 Detailed Technical Flow

### 1. Initialization (in each R script)

```r
# Load group comparison utilities
source("scripts/utils/group_comparison.R")

# Get metadata file path from Snakemake params
metadata_file <- if (!is.null(snakemake@params[["metadata_file"]])) {
  metadata_path <- snakemake@params[["metadata_file"]]
  if (metadata_path != "" && file.exists(metadata_path)) {
    metadata_path
  } else {
    NULL
  }
} else {
  NULL
}
```

### 2. Group Detection

```r
# Use flexible group extraction
sample_groups <- extract_sample_groups(data, metadata_file = metadata_file)

# Get dynamic group names
unique_groups <- sort(unique(sample_groups$group))
group1_name <- unique_groups[1]  # e.g., "Disease" or "ALS"
group2_name <- unique_groups[2]  # e.g., "Control" or "Healthy"

group1_samples <- sample_groups %>% filter(group == group1_name) %>% pull(sample_id)
group2_samples <- sample_groups %>% filter(group == group2_name) %>% pull(sample_id)
```

### 3. Dynamic Column Detection

```r
# Detect group mean columns dynamically
group1_mean_col <- paste0(group1_name, "_mean")  # e.g., "Disease_mean"
group2_mean_col <- paste0(group2_name, "_mean")  # e.g., "Control_mean"

# Fallback to ALS/Control if dynamic columns not found
if (!group1_mean_col %in% names(statistical_results)) {
  group1_mean_col <- "ALS_mean"
}
if (!group2_mean_col %in% names(statistical_results)) {
  group2_mean_col <- "Control_mean"
}
```

### 4. Dynamic Column Usage

```r
# Use dynamic columns in analysis
family_summary <- statistical_results %>%
  summarise(
    avg_group1_mean = mean(!!sym(group1_mean_col), na.rm = TRUE),
    avg_group2_mean = mean(!!sym(group2_mean_col), na.rm = TRUE),
    # Backward compatibility
    avg_ALS_mean = if ("ALS_mean" %in% names(statistical_results)) {
      mean(ALS_mean, na.rm = TRUE)
    } else {
      NA_real_
    },
    ...
  )
```

### 5. Dynamic Visualization

```r
# Dynamic labels in plots
ggplot(data, aes(x = group, y = value, fill = group)) +
  scale_fill_manual(
    values = setNames(c(color_gt, color_control), c(group1_name, group2_name)),
    name = "Group"
  ) +
  labs(
    title = paste0("Comparison: ", group1_name, " vs ", group2_name),
    ...
  )
```

---

## 🔗 Integration Points

### Snakemake Rules

Each Snakemake rule that needs group information passes:

```python
params:
    metadata_file = config["paths"]["data"].get("metadata", ""),
    group_functions = "scripts/utils/group_comparison.R"
```

### R Scripts

All R scripts that compare groups:
- Load `group_comparison.R` utilities
- Call `extract_sample_groups()` with metadata_file parameter
- Use dynamic group names throughout

**Scripts Updated:**
- ✅ `scripts/step2/01_statistical_comparisons.R`
- ✅ `scripts/step2/02_volcano_plots.R`
- ✅ `scripts/step2/03_effect_size_analysis.R`
- ✅ `scripts/step2/04_generate_summary_tables.R`
- ✅ `scripts/step2/00_batch_effect_analysis.R`
- ✅ `scripts/step2/00_confounder_analysis.R`
- ✅ `scripts/step3/01_functional_target_analysis.R`
- ✅ `scripts/step4/01_biomarker_roc_analysis.R`
- ✅ `scripts/step4/02_biomarker_signature_heatmap.R`
- ✅ `scripts/step5/01_family_identification.R`
- ✅ `scripts/step5/02_family_comparison_visualization.R`
- ✅ `scripts/step7/01_clustering_analysis.R`

---

## 📝 Configuration

### config.yaml

```yaml
paths:
  data:
    # Path to your main data CSV file
    input_data: "/path/to/data.csv"
    
    # Path to metadata file (OPTIONAL but recommended)
    metadata: "/path/to/sample_metadata.tsv"
    
    # If metadata not provided, pattern matching is used
```

### Metadata File Template

See `sample_metadata_template.tsv` or `sample_metadata_template_minimal.tsv` in the repository root.

**Minimal format:**
```tsv
sample_id	group
Sample1	Disease
Sample2	Control
```

**Full format (with covariates):**
```tsv
sample_id	group	batch	age	sex	timepoint
Sample1	Disease	Batch1	65	M	0d
Sample2	Control	Batch1	62	F	0d
```

---

## 🔄 Backward Compatibility

### Automatic Fallback

If no metadata file is provided:
1. Pipeline uses pattern matching
2. Searches for "ALS" pattern → "Disease" group
3. Searches for "control" pattern → "Control" group
4. Works exactly as before

### Legacy Column Support

All scripts maintain backward compatibility:
- If `ALS_mean`/`Control_mean` columns exist → Used as fallback
- If dynamic columns exist → Used preferentially
- Both sets of columns may be present in output tables

---

## ✅ Validation

### Automatic Checks

The system validates:
1. ✅ At least 2 groups identified
2. ✅ Each group has at least 2 samples
3. ✅ Sample IDs match between data and metadata (if provided)
4. ✅ Metadata file format is correct (if provided)

### Error Messages

Clear error messages guide users:
- `"Need at least 2 groups for comparison"` → Add more groups
- `"Each group needs at least 2 samples"` → Add more samples
- `"Metadata file must contain 'sample_id' column"` → Fix metadata format

---

## 🧪 Testing

### Test Case 1: With Metadata File

```bash
# 1. Create metadata file
cat > sample_metadata.tsv << EOF
sample_id	group
Sample1	Parkinson
Sample2	Parkinson
Sample3	Healthy
Sample4	Healthy
EOF

# 2. Add to config.yaml
paths:
  data:
    metadata: "sample_metadata.tsv"

# 3. Run pipeline
snakemake -j 4

# Expected: Groups "Parkinson" and "Healthy" detected
# Tables: Parkinson_mean, Healthy_mean
# Figures: Labels "Parkinson vs Healthy"
```

### Test Case 2: Without Metadata (Pattern Matching)

```bash
# 1. No metadata file in config.yaml
# 2. Sample names contain "ALS" or "control"
# 3. Run pipeline

# Expected: Groups "Disease" and "Control" detected (from patterns)
# Tables: Disease_mean, Control_mean (or ALS_mean, Control_mean)
# Figures: Labels "Disease vs Control"
```

---

## 📚 Related Documentation

- **`FLEXIBLE_GROUP_SYSTEM.md`** - User guide for flexible groups
- **`DATA_FORMAT_AND_FLEXIBILITY.md`** - Input data format details
- **`README.md`** - Main pipeline documentation
- **`sample_metadata_template.tsv`** - Metadata file template

---

## 🎯 Summary

**How It Works:**
1. ✅ Metadata file (if provided) → Explicit group assignment
2. ✅ Pattern matching (if no metadata) → Automatic group detection
3. ✅ Dynamic column generation → Adapts to any group names
4. ✅ Backward compatibility → Works with existing workflows

**Key Benefits:**
- ✅ Flexible group names (not limited to ALS/Control)
- ✅ Explicit control via metadata file
- ✅ Automatic fallback to pattern matching
- ✅ No breaking changes to existing workflows

---

**Document Maintained By:** Pipeline Development Team  
**Last Updated:** 2025-01-21

