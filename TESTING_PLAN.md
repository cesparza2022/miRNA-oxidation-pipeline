# 🧪 Testing Plan - Phase 1 Critical Corrections

**Date:** 2025-01-21  
**Purpose:** Validate all Phase 1 critical corrections (statistical assumptions, batch effects, confounders)

---

## 📋 Overview

This testing plan validates the newly implemented critical statistical improvements:
1. ✅ Statistical assumptions validation
2. ✅ Batch effect analysis
3. ✅ Confounder analysis
4. ✅ Integration in Step 2.1

---

## 🎯 Pre-Testing Checklist

### 1. Environment Setup

```bash
# Verify conda environment is activated
conda activate mirna_oxidation_pipeline

# Check key packages
Rscript -e "library(tidyverse); library(ggplot2); cat('✅ Core packages OK\n')"
```

### 2. Configuration Check

```bash
# Verify config.yaml exists and is properly configured
cat config/config.yaml | grep -E "alpha|fdr_method|assumptions|batch_correction|confounders"
```

**Expected output should include:**
- `alpha: 0.05`
- `fdr_method: "BH"`
- `assumptions:` section
- `batch_correction:` section
- `confounders:` section

### 3. Data Availability

**Required:**
- VAF-filtered data from Step 1.5: `outputs/step1_5/tables/filtered_data/ALL_MUTATIONS_VAF_FILTERED.csv`
- OR processed clean data: Path specified in `config.yaml`

**Optional (for full testing):**
- Sample metadata file with `batch`, `age`, `sex` columns

---

## 🧪 Testing Steps

### Test 1: Statistical Assumptions Validation

**Objective:** Verify that assumption checking functions work correctly

**Steps:**
1. **Dry-run Step 2.1:**
   ```bash
   snakemake -j 1 step2_statistical_comparisons -n
   ```

2. **Check inputs:**
   - Verify `scripts/utils/statistical_assumptions.R` exists
   - Verify it's loaded in Step 2.1

3. **Run Step 2.1 with assumption checking:**
   ```bash
   snakemake -j 1 step2_statistical_comparisons
   ```

4. **Validate outputs:**
   ```bash
   # Check assumption report exists
   ls -lh outputs/step2/logs/statistical_assumptions_report.txt
   
   # Check report content
   cat outputs/step2/logs/statistical_assumptions_report.txt
   ```

**Expected outputs:**
- ✅ `outputs/step2/logs/statistical_assumptions_report.txt` exists
- ✅ Report contains normality check results
- ✅ Report contains variance homogeneity check results
- ✅ Report contains test recommendation

**Success criteria:**
- No errors in logs
- Assumption report is readable
- Test recommendation is logical

---

### Test 2: Batch Effect Analysis

**Objective:** Verify batch effect detection and reporting

**Steps:**
1. **Dry-run batch effect analysis:**
   ```bash
   snakemake -j 1 step2_batch_effect_analysis -n
   ```

2. **Run batch effect analysis:**
   ```bash
   snakemake -j 1 step2_batch_effect_analysis
   ```

3. **Validate outputs:**
   ```bash
   # Check batch-corrected data exists
   ls -lh outputs/step2/tables/statistical_results/S2_batch_corrected_data.csv
   
   # Check PCA plot exists
   ls -lh outputs/step2/figures/step2_batch_effect_pca_before.png
   
   # Check report exists
   ls -lh outputs/step2/logs/batch_effect_report.txt
   
   # View report
   cat outputs/step2/logs/batch_effect_report.txt
   ```

**Expected outputs:**
- ✅ `outputs/step2/tables/statistical_results/S2_batch_corrected_data.csv`
- ✅ `outputs/step2/figures/step2_batch_effect_pca_before.png`
- ✅ `outputs/step2/logs/batch_effect_report.txt`

**Report should contain:**
- Number of batches detected
- Batch effect significance (yes/no)
- Statistical test results (ANOVA p-values)
- PCA variance explained
- Recommendations

**Success criteria:**
- No errors in logs
- PCA plot is generated and readable
- Report is comprehensive
- Batch-corrected data has same structure as input

---

### Test 3: Confounder Analysis

