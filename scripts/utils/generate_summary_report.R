#!/usr/bin/env Rscript
# ============================================================================
# Generate Summary Report (Consolidated HTML)
# FASE 3: Creates summary_report.html with all key results
# ============================================================================

library(yaml)
library(jsonlite)
library(dplyr)

# Check if running in Snakemake context
if (exists("snakemake")) {
  # Snakemake context: use snakemake object
  config_file <- snakemake@params[["config_file"]]
  output_dir <- snakemake@params[["output_dir"]]
  snakemake_dir <- snakemake@params[["snakemake_dir"]]
} else {
  # Command-line context: use commandArgs
  args <- commandArgs(trailingOnly = TRUE)
  config_file <- args[1]
  output_dir <- args[2]
  snakemake_dir <- args[3]
  
  if (is.na(config_file) || is.na(output_dir)) {
    stop("Usage: Rscript generate_summary_report.R <config.yaml> <output_dir> <snakemake_dir>")
  }
}

# Create output directory
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# Load config
config <- yaml::read_yaml(config_file)

# Helper for NULL coalescing
`%||%` <- function(x, y) if (is.null(x) || length(x) == 0) y else x

# ============================================================================
# LOAD DATA
# ============================================================================

cat("Loading data for summary report...\n")

# Paths
step1_dir <- file.path(snakemake_dir, "results/step1/final")
step1_5_dir <- file.path(snakemake_dir, "results/step1_5/final")
step2_dir <- file.path(snakemake_dir, "results/step2/final")
pipeline_info_dir <- file.path(snakemake_dir, "results/pipeline_info")

# Load execution info
execution_info <- NULL
if (file.exists(file.path(pipeline_info_dir, "execution_info.yaml"))) {
  execution_info <- yaml::read_yaml(file.path(pipeline_info_dir, "execution_info.yaml"))
}

# Load statistical results (Step 2)
statistical_data <- NULL
statistical_file <- file.path(step2_dir, "tables/step2_statistical_comparisons.csv")
if (file.exists(statistical_file)) {
  statistical_data <- read.csv(statistical_file, stringsAsFactors = FALSE)
}

effect_sizes <- NULL
effect_sizes_file <- file.path(step2_dir, "tables/step2_effect_sizes.csv")
if (file.exists(effect_sizes_file)) {
  effect_sizes <- read.csv(effect_sizes_file, stringsAsFactors = FALSE)
}

# ============================================================================
# CALCULATE SUMMARY STATISTICS
# ============================================================================

cat("Calculating summary statistics...\n")

# Step 1: Count figures and tables
step1_figures <- if (file.exists(file.path(step1_dir, "figures"))) {
  length(list.files(file.path(step1_dir, "figures"), pattern = "\\.png$"))
} else 0

step1_tables <- if (file.exists(file.path(step1_dir, "tables"))) {
  length(list.files(file.path(step1_dir, "tables"), pattern = "\\.csv$"))
} else 0

# Step 2: Statistical results
num_total_mutations <- if (!is.null(statistical_data)) nrow(statistical_data) else 0
num_significant <- if (!is.null(statistical_data)) {
  sum(statistical_data$significant == TRUE, na.rm = TRUE)
} else 0

num_significant_t_test <- if (!is.null(statistical_data)) {
  sum(statistical_data$t_test_significant == TRUE, na.rm = TRUE)
} else 0

num_significant_wilcoxon <- if (!is.null(statistical_data)) {
  sum(statistical_data$wilcoxon_significant == TRUE, na.rm = TRUE)
} else 0

# Top effect sizes
top_effect_sizes <- if (!is.null(effect_sizes) && nrow(effect_sizes) > 0) {
  # Extract position from pos.mut (format: "6:GT" -> 6)
  effect_sizes <- effect_sizes %>%
    mutate(position = as.numeric(gsub(":.*", "", pos.mut))) %>%
    arrange(desc(abs(log2_fold_change))) %>%
    head(10)
  
  # Select and format columns
  top_effect_sizes <- effect_sizes %>%
    select(miRNA_name, pos.mut, position, log2_fold_change, t_test_fdr) %>%
    mutate(rank = row_number())
  top_effect_sizes
} else NULL

