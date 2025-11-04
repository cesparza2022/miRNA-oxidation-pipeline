# ============================================================================
# SNAKEMAKE RULES: STEP 4 - Biomarker Analysis
# ============================================================================
# Rules for biomarker identification and diagnostic potential evaluation
# ============================================================================

# Load configuration
configfile: "config/config.yaml"

# ============================================================================
# COMMON PATHS AND PARAMETERS
# ============================================================================

# Input data
STEP2_DATA_DIR = config["paths"]["snakemake_dir"] + "/" + config["paths"]["outputs"]["step2"]
STEP1_5_DATA_DIR = config["paths"]["snakemake_dir"] + "/" + config["paths"]["outputs"]["step1_5"]
INPUT_STATISTICAL = STEP2_DATA_DIR + "/tables/statistical_results/S2_statistical_comparisons.csv"
INPUT_VAF_FILTERED = STEP1_5_DATA_DIR + "/tables/filtered_data/ALL_MUTATIONS_VAF_FILTERED.csv"

# Output directories
OUTPUT_STEP4 = config["paths"]["outputs"]["step4"]
OUTPUT_FIGURES = OUTPUT_STEP4 + "/figures"
OUTPUT_TABLES = OUTPUT_STEP4 + "/tables"
OUTPUT_TABLES_BIOMARKERS = OUTPUT_TABLES + "/biomarkers"
OUTPUT_LOGS = OUTPUT_STEP4 + "/logs"

# Scripts directories
SCRIPTS_STEP4 = config["paths"]["snakemake_dir"] + "/" + config["paths"]["scripts"]["step4"]
SCRIPTS_UTILS = config["paths"]["snakemake_dir"] + "/" + config["paths"]["scripts"]["utils"]

# Common parameters
FUNCTIONS_COMMON = SCRIPTS_UTILS + "/functions_common.R"

# ============================================================================
# RULE: ROC Analysis
# ============================================================================

rule step4_roc_analysis:
    input:
        statistical_results = INPUT_STATISTICAL,
        vaf_filtered = INPUT_VAF_FILTERED,
        functions = FUNCTIONS_COMMON
    output:
        roc_table = OUTPUT_TABLES_BIOMARKERS + "/S4_roc_analysis.csv",
        signatures = OUTPUT_TABLES_BIOMARKERS + "/S4_biomarker_signatures.csv",
        roc_figure = OUTPUT_FIGURES + "/step4_roc_curves.png"
    params:
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/roc_analysis.log"
    script:
        SCRIPTS_STEP4 + "/01_biomarker_roc_analysis.R"

# ============================================================================
# RULE: Biomarker Signature Heatmap
# ============================================================================

rule step4_biomarker_heatmap:
    input:
        roc_table = OUTPUT_TABLES_BIOMARKERS + "/S4_roc_analysis.csv",
        vaf_filtered = INPUT_VAF_FILTERED,
        functions = FUNCTIONS_COMMON
    output:
        heatmap = OUTPUT_FIGURES + "/step4_biomarker_signature_heatmap.png"
    params:
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/biomarker_heatmap.log"
    script:
        SCRIPTS_STEP4 + "/02_biomarker_signature_heatmap.R"

# ============================================================================
# AGGREGATE RULE: All Step 4 outputs
# ============================================================================

rule all_step4:
    input:
        # Biomarker tables
        OUTPUT_TABLES_BIOMARKERS + "/S4_roc_analysis.csv",
        OUTPUT_TABLES_BIOMARKERS + "/S4_biomarker_signatures.csv",
        # Figures
        OUTPUT_FIGURES + "/step4_roc_curves.png",
        OUTPUT_FIGURES + "/step4_biomarker_signature_heatmap.png"