**Objective:** Verify confounder analysis and group balance assessment

**Steps:**
1. **Dry-run confounder analysis:**
   ```bash
   snakemake -j 1 step2_confounder_analysis -n
   ```

2. **Run confounder analysis:**
   ```bash
   snakemake -j 1 step2_confounder_analysis
   ```

3. **Validate outputs:**
   ```bash
   # Check group balance table exists
   ls -lh outputs/step2/tables/statistical_results/S2_group_balance.json
   
   # Check balance plot exists
   ls -lh outputs/step2/figures/step2_group_balance.png
   
   # Check report exists
   ls -lh outputs/step2/logs/confounder_analysis_report.txt
   
   # View report
   cat outputs/step2/logs/confounder_analysis_report.txt
   ```

**Expected outputs:**
- ✅ `outputs/step2/tables/statistical_results/S2_group_balance.json` (or CSV)
- ✅ `outputs/step2/figures/step2_group_balance.png`
- ✅ `outputs/step2/logs/confounder_analysis_report.txt`

**Report should contain:**
- Age distribution by group (if available)
- Sex distribution by group (if available)
- Statistical test results (t-test, Chi-square)
- Balance assessment (balanced/imbalanced)
- Recommendations

**Success criteria:**
- No errors in logs
- Balance plot is generated (if confounder data available)
- Report is comprehensive
- Graceful handling when metadata is missing

---

### Test 4: Step 2.1 Integration

**Objective:** Verify Step 2.1 uses batch-corrected data and assumption validation

**Steps:**
1. **Run complete Step 2 (including new steps):**
   ```bash
   snakemake -j 1 all_step2
   ```

2. **Check execution order:**
   - Step 2.0 (batch effects) should run first
   - Step 2.0b (confounders) should run in parallel or after 2.0
   - Step 2.1 (statistical comparisons) should use batch-corrected data

3. **Validate Step 2.1 outputs:**
   ```bash
   # Check statistical results
   ls -lh outputs/step2/tables/statistical_results/S2_statistical_comparisons.csv
   
   # Check assumption report
   ls -lh outputs/step2/logs/statistical_assumptions_report.txt
   
   # View first few lines of results
   head -20 outputs/step2/tables/statistical_results/S2_statistical_comparisons.csv
   ```

**Expected outputs:**
- ✅ Statistical comparisons table with p-values and FDR
- ✅ Assumption validation report
- ✅ Log file indicates batch-corrected data was used

**Success criteria:**
- No errors in execution
- Results table has expected columns
- Assumption validation was performed
- Data source is correct (batch-corrected if available)

---

### Test 5: End-to-End Pipeline Test

**Objective:** Verify complete pipeline execution with new steps

**Steps:**
1. **Run complete pipeline:**
   ```bash
   snakemake -j 4  # Use 4 cores
   ```

2. **Check all Step 2 outputs:**
   ```bash
   # List all Step 2 outputs
   find outputs/step2 -type f | sort
   ```

3. **Validate output structure:**
   ```bash
   # Figures
   ls outputs/step2/figures/
   # Should include:
   # - step2_batch_effect_pca_before.png
   # - step2_group_balance.png
   # - step2_volcano_plot.png
   # - step2_effect_size_distribution.png
   
   # Tables
   ls outputs/step2/tables/statistical_results/
   # Should include:
   # - S2_batch_corrected_data.csv
   # - S2_group_balance.json
   # - S2_statistical_comparisons.csv
   # - S2_effect_sizes.csv
   
   # Logs
   ls outputs/step2/logs/
   # Should include:
   # - batch_effect_analysis.log
   # - confounder_analysis.log
   # - statistical_comparisons.log
   # - batch_effect_report.txt
   # - confounder_analysis_report.txt
   # - statistical_assumptions_report.txt
   ```

**Success criteria:**
- All expected files are generated
- No errors in any log files
- Outputs are readable and have expected structure
- Pipeline completes successfully

---

## 🔍 Validation Checks

### Check 1: Assumption Validation Report

**File:** `outputs/step2/logs/statistical_assumptions_report.txt`

