# ============================================================================
# SNAKEMAKE RULES: STEP 7 - Clustering Analysis
# ============================================================================
# Purpose: Identify clusters of miRNAs with similar oxidation patterns
# ============================================================================

# Load configuration
configfile: "config/config.yaml"

# ============================================================================
# COMMON PATHS
# ============================================================================

SCRIPTS_STEP7 = config["paths"]["snakemake_dir"] + "/" + config["paths"]["scripts"]["step7"]
SCRIPTS_UTILS = config["paths"]["snakemake_dir"] + "/" + config["paths"]["scripts"]["utils"]
FUNCTIONS_COMMON = SCRIPTS_UTILS + "/functions_common.R"

# Output directories (using full paths like step4)
OUTPUT_STEP7 = config["paths"]["outputs"]["step7"]
OUTPUT_FIGURES = OUTPUT_STEP7 + "/figures"
OUTPUT_TABLES_CLUSTERS = OUTPUT_STEP7 + "/tables/clusters"
OUTPUT_LOGS = OUTPUT_STEP7 + "/logs"

# Inputs from previous steps (using full paths)
STEP2_DATA_DIR = config["paths"]["snakemake_dir"] + "/" + config["paths"]["outputs"]["step2"]
STEP1_5_DATA_DIR = config["paths"]["snakemake_dir"] + "/" + config["paths"]["outputs"]["step1_5"]
INPUT_STEP2_STATS = STEP2_DATA_DIR + "/tables/statistical_results/S2_statistical_comparisons.csv"
INPUT_STEP1_5_FILTERED_DATA = STEP1_5_DATA_DIR + "/tables/filtered_data/ALL_MUTATIONS_VAF_FILTERED.csv"

# ============================================================================
# RULE: Clustering Analysis
# ============================================================================

rule step7_clustering_analysis:
    input:
        comparisons = INPUT_STEP2_STATS,
        filtered_data = INPUT_STEP1_5_FILTERED_DATA,
        functions = FUNCTIONS_COMMON
    output:
        cluster_assignments = OUTPUT_TABLES_CLUSTERS + "/S7_cluster_assignments.csv",
        cluster_summary = OUTPUT_TABLES_CLUSTERS + "/S7_cluster_summary.csv"
    params:
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/clustering_analysis.log"
    script:
        SCRIPTS_STEP7 + "/01_clustering_analysis.R"

# ============================================================================
# RULE: Clustering Visualization
# ============================================================================

rule step7_clustering_visualization:
    input:
        cluster_assignments = OUTPUT_TABLES_CLUSTERS + "/S7_cluster_assignments.csv",
        cluster_summary = OUTPUT_TABLES_CLUSTERS + "/S7_cluster_summary.csv",
        filtered_data = INPUT_STEP1_5_FILTERED_DATA,
        functions = FUNCTIONS_COMMON
    output:
        figure_a = OUTPUT_FIGURES + "/step7_panelA_cluster_heatmap.png",
        figure_b = OUTPUT_FIGURES + "/step7_panelB_cluster_dendrogram.png"
    params:
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/clustering_visualization.log"
    script:
        SCRIPTS_STEP7 + "/02_clustering_visualization.R"

# ============================================================================
# AGGREGATE RULE: All Step 7 outputs
# ============================================================================

rule all_step7:
    input:
        # Clustering analysis tables
        OUTPUT_TABLES_CLUSTERS + "/S7_cluster_assignments.csv",
        OUTPUT_TABLES_CLUSTERS + "/S7_cluster_summary.csv",
        # Figures
        OUTPUT_FIGURES + "/step7_panelA_cluster_heatmap.png",
        OUTPUT_FIGURES + "/step7_panelB_cluster_dendrogram.png"

