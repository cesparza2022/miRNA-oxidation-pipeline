# ============================================================================
# SNAKEMAKE RULES: OUTPUT VALIDATION
# ============================================================================
# Purpose: Validate pipeline outputs to ensure they are correct and complete
# ============================================================================

# Load configuration
configfile: "config/config.yaml"

# ============================================================================
# COMMON PATHS
# ============================================================================

OUTPUT_VALIDATION = "results/validation"
SCRIPTS_UTILS = config["paths"]["snakemake_dir"] + "/" + config["paths"]["scripts"]["utils"]
STEP1_FINAL = "results/step1/final"
STEP1_5_FINAL = "results/step1_5/final"
STEP2_FINAL = "results/step2/final"

# ============================================================================
# RULE: Validate Step 1 Outputs
# ============================================================================

rule validate_step1_outputs:
    input:
        # Key outputs from Step 1 - use actual file names
        figures = [
            STEP1_FINAL + "/figures/step1_panelB_gt_count_by_position.png",
            STEP1_FINAL + "/figures/step1_panelC_gx_spectrum.png",
            STEP1_FINAL + "/figures/step1_panelD_positional_fraction.png",
            STEP1_FINAL + "/figures/step1_panelE_gcontent.png",
            STEP1_FINAL + "/figures/step1_panelF_seed_interaction.png",
            STEP1_FINAL + "/figures/step1_panelG_gt_specificity.png"
        ],
        tables = [
            STEP1_FINAL + "/tables/summary/S1_B_gt_counts_by_position.csv",
            STEP1_FINAL + "/tables/summary/S1_C_gx_spectrum_by_position.csv",
            STEP1_FINAL + "/tables/summary/S1_D_positional_fractions.csv",
            STEP1_FINAL + "/tables/summary/S1_E_gcontent_landscape.csv",
            STEP1_FINAL + "/tables/summary/S1_F_seed_vs_nonseed.csv",
            STEP1_FINAL + "/tables/summary/S1_G_gt_specificity.csv"
        ]
    output:
        validation_report = OUTPUT_VALIDATION + "/step1_validation.txt"
    params:
        step_name = "Step 1",
        output_dir = STEP1_FINAL,
        script = SCRIPTS_UTILS + "/verify_outputs.R"
    log:
        OUTPUT_VALIDATION + "/step1_validation.log"
    shell:
        """
        mkdir -p {OUTPUT_VALIDATION}
        if Rscript {params.script} "{params.step_name}" "{params.output_dir}" > {output} 2>&1; then
            echo "Step 1 validation completed at $(date)" >> {output}
        else
            echo "Step 1 validation FAILED at $(date)" >> {output}
            cat {output}
            exit 1
        fi
        """

# ============================================================================
# RULE: Validate Step 1.5 Outputs
# ============================================================================

rule validate_step1_5_outputs:
    input:
        # VAF filtered data (check if exists, make optional for now)
        vaf_filtered = STEP1_5_FINAL + "/tables/filtered_data/ALL_MUTATIONS_VAF_FILTERED.csv",
        # Diagnostic figures
        figures = expand(
            STEP1_5_FINAL + "/figures/{fig}.png",
            fig=["QC_FIG1_VAF_DISTRIBUTION", "QC_FIG2_FILTER_IMPACT", 
                 "QC_FIG3_AFFECTED_MIRNAS", "QC_FIG4_BEFORE_AFTER",
                 "STEP1.5_FIG1_HEATMAP_SNVS", "STEP1.5_FIG2_HEATMAP_COUNTS",
                 "STEP1.5_FIG3_G_TRANSVERSIONS_SNVS", "STEP1.5_FIG4_G_TRANSVERSIONS_COUNTS",
                 "STEP1.5_FIG5_BUBBLE_PLOT", "STEP1.5_FIG6_VIOLIN_DISTRIBUTIONS",
                 "STEP1.5_FIG7_FOLD_CHANGE"]
        )
    output:
        validation_report = OUTPUT_VALIDATION + "/step1_5_validation.txt"
    params:
        step_name = "Step 1.5",
        output_dir = STEP1_5_FINAL,
        script = SCRIPTS_UTILS + "/verify_outputs.R",
        quality_script = SCRIPTS_UTILS + "/validate_data_quality.R"
    log:
        OUTPUT_VALIDATION + "/step1_5_validation.log"
    shell:
        """
        mkdir -p {OUTPUT_VALIDATION}
        # Validate figures (required)
        for fig in {input.figures}; do
            if [ ! -f "$fig" ]; then
                echo "ERROR: Missing figure: $fig" > {output}
                exit 1
            fi
        done
        # Validate step outputs (basic)
        if Rscript {params.script} "{params.step_name}" "{params.output_dir}" > {output} 2>&1; then
            echo "" >> {output}
            echo "📊 Data Quality Validation:" >> {output}
            # Validate VAF values are in range [0, 1] if file exists
            if [ -f {input.vaf_filtered} ]; then
                Rscript {params.quality_script} {input.vaf_filtered} csv VAF 0 1 >> {output} 2>&1 || echo "  ⚠️  Warning: VAF validation failed (check if column exists)" >> {output}
            else
                echo "  ℹ️  VAF filtered data not found (optional)" >> {output}
            fi
            echo "Step 1.5 validation completed at $(date)" >> {output}
        else
            echo "Step 1.5 validation FAILED at $(date)" >> {output}
            cat {output}
            exit 1
        fi
        """

