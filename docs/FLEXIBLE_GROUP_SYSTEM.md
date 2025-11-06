# 🔄 Flexible Group Assignment System

**Date:** 2025-01-21  
**Purpose:** Documentation for the new flexible group assignment system that supports any condition names, not just "ALS" and "Control"

---

## 🎯 Overview

The pipeline now supports **flexible group assignment** through a metadata file system. This allows you to:

- ✅ Use **any condition/group names** (not limited to "ALS"/"Control")
- ✅ Specify groups explicitly in a metadata file
- ✅ Maintain backward compatibility with pattern matching (fallback method)
- ✅ Support any number of groups (currently optimized for 2-group comparisons)

---

## 📋 How It Works

### Priority System

The pipeline uses a **two-tier priority system**:

1. **Priority 1: Metadata File** (if provided)
   - Loads groups from a TSV metadata file
   - Exact matching of sample IDs to column names
   - Supports any group names

2. **Priority 2: Pattern Matching** (fallback)
   - Uses pattern matching on column names
   - Backward compatible with existing workflows
   - Default patterns: "ALS" → "Disease", "control" → "Control"

---

## 📝 Metadata File Format

### Required Columns

**Minimum Required:**
- `sample_id`: Must **exactly match** column names in your data CSV file
- `group`: Condition/group name (can be **anything** - "ALS", "Parkinson", "Disease", "Treatment", etc.)

### Optional Columns (for Advanced Analyses)

- `batch`: Batch or run identifier (for batch effect analysis)
- `age`: Age of the subject (for confounder analysis)
- `sex`: Sex of the subject (M/F or Male/Female, for confounder analysis)
- `timepoint`: Time point (e.g., 0d, 7d, 14d, 1m, 3m, 6m, 1y)
- `subject_id`: Unique identifier for each subject
- `diagnosis`: Clinical diagnosis
- `treatment`: Treatment received
- `notes`: Additional notes

### Example Metadata File

**Format:** TSV (tab-separated values)

```tsv
sample_id	group	batch	age	sex
Magen-ALS-enrolment-bloodplasma-SRR13934430	ALS	Batch1	65	M
Magen-ALS-enrolment-bloodplasma-SRR13934402	ALS	Batch1	58	F
Magen-control-control-bloodplasma-SRR14631747	Control	Batch1	62	F
Magen-control-control-bloodplasma-SRR14631738	Control	Batch1	55	M
```

**For Any Disease:**
```tsv
sample_id	group	batch	age	sex
Sample-001	Parkinson	Batch1	70	M
Sample-002	Parkinson	Batch1	68	F
Sample-003	Healthy	Batch1	69	M
Sample-004	Healthy	Batch1	71	F
```

---

## ⚙️ Configuration

### config.yaml

Add the metadata file path to your `config.yaml`:

```yaml
paths:
  data:
    # ... other data paths ...
    metadata: "/path/to/your/sample_metadata.tsv"  # Optional but recommended
```

**If Not Provided:**
- Pipeline will use pattern matching as fallback
- Still works but with less flexibility

---

## 🔧 Function Details

### `extract_sample_groups()`

**Signature:**
```r
extract_sample_groups(data, 
                      als_pattern = "ALS", 
                      control_pattern = "control|Control|CTRL",
                      metadata_file = NULL)
```

**Parameters:**
- `data`: Data frame with sample columns
- `als_pattern`: Regex pattern for disease samples (used only if metadata not provided)
- `control_pattern`: Regex pattern for control samples (used only if metadata not provided)
- `metadata_file`: Path to metadata TSV file (optional)

**Returns:**
- Data frame with columns: `sample_id`, `group` (and other metadata columns if present)

**Behavior:**
1. If `metadata_file` is provided and exists → Loads groups from metadata
2. If metadata file not provided or fails → Uses pattern matching
3. Validates that at least 2 groups exist, each with 2+ samples

### `split_data_by_groups()`

**Signature:**
```r
split_data_by_groups(data, groups_df)
```

