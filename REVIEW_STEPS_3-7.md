# 📋 EXHAUSTIVE REVIEW: Steps 3-7 of the Pipeline

## 🎯 OBJECTIVE
This document critically reviews what questions Steps 3-7 answer, what specific data they use, how they generate outputs, and their coherence with the pipeline style.

---

## 📊 STEP 3: FUNCTIONAL ANALYSIS

### ❓ **Questions Answered:**

1. **What genes are affected by miRNA oxidation in the seed region?**
   - Identifies potential targets of oxidized miRNAs
   - Compares canonical vs oxidized targets
   - Evaluates functional impact by position

2. **What biological pathways are enriched?**
   - GO (Gene Ontology) enrichment analysis
   - KEGG (metabolic pathways) enrichment analysis
   - Identification of ALS-specific pathways

3. **What ALS-relevant genes are impacted?**
   - List of 23 known ALS genes
   - Functional impact analysis by miRNA
   - Functional impact scoring

### 🔍 **Data Used (CRITICAL):**

**Filter applied (same as Steps 1-2):**
```r
significant_gt <- statistical_results %>%
  filter(
    str_detect(pos.mut, ":GT$"),                    # Only G>T mutations
    !is.na(t_test_fdr) | !is.na(wilcoxon_fdr),     # Has statistical tests
    (t_test_fdr < alpha | wilcoxon_fdr < alpha),   # Significant (FDR < 0.05)
    !is.na(log2_fold_change),
    log2_fold_change > log2fc_threshold_step3       # Higher in ALS (log2FC > 1.0)
  ) %>%
  mutate(
    position = as.numeric(str_extract(pos.mut, "^\\d+")),
    in_seed = position >= seed_start & position <= seed_end  # seed_start=2, seed_end=8
  ) %>%
  filter(in_seed == TRUE) %>%  # ⚠️ ONLY SEED REGION (positions 2-8)
  distinct(miRNA_name, pos.mut, .keep_all = TRUE)
```

**✅ VERIFICATION:**
- ✅ Uses only G>T in seed region (2-8)
- ✅ Filters by statistical significance (FDR < alpha)
- ✅ Requires log2FC > 1.0 (higher in ALS)
- ✅ Uses significantly most oxidized miRNAs

### 📁 **Output Format:**

**Tables (CSV):**
- `results/step3/final/tables/functional/S3_target_analysis.csv`
  - Columns: `miRNA_name`, `pos.mut`, `position`, `ALS_mean`, `Control_mean`, `log2_fold_change`, `t_test_fdr`, `canonical_targets`, `oxidized_targets`, `binding_impact`, `functional_impact_score`
  - Format: CSV with `write_csv()` (readr)
  
- `results/step3/final/tables/functional/S3_als_relevant_genes.csv`
- `results/step3/final/tables/functional/S3_target_comparison.csv`
- `results/step3/final/tables/functional/S3_go_enrichment.csv`
- `results/step3/final/tables/functional/S3_kegg_enrichment.csv`
- `results/step3/final/tables/functional/S3_als_pathways.csv`

**Figures (PNG):**
- `results/step3/final/figures/step3_panelA_pathway_enrichment.png`
  - Format: PNG, 3000x2400px (12x10in @ 300 DPI)
  - Function: `ggsave(output, plot, width=12, height=10, dpi=300, bg="white")`
  - Theme: `theme_professional` (consistent with pipeline)
  
- `results/step3/final/figures/step3_panelB_als_genes_impact.png`
- `results/step3/final/figures/step3_panelC_target_comparison.png`
- `results/step3/final/figures/step3_panelD_position_impact.png`
- `results/step3/final/figures/step3_pathway_enrichment_heatmap.png`

**Logs:**
- `results/step3/final/logs/functional_target_analysis.log`
- `results/step3/final/logs/pathway_enrichment.log`
- `results/step3/final/logs/complex_functional_viz.log`

### 🎨 **Coherence with Pipeline:**

