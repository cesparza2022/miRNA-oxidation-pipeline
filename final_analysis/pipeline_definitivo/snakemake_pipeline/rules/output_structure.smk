# ============================================================================
# SNAKEMAKE RULES: OUTPUT STRUCTURE
# ============================================================================
# Purpose: Ensure output directories are created automatically
# ============================================================================

# Load configuration
configfile: "config/config.yaml"

# ============================================================================
# COMMON PATHS
# ============================================================================

SCRIPTS_UTILS = config["paths"]["snakemake_dir"] + "/" + config["paths"]["scripts"]["utils"]

# ============================================================================
# RULE: Create Output Structure
# ============================================================================

rule create_output_structure:
    output:
        directory("results/step1/final/figures"),
        directory("results/step1/final/tables/summary"),
        directory("results/step1/final/logs"),
        directory("results/step1_5/final/figures"),
        directory("results/step1_5/final/tables/filtered_data"),
        directory("results/step1_5/final/logs"),
        directory("results/step2/final/figures"),
        directory("results/step2/final/tables/statistical_results"),
        directory("results/step2/final/logs"),
        directory("results/pipeline_info"),
        directory("results/summary"),
        directory("results/validation"),
        directory("viewers")
    params:
        script = SCRIPTS_UTILS + "/create_output_structure.R"
    shell:
        """
        Rscript {params.script} results || {
            # Fallback: create manually
            mkdir -p results/step1/final/{figures,tables/summary,logs,logs/benchmarks}
            mkdir -p results/step1/intermediate
            mkdir -p results/step1_5/final/{figures,tables/filtered_data,tables/filter_report,tables/statistics,logs,logs/benchmarks}
            mkdir -p results/step1_5/intermediate
            mkdir -p results/step2/final/{figures,figures_clean,tables/statistical_results,tables/summary,logs,logs/benchmarks}
            mkdir -p results/step2/intermediate
            mkdir -p results/{pipeline_info,summary,validation,viewers}
        }
        """

