# 🔬 Pipeline Overview: miRNA Oxidation Analysis

**Version:** 1.0.0  
**Last Updated:** 2025-01-21

---

## Scientific Background

This pipeline analyzes **8-oxoguanine (8-oxoG) damage** in microRNAs (miRNAs), which is a biomarker of oxidative stress. The primary signature of 8-oxoG damage is **G>T mutations**, which occur when guanine is oxidized and mispairs with adenine during reverse transcription.

### Key Scientific Concepts

- **8-oxoguanine**: Most common oxidative DNA/RNA lesion
- **G>T mutations**: Primary signature of 8-oxoG damage
- **Seed region**: Positions 2-8 in mature miRNAs, critical for target binding
- **VAF (Variant Allele Frequency)**: Proportion of reads containing the mutation
- **Oxidative stress**: Imbalance between reactive oxygen species and antioxidants

---

## Pipeline Architecture

### Workflow Overview

```
Raw Data (CSV)
    ↓
[Step 1] Exploratory Analysis
    ↓
[Step 1.5] VAF Quality Control (Filter VAF ≥ 0.5)
    ↓
[Step 2] Statistical Comparisons
    ├── Assumptions Validation
    ├── Batch Effect Analysis
    ├── Confounder Analysis
    ├── Group Comparisons
    └── Position-Specific Analysis (NEW)
    ↓
[Step 7] Clustering Analysis ⭐ REORDERED
    └── Discover groups of miRNAs with similar oxidation patterns
    ↓
[Step 5] Family Analysis ⭐ REORDERED
    ├── Family Identification
    └── Compare clusters with biological families
    ↓
[Step 6] Expression Correlation ⭐ REORDERED
    └── Expression vs Oxidation relationships
    ↓
[Step 3] Functional Analysis ⭐ REORDERED
    ├── Target Prediction (with cluster/family context)
    ├── Pathway Enrichment
    └── Disease-Relevant Genes
    ↓
[Step 4] Biomarker Analysis ⭐ REORDERED (LAST)
    ├── ROC Curves (integrates all insights)
    └── Diagnostic Signatures
```

**Note:** Steps have been reordered for logical flow:
- **Structure discovery first** (Step 7: Clustering, Step 5: Families)
- **Relationship analysis** (Step 6: Expression)
- **Functional interpretation** (Step 3: Functional)
- **Biomarker integration** (Step 4: Biomarkers - integrates all)

---

## Step-by-Step Description

### Step 1: Exploratory Analysis

**Purpose:** Characterize the dataset and understand basic patterns.

**What it does:**
- Counts G>T mutations by position
- Analyzes mutation spectrum (G>T, G>A, G>C, etc.)
- Calculates positional fractions
- Examines G-content distribution
- Compares seed vs non-seed regions
- Analyzes G>T specificity

**Outputs:**
- 6 figures: Dataset evolution, mutation spectra, positional patterns
- 6 tables: Summary statistics

**Key metrics:**
- Total G>T mutations
- G>T distribution across positions
- Seed region enrichment

---

### Step 1.5: VAF Quality Control

**Purpose:** Remove technical artifacts and ensure data quality.

**What it does:**
- Calculates VAF for all mutations
- Filters artifacts: VAF ≥ 0.5 (technical artifacts)
- Generates diagnostic visualizations
- Reports filter impact

**Critical filter:**
- **VAF ≥ 0.5 → Filtered** (artifacts)
- **VAF < 0.5 → Kept** (biological signal)

**Why important:**
- VAF = 0.5 often indicates sequencing errors or technical artifacts
- Removing these improves signal-to-noise ratio

**Outputs:**
- 11 diagnostic figures
- 7 tables (filtered data + reports)

---

### Step 2: Statistical Comparisons

**Purpose:** Compare groups statistically and identify significant differences.

**What it does:**

1. **Assumptions Validation:**
   - Normality tests (Shapiro-Wilk, Kolmogorov-Smirnov)
   - Variance homogeneity tests (Levene's, Bartlett's)
   - Automatic test selection (parametric vs non-parametric)

2. **Batch Effect Analysis:**
   - PCA visualization
   - Statistical testing for batch effects
   - Batch correction (if enabled)

3. **Confounder Analysis:**
   - Group balance assessment (age, sex)
   - Covariate analysis