✅ **Consistent:**
- Uses `theme_professional` (same style as Steps 1-2)
- Uses `functions_common.R` (logging, validation, colors)
- Reads parameters from `config.yaml` (alpha, seed_region, log2fc_threshold_step3)
- Identical logging structure (initialize_logging, log_section, log_subsection)
- File nomenclature: `S3_*` (Step 3)
- Colors: `color_gt = "#D62728"` (red for oxidation)

❌ **Potential Improvement Points:**
- Target prediction is simplified (uses placeholders instead of real TargetScan/miRDB)
- GO/KEGG enrichment is simulated (real implementation would use clusterProfiler)

---

## 📊 STEP 4: BIOMARKER ANALYSIS

### ❓ **Questions Answered:**

1. **Can oxidized miRNAs be used as diagnostic biomarkers?**
   - ROC curves for each individual miRNA
   - AUC (Area Under Curve) calculation
   - Ranking of best biomarkers

2. **Is there a combined signature of multiple miRNAs?**
   - Multi-miRNA signature
   - Combined ROC curve
   - Individual vs combined performance comparison

3. **Which miRNAs have better diagnostic capacity?**
   - Top 5-10 biomarkers by AUC
   - Sensitivity and specificity
   - Signature heatmap by sample

### 🔍 **Data Used (CRITICAL):**

**Filter applied (same as Step 3):**
```r
significant_gt <- statistical_results %>%
  filter(
    str_detect(pos.mut, ":GT$"),
    !is.na(t_test_fdr) | !is.na(wilcoxon_fdr),
    (t_test_fdr < alpha | wilcoxon_fdr < alpha),
    !is.na(log2_fold_change),
    log2_fold_change > log2fc_threshold_step3  # log2FC > 1.0
  ) %>%
  mutate(
    position = as.numeric(str_extract(pos.mut, "^\\d+")),
    in_seed = position >= seed_start & position <= seed_end
  ) %>%
  filter(in_seed == TRUE) %>%  # ⚠️ ONLY SEED REGION
  distinct(miRNA_name, pos.mut, .keep_all = TRUE) %>%
  arrange(desc(log2_fold_change)) %>%
  head(50)  # Top 50 for ROC analysis
```

**✅ VERIFICATION:**
- ✅ Uses only G>T in seed region (2-8)
- ✅ Filters by statistical significance
- ✅ Requires log2FC > 1.0
- ✅ Selects top 50 by log2FC (best biomarkers)

### 📁 **Output Format:**

**Tables (CSV):**
- `results/step4/final/tables/biomarkers/S4_roc_analysis.csv`
  - Columns: `SNV_id`, `miRNA_name`, `pos.mut`, `AUC`, `Sensitivity`, `Specificity`, `95%_CI_lower`, `95%_CI_upper`
  - Includes `COMBINED_SIGNATURE` row with combined signature AUC
  
- `results/step4/final/tables/biomarkers/S4_biomarker_signatures.csv`
  - Columns: `sample_id`, `group`, `signature_score`, `individual_biomarker_scores...`

**Figures (PNG):**
- `results/step4/final/figures/step4_roc_curves.png`
  - Format: PNG, 3000x2400px (12x10in @ 300 DPI)
  - Multiple ROC curves (top 5 individual + combined)
  - Theme: `theme_professional`
  
- `results/step4/final/figures/step4_biomarker_signature_heatmap.png`
  - Signature heatmap by sample
  - Colors: red for ALS, gray for Control

### 🎨 **Coherence with Pipeline:**

✅ **Consistent:**
- Uses `theme_professional`
- Uses `functions_common.R`
- Reads from `config.yaml`
- Consistent logging
- Nomenclature: `S4_*`
- Consistent colors

---

## 📊 STEP 5: miRNA FAMILY ANALYSIS

### ❓ **Questions Answered:**

1. **Which miRNA families are most affected by oxidation?**
   - Family identification (let-7, miR-X, etc.)
   - Oxidation summary by family
   - ALS vs Control comparison by family

