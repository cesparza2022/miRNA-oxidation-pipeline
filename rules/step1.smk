# ============================================================================
# SNAKEMAKE RULES: STEP 1 - Exploratory Analysis
# ============================================================================
# Rules for generating figures and tables from Step 1 analysis

# Load configuration
configfile: "config/config.yaml"

# ============================================================================
# COMMON PATHS AND PARAMETERS
# ============================================================================

# Input data paths
INPUT_DATA_CLEAN = config["paths"]["data"]["processed_clean"]
INPUT_DATA_RAW = config["paths"]["data"]["raw"]

# Output directories
OUTPUT_STEP1 = config["paths"]["outputs"]["step1"]
OUTPUT_FIGURES = OUTPUT_STEP1 + "/figures"
OUTPUT_TABLES = OUTPUT_STEP1 + "/tables"
OUTPUT_TABLES_SUMMARY = OUTPUT_TABLES + "/summary"
OUTPUT_LOGS = OUTPUT_STEP1 + "/logs"

# Scripts directory (already relative to snakemake_dir from config)
# Note: In Snakemake, paths are resolved from the Snakefile directory
SCRIPTS_STEP1 = config["paths"]["snakemake_dir"] + "/" + config["paths"]["scripts"]["step1"]
SCRIPTS_UTILS = config["paths"]["snakemake_dir"] + "/" + config["paths"]["scripts"]["utils"]

# Common parameters
FUNCTIONS_COMMON = SCRIPTS_UTILS + "/functions_common.R"

# ============================================================================
# RULE: Panel B - G>T Count by Position (uses CLEAN data)
# ============================================================================

rule panel_b_gt_count_by_position:
    input:
        data = INPUT_DATA_CLEAN,
        functions = FUNCTIONS_COMMON
    output:
        figure = OUTPUT_FIGURES + "/step1_panelB_gt_count_by_position.png",
        table = OUTPUT_TABLES_SUMMARY + "/S1_B_gt_counts_by_position.csv"
    params:
        functions = FUNCTIONS_COMMON
    benchmark:
        OUTPUT_LOGS + "/benchmarks/panel_b.txt"
    # conda:
    #     "envs/r_analysis.yaml"  # Disabled - using local R
    log:
        OUTPUT_LOGS + "/panel_b.log"
    script:
        SCRIPTS_STEP1 + "/01_panel_b_gt_count_by_position.R"

# ============================================================================
# RULE: Panel C - G>X Mutation Spectrum by Position (uses processed_clean for consistency)
# ============================================================================

rule panel_c_gx_spectrum:
    input:
        data = INPUT_DATA_CLEAN,  # ✅ CORREGIDO: Usa processed_clean para consistencia
        functions = FUNCTIONS_COMMON
    output:
        figure = OUTPUT_FIGURES + "/step1_panelC_gx_spectrum.png",
        table = OUTPUT_TABLES_SUMMARY + "/S1_C_gx_spectrum_by_position.csv"
    params:
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/panel_c.log"
    # conda:
    #     "envs/r_analysis.yaml"  # Disabled - using local R
    script:
        SCRIPTS_STEP1 + "/02_panel_c_gx_spectrum.R"

# ============================================================================
# RULE: Panel D - Positional Fraction of Mutations (uses processed_clean for consistency)
# ============================================================================

rule panel_d_positional_fraction:
    input:
        data = INPUT_DATA_CLEAN,  # ✅ CORREGIDO: Usa processed_clean para consistencia
        functions = FUNCTIONS_COMMON
    output:
        figure = OUTPUT_FIGURES + "/step1_panelD_positional_fraction.png",
        table = OUTPUT_TABLES_SUMMARY + "/S1_D_positional_fractions.csv"
    params:
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/panel_d.log"
    # conda:
    #     "envs/r_analysis.yaml"  # Disabled - using local R
    script:
        SCRIPTS_STEP1 + "/03_panel_d_positional_fraction.R"

# ============================================================================
# RULE: Panel E - G-Content Landscape (uses CLEAN data)
# ============================================================================

rule panel_e_gcontent:
    input:
        data = INPUT_DATA_CLEAN,
        functions = FUNCTIONS_COMMON
    output:
        figure = OUTPUT_FIGURES + "/step1_panelE_gcontent.png",
        table = OUTPUT_TABLES_SUMMARY + "/S1_E_gcontent_landscape.csv"
    params:
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/panel_e.log"
    # conda:
    #     "envs/r_analysis.yaml"  # Disabled - using local R
    script:
        SCRIPTS_STEP1 + "/04_panel_e_gcontent.R"

# ============================================================================
# RULE: Panel F - Seed vs Non-seed Comparison (uses CLEAN data)
# ============================================================================

rule panel_f_seed_vs_nonseed:
    input:
        data = INPUT_DATA_CLEAN,
        functions = FUNCTIONS_COMMON
    output:
        figure = OUTPUT_FIGURES + "/step1_panelF_seed_interaction.png",
        table = OUTPUT_TABLES_SUMMARY + "/S1_F_seed_vs_nonseed.csv"
    params:
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/panel_f.log"
    # conda:
    #     "envs/r_analysis.yaml"  # Disabled - using local R
    script:
        SCRIPTS_STEP1 + "/05_panel_f_seed_vs_nonseed.R"

# ============================================================================
# RULE: Panel G - G>T Specificity (uses CLEAN data)
# ============================================================================

rule panel_g_gt_specificity:
    input:
        data = INPUT_DATA_CLEAN,
        functions = FUNCTIONS_COMMON
    output:
        figure = OUTPUT_FIGURES + "/step1_panelG_gt_specificity.png",
        table = OUTPUT_TABLES_SUMMARY + "/S1_G_gt_specificity.csv"
    params:
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/panel_g.log"
    # conda:
    #     "envs/r_analysis.yaml"  # Disabled - using local R
    script:
        SCRIPTS_STEP1 + "/06_panel_g_gt_specificity.R"

# ============================================================================
# RULE: All Step 1 outputs (aggregator)
# ============================================================================

rule all_step1:
    input:
        OUTPUT_FIGURES + "/step1_panelB_gt_count_by_position.png",
        OUTPUT_FIGURES + "/step1_panelC_gx_spectrum.png",
        OUTPUT_FIGURES + "/step1_panelD_positional_fraction.png",
        OUTPUT_FIGURES + "/step1_panelE_gcontent.png",
        OUTPUT_FIGURES + "/step1_panelF_seed_interaction.png",
        OUTPUT_FIGURES + "/step1_panelG_gt_specificity.png"