**Returns:**
- List with data frames for each group
- For 2 groups: Returns backward-compatible `als_data`, `control_data` (even if groups aren't named "ALS"/"Control")
- Also returns generic names: `{group_name}_data`, `{group_name}_samples`
- Includes: `groups`, `n_groups`, `group1_name`, `group2_name`

---

## 📊 Impact on Outputs

### Tables

**Column Names:**
- Dynamically generated from group names
- Example: If groups are "Parkinson" and "Healthy":
  - `Parkinson_mean`, `Parkinson_sd`, `Parkinson_n`
  - `Healthy_mean`, `Healthy_sd`, `Healthy_n`
- For backward compatibility with 2 groups, also includes:
  - `als_data` → first group
  - `control_data` → second group

### Figures

**Labels and Colors:**
- Group labels: From parsed groups (not hardcoded)
- Colors: Still configurable in `config.yaml`, but will be applied to whatever groups are found

**Example:**
- If groups are "Disease" and "Control":
  - Figures will show "Disease" vs "Control" labels
  - Colors from config will apply to these groups

---

## 🧪 Validation

### Requirements

1. **Metadata File:**
   - Must contain `sample_id` column
   - Must contain `group` column
   - `sample_id` must exactly match data column names

2. **Groups:**
   - At least 2 groups required
   - Each group needs at least 2 samples

3. **Sample Matching:**
   - Samples in data but not in metadata → Excluded (with warning)
   - Samples in metadata but not in data → Excluded (with warning)

### Error Messages

- `"Need at least 2 groups for comparison"` → Add more groups or samples
- `"Each group needs at least 2 samples"` → Add more samples to the group
- `"Metadata file must contain 'sample_id' column"` → Fix metadata file format
- `"samples in data but not in metadata file"` → Add missing samples to metadata

---

## 📚 Examples

### Example 1: ALS vs Control (Current Data)

**Metadata file:**
```tsv
sample_id	group	batch
Magen-ALS-enrolment-bloodplasma-SRR13934430	ALS	Batch1
Magen-control-control-bloodplasma-SRR14631747	Control	Batch1
```

**Result:**
- Groups: "ALS" (626 samples), "Control" (204 samples)
- Tables: `ALS_mean`, `Control_mean`, etc.
- Figures: Labels "ALS" vs "Control"

### Example 2: Parkinson vs Healthy

**Metadata file:**
```tsv
sample_id	group	batch
PD-001	Parkinson	Batch1
PD-002	Parkinson	Batch1
Healthy-001	Healthy	Batch1
Healthy-002	Healthy	Batch1
```

**Result:**
- Groups: "Parkinson" (2 samples), "Healthy" (2 samples)
- Tables: `Parkinson_mean`, `Healthy_mean`, etc.
- Figures: Labels "Parkinson" vs "Healthy"

### Example 3: Multiple Groups (Experimental)

**Metadata file:**
```tsv
sample_id	group
Sample1	Treatment_A
Sample2	Treatment_B
Sample3	Control
```

**Result:**
- Groups: "Treatment_A", "Treatment_B", "Control"
- **Note:** Currently optimized for 2-group comparisons. Multi-group support may require additional script modifications.

---

## 🔄 Migration Guide

### For Existing Users (Using Pattern Matching)

**No changes required!** Your pipeline will continue to work:
- If you don't provide a metadata file, pattern matching is used
- Existing workflows remain functional

### For New Users (Wanting Flexibility)

1. **Create metadata file:**
   - Use `sample_metadata_template.tsv` as a template
   - Or use `sample_metadata_template_minimal.tsv` for minimal format

2. **Add to config.yaml:**
   ```yaml
   paths:
     data:
       metadata: "/path/to/your/sample_metadata.tsv"
   ```

3. **Run pipeline:**
   - Pipeline will automatically use metadata file
   - Groups will be loaded from metadata

---

## ✅ Summary

**Benefits:**
- ✅ Flexible group names (not limited to "ALS"/"Control")
- ✅ Explicit control over group assignments
- ✅ Better support for batch/confounder analysis
- ✅ Backward compatible with pattern matching

**Requirements:**
- ✅ Metadata file must have `sample_id` and `group` columns
- ✅ `sample_id` must exactly match data column names
- ✅ At least 2 groups, each with 2+ samples

**Fallback:**
- ✅ If metadata not provided → Pattern matching (backward compatible)

---

## 🔄 How It Works (Technical Details)

### Step-by-Step Flow

1. **Script Execution:**
   - Each R script loads `group_comparison.R` utilities
   - Calls `extract_sample_groups(data, metadata_file = metadata_file)`

2. **Group Detection:**
   - If `metadata_file` provided in `config.yaml` → Loads from metadata
   - If metadata not provided → Uses pattern matching on column names
   - Validates groups (at least 2 groups, 2+ samples each)

3. **Dynamic Column Generation:**
   - Scripts detect group names from `groups_df`
   - Generate column names dynamically: `{group_name}_mean`, `{group_name}_sd`
   - Falls back to `ALS_mean`/`Control_mean` if dynamic columns not found

4. **Visualization:**
   - Labels use dynamic group names
   - Colors assigned based on group names (configurable in `config.yaml`)
   - Figures automatically adapt to group names

### Example: Complete Workflow

**Input:**
```yaml
# config.yaml
paths:
  data:
    metadata: "sample_metadata.tsv"
```

**Metadata file:**
```tsv
sample_id	group
Sample1	Parkinson
Sample2	Parkinson
Sample3	Healthy
Sample4	Healthy
```

**Result:**
- Groups detected: "Parkinson" (2 samples), "Healthy" (2 samples)
- Tables: `Parkinson_mean`, `Healthy_mean`, `log2FoldChange`
- Figures: Labels show "Parkinson vs Healthy"
- Colors: Applied to Parkinson and Healthy groups

---

**Document Maintained By:** Pipeline Development Team  
**Last Updated:** 2025-01-21

