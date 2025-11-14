# ============================================================================
# SNAKEMAKE RULES: STEP 2 - CORRECT FIGURES (15 figures + 2 clustering = 17 total)
# ============================================================================
# Rules for generating the 15 correct Step 2 figures using original scripts
# Note: FIG_2.8 removed (redundant with FIG_2.16 which uses ALL G>T SNVs)
# ============================================================================

# Load configuration
configfile: "config/config.yaml"

# Import os for path checking
import os

# ============================================================================
# COMMON PATHS AND PARAMETERS
# ============================================================================

# Input data: Use processed_clean.csv (has Total columns needed for VAF calculation)
# Step 1.5 output (ALL_MUTATIONS_VAF_FILTERED.csv) only has SNV counts, not Total counts
# We need Total counts to calculate VAF for the detailed figure scripts
INPUT_DATA_PRIMARY = config["paths"]["data"]["processed_clean"]

# Alternative: use VAF filtered data if processed_clean not available (will warn about missing Total columns)
STEP1_5_DATA_DIR = config["paths"]["outputs"]["step1_5"]
INPUT_DATA_FALLBACK = STEP1_5_DATA_DIR + "/tables/filtered_data/ALL_MUTATIONS_VAF_FILTERED.csv"

# Output directories
OUTPUT_STEP2 = config["paths"]["outputs"]["step2"]
OUTPUT_FIGURES = OUTPUT_STEP2 + "/figures"
OUTPUT_TABLES = OUTPUT_STEP2 + "/tables"
OUTPUT_LOGS = OUTPUT_STEP2 + "/logs"

# Scripts directories
SCRIPTS_STEP2_FIGURES = "../scripts/step2_figures"  # For script: (resolved from rules/)
# Path to original figure scripts (relative to repository root)
ORIGINAL_SCRIPTS_DIR = "scripts/step2_figures/original_scripts"

# Common parameters
FUNCTIONS_COMMON = "scripts/utils/functions_common.R"  # For input: (resolved from Snakefile)

# ============================================================================
# RULE: Generate Metadata (required for all Step 2 figures)
# ============================================================================

rule step2_generate_metadata:
    input:
        data = INPUT_DATA_PRIMARY,
        fallback = INPUT_DATA_FALLBACK
    output:
        metadata = OUTPUT_TABLES + "/S2_metadata.csv"
    params:
        data_file = lambda wildcards: INPUT_DATA_PRIMARY if os.path.exists(INPUT_DATA_PRIMARY) else INPUT_DATA_FALLBACK
    log:
        OUTPUT_LOGS + "/generate_metadata.log"
    shell:
        """
        Rscript scripts/utils/generate_metadata.R \
            {params.data_file} \
            {output.metadata} \
            > {log} 2>&1
        """

# ============================================================================
# RULE: Run All Step 2 Figures (using original scripts)
# ============================================================================

rule step2_generate_all_figures:
    input:
        data = INPUT_DATA_PRIMARY,
        fallback = INPUT_DATA_FALLBACK,
        metadata = OUTPUT_TABLES + "/S2_metadata.csv"
    output:
        # All 15 figures (2.7 is optional - will be handled separately if needed)
        fig_2_1 = OUTPUT_FIGURES + "/FIG_2.1_VAF_GLOBAL_CLEAN.png",
        fig_2_2 = OUTPUT_FIGURES + "/FIG_2.2_DISTRIBUTIONS_CLEAN.png",
        fig_2_3 = OUTPUT_FIGURES + "/FIG_2.3_VOLCANO_PER_SAMPLE_METHOD.png",
        fig_2_4 = OUTPUT_FIGURES + "/FIG_2.4_HEATMAP_TOP50_CLEAN.png",
        fig_2_5 = OUTPUT_FIGURES + "/FIG_2.5_HEATMAP_ZSCORE_CLEAN.png",
        fig_2_6 = OUTPUT_FIGURES + "/FIG_2.6_POSITIONAL_CLEAN.png",
        # fig_2_8 = OUTPUT_FIGURES + "/FIG_2.8_CLUSTERING_CLEAN.png",  # REMOVED: Redundant with FIG_2.16
        fig_2_9 = OUTPUT_FIGURES + "/FIG_2.9_CV_CLEAN.png",
        fig_2_10 = OUTPUT_FIGURES + "/FIG_2.10_RATIO_CLEAN.png",
        fig_2_11 = OUTPUT_FIGURES + "/FIG_2.11_MUTATION_TYPES_CLEAN.png",
        fig_2_12 = OUTPUT_FIGURES + "/FIG_2.12_ENRICHMENT_CLEAN.png",
        fig_2_13 = OUTPUT_FIGURES + "/FIG_2.13_DENSITY_HEATMAP_ALS.png",
        fig_2_14 = OUTPUT_FIGURES + "/FIG_2.14_DENSITY_HEATMAP_CONTROL.png",
        fig_2_15 = OUTPUT_FIGURES + "/FIG_2.15_DENSITY_COMBINED.png"
    params:
        data_file = lambda wildcards: INPUT_DATA_PRIMARY if os.path.exists(INPUT_DATA_PRIMARY) else INPUT_DATA_FALLBACK,
        metadata_file = OUTPUT_TABLES + "/S2_metadata.csv",
        output_dir = OUTPUT_FIGURES,
        scripts_dir = ORIGINAL_SCRIPTS_DIR
    log:
        OUTPUT_LOGS + "/generate_all_figures.log"
    shell:
        """
        Rscript scripts/step2_figures/run_all_step2_figures.R \
            {params.data_file} \
            {params.metadata_file} \
            {params.output_dir} \
            {params.scripts_dir} \
            > {log} 2>&1
        """

