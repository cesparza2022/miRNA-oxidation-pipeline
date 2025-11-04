#!/usr/bin/env Rscript
# ============================================================================
# BUILD STEP 2 VIEWER HTML
# ============================================================================
# Generates HTML viewer for Step 2 results
# ============================================================================

suppressPackageStartupMessages({
  library(readr)
  library(stringr)
})

# Get Snakemake inputs
comparisons_file <- snakemake@input[["comparisons"]]
volcano_plot <- snakemake@input[["volcano"]]
effect_size_table <- snakemake@input[["effect_sizes"]]
effect_size_plot <- snakemake@input[["effect_size_plot"]]

output_html <- snakemake@output[["viewer"]]

# Load comparison results for summary
comparisons <- read_csv(comparisons_file, show_col_types = FALSE)

# Calculate summary statistics
n_total <- nrow(comparisons)
n_significant <- sum(comparisons$significant, na.rm = TRUE)
n_up <- sum(comparisons$significant & !is.na(comparisons$log2_fold_change) & comparisons$log2_fold_change > 0, na.rm = TRUE)
n_down <- sum(comparisons$significant & !is.na(comparisons$log2_fold_change) & comparisons$log2_fold_change < 0, na.rm = TRUE)

# Read image files as base64
encode_image <- function(image_path) {
  if (!file.exists(image_path)) {
    return("")
  }
  con <- file(image_path, "rb")
  img_data <- readBin(con, "raw", file.info(image_path)$size)
  close(con)
  base64_data <- base64enc::base64encode(img_data)
  return(paste0("data:image/png;base64,", base64_data))
}

# Try to load base64enc, fallback if not available
if (!requireNamespace("base64enc", quietly = TRUE)) {
  # Fallback: return relative path
  encode_image <- function(image_path) {
    if (!file.exists(image_path)) {
      return("")
    }
    # Return relative path
    return(image_path)
  }
} else {
  library(base64enc)
  encode_image <- function(image_path) {
    if (!file.exists(image_path)) {
      return("")
    }
    con <- file(image_path, "rb")
    img_data <- readBin(con, "raw", file.info(image_path)$size)
    close(con)
    base64_data <- base64enc::base64encode(img_data)
    return(paste0("data:image/png;base64,", base64_data))
  }
}

volcano_img <- if (file.exists(volcano_plot)) encode_image(volcano_plot) else ""
effect_img <- if (file.exists(effect_size_plot)) encode_image(effect_size_plot) else ""

# Generate HTML
html_content <- paste0('<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>📊 STEP 2: Statistical Comparisons - ALS vs Control</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            background: #f5f5f5;
        }
        .container {
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            padding: 40px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #D62728;
            border-bottom: 3px solid #D62728;
            padding-bottom: 10px;
        }
        .summary {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            margin: 20px 0;
        }
        .summary h2 {
            color: #333;
            margin-top: 0;
        }
        .stat-box {
            display: inline-block;
            margin: 10px 15px;
            padding: 15px 25px;
            background: white;
            border-radius: 5px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }
        .stat-box strong {
            color: #D62728;
            font-size: 1.2em;
        }
        .figure-container {
            margin: 30px 0;
            text-align: center;
        }
        .figure-container img {
            max-width: 100%;
            height: auto;
            border: 1px solid #ddd;
            border-radius: 5px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        .figure-title {
            font-size: 1.2em;
            font-weight: bold;
            color: #333;
            margin: 15px 0 10px 0;
        }
        .figure-description {
            color: #666;
            font-size: 0.95em;
            margin-bottom: 20px;
        }
        .footer {
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #ddd;
            text-align: center;
            color: #666;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>📊 STEP 2: Statistical Comparisons - ALS vs Control</h1>
        
        <div class="summary">
            <h2>📈 Summary Statistics</h2>
            <div class="stat-box">
                <strong>', format(n_total, big.mark = ","), '</strong><br>
                Total SNVs Tested
            </div>
            <div class="stat-box">
                <strong>', n_significant, '</strong><br>
                Significant (FDR < 0.05)
            </div>
            <div class="stat-box">
                <strong>', n_up, '</strong><br>
                Upregulated (ALS > Control)
            </div>
            <div class="stat-box">
                <strong>', n_down, '</strong><br>
                Downregulated (ALS < Control)
            </div>
        </div>
        
        <div class="figure-container">
            <div class="figure-title">Figure 2.1: Volcano Plot</div>
            <div class="figure-description">
                Significance (-log10 FDR) vs Fold Change (log2 FC). 
                Points colored by significance and fold change thresholds.
            </div>
            ', if (volcano_img != "" && str_starts(volcano_img, "data:")) {
              paste0('<img src="', volcano_img, '" alt="Volcano Plot">')
            } else if (volcano_img != "") {
              paste0('<img src="', volcano_img, '" alt="Volcano Plot">')
            } else {
              '<p style="color: red;">⚠️ Volcano plot not found</p>'
            }, '
        </div>
        
        <div class="figure-container">
            <div class="figure-title">Figure 2.2: Effect Size Distribution</div>
            <div class="figure-description">
                Distribution of Cohen\'s d effect sizes. Categories: Large (|d| ≥ 0.8), 
                Medium (0.5 ≤ |d| < 0.8), Small (0.2 ≤ |d| < 0.5), Negligible (|d| < 0.2).
            </div>
            ', if (effect_img != "" && str_starts(effect_img, "data:")) {
              paste0('<img src="', effect_img, '" alt="Effect Size Distribution">')
            } else if (effect_img != "") {
              paste0('<img src="', effect_img, '" alt="Effect Size Distribution">')
            } else {
              '<p style="color: red;">⚠️ Effect size plot not found</p>'
            }, '
        </div>
        
        <div class="footer">
            <p>Pipeline: Snakemake | Step 2: Statistical Comparisons</p>
            <p>Generated: ', Sys.time(), '</p>
        </div>
    </div>
