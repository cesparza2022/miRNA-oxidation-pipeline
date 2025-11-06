# ============================================================================
# SNAKEMAKE RULES: STEP 2 - Statistical Comparisons (ALS vs Control)
# ============================================================================
# Rules for comparing ALS vs Control groups
# ============================================================================

# Load configuration
configfile: "config/config.yaml"

# Import os for path checking
import os

# ============================================================================
# COMMON PATHS AND PARAMETERS
# ============================================================================

# Input data (from Step 1.5 - VAF filtered)
# Note: Path is relative to snakemake_dir
STEP1_5_DATA_DIR = config["paths"]["snakemake_dir"] + "/" + config["paths"]["outputs"]["step1_5"]
INPUT_DATA_VAF_FILTERED = STEP1_5_DATA_DIR + "/tables/filtered_data/ALL_MUTATIONS_VAF_FILTERED.csv"

# Alternative: use processed clean data if VAF filtered not available
INPUT_DATA_FALLBACK = config["paths"]["data"]["processed_clean"]

# Sample metadata file (optional - for flexible group assignment)
METADATA_FILE = config["paths"]["data"].get("metadata", None)

# Output directories
OUTPUT_STEP2 = config["paths"]["outputs"]["step2"]
OUTPUT_FIGURES = OUTPUT_STEP2 + "/figures"
OUTPUT_TABLES = OUTPUT_STEP2 + "/tables"
OUTPUT_TABLES_STATISTICAL = OUTPUT_TABLES + "/statistical_results"
OUTPUT_TABLES_SUMMARY = OUTPUT_TABLES + "/summary"
OUTPUT_LOGS = OUTPUT_STEP2 + "/logs"

# Scripts directories
# Note: In Snakemake, when using include: to include rules from rules/ directory,
# paths in script: directive are resolved relative to the INCLUDED file's directory (rules/),
# not the main Snakefile directory. So we need to go up one level.
SCRIPTS_STEP2 = "../scripts/step2"  # For script: (resolved from rules/)
SCRIPTS_UTILS = "../scripts/utils"  # For script: (resolved from rules/)

# Common parameters
# For input: use path relative to Snakefile (pipeline root)
FUNCTIONS_COMMON = "scripts/utils/functions_common.R"  # For input: (resolved from Snakefile)
GROUP_FUNCTIONS = "scripts/utils/group_comparison.R"  # For input: (resolved from Snakefile)

# ============================================================================
# RULE: Batch Effect Analysis (Step 2.0)
# ============================================================================

rule step2_batch_effect_analysis:
    input:
        vaf_filtered_data = INPUT_DATA_VAF_FILTERED,
        fallback_data = INPUT_DATA_FALLBACK,
        functions = FUNCTIONS_COMMON,
        metadata = lambda wildcards: METADATA_FILE if METADATA_FILE else []
    output:
        batch_corrected = OUTPUT_TABLES_STATISTICAL + "/S2_batch_corrected_data.csv",
        report = OUTPUT_LOGS + "/batch_effect_report.txt",
        pca_before = OUTPUT_FIGURES + "/step2_batch_effect_pca_before.png"
    params:
        functions = FUNCTIONS_COMMON,
        group_functions = GROUP_FUNCTIONS,
        metadata_file = METADATA_FILE if METADATA_FILE else ""
    log:
        OUTPUT_LOGS + "/batch_effect_analysis.log"
    script:
        SCRIPTS_STEP2 + "/00_batch_effect_analysis.R"

# ============================================================================
# RULE: Confounder Analysis (Step 2.0b)
# ============================================================================

rule step2_confounder_analysis:
    input:
        vaf_filtered_data = INPUT_DATA_VAF_FILTERED,
        fallback_data = INPUT_DATA_FALLBACK,
        functions = FUNCTIONS_COMMON,
        metadata = lambda wildcards: METADATA_FILE if METADATA_FILE else []
    output:
        report = OUTPUT_LOGS + "/confounder_analysis_report.txt",
        group_balance = OUTPUT_TABLES_STATISTICAL + "/S2_group_balance.json",
        balance_plot = OUTPUT_FIGURES + "/step2_group_balance.png"
    params:
        functions = FUNCTIONS_COMMON,
        group_functions = GROUP_FUNCTIONS,
        metadata_file = METADATA_FILE if METADATA_FILE else ""
    log:
        OUTPUT_LOGS + "/confounder_analysis.log"
    script:
        SCRIPTS_STEP2 + "/00_confounder_analysis.R"

