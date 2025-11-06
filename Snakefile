# ============================================================================
# SNAKEMAKE PIPELINE: miRNA Oxidation Analysis
# ============================================================================
# Main orchestrator for the complete analysis pipeline
#
# Usage:
#   snakemake -j 1              # Run all
#   snakemake -j 1 all_step1    # Run only Step 1
#   snakemake -n                # Dry-run (see what would run)
# ============================================================================

# Load configuration
configfile: "config/config.yaml"

# Include step-specific rule files
include: "rules/output_structure.smk"  # Auto-create output directories
include: "rules/step1.smk"
include: "rules/step1_5.smk"  # VAF Quality Control
include: "rules/step2.smk"    # Statistical Comparisons (ALS vs Control)
# REORDERED: Logical flow after statistical comparisons
include: "rules/step7.smk"    # Clustering Analysis (discovers groups with similar patterns)
include: "rules/step5.smk"    # miRNA Family Analysis (compares clusters with biological families)
include: "rules/step6.smk"    # Expression vs Oxidation Correlation (examines expression relationships)
include: "rules/step3.smk"    # Functional Analysis (analyzes functional implications with context)
include: "rules/step4.smk"    # Biomarker Analysis (integrates all previous insights)
# Viewers HTML removed - output is organized in folders with figures and tables
include: "rules/pipeline_info.smk"  # FASE 2: Pipeline metadata generation
include: "rules/summary.smk"  # FASE 3: Consolidated summary reports
include: "rules/validation.smk"  # Output validation and final checks

# ============================================================================
# DEFAULT TARGET (when running just 'snakemake')
# ============================================================================

rule all:
    input:
        rules.create_output_structure.output,  # Ensure output directories exist
        rules.all_step1.output,
        rules.all_step1_5.output,  # VAF Quality Control
        rules.all_step2.output,    # Statistical Comparisons
            # REORDERED: Logical flow - structure discovery before functional interpretation
            rules.all_step7.output,    # Clustering Analysis (discovers groups)
            rules.all_step5.output,    # miRNA Family Analysis (compares with biological families)
            rules.all_step6.output,    # Expression Correlation (examines expression relationships)
            rules.all_step3.output,    # Functional Analysis (functional implications with context)
            rules.all_step4.output,    # Biomarker Analysis (integrates all insights)
        rules.generate_pipeline_info.output,  # FASE 2: Pipeline metadata
        rules.generate_summary_report.output,  # FASE 3: Summary reports
        rules.validate_pipeline_completion.output  # Final validation report