</body>
</html>')

# Write HTML file
writeLines(html_content, output_html)
cat("✅ Step 2 viewer generated:", output_html, "\n")


# BUILD STEP 2 VIEWER HTML
# ============================================================================
# Generates HTML viewer for Step 2 results
# ============================================================================

suppressPackageStartupMessages({
  library(readr)
  library(stringr)
})

# Get Snakemake inputs
comparisons_file <- snakemake@input[["comparisons"]]
volcano_plot <- snakemake@input[["volcano"]]
effect_size_table <- snakemake@input[["effect_sizes"]]
effect_size_plot <- snakemake@input[["effect_size_plot"]]

output_html <- snakemake@output[["viewer"]]

# Load comparison results for summary
comparisons <- read_csv(comparisons_file, show_col_types = FALSE)

# Calculate summary statistics
n_total <- nrow(comparisons)
n_significant <- sum(comparisons$significant, na.rm = TRUE)
n_up <- sum(comparisons$significant & !is.na(comparisons$log2_fold_change) & comparisons$log2_fold_change > 0, na.rm = TRUE)
n_down <- sum(comparisons$significant & !is.na(comparisons$log2_fold_change) & comparisons$log2_fold_change < 0, na.rm = TRUE)

# Read image files as base64
encode_image <- function(image_path) {
  if (!file.exists(image_path)) {
    return("")
  }
  con <- file(image_path, "rb")
  img_data <- readBin(con, "raw", file.info(image_path)$size)
  close(con)
  base64_data <- base64enc::base64encode(img_data)
  return(paste0("data:image/png;base64,", base64_data))
}

# Try to load base64enc, fallback if not available
if (!requireNamespace("base64enc", quietly = TRUE)) {
  # Fallback: return relative path
  encode_image <- function(image_path) {
    if (!file.exists(image_path)) {
      return("")
    }
    # Return relative path
    return(image_path)
  }
} else {
  library(base64enc)
  encode_image <- function(image_path) {
    if (!file.exists(image_path)) {
      return("")
    }
    con <- file(image_path, "rb")
    img_data <- readBin(con, "raw", file.info(image_path)$size)
    close(con)
    base64_data <- base64enc::base64encode(img_data)
    return(paste0("data:image/png;base64,", base64_data))
  }
}

volcano_img <- if (file.exists(volcano_plot)) encode_image(volcano_plot) else ""
effect_img <- if (file.exists(effect_size_plot)) encode_image(effect_size_plot) else ""