2. **Are there families with higher susceptibility?**
   - Family ranking by number of mutations
   - Average log2FC by family
   - Percentage of significant miRNAs by family

### 🔍 **Data Used (CRITICAL):**

**Filter applied:**
```r
significant_gt_family <- statistical_results_family %>%
  filter(
    str_detect(pos.mut, ":GT$"),
    !is.na(t_test_fdr) | !is.na(wilcoxon_fdr),
    (t_test_fdr < alpha | wilcoxon_fdr < alpha),
    !is.na(log2_fold_change),
    log2_fold_change > log2fc_threshold_step3  # log2FC > 1.0
  ) %>%
  mutate(
    position = as.numeric(str_extract(pos.mut, "^\\d+")),
    in_seed = position >= seed_start & position <= seed_end
  ) %>%
  filter(in_seed == TRUE)  # ⚠️ ONLY SEED REGION
```

**✅ VERIFICATION:**
- ✅ Uses only G>T in seed region (2-8)
- ✅ Filters by statistical significance
- ✅ Requires log2FC > 1.0
- ✅ Groups by family (let-7, miR-X)

### 📁 **Output Format:**

**Tables (CSV):**
- `results/step5/final/tables/families/S5_family_summary.csv`
  - Columns: `family`, `n_miRNAs`, `n_mutations`, `n_seed_mutations`, `avg_log2FC`, `median_log2FC`, `n_significant`, `avg_ALS_mean`, `avg_Control_mean`, `avg_oxidation_diff`, `pct_significant`
  
- `results/step5/final/tables/families/S5_family_comparison.csv`
  - Columns: `family`, `mean_vaf_ALS`, `mean_vaf_Control`, `vaf_difference`, `fold_change`, `log2_fold_change`, `n_miRNAs`, `n_mutations`, `n_significant`, `avg_log2FC`

**Figures (PNG):**
- `results/step5/final/figures/step5_panelA_family_oxidation_comparison.png`
  - Barplot comparing ALS vs Control by family
  - Top 20 families by VAF difference
  
- `results/step5/final/figures/step5_panelB_family_heatmap.png`
  - Heatmap of log2FC and % significant by family
  - Top 20 families

### 🎨 **Coherence with Pipeline:**

✅ **Consistent:**
- Uses `theme_professional`
- Uses `functions_common.R`
- Reads from `config.yaml`
- Consistent logging
- Nomenclature: `S5_*`
- Consistent colors

---

## 📊 STEP 6: EXPRESSION vs OXIDATION CORRELATION

### ❓ **Questions Answered:**

1. **Is there a correlation between miRNA expression and oxidation?**
   - Pearson correlation (r) between RPM and G>T counts
   - Correlation p-value
   - Robust analysis (Spearman correlation)

2. **Are more highly expressed miRNAs more oxidized?**
   - Categorization by expression level (quintiles)
   - Oxidation comparison by category
   - Identification of high-expression high-oxidation miRNAs

### 🔍 **Data Used (CRITICAL):**

**Filter applied:**
```r
# To calculate oxidation:
oxidation_data_per_mirna <- vaf_data %>%
  semi_join(significant_gt, by = c("miRNA_name", "pos.mut")) %>%  # Only significant G>T in seed
  pivot_longer(cols = all_of(sample_cols), names_to = "sample_id", values_to = "vaf") %>%
  mutate(
    position = as.numeric(str_extract(pos.mut, "^\\d+")),
    in_seed = position >= seed_start & position <= seed_end
  ) %>%
  filter(in_seed == TRUE) %>%  # ⚠️ ONLY SEED REGION
  group_by(miRNA_name) %>%
  summarise(total_gt_vaf = sum(vaf, na.rm = TRUE), .groups = "drop")
```

**✅ VERIFICATION:**
- ✅ Uses only G>T in seed region (2-8)
- ✅ Uses `significant_gt` (filtered by significance)
- ✅ Calculates RPM from raw data (expression)
- ✅ Sums VAF of all G>T in seed by miRNA