# ============================================================================
# RULE: Hierarchical Clustering - ALL G>T SNVs (Step 2.16)
# ============================================================================

rule step2_clustering_all_gt:
    input:
        vaf_filtered_data = INPUT_DATA_PRIMARY,
        fallback_data = INPUT_DATA_FALLBACK,
        functions = FUNCTIONS_COMMON
    output:
        clustering_figure = OUTPUT_FIGURES + "/FIG_2.16_CLUSTERING_ALL_GT.png",
        cluster_assignments = OUTPUT_TABLES + "/S2_clustering_all_gt_assignments.csv",
        clustering_table = OUTPUT_TABLES + "/S2_clustering_all_gt_summary.csv"
    params:
        functions = FUNCTIONS_COMMON,
        data_file = lambda wildcards: INPUT_DATA_PRIMARY if os.path.exists(INPUT_DATA_PRIMARY) else INPUT_DATA_FALLBACK
    log:
        OUTPUT_LOGS + "/clustering_all_gt.log"
    script:
        "../scripts/step2/06_hierarchical_clustering_all_gt.R"

# ============================================================================
# RULE: Hierarchical Clustering - SEED REGION G>T SNVs ONLY (Step 2.17)
# ============================================================================

rule step2_clustering_seed_gt:
    input:
        vaf_filtered_data = INPUT_DATA_PRIMARY,
        fallback_data = INPUT_DATA_FALLBACK,
        functions = FUNCTIONS_COMMON
    output:
        clustering_figure = OUTPUT_FIGURES + "/FIG_2.17_CLUSTERING_SEED_GT.png",
        cluster_assignments = OUTPUT_TABLES + "/S2_clustering_seed_gt_assignments.csv",
        clustering_table = OUTPUT_TABLES + "/S2_clustering_seed_gt_summary.csv"
    params:
        functions = FUNCTIONS_COMMON,
        data_file = lambda wildcards: INPUT_DATA_PRIMARY if os.path.exists(INPUT_DATA_PRIMARY) else INPUT_DATA_FALLBACK
    log:
        OUTPUT_LOGS + "/clustering_seed_gt.log"
    script:
        "../scripts/step2/07_hierarchical_clustering_seed_gt.R"

# ============================================================================
# AGGREGATE RULE: All Step 2 Correct Figures (15 original + 2 clustering = 17 total)
# Note: FIG_2.8 removed (redundant with FIG_2.16)
# ============================================================================

rule all_step2_figures:
    input:
        # DEPENDENCY: Step 1.5 must complete before Step 2
        rules.all_step1_5.output,
        # Metadata
        OUTPUT_TABLES + "/S2_metadata.csv",
        # All 15 original figures (2.7 is optional - will be handled separately if needed)
        OUTPUT_FIGURES + "/FIG_2.1_VAF_GLOBAL_CLEAN.png",
        OUTPUT_FIGURES + "/FIG_2.2_DISTRIBUTIONS_CLEAN.png",
        OUTPUT_FIGURES + "/FIG_2.3_VOLCANO_PER_SAMPLE_METHOD.png",
        OUTPUT_FIGURES + "/FIG_2.4_HEATMAP_TOP50_CLEAN.png",
        OUTPUT_FIGURES + "/FIG_2.5_HEATMAP_ZSCORE_CLEAN.png",
        OUTPUT_FIGURES + "/FIG_2.6_POSITIONAL_CLEAN.png",
        # OUTPUT_FIGURES + "/FIG_2.8_CLUSTERING_CLEAN.png",  # REMOVED: Redundant with FIG_2.16
        OUTPUT_FIGURES + "/FIG_2.9_CV_CLEAN.png",
        OUTPUT_FIGURES + "/FIG_2.10_RATIO_CLEAN.png",
        OUTPUT_FIGURES + "/FIG_2.11_MUTATION_TYPES_CLEAN.png",
        OUTPUT_FIGURES + "/FIG_2.12_ENRICHMENT_CLEAN.png",
        OUTPUT_FIGURES + "/FIG_2.13_DENSITY_HEATMAP_ALS.png",
        OUTPUT_FIGURES + "/FIG_2.14_DENSITY_HEATMAP_CONTROL.png",
        OUTPUT_FIGURES + "/FIG_2.15_DENSITY_COMBINED.png",
        # NEW: Hierarchical clustering analyses (guía para el análisis)
        OUTPUT_FIGURES + "/FIG_2.16_CLUSTERING_ALL_GT.png",
        OUTPUT_TABLES + "/S2_clustering_all_gt_assignments.csv",
        OUTPUT_TABLES + "/S2_clustering_all_gt_summary.csv",
        OUTPUT_FIGURES + "/FIG_2.17_CLUSTERING_SEED_GT.png",
        OUTPUT_TABLES + "/S2_clustering_seed_gt_assignments.csv",
        OUTPUT_TABLES + "/S2_clustering_seed_gt_summary.csv"