# ============================================================================
# RULE: Statistical Comparisons (Step 2.1) - Updated with assumptions validation
# ============================================================================

rule step2_statistical_comparisons:
    input:
        # Batch effect analysis output (optional - script will check if exists)
        batch_corrected = rules.step2_batch_effect_analysis.output.batch_corrected,
        vaf_filtered_data = INPUT_DATA_VAF_FILTERED,  # Fallback: Try VAF filtered
        fallback_data = INPUT_DATA_FALLBACK,  # Fallback: processed clean
        functions = FUNCTIONS_COMMON,
        assumptions_functions = "scripts/utils/statistical_assumptions.R",  # For input: (resolved from Snakefile)
        metadata = lambda wildcards: METADATA_FILE if METADATA_FILE else []
    output:
        table = OUTPUT_TABLES_STATISTICAL + "/S2_statistical_comparisons.csv",
        assumptions_report = OUTPUT_LOGS + "/statistical_assumptions_report.txt"
    params:
        functions = FUNCTIONS_COMMON,
        group_functions = GROUP_FUNCTIONS,
        assumptions_functions = "scripts/utils/statistical_assumptions.R",  # For params: (resolved from Snakefile)
        metadata_file = METADATA_FILE if METADATA_FILE else ""
    log:
        OUTPUT_LOGS + "/statistical_comparisons.log"
    script:
        SCRIPTS_STEP2 + "/01_statistical_comparisons.R"

# ============================================================================
# RULE: Volcano Plot
# ============================================================================

rule step2_volcano_plot:
    input:
        comparisons = OUTPUT_TABLES_STATISTICAL + "/S2_statistical_comparisons.csv",
        functions = FUNCTIONS_COMMON
    output:
        figure = OUTPUT_FIGURES + "/step2_volcano_plot.png"
    params:
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/volcano_plot.log"
    script:
        SCRIPTS_STEP2 + "/02_volcano_plots.R"

# ============================================================================
# RULE: Effect Size Analysis
# ============================================================================

rule step2_effect_size:
    input:
        comparisons = OUTPUT_TABLES_STATISTICAL + "/S2_statistical_comparisons.csv",
        functions = FUNCTIONS_COMMON
    output:
        table = OUTPUT_TABLES_STATISTICAL + "/S2_effect_sizes.csv",
        figure = OUTPUT_FIGURES + "/step2_effect_size_distribution.png"
    params:
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/effect_size.log"
    script:
        SCRIPTS_STEP2 + "/03_effect_size_analysis.R"

# ============================================================================
# RULE: Generate Summary Tables (Interpretative)
# ============================================================================

rule step2_generate_summary_tables:
    input:
        comparisons = OUTPUT_TABLES_STATISTICAL + "/S2_statistical_comparisons.csv",
        effect_sizes = OUTPUT_TABLES_STATISTICAL + "/S2_effect_sizes.csv",
        functions = FUNCTIONS_COMMON
    output:
        significant_mutations = OUTPUT_TABLES_SUMMARY + "/S2_significant_mutations.csv",
        top_effect_sizes = OUTPUT_TABLES_SUMMARY + "/S2_top_effect_sizes.csv",
        seed_significant = OUTPUT_TABLES_SUMMARY + "/S2_seed_region_significant.csv"
    params:
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/generate_summary_tables.log"
    script:
        SCRIPTS_STEP2 + "/04_generate_summary_tables.R"

# ============================================================================
# RULE: Position-Specific Analysis (Step 2.5)
# ============================================================================

rule step2_position_specific_analysis:
    input:
        vaf_filtered_data = INPUT_DATA_VAF_FILTERED,
        fallback_data = INPUT_DATA_FALLBACK,
        functions = FUNCTIONS_COMMON,
        metadata = lambda wildcards: METADATA_FILE if METADATA_FILE else []
    output:
        table = OUTPUT_TABLES_STATISTICAL + "/S2_position_specific_statistics.csv",
        figure = OUTPUT_FIGURES + "/step2_position_specific_distribution.png"
    params:
        functions = FUNCTIONS_COMMON,
        group_functions = GROUP_FUNCTIONS,
        metadata_file = METADATA_FILE if METADATA_FILE else ""
    log:
        OUTPUT_LOGS + "/position_specific_analysis.log"
    script:
        SCRIPTS_STEP2 + "/05_position_specific_analysis.R"

# ============================================================================
# RULE: Hierarchical Clustering - ALL G>T SNVs (Step 2.6)
# ============================================================================