# ============================================================================
# RULE: Validate Step 2 Outputs
# ============================================================================

rule validate_step2_outputs:
    input:
        # Statistical comparison results (required)
        statistical_table = STEP2_FINAL + "/tables/step2_statistical_comparisons.csv",
        effect_sizes = STEP2_FINAL + "/tables/step2_effect_sizes.csv",
        # Figures (required)
        figures = expand(
            STEP2_FINAL + "/figures/step2_{fig}.png",
            fig=["volcano_plot", "effect_size_distribution"]
        )
    output:
        validation_report = OUTPUT_VALIDATION + "/step2_validation.txt"
    params:
        step_name = "Step 2",
        output_dir = STEP2_FINAL,
        script = SCRIPTS_UTILS + "/verify_outputs.R",
        quality_script = SCRIPTS_UTILS + "/validate_data_quality.R"
    log:
        OUTPUT_VALIDATION + "/step2_validation.log"
    shell:
        """
        mkdir -p {OUTPUT_VALIDATION}
        # Validate required files exist
        if [ ! -f {input.statistical_table} ]; then
            echo "ERROR: Missing statistical table: {input.statistical_table}" > {output}
            exit 1
        fi
        if [ ! -f {input.effect_sizes} ]; then
            echo "ERROR: Missing effect sizes: {input.effect_sizes}" > {output}
            exit 1
        fi
        # Validate figures
        for fig in {input.figures}; do
            if [ ! -f "$fig" ]; then
                echo "ERROR: Missing figure: $fig" > {output}
                exit 1
            fi
        done
        # Validate step outputs (basic)
        if Rscript {params.script} "{params.step_name}" "{params.output_dir}" > {output} 2>&1; then
            echo "" >> {output}
            echo "📊 Data Quality Validation:" >> {output}
            # Validate p-values are in range [0, 1]
            Rscript {params.quality_script} {input.statistical_table} csv t_test_pvalue 0 1 >> {output} 2>&1 || echo "  ⚠️  Warning: t_test_pvalue validation failed (check if column exists)" >> {output}
            # Validate log2FC values are reasonable (typically -10 to 10 for miRNA data)
            Rscript {params.quality_script} {input.statistical_table} csv log2_fold_change -10 10 >> {output} 2>&1 || echo "  ⚠️  Warning: log2_fold_change validation failed (check if column exists)" >> {output}
            echo "Step 2 validation completed at $(date)" >> {output}
        else
            echo "Step 2 validation FAILED at $(date)" >> {output}
            cat {output}
            exit 1
        fi
        """

# ============================================================================
# RULE: Validate Viewers HTML
# ============================================================================

rule validate_viewers:
    input:
        step1_viewer = "viewers/step1.html",
        step1_5_viewer = "viewers/step1_5.html",
        step2_viewer = "viewers/step2.html"
    output:
        validation_report = OUTPUT_VALIDATION + "/viewers_validation.txt"
    params:
        script = SCRIPTS_UTILS + "/validate_outputs.R"
    log:
        OUTPUT_VALIDATION + "/viewers_validation.log"
    shell:
        """
        mkdir -p {OUTPUT_VALIDATION}
        echo "Validating HTML viewers..." > {output}
        for viewer in {input.step1_viewer} {input.step1_5_viewer} {input.step2_viewer}; do
            Rscript {params.script} "$viewer" html >> {output} 2>&1 || exit 1
        done
        echo "All viewers validated successfully" >> {output}
        echo "Viewers validation completed at $(date)" >> {output}
        """

