# Changelog - miRNA Oxidation Pipeline Implementation

## [Latest] - 2025-11-13

### Fixed
- **Step 4.3 - Complex Functional Visualization**: 
  - Fixed indentation error in Panel D plotting code (missing closing brace)
  - Updated all context messages from "Step 6.3" to "Step 4.3" to reflect correct pipeline step
  - Added proper handling for empty input dataframes (`als_genes_data`, `target_comp`, `target_data`) to prevent errors when generating plots
  - Added placeholder figures with "No data available" messages when input data is empty
  - Fixed calculation of `top_mirna` and `top_impact` statistics for Panel B to handle empty `als_summary`
  - All 4 functional panels (A, B, C, D) now generate successfully even with empty data

### Changed
- **Step 4 Viewer**: Regenerated with all functional analysis figures, including placeholders for panels with no data

---

## [Previous] - 2025-11-13

### Major Pipeline Reorganization

#### Structural Changes
- **Step 0 - Overview**: New initial step for dataset characterization without G>T bias
  - Added general statistics on miRNAs, samples, and SNVs
  - Added pie charts for SNV type distribution
  - All figures and text translated to English
  - Generates comprehensive overview tables and figures

- **Step 1.5 - VAF Filtering**: Modified to output only SNV count columns (415 columns)
  - Removed redundant total count columns from primary output
  - Ensures downstream steps use correct data matrix

- **Step 3 - Clustering Analysis**: Separated from Functional Analysis
  - Now only contains clustering and visualization rules
  - Outputs cluster assignments for use in Steps 4 and 5

- **Step 4 - Functional Analysis**: Reorganized from original Step 3
  - Moved functional target analysis, pathway enrichment, and complex visualization from Step 3
  - Now receives cluster assignments from Step 3 as input
  - Includes proper handling for empty input data

- **Step 5 - Family Analysis**: Enhanced with cluster context
  - Now uses cluster assignments from Step 3
  - Compares data-driven clusters with biological miRNA families

- **Step 6 - Expression Correlation**: Simplified
  - Removed functional analysis rules (moved to Step 4)
  - Now only contains expression vs oxidation correlation analysis
  - Uses base R operations to avoid "variable names limited to 10000 bytes" error

- **Step 7 - Biomarker Analysis**: Reorganized from original Step 4
  - Moved ROC analysis and biomarker signature heatmap from Step 4
  - Now receives statistical comparison results from Step 2 as input
  - Uses base R operations to avoid "variable names limited to 10000 bytes" error

#### Technical Improvements

##### Data Matrix Separation
- Created `scripts/utils/data_loading_helpers.R` with helper functions:
  - `identify_snv_count_columns()`: Identifies SNV count columns
  - `identify_total_count_columns()`: Identifies total count columns
  - `identify_vaf_columns()`: Identifies VAF columns
- Integrated helper functions into:
  - `scripts/step2/01_statistical_comparisons.R`
  - `scripts/step3/01_clustering_analysis.R`
  - `scripts/step3/02_clustering_visualization.R`
  - `scripts/step7/01_biomarker_roc_analysis.R`
  - `scripts/step7/02_biomarker_signature_heatmap.R`
- Ensures only 415 SNV count columns are used in downstream analyses (not 830)

##### Base R Migration (Performance)
- Replaced `dplyr` operations with base R equivalents in:
  - `scripts/step6/01_expression_oxidation_correlation.R`
  - `scripts/step7/01_biomarker_roc_analysis.R`
  - `scripts/utils/group_comparison.R`
- Resolved "variable names are limited to 10000 bytes" error when processing 415 sample columns
- Improved memory efficiency for large datasets

##### Error Handling
- Added empty data checks in:
  - `scripts/step6/02_correlation_visualization.R`: Handles empty correlation data
  - `scripts/step7/01_biomarker_roc_analysis.R`: Handles empty significant G>T mutations
  - `scripts/step7/02_biomarker_signature_heatmap.R`: Handles empty ROC table
  - `scripts/step4/03_complex_functional_visualization.R`: Handles empty functional data
- All scripts now generate placeholder figures or empty output files when no data is available

##### Dynamic Group Detection
- Updated `scripts/utils/group_comparison.R`:
  - `extract_sample_groups()`: Processes large datasets in chunks (200+ columns)
  - Uses base R subsetting to avoid variable name limits
- Updated `scripts/step2/01_statistical_comparisons.R`:
  - Dynamically generates `group1_mean_col` and `group2_mean_col` based on detected group names
- Updated `scripts/step3/01_clustering_analysis.R`:
  - Dynamically detects `group1_mean_col` and `group2_mean_col` for cluster summary

#### Viewer Updates
- **Step 0 Viewer**: New HTML viewer for dataset overview
- **Step 3 Viewer**: Updated to display only clustering results (removed functional analysis content)
- **Step 4 Viewer**: Updated to display functional analysis results
- **Step 5 Viewer**: Updated to display miRNA family analysis results
- **Step 6 Viewer**: Updated to display expression-oxidation correlation results
- **Step 7 Viewer**: Updated to display biomarker analysis results
- All viewers now copy assets to local directories for browser compatibility

#### Documentation
- **README.md**: 
  - Added detailed Step 0 description
  - Expanded descriptions for all steps (0-7)
  - Updated output structure section
  - Added "Run only Step 0" and "Run Steps 3-7" usage examples
- **CHANGELOG_IMPLEMENTATION.md**: This file, tracking all implementation changes

#### File Cleanup
- Removed residual functional analysis files from `results/step3/final/tables/functional/`
- Cleaned up old output files from previous pipeline structure

### Fixed
- **Step 2 Density Heatmaps (FIG_2.13-2.15)**: 
  - Restored `ComplexHeatmap` style with proper color scales, titles, and annotations
  - Fixed combination logic for FIG_2.15 using Python Pillow script
  - Ensured consistent row counts when combining heatmaps
- **Step 3 Clustering Visualization**: 
  - Fixed column name detection using `standardize_mirna_col()` and `standardize_posmut_col()`
  - Fixed `across()` usage in `summarise` call
- **Step 6 Expression Correlation**: 
  - Fixed "variable names limited to 10000 bytes" error
  - Fixed column name handling in `aggregate` formulas (temporary renaming for spaces)
  - Fixed undefined columns error in filtered expression data
- **Step 7 Biomarker Analysis**: 
  - Fixed script path in `rules/step4.smk` (was pointing to wrong directory)
  - Fixed logging initialization order
  - Fixed missing `dplyr` library in `build_step7_viewer.R`
- **Viewer HTML Files**: 
  - Fixed browser security restrictions by copying assets to local directories
  - Fixed incorrect titles in Step 3 and Step 4 viewers
  - Removed residual functional analysis content from Step 3 viewer

### Added
- **Step 0 - Overview**: Complete new step for initial dataset analysis
- **Helper Functions**: `data_loading_helpers.R` for robust column identification
- **Placeholder Figures**: For steps with no significant findings
- **Empty Data Handling**: Comprehensive checks across all visualization scripts

---

## Notes

- All changes maintain backward compatibility with existing data formats
- Pipeline now follows a logical sequence: Overview → Exploratory → QC → Statistics → Clustering → Functional → Family → Expression → Biomarkers
- All viewers are functional and display correctly in browsers
- All steps handle edge cases (empty data, missing files, etc.) gracefully