rule step2_hierarchical_clustering_all_gt:
    input:
        vaf_filtered_data = INPUT_DATA_VAF_FILTERED,
        fallback_data = INPUT_DATA_FALLBACK,
        functions = FUNCTIONS_COMMON
    output:
        clustering_figure = OUTPUT_FIGURES + "/step2_clustering_all_gt.png",
        cluster_assignments = OUTPUT_TABLES_STATISTICAL + "/S2_clustering_all_gt_assignments.csv",
        clustering_table = OUTPUT_TABLES_STATISTICAL + "/S2_clustering_all_gt_summary.csv"
    params:
        functions = FUNCTIONS_COMMON,
        data_file = lambda wildcards: INPUT_DATA_VAF_FILTERED if os.path.exists(INPUT_DATA_VAF_FILTERED) else INPUT_DATA_FALLBACK
    log:
        OUTPUT_LOGS + "/hierarchical_clustering_all_gt.log"
    script:
        SCRIPTS_STEP2 + "/06_hierarchical_clustering_all_gt.R"

# ============================================================================
# RULE: Hierarchical Clustering - SEED REGION G>T SNVs ONLY (Step 2.7)
# ============================================================================

rule step2_hierarchical_clustering_seed_gt:
    input:
        vaf_filtered_data = INPUT_DATA_VAF_FILTERED,
        fallback_data = INPUT_DATA_FALLBACK,
        functions = FUNCTIONS_COMMON
    output:
        clustering_figure = OUTPUT_FIGURES + "/step2_clustering_seed_gt.png",
        cluster_assignments = OUTPUT_TABLES_STATISTICAL + "/S2_clustering_seed_gt_assignments.csv",
        clustering_table = OUTPUT_TABLES_STATISTICAL + "/S2_clustering_seed_gt_summary.csv"
    params:
        functions = FUNCTIONS_COMMON,
        data_file = lambda wildcards: INPUT_DATA_VAF_FILTERED if os.path.exists(INPUT_DATA_VAF_FILTERED) else INPUT_DATA_FALLBACK
    log:
        OUTPUT_LOGS + "/hierarchical_clustering_seed_gt.log"
    script:
        SCRIPTS_STEP2 + "/07_hierarchical_clustering_seed_gt.R"

# ============================================================================
# AGGREGATE RULE: All Step 2 outputs
# ============================================================================

rule all_step2:
    input:
        # DEPENDENCY: Step 1.5 must complete before Step 2
        rules.all_step1_5.output,
        # Pre-analysis (new critical steps)
        OUTPUT_TABLES_STATISTICAL + "/S2_batch_corrected_data.csv",
        OUTPUT_LOGS + "/batch_effect_report.txt",
        OUTPUT_FIGURES + "/step2_batch_effect_pca_before.png",
        OUTPUT_LOGS + "/confounder_analysis_report.txt",
        OUTPUT_TABLES_STATISTICAL + "/S2_group_balance.json",
        OUTPUT_FIGURES + "/step2_group_balance.png",
        # Statistical results (complete)
        OUTPUT_TABLES_STATISTICAL + "/S2_statistical_comparisons.csv",
        OUTPUT_TABLES_STATISTICAL + "/S2_effect_sizes.csv",
        # NEW: Position-specific analysis
        OUTPUT_TABLES_STATISTICAL + "/S2_position_specific_statistics.csv",
        OUTPUT_FIGURES + "/step2_position_specific_distribution.png",
        # NEW: Hierarchical clustering analyses
        OUTPUT_FIGURES + "/step2_clustering_all_gt.png",
        OUTPUT_TABLES_STATISTICAL + "/S2_clustering_all_gt_assignments.csv",
        OUTPUT_TABLES_STATISTICAL + "/S2_clustering_all_gt_summary.csv",
        OUTPUT_FIGURES + "/step2_clustering_seed_gt.png",
        OUTPUT_TABLES_STATISTICAL + "/S2_clustering_seed_gt_assignments.csv",
        OUTPUT_TABLES_STATISTICAL + "/S2_clustering_seed_gt_summary.csv",
        # Figures
        OUTPUT_FIGURES + "/step2_volcano_plot.png",
        OUTPUT_FIGURES + "/step2_effect_size_distribution.png",
        # Summary tables (interpretative)
        OUTPUT_TABLES_SUMMARY + "/S2_significant_mutations.csv",
        OUTPUT_TABLES_SUMMARY + "/S2_top_effect_sizes.csv",
        OUTPUT_TABLES_SUMMARY + "/S2_seed_region_significant.csv"