# Generate HTML
html_content <- paste0('<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>📊 STEP 2: Statistical Comparisons - ALS vs Control</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            background: #f5f5f5;
        }
        .container {
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            padding: 40px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #D62728;
            border-bottom: 3px solid #D62728;
            padding-bottom: 10px;
        }
        .summary {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            margin: 20px 0;
        }
        .summary h2 {
            color: #333;
            margin-top: 0;
        }
        .stat-box {
            display: inline-block;
            margin: 10px 15px;
            padding: 15px 25px;
            background: white;
            border-radius: 5px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }
        .stat-box strong {
            color: #D62728;
            font-size: 1.2em;
        }
        .figure-container {
            margin: 30px 0;
            text-align: center;
        }
        .figure-container img {
            max-width: 100%;
            height: auto;
            border: 1px solid #ddd;
            border-radius: 5px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        .figure-title {
            font-size: 1.2em;
            font-weight: bold;
            color: #333;
            margin: 15px 0 10px 0;
        }
        .figure-description {
            color: #666;
            font-size: 0.95em;
            margin-bottom: 20px;
        }
        .footer {
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #ddd;
            text-align: center;
            color: #666;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>📊 STEP 2: Statistical Comparisons - ALS vs Control</h1>
        
        <div class="summary">
            <h2>📈 Summary Statistics</h2>
            <div class="stat-box">
                <strong>', format(n_total, big.mark = ","), '</strong><br>
                Total SNVs Tested
            </div>
            <div class="stat-box">
                <strong>', n_significant, '</strong><br>
                Significant (FDR < 0.05)
            </div>
            <div class="stat-box">
                <strong>', n_up, '</strong><br>
                Upregulated (ALS > Control)
            </div>
            <div class="stat-box">
                <strong>', n_down, '</strong><br>
                Downregulated (ALS < Control)
            </div>
        </div>
        
        <div class="figure-container">
            <div class="figure-title">Figure 2.1: Volcano Plot</div>
            <div class="figure-description">
                Significance (-log10 FDR) vs Fold Change (log2 FC). 
                Points colored by significance and fold change thresholds.
            </div>
            ', if (volcano_img != "" && str_starts(volcano_img, "data:")) {
              paste0('<img src="', volcano_img, '" alt="Volcano Plot">')
            } else if (volcano_img != "") {
              paste0('<img src="', volcano_img, '" alt="Volcano Plot">')
            } else {
              '<p style="color: red;">⚠️ Volcano plot not found</p>'
            }, '
        </div>
        
        <div class="figure-container">
            <div class="figure-title">Figure 2.2: Effect Size Distribution</div>
            <div class="figure-description">
                Distribution of Cohen\'s d effect sizes. Categories: Large (|d| ≥ 0.8), 
                Medium (0.5 ≤ |d| < 0.8), Small (0.2 ≤ |d| < 0.5), Negligible (|d| < 0.2).
            </div>
            ', if (effect_img != "" && str_starts(effect_img, "data:")) {
              paste0('<img src="', effect_img, '" alt="Effect Size Distribution">')
            } else if (effect_img != "") {
              paste0('<img src="', effect_img, '" alt="Effect Size Distribution">')
            } else {
              '<p style="color: red;">⚠️ Effect size plot not found</p>'
            }, '
        </div>
        
        <div class="footer">
            <p>Pipeline: Snakemake | Step 2: Statistical Comparisons</p>
            <p>Generated: ', Sys.time(), '</p>
        </div>
    </div>
</body>
</html>')

# Write HTML file
writeLines(html_content, output_html)
cat("✅ Step 2 viewer generated:", output_html, "\n")


# BUILD STEP 2 VIEWER HTML
# ============================================================================
# Generates HTML viewer for Step 2 results
# ============================================================================

suppressPackageStartupMessages({
  library(readr)
  library(stringr)
})

# Get Snakemake inputs
comparisons_file <- snakemake@input[["comparisons"]]
volcano_plot <- snakemake@input[["volcano"]]
effect_size_table <- snakemake@input[["effect_sizes"]]
effect_size_plot <- snakemake@input[["effect_size_plot"]]

output_html <- snakemake@output[["viewer"]]

# Load comparison results for summary
comparisons <- read_csv(comparisons_file, show_col_types = FALSE)

# Calculate summary statistics
n_total <- nrow(comparisons)
n_significant <- sum(comparisons$significant, na.rm = TRUE)
n_up <- sum(comparisons$significant & !is.na(comparisons$log2_fold_change) & comparisons$log2_fold_change > 0, na.rm = TRUE)
n_down <- sum(comparisons$significant & !is.na(comparisons$log2_fold_change) & comparisons$log2_fold_change < 0, na.rm = TRUE)

# Read image files as base64
encode_image <- function(image_path) {
  if (!file.exists(image_path)) {
    return("")
  }
  con <- file(image_path, "rb")
  img_data <- readBin(con, "raw", file.info(image_path)$size)
  close(con)
  base64_data <- base64enc::base64encode(img_data)
  return(paste0("data:image/png;base64,", base64_data))
}