**Should contain:**
- Normality check results (Shapiro-Wilk/KS p-values)
- Variance homogeneity check results (Levene's/Bartlett's p-values)
- Recommended test (parametric/non-parametric)
- Summary statistics

**Validation:**
```bash
# Check report exists and has content
if [ -f outputs/step2/logs/statistical_assumptions_report.txt ]; then
  echo "✅ Assumption report exists"
  wc -l outputs/step2/logs/statistical_assumptions_report.txt
  echo "--- First 20 lines:"
  head -20 outputs/step2/logs/statistical_assumptions_report.txt
else
  echo "❌ Assumption report missing"
fi
```

### Check 2: Batch Effect Report

**File:** `outputs/step2/logs/batch_effect_report.txt`

**Should contain:**
- Number of batches
- Batch effect significance
- Statistical test p-values
- PCA variance explained
- Recommendations

**Validation:**
```bash
# Check report
if [ -f outputs/step2/logs/batch_effect_report.txt ]; then
  echo "✅ Batch effect report exists"
  grep -E "batches|significant|p-value|PCA|RECOMMENDATION" outputs/step2/logs/batch_effect_report.txt
else
  echo "❌ Batch effect report missing"
fi
```

### Check 3: Confounder Analysis Report

**File:** `outputs/step2/logs/confounder_analysis_report.txt`

**Should contain:**
- Age distribution (if available)
- Sex distribution (if available)
- Statistical test results
- Balance assessment
- Recommendations

**Validation:**
```bash
# Check report
if [ -f outputs/step2/logs/confounder_analysis_report.txt ]; then
  echo "✅ Confounder report exists"
  grep -E "AGE|SEX|balance|RECOMMENDATION" outputs/step2/logs/confounder_analysis_report.txt
else
  echo "❌ Confounder report missing"
fi
```

### Check 4: Statistical Results Table

**File:** `outputs/step2/tables/statistical_results/S2_statistical_comparisons.csv`

**Should contain columns:**
- `SNV_id`, `miRNA_name`, `pos.mut`
- `ALS_mean`, `ALS_sd`, `ALS_n`
- `Control_mean`, `Control_sd`, `Control_n`
- `fold_change`, `log2_fold_change`
- `t_test_pvalue`, `wilcoxon_pvalue`
- `t_test_fdr`, `wilcoxon_fdr`
- `t_test_significant`, `wilcoxon_significant`, `significant`

**Validation:**
```bash
# Check table structure
if [ -f outputs/step2/tables/statistical_results/S2_statistical_comparisons.csv ]; then
  echo "✅ Statistical results table exists"
  echo "--- Columns:"
  head -1 outputs/step2/tables/statistical_results/S2_statistical_comparisons.csv | tr ',' '\n' | nl
  echo "--- Row count:"
  wc -l outputs/step2/tables/statistical_results/S2_statistical_comparisons.csv
else
  echo "❌ Statistical results table missing"
fi
```

### Check 5: Data Quality

**Validation script:**
```r
# R script to validate data quality
library(tidyverse)

# Read statistical results
results <- read_csv("outputs/step2/tables/statistical_results/S2_statistical_comparisons.csv")

# Check p-values are in valid range [0, 1]
cat("P-value validation:\n")
cat("  t-test p-values in [0,1]:", all(results$t_test_pvalue >= 0 & results$t_test_pvalue <= 1, na.rm = TRUE), "\n")
cat("  Wilcoxon p-values in [0,1]:", all(results$wilcoxon_pvalue >= 0 & results$wilcoxon_pvalue <= 1, na.rm = TRUE), "\n")

# Check FDR values are in valid range [0, 1]
cat("FDR validation:\n")
cat("  t-test FDR in [0,1]:", all(results$t_test_fdr >= 0 & results$t_test_fdr <= 1, na.rm = TRUE), "\n")
cat("  Wilcoxon FDR in [0,1]:", all(results$wilcoxon_fdr >= 0 & results$wilcoxon_fdr <= 1, na.rm = TRUE), "\n")

# Check log2FC is reasonable (not infinite)
cat("Log2FC validation:\n")
cat("  Log2FC finite:", all(is.finite(results$log2_fold_change), na.rm = TRUE), "\n")
cat("  Log2FC range:", range(results$log2_fold_change, na.rm = TRUE), "\n")

cat("✅ Data quality checks passed\n")
```