# ============================================================================
# GENERATE HTML REPORT (Manual HTML generation)
# ============================================================================

cat("Generating HTML summary report...\n")

# CSS Styles
css_styles <- '
<style>
body {
  font-family: "Segoe UI", Tahoma, Geneva, Verdana, sans-serif;
  line-height: 1.6;
  color: #333;
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
  background-color: #f5f5f5;
}
h1 {
  color: #2c3e50;
  border-bottom: 3px solid #3498db;
  padding-bottom: 10px;
}
h2 {
  color: #34495e;
  margin-top: 30px;
  border-bottom: 2px solid #95a5a6;
  padding-bottom: 5px;
}
.summary-box {
  background: white;
  border-radius: 8px;
  padding: 20px;
  margin: 20px 0;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}
.stat-row {
  display: flex;
  justify-content: space-between;
  padding: 8px 0;
  border-bottom: 1px solid #ecf0f1;
}
.stat-label {
  font-weight: 600;
  color: #555;
}
.stat-value {
  color: #2c3e50;
  font-weight: bold;
}
.highlight {
  background-color: #fff3cd;
  padding: 15px;
  border-left: 4px solid #ffc107;
  margin: 15px 0;
}
table {
  width: 100%;
  border-collapse: collapse;
  margin: 20px 0;
  background: white;
}
th {
  background-color: #3498db;
  color: white;
  padding: 12px;
  text-align: left;
}
td {
  padding: 10px;
  border-bottom: 1px solid #ecf0f1;
}
tr:hover {
  background-color: #f8f9fa;
}
.badge {
  display: inline-block;
  padding: 3px 8px;
  border-radius: 3px;
  font-size: 0.85em;
  font-weight: bold;
}
.badge-success {
  background-color: #28a745;
  color: white;
}
.badge-info {
  background-color: #17a2b8;
  color: white;
}
.link-section {
  margin: 20px 0;
  padding: 15px;
  background: #e8f4f8;
  border-radius: 5px;
}
.link-section a {
  color: #3498db;
  text-decoration: none;
  margin-right: 15px;
}
.link-section a:hover {
  text-decoration: underline;
}
</style>
'

