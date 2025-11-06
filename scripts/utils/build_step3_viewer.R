#!/usr/bin/env Rscript
# ============================================================================
# BUILD STEP 3 VIEWER HTML
# ============================================================================
# Generates HTML viewer for Step 3 Clustering Analysis results
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

output_html <- snakemake@output[["html"]]
tables_dir <- snakemake@params[["tables_dir"]]

# Load cluster data for summary
cluster_assignments_file <- file.path(tables_dir, "clusters", "S7_cluster_assignments.csv")
cluster_summary_file <- file.path(tables_dir, "clusters", "S7_cluster_summary.csv")

n_miRNAs <- if (file.exists(cluster_assignments_file)) nrow(read_csv(cluster_assignments_file, show_col_types = FALSE)) else 0
n_clusters <- if (file.exists(cluster_summary_file)) nrow(read_csv(cluster_summary_file, show_col_types = FALSE)) else 0

cluster_sizes <- if (file.exists(cluster_summary_file)) {
  summary <- read_csv(cluster_summary_file, show_col_types = FALSE)
  paste(summary$n_miRNAs, collapse = ", ")
} else "N/A"

# Generate HTML
html_content <- paste0('<!DOCTYPE html>
<html>
<head>
  <title>Step 3: Clustering Analysis Viewer</title>
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
    <h1>Step 3: Clustering Analysis Results</h1>
    
    <div class="summary">
      <h2>📊 Summary Statistics</h2>
      <div class="stats">
        <div class="stat-box">
          <div class="stat-number">', n_miRNAs, '</div>
          <div class="stat-label">miRNAs Clustered</div>
        </div>
        <div class="stat-box">
          <div class="stat-number">', n_clusters, '</div>
          <div class="stat-label">Clusters Identified</div>
        </div>
        <div class="stat-box">
          <div class="stat-number">', cluster_sizes, '</div>
          <div class="stat-label">Cluster Sizes</div>
        </div>
      </div>
    </div>

    <h2>🔥 Panel A: Cluster Heatmap</h2>
    <div class="figure">
      <img src="', encode_image(fig_a), '" alt="Cluster Heatmap">
      <div class="figure-caption">Heatmap showing miRNA clusters based on oxidation patterns</div>
    </div>

    <h2>🌳 Panel B: Cluster Dendrogram</h2>
    <div class="figure">
      <img src="', encode_image(fig_b), '" alt="Cluster Dendrogram">
      <div class="figure-caption">Hierarchical clustering dendrogram showing cluster relationships</div>
    </div>

    <div class="summary" style="margin-top: 40px;">
      <h2>📋 Available Tables</h2>
      <ul>
        <li><strong>S7_cluster_assignments.csv</strong>: Cluster assignments for each miRNA</li>
        <li><strong>S7_cluster_summary.csv</strong>: Summary statistics by cluster</li>
      </ul>
    </div>
  </div>
</body>
</html>')

writeLines(html_content, output_html)
cat("✅ Step 3 viewer generated:", output_html, "\n")

