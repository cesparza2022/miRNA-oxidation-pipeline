# ============================================================================
<<<<<<< HEAD:final_analysis/pipeline_definitivo/snakemake_pipeline/rules/step7.smk
# SNAKEMAKE RULES: STEP 7 - Biomarker Analysis (Final Integration)
# ============================================================================
# Purpose: Biomarker identification and diagnostic potential evaluation
# Execution: Runs LAST, after Step 6
# Note: Currently uses Steps 1.5, 2 primarily. Future versions may integrate Steps 3-5 data.
=======
# SNAKEMAKE RULES: STEP 7 - Clustering Analysis
# ============================================================================
# Purpose: Identify clusters of miRNAs with similar oxidation patterns
>>>>>>> 352eb6950c566304a08c8054f00dc95591ac07de:rules/step7.smk
# ============================================================================

# Load configuration
configfile: "config/config.yaml"

# ============================================================================
<<<<<<< HEAD:final_analysis/pipeline_definitivo/snakemake_pipeline/rules/step7.smk
# COMMON PATHS AND PARAMETERS
# ============================================================================

# Input data
STEP2_DATA_DIR = config["paths"]["snakemake_dir"] + "/" + config["paths"]["outputs"]["step2"]
STEP1_5_DATA_DIR = config["paths"]["snakemake_dir"] + "/" + config["paths"]["outputs"]["step1_5"]
INPUT_STATISTICAL = STEP2_DATA_DIR + "/tables/statistical_results/S2_statistical_comparisons.csv"
INPUT_VAF_FILTERED = STEP1_5_DATA_DIR + "/tables/filtered_data/ALL_MUTATIONS_VAF_FILTERED.csv"

# Output directories
OUTPUT_STEP7 = config["paths"]["outputs"]["step7"]
OUTPUT_FIGURES = OUTPUT_STEP7 + "/figures"
OUTPUT_TABLES = OUTPUT_STEP7 + "/tables"
OUTPUT_TABLES_BIOMARKERS = OUTPUT_TABLES + "/biomarkers"
OUTPUT_LOGS = OUTPUT_STEP7 + "/logs"

# Scripts paths
# For script: directive (resolved from rules/ directory), use relative path
SCRIPTS_STEP7_SCRIPT = "../scripts/step7"  # For script: (resolved from rules/)
SCRIPTS_UTILS_SCRIPT = "../scripts/utils"  # For script: (resolved from rules/)
# For input: directive (resolved from Snakefile), use config path
SCRIPTS_STEP7 = config["paths"]["scripts"]["step7"]  # For input: (resolved from Snakefile)
SCRIPTS_UTILS = config["paths"]["scripts"]["utils"]  # For input: (resolved from Snakefile)

# Common parameters
FUNCTIONS_COMMON = SCRIPTS_UTILS + "/functions_common.R"

# ============================================================================
# RULE: ROC Analysis
# ============================================================================

rule step7_roc_analysis:
    input:
        statistical_results = INPUT_STATISTICAL,
        vaf_filtered = INPUT_VAF_FILTERED,
        functions = FUNCTIONS_COMMON
    output:
        roc_table = OUTPUT_TABLES_BIOMARKERS + "/S7_roc_analysis.csv",
        signatures = OUTPUT_TABLES_BIOMARKERS + "/S7_biomarker_signatures.csv",
        roc_figure = OUTPUT_FIGURES + "/step7_roc_curves.png"
    params:
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/roc_analysis.log"
    script:
        SCRIPTS_STEP7_SCRIPT + "/01_biomarker_roc_analysis.R"

# ============================================================================
# RULE: Biomarker Signature Heatmap
# ============================================================================

rule step7_biomarker_heatmap:
    input:
        roc_table = OUTPUT_TABLES_BIOMARKERS + "/S7_roc_analysis.csv",
        vaf_filtered = INPUT_VAF_FILTERED,
        functions = FUNCTIONS_COMMON
    output:
        heatmap = OUTPUT_FIGURES + "/step7_biomarker_signature_heatmap.png"
    params:
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/biomarker_heatmap.log"
    script:
        SCRIPTS_STEP7_SCRIPT + "/02_biomarker_signature_heatmap.R"
=======
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
>>>>>>> 352eb6950c566304a08c8054f00dc95591ac07de:rules/step7.smk

# ============================================================================
# AGGREGATE RULE: All Step 7 outputs
# ============================================================================

rule all_step7:
    input:
<<<<<<< HEAD:final_analysis/pipeline_definitivo/snakemake_pipeline/rules/step7.smk
        # DEPENDENCY: Step 7 requires Step 6 (functional analysis)
        rules.all_step6.output,
        # Biomarker tables
        OUTPUT_TABLES_BIOMARKERS + "/S7_roc_analysis.csv",
        OUTPUT_TABLES_BIOMARKERS + "/S7_biomarker_signatures.csv",
        # Figures
        OUTPUT_FIGURES + "/step7_roc_curves.png",
        OUTPUT_FIGURES + "/step7_biomarker_signature_heatmap.png"
=======
        # Clustering analysis tables
        OUTPUT_TABLES_CLUSTERS + "/S7_cluster_assignments.csv",
        OUTPUT_TABLES_CLUSTERS + "/S7_cluster_summary.csv",
        # Figures
        OUTPUT_FIGURES + "/step7_panelA_cluster_heatmap.png",
        OUTPUT_FIGURES + "/step7_panelB_cluster_dendrogram.png"
>>>>>>> 352eb6950c566304a08c8054f00dc95591ac07de:rules/step7.smk

