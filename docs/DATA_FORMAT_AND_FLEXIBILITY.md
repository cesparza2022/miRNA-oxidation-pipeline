# 📊 Data Format and Pipeline Flexibility

**Date:** 2025-01-21  
**Purpose:** Document data format requirements, parsing patterns, and pipeline flexibility

---

## 📋 Data Format Overview

### Current Data Structure

**Source:** `results/step1_5/final/tables/filtered_data/ALL_MUTATIONS_VAF_FILTERED.csv`

**Format:** CSV (Comma-separated values)

**Structure:**
```
miRNA name, pos:mut, Sample1, Sample2, Sample3, ...
```

**Column Types:**
1. **Metadata columns** (first 2 columns):
   - `miRNA name` or `miRNA_name`: miRNA identifier (e.g., "hsa-let-7a-2-3p")
   - `pos:mut` or `pos.mut`: Position and mutation (e.g., "PM", "7:AT", "18:TC")

2. **Sample columns** (all remaining columns):
   - Each column represents one sample
   - Column names contain sample identifiers
   - Values are counts (integers) or NA

---

## 🔍 Sample Group Parsing

### How Groups are Identified

The pipeline uses **pattern matching** on column names to identify sample groups.

### Pattern Matching Rules

**Function:** `extract_sample_groups()` in `scripts/utils/group_comparison.R`

**Default Patterns:**
- **ALS samples:** Column names containing `"ALS"` (case-insensitive)
- **Control samples:** Column names containing `"control"`, `"Control"`, or `"CTRL"` (case-insensitive)

**Pattern Matching Logic:**
```r
group = case_when(
  str_detect(sample_id, regex("ALS", ignore_case = TRUE)) ~ "ALS",
  str_detect(sample_id, regex("control|Control|CTRL", ignore_case = TRUE)) ~ "Control",
  TRUE ~ NA_character_  # Unmatched samples
)
```

### Current Data Sample Names

**Example ALS samples:**
- `Magen-ALS-enrolment-bloodplasma-SRR13934430`
- `Magen-ALS-enrolment-bloodplasma-SRR13934402`
- `Magen-ALS-longitudinal_2-bloodplasma-SRR13934499`

**Example Control samples:**
- `Magen-control-control-bloodplasma-SRR14631747`
- `Magen-control-control-bloodplasma-SRR14631738`
- `Magen-control-control-bloodplasma-SRR14631805`

**Pattern Detection:**
- ✅ `"ALS"` in column name → Classified as **ALS**
- ✅ `"control"` in column name → Classified as **Control**
- ⚠️ Samples without either pattern → **Excluded** from analysis

---

## 🔧 Flexibility and Customization

### 1. Column Name Flexibility

**Metadata Columns:**
- Accepts: `"miRNA name"`, `"miRNA_name"`, `"pos:mut"`, `"pos.mut"`
- Automatically normalizes to: `miRNA_name`, `pos.mut`

**Sample Columns:**
- Any column name NOT matching metadata patterns is treated as a sample
- Sample names can contain any characters
- Pattern matching is case-insensitive

### 2. Pattern Customization

**Can be customized in scripts:**
```r
# Custom ALS pattern
extract_sample_groups(data, als_pattern = "DISEASE|CASE")

# Custom control pattern
extract_sample_groups(data, control_pattern = "HEALTHY|NORMAL")
```

**Note:** Currently, patterns are hardcoded in the scripts. For full customization, you would need to:
1. Add pattern parameters to `config.yaml`
2. Pass them through Snakemake rules
3. Use them in R scripts

### 3. File Format Flexibility

**Supported Formats:**
- ✅ CSV (`.csv`) - **Primary format**
- ✅ TSV (`.tsv`) - **Alternative format**

**Automatic Detection:**
```r
if (str_ends(input_file, ".csv")) {
  data <- read_csv(input_file, show_col_types = FALSE)
} else {
  data <- read_tsv(input_file, show_col_types = FALSE)
}
```

### 4. Data Value Flexibility

**Accepted Values:**
- ✅ Integers (counts): `0`, `1`, `50`, `100`
- ✅ NA (missing values): `NA`, empty cells
- ⚠️ Decimals: Supported but may be rounded in some analyses

**Data Type Handling:**
- Counts are expected to be integers
- Missing values (NA) are handled gracefully
- Negative values are not expected but may be filtered

---

## 📐 Input Data Requirements

### Minimum Requirements

1. **Required Columns:**
   - At least one metadata column: `miRNA name` or `miRNA_name`
   - At least one metadata column: `pos:mut` or `pos.mut`
   - At least one sample column

2. **Required Groups:**
   - At least **2 samples** in ALS group
   - At least **2 samples** in Control group

3. **Data Format:**
   - CSV or TSV format
   - First row contains column names
   - Subsequent rows contain data

### Validation

The pipeline validates:
- ✅ File exists and is readable
- ✅ Required metadata columns present
- ✅ At least 2 groups with samples identified
- ⚠️ Missing values are handled but may affect statistics

---

## 🎯 Example Data Formats

### Format 1: Current Format (VAF-filtered)

```csv
miRNA name,pos:mut,Sample1-ALS,Sample2-ALS,Sample3-control,Sample4-control
hsa-let-7a-2-3p,PM,0,1,2,0
hsa-let-7a-2-3p,7:AT,0,0,1,0
```

