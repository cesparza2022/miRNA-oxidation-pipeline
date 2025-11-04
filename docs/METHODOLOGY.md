# 📊 Statistical Methodology Documentation

**Pipeline:** miRNA Oxidation Analysis Pipeline  
**Version:** 1.0.0  
**Last Updated:** 2025-01-21

---

## Table of Contents

1. [Overview](#overview)
2. [Statistical Assumptions Validation](#statistical-assumptions-validation)
3. [Batch Effect Analysis and Correction](#batch-effect-analysis-and-correction)
4. [Confounder Analysis and Control](#confounder-analysis-and-control)
5. [Group Comparison Methods](#group-comparison-methods)
6. [Multiple Testing Correction](#multiple-testing-correction)
7. [Effect Size Estimation](#effect-size-estimation)
8. [References](#references)

---

## Overview

This pipeline implements rigorous statistical methods for comparing miRNA oxidation patterns between experimental groups (e.g., ALS vs. Control). The methodology emphasizes:

- **Statistical rigor**: Validating assumptions before selecting appropriate tests
- **Bias control**: Detecting and correcting for batch effects and confounders
- **Robust inference**: Using appropriate parametric or non-parametric tests based on data characteristics
- **Reproducibility**: Configurable parameters and transparent reporting

---

## Statistical Assumptions Validation

### Purpose

Before performing group comparisons, we validate statistical assumptions to ensure appropriate test selection and valid inference.

### Methods

#### 1. **Normality Testing**

**Tests Performed:**
- **Shapiro-Wilk Test**: For sample sizes ≤ 5000
  - Null hypothesis: Data are normally distributed
  - More powerful than other normality tests for small to moderate samples
- **Kolmogorov-Smirnov Test**: For sample sizes > 5000
  - Compares empirical distribution to theoretical normal distribution
- **Visual Assessment**: Skewness and kurtosis
  - Normal distribution: skewness ≈ 0, kurtosis ≈ 0
  - Acceptable range: |skewness| < 2, |kurtosis| < 2

**Implementation:**
```r
check_normality(data, group = NULL, alpha = 0.05)
```

**Decision Rule:**
- If normality assumptions are met → use parametric tests (t-test)
- If normality assumptions are violated → use non-parametric tests (Wilcoxon)

#### 2. **Variance Homogeneity Testing**

**Tests Performed:**
- **Levene's Test**: Primary test (robust to non-normality)
  - Tests equality of variances across groups
  - Uses absolute deviations from group means
- **Bartlett's Test**: Secondary test (more powerful if data are normal)
  - More sensitive to non-normality than Levene's

**Implementation:**
```r
check_variance_homogeneity(data, group, alpha = 0.05)
```

**Decision Rule:**
- If variances are equal → use standard t-test
- If variances are unequal → use Welch's t-test (unequal variances)

#### 3. **Diagnostic Plots**

**Plots Generated:**
- **Q-Q Plots**: Visual assessment of normality
  - Points should follow diagonal line if normally distributed
- **Histograms with Normal Overlay**: Distribution shape assessment
- **Box Plots by Group**: Visual check for variance homogeneity and outliers

**Implementation:**
```r
diagnostic_plots(data, group = NULL, output_dir = NULL, prefix = "diagnostic")
```

### Automatic Test Selection

The pipeline automatically selects the appropriate statistical test based on assumption validation:

**Decision Tree:**
1. **Normal + Equal Variances** → t-test (two-sample, equal variances)
2. **Normal + Unequal Variances** → t-test (Welch's, unequal variances)
3. **Non-normal** → Wilcoxon rank-sum test (non-parametric)

**Implementation:**
```r
select_appropriate_test(data, group, alpha = 0.05, output_dir = NULL, prefix = "assumptions")
```

### Configuration

Assumption checking can be configured in `config.yaml`:

```yaml
analysis:
  assumptions:
    check_normality: true
    check_variance_homogeneity: true
    generate_diagnostic_plots: true
    auto_select_test: true
```

### Reporting

Assumption validation results are:
- Logged during pipeline execution
- Saved to `outputs/step2/logs/statistical_assumptions_report.txt`
- Included in diagnostic plots directory

---

## Batch Effect Analysis and Correction

### Purpose

Batch effects are systematic technical variations introduced during data collection or processing that can confound biological signals. This pipeline detects and optionally corrects batch effects before statistical comparisons.

### Methods

#### 1. **Principal Component Analysis (PCA)**

**Purpose:** Visualize and detect batch clustering in high-dimensional data space.

**Implementation:**
- Data transformation: log2(count + 1) to reduce skewness
- PCA on transposed count matrix (samples as rows, SNVs as columns)
- Standardization: center and scale before PCA
- Visualization: PC1 vs PC2 colored by batch

**Interpretation:**
- If batches cluster separately → batch effects likely present
- If batches overlap → no strong batch effects

#### 2. **Statistical Testing for Batch Effects**

**Tests Performed:**
- **ANOVA on PC1 by Batch**: Tests if batch explains variance in first principal component
- **ANOVA on PC2 by Batch**: Tests if batch explains variance in second principal component
- **Chi-square Test**: Tests independence of batch and group (confounding assessment)

**Decision Rule:**
- If p-value < threshold (default: 0.05) → significant batch effects detected
- If batch and group are confounded → warning issued (may bias results)

#### 3. **Batch Correction Methods**

**Available Methods (configurable):**
- **`none`**: No correction applied (default)
- **`mean_centering`**: Simple per-batch mean centering (placeholder)
- **`combat`**: ComBat method (requires `sva` package) - **Not yet implemented**
- **`limma`**: limma's `removeBatchEffect()` (requires `limma` package) - **Not yet implemented**

**Recommended Approach:**
For production use, implement ComBat or limma's batch correction methods, which are well-validated in genomics literature.

### Configuration

```yaml
analysis:
  batch_correction:
    method: "none"  # Options: "none", "mean_centering", "combat", "limma"
    pvalue_threshold: 0.05
```

### Outputs

- **Batch-corrected data**: `outputs/step2/tables/statistical_results/S2_batch_corrected_data.csv`
- **PCA plot**: `outputs/step2/figures/step2_batch_effect_pca_before.png`
- **Report**: `outputs/step2/logs/batch_effect_report.txt`

### Interpretation

**If batch effects are detected:**
- ⚠️ Consider batch correction for downstream analysis
- ⚠️ Report batch effects in publication
- ⚠️ If batch and group are confounded, results may be biased

**If no batch effects:**
- ✓ Proceed with standard analysis
- ✓ No correction needed

---

## Confounder Analysis and Control

### Purpose

Confounders are variables that are associated with both the exposure (group) and outcome (miRNA oxidation), potentially biasing results. This pipeline assesses group balance on potential confounders (e.g., age, sex) and provides recommendations for adjusted models.

### Methods

#### 1. **Group Balance Assessment**

**Variables Analyzed:**
- **Age**: Continuous variable
  - Summary statistics: mean, SD, median, min, max per group
  - Statistical test: t-test (or Wilcoxon if non-normal)
  
- **Sex**: Categorical variable
  - Summary: frequency and percentage per group
  - Statistical test: Chi-square test of independence

**Implementation:**
```r
# Age balance
age_test <- t.test(age[group == "ALS"], age[group == "Control"])

# Sex balance
sex_test <- chisq.test(table(group, sex))
```

#### 2. **Balance Interpretation**

**Decision Rules:**
- **Age imbalance (p < 0.05)**: Groups differ significantly in age
  - **Recommendation**: Adjust for age in statistical models (ANCOVA)
- **Sex imbalance (p < 0.05)**: Groups differ significantly in sex distribution
  - **Recommendation**: Adjust for sex in statistical models (GLM)
- **No imbalance**: Groups appear balanced
  - **Recommendation**: Unadjusted analysis should be valid, but adjusting anyway improves robustness

#### 3. **Visualization**

**Plots Generated:**
- **Age Distribution**: Violin plots with box plots and jitter points
- **Sex Distribution**: Stacked bar charts showing percentages

### Configuration

```yaml
analysis:
  confounders:
    adjust: true  # Whether to adjust for confounders in models
    variables: ["age", "sex"]  # List of confounders to analyze
```

### Outputs

- **Group balance table**: `outputs/step2/tables/statistical_results/S2_group_balance.json`
- **Balance plot**: `outputs/step2/figures/step2_group_balance.png`
- **Report**: `outputs/step2/logs/confounder_analysis_report.txt`

### Recommendations

**If imbalance detected:**
- ⚠️ Use multivariate models (ANCOVA, GLM) to adjust for confounders
- ⚠️ Report both unadjusted and adjusted results
- ⚠️ Acknowledge potential residual confounding in limitations

**If balanced:**
- ✓ Unadjusted analysis should be valid
- ✓ Consider adjusting anyway for robustness (recommended)

### Future Implementation

**Planned additions:**
- ANCOVA models with age as covariate
- GLM models with sex as covariate
- Multivariate models with multiple confounders
- Comparison of unadjusted vs. adjusted results

---

## Group Comparison Methods

### Purpose

Compare miRNA oxidation patterns (G>T mutation counts) between experimental groups (e.g., ALS vs. Control) for each SNV.

### Methods

#### 1. **Parametric Tests: t-test**

**When to Use:**
- Data are normally distributed (or approximately normal)
- Variances are equal (or use Welch's t-test for unequal variances)

**Implementation:**
```r
# Standard t-test (equal variances)
t.test(counts[group == "ALS"], counts[group == "Control"], alternative = "two.sided")

# Welch's t-test (unequal variances - default in R)
t.test(counts[group == "ALS"], counts[group == "Control"], var.equal = FALSE)
```

**Assumptions:**
- Independence of observations
- Normality (tested via Shapiro-Wilk/KS)
- Equal variances (tested via Levene's/Bartlett's)

#### 2. **Non-Parametric Tests: Wilcoxon Rank-Sum Test**

**When to Use:**
- Data are non-normal (violated normality assumption)
- Ordinal data or skewed distributions
- Small sample sizes with unknown distribution

**Implementation:**
```r
wilcox.test(counts[group == "ALS"], counts[group == "Control"], alternative = "two.sided")
```

**Advantages:**
- No distributional assumptions
- Robust to outliers
- Valid for small samples

**Disadvantages:**
- Less powerful than t-test when normality holds
- Tests medians, not means (can be interpreted differently)

#### 3. **Test Selection Strategy**

The pipeline uses a **dual approach**:

1. **Assumption-based selection** (if enabled):
   - Validates assumptions on representative SNV sample
   - Selects test based on assumption results
   - Applies recommendation to all SNVs

2. **Always calculate both tests** (default):
   - Calculates both t-test and Wilcoxon
   - Reports both p-values
   - Significance determined by either test (more conservative)

**Rationale:**
- Non-parametric tests are robust and valid regardless of distribution
- Reporting both provides transparency
- Allows readers to assess robustness

### Effect Size Metrics

**Fold Change:**
- Raw fold change: `FC = mean_ALS / mean_Control`
- Log2 fold change: `log2FC = log2(FC)`
- Interpretation:
  - `log2FC > 0`: Higher in ALS
  - `log2FC < 0`: Higher in Control
  - `|log2FC| > 1`: 2-fold change

**Additional Metrics (in Step 2.3):**
- **Cohen's d**: Standardized mean difference
  - Small: |d| < 0.2
  - Medium: 0.2 ≤ |d| < 0.5
  - Large: |d| ≥ 0.5

### Outputs

For each SNV, the pipeline reports:
- Group means and standard deviations
- Sample sizes per group
- Fold change and log2 fold change
- p-values (t-test and Wilcoxon)
- FDR-adjusted p-values
- Significance flags

---

## Multiple Testing Correction

### Purpose

When performing multiple hypothesis tests (one per SNV), we must correct for multiple comparisons to control the false discovery rate (FDR).

### Method: Benjamini-Hochberg (BH) Procedure

**Why BH?**
- Controls FDR (expected proportion of false positives)
- More powerful than Bonferroni (less conservative)
- Standard in genomics and high-throughput biology
- Valid under independence or positive dependence

**Implementation:**
```r
p.adjust(pvalues, method = "BH")
```

**Algorithm:**
1. Rank p-values: p(1) ≤ p(2) ≤ ... ≤ p(m)
2. For each p-value p(i), calculate adjusted p-value:
   - `p_adj(i) = min(1, p(i) × m / i)`
3. Apply threshold: p_adj < α (default: 0.05)

**Interpretation:**
- FDR < 0.05: Expected false positive rate < 5%
- More conservative than uncorrected p-values
- More powerful than Bonferroni correction

### Configuration

```yaml
analysis:
  alpha: 0.05  # Significance threshold
  fdr_method: "BH"  # FDR correction method
```

### Alternative Methods

**Available in R:**
- `"BH"`: Benjamini-Hochberg (default, recommended)
- `"bonferroni"`: Bonferroni (very conservative)
- `"fdr"`: Same as BH (alias)
- `"BY"`: Benjamini-Yekutieli (more conservative, valid under any dependence)

**Recommendation:** Use BH (default) unless strong dependence structure requires BY.

---

## Effect Size Estimation

### Purpose

Effect sizes quantify the magnitude of differences between groups, independent of sample size. They are essential for:
- Assessing biological significance (not just statistical)
- Power analysis for future studies
- Meta-analyses
- Clinical interpretation

### Methods

#### 1. **Cohen's d (Standardized Mean Difference)**

**Formula:**
```
d = (mean_ALS - mean_Control) / pooled_SD
```

**Pooled Standard Deviation:**
```
pooled_SD = sqrt(((n_ALS - 1) × SD_ALS² + (n_Control - 1) × SD_Control²) / (n_ALS + n_Control - 2))
```

**Interpretation:**
- **Small**: |d| < 0.2
- **Medium**: 0.2 ≤ |d| < 0.5
- **Large**: |d| ≥ 0.5

**When to Use:**
- Parametric data (normal distribution)
- Appropriate for t-test results

#### 2. **Hedges' g (Bias-Corrected Cohen's d)**

**Formula:**
```
g = d × correction_factor
correction_factor = 1 - (3 / (4 × (n_ALS + n_Control - 2) - 1))
```

**When to Use:**
- Small sample sizes (n < 20 per group)
- Provides unbiased estimate

#### 3. **Glass's Δ (Control Group SD)**

**Formula:**
```
Δ = (mean_ALS - mean_Control) / SD_Control
```

**When to Use:**
- Control group represents baseline/reference
- Useful when control variance is more stable

### Implementation

Effect sizes are calculated in Step 2.3 (`03_effect_size_analysis.R`).

---

## Quality Control and Validation

### Pre-Analysis Checks

1. **Data Integrity**
   - Check for missing values
   - Validate data types
   - Verify sample group assignments

2. **Statistical Assumptions**
   - Normality testing
   - Variance homogeneity
   - Diagnostic plots

3. **Batch Effects**
   - PCA visualization
   - Statistical testing
   - Confounding assessment

4. **Confounders**
   - Group balance assessment
   - Statistical testing
   - Recommendations

### Post-Analysis Validation

1. **Output Validation**
   - Check for expected output files
   - Validate data ranges (p-values: 0-1, log2FC: reasonable)
   - Verify FDR correction applied correctly

2. **Summary Statistics**
   - Number of significant SNVs
   - Distribution of effect sizes
   - Top significant findings

---

## Configuration Parameters

### Key Parameters in `config.yaml`

```yaml
analysis:
  # Significance threshold
  alpha: 0.05
  
  # FDR correction method
  fdr_method: "BH"
  
  # Assumptions validation
  assumptions:
    check_normality: true
    check_variance_homogeneity: true
    generate_diagnostic_plots: true
    auto_select_test: true
  
  # Batch effect correction
  batch_correction:
    method: "none"
    pvalue_threshold: 0.05
  
  # Confounder analysis
  confounders:
    adjust: true
    variables: ["age", "sex"]
```

### Recommendations for Different Scenarios

**Small Sample Sizes (n < 10 per group):**
- Use non-parametric tests (Wilcoxon)
- Use Hedges' g for effect size
- Consider permutation tests

**Large Sample Sizes (n > 30 per group):**
- Central Limit Theorem applies
- t-test is robust even with mild non-normality
- Cohen's d is appropriate

**Known Batch Effects:**
- Set `batch_correction.method: "combat"` (when implemented)
- Or use `limma::removeBatchEffect()`

**Imbalanced Groups:**
- Use adjusted models (ANCOVA, GLM)
- Report both unadjusted and adjusted results

---

## References

### Statistical Methods

1. **Normality Testing:**
   - Shapiro, S. S., & Wilk, M. B. (1965). An analysis of variance test for normality (complete samples). *Biometrika*, 52(3/4), 591-611.

2. **Variance Homogeneity:**
   - Levene, H. (1960). Robust tests for equality of variances. In *Contributions to Probability and Statistics* (pp. 278-292).

3. **Multiple Testing:**
   - Benjamini, Y., & Hochberg, Y. (1995). Controlling the false discovery rate: a practical and powerful approach to multiple testing. *Journal of the Royal Statistical Society*, 57(1), 289-300.

4. **Batch Effect Correction:**
   - Johnson, W. E., Li, C., & Rabinovic, A. (2007). Adjusting batch effects in microarray expression data using empirical Bayes methods. *Biostatistics*, 8(1), 118-127.

5. **Effect Sizes:**
   - Cohen, J. (1988). *Statistical Power Analysis for the Behavioral Sciences* (2nd ed.). Lawrence Erlbaum Associates.

### Best Practices

- **Statistical Analysis in Genomics:**
  - Gentleman, R., et al. (2005). *Bioinformatics and Computational Biology Solutions Using R and Bioconductor*. Springer.

- **Reproducible Research:**
  - Sandve, G. K., et al. (2013). Ten simple rules for reproducible computational research. *PLoS Computational Biology*, 9(10), e1003285.

---

## Appendix: Statistical Test Selection Flowchart

```
START
  ↓
Check Normality (Shapiro-Wilk/KS)
  ↓
  ├─ Normal? ──→ Check Variance Homogeneity
  │                ↓
  │                ├─ Equal Variances? ──→ t-test (equal variances)
  │                │
  │                └─ Unequal Variances? ──→ t-test (Welch's)
  │
  └─ Non-normal? ──→ Wilcoxon rank-sum test
  ↓
Apply FDR Correction (Benjamini-Hochberg)
  ↓
Report Results
```

---

**Document Maintained By:** Pipeline Development Team  
**For Questions or Issues:** See `README.md` for contact information