4. **Group Comparisons:**
   - t-test (parametric)
   - Wilcoxon rank-sum test (non-parametric)
   - FDR correction (Benjamini-Hochberg)
   - Effect size calculation (Cohen's d)

5. **Position-Specific Analysis (NEW):**
   - Analyzes each position individually (1-24)
   - Statistical testing per position
   - Generates position-specific bar chart

**Filters applied:**
- G>T mutations only
- Statistical significance: `FDR < alpha` (default: 0.05)
- Log2FC threshold: `log2_fold_change > threshold` (default: 0.58)

**Outputs:**
- 4 figures: Volcano plot, effect size distribution, position-specific distribution, batch effect PCA
- Statistical results tables

---

### Step 3: Functional Analysis

**Purpose:** Understand biological impact of oxidized miRNAs.

**What it does:**

1. **Target Prediction:**
   - Predicts mRNA targets for oxidized miRNAs
   - Uses seed region sequences (positions 2-8)
   - Calculates binding scores

2. **Pathway Enrichment:**
   - GO term enrichment (Biological Process, Molecular Function, Cellular Component)
   - KEGG pathway enrichment
   - Disease-relevant pathway identification

3. **Disease-Relevant Genes:**
   - Identifies targets that are ALS-relevant genes
   - Calculates impact scores

**Filters applied:**
- Significant G>T mutations only
- Seed region only (positions 2-8)
- Log2FC threshold: `log2_fold_change > 1.0`

**Outputs:**
- 5 figures: Pathway enrichment, target comparison, position impact
- 6 tables: Target analysis, GO enrichment, KEGG enrichment

---

### Step 4: Biomarker Analysis

**Purpose:** Evaluate diagnostic potential of oxidized miRNAs.

**What it does:**
- ROC curve analysis for individual miRNAs
- AUC calculation
- Multi-miRNA signature identification
- Sensitivity and specificity calculation

**Filters applied:**
- Significant G>T mutations in seed region
- Top 50 by log2FC (for ROC analysis)

**Outputs:**
- 2 figures: ROC curves, biomarker signature heatmap
- 2 tables: ROC results, biomarker signatures

**Key metrics:**
- AUC (Area Under Curve): >0.7 = good, >0.8 = excellent
- Sensitivity: True positive rate
- Specificity: True negative rate

---

### Step 5: miRNA Family Analysis

**Purpose:** Identify family-level oxidation patterns.

**What it does:**
- Groups miRNAs by family (let-7, miR-1, etc.)
- Calculates family-level oxidation metrics
- Compares families between groups

**Filters applied:**
- Significant G>T mutations in seed region

**Outputs:**
- 2 figures: Family comparison bar chart, family heatmap
- 2 tables: Family summary, family comparison

**Key insights:**
- Which families are most affected
- Family-level conservation patterns

---

### Step 6: Expression-Oxidation Correlation

**Purpose:** Examine relationship between miRNA expression and oxidation.

**What it does:**
- Calculates correlation between RPM (Reads Per Million) and G>T VAF
- Groups miRNAs by expression level
- Analyzes expression category effects

**Filters applied:**
- Significant G>T mutations in seed region
- Expression data available

**Outputs:**
- 2 figures: Expression vs oxidation scatter, expression group comparison
- 2 tables: Correlation results, expression summary

**Key question:**
- Are highly expressed miRNAs more or less oxidized?

---

### Step 7: Clustering Analysis

**Purpose:** Identify groups of miRNAs with similar oxidation patterns.

**What it does:**
- Hierarchical clustering of miRNAs
- Identifies clusters (k=6)
- Characterizes cluster patterns

**Filters applied:**
- Significant G>T mutations in seed region

**Outputs:**
- 2 figures: Cluster heatmap, dendrogram
- 2 tables: Cluster assignments, cluster summary

**Key insights:**
- Which miRNAs co-oxidize
- Functional relationships between clusters

---

## Data Flow

### Input → Output

```
Raw CSV (miRNA counts)
    ↓
Step 1.5: VAF Filtering
    ↓
Filtered CSV (VAF < 0.5)
    ↓
Step 2: Statistical Comparisons
    ↓
Statistical Results CSV
    ↓
Steps 3-7: Downstream Analysis
    ↓
Functional/Biomarker/Family/Clustering Results
```

### Filter Progression

1. **All mutations** → Step 1
2. **VAF < 0.5** → Step 1.5
3. **G>T only** → Step 2
4. **Significant + Log2FC** → Step 2 results
5. **Seed region (2-8)** → Steps 3-7

---

## Key Concepts

### VAF (Variant Allele Frequency)

```
VAF = (Count of mutated reads) / (Total reads)
```

- **VAF = 0.5**: Often technical artifact (filtered)
- **VAF < 0.5**: Biological signal (kept)
- **VAF = 0.01**: Low-level mutation (1% of reads)

### Seed Region

Positions **2-8** in mature miRNAs:
- Critical for target binding
- Mutations here have functional impact
- Higher G-content → more susceptible to oxidation

### Statistical Significance

- **p-value**: Raw statistical significance
- **FDR (False Discovery Rate)**: Multiple testing correction
- **Log2FC**: Fold change (log2 scale)
  - Log2FC > 0: Higher in group 1
  - Log2FC < 0: Higher in group 2
  - Log2FC > 0.58: ~1.5x fold change

---

## Adaptive Thresholds

The pipeline includes adaptive threshold detection:

- **<5 significant mutations** → Warning: "Low signal detected"
- **>90% data filtered** → Warning: "Excessive filtering"
- **Max AUC < 0.6** → Warning: "Poor biomarker performance"
- **|correlation| < 0.2** → Warning: "Weak correlation"

These warnings help identify when the dataset may not have sufficient signal.

---

## Output Interpretation

### Statistical Results

**S2_statistical_comparisons.csv:**
- `significant = TRUE`: Mutation is significantly different between groups
- `log2_fold_change > 0`: Higher in group 1 (e.g., Disease)
- `log2_fold_change < 0`: Higher in group 2 (e.g., Control)

### Position-Specific Results

**S2_position_specific_statistics.csv:**
- Shows which positions (1-24) have significant differences
- **Position 2-8**: Seed region (functionally important)
- **Position 21-22**: Often high mutation rates (less functional impact)

### Biomarker Results

**S4_roc_analysis.csv:**
- **AUC > 0.8**: Excellent biomarker
- **AUC 0.7-0.8**: Good biomarker
- **AUC < 0.6**: Poor biomarker (may not be useful)

---

## Best Practices

1. **Always check Step 1.5 outputs** to verify data quality
2. **Review Step 2 position-specific analysis** to identify key positions
3. **Use metadata file** for reliable group assignment
4. **Check adaptive threshold warnings** to assess data quality
5. **Review functional analysis** in context of disease biology

---

**Last Updated:** 2025-01-21  
**Document Version:** 1.0.0