---

## 🐛 Troubleshooting

### Issue 1: "statistical_assumptions.R not found"

**Error:**
```
Error: statistical_assumptions.R not found
```

**Solution:**
```bash
# Verify file exists
ls -lh scripts/utils/statistical_assumptions.R

# Check path in config or script
grep -r "statistical_assumptions" scripts/step2/01_statistical_comparisons.R
```

### Issue 2: "No batches detected"

**Warning:**
```
Less than 2 batches detected. Batch effect analysis may not be meaningful.
```

**Solution:**
- This is expected if data doesn't have batch structure
- Pipeline will skip batch correction and return original data
- Check batch effect report for explanation

### Issue 3: "No metadata available"

**Warning:**
```
No metadata file provided. Confounder analysis will be limited.
```

**Solution:**
- This is expected if metadata file is not provided
- Pipeline will still run but report limited confounder analysis
- To enable full analysis, provide metadata file with `age`, `sex`, `batch` columns

### Issue 4: "Batch-corrected data not found in Step 2.1"

**Error:**
```
Could not find input data file. Tried batch_corrected, vaf_filtered_data, and fallback_data.
```

**Solution:**
```bash
# Check Step 2.0 completed successfully
ls -lh outputs/step2/tables/statistical_results/S2_batch_corrected_data.csv

# Check logs for errors
cat outputs/step2/logs/batch_effect_analysis.log

# Manually run Step 2.0 first
snakemake -j 1 step2_batch_effect_analysis
```

---

## ✅ Success Criteria Summary

**All tests pass if:**
1. ✅ Statistical assumptions validation runs without errors
2. ✅ Batch effect analysis completes and generates report
3. ✅ Confounder analysis completes (gracefully handles missing metadata)
4. ✅ Step 2.1 uses batch-corrected data when available
5. ✅ All output files are generated with expected structure
6. ✅ Data quality checks pass (p-values in [0,1], FDR correct, etc.)
7. ✅ Logs are clean (no critical errors)

---

## 📝 Testing Report Template

After running tests, document results:

```markdown
# Testing Report - Phase 1 Critical Corrections

**Date:** [DATE]
**Tester:** [NAME]
**Data:** [DATA FILE PATH]

## Test Results

### Test 1: Statistical Assumptions Validation
- Status: ✅ PASS / ❌ FAIL
- Issues: [NONE / LIST ISSUES]
- Outputs: [LIST FILES]

### Test 2: Batch Effect Analysis
- Status: ✅ PASS / ❌ FAIL
- Issues: [NONE / LIST ISSUES]
- Outputs: [LIST FILES]

### Test 3: Confounder Analysis
- Status: ✅ PASS / ❌ FAIL
- Issues: [NONE / LIST ISSUES]
- Outputs: [LIST FILES]

### Test 4: Step 2.1 Integration
- Status: ✅ PASS / ❌ FAIL
- Issues: [NONE / LIST ISSUES]
- Outputs: [LIST FILES]

### Test 5: End-to-End Pipeline
- Status: ✅ PASS / ❌ FAIL
- Issues: [NONE / LIST ISSUES]
- Outputs: [LIST FILES]

## Summary
[OVERALL STATUS AND NEXT STEPS]
```

---

## 🚀 Quick Start Testing

**For quick validation, run:**

```bash
# 1. Activate environment
conda activate mirna_oxidation_pipeline

# 2. Run Step 2 (includes all new analyses)
snakemake -j 4 all_step2

# 3. Check outputs
ls -lh outputs/step2/figures/
ls -lh outputs/step2/tables/statistical_results/
ls -lh outputs/step2/logs/

# 4. View reports
cat outputs/step2/logs/batch_effect_report.txt
cat outputs/step2/logs/confounder_analysis_report.txt
cat outputs/step2/logs/statistical_assumptions_report.txt
```

---

**Document Maintained By:** Pipeline Development Team  
**For Issues:** See `README.md` for contact information

