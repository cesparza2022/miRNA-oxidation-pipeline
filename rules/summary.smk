# ============================================================================
# SNAKEMAKE RULES: SUMMARY REPORTS
# FASE 3: Generate consolidated summary reports
# ============================================================================

# Load configuration
configfile: "config/config.yaml"

# ============================================================================
# COMMON PATHS
# ============================================================================

OUTPUT_SUMMARY = "results/summary"
SCRIPTS_UTILS = config["paths"]["snakemake_dir"] + "/" + config["paths"]["scripts"]["utils"]
CONFIG_FILE = config["paths"]["snakemake_dir"] + "/config/config.yaml"

# ============================================================================
# RULE: Generate Summary Report
# ============================================================================

rule generate_summary_report:
    input:
        config = CONFIG_FILE,
        execution_info = "results/pipeline_info/execution_info.yaml"
        # Note: We depend on pipeline_info being generated first (FASE 2)
    output:
        summary_html = OUTPUT_SUMMARY + "/summary_report.html",
        summary_json = OUTPUT_SUMMARY + "/summary_statistics.json",
        key_findings = OUTPUT_SUMMARY + "/key_findings.md"
    params:
        config_file = CONFIG_FILE,
        output_dir = OUTPUT_SUMMARY,
        snakemake_dir = config["paths"]["snakemake_dir"]
    log:
        OUTPUT_SUMMARY + "/generate_summary_report.log"
    script:
        SCRIPTS_UTILS + "/generate_summary_report.R"

# ============================================================================
# RULE: Prepare Summary Directory
# ============================================================================

rule prepare_summary_dir:
    output:
        directory(OUTPUT_SUMMARY)
    shell:
        "mkdir -p {output} && touch {output}/.gitkeep"

