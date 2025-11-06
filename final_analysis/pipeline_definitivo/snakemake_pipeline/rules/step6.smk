# ============================================================================
# SNAKEMAKE RULES: STEP 6 - Functional Analysis
# ============================================================================
# Purpose: Functional target and pathway enrichment analysis
# Execution: Runs after Step 3 (clustering), in parallel with Steps 4, 5
#            Uses clustering context for functional interpretation
# ============================================================================

# Load configuration
configfile: "config/config.yaml"

# ============================================================================
# COMMON PATHS AND PARAMETERS
# ============================================================================

# Input data (from Step 2 - Statistical comparisons and Step 3 - Clustering)
STEP1_5_DATA_DIR = config["paths"]["snakemake_dir"] + "/" + config["paths"]["outputs"]["step1_5"]
STEP2_DATA_DIR = config["paths"]["snakemake_dir"] + "/" + config["paths"]["outputs"]["step2"]
STEP3_DATA_DIR = config["paths"]["snakemake_dir"] + "/" + config["paths"]["outputs"]["step3"]
INPUT_STATISTICAL = STEP2_DATA_DIR + "/tables/statistical_results/S2_statistical_comparisons.csv"
INPUT_STEP3_CLUSTERS = STEP3_DATA_DIR + "/tables/clusters/S3_cluster_assignments.csv"

# Output directories
OUTPUT_STEP6 = config["paths"]["outputs"]["step6"]
OUTPUT_FIGURES = OUTPUT_STEP6 + "/figures"
OUTPUT_TABLES = OUTPUT_STEP6 + "/tables"
OUTPUT_TABLES_FUNCTIONAL = OUTPUT_TABLES + "/functional"
OUTPUT_LOGS = OUTPUT_STEP6 + "/logs"

# Scripts paths
# For script: directive (resolved from rules/ directory), use relative path
SCRIPTS_STEP6_SCRIPT = "../scripts/step6"  # For script: (resolved from rules/)
SCRIPTS_UTILS_SCRIPT = "../scripts/utils"  # For script: (resolved from rules/)
# For input: directive (resolved from Snakefile), use config path
SCRIPTS_STEP6 = config["paths"]["scripts"]["step6"]  # For input: (resolved from Snakefile)
SCRIPTS_UTILS = config["paths"]["scripts"]["utils"]  # For input: (resolved from Snakefile)

# Common parameters
FUNCTIONS_COMMON = SCRIPTS_UTILS + "/functions_common.R"  # For input: (resolved from Snakefile)

# ============================================================================
# RULE: Functional Target Analysis
# ============================================================================

rule step6_functional_target_analysis:
    input:
        statistical_results = INPUT_STATISTICAL,
        functions = FUNCTIONS_COMMON
    output:
        targets = OUTPUT_TABLES_FUNCTIONAL + "/S6_target_analysis.csv",
        als_genes = OUTPUT_TABLES_FUNCTIONAL + "/S6_als_relevant_genes.csv",
        target_comparison = OUTPUT_TABLES_FUNCTIONAL + "/S6_target_comparison.csv"
    params:
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/functional_target_analysis.log"
    script:
        SCRIPTS_STEP6_SCRIPT + "/01_functional_target_analysis.R"

# ============================================================================
# RULE: Pathway Enrichment Analysis
# ============================================================================

rule step6_pathway_enrichment:
    input:
        targets = OUTPUT_TABLES_FUNCTIONAL + "/S6_target_analysis.csv",
        functions = FUNCTIONS_COMMON
    output:
        go_enrichment = OUTPUT_TABLES_FUNCTIONAL + "/S6_go_enrichment.csv",
        kegg_enrichment = OUTPUT_TABLES_FUNCTIONAL + "/S6_kegg_enrichment.csv",
        als_pathways = OUTPUT_TABLES_FUNCTIONAL + "/S6_als_pathways.csv",
        heatmap = OUTPUT_FIGURES + "/step6_pathway_enrichment_heatmap.png"
    params:
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/pathway_enrichment.log"
    script:
        SCRIPTS_STEP6_SCRIPT + "/02_pathway_enrichment_analysis.R"

