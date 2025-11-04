# ============================================================================
# SNAKEMAKE RULES: STEP 3 - Functional Analysis
# ============================================================================
# Rules for functional target and pathway enrichment analysis
# ============================================================================

# Load configuration
configfile: "config/config.yaml"

# ============================================================================
# COMMON PATHS AND PARAMETERS
# ============================================================================

# Input data (from Step 2 - Statistical comparisons)
STEP2_DATA_DIR = config["paths"]["snakemake_dir"] + "/" + config["paths"]["outputs"]["step2"]
INPUT_STATISTICAL = STEP2_DATA_DIR + "/tables/statistical_results/S2_statistical_comparisons.csv"

# Output directories
OUTPUT_STEP3 = config["paths"]["outputs"]["step3"]
OUTPUT_FIGURES = OUTPUT_STEP3 + "/figures"
OUTPUT_TABLES = OUTPUT_STEP3 + "/tables"
OUTPUT_TABLES_FUNCTIONAL = OUTPUT_TABLES + "/functional"
OUTPUT_LOGS = OUTPUT_STEP3 + "/logs"

# Scripts directories
SCRIPTS_STEP3 = config["paths"]["snakemake_dir"] + "/" + config["paths"]["scripts"]["step3"]
SCRIPTS_UTILS = config["paths"]["snakemake_dir"] + "/" + config["paths"]["scripts"]["utils"]

# Common parameters
FUNCTIONS_COMMON = SCRIPTS_UTILS + "/functions_common.R"

# ============================================================================
# RULE: Functional Target Analysis
# ============================================================================

rule step3_functional_target_analysis:
    input:
        statistical_results = INPUT_STATISTICAL,
        functions = FUNCTIONS_COMMON
    output:
        targets = OUTPUT_TABLES_FUNCTIONAL + "/S3_target_analysis.csv",
        als_genes = OUTPUT_TABLES_FUNCTIONAL + "/S3_als_relevant_genes.csv",
        target_comparison = OUTPUT_TABLES_FUNCTIONAL + "/S3_target_comparison.csv"
    params:
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/functional_target_analysis.log"
    script:
        SCRIPTS_STEP3 + "/01_functional_target_analysis.R"

# ============================================================================
# RULE: Pathway Enrichment Analysis
# ============================================================================

rule step3_pathway_enrichment:
    input:
        targets = OUTPUT_TABLES_FUNCTIONAL + "/S3_target_analysis.csv",
        functions = FUNCTIONS_COMMON
    output:
        go_enrichment = OUTPUT_TABLES_FUNCTIONAL + "/S3_go_enrichment.csv",
        kegg_enrichment = OUTPUT_TABLES_FUNCTIONAL + "/S3_kegg_enrichment.csv",
        als_pathways = OUTPUT_TABLES_FUNCTIONAL + "/S3_als_pathways.csv",
        heatmap = OUTPUT_FIGURES + "/step3_pathway_enrichment_heatmap.png"
    params:
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/pathway_enrichment.log"
    script:
        SCRIPTS_STEP3 + "/02_pathway_enrichment_analysis.R"

# ============================================================================
# RULE: Complex Functional Visualization
# ============================================================================

rule step3_complex_functional_viz:
    input:
        targets = OUTPUT_TABLES_FUNCTIONAL + "/S3_target_analysis.csv",
        go_enrichment = OUTPUT_TABLES_FUNCTIONAL + "/S3_go_enrichment.csv",
        kegg_enrichment = OUTPUT_TABLES_FUNCTIONAL + "/S3_kegg_enrichment.csv",
        als_genes = OUTPUT_TABLES_FUNCTIONAL + "/S3_als_relevant_genes.csv",
        target_comparison = OUTPUT_TABLES_FUNCTIONAL + "/S3_target_comparison.csv",
        functions = FUNCTIONS_COMMON
    output:
        figure_a = OUTPUT_FIGURES + "/step3_panelA_pathway_enrichment.png",
        figure_b = OUTPUT_FIGURES + "/step3_panelB_als_genes_impact.png",
        figure_c = OUTPUT_FIGURES + "/step3_panelC_target_comparison.png",
        figure_d = OUTPUT_FIGURES + "/step3_panelD_position_impact.png"
    params:
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/complex_functional_viz.log"
    script:
        SCRIPTS_STEP3 + "/03_complex_functional_visualization.R"

# ============================================================================
# AGGREGATE RULE: All Step 3 outputs
# ============================================================================

rule all_step3:
    input:
        # Functional analysis tables
        OUTPUT_TABLES_FUNCTIONAL + "/S3_target_analysis.csv",
        OUTPUT_TABLES_FUNCTIONAL + "/S3_als_relevant_genes.csv",
        OUTPUT_TABLES_FUNCTIONAL + "/S3_target_comparison.csv",
        OUTPUT_TABLES_FUNCTIONAL + "/S3_go_enrichment.csv",
        OUTPUT_TABLES_FUNCTIONAL + "/S3_kegg_enrichment.csv",
        OUTPUT_TABLES_FUNCTIONAL + "/S3_als_pathways.csv",
        # Figures
        OUTPUT_FIGURES + "/step3_pathway_enrichment_heatmap.png",
        OUTPUT_FIGURES + "/step3_panelA_pathway_enrichment.png",
        OUTPUT_FIGURES + "/step3_panelB_als_genes_impact.png",
        OUTPUT_FIGURES + "/step3_panelC_target_comparison.png",
        OUTPUT_FIGURES + "/step3_panelD_position_impact.png"

