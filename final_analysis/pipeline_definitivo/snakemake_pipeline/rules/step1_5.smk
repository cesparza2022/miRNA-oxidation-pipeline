# ============================================================================
# SNAKEMAKE RULES: STEP 1.5 - VAF Quality Control
# ============================================================================
# Rules for VAF filtering and diagnostic figure generation

# Load configuration
configfile: "config/config.yaml"

# ============================================================================
# COMMON PATHS AND PARAMETERS
# ============================================================================

# Input data path (original data for VAF calculation)
INPUT_DATA_ORIGINAL = config["paths"]["data"]["step1_original"]

# Output directories
OUTPUT_STEP1_5 = config["paths"]["outputs"]["step1_5"]
OUTPUT_FIGURES = OUTPUT_STEP1_5 + "/figures"
OUTPUT_FIGURES_QC = OUTPUT_FIGURES + "/qc"
OUTPUT_FIGURES_DIAGNOSTIC = OUTPUT_FIGURES + "/diagnostic"
OUTPUT_TABLES = OUTPUT_STEP1_5 + "/tables"
OUTPUT_TABLES_FILTERED_DATA = OUTPUT_TABLES + "/filtered_data"
OUTPUT_TABLES_FILTER_REPORT = OUTPUT_TABLES + "/filter_report"
OUTPUT_TABLES_SUMMARY = OUTPUT_TABLES + "/summary"
OUTPUT_LOGS = OUTPUT_STEP1_5 + "/logs"

# Scripts directory
SCRIPTS_STEP1_5 = config["paths"]["snakemake_dir"] + "/" + config["paths"]["scripts"]["step1_5"]

# ============================================================================
# RULE 1: Apply VAF Filter
# ============================================================================
# Filters out technical artifacts (VAF >= 0.5)
# Input: step1_original_data.csv (with SNV counts and total counts)
# Outputs: 4 CSV tables

rule apply_vaf_filter:
    input:
        data = INPUT_DATA_ORIGINAL
    output:
        filtered_data = OUTPUT_TABLES_FILTERED_DATA + "/ALL_MUTATIONS_VAF_FILTERED.csv",
        filter_report = OUTPUT_TABLES_FILTER_REPORT + "/S1.5_filter_report.csv",
        stats_by_type = OUTPUT_TABLES_FILTER_REPORT + "/S1.5_stats_by_type.csv",
        stats_by_mirna = OUTPUT_TABLES_FILTER_REPORT + "/S1.5_stats_by_mirna.csv"
    log:
        OUTPUT_LOGS + "/apply_vaf_filter.log"
    # conda:
    #     "envs/r_analysis.yaml"  # Disabled - using local R
    script:
        SCRIPTS_STEP1_5 + "/01_apply_vaf_filter.R"

# ============================================================================
# RULE 2: Generate Diagnostic Figures
# ============================================================================
# Generates 11 figures (4 QC + 7 diagnostic) and 3 summary tables
# Inputs: 4 CSV tables from Rule 1
# Outputs: 11 PNG figures + 3 CSV tables

