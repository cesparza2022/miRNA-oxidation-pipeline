# ============================================================================
<<<<<<< HEAD:final_analysis/pipeline_definitivo/snakemake_pipeline/rules/step5.smk
# SNAKEMAKE RULES: STEP 5 - Expression vs Oxidation Correlation
# ============================================================================
# Purpose: Analyze correlation between miRNA expression levels and oxidation
# Execution: Runs after Step 3 (clustering), in parallel with Steps 4, 6
#            Can use clustering context for expression analysis
=======
# SNAKEMAKE RULES: STEP 5 - miRNA FAMILY ANALYSIS
# ============================================================================
# Purpose: Analyze oxidation patterns by miRNA families
>>>>>>> 352eb6950c566304a08c8054f00dc95591ac07de:rules/step5.smk
# ============================================================================

# Load configuration
configfile: "config/config.yaml"

# ============================================================================
# COMMON PATHS
# ============================================================================

<<<<<<< HEAD:final_analysis/pipeline_definitivo/snakemake_pipeline/rules/step5.smk
# Scripts paths
# For script: directive (resolved from rules/ directory), use relative path
SCRIPTS_STEP5_SCRIPT = "../scripts/step5"  # For script: (resolved from rules/)
SCRIPTS_UTILS_SCRIPT = "../scripts/utils"  # For script: (resolved from rules/)
# For input: directive (resolved from Snakefile), use config path
SCRIPTS_STEP5 = config["paths"]["scripts"]["step5"]  # For input: (resolved from Snakefile)
SCRIPTS_UTILS = config["paths"]["scripts"]["utils"]  # For input: (resolved from Snakefile)
FUNCTIONS_COMMON = SCRIPTS_UTILS + "/functions_common.R"  # For input: (resolved from Snakefile)

# Output directories (using full paths)
OUTPUT_STEP5 = config["paths"]["outputs"]["step5"]
OUTPUT_FIGURES = OUTPUT_STEP5 + "/figures"
OUTPUT_TABLES_CORRELATION = OUTPUT_STEP5 + "/tables/correlation"
=======
SCRIPTS_STEP5 = config["paths"]["snakemake_dir"] + "/" + config["paths"]["scripts"]["step5"]
SCRIPTS_UTILS = config["paths"]["snakemake_dir"] + "/" + config["paths"]["scripts"]["utils"]
FUNCTIONS_COMMON = SCRIPTS_UTILS + "/functions_common.R"

# Output directories (using full paths like step4)
OUTPUT_STEP5 = config["paths"]["outputs"]["step5"]
OUTPUT_FIGURES = OUTPUT_STEP5 + "/figures"
OUTPUT_TABLES_FAMILIES = OUTPUT_STEP5 + "/tables/families"
>>>>>>> 352eb6950c566304a08c8054f00dc95591ac07de:rules/step5.smk
OUTPUT_LOGS = OUTPUT_STEP5 + "/logs"

# Inputs from previous steps (using full paths)
STEP2_DATA_DIR = config["paths"]["snakemake_dir"] + "/" + config["paths"]["outputs"]["step2"]
STEP1_5_DATA_DIR = config["paths"]["snakemake_dir"] + "/" + config["paths"]["outputs"]["step1_5"]
INPUT_STEP2_STATS = STEP2_DATA_DIR + "/tables/statistical_results/S2_statistical_comparisons.csv"
INPUT_STEP1_5_FILTERED_DATA = STEP1_5_DATA_DIR + "/tables/filtered_data/ALL_MUTATIONS_VAF_FILTERED.csv"
<<<<<<< HEAD:final_analysis/pipeline_definitivo/snakemake_pipeline/rules/step5.smk
# Need raw expression data (RPM) - use step1 original or processed data
INPUT_EXPRESSION_DATA = config["paths"]["data"]["raw"]
# Note: Step 5 currently doesn't use cluster assignments, but could in future versions
# For now, clusters are not included as input to avoid unnecessary dependency

# ============================================================================
# RULE: Expression-Oxidation Correlation Analysis
# ============================================================================

rule step5_correlation_analysis:
    input:
        comparisons = INPUT_STEP2_STATS,
        filtered_data = INPUT_STEP1_5_FILTERED_DATA,
        expression_data = INPUT_EXPRESSION_DATA,
        functions = FUNCTIONS_COMMON
    output:
        correlation_table = OUTPUT_TABLES_CORRELATION + "/S5_expression_oxidation_correlation.csv",
        expression_summary = OUTPUT_TABLES_CORRELATION + "/S5_expression_summary.csv"
    params:
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/correlation_analysis.log"
    script:
        SCRIPTS_STEP5_SCRIPT + "/01_expression_oxidation_correlation.R"

# ============================================================================
# RULE: Correlation Visualization
# ============================================================================

rule step5_correlation_visualization:
    input:
        correlation_table = OUTPUT_TABLES_CORRELATION + "/S5_expression_oxidation_correlation.csv",
        expression_summary = OUTPUT_TABLES_CORRELATION + "/S5_expression_summary.csv",
        functions = FUNCTIONS_COMMON
    output:
        figure_a = OUTPUT_FIGURES + "/step5_panelA_expression_vs_oxidation.png",
        figure_b = OUTPUT_FIGURES + "/step5_panelB_expression_groups_comparison.png"
    params:
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/correlation_visualization.log"
    script:
        SCRIPTS_STEP5_SCRIPT + "/02_correlation_visualization.R"
=======

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
>>>>>>> 352eb6950c566304a08c8054f00dc95591ac07de:rules/step5.smk

# ============================================================================
# AGGREGATE RULE: All Step 5 outputs
# ============================================================================

rule all_step5:
    input:
<<<<<<< HEAD:final_analysis/pipeline_definitivo/snakemake_pipeline/rules/step5.smk
        # DEPENDENCY: Step 5 requires Step 2 (statistical comparisons) and Step 3 (clustering)
        rules.all_step2.output,
        rules.all_step3.output,
        # Correlation analysis tables
        OUTPUT_TABLES_CORRELATION + "/S5_expression_oxidation_correlation.csv",
        OUTPUT_TABLES_CORRELATION + "/S5_expression_summary.csv",
        # Figures
        OUTPUT_FIGURES + "/step5_panelA_expression_vs_oxidation.png",
        OUTPUT_FIGURES + "/step5_panelB_expression_groups_comparison.png"
=======
        # Family analysis tables
        OUTPUT_TABLES_FAMILIES + "/S5_family_summary.csv",
        OUTPUT_TABLES_FAMILIES + "/S5_family_comparison.csv",
        # Figures
        OUTPUT_FIGURES + "/step5_panelA_family_oxidation_comparison.png",
        OUTPUT_FIGURES + "/step5_panelB_family_heatmap.png"
>>>>>>> 352eb6950c566304a08c8054f00dc95591ac07de:rules/step5.smk

