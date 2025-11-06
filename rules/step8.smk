# ============================================================================
# SNAKEMAKE RULES: STEP 8 - Sequence-Based Analysis (Paper Reference Methods)
# ============================================================================
# Purpose: Implement sequence-based analysis methods from reference paper:
#   - Trinucleotide context analysis (XGY)
#   - Position-specific sequence logos
#   - Temporal pattern analysis (if timepoints available)
# Execution: Runs after Step 7 (optional step, can run independently)
# ============================================================================

# Load configuration
configfile: "config/config.yaml"

# ============================================================================
# COMMON PATHS AND PARAMETERS
# ============================================================================

# Input data
STEP1_5_DATA_DIR = config["paths"]["snakemake_dir"] + "/" + config["paths"]["outputs"]["step1_5"]
STEP2_DATA_DIR = config["paths"]["snakemake_dir"] + "/" + config["paths"]["outputs"]["step2"]
INPUT_VAF_FILTERED = STEP1_5_DATA_DIR + "/tables/filtered_data/ALL_MUTATIONS_VAF_FILTERED.csv"
INPUT_STATISTICAL = STEP2_DATA_DIR + "/tables/statistical_results/S2_statistical_comparisons.csv"

# Output directories
OUTPUT_STEP8 = config["paths"]["outputs"]["step8"]
OUTPUT_FIGURES = OUTPUT_STEP8 + "/figures"
OUTPUT_TABLES = OUTPUT_STEP8 + "/tables"
OUTPUT_LOGS = OUTPUT_STEP8 + "/logs"

# Scripts paths
# For script: directive (resolved from rules/ directory), use relative path
SCRIPTS_STEP8_SCRIPT = "../scripts/step8"  # For script: (resolved from rules/)
SCRIPTS_UTILS_SCRIPT = "../scripts/utils"  # For script: (resolved from rules/)
# For input: directive (resolved from Snakefile), use config path
SCRIPTS_STEP8 = config["paths"]["scripts"]["step8"]  # For input: (resolved from Snakefile)
SCRIPTS_UTILS = config["paths"]["scripts"]["utils"]  # For input: (resolved from Snakefile)

# Common parameters
FUNCTIONS_COMMON = SCRIPTS_UTILS + "/functions_common.R"

# Seed region positions (from config)
SEED_START = config["analysis"]["seed_region"]["start"]
SEED_END = config["analysis"]["seed_region"]["end"]

# ============================================================================
# RULE: Trinucleotide Context Analysis (XGY)
# ============================================================================

rule step8_trinucleotide_context:
    input:
        vaf_filtered = INPUT_VAF_FILTERED,
        functions = FUNCTIONS_COMMON
    output:
        enrichment_table = OUTPUT_TABLES + "/S8_trinucleotide_enrichment.csv",
        context_summary = OUTPUT_TABLES + "/S8_context_summary.csv",
        figure = OUTPUT_FIGURES + "/S8_trinucleotide_context.png"
    params:
        seed_start = SEED_START,
        seed_end = SEED_END
    log:
        OUTPUT_LOGS + "/trinucleotide_context.log"
    script:
        SCRIPTS_STEP8_SCRIPT + "/01_trinucleotide_context.R"

# ============================================================================
# RULE: Position-Specific Sequence Logos
# ============================================================================

rule step8_sequence_logos:
    input:
        vaf_filtered = INPUT_VAF_FILTERED,
        functions = FUNCTIONS_COMMON
    output:
        logo_pos2 = OUTPUT_FIGURES + "/S8_logo_position_2.png",
        logo_pos3 = OUTPUT_FIGURES + "/S8_logo_position_3.png",
        logo_pos5 = OUTPUT_FIGURES + "/S8_logo_position_5.png",
        logo_summary = OUTPUT_TABLES + "/S8_logos_summary.csv"
    params:
        seed_start = SEED_START,
        seed_end = SEED_END,
        hotspot_positions = "2,3,5"  # Main hotspots from Step 2 (comma-separated string for R)
    log:
        OUTPUT_LOGS + "/sequence_logos.log"
    script:
        SCRIPTS_STEP8_SCRIPT + "/02_position_specific_logos.R"

