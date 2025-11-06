#!/usr/bin/env Rscript
# ============================================================================
# BUILD STEP 5 VIEWER HTML
# ============================================================================
# Generates HTML viewer for Step 5 Expression-Oxidation Correlation results
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

# Load correlation data for summary
correlation_file <- file.path(tables_dir, "correlation", "S6_expression_oxidation_correlation.csv")
expression_summary_file <- file.path(tables_dir, "correlation", "S6_expression_summary.csv")

n_miRNAs <- if (file.exists(correlation_file)) nrow(read_csv(correlation_file, show_col_types = FALSE)) else 0

# Calculate correlation from data
correlation_r <- if (file.exists(correlation_file)) {
  cor_data <- read_csv(correlation_file, show_col_types = FALSE)
  cor_result <- cor.test(cor_data$estimated_rpm, cor_data$total_gt_counts, method = "pearson")
  round(cor_result$estimate, 4)
} else 0

high_expression_n <- if (file.exists(expression_summary_file)) {
  summary <- read_csv(expression_summary_file, show_col_types = FALSE)
  summary %>% filter(expression_category == "High (top 20%)") %>% pull(n_miRNAs)
} else 0

# Generate HTML
html_content <- paste0('<!DOCTYPE html>
<html>
<head>
  <title>Step 5: Expression-Oxidation Correlation Viewer</title>
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
    <h1>Step 5: Expression vs Oxidation Correlation Results</h1>
    
    <div class="summary">
      <h2>📊 Summary Statistics</h2>
      <div class="stats">
        <div class="stat-box">
          <div class="stat-number">', n_miRNAs, '</div>
          <div class="stat-label">miRNAs Analyzed</div>
        </div>
        <div class="stat-box">
          <div class="stat-number">', correlation_r, '</div>
          <div class="stat-label">Pearson Correlation (r)</div>
        </div>
        <div class="stat-box">
          <div class="stat-number">', high_expression_n, '</div>
          <div class="stat-label">High Expression miRNAs</div>
        </div>
      </div>
    </div>

    <h2>📈 Panel A: Expression vs Oxidation Scatter</h2>
    <div class="figure">
      <img src="', encode_image(fig_a), '" alt="Expression vs Oxidation">
      <div class="figure-caption">Correlation between miRNA expression (RPM) and G>T oxidation counts</div>
    </div>

    <h2>📊 Panel B: Oxidation by Expression Category</h2>
    <div class="figure">
      <img src="', encode_image(fig_b), '" alt="Expression Groups">
      <div class="figure-caption">Oxidation levels grouped by expression category</div>
    </div>

    <div class="summary" style="margin-top: 40px;">
      <h2>📋 Available Tables</h2>
      <ul>
        <li><strong>S6_expression_oxidation_correlation.csv</strong>: Per-miRNA correlation data</li>
        <li><strong>S6_expression_summary.csv</strong>: Summary by expression category</li>
      </ul>
    </div>
  </div>
</body>
</html>')

writeLines(html_content, output_html)
cat("✅ Step 5 viewer generated:", output_html, "\n")

