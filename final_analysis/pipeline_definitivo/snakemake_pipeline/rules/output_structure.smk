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
        structure_created = touch("results/.structure_created")
    params:
        script = SCRIPTS_UTILS + "/create_output_structure.R"
    shell:
        """
        # Create output structure using R script or fallback
        if command -v Rscript &> /dev/null; then
            Rscript {params.script} results || {
                echo "Rscript failed, using fallback method..."
                mkdir -p results/step1/final/{figures,tables/summary,logs,logs/benchmarks}
                mkdir -p results/step1/intermediate
                mkdir -p results/step1_5/final/{figures,tables/filtered_data,tables/filter_report,tables/statistics,logs,logs/benchmarks}
                mkdir -p results/step1_5/intermediate
                mkdir -p results/step2/final/{figures,figures_clean,tables/statistical_results,tables/summary,logs,logs/benchmarks}
                mkdir -p results/step2/intermediate
                mkdir -p results/{pipeline_info,summary,validation,viewers}
            }
        else
            echo "Creating output structure manually..."
            mkdir -p results/step1/final/{figures,tables/summary,logs,logs/benchmarks}
            mkdir -p results/step1/intermediate
            mkdir -p results/step1_5/final/{figures,tables/filtered_data,tables/filter_report,tables/statistics,logs,logs/benchmarks}
            mkdir -p results/step1_5/intermediate
            mkdir -p results/step2/final/{figures,figures_clean,tables/statistical_results,tables/summary,logs,logs/benchmarks}
            mkdir -p results/step2/intermediate
            mkdir -p results/step3/final/{figures,tables/functional,logs,logs/benchmarks}
            mkdir -p results/step3/intermediate
            mkdir -p results/step4/final/{figures,tables/biomarkers,logs,logs/benchmarks}
            mkdir -p results/step4/intermediate
            mkdir -p results/{pipeline_info,summary,validation,viewers}
        fi
        touch {output.structure_created}
        echo "✅ Output structure created successfully"
        """

