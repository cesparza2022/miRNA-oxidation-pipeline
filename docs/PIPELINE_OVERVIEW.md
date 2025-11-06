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
<<<<<<< HEAD:final_analysis/pipeline_definitivo/snakemake_pipeline/docs/PIPELINE_OVERVIEW.md
[Step 7] Clustering Analysis (FIRST - Structure Discovery)
    └── Discover groups of miRNAs with similar oxidation patterns
    ↓
[Step 5] Family Analysis (parallel with 6, 3)
    ├── Family Identification
    └── Compare data-driven clusters (from Step 7) with biological families
    ↓
[Step 6] Expression Correlation (parallel with 5, 3)
    └── Expression vs Oxidation relationships (can use clustering context)
    ↓
[Step 3] Functional Analysis (parallel with 5, 6)
    ├── Target Prediction (with clustering context from Step 7)
    ├── Pathway Enrichment
    └── Disease-Relevant Genes
    ↓
[Step 4] Biomarker Analysis (LAST)
=======
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
>>>>>>> 352eb6950c566304a08c8054f00dc95591ac07de:docs/PIPELINE_OVERVIEW.md
    ├── ROC Curves (integrates all insights)
    └── Diagnostic Signatures
```

<<<<<<< HEAD:final_analysis/pipeline_definitivo/snakemake_pipeline/docs/PIPELINE_OVERVIEW.md
**Note:** Execution order follows logical flow:
- **Step 7** runs FIRST after Step 2 (discovers structure before interpretation)
- **Steps 5, 6, 3** run in parallel after Step 7 (use clustering context)
- **Step 4** runs last (integrates all insights for biomarkers)
=======
**Note:** Steps have been reordered for logical flow:
- **Structure discovery first** (Step 7: Clustering, Step 5: Families)
- **Relationship analysis** (Step 6: Expression)
- **Functional interpretation** (Step 3: Functional)
- **Biomarker integration** (Step 4: Biomarkers - integrates all)
>>>>>>> 352eb6950c566304a08c8054f00dc95591ac07de:docs/PIPELINE_OVERVIEW.md

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

<<<<<<< HEAD:final_analysis/pipeline_definitivo/snakemake_pipeline/docs/PIPELINE_OVERVIEW.md
### Step 7: Clustering Analysis (Structure Discovery - Runs FIRST)
=======
### Step 7: Clustering Analysis ⭐ REORDERED (Now Step 4 in execution)
>>>>>>> 352eb6950c566304a08c8054f00dc95591ac07de:docs/PIPELINE_OVERVIEW.md

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
- Groups of miRNAs with similar oxidation patterns
<<<<<<< HEAD:final_analysis/pipeline_definitivo/snakemake_pipeline/docs/PIPELINE_OVERVIEW.md
- **Provides structure for downstream analyses** (family, expression, functional)

**Why this order?** Clustering runs FIRST to discover data-driven structure before biological interpretation. Steps 5, 6, and 3 use clustering results to inform their analyses.

---

### Step 5: miRNA Family Analysis

**Purpose:** Identify family-level oxidation patterns and compare data-driven clusters with biological families.
=======
- **Informs downstream analyses** (family, functional, biomarker)

**Why this order?** Clustering discovers structure in the data, which informs family analysis, functional interpretation, and biomarker development.

---

### Step 5: miRNA Family Analysis ⭐ REORDERED (Now Step 5 in execution)

**Purpose:** Identify family-level oxidation patterns and compare with clusters.
>>>>>>> 352eb6950c566304a08c8054f00dc95591ac07de:docs/PIPELINE_OVERVIEW.md

**What it does:**
- Groups miRNAs by family (let-7, miR-1, etc.)
- Calculates family-level oxidation metrics
- Compares families between groups
<<<<<<< HEAD:final_analysis/pipeline_definitivo/snakemake_pipeline/docs/PIPELINE_OVERVIEW.md
- **Compares data-driven clusters (from Step 7) with biological families**
=======
- **Can compare clusters (from Step 7) with biological families**
>>>>>>> 352eb6950c566304a08c8054f00dc95591ac07de:docs/PIPELINE_OVERVIEW.md

**Filters applied:**
- Significant G>T mutations in seed region

**Outputs:**
- 2 figures: Family comparison bar chart, family heatmap
- 2 tables: Family summary, family comparison

**Key insights:**
- Which families are most affected
- Family-level conservation patterns
<<<<<<< HEAD:final_analysis/pipeline_definitivo/snakemake_pipeline/docs/PIPELINE_OVERVIEW.md
- Do data-driven clusters (Step 7) match biological families?

**Why this order?** Runs after Step 7 (clustering) to compare data-driven structure with known biological families. Runs in parallel with Steps 6 and 3.

---

### Step 6: Expression-Oxidation Correlation
=======
- Do clusters match biological families?

**Why this order?** After discovering clusters, we can check if they align with known biological families.

---

### Step 6: Expression-Oxidation Correlation ⭐ REORDERED (Now Step 6 in execution)
>>>>>>> 352eb6950c566304a08c8054f00dc95591ac07de:docs/PIPELINE_OVERVIEW.md

**Purpose:** Examine relationship between miRNA expression and oxidation.

**What it does:**
- Calculates correlation between RPM (Reads Per Million) and G>T VAF
- Groups miRNAs by expression level
- Analyzes expression category effects
<<<<<<< HEAD:final_analysis/pipeline_definitivo/snakemake_pipeline/docs/PIPELINE_OVERVIEW.md
- Can use clustering context from Step 7
=======
>>>>>>> 352eb6950c566304a08c8054f00dc95591ac07de:docs/PIPELINE_OVERVIEW.md

**Filters applied:**
- Significant G>T mutations in seed region
- Expression data available

**Outputs:**
- 2 figures: Expression vs oxidation scatter, expression group comparison
- 2 tables: Correlation results, expression summary

**Key question:**
- Are highly expressed miRNAs more or less oxidized?
<<<<<<< HEAD:final_analysis/pipeline_definitivo/snakemake_pipeline/docs/PIPELINE_OVERVIEW.md
- Do expression patterns correlate with clustering structure?

**Why this order?** Runs after Step 7 (clustering) to examine expression relationships with clustering context. Runs in parallel with Steps 5 and 3.

---

### Step 3: Functional Analysis

**Purpose:** Understand biological impact of oxidized miRNAs with clustering context from Step 7.
=======

**Why this order?** After understanding structure (clusters, families), we examine expression relationships.

---

### Step 3: Functional Analysis ⭐ REORDERED (Now Step 7 in execution)

**Purpose:** Understand biological impact of oxidized miRNAs (with context from clustering/families).
>>>>>>> 352eb6950c566304a08c8054f00dc95591ac07de:docs/PIPELINE_OVERVIEW.md

**What it does:**

1. **Target Prediction:**
   - Predicts mRNA targets for oxidized miRNAs
   - Uses seed region sequences (positions 2-8)
   - Calculates binding scores
<<<<<<< HEAD:final_analysis/pipeline_definitivo/snakemake_pipeline/docs/PIPELINE_OVERVIEW.md
   - **Uses clustering context from Step 7 to analyze co-oxidized groups**
=======
   - **Can analyze functional implications of clusters and families**
>>>>>>> 352eb6950c566304a08c8054f00dc95591ac07de:docs/PIPELINE_OVERVIEW.md

2. **Pathway Enrichment:**
   - GO term enrichment (Biological Process, Molecular Function, Cellular Component)
   - KEGG pathway enrichment
   - Disease-relevant pathway identification
<<<<<<< HEAD:final_analysis/pipeline_definitivo/snakemake_pipeline/docs/PIPELINE_OVERVIEW.md
   - **Can analyze pathway enrichment by cluster (from Step 7)**

3. **Disease-Relevant Genes:**
   - Identifies targets that are disease-relevant genes
   - Calculates impact scores
   - **Can analyze functional impact by cluster (from Step 7)**
=======

3. **Disease-Relevant Genes:**
   - Identifies targets that are ALS-relevant genes
   - Calculates impact scores
>>>>>>> 352eb6950c566304a08c8054f00dc95591ac07de:docs/PIPELINE_OVERVIEW.md

**Filters applied:**
- Significant G>T mutations only
- Seed region only (positions 2-8)
- Log2FC threshold: `log2_fold_change > 1.0`

**Outputs:**
- 5 figures: Pathway enrichment, target comparison, position impact
- 6 tables: Target analysis, GO enrichment, KEGG enrichment

**Key insights:**
- Which pathways are affected
<<<<<<< HEAD:final_analysis/pipeline_definitivo/snakemake_pipeline/docs/PIPELINE_OVERVIEW.md
- Which disease-relevant genes are targeted
- Functional impact of oxidation
- Functional implications of co-oxidized clusters (from Step 7)

**Why this order?** Runs after Step 7 (clustering) to use clustering context for functional interpretation. Runs in parallel with Steps 5 and 6.

---

### Step 4: Biomarker Analysis
=======
- Which ALS-relevant genes are targeted
- Functional impact of oxidation
- Functional implications of co-oxidized clusters

**Why this order?** Functional analysis benefits from context: knowing which miRNAs co-oxidize (clusters) and which families are affected helps interpret functional significance.

---

### Step 4: Biomarker Analysis ⭐ REORDERED (Now Step 8 - LAST in execution)
>>>>>>> 352eb6950c566304a08c8054f00dc95591ac07de:docs/PIPELINE_OVERVIEW.md

**Purpose:** Evaluate diagnostic potential of oxidized miRNAs (integrating all previous insights).

**What it does:**
- ROC curve analysis for individual miRNAs
- AUC calculation
- Multi-miRNA signature identification
- Sensitivity and specificity calculation
- **Can incorporate cluster, family, expression, and functional information**

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

**Why this order?** Biomarker analysis integrates all insights: statistical significance, clustering patterns, family relationships, expression correlations, and functional relevance.

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

### Analysis Flow Logic

**Discovery → Description → Interpretation → Integration**

1. **Step 1-2**: Exploratory and statistical identification
<<<<<<< HEAD:final_analysis/pipeline_definitivo/snakemake_pipeline/docs/PIPELINE_OVERVIEW.md
2. **Step 7**: Structure discovery (clustering) - RUNS FIRST
3. **Steps 5, 6, 3**: Run in parallel after Step 7:
   - **Step 5**: Biological grouping (families) - compares clusters with families
   - **Step 6**: Relationship analysis (expression) - can use clustering context
   - **Step 3**: Functional interpretation - uses clustering context
4. **Step 4**: Biomarker integration (all insights) - LAST
=======
2. **Step 7**: Structure discovery (clustering) ⭐ REORDERED
3. **Step 5**: Biological grouping (families) ⭐ REORDERED
4. **Step 6**: Relationship analysis (expression) ⭐ REORDERED
5. **Step 3**: Functional interpretation (with context) ⭐ REORDERED
6. **Step 4**: Biomarker integration (all insights) ⭐ REORDERED - LAST
>>>>>>> 352eb6950c566304a08c8054f00dc95591ac07de:docs/PIPELINE_OVERVIEW.md

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

