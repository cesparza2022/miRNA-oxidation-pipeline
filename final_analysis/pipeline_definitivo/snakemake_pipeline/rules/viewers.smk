# ============================================================================
# SNAKEMAKE RULES: VIEWERS HTML
# ============================================================================
# Rules for generating HTML viewers for each step

# Load configuration
configfile: "config/config.yaml"

# ============================================================================
# COMMON PATHS
# ============================================================================

OUTPUT_STEP1 = config["paths"]["outputs"]["step1"]
OUTPUT_FIGURES_STEP1 = OUTPUT_STEP1 + "/figures"
OUTPUT_TABLES_STEP1 = OUTPUT_STEP1 + "/tables"

OUTPUT_STEP1_5 = config["paths"]["outputs"]["step1_5"]
OUTPUT_FIGURES_STEP1_5 = OUTPUT_STEP1_5 + "/figures"
OUTPUT_TABLES_STEP1_5 = OUTPUT_STEP1_5 + "/tables"

OUTPUT_VIEWERS = config["paths"]["viewers"]
OUTPUT_STEP2 = config["paths"]["outputs"]["step2"]
OUTPUT_STEP2_FIGURES = OUTPUT_STEP2 + "/figures"
OUTPUT_STEP2_TABLES = OUTPUT_STEP2 + "/tables"
SCRIPTS_UTILS = config["paths"]["snakemake_dir"] + "/" + config["paths"]["scripts"]["utils"]

# ============================================================================
# RULE: Generate Step 1 HTML Viewer
# ============================================================================

rule generate_step1_viewer:
    input:
        # All figures from Step 1
        figure_b = OUTPUT_FIGURES_STEP1 + "/step1_panelB_gt_count_by_position.png",
        figure_c = OUTPUT_FIGURES_STEP1 + "/step1_panelC_gx_spectrum.png",
        figure_d = OUTPUT_FIGURES_STEP1 + "/step1_panelD_positional_fraction.png",
        figure_e = OUTPUT_FIGURES_STEP1 + "/step1_panelE_gcontent.png",
        figure_f = OUTPUT_FIGURES_STEP1 + "/step1_panelF_seed_interaction.png",
        figure_g = OUTPUT_FIGURES_STEP1 + "/step1_panelG_gt_specificity.png"
    output:
        html = OUTPUT_VIEWERS + "/step1.html"
    params:
        figures_dir = OUTPUT_FIGURES_STEP1,
        tables_dir = OUTPUT_TABLES_STEP1
    log:
        OUTPUT_STEP1 + "/logs/viewer_step1.log"
    script:
        SCRIPTS_UTILS + "/build_step1_viewer.R"

# ============================================================================
# RULE: Generate Step 1.5 HTML Viewer
# ============================================================================

rule generate_step1_5_viewer:
    input:
        # All QC figures (4)
        qc_fig1 = OUTPUT_FIGURES_STEP1_5 + "/QC_FIG1_VAF_DISTRIBUTION.png",
        qc_fig2 = OUTPUT_FIGURES_STEP1_5 + "/QC_FIG2_FILTER_IMPACT.png",
        qc_fig3 = OUTPUT_FIGURES_STEP1_5 + "/QC_FIG3_AFFECTED_MIRNAS.png",
        qc_fig4 = OUTPUT_FIGURES_STEP1_5 + "/QC_FIG4_BEFORE_AFTER.png",
        # All diagnostic figures (7)
        diag_fig1 = OUTPUT_FIGURES_STEP1_5 + "/STEP1.5_FIG1_HEATMAP_SNVS.png",
        diag_fig2 = OUTPUT_FIGURES_STEP1_5 + "/STEP1.5_FIG2_HEATMAP_COUNTS.png",
        diag_fig3 = OUTPUT_FIGURES_STEP1_5 + "/STEP1.5_FIG3_G_TRANSVERSIONS_SNVS.png",
        diag_fig4 = OUTPUT_FIGURES_STEP1_5 + "/STEP1.5_FIG4_G_TRANSVERSIONS_COUNTS.png",
        diag_fig5 = OUTPUT_FIGURES_STEP1_5 + "/STEP1.5_FIG5_BUBBLE_PLOT.png",
        diag_fig6 = OUTPUT_FIGURES_STEP1_5 + "/STEP1.5_FIG6_VIOLIN_DISTRIBUTIONS.png",
        diag_fig7 = OUTPUT_FIGURES_STEP1_5 + "/STEP1.5_FIG7_FOLD_CHANGE.png"
    output:
        html = OUTPUT_VIEWERS + "/step1_5.html"
    params:
        figures_dir = OUTPUT_FIGURES_STEP1_5,
        tables_dir = OUTPUT_TABLES_STEP1_5
    log:
        OUTPUT_STEP1_5 + "/logs/viewer_step1_5.log"
    script:
        SCRIPTS_UTILS + "/build_step1_5_viewer.R"

# ============================================================================
# RULE: Generate Step 2 HTML Viewer
# ============================================================================

rule generate_step2_viewer:
    input:
        comparisons = OUTPUT_STEP2_TABLES + "/statistical_results/S2_statistical_comparisons.csv",
        volcano = OUTPUT_STEP2_FIGURES + "/step2_volcano_plot.png",
        effect_sizes = OUTPUT_STEP2_TABLES + "/statistical_results/S2_effect_sizes.csv",
        effect_size_plot = OUTPUT_STEP2_FIGURES + "/step2_effect_size_distribution.png"
    output:
        viewer = OUTPUT_VIEWERS + "/step2.html"
    log:
        OUTPUT_STEP2 + "/logs/viewer_step2.log"
    script:
        SCRIPTS_UTILS + "/build_step2_viewer.R"
