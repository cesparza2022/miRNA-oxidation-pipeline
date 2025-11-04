# ============================================================================
# SNAKEMAKE RULES: STEP 5 - miRNA FAMILY ANALYSIS
# ============================================================================
# Purpose: Analyze oxidation patterns by miRNA families
# ============================================================================

# Load configuration
configfile: "config/config.yaml"

# ============================================================================
# COMMON PATHS
# ============================================================================

SCRIPTS_STEP5 = config["paths"]["snakemake_dir"] + "/" + config["paths"]["scripts"]["step5"]
SCRIPTS_UTILS = config["paths"]["snakemake_dir"] + "/" + config["paths"]["scripts"]["utils"]
FUNCTIONS_COMMON = SCRIPTS_UTILS + "/functions_common.R"

# Output directories (using full paths like step4)
OUTPUT_STEP5 = config["paths"]["outputs"]["step5"]
OUTPUT_FIGURES = OUTPUT_STEP5 + "/figures"
OUTPUT_TABLES_FAMILIES = OUTPUT_STEP5 + "/tables/families"
OUTPUT_LOGS = OUTPUT_STEP5 + "/logs"

# Inputs from previous steps (using full paths)
STEP2_DATA_DIR = config["paths"]["snakemake_dir"] + "/" + config["paths"]["outputs"]["step2"]
STEP1_5_DATA_DIR = config["paths"]["snakemake_dir"] + "/" + config["paths"]["outputs"]["step1_5"]
INPUT_STEP2_STATS = STEP2_DATA_DIR + "/tables/statistical_results/S2_statistical_comparisons.csv"
INPUT_STEP1_5_FILTERED_DATA = STEP1_5_DATA_DIR + "/tables/filtered_data/ALL_MUTATIONS_VAF_FILTERED.csv"

# ============================================================================
# RULE: Family Identification and Summary
# ============================================================================

rule step5_family_identification:
    input:
        comparisons = INPUT_STEP2_STATS,
        filtered_data = INPUT_STEP1_5_FILTERED_DATA,
        functions = FUNCTIONS_COMMON
    output:
        family_summary = OUTPUT_TABLES_FAMILIES + "/S5_family_summary.csv",
        family_comparison = OUTPUT_TABLES_FAMILIES + "/S5_family_comparison.csv"
    params:
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/family_identification.log"
    script:
        SCRIPTS_STEP5 + "/01_family_identification.R"

# ============================================================================
# RULE: Family Comparison Visualization
# ============================================================================

rule step5_family_visualization:
    input:
        family_summary = OUTPUT_TABLES_FAMILIES + "/S5_family_summary.csv",
        family_comparison = OUTPUT_TABLES_FAMILIES + "/S5_family_comparison.csv",
        functions = FUNCTIONS_COMMON
    output:
        figure_a = OUTPUT_FIGURES + "/step5_panelA_family_oxidation_comparison.png",
        figure_b = OUTPUT_FIGURES + "/step5_panelB_family_heatmap.png"
    params:
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/family_visualization.log"
    script:
        SCRIPTS_STEP5 + "/02_family_comparison_visualization.R"

# ============================================================================
# AGGREGATE RULE: All Step 5 outputs
# ============================================================================

rule all_step5:
    input:
        # Family analysis tables
        OUTPUT_TABLES_FAMILIES + "/S5_family_summary.csv",
        OUTPUT_TABLES_FAMILIES + "/S5_family_comparison.csv",
        # Figures
        OUTPUT_FIGURES + "/step5_panelA_family_oxidation_comparison.png",
        OUTPUT_FIGURES + "/step5_panelB_family_heatmap.png"

