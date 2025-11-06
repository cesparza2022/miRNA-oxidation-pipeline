# 🔄 Pipeline Execution Order

## Overview

This document explains the logical execution order of the miRNA oxidation analysis pipeline, which differs from the numeric step order due to dependencies and parallel execution opportunities.

## Execution Flow

```
┌─────────┐
│ Step 1  │  Exploratory Analysis (data characterization)
└────┬────┘
     │
     ▼
┌─────────┐
│Step 1.5 │  VAF Quality Control (filter technical artifacts)
└────┬────┘
     │
     ▼
┌─────────┐
│ Step 2  │  Statistical Comparisons (ALS vs Control)
└────┬────┘
     │
     ▼
┌─────────┐
│ Step 7  │  Clustering Analysis (Structure Discovery - FIRST)
│ Clustering│
└────┬────┘
     │
     ├───────────────────────────────────┐
     │                                   │
     ▼                                   ▼
┌─────────┐                         ┌─────────┐
│ Step 5  │                         │ Step 6  │
│ Families│                         │Expression│
└────┬────┘                         └─────────┘
     │                                   │
     │                                   ▼
     │                              ┌─────────┐
     │                              │ Step 3  │
     │                              │Functional│
     │                              └─────────┘
     │                                   │
     └───────────────────────────────────┘
                     │
                     ▼
              ┌─────────┐
              │ Step 4  │  Biomarker Analysis (integrates all)
              └─────────┘
```

## Detailed Step Dependencies

### Sequential Steps (Must run in order)

1. **Step 1**: Exploratory Analysis
   - **Input**: `processed_clean` data
   - **Output**: Exploratory figures and tables
   - **Purpose**: Characterize the dataset (mutations by position, G>T patterns, etc.)

2. **Step 1.5**: VAF Quality Control
   - **Input**: `step1_original` data (with SNV and total counts)
   - **Dependencies**: None (can run in parallel with Step 1)
   - **Output**: VAF-filtered data, diagnostic figures
   - **Purpose**: Filter technical artifacts (VAF ≥ 0.5)

3. **Step 2**: Statistical Comparisons
   - **Input**: Step 1.5 filtered data
   - **Dependencies**: Step 1.5 (must complete)
   - **Output**: Statistical comparisons, volcano plots, effect sizes
   - **Purpose**: Identify significant differences between ALS and Control

### Structure Discovery Step (Runs First After Step 2)

4. **Step 7**: Clustering Analysis
   - **Input**: Step 2 statistical comparisons
   - **Dependencies**: Step 2
   - **Output**: Cluster assignments, dendrograms
   - **Purpose**: Discover groups with similar mutation patterns (data-driven structure)
   - **Why First**: Provides clustering context for subsequent analyses

### Parallel Steps (Can run simultaneously after Step 7)

5. **Step 5**: miRNA Family Analysis
   - **Input**: Step 2 statistical comparisons, Step 7 clustering results
   - **Dependencies**: Step 2, Step 7
   - **Output**: Family-level comparisons
   - **Purpose**: Compare data-driven clusters (from Step 7) with biological families

6. **Step 6**: Expression vs Oxidation Correlation
   - **Input**: Step 2 statistical comparisons, Step 7 clustering results
   - **Dependencies**: Step 2, Step 7
   - **Output**: Correlation analysis
   - **Purpose**: Examine relationship between expression and oxidation (can use clustering context)

7. **Step 3**: Functional Analysis
   - **Input**: Step 2 statistical comparisons, Step 7 clustering results
   - **Dependencies**: Step 2, Step 7
   - **Output**: Target analysis, pathway enrichment
   - **Purpose**: Understand functional implications with clustering context

### Final Integration Step

8. **Step 4**: Biomarker Analysis
   - **Input**: Step 3 functional analysis
   - **Dependencies**: Step 3 (requires functional context)
   - **Output**: ROC curves, biomarker signatures
   - **Purpose**: Integrate all analyses to identify biomarkers

## Why This Order?

### Logical Flow

1. **Discovery First** (Steps 1-2): Understand the data and identify significant differences
2. **Structure Discovery** (Step 7): Discover data-driven clusters FIRST
3. **Biological Context** (Steps 5, 6): Compare clusters with families and expression (parallel)
4. **Functional Interpretation** (Step 3): Understand biological meaning with clustering context
5. **Integration** (Step 4): Combine all insights for biomarker identification

### Why Step 7 Runs First, Then Steps 5, 6, 3 Run in Parallel

- **Step 7** (Clustering): Runs FIRST after Step 2 to discover data structure
- **Step 5** (Families): Runs after Step 7, compares data-driven clusters with biological families
- **Step 6** (Expression): Runs after Step 7, can use clustering context for expression analysis
- **Step 3** (Functional): Runs after Step 7, uses clustering context for functional interpretation

Step 7 must complete first, then Steps 5, 6, 3 can run simultaneously, saving execution time.

### Why Step 4 Comes Last

Step 4 (Biomarker Analysis) integrates:
- Functional targets from Step 3
- Statistical significance from Step 2
- All previous insights

It needs the complete context to identify meaningful biomarkers.

## Execution Strategy

### Snakemake Dependency Graph

Snakemake automatically resolves dependencies:

```python
# Explicit dependencies in rules:
all_step2:
    input: rules.all_step1_5.output  # Step 2 depends on Step 1.5

all_step7:
    input: rules.all_step2.output    # Step 7 depends on Step 2 (runs FIRST)

all_step5:
    input: rules.all_step2.output,   # Step 5 depends on Step 2
           rules.all_step7.output    # and Step 7 (clustering)

all_step6:
    input: rules.all_step2.output,   # Step 6 depends on Step 2
           rules.all_step7.output    # and Step 7 (clustering)

all_step3:
    input: rules.all_step2.output,   # Step 3 depends on Step 2
           rules.all_step7.output    # and Step 7 (clustering)

all_step4:
    input: rules.all_step3.output    # Step 4 depends on Step 3
```

### Running the Pipeline

**Full pipeline:**
```bash
snakemake -j 4  # Run all steps with 4 parallel jobs
```

**Specific step:**
```bash
snakemake -j 4 all_step2  # Run only Step 2 (and dependencies)
```

**Dry run:**
```bash
snakemake -n  # See what would run without executing
```

## Performance Considerations

- **Steps 1, 1.5**: Can run in parallel (independent inputs)
- **Step 7**: Runs FIRST after Step 2 (must complete before 5, 6, 3)
- **Steps 5, 6, 3**: Can run in parallel after Step 7 completes
- **Total parallel execution time**: ~Step1 + Step1.5 + Step2 + Step7 + max(Step5, Step6, Step3) + Step4

## Summary

The pipeline follows a logical discovery → interpretation → integration flow rather than strict numeric order. This design:
- ✅ Maximizes parallel execution opportunities
- ✅ Ensures dependencies are satisfied
- ✅ Follows scientific reasoning (data → patterns → function → biomarkers)
- ✅ Is enforced by Snakemake's dependency resolution

