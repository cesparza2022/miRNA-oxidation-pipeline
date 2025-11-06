#!/usr/bin/env Rscript
# ============================================================================
# BUILD STEP 6 VIEWER HTML
# ============================================================================
# Generates HTML viewer for Step 6 Functional Analysis results
# ============================================================================

suppressPackageStartupMessages({
  library(readr)
  library(stringr)
})

if (requireNamespace("base64enc", quietly = TRUE)) {
  library(base64enc)
  encode_image <- function(image_path) {
    if (!file.exists(image_path)) return("")
    con <- file(image_path, "rb")
    img_data <- readBin(con, "raw", file.info(image_path)$size)
    close(con)
    base64_data <- base64encode(img_data)
    return(paste0("data:image/png;base64,", base64_data))
  }
} else {
  encode_image <- function(image_path) {
    if (!file.exists(image_path)) return("")
    return(image_path)
  }
}

# Get Snakemake inputs
fig_a <- snakemake@input[["figure_a"]]
fig_b <- snakemake@input[["figure_b"]]
fig_c <- snakemake@input[["figure_c"]]
fig_d <- snakemake@input[["figure_d"]]
pathway_heatmap <- snakemake@input[["pathway_heatmap"]]

output_html <- snakemake@output[["html"]]
figures_dir <- snakemake@params[["figures_dir"]]
tables_dir <- snakemake@params[["tables_dir"]]

# Load summary data
targets_file <- file.path(tables_dir, "functional", "S3_target_analysis.csv")
go_file <- file.path(tables_dir, "functional", "S3_go_enrichment.csv")
kegg_file <- file.path(tables_dir, "functional", "S3_kegg_enrichment.csv")

n_targets <- if (file.exists(targets_file)) nrow(read_csv(targets_file, show_col_types = FALSE)) else 0
n_go <- if (file.exists(go_file)) sum(read_csv(go_file, show_col_types = FALSE)$p.adjust < 0.1, na.rm = TRUE) else 0
n_kegg <- if (file.exists(kegg_file)) sum(read_csv(kegg_file, show_col_types = FALSE)$p.adjust < 0.1, na.rm = TRUE) else 0

# Generate HTML
html_content <- paste0('<!DOCTYPE html>
<html>
<head>
  <title>Step 6: Functional Analysis Viewer</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
    .container { max-width: 1400px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
    h1 { color: #D62728; border-bottom: 3px solid #D62728; padding-bottom: 10px; }
    h2 { color: #2E86AB; margin-top: 30px; }
    .figure { margin: 20px 0; text-align: center; }
    .figure img { max-width: 100%; height: auto; border: 1px solid #ddd; border-radius: 4px; }
    .figure-caption { margin-top: 10px; font-style: italic; color: #666; }
    .summary { background: #f9f9f9; padding: 15px; border-radius: 4px; margin: 20px 0; }
    .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin: 20px 0; }
    .stat-box { background: #e8f4f8; padding: 15px; border-radius: 4px; text-align: center; }
    .stat-number { font-size: 24px; font-weight: bold; color: #D62728; }
    .stat-label { color: #666; margin-top: 5px; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Step 6: Functional Analysis Results</h1>
    
    <div class="summary">
      <h2>📊 Summary Statistics</h2>
      <div class="stats">
        <div class="stat-box">
          <div class="stat-number">', n_targets, '</div>
          <div class="stat-label">Targets Analyzed</div>
        </div>
        <div class="stat-box">
          <div class="stat-number">', n_go, '</div>
          <div class="stat-label">Significant GO Terms</div>
        </div>
        <div class="stat-box">
          <div class="stat-number">', n_kegg, '</div>
          <div class="stat-label">Significant KEGG Pathways</div>
        </div>
      </div>
    </div>

    <h2>🎯 Pathway Enrichment Heatmap</h2>
    <div class="figure">
      <img src="', encode_image(pathway_heatmap), '" alt="Pathway Enrichment Heatmap">
      <div class="figure-caption">Top enriched pathways (GO and KEGG) for targets of oxidized miRNAs</div>
    </div>

    <h2>📈 Panel A: Pathway Enrichment</h2>
    <div class="figure">
      <img src="', encode_image(fig_a), '" alt="Pathway Enrichment">
      <div class="figure-caption">Top enriched pathways by significance (-log10 adjusted p-value)</div>
    </div>

    <h2>🧬 Panel B: ALS-Relevant Genes Impact</h2>
    <div class="figure">
      <img src="', encode_image(fig_b), '" alt="ALS Genes Impact">
      <div class="figure-caption">Functional impact of oxidized miRNAs on ALS-relevant genes</div>
    </div>

    <h2>🔀 Panel C: Target Comparison</h2>
    <div class="figure">
      <img src="', encode_image(fig_c), '" alt="Target Comparison">
      <div class="figure-caption">Comparison of canonical vs oxidized miRNA targets</div>
    </div>

    <h2>📍 Panel D: Position-Specific Impact</h2>
    <div class="figure">
      <img src="', encode_image(fig_d), '" alt="Position Impact">
      <div class="figure-caption">Functional impact by position in seed region</div>
    </div>

    <div class="summary" style="margin-top: 40px;">
      <h2>📋 Available Tables</h2>
      <ul>
        <li><strong>S3_target_analysis.csv</strong>: miRNA-target analysis results</li>
        <li><strong>S3_als_relevant_genes.csv</strong>: ALS-relevant genes analysis</li>
        <li><strong>S3_target_comparison.csv</strong>: Canonical vs oxidized target comparison</li>
        <li><strong>S3_go_enrichment.csv</strong>: GO enrichment results</li>
        <li><strong>S3_kegg_enrichment.csv</strong>: KEGG enrichment results</li>
        <li><strong>S3_als_pathways.csv</strong>: ALS-specific pathways</li>
      </ul>
    </div>
  </div>
</body>
</html>')

writeLines(html_content, output_html)
cat("✅ Step 6 viewer generated:", output_html, "\n")

