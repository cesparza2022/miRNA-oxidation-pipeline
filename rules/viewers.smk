# ============================================================================
# SNAKEMAKE RULES: VIEWERS HTML
# ============================================================================
# Rules for generating HTML viewers for each step

# Load configuration
configfile: "config/config.yaml"

# ============================================================================
# COMMON PATHS
# ============================================================================

OUTPUT_STEP1 = config["paths"]["snakemake_dir"] + "/" + config["paths"]["outputs"]["step1"]
OUTPUT_FIGURES_STEP1 = OUTPUT_STEP1 + "/figures"
OUTPUT_TABLES_STEP1 = OUTPUT_STEP1 + "/tables"

OUTPUT_STEP1_5 = config["paths"]["snakemake_dir"] + "/" + config["paths"]["outputs"]["step1_5"]
OUTPUT_FIGURES_STEP1_5 = OUTPUT_STEP1_5 + "/figures"
OUTPUT_TABLES_STEP1_5 = OUTPUT_STEP1_5 + "/tables"

OUTPUT_VIEWERS = config["paths"]["viewers"]
OUTPUT_STEP2 = config["paths"]["snakemake_dir"] + "/" + config["paths"]["outputs"]["step2"]
OUTPUT_STEP2_FIGURES = OUTPUT_STEP2 + "/figures"
OUTPUT_STEP2_TABLES = OUTPUT_STEP2 + "/tables"

OUTPUT_STEP3 = config["paths"]["snakemake_dir"] + "/" + config["paths"]["outputs"]["step3"]
OUTPUT_STEP3_FIGURES = OUTPUT_STEP3 + "/figures"
OUTPUT_STEP3_TABLES = OUTPUT_STEP3 + "/tables"

OUTPUT_STEP4 = config["paths"]["snakemake_dir"] + "/" + config["paths"]["outputs"]["step4"]
OUTPUT_STEP4_FIGURES = OUTPUT_STEP4 + "/figures"
OUTPUT_STEP4_TABLES = OUTPUT_STEP4 + "/tables"

OUTPUT_STEP5 = config["paths"]["snakemake_dir"] + "/" + config["paths"]["outputs"]["step5"]
OUTPUT_STEP5_FIGURES = OUTPUT_STEP5 + "/figures"
OUTPUT_STEP5_TABLES = OUTPUT_STEP5 + "/tables"

OUTPUT_STEP6 = config["paths"]["snakemake_dir"] + "/" + config["paths"]["outputs"]["step6"]
OUTPUT_STEP6_FIGURES = OUTPUT_STEP6 + "/figures"
OUTPUT_STEP6_TABLES = OUTPUT_STEP6 + "/tables"

OUTPUT_STEP7 = config["paths"]["snakemake_dir"] + "/" + config["paths"]["outputs"]["step7"]
OUTPUT_STEP7_FIGURES = OUTPUT_STEP7 + "/figures"
OUTPUT_STEP7_TABLES = OUTPUT_STEP7 + "/tables"

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

# ============================================================================
# RULE: Generate Step 3 HTML Viewer
# ============================================================================

rule generate_step3_viewer:
    input:
        figure_a = OUTPUT_STEP3_FIGURES + "/step3_panelA_pathway_enrichment.png",
        figure_b = OUTPUT_STEP3_FIGURES + "/step3_panelB_als_genes_impact.png",
        figure_c = OUTPUT_STEP3_FIGURES + "/step3_panelC_target_comparison.png",
        figure_d = OUTPUT_STEP3_FIGURES + "/step3_panelD_position_impact.png",
        pathway_heatmap = OUTPUT_STEP3_FIGURES + "/step3_pathway_enrichment_heatmap.png"
    output:
        html = OUTPUT_VIEWERS + "/step3.html"
    params:
        figures_dir = OUTPUT_STEP3_FIGURES,
        tables_dir = OUTPUT_STEP3_TABLES
    log:
        OUTPUT_STEP3 + "/logs/viewer_step3.log"
    script:
        SCRIPTS_UTILS + "/build_step3_viewer.R"

# ============================================================================
# RULE: Generate Step 4 HTML Viewer
# ============================================================================

rule generate_step4_viewer:
    input:
        roc_figure = OUTPUT_STEP4_FIGURES + "/step4_roc_curves.png",
        heatmap_figure = OUTPUT_STEP4_FIGURES + "/step4_biomarker_signature_heatmap.png"
    output:
        html = OUTPUT_VIEWERS + "/step4.html"
    params:
        figures_dir = OUTPUT_STEP4_FIGURES,
        tables_dir = OUTPUT_STEP4_TABLES
    log:
        OUTPUT_STEP4 + "/logs/viewer_step4.log"
    script:
        SCRIPTS_UTILS + "/build_step4_viewer.R"

# ============================================================================
# RULE: Generate Step 5 HTML Viewer
# ============================================================================

rule generate_step5_viewer:
    input:
        figure_a = OUTPUT_STEP5_FIGURES + "/step5_panelA_family_oxidation_comparison.png",
        figure_b = OUTPUT_STEP5_FIGURES + "/step5_panelB_family_heatmap.png"
    output:
        html = OUTPUT_VIEWERS + "/step5.html"
    params:
        figures_dir = OUTPUT_STEP5_FIGURES,
        tables_dir = OUTPUT_STEP5_TABLES
    log:
        OUTPUT_STEP5 + "/logs/viewer_step5.log"
    script:
        SCRIPTS_UTILS + "/build_step5_viewer.R"

# ============================================================================
# RULE: Generate Step 6 HTML Viewer
# ============================================================================

rule generate_step6_viewer:
    input:
        figure_a = OUTPUT_STEP6_FIGURES + "/step6_panelA_expression_vs_oxidation.png",
        figure_b = OUTPUT_STEP6_FIGURES + "/step6_panelB_expression_groups_comparison.png"
    output:
        html = OUTPUT_VIEWERS + "/step6.html"
    params:
        figures_dir = OUTPUT_STEP6_FIGURES,
        tables_dir = OUTPUT_STEP6_TABLES
    log:
        OUTPUT_STEP6 + "/logs/viewer_step6.log"
    script:
        SCRIPTS_UTILS + "/build_step6_viewer.R"

# ============================================================================
# RULE: Generate Step 7 HTML Viewer
# ============================================================================

rule generate_step7_viewer:
    input:
        figure_a = OUTPUT_STEP7_FIGURES + "/step7_panelA_cluster_heatmap.png",
        figure_b = OUTPUT_STEP7_FIGURES + "/step7_panelB_cluster_dendrogram.png"
    output:
        html = OUTPUT_VIEWERS + "/step7.html"
    params:
        figures_dir = OUTPUT_STEP7_FIGURES,
        tables_dir = OUTPUT_STEP7_TABLES
    log:
        OUTPUT_STEP7 + "/logs/viewer_step7.log"
    script:
        SCRIPTS_UTILS + "/build_step7_viewer.R"