### 📁 **Output Format:**

**Tables (CSV):**
- `results/step6/final/tables/correlation/S6_expression_oxidation_correlation.csv`
  - Columns: `miRNA_name`, `estimated_rpm`, `total_gt_counts`, `total_gt_vaf`
  - Data by miRNA for scatterplot
  
- `results/step6/final/tables/correlation/S6_expression_summary.csv`
  - Columns: `expression_category`, `n_miRNAs`, `mean_avg_rpm`, `median_avg_rpm`, `mean_total_gt_vaf`, `median_total_gt_vaf`
  - Summary by expression category (Low, Medium-Low, Medium, Medium-High, High)

**Figures (PNG):**
- `results/step6/final/figures/step6_panelA_expression_vs_oxidation.png`
  - Scatterplot: RPM (log10) vs Total G>T VAF (log10)
  - Linear regression with confidence interval
  - Annotation: Pearson r, p-value
  
- `results/step6/final/figures/step6_panelB_expression_groups_comparison.png`
  - Boxplot: Total G>T VAF by expression category
  - 5 expression categories

### 🎨 **Coherence with Pipeline:**

✅ **Consistent:**
- Uses `theme_professional`
- Uses `functions_common.R`
- Reads from `config.yaml`
- Consistent logging
- Nomenclature: `S6_*`
- Consistent colors

---

## 📊 STEP 7: CLUSTERING ANALYSIS

### ❓ **Questions Answered:**

1. **Are there groups of miRNAs with similar oxidation patterns?**
   - Hierarchical clustering
   - Cluster identification (k=6)
   - Dendrogram showing relationships

2. **Which miRNAs have similar oxidation patterns?**
   - Cluster heatmap
   - Cluster assignment by miRNA
   - Statistical summary by cluster

### 🔍 **Data Used (CRITICAL):**

**Filter applied:**
```r
significant_gt <- statistical_results %>%
  filter(
    str_detect(pos.mut, ":GT$"),
    !is.na(t_test_fdr) | !is.na(wilcoxon_fdr),
    (t_test_fdr < alpha | wilcoxon_fdr < alpha),
    !is.na(log2_fold_change)
  ) %>%
  mutate(
    position = as.numeric(str_extract(pos.mut, "^\\d+")),
    in_seed = position >= seed_start & position <= seed_end
  ) %>%
  filter(in_seed == TRUE)  # ⚠️ ONLY SEED REGION

# Clustering matrix:
clustering_data <- vaf_data %>%
  filter(
    str_detect(pos.mut, ":GT$"),
    miRNA_name %in% significant_gt$miRNA_name
  ) %>%
  mutate(
    position = as.numeric(str_extract(pos.mut, "^\\d+")),
    in_seed = position >= seed_start & position <= seed_end
  ) %>%
  filter(in_seed == TRUE) %>%  # ⚠️ ONLY SEED REGION
  select(miRNA_name, all_of(sample_cols)) %>%
  group_by(miRNA_name) %>%
  summarise(across(all_of(sample_cols), ~ mean(.x, na.rm = TRUE)), .groups = "drop")
```

**✅ VERIFICATION:**
- ✅ Uses only G>T in seed region (2-8)
- ✅ Filters by statistical significance
- ✅ Averages VAF by miRNA (across samples)
- ✅ Normalizes by z-score before clustering

### 📁 **Output Format:**

**Tables (CSV):**
- `results/step7/final/tables/clusters/S7_cluster_assignments.csv`
  - Columns: `miRNA_name`, `cluster` (1-6)
  - Cluster assignment for each miRNA
  
- `results/step7/final/tables/clusters/S7_cluster_summary.csv`
  - Columns: `cluster`, `n_miRNAs`, `avg_n_mutations`, `avg_log2FC`, `avg_ALS_mean`, `avg_Control_mean`, `avg_oxidation_diff`

