#!/usr/bin/env Rscript
# ============================================================================
# BUILD STEP 7 VIEWER HTML
# ============================================================================
# Generates HTML viewer for Step 7 Biomarker Analysis results
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
roc_figure <- snakemake@input[["roc_figure"]]
heatmap_figure <- snakemake@input[["heatmap_figure"]]

output_html <- snakemake@output[["html"]]
tables_dir <- snakemake@params[["tables_dir"]]

# Load ROC data for summary
roc_file <- file.path(tables_dir, "biomarkers", "S4_roc_analysis.csv")
signatures_file <- file.path(tables_dir, "biomarkers", "S4_biomarker_signatures.csv")

n_biomarkers <- if (file.exists(roc_file)) {
  roc_data <- read_csv(roc_file, show_col_types = FALSE)
  nrow(roc_data %>% filter(SNV_id != "COMBINED_SIGNATURE"))
} else 0

top_auc <- if (file.exists(roc_file)) {
  roc_data <- read_csv(roc_file, show_col_types = FALSE)
  round(max(roc_data$AUC, na.rm = TRUE), 3)
} else 0

combined_auc <- if (file.exists(roc_file)) {
  roc_data <- read_csv(roc_file, show_col_types = FALSE)
  combined <- roc_data %>% filter(SNV_id == "COMBINED_SIGNATURE")
  if (nrow(combined) > 0) round(combined$AUC[1], 3) else 0
} else 0

# Generate HTML
html_content <- paste0('<!DOCTYPE html>
<html>
<head>
  <title>Step 7: Biomarker Analysis Viewer</title>
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
    <h1>Step 7: Biomarker Analysis Results</h1>
    
    <div class="summary">
      <h2>📊 Summary Statistics</h2>
      <div class="stats">
        <div class="stat-box">
          <div class="stat-number">', n_biomarkers, '</div>
          <div class="stat-label">Individual Biomarkers</div>
        </div>
        <div class="stat-box">
          <div class="stat-number">', top_auc, '</div>
          <div class="stat-label">Top AUC</div>
        </div>
        <div class="stat-box">
          <div class="stat-number">', combined_auc, '</div>
          <div class="stat-label">Combined Signature AUC</div>
        </div>
      </div>
    </div>

    <h2>📈 ROC Curves Analysis</h2>
    <div class="figure">
      <img src="', encode_image(roc_figure), '" alt="ROC Curves">
      <div class="figure-caption">ROC curves for top biomarkers and combined signature</div>
    </div>

    <h2>🔥 Biomarker Signature Heatmap</h2>
    <div class="figure">
      <img src="', encode_image(heatmap_figure), '" alt="Biomarker Heatmap">
      <div class="figure-caption">Heatmap showing biomarker signatures across samples</div>
    </div>

    <div class="summary" style="margin-top: 40px;">
      <h2>📋 Available Tables</h2>
      <ul>
        <li><strong>S4_roc_analysis.csv</strong>: ROC analysis results for all biomarkers</li>
        <li><strong>S4_biomarker_signatures.csv</strong>: Per-sample signature scores</li>
      </ul>
    </div>
  </div>
</body>
</html>')

writeLines(html_content, output_html)
cat("✅ Step 7 viewer generated:", output_html, "\n")