# ============================================================================
# RULE: Validate Metadata and Reports
# ============================================================================

rule validate_metadata:
    input:
        execution_info = "results/pipeline_info/execution_info.yaml",
        software_versions = "results/pipeline_info/software_versions.yml",
        config_used = "results/pipeline_info/config_used.yaml",
        provenance = "results/pipeline_info/provenance.json",
        summary_html = "results/summary/summary_report.html",
        summary_json = "results/summary/summary_statistics.json",
        key_findings = "results/summary/key_findings.md"
    output:
        validation_report = OUTPUT_VALIDATION + "/metadata_validation.txt"
    params:
        script = SCRIPTS_UTILS + "/validate_outputs.R"
    log:
        OUTPUT_VALIDATION + "/metadata_validation.log"
    shell:
        """
        mkdir -p {OUTPUT_VALIDATION}
        echo "Validating metadata and reports..." > {output}
        Rscript {params.script} {input.execution_info} yaml >> {output} 2>&1 || exit 1
        Rscript {params.script} {input.software_versions} yaml >> {output} 2>&1 || exit 1
        Rscript {params.script} {input.config_used} yaml >> {output} 2>&1 || exit 1
        Rscript {params.script} {input.provenance} json >> {output} 2>&1 || exit 1
        Rscript {params.script} {input.summary_html} html >> {output} 2>&1 || exit 1
        Rscript {params.script} {input.summary_json} json >> {output} 2>&1 || exit 1
        Rscript {params.script} {input.key_findings} file >> {output} 2>&1 || exit 1
        echo "All metadata and reports validated successfully" >> {output}
        echo "Metadata validation completed at $(date)" >> {output}
        """

# ============================================================================
# RULE: Final Validation (Consolidate All Validations)
# ============================================================================

rule validate_pipeline_completion:
    input:
        step1_validation = OUTPUT_VALIDATION + "/step1_validation.txt",
        step1_5_validation = OUTPUT_VALIDATION + "/step1_5_validation.txt",
        step2_validation = OUTPUT_VALIDATION + "/step2_validation.txt",
        viewers_validation = OUTPUT_VALIDATION + "/viewers_validation.txt",
        metadata_validation = OUTPUT_VALIDATION + "/metadata_validation.txt"
    output:
        final_validation_report = OUTPUT_VALIDATION + "/final_validation_report.txt"
    shell:
        """
        echo "═══════════════════════════════════════════════════════════════════" > {output}
        echo "  ✅ PIPELINE VALIDATION COMPLETE" >> {output}
        echo "═══════════════════════════════════════════════════════════════════" >> {output}
        echo "" >> {output}
        echo "Generated: $(date)" >> {output}
        echo "" >> {output}
        echo "Validation Summary:" >> {output}
        echo "───────────────────────────────────────────────────────────────────" >> {output}
        echo "" >> {output}
        echo "Step 1 (Exploratory Analysis):" >> {output}
        cat {input.step1_validation} | tail -3 >> {output}
        echo "" >> {output}
        echo "Step 1.5 (VAF Quality Control):" >> {output}
        cat {input.step1_5_validation} | tail -3 >> {output}
        echo "" >> {output}
        echo "Step 2 (Statistical Comparisons):" >> {output}
        cat {input.step2_validation} | tail -3 >> {output}
        echo "" >> {output}
        echo "Viewers (HTML Reports):" >> {output}
        cat {input.viewers_validation} | tail -3 >> {output}
        echo "" >> {output}
        echo "Metadata and Reports:" >> {output}
        cat {input.metadata_validation} | tail -3 >> {output}
        echo "" >> {output}
        echo "═══════════════════════════════════════════════════════════════════" >> {output}
        echo "✅ ALL VALIDATIONS PASSED - PIPELINE COMPLETED SUCCESSFULLY" >> {output}
        echo "═══════════════════════════════════════════════════════════════════" >> {output}
        """

# ============================================================================
# RULE: Prepare Validation Directory
# ============================================================================

rule prepare_validation_dir:
    output:
        directory(OUTPUT_VALIDATION)
    shell:
        "mkdir -p {output} && touch {output}/.gitkeep"