# ============================================================================
# RULE: Direct Target Prediction (Canonical vs Oxidized)
# ============================================================================

rule step6_direct_target_prediction:
    input:
        targets = OUTPUT_TABLES_FUNCTIONAL + "/S6_target_analysis.csv",
        vaf_filtered = STEP1_5_DATA_DIR + "/tables/filtered_data/ALL_MUTATIONS_VAF_FILTERED.csv",
        functions = FUNCTIONS_COMMON
    output:
        canonical_targets = OUTPUT_TABLES_FUNCTIONAL + "/S6_canonical_targets.csv",
        oxidized_targets = OUTPUT_TABLES_FUNCTIONAL + "/S6_oxidized_targets.csv",
        target_comparison = OUTPUT_TABLES_FUNCTIONAL + "/S6_target_comparison_detailed.csv",
        target_comparison_figure = OUTPUT_FIGURES + "/step6_target_comparison.png"
    params:
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/direct_target_prediction.log"
    script:
        SCRIPTS_STEP6_SCRIPT + "/03_direct_target_prediction.R"

# ============================================================================
# RULE: Complex Functional Visualization
# ============================================================================

rule step6_complex_functional_viz:
    input:
        targets = OUTPUT_TABLES_FUNCTIONAL + "/S6_target_analysis.csv",
        go_enrichment = OUTPUT_TABLES_FUNCTIONAL + "/S6_go_enrichment.csv",
        kegg_enrichment = OUTPUT_TABLES_FUNCTIONAL + "/S6_kegg_enrichment.csv",
        als_genes = OUTPUT_TABLES_FUNCTIONAL + "/S6_als_relevant_genes.csv",
        target_comparison = OUTPUT_TABLES_FUNCTIONAL + "/S6_target_comparison.csv",
        functions = FUNCTIONS_COMMON
    output:
        figure_a = OUTPUT_FIGURES + "/step6_panelA_pathway_enrichment.png",
        figure_b = OUTPUT_FIGURES + "/step6_panelB_als_genes_impact.png",
        figure_c = OUTPUT_FIGURES + "/step6_panelC_target_comparison.png",
        figure_d = OUTPUT_FIGURES + "/step6_panelD_position_impact.png"
    params:
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/complex_functional_viz.log"
    script:
        SCRIPTS_STEP6_SCRIPT + "/03_complex_functional_visualization.R"

# ============================================================================
# AGGREGATE RULE: All Step 6 outputs
# ============================================================================

rule all_step6:
    input:
        # DEPENDENCY: Step 6 requires Step 2 (statistical comparisons) and Step 3 (clustering)
        rules.all_step2.output,
        rules.all_step3.output,
        # Functional analysis tables
        OUTPUT_TABLES_FUNCTIONAL + "/S6_target_analysis.csv",
        OUTPUT_TABLES_FUNCTIONAL + "/S6_als_relevant_genes.csv",
        OUTPUT_TABLES_FUNCTIONAL + "/S6_target_comparison.csv",
        OUTPUT_TABLES_FUNCTIONAL + "/S6_go_enrichment.csv",
        OUTPUT_TABLES_FUNCTIONAL + "/S6_kegg_enrichment.csv",
        OUTPUT_TABLES_FUNCTIONAL + "/S6_als_pathways.csv",
        # Direct target prediction (new)
        OUTPUT_TABLES_FUNCTIONAL + "/S6_canonical_targets.csv",
        OUTPUT_TABLES_FUNCTIONAL + "/S6_oxidized_targets.csv",
        OUTPUT_TABLES_FUNCTIONAL + "/S6_target_comparison_detailed.csv",
        OUTPUT_FIGURES + "/step6_target_comparison.png",
        # Figures
        OUTPUT_FIGURES + "/step6_pathway_enrichment_heatmap.png",
        OUTPUT_FIGURES + "/step6_panelA_pathway_enrichment.png",
        OUTPUT_FIGURES + "/step6_panelB_als_genes_impact.png",
        OUTPUT_FIGURES + "/step6_panelC_target_comparison.png",
        OUTPUT_FIGURES + "/step6_panelD_position_impact.png"

