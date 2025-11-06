#!/usr/bin/env Rscript
# ============================================================================
# BUILD STEP 4 VIEWER HTML
# ============================================================================
# Generates HTML viewer for Step 4 Family Analysis results
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

# Load family data for summary
family_summary_file <- file.path(tables_dir, "families", "S5_family_summary.csv")
family_comp_file <- file.path(tables_dir, "families", "S5_family_comparison.csv")

n_families <- if (file.exists(family_summary_file)) nrow(read_csv(family_summary_file, show_col_types = FALSE)) else 0
n_significant_families <- if (file.exists(family_summary_file)) {
  summary <- read_csv(family_summary_file, show_col_types = FALSE)
  sum(summary$n_significant > 0, na.rm = TRUE)
} else 0

top_family <- if (file.exists(family_comp_file)) {
  comp <- read_csv(family_comp_file, show_col_types = FALSE)
  comp %>% arrange(desc(n_significant)) %>% head(1) %>% pull(family)
} else "N/A"

# Generate HTML
html_content <- paste0('<!DOCTYPE html>
<html>
<head>
  <title>Step 4: Family Analysis Viewer</title>
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
    <h1>Step 4: miRNA Family Analysis Results</h1>
    
    <div class="summary">
      <h2>📊 Summary Statistics</h2>
      <div class="stats">
        <div class="stat-box">
          <div class="stat-number">', n_families, '</div>
          <div class="stat-label">Total Families</div>
        </div>
        <div class="stat-box">
          <div class="stat-number">', n_significant_families, '</div>
          <div class="stat-label">Families with Significant Mutations</div>
        </div>
        <div class="stat-box">
          <div class="stat-number">', top_family, '</div>
          <div class="stat-label">Top Family</div>
        </div>
      </div>
    </div>

    <h2>📊 Panel A: Family Oxidation Comparison</h2>
    <div class="figure">
      <img src="', encode_image(fig_a), '" alt="Family Comparison">
      <div class="figure-caption">Comparison of oxidation patterns (ALS vs Control) by miRNA family</div>
    </div>

    <h2>🔥 Panel B: Family Heatmap</h2>
    <div class="figure">
      <img src="', encode_image(fig_b), '" alt="Family Heatmap">
      <div class="figure-caption">Heatmap showing oxidation patterns across top families</div>
    </div>

    <div class="summary" style="margin-top: 40px;">
      <h2>📋 Available Tables</h2>
      <ul>
        <li><strong>S5_family_summary.csv</strong>: Summary statistics by miRNA family</li>
        <li><strong>S5_family_comparison.csv</strong>: ALS vs Control comparison by family</li>
      </ul>
    </div>
  </div>
</body>
</html>')

writeLines(html_content, output_html)
cat("✅ Step 4 viewer generated:", output_html, "\n")