# ============================================================================
# RULE: Temporal Pattern Analysis (if timepoints available)
# ============================================================================

rule step8_temporal_analysis:
    input:
        vaf_filtered = INPUT_VAF_FILTERED,
        functions = FUNCTIONS_COMMON
    output:
        temporal_table = OUTPUT_TABLES + "/S8_temporal_accumulation.csv",
        temporal_figure = OUTPUT_FIGURES + "/S8_temporal_patterns.png"
    params:
        seed_start = SEED_START,
        seed_end = SEED_END
    log:
        OUTPUT_LOGS + "/temporal_analysis.log"
    script:
        SCRIPTS_STEP8_SCRIPT + "/03_temporal_patterns.R"

# ============================================================================
# RULE: Individual miRNA Analysis
# ============================================================================

rule step8_individual_mirna_analysis:
    input:
        vaf_filtered = INPUT_VAF_FILTERED,
        context_summary = OUTPUT_TABLES + "/S8_context_summary.csv",
        statistical = INPUT_STATISTICAL,
        functions = FUNCTIONS_COMMON
    output:
        top_mirnas_comparison = OUTPUT_FIGURES + "/S8_top_mirnas_comparison.png",
        top_mirnas_table = OUTPUT_TABLES + "/S8_top_mirnas_individual.csv"
    params:
        output_figures = OUTPUT_FIGURES,
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/individual_mirna_analysis.log"
    script:
        SCRIPTS_STEP8_SCRIPT + "/04_individual_mirna_analysis.R"

# ============================================================================
# RULE: Sequence-Based Clustering and Heatmap
# ============================================================================

rule step8_sequence_clustering_heatmap:
    input:
        vaf_filtered = INPUT_VAF_FILTERED,
        context_summary = OUTPUT_TABLES + "/S8_context_summary.csv",
        statistical = INPUT_STATISTICAL,
        functions = FUNCTIONS_COMMON
    output:
        clustering_heatmap = OUTPUT_FIGURES + "/S8_sequence_clustering_heatmap.png",
        clustering_dendrogram = OUTPUT_FIGURES + "/S8_clustering_dendrogram.png",
        cluster_assignments = OUTPUT_TABLES + "/S8_cluster_assignments.csv"
    params:
        output_figures = OUTPUT_FIGURES,
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/sequence_clustering_heatmap.log"
    script:
        SCRIPTS_STEP8_SCRIPT + "/05_sequence_clustering_heatmap.R"

# ============================================================================
# AGGREGATE RULE: All Step 8 Analysis
# ============================================================================

rule all_step8:
    input:
        # Step 8 depends on Step 1.5 (VAF-filtered data) and Step 2 (statistical results)
        rules.all_step1_5.output,
        rules.all_step2.output,
        # Step 8 basic outputs (trinucleotide, logos, temporal)
        OUTPUT_TABLES + "/S8_trinucleotide_enrichment.csv",
        OUTPUT_TABLES + "/S8_context_summary.csv",
        OUTPUT_FIGURES + "/S8_trinucleotide_context.png",
        OUTPUT_FIGURES + "/S8_logo_position_2.png",
        OUTPUT_FIGURES + "/S8_logo_position_3.png",
        OUTPUT_FIGURES + "/S8_logo_position_5.png",
        OUTPUT_TABLES + "/S8_logos_summary.csv",
        OUTPUT_TABLES + "/S8_temporal_accumulation.csv",
        OUTPUT_FIGURES + "/S8_temporal_patterns.png",
        # Step 8 advanced outputs (individual miRNAs, clustering)
        OUTPUT_FIGURES + "/S8_top_mirnas_comparison.png",
        OUTPUT_TABLES + "/S8_top_mirnas_individual.csv",
        OUTPUT_FIGURES + "/S8_sequence_clustering_heatmap.png",
        OUTPUT_FIGURES + "/S8_clustering_dendrogram.png",
        OUTPUT_TABLES + "/S8_cluster_assignments.csv"