# Try to load base64enc, fallback if not available
if (!requireNamespace("base64enc", quietly = TRUE)) {
  # Fallback: return relative path
  encode_image <- function(image_path) {
    if (!file.exists(image_path)) {
      return("")
    }
    # Return relative path
    return(image_path)
  }
} else {
  library(base64enc)
  encode_image <- function(image_path) {
    if (!file.exists(image_path)) {
      return("")
    }
    con <- file(image_path, "rb")
    img_data <- readBin(con, "raw", file.info(image_path)$size)
    close(con)
    base64_data <- base64enc::base64encode(img_data)
    return(paste0("data:image/png;base64,", base64_data))
  }
}

volcano_img <- if (file.exists(volcano_plot)) encode_image(volcano_plot) else ""
effect_img <- if (file.exists(effect_size_plot)) encode_image(effect_size_plot) else ""

# Generate HTML
html_content <- paste0('<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>📊 STEP 2: Statistical Comparisons - ALS vs Control</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            background: #f5f5f5;
        }
        .container {
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            padding: 40px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #D62728;
            border-bottom: 3px solid #D62728;
            padding-bottom: 10px;
        }
        .summary {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            margin: 20px 0;
        }
        .summary h2 {
            color: #333;
            margin-top: 0;
        }
        .stat-box {
            display: inline-block;
            margin: 10px 15px;
            padding: 15px 25px;
            background: white;
            border-radius: 5px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }
        .stat-box strong {
            color: #D62728;
            font-size: 1.2em;
        }
        .figure-container {
            margin: 30px 0;
            text-align: center;
        }
        .figure-container img {
            max-width: 100%;
            height: auto;
            border: 1px solid #ddd;
            border-radius: 5px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        .figure-title {
            font-size: 1.2em;
            font-weight: bold;
            color: #333;
            margin: 15px 0 10px 0;
        }
        .figure-description {
            color: #666;
            font-size: 0.95em;
            margin-bottom: 20px;
        }
        .footer {
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #ddd;
            text-align: center;
            color: #666;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>📊 STEP 2: Statistical Comparisons - ALS vs Control</h1>
        
        <div class="summary">
            <h2>📈 Summary Statistics</h2>
            <div class="stat-box">
                <strong>', format(n_total, big.mark = ","), '</strong><br>
                Total SNVs Tested
            </div>
            <div class="stat-box">
                <strong>', n_significant, '</strong><br>
                Significant (FDR < 0.05)
            </div>
            <div class="stat-box">
                <strong>', n_up, '</strong><br>
                Upregulated (ALS > Control)
            </div>
            <div class="stat-box">
                <strong>', n_down, '</strong><br>
                Downregulated (ALS < Control)
            </div>
        </div>
        
        <div class="figure-container">
            <div class="figure-title">Figure 2.1: Volcano Plot</div>
            <div class="figure-description">
                Significance (-log10 FDR) vs Fold Change (log2 FC). 
                Points colored by significance and fold change thresholds.
            </div>
            ', if (volcano_img != "" && str_starts(volcano_img, "data:")) {
              paste0('<img src="', volcano_img, '" alt="Volcano Plot">')
            } else if (volcano_img != "") {
              paste0('<img src="', volcano_img, '" alt="Volcano Plot">')
            } else {
              '<p style="color: red;">⚠️ Volcano plot not found</p>'
            }, '
        </div>
        
        <div class="figure-container">
            <div class="figure-title">Figure 2.2: Effect Size Distribution</div>
            <div class="figure-description">
                Distribution of Cohen\'s d effect sizes. Categories: Large (|d| ≥ 0.8), 
                Medium (0.5 ≤ |d| < 0.8), Small (0.2 ≤ |d| < 0.5), Negligible (|d| < 0.2).
            </div>
            ', if (effect_img != "" && str_starts(effect_img, "data:")) {
              paste0('<img src="', effect_img, '" alt="Effect Size Distribution">')
            } else if (effect_img != "") {
              paste0('<img src="', effect_img, '" alt="Effect Size Distribution">')
            } else {
              '<p style="color: red;">⚠️ Effect size plot not found</p>'
            }, '
        </div>
        
        <div class="footer">
            <p>Pipeline: Snakemake | Step 2: Statistical Comparisons</p>
            <p>Generated: ', Sys.time(), '</p>
        </div>
    </div>
</body>
</html>')

# Write HTML file
writeLines(html_content, output_html)
cat("✅ Step 2 viewer generated:", output_html, "\n")

