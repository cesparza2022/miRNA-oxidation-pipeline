# ============================================================================
# SNAKEMAKE RULES: STEP 4 - miRNA Family Analysis
# ============================================================================
# Purpose: Analyze oxidation patterns by miRNA families
# Execution: Runs after Step 3 (clustering), in parallel with Steps 5, 6
#            Uses clustering results to compare with biological families
# ============================================================================

# Load configuration
configfile: "config/config.yaml"

# ============================================================================
# COMMON PATHS
# ============================================================================

# Scripts paths
# For script: directive (resolved from rules/ directory), use relative path
SCRIPTS_STEP4_SCRIPT = "../scripts/step4"  # For script: (resolved from rules/)
SCRIPTS_UTILS_SCRIPT = "../scripts/utils"  # For script: (resolved from rules/)
# For input: directive (resolved from Snakefile), use config path
SCRIPTS_STEP4 = config["paths"]["scripts"]["step4"]  # For input: (resolved from Snakefile)
SCRIPTS_UTILS = config["paths"]["scripts"]["utils"]  # For input: (resolved from Snakefile)
FUNCTIONS_COMMON = SCRIPTS_UTILS + "/functions_common.R"  # For input: (resolved from Snakefile)

# Output directories (using full paths)
OUTPUT_STEP4 = config["paths"]["outputs"]["step4"]
OUTPUT_FIGURES = OUTPUT_STEP4 + "/figures"
OUTPUT_TABLES_FAMILIES = OUTPUT_STEP4 + "/tables/families"
OUTPUT_LOGS = OUTPUT_STEP4 + "/logs"

# Inputs from previous steps (using full paths)
STEP2_DATA_DIR = config["paths"]["snakemake_dir"] + "/" + config["paths"]["outputs"]["step2"]
STEP3_DATA_DIR = config["paths"]["snakemake_dir"] + "/" + config["paths"]["outputs"]["step3"]
STEP1_5_DATA_DIR = config["paths"]["snakemake_dir"] + "/" + config["paths"]["outputs"]["step1_5"]
INPUT_STEP2_STATS = STEP2_DATA_DIR + "/tables/statistical_results/S2_statistical_comparisons.csv"
INPUT_STEP3_CLUSTERS = STEP3_DATA_DIR + "/tables/clusters/S3_cluster_assignments.csv"
INPUT_STEP1_5_FILTERED_DATA = STEP1_5_DATA_DIR + "/tables/filtered_data/ALL_MUTATIONS_VAF_FILTERED.csv"

# ============================================================================
# RULE: Family Identification and Summary
# ============================================================================

rule step4_family_identification:
    input:
        comparisons = INPUT_STEP2_STATS,
        filtered_data = INPUT_STEP1_5_FILTERED_DATA,
        functions = FUNCTIONS_COMMON
    output:
        family_summary = OUTPUT_TABLES_FAMILIES + "/S4_family_summary.csv",
        family_comparison = OUTPUT_TABLES_FAMILIES + "/S4_family_comparison.csv"
    params:
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/family_identification.log"
    script:
        SCRIPTS_STEP4_SCRIPT + "/01_family_identification.R"

# ============================================================================
# RULE: Family Comparison Visualization
# ============================================================================

rule step4_family_visualization:
    input:
        family_summary = OUTPUT_TABLES_FAMILIES + "/S4_family_summary.csv",
        family_comparison = OUTPUT_TABLES_FAMILIES + "/S4_family_comparison.csv",
        cluster_assignments = INPUT_STEP3_CLUSTERS,
        functions = FUNCTIONS_COMMON
    output:
        figure_a = OUTPUT_FIGURES + "/step4_panelA_family_oxidation_comparison.png",
        figure_b = OUTPUT_FIGURES + "/step4_panelB_family_heatmap.png"
    params:
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/family_visualization.log"
    script:
        SCRIPTS_STEP4_SCRIPT + "/02_family_comparison_visualization.R"

# ============================================================================
# AGGREGATE RULE: All Step 4 outputs
# ============================================================================

rule all_step4:
    input:
        # DEPENDENCY: Step 4 requires Step 2 (statistical comparisons) and Step 3 (clustering)
        rules.all_step2.output,
        rules.all_step3.output,
        # Family analysis tables
        OUTPUT_TABLES_FAMILIES + "/S4_family_summary.csv",
        OUTPUT_TABLES_FAMILIES + "/S4_family_comparison.csv",
        # Figures
        OUTPUT_FIGURES + "/step4_panelA_family_oxidation_comparison.png",
        OUTPUT_FIGURES + "/step4_panelB_family_heatmap.png"

