# 🔄 Pipeline Reordering Proposal

## Current Order (Problematic)

```
Step 1: Exploratory Analysis
Step 1.5: VAF Filtering
Step 2: Statistical Comparisons
Step 3: Functional Analysis
Step 4: Biomarker Analysis
Step 5: Family Analysis
Step 6: Expression Correlation
Step 7: Clustering Analysis  ← Should come earlier!
```

## Problems with Current Order

### 1. **Clustering (Step 7) comes too late**
- **Issue**: Clustering discovers groups of miRNAs with similar oxidation patterns
- **Problem**: These patterns should inform downstream analyses (functional, family)
- **Impact**: Miss opportunity to analyze functional implications of clusters
- **Current**: Clustering is done last, after all other analyses

### 2. **Family Analysis (Step 5) after Biomarker (Step 4)**
- **Issue**: Both are independent analyses, but family analysis could benefit from clustering
- **Problem**: No logical dependency between biomarker and family analysis
- **Impact**: Family analysis could be more informative if done after clustering

### 3. **Functional Analysis (Step 3) before Clustering**
- **Issue**: Functional analysis is done on individual miRNAs
- **Problem**: Could be more powerful if done on clusters or families
- **Impact**: Miss opportunity to analyze functional implications of co-oxidized miRNAs

## Proposed Logical Order

```
Step 1: Exploratory Analysis
  ↓ (characterize dataset)
Step 1.5: VAF Filtering
  ↓ (quality control)
Step 2: Statistical Comparisons
  ↓ (identify significant miRNAs)
Step 7: Clustering Analysis  ← MOVED EARLIER
  ↓ (discover groups with similar patterns)
Step 5: Family Analysis  ← MOVED EARLIER
  ↓ (see if clusters match biological families)
Step 6: Expression Correlation  ← MOVED EARLIER
  ↓ (understand expression-oxidation relationship)
Step 3: Functional Analysis  ← MOVED LATER
  ↓ (functional analysis of clusters/families/miRNAs)
Step 4: Biomarker Analysis  ← MOVED LAST
  ↓ (biomarkers based on all previous insights)
```

## New Order Rationale

### Step 1 → Step 1.5 → Step 2 (Same)
- Exploratory → Quality Control → Statistical Significance
- **No change needed**

### Step 7: Clustering (NEW POSITION 4)
- **Why here?**
  - Discovers groups of miRNAs that co-oxidize
  - Patterns can inform downstream analyses
  - Exploratory step that reveals structure in data
  
- **Outputs inform:**
  - Family Analysis (do clusters match families?)
  - Functional Analysis (functional implications of clusters)
  - Biomarker Analysis (cluster-based biomarkers)

### Step 5: Family Analysis (NEW POSITION 5)
- **Why here?**
  - After clustering, can check if clusters match biological families
  - Can identify family-level patterns that complement clustering
  - Natural grouping based on seed sequence similarity
  
- **Outputs inform:**
  - Functional Analysis (family-level functional implications)
  - Biomarker Analysis (family-based biomarkers)

### Step 6: Expression Correlation (NEW POSITION 6)
- **Why here?**
  - After understanding structure (clusters, families), can examine expression
  - Can correlate expression with oxidation patterns
  - Can identify if highly expressed miRNAs are more/less oxidized
  
- **Outputs inform:**
  - Functional Analysis (expression affects function)
  - Biomarker Analysis (expression-based biomarkers)

### Step 3: Functional Analysis (NEW POSITION 7)
- **Why here?**
  - Now has context from clusters, families, expression
  - Can analyze functional implications of:
    - Individual significant miRNAs
    - Clusters of co-oxidized miRNAs
    - Family-level patterns
  - More informed functional analysis
  
- **Outputs inform:**
  - Biomarker Analysis (functionally relevant biomarkers)

### Step 4: Biomarker Analysis (NEW POSITION 8 - LAST)
- **Why last?**
  - Integrates all previous insights:
    - Statistical significance (Step 2)
    - Clustering patterns (Step 7)
    - Family patterns (Step 5)
    - Expression relationships (Step 6)
    - Functional relevance (Step 3)
  - Can build biomarkers based on comprehensive understanding

## Implementation Plan

### 1. Rename Steps (Logical numbering)
- Step 7 → Step 4 (Clustering)
- Step 5 → Step 5 (Family) - stays same
- Step 6 → Step 6 (Expression) - stays same
- Step 3 → Step 7 (Functional)
- Step 4 → Step 8 (Biomarker)

OR keep original numbers but change order in Snakefile

### 2. Update Dependencies
- Check if Step 3 (Functional) needs Step 7 (Clustering) output
- Check if Step 4 (Biomarker) needs Step 7 (Clustering) output
- Update Snakefile to reflect new order

### 3. Update Documentation
- Update PIPELINE_OVERVIEW.md
- Update USER_GUIDE.md
- Update all step descriptions

## Benefits of New Order

1. **Clustering informs downstream analyses**
   - Functional analysis can consider clusters
   - Family analysis can compare with clusters
   - Biomarker analysis can use cluster information

2. **Progressive understanding**
   - Start with individual miRNAs (Step 2)
   - Discover groups (Step 7)
   - Understand biological families (Step 5)
   - Understand expression relationships (Step 6)
   - Analyze functional implications (Step 3)
   - Build biomarkers (Step 4)

3. **More logical flow**
   - Exploratory → Descriptive → Explanatory → Predictive
   - Structure discovery before functional interpretation

## Questions to Consider

1. **Do Step 3 (Functional) or Step 4 (Biomarker) currently use clustering results?**
   - If not, should they?
   - Could they benefit from cluster information?

2. **Should we keep original step numbers or rename?**
   - Keep numbers: Easier transition, but confusing
   - Rename: Clearer, but requires more updates

3. **Are there any technical dependencies that prevent reordering?**
   - Check if scripts read outputs from wrong step numbers
   - Check if paths reference specific step numbers

