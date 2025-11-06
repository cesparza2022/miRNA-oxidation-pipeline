# ============================================================================
# SNAKEMAKE RULES: STEP 3 - Clustering Analysis (Structure Discovery)
# ============================================================================
# Purpose: Identify clusters of miRNAs with similar oxidation patterns
# Execution: Runs FIRST after Step 2, before Steps 4, 5, 6
#            Steps 4, 5, 6 depend on Step 3 to use clustering results
# ============================================================================

# Load configuration
configfile: "config/config.yaml"

# ============================================================================
# COMMON PATHS
# ============================================================================

# Scripts paths
# For script: directive (resolved from rules/ directory), use relative path
SCRIPTS_STEP3_SCRIPT = "../scripts/step3"  # For script: (resolved from rules/)
SCRIPTS_UTILS_SCRIPT = "../scripts/utils"  # For script: (resolved from rules/)
# For input: directive (resolved from Snakefile), use config path
SCRIPTS_STEP3 = config["paths"]["scripts"]["step3"]  # For input: (resolved from Snakefile)
SCRIPTS_UTILS = config["paths"]["scripts"]["utils"]  # For input: (resolved from Snakefile)
FUNCTIONS_COMMON = SCRIPTS_UTILS + "/functions_common.R"  # For input: (resolved from Snakefile)

# Output directories (using full paths)
OUTPUT_STEP3 = config["paths"]["outputs"]["step3"]
OUTPUT_FIGURES = OUTPUT_STEP3 + "/figures"
OUTPUT_TABLES_CLUSTERS = OUTPUT_STEP3 + "/tables/clusters"
OUTPUT_LOGS = OUTPUT_STEP3 + "/logs"

# Inputs from previous steps (using full paths)
STEP2_DATA_DIR = config["paths"]["snakemake_dir"] + "/" + config["paths"]["outputs"]["step2"]
STEP1_5_DATA_DIR = config["paths"]["snakemake_dir"] + "/" + config["paths"]["outputs"]["step1_5"]
INPUT_STEP2_STATS = STEP2_DATA_DIR + "/tables/statistical_results/S2_statistical_comparisons.csv"
INPUT_STEP1_5_FILTERED_DATA = STEP1_5_DATA_DIR + "/tables/filtered_data/ALL_MUTATIONS_VAF_FILTERED.csv"

# ============================================================================
# RULE: Clustering Analysis
# ============================================================================

rule step3_clustering_analysis:
    input:
        comparisons = INPUT_STEP2_STATS,
        filtered_data = INPUT_STEP1_5_FILTERED_DATA,
        functions = FUNCTIONS_COMMON
    output:
        cluster_assignments = OUTPUT_TABLES_CLUSTERS + "/S3_cluster_assignments.csv",
        cluster_summary = OUTPUT_TABLES_CLUSTERS + "/S3_cluster_summary.csv"
    params:
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/clustering_analysis.log"
    script:
        SCRIPTS_STEP3_SCRIPT + "/01_clustering_analysis.R"

# ============================================================================
# RULE: Clustering Visualization
# ============================================================================

rule step3_clustering_visualization:
    input:
        cluster_assignments = OUTPUT_TABLES_CLUSTERS + "/S3_cluster_assignments.csv",
        cluster_summary = OUTPUT_TABLES_CLUSTERS + "/S3_cluster_summary.csv",
        filtered_data = INPUT_STEP1_5_FILTERED_DATA,
        functions = FUNCTIONS_COMMON
    output:
        figure_a = OUTPUT_FIGURES + "/step3_panelA_cluster_heatmap.png",
        figure_b = OUTPUT_FIGURES + "/step3_panelB_cluster_dendrogram.png"
    params:
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/clustering_visualization.log"
    script:
        SCRIPTS_STEP3_SCRIPT + "/02_clustering_visualization.R"

# ============================================================================
# AGGREGATE RULE: All Step 3 outputs
# ============================================================================

rule all_step3:
    input:
        # DEPENDENCY: Step 3 requires Step 2 (statistical comparisons)
        rules.all_step2.output,
        # Clustering analysis tables
        OUTPUT_TABLES_CLUSTERS + "/S3_cluster_assignments.csv",
        OUTPUT_TABLES_CLUSTERS + "/S3_cluster_summary.csv",
        # Figures
        OUTPUT_FIGURES + "/step3_panelA_cluster_heatmap.png",
        OUTPUT_FIGURES + "/step3_panelB_cluster_dendrogram.png"