rule generate_diagnostic_figures:
    input:
        filtered_data = rules.apply_vaf_filter.output.filtered_data,
        filter_report = rules.apply_vaf_filter.output.filter_report,
        stats_by_type = rules.apply_vaf_filter.output.stats_by_type,
        stats_by_mirna = rules.apply_vaf_filter.output.stats_by_mirna
    output:
        # QC Figures (4)
        qc_fig1 = OUTPUT_FIGURES_QC + "/QC_FIG1_VAF_DISTRIBUTION.png",
        qc_fig2 = OUTPUT_FIGURES_QC + "/QC_FIG2_FILTER_IMPACT.png",
        qc_fig3 = OUTPUT_FIGURES_QC + "/QC_FIG3_AFFECTED_MIRNAS.png",
        qc_fig4 = OUTPUT_FIGURES_QC + "/QC_FIG4_BEFORE_AFTER.png",
        # Diagnostic Figures (7)
        diag_fig1 = OUTPUT_FIGURES_DIAGNOSTIC + "/STEP1.5_FIG1_HEATMAP_SNVS.png",
        diag_fig2 = OUTPUT_FIGURES_DIAGNOSTIC + "/STEP1.5_FIG2_HEATMAP_COUNTS.png",
        diag_fig3 = OUTPUT_FIGURES_DIAGNOSTIC + "/STEP1.5_FIG3_G_TRANSVERSIONS_SNVS.png",
        diag_fig4 = OUTPUT_FIGURES_DIAGNOSTIC + "/STEP1.5_FIG4_G_TRANSVERSIONS_COUNTS.png",
        diag_fig5 = OUTPUT_FIGURES_DIAGNOSTIC + "/STEP1.5_FIG5_BUBBLE_PLOT.png",
        diag_fig6 = OUTPUT_FIGURES_DIAGNOSTIC + "/STEP1.5_FIG6_VIOLIN_DISTRIBUTIONS.png",
        diag_fig7 = OUTPUT_FIGURES_DIAGNOSTIC + "/STEP1.5_FIG7_FOLD_CHANGE.png",
        # Summary Tables (3)
        sample_metrics = OUTPUT_TABLES_SUMMARY + "/S1.5_sample_metrics.csv",
        position_metrics = OUTPUT_TABLES_SUMMARY + "/S1.5_position_metrics.csv",
        mutation_summary = OUTPUT_TABLES_SUMMARY + "/S1.5_mutation_type_summary.csv"
    log:
        OUTPUT_LOGS + "/generate_diagnostic_figures.log"
    # conda:
    #     "envs/r_analysis.yaml"  # Disabled - using local R
    script:
        SCRIPTS_STEP1_5 + "/02_generate_diagnostic_figures.R"

# ============================================================================
# RULE: All Step 1.5 outputs (aggregator)
# ============================================================================

rule all_step1_5:
    input:
        # All figures (11 total)
        OUTPUT_FIGURES_QC + "/QC_FIG1_VAF_DISTRIBUTION.png",
        OUTPUT_FIGURES_QC + "/QC_FIG2_FILTER_IMPACT.png",
        OUTPUT_FIGURES_QC + "/QC_FIG3_AFFECTED_MIRNAS.png",
        OUTPUT_FIGURES_QC + "/QC_FIG4_BEFORE_AFTER.png",
        OUTPUT_FIGURES_DIAGNOSTIC + "/STEP1.5_FIG1_HEATMAP_SNVS.png",
        OUTPUT_FIGURES_DIAGNOSTIC + "/STEP1.5_FIG2_HEATMAP_COUNTS.png",
        OUTPUT_FIGURES_DIAGNOSTIC + "/STEP1.5_FIG3_G_TRANSVERSIONS_SNVS.png",
        OUTPUT_FIGURES_DIAGNOSTIC + "/STEP1.5_FIG4_G_TRANSVERSIONS_COUNTS.png",
        OUTPUT_FIGURES_DIAGNOSTIC + "/STEP1.5_FIG5_BUBBLE_PLOT.png",
        OUTPUT_FIGURES_DIAGNOSTIC + "/STEP1.5_FIG6_VIOLIN_DISTRIBUTIONS.png",
        OUTPUT_FIGURES_DIAGNOSTIC + "/STEP1.5_FIG7_FOLD_CHANGE.png",
        # All tables (7 total: 1 filtered data + 3 filter reports + 3 summaries)
        OUTPUT_TABLES_FILTERED_DATA + "/ALL_MUTATIONS_VAF_FILTERED.csv",
        OUTPUT_TABLES_FILTER_REPORT + "/S1.5_filter_report.csv",
        OUTPUT_TABLES_FILTER_REPORT + "/S1.5_stats_by_type.csv",
        OUTPUT_TABLES_FILTER_REPORT + "/S1.5_stats_by_mirna.csv",
        OUTPUT_TABLES_SUMMARY + "/S1.5_sample_metrics.csv",
        OUTPUT_TABLES_SUMMARY + "/S1.5_position_metrics.csv",
        OUTPUT_TABLES_SUMMARY + "/S1.5_mutation_type_summary.csv"