# Build HTML content
html_lines <- c(
  '<!DOCTYPE html>',
  '<html lang="en">',
  '<head>',
  '  <meta charset="UTF-8">',
  '  <meta name="viewport" content="width=device-width, initial-scale=1.0">',
  sprintf('  <title>%s - Summary Report</title>', config$project$name %||% "miRNA Oxidation Analysis"),
  css_styles,
  '</head>',
  '<body>',
  '  <h1>🧬 miRNA Oxidation Analysis - Summary Report</h1>',
  '',
  '  <div class="summary-box">',
    sprintf('    <p><strong>Pipeline:</strong> %s</p>', config$project$name %||% "miRNA Oxidation Analysis"),
  sprintf('    <p><strong>Version:</strong> %s</p>', config$project$version %||% "1.0.0"),
  if (!is.null(execution_info)) {
    sprintf('    <p><strong>Execution Date:</strong> %s</p>', execution_info$execution$date %||% "Unknown")
  },
  sprintf('    <p><strong>Generated:</strong> %s</p>', format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  '  </div>',
  '',
  '  <h2>📊 Pipeline Execution Summary</h2>',
  '  <div class="summary-box">',
  '    <div class="stat-row">',
  '      <span class="stat-label">Pipeline Status:</span>',
  '      <span class="stat-value">',
  if (!is.null(execution_info) && execution_info$execution$status == "completed") {
    '        <span class="badge badge-success">✅ Completed</span>'
  } else {
    '        <span class="badge badge-info">⏱️ Partial</span>'
  },
  '      </span>',
  '    </div>',
  if (!is.null(execution_info)) {
    c(
      '    <div class="stat-row">',
      '      <span class="stat-label">Steps Completed:</span>',
      sprintf('      <span class="stat-value">%s</span>', paste(execution_info$execution$steps_completed, collapse = ", ")),
      '    </div>',
      '    <div class="stat-row">',
      '      <span class="stat-label">Total Figures:</span>',
      sprintf('      <span class="stat-value">%s</span>', as.character(execution_info$outputs$total_figures)),
      '    </div>',
      '    <div class="stat-row">',
      '      <span class="stat-label">Total Tables:</span>',
      sprintf('      <span class="stat-value">%s</span>', as.character(execution_info$outputs$total_tables)),
      '    </div>'
    )
  },
  '  </div>',
  '',
  '  <h2>📈 Key Statistical Findings</h2>'
)

# Add statistical results
if (!is.null(statistical_data) && num_total_mutations > 0) {
  html_lines <- c(html_lines,
    '  <div class="summary-box">',
    '    <div class="stat-row">',
    '      <span class="stat-label">Total Mutations Analyzed:</span>',
    sprintf('      <span class="stat-value">%s</span>', as.character(num_total_mutations)),
    '    </div>',
    '    <div class="stat-row">',
    '      <span class="stat-label">Significant Mutations (FDR &lt; 0.05):</span>',
    sprintf('      <span class="stat-value" style="color: #d62728; font-size: 1.2em;">%s</span>', as.character(num_significant)),
    '    </div>',
    '    <div class="stat-row">',
    '      <span class="stat-label">Significant (t-test):</span>',
    sprintf('      <span class="stat-value">%s</span>', as.character(num_significant_t_test)),
    '    </div>',
    '    <div class="stat-row">',
    '      <span class="stat-label">Significant (Wilcoxon):</span>',
    sprintf('      <span class="stat-value">%s</span>', as.character(num_significant_wilcoxon)),
    '    </div>',
    '  </div>'
  )
} else {
  html_lines <- c(html_lines,
    '  <div class="highlight">',
    '    <p>⚠️ Statistical results not available. Run Step 2 to generate statistical comparisons.</p>',
    '  </div>'
  )
}

# Add top effect sizes table
if (!is.null(top_effect_sizes) && nrow(top_effect_sizes) > 0) {
  html_lines <- c(html_lines,
    '',
    '  <h2>🔝 Top 10 Mutations by Effect Size</h2>',
    '  <div class="summary-box">',
    '    <table>',
    '      <thead>',
    '        <tr>',
    '          <th>Rank</th>',
    '          <th>miRNA</th>',
    '          <th>Position</th>',
    '          <th>Log2 Fold Change</th>',
    '          <th>FDR</th>',
    '        </tr>',
    '      </thead>',
    '      <tbody>'
  )
  
  # Add table rows
  for (i in 1:nrow(top_effect_sizes)) {
    row <- top_effect_sizes[i, ]
    pos_display <- ifelse(is.na(row$position) || is.null(row$position), as.character(row$pos.mut), as.character(row$position))
    fdr_display <- ifelse(is.na(row$t_test_fdr) || is.null(row$t_test_fdr), "N/A", sprintf("%.4f", row$t_test_fdr))
    
    html_lines <- c(html_lines,
      '        <tr>',
      sprintf('          <td>%d</td>', row$rank),
      sprintf('          <td>%s</td>', row$miRNA_name),
      sprintf('          <td>%s</td>', pos_display),
      sprintf('          <td>%.3f</td>', row$log2_fold_change),
      sprintf('          <td>%s</td>', fdr_display),
      '        </tr>'
    )
  }
  
  html_lines <- c(html_lines,
    '      </tbody>',
    '    </table>',
    '  </div>'
  )
}

# Add navigation and parameters
html_lines <- c(html_lines,
  '',
  '  <h2>🔗 Navigation Links</h2>',
  '  <div class="link-section">',
  '    <p><strong>Results:</strong>',
  '      <a href="../INDEX.md">📋 Results Index</a>',
  '      <a href="../pipeline_info/">📊 Pipeline Info</a>',
  '      <a href="../step1/final/">🔍 Step 1: Exploratory</a>',
  '      <a href="../step1_5/final/">🔬 Step 1.5: VAF QC</a>',
  '      <a href="../step2/final/">📈 Step 2: Statistics</a>',
  '    </p>',
  '  </div>',
  '',
  '  <h2>📝 Parameters Used</h2>'
)

if (!is.null(execution_info)) {
  html_lines <- c(html_lines,
    '  <div class="summary-box">',
    '    <div class="stat-row">',
    '      <span class="stat-label">VAF Threshold:</span>',
    sprintf('      <span class="stat-value">%s</span>', as.character(execution_info$parameters$vaf_threshold)),
    '    </div>',
    '    <div class="stat-row">',
    '      <span class="stat-label">Alpha (Significance):</span>',
    sprintf('      <span class="stat-value">%s</span>', as.character(execution_info$parameters$alpha)),
    '    </div>',
    '    <div class="stat-row">',
    '      <span class="stat-label">FDR Method:</span>',
    sprintf('      <span class="stat-value">%s</span>', execution_info$parameters$fdr_method),
    '    </div>',
    '    <div class="stat-row">',
    '      <span class="stat-label">Log2FC Threshold:</span>',
    sprintf('      <span class="stat-value">%s</span>', as.character(execution_info$parameters$log2fc_threshold)),
    '    </div>',
    '  </div>'
  )
}

html_lines <- c(html_lines,
  '',
  '</body>',
  '</html>'
)

# Write HTML file
writeLines(html_lines, file.path(output_dir, "summary_report.html"))
cat("✅ summary_report.html created\n")

# ============================================================================
# GENERATE SUMMARY STATISTICS JSON
# ============================================================================

cat("Generating summary_statistics.json...\n")

summary_stats <- list(
  pipeline = list(
    name = config$project$name %||% "miRNA Oxidation Analysis",
    version = config$project$version %||% "1.0.0",
    execution_date = if (!is.null(execution_info)) execution_info$execution$date else as.character(Sys.Date()),
    status = if (!is.null(execution_info)) execution_info$execution$status else "unknown"
  ),
  outputs = list(
    step1 = list(
      figures = step1_figures,
      tables = step1_tables
    ),
    total_figures = if (!is.null(execution_info)) execution_info$outputs$total_figures else step1_figures,
    total_tables = if (!is.null(execution_info)) execution_info$outputs$total_tables else step1_tables
  ),
  statistical_results = list(
    total_mutations_analyzed = num_total_mutations,
    significant_mutations = num_significant,
    significant_t_test = num_significant_t_test,
    significant_wilcoxon = num_significant_wilcoxon,
    significant_percentage = if (num_total_mutations > 0) {
      round((num_significant / num_total_mutations) * 100, 2)
    } else 0
  )
)

# Helper function to clean Inf/-Inf values
clean_inf_values <- function(x, max_value = 10, min_value = -10) {
  if (is.numeric(x)) {
    if (is.infinite(x) && x > 0) return(max_value)
    if (is.infinite(x) && x < 0) return(min_value)
    return(x)
  }
  return(x)
}

# Add top findings if available
if (!is.null(top_effect_sizes) && nrow(top_effect_sizes) > 0) {
  summary_stats$top_findings <- lapply(1:nrow(top_effect_sizes), function(i) {
    row <- top_effect_sizes[i, ]
    
    # Clean log2_fold_change: replace Inf with max_value, -Inf with min_value
    log2fc_cleaned <- clean_inf_values(row$log2_fold_change, max_value = 10, min_value = -10)
    
    list(
      rank = row$rank,
      miRNA_name = row$miRNA_name,
      position = as.character(row$pos.mut),
      log2_fold_change = ifelse(is.na(log2fc_cleaned), NA, round(log2fc_cleaned, 4)),
      fdr = ifelse(is.na(row$t_test_fdr), NA, round(row$t_test_fdr, 4))
    )
  })
}

# Clean all numeric values in summary_stats before writing JSON
summary_stats_cleaned <- jsonlite::fromJSON(
  jsonlite::toJSON(summary_stats, auto_unbox = TRUE, null = "null", na = "null"),
  simplifyVector = TRUE
)

# Recursively clean Inf/-Inf values in the cleaned structure
clean_structure <- function(x) {
  if (is.list(x)) {
    return(lapply(x, clean_structure))
  } else if (is.numeric(x)) {
    if (is.infinite(x) && x > 0) return(10)  # Cap Inf at 10
    if (is.infinite(x) && x < 0) return(-10)  # Cap -Inf at -10
    return(x)
  }
  return(x)
}

summary_stats_cleaned <- clean_structure(summary_stats_cleaned)

write_json(summary_stats_cleaned, file.path(output_dir, "summary_statistics.json"), pretty = TRUE, auto_unbox = TRUE, null = "null", na = "null")
cat("✅ summary_statistics.json created (Inf/-Inf values cleaned)\n")

# ============================================================================
# GENERATE KEY FINDINGS MARKDOWN
# ============================================================================

cat("Generating key_findings.md...\n")

key_findings_lines <- c(
  "# 🔑 Key Findings - miRNA Oxidation Analysis",
  "",
  sprintf("**Generated:** %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  "",
  "---",
  "",
  "## 📊 Pipeline Execution",
  "",
  if (!is.null(execution_info)) {
    c(
      sprintf("- **Status:** %s", execution_info$execution$status),
      sprintf("- **Steps Completed:** %s", paste(execution_info$execution$steps_completed, collapse = ", ")),
      sprintf("- **Total Figures Generated:** %s", as.character(execution_info$outputs$total_figures)),
      sprintf("- **Total Tables Generated:** %s", as.character(execution_info$outputs$total_tables)),
      ""
    )
  },
  "---",
  "",
  "## 📈 Statistical Findings",
  ""
)

if (!is.null(statistical_data) && num_total_mutations > 0) {
  key_findings_lines <- c(key_findings_lines,
    sprintf("- **Total Mutations Analyzed:** %d", num_total_mutations),
    sprintf("- **Significant Mutations (FDR < 0.05):** %d (%.2f%%)", 
            num_significant, 
            round((num_significant / num_total_mutations) * 100, 2)),
    sprintf("- **Significant (t-test):** %d", num_significant_t_test),
    sprintf("- **Significant (Wilcoxon):** %d", num_significant_wilcoxon),
    "",
    "### Top Findings by Effect Size",
    ""
  )
  
  if (!is.null(top_effect_sizes) && nrow(top_effect_sizes) > 0) {
    key_findings_lines <- c(key_findings_lines,
      "| Rank | miRNA | Position | Log2 Fold Change | FDR |",
      "|------|-------|----------|-------------------|-----|"
    )
    
    for (i in 1:nrow(top_effect_sizes)) {
      row <- top_effect_sizes[i, ]
      pos_display <- ifelse(is.na(row$position), as.character(row$pos.mut), as.character(row$position))
      fdr_display <- ifelse(is.na(row$t_test_fdr), "N/A", sprintf("%.4f", row$t_test_fdr))
      
      key_findings_lines <- c(key_findings_lines,
        sprintf("| %d | %s | %s | %.3f | %s |", 
                row$rank, row$miRNA_name, pos_display, row$log2_fold_change, fdr_display)
      )
    }
    key_findings_lines <- c(key_findings_lines, "")
  }
} else {
  key_findings_lines <- c(key_findings_lines,
    "⚠️ Statistical results not available. Run Step 2 to generate statistical comparisons.",
    ""
  )
}

key_findings_lines <- c(key_findings_lines,
  "---",
  "",
  "## 📝 Parameters Used",
  "",
  if (!is.null(execution_info)) {
    c(
      sprintf("- **VAF Threshold:** %s", as.character(execution_info$parameters$vaf_threshold)),
      sprintf("- **Alpha (Significance):** %s", as.character(execution_info$parameters$alpha)),
      sprintf("- **FDR Method:** %s", execution_info$parameters$fdr_method),
      sprintf("- **Log2FC Threshold:** %s", as.character(execution_info$parameters$log2fc_threshold)),
      ""
    )
  },
  "---",
  "",
  "## 🔗 Related Files",
  "",
  "- [Summary Report HTML](summary_report.html)",
  "- [Summary Statistics JSON](summary_statistics.json)",
  "- [Results Index](../INDEX.md)",
  "- [Pipeline Info](../pipeline_info/)",
  ""
)

writeLines(key_findings_lines, file.path(output_dir, "key_findings.md"))
cat("✅ key_findings.md created\n")

cat("\n✅ Summary report generation completed!\n")
cat(sprintf("   Output directory: %s\n", output_dir))
cat(sprintf("   Files created:\n"))
cat(sprintf("     - summary_report.html\n"))
cat(sprintf("     - summary_statistics.json\n"))
cat(sprintf("     - key_findings.md\n"))