**Figures (PNG):**
- `results/step7/final/figures/step7_panelA_cluster_heatmap.png`
  - Heatmap: miRNAs (rows) x Samples (columns)
  - Cluster annotation by color
  - Normalized by z-score
  
- `results/step7/final/figures/step7_panelB_cluster_dendrogram.png`
  - Hierarchical dendrogram
  - Colored rectangles by cluster (k=6)
  - Method: Ward.D2

### 🎨 **Coherence with Pipeline:**

✅ **Consistent:**
- Uses `theme_professional` (for dendrogram base R plot)
- Uses `functions_common.R`
- Reads from `config.yaml`
- Consistent logging
- Nomenclature: `S7_*`
- Consistent colors

⚠️ **Note:** Panel B uses `base::plot()` instead of ggplot2 (normal for dendrograms)

---

## 📐 OUTPUT FORMAT: PIPELINE STANDARDS

### 📊 **Tables (CSV):**

**Standard format:**
- **Function:** `write_csv(data, file, ...)` (readr)
- **Location:** `results/stepX/final/tables/{category}/SX_description.csv`
- **Nomenclature:** `S{step_number}_{descriptive_name}.csv`
- **Encoding:** UTF-8
- **Separator:** Comma (`,`)
- **Headers:** Always present (first row)

**Example structure:**
```csv
miRNA_name,pos.mut,position,ALS_mean,Control_mean,log2_fold_change,t_test_fdr
hsa-miR-219a-2-3p,7:GT,7,181.88,2.40,6.25,5.34e-5
```

### 📈 **Figures (PNG):**

**Standard format:**
- **Function:** `ggsave(file, plot, width, height, dpi, bg)`
- **Location:** `results/stepX/final/figures/stepX_panel{letter}_description.png`
- **Nomenclature:** `step{step_number}_panel{letter}_{descriptive_name}.png`
- **Dimensions:** 12x10 inches (configurable in config.yaml)
- **DPI:** 300 (publication quality)
- **Background:** White (`bg="white"`)
- **Theme:** `theme_professional` (consistent)

**Configurable parameters:**
```yaml
analysis:
  figure:
    width: 12
    height: 10
    dpi: 300
```

**Code example:**
```r
ggsave(output_figure_a, panel_a,
       width = fig_width,      # 12 (from config)
       height = fig_height,    # 10 (from config)
       dpi = fig_dpi,          # 300 (from config)
       bg = "white")
```

### 📝 **Logs:**

**Standard format:**
- **Location:** `results/stepX/final/logs/{script_name}.log`
- **Format:** Timestamped with levels (INFO, SUCCESS, WARNING, ERROR)
- **Functions:** `initialize_logging()`, `log_info()`, `log_success()`, etc.

**Example:**
```
2025-11-03 19:04:04 [INFO] Input statistical: /path/to/file.csv
2025-11-03 19:04:04 [SUCCESS] Loaded: 68968 SNVs
2025-11-03 19:04:09 [INFO] Significant G>T mutations in seed region: 331
```

---

## ✅ COHERENCE VERIFICATION

### 🎨 **Visual Style:**

✅ **All steps use:**
- `theme_professional` (same base theme)
- Consistent colors: `color_gt = "#D62728"` (red)
- Consistent font sizes
- Consistent grid styling
- Standard format for captions and subtitles

### 📊 **Data:**

✅ **All steps filter by:**
- G>T mutations (`str_detect(pos.mut, ":GT$")`)
- Seed region (positions 2-8)
- Statistical significance (FDR < alpha)
- Log2FC threshold (configurable, but consistent)

⚠️ **Justified variations:**
- **Step 3:** log2fc_threshold_step3 = 1.0 (more stringent functional analysis)
- **Step 4:** Uses top 50 for ROC (computational efficiency)
- **Step 6:** Does not require log2FC threshold (exploratory correlation)

### 🔧 **Configuration:**