### Format 2: Alternative Metadata Column Names

```csv
miRNA_name,pos.mut,Sample1_ALS,Sample2_ALS,Sample3_Control,Sample4_Control
hsa-let-7a-2-3p,PM,0,1,2,0
```

### Format 3: Different Group Naming

```csv
miRNA name,pos:mut,DISEASE_1,DISEASE_2,HEALTHY_1,HEALTHY_2
hsa-let-7a-2-3p,PM,0,1,2,0
```

**Note:** For Format 3, you would need to customize the patterns in the scripts.

---

## 🔄 Batch Information Parsing

### Current Implementation

**Batch Effect Analysis:**
- Attempts to infer batch from sample names or metadata
- If no batch information is available, creates dummy batches for demonstration
- **Recommendation:** Provide explicit batch information in a metadata file

### Metadata File Format (Optional)

If you have a metadata file with batch, age, sex information:

```tsv
Sample,Group,Batch,Age,Sex
Sample1-ALS,ALS,Batch1,45,M
Sample2-ALS,ALS,Batch1,52,F
Sample3-control,Control,Batch2,48,M
```

**Location:** Should be specified in `config.yaml` under `paths.data.metadata`

**If Not Provided:**
- Batch effect analysis will use dummy batches
- Confounder analysis will be limited
- Pipeline will still run but with warnings

---

## 📊 Graph and Table Generation

### Figure Generation

**Patterns Used in Figures:**
- **Group labels:** "ALS" and "Control" (from parsed groups)
- **Colors:** 
  - ALS: `#D62728` (red) - from `config.yaml`
  - Control: `grey60` - from `config.yaml`

**Flexibility:**
- Colors can be customized in `config.yaml`
- Group labels come from parsed groups (not hardcoded)
- Figure dimensions configurable in `config.yaml`

### Table Generation

**Column Names in Tables:**
- `ALS_mean`, `ALS_sd`, `ALS_n` - from parsed group names
- `Control_mean`, `Control_sd`, `Control_n` - from parsed group names
- `fold_change`, `log2_fold_change` - calculated
- `t_test_pvalue`, `wilcoxon_pvalue` - calculated
- `t_test_fdr`, `wilcoxon_fdr` - calculated
- `significant` - boolean based on thresholds

**Flexibility:**
- Column names are dynamically generated from group names
- If groups are named differently, column names will reflect that

---

## ⚙️ Configuration Options

### Current Configurable Parameters

**In `config.yaml`:**
```yaml
analysis:
  alpha: 0.05  # Significance threshold
  fdr_method: "BH"  # FDR correction method
  log2fc_threshold_step2: 0.58
  log2fc_threshold_step3: 1.0
  colors:
    gt: "#D62728"
    control: "grey60"
    als: "#D62728"
  figure:
    dpi: 300
    width: 12
    height: 10
```

**Not Currently Configurable (Hardcoded):**
- ALS pattern: `"ALS"`
- Control pattern: `"control|Control|CTRL"`
- Metadata column names: `["miRNA_name", "miRNA name", "pos.mut", "pos:mut"]`

---

## 🧪 Testing with Current Data

### Data Verification

**Current Status:**
- ✅ Data file exists: `ALL_MUTATIONS_VAF_FILTERED.csv` (168 MB)
- ✅ Format: CSV with proper headers
- ✅ Metadata columns: `miRNA name`, `pos:mut`
- ✅ Sample groups: ALS and Control samples identified
- ✅ Pattern matching: Works with current sample names

### Sample Group Counts (from current data)

**Expected after parsing:**
- ALS samples: ~200+ samples (containing "ALS" in name)
- Control samples: ~50+ samples (containing "control" in name)
- Other samples: Samples with "(PM+1MM+2MM)" suffix (may be excluded)

---

## 🚀 Recommendations for Users

### For New Datasets

1. **Ensure sample names contain group identifiers:**
   - Include "ALS" or "DISEASE" or "CASE" for disease group
   - Include "control" or "CTRL" or "HEALTHY" for control group

2. **Use standard metadata column names:**
   - `miRNA name` or `miRNA_name`
   - `pos:mut` or `pos.mut`

3. **Provide metadata file if available:**
   - Batch information
   - Age, sex, or other covariates

4. **Test pattern matching first:**
   ```r
   source("scripts/utils/group_comparison.R")
   groups <- extract_sample_groups(data)
   ```

### For Custom Patterns

If your dataset uses different naming:
1. Modify `extract_sample_groups()` calls in scripts
2. Or create a wrapper function that pre-processes column names
3. Or rename columns to match expected patterns

---

## 📝 Summary

**Current Pipeline Flexibility:**

✅ **Flexible:**
- File format (CSV/TSV)
- Metadata column name variations
- Sample column naming (as long as patterns are present)
- Data values (integers, NA)
- Colors and figure dimensions

⚠️ **Semi-Flexible:**
- Group patterns (hardcoded but can be customized in scripts)
- Batch information (can infer or use metadata)

❌ **Not Flexible (Hardcoded):**
- Group patterns in default configuration
- Two-group comparison assumption (ALS vs Control)
- Some metadata column name expectations

**For Maximum Flexibility:**
- Add pattern configuration to `config.yaml`
- Pass patterns through Snakemake rules
- Use configurable patterns in R scripts

---

**Document Maintained By:** Pipeline Development Team  
**Last Updated:** 2025-01-21