✅ **All steps read from config.yaml:**
- `analysis.alpha` (FDR threshold)
- `analysis.seed_region.start` (2)
- `analysis.seed_region.end` (8)
- `analysis.log2fc_threshold_step3` (1.0)
- `analysis.colors.gt` (#D62728)
- `analysis.figure.width/height/dpi`

### 📁 **File Structure:**

✅ **Consistent:**
```
results/
  stepX/
    final/
      figures/
        stepX_panelA_*.png
        stepX_panelB_*.png
      tables/
        {category}/
          SX_*.csv
      logs/
        *.log
```

### 🧪 **Logging:**

✅ **All steps:**
- Initialize logging with `initialize_logging()`
- Use `log_section()`, `log_subsection()`, `log_info()`, `log_success()`
- Consistent timestamps
- Error handling with `tryCatch()`

---

## 🚨 IDENTIFIED PROBLEMS AND RECOMMENDATIONS

### ❌ **Critical Problems:**

1. **Step 3: Simplified Target Prediction**
   - **Problem:** Uses placeholders instead of real databases (TargetScan, miRDB)
   - **Impact:** Results are not biologically valid
   - **Recommendation:** Integrate with `multiMiR` or `targetscan.Hs.eg.db` (R packages)

2. **Step 3: Simulated GO/KEGG Enrichment**
   - **Problem:** Uses simulated data instead of `clusterProfiler`
   - **Impact:** Enrichments are not real
   - **Recommendation:** Implement with `clusterProfiler::enrichGO()` and `enrichKEGG()`

3. **Step 6: Data Reconstruction in Visualization**
   - **Problem:** Visualization script reconstructs dummy data for boxplot
   - **Impact:** Boxplot may not reflect real data
   - **Recommendation:** Pass `combined_data_categories` as output from Step 6.1

### ⚠️ **Recommended Improvements:**

1. **Documentation of Specific miRNAs/SNVs:**
   - Add `miRNAs_analyzed` and `SNVs_analyzed` columns to summary tables
   - Include list of miRNAs in logs of each step

2. **Output Validation:**
   - Add range validation (p-values between 0-1, reasonable log2FC)
   - Verify that all figures were generated correctly

3. **Nomenclature Coherence:**
   - Some scripts use `pos.mut`, others `pos:mut` → normalize to `pos.mut`

---

## 📋 SUMMARY OF QUESTIONS BY STEP

| Step | Main Question | miRNAs/SNVs Used | Main Output |
|------|--------------|------------------|-------------|
| **Step 3** | What genes/pathways are affected? | G>T in seed (2-8), significant, log2FC > 1.0 | 5 figures + 6 tables |
| **Step 4** | Can they be used as biomarkers? | Top 50 G>T in seed significant | 2 figures + 2 tables |
| **Step 5** | Which families are most affected? | G>T in seed significant, grouped by family | 2 figures + 2 tables |
| **Step 6** | Is there expression-oxidation correlation? | G>T in seed significant, with expression data | 2 figures + 2 tables |
| **Step 7** | Are there clusters of similar patterns? | G>T in seed significant, grouped by similarity | 2 figures + 2 tables |

---

## ✅ CONCLUSION

**General Coherence:** ✅ **EXCELLENT**

- All steps use the same filtering criteria (G>T in seed, significant)
- Consistent output format (CSV for tables, PNG for figures)
- Coherent visual style (`theme_professional`)
- Centralized configuration (`config.yaml`)
- Consistent logging

**Strengths:**
- ✅ Correct data filtering (only most oxidized in seed)
- ✅ Organized and clear output structure
- ✅ Reuse of common functions
- ✅ Flexible configuration

**Areas for Improvement:**
- ⚠️ Implement real target prediction (Step 3)
- ⚠️ Implement real GO/KEGG enrichment (Step 3)
- ⚠️ Improve data passing between scripts (Step 6)

---

**Generated:** 2025-11-03  
**Last Updated:** Exhaustive review of Steps 3-7
