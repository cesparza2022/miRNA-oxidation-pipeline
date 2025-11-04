#!/usr/bin/env Rscript
# ============================================================================
# BUILD STEP 1.5 HTML VIEWER (Snakemake version)
# ============================================================================
# Generates an HTML viewer with all Step 1.5 figures and tables
# Uses Snakemake input/output structure

suppressPackageStartupMessages({
  library(base64enc)
})

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  🌐 BUILDING STEP 1.5 HTML VIEWER\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# ============================================================================
# GET SNAKEMAKE PARAMETERS
# ============================================================================

# Get paths from Snakemake
output_html <- snakemake@output[["html"]]
figures_dir <- snakemake@params[["figures_dir"]]
tables_dir <- snakemake@params[["tables_dir"]]

cat("📋 Parameters:\n")
cat("   Output HTML:", output_html, "\n")
cat("   Figures dir:", figures_dir, "\n")
cat("   Tables dir:", tables_dir, "\n\n")

# ============================================================================
# DEFINE FIGURES AND DESCRIPTIONS
# ============================================================================

panels <- list(
  # QC Figures (4)
  list(
    id = "QC1",
    title = "VAF Distribution of Filtered Values",
    filename = "QC_FIG1_VAF_DISTRIBUTION.png",
    description = "Distribution of Variant Allele Frequencies (VAF) for all values that were filtered (VAF >= 0.5). These represent technical artifacts that would skew downstream analyses.",
    category = "Quality Control"
  ),
  list(
    id = "QC2",
    title = "Filter Impact by Mutation Type",
    filename = "QC_FIG2_FILTER_IMPACT.png",
    description = "Number of filtered values per mutation type. Shows which mutation types were most affected by the VAF filter.",
    category = "Quality Control"
  ),
  list(
    id = "QC3",
    title = "Top 20 Most Affected miRNAs",
    filename = "QC_FIG3_AFFECTED_MIRNAS.png",
    description = "miRNAs with the highest number of filtered values. Helps identify miRNAs that may have technical issues.",
    category = "Quality Control"
  ),
  list(
    id = "QC4",
    title = "Data Quality Before vs After VAF Filter",
    filename = "QC_FIG4_BEFORE_AFTER.png",
    description = "Comparison of total valid values before and after VAF filtering. Shows the impact of filtering on dataset size.",
    category = "Quality Control"
  ),
  # Diagnostic Figures (7)
  list(
    id = "D1",
    title = "SNVs by Position - VAF-Filtered",
    filename = "STEP1.5_FIG1_HEATMAP_SNVS.png",
    description = "Heatmap showing the number of SNVs by position and mutation type after VAF filtering. G>T (oxidation) is highlighted in red.",
    category = "Diagnostic"
  ),
  list(
    id = "D2",
    title = "Total Counts by Position - VAF-Filtered",
    filename = "STEP1.5_FIG2_HEATMAP_COUNTS.png",
    description = "Heatmap of sequencing depth (total counts) by position and mutation type. Log scale to visualize patterns across different orders of magnitude.",
    category = "Diagnostic"
  ),
  list(
    id = "D3",
    title = "G Transversions - SNVs by Position",
    filename = "STEP1.5_FIG3_G_TRANSVERSIONS_SNVS.png",
    description = "Comparison of G>T (oxidation), G>A, and G>C mutations across positions. Shows the specificity of oxidative damage (8-oxoG) relative to other G mutations.",
    category = "Diagnostic"
  ),
  list(
    id = "D4",
    title = "G Transversions - Counts by Position",
    filename = "STEP1.5_FIG4_G_TRANSVERSIONS_COUNTS.png",
    description = "Sequencing depth for G transversions across positions. Provides context for the abundance of each G mutation type.",
    category = "Diagnostic"
  ),
  list(
    id = "D5",
    title = "SNVs vs Counts Bubble Plot",
    filename = "STEP1.5_FIG5_BUBBLE_PLOT.png",
    description = "Bubble plot showing the relationship between mean SNVs per sample and mean total counts per sample. Bubble size represents variability (SD). G>T is shown as a diamond.",
    category = "Diagnostic"
  ),
  list(
    id = "D6",
    title = "Complete Distributions - Violin Plots",
    filename = "STEP1.5_FIG6_VIOLIN_DISTRIBUTIONS.png",
    description = "Violin plots showing the distribution of SNVs and counts per sample for the top 8 mutation types. Includes boxplots and mean markers.",
    category = "Diagnostic"
  ),
  list(
    id = "D7",
    title = "Fold Change vs G>T",
    filename = "STEP1.5_FIG7_FOLD_CHANGE.png",
    description = "Fold change of each mutation type relative to G>T. Shows the relative abundance of other mutations compared to oxidative damage (G>T).",
    category = "Diagnostic"
  )
)

# ============================================================================
# HELPER FUNCTION: Encode image to base64
# ============================================================================

encode_image_base64 <- function(image_path) {
  if (!file.exists(image_path)) {
    return(NULL)
  }
  tryCatch({
    image_data <- readBin(image_path, "raw", file.info(image_path)$size)
    base64_data <- base64encode(image_data)
    ext <- tools::file_ext(image_path)
    mime_type <- switch(tolower(ext),
      "png" = "image/png",
      "jpg" = "image/jpeg",
      "jpeg" = "image/jpeg",
      "svg" = "image/svg+xml",
      "image/png"  # default
    )
    return(paste0("data:", mime_type, ";base64,", base64_data))
  }, error = function(e) {
    cat("   ⚠️  Warning: Could not encode", image_path, ":", e$message, "\n")
    return(NULL)
  })
}

# ============================================================================
# COLLECT FIGURES AND TABLES
# ============================================================================

cat("📊 Collecting figures and tables...\n")

available_panels <- list()
for (panel in panels) {
  fig_path <- file.path(figures_dir, panel$filename)
  
  if (file.exists(fig_path)) {
    panel$figure_path <- fig_path
    panel$figure_base64 <- encode_image_base64(fig_path)
    available_panels[[length(available_panels) + 1]] <- panel
    cat("   ✅", panel$id, "-", panel$title, "\n")
  } else {
    cat("   ⚠️ ", panel$id, "- Figure not found:", fig_path, "\n")
  }
}

if (length(available_panels) == 0) {
  stop("❌ No figures found! Cannot generate viewer.")
}

cat("\n✅ Found", length(available_panels), "panels with figures\n\n")

# Separate QC and Diagnostic panels
qc_panels <- Filter(function(p) p$category == "Quality Control", available_panels)
diag_panels <- Filter(function(p) p$category == "Diagnostic", available_panels)

# ============================================================================
# GENERATE HTML CONTENT
# ============================================================================

cat("🌐 Generating HTML content...\n")

html_content <- paste0('<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>📊 STEP 1.5: VAF Quality Control</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, \'Segoe UI\', Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            background: linear-gradient(135deg, #2CA02C 0%, #667eea 100%);
            padding: 20px;
        }
        
        .container {
            max-width: 1800px;
            margin: 0 auto;
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            padding: 50px;
        }
        
        header {
            text-align: center;
            margin-bottom: 50px;
            padding-bottom: 30px;
            border-bottom: 4px solid #2CA02C;
        }
        
        h1 {
            color: #2CA02C;
            font-size: 3em;
            margin-bottom: 15px;
            font-weight: 800;
        }
        
        .subtitle {
            color: #666;
            font-size: 1.3em;
            margin: 10px 0;
        }
        
        .section {
            margin: 40px 0;
            padding: 30px;
            background: #f8f9fa;
            border-radius: 15px;
            border-left: 5px solid #2CA02C;
        }
        
        .section.qc {
            border-left-color: #D62728;
        }
        
        .section.diag {
            border-left-color: #667eea;
        }
        
        .grid-2 {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 30px;
            margin: 30px 0;
        }
        
        .grid-3 {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 30px;
            margin: 30px 0;
        }
        
        .figure-container {
            background: white;
            border: 2px solid #e9ecef;
            border-radius: 15px;
            padding: 25px;
            text-align: center;
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
            transition: transform 0.3s ease;
        }
        
        .figure-container:hover {
            transform: translateY(-5px);
            box-shadow: 0 10px 25px rgba(0,0,0,0.15);
        }
        
        .figure-title {
            font-weight: 700;
            color: #2CA02C;
            font-size: 1.2em;
            margin-bottom: 15px;
        }
        
        .figure-container img {
            max-width: 100%;
            height: auto;
            border-radius: 10px;
            box-shadow: 0 3px 10px rgba(0,0,0,0.1);
        }
        
        .figure-description {
            color: #555;
            font-size: 0.95em;
            margin-top: 15px;
            line-height: 1.5;
        }
        
        .category-badge {
            display: inline-block;
            padding: 5px 12px;
            border-radius: 20px;
            font-size: 0.8em;
            font-weight: 600;
            margin-bottom: 10px;
        }
        
        .badge-qc {
            background: #D62728;
            color: white;
        }
        
        .badge-diag {
            background: #667eea;
            color: white;
        }
        
        .footer {
            text-align: center;
            margin-top: 50px;
            padding-top: 30px;
            border-top: 2px solid #e9ecef;
            color: #666;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>📊 STEP 1.5: VAF Quality Control</h1>
            <div class="subtitle">Variant Allele Frequency Filtering & Diagnostic Analysis</div>
            <div class="subtitle" style="font-size: 1em; margin-top: 10px;">
                Generated: ', Sys.Date(), '
            </div>
        </header>
        
        <div class="section">
            <h2 style="color: #2CA02C; margin-bottom: 20px;">Overview</h2>
            <p style="font-size: 1.1em; color: #555; line-height: 1.8;">
                This step applies <strong>Variant Allele Frequency (VAF) filtering</strong> to remove technical artifacts.
                Values with VAF >= 0.5 (≥50% of reads showing the variant) are considered technical artifacts and removed.
                The viewer shows both <strong>Quality Control figures</strong> (demonstrating filter impact) and <strong>Diagnostic figures</strong>
                (showing the cleaned dataset equivalent to Step 1 analysis but with artifacts removed).
            </p>
        </div>')

# Add QC Figures section
if (length(qc_panels) > 0) {
  html_content <- paste0(html_content, '
        <div class="section qc">
            <h2 style="color: #D62728; margin-bottom: 30px;">🔍 Quality Control Figures (', length(qc_panels), ')</h2>
            <p style="margin-bottom: 20px; color: #666;">
                These figures demonstrate the impact of VAF filtering and help validate the quality control process.
            </p>
            <div class="grid-2">')
  
  for (panel in qc_panels) {
    img_tag <- if (!is.null(panel$figure_base64)) {
      paste0('<img src="', panel$figure_base64, '" alt="', panel$title, '">')
    } else {
      paste0('<div style="padding: 40px; color: #999;">Figure not available</div>')
    }
    
    html_content <- paste0(html_content, '
                <div class="figure-container">
                    <span class="category-badge badge-qc">QC</span>
                    <div class="figure-title">', panel$title, '</div>
                    ', img_tag, '
                    <div class="figure-description">', panel$description, '</div>
                </div>')
  }
  
  html_content <- paste0(html_content, '
            </div>
        </div>')
}

# Add Diagnostic Figures section
if (length(diag_panels) > 0) {
  html_content <- paste0(html_content, '
        <div class="section diag">
            <h2 style="color: #667eea; margin-bottom: 30px;">📈 Diagnostic Figures (', length(diag_panels), ')</h2>
            <p style="margin-bottom: 20px; color: #666;">
                These figures replicate the Step 1 exploratory analysis but on VAF-filtered data (artifacts removed).
                Compare these with Step 1 figures to see the impact of quality control.
            </p>
            <div class="grid-2">')
  
  for (panel in diag_panels) {
    img_tag <- if (!is.null(panel$figure_base64)) {
      paste0('<img src="', panel$figure_base64, '" alt="', panel$title, '">')
    } else {
      paste0('<div style="padding: 40px; color: #999;">Figure not available</div>')
    }
    
    html_content <- paste0(html_content, '
                <div class="figure-container">
                    <span class="category-badge badge-diag">Diagnostic</span>
                    <div class="figure-title">', panel$title, '</div>
                    ', img_tag, '
                    <div class="figure-description">', panel$description, '</div>
                </div>')
  }
  
  html_content <- paste0(html_content, '
            </div>
        </div>')
}

# Add tables section
html_content <- paste0(html_content, '
        <div class="section">
            <h2 style="color: #2CA02C; margin-bottom: 20px;">📋 Summary Tables</h2>
            <p style="margin-bottom: 20px; color: #666;">
                The following tables are available in the outputs/tables/ directory:
            </p>
            <ul style="line-height: 2; color: #555; font-size: 1.05em;">
                <li><strong>ALL_MUTATIONS_VAF_FILTERED.csv</strong> - Main dataset with VAF-filtered values (NAs)</li>
                <li><strong>vaf_filter_report.csv</strong> - Detailed log of all filtered values</li>
                <li><strong>vaf_statistics_by_type.csv</strong> - Statistics by mutation type</li>
                <li><strong>vaf_statistics_by_mirna.csv</strong> - Statistics by miRNA</li>
                <li><strong>sample_metrics_vaf_filtered.csv</strong> - Metrics per sample</li>
                <li><strong>position_metrics_vaf_filtered.csv</strong> - Metrics per position</li>
                <li><strong>mutation_type_summary_vaf_filtered.csv</strong> - Summary by mutation type</li>
            </ul>
        </div>
        
        <div class="footer">
            <p>Pipeline: Snakemake | Step 1.5: VAF Quality Control</p>
            <p style="font-size: 0.9em; margin-top: 10px;">
                Total figures: ', length(available_panels), ' (', length(qc_panels), ' QC + ', length(diag_panels), ' Diagnostic) | Generated: ', format(Sys.time(), "%Y-%m-%d %H:%M:%S"), '
            </p>
        </div>
    </div>
</body>
</html>')

# ============================================================================
# WRITE HTML FILE
# ============================================================================

cat("💾 Writing HTML file...\n")
writeLines(html_content, output_html)
cat("   ✅ HTML viewer saved:", output_html, "\n")
cat("   📄 File size:", format(file.info(output_html)$size, big.mark = ","), "bytes\n\n")

cat("═══════════════════════════════════════════════════════════════════\n")
cat("✅ STEP 1.5 HTML VIEWER COMPLETE!\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

# ============================================================================
# BUILD STEP 1.5 HTML VIEWER (Snakemake version)
# ============================================================================
# Generates an HTML viewer with all Step 1.5 figures and tables
# Uses Snakemake input/output structure

suppressPackageStartupMessages({
  library(base64enc)
})

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  🌐 BUILDING STEP 1.5 HTML VIEWER\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# ============================================================================
# GET SNAKEMAKE PARAMETERS
# ============================================================================

# Get paths from Snakemake
output_html <- snakemake@output[["html"]]
figures_dir <- snakemake@params[["figures_dir"]]
tables_dir <- snakemake@params[["tables_dir"]]

cat("📋 Parameters:\n")
cat("   Output HTML:", output_html, "\n")
cat("   Figures dir:", figures_dir, "\n")
cat("   Tables dir:", tables_dir, "\n\n")

# ============================================================================
# DEFINE FIGURES AND DESCRIPTIONS
# ============================================================================

panels <- list(
  # QC Figures (4)
  list(
    id = "QC1",
    title = "VAF Distribution of Filtered Values",
    filename = "QC_FIG1_VAF_DISTRIBUTION.png",
    description = "Distribution of Variant Allele Frequencies (VAF) for all values that were filtered (VAF >= 0.5). These represent technical artifacts that would skew downstream analyses.",
    category = "Quality Control"
  ),
  list(
    id = "QC2",
    title = "Filter Impact by Mutation Type",
    filename = "QC_FIG2_FILTER_IMPACT.png",
    description = "Number of filtered values per mutation type. Shows which mutation types were most affected by the VAF filter.",
    category = "Quality Control"
  ),
  list(
    id = "QC3",
    title = "Top 20 Most Affected miRNAs",
    filename = "QC_FIG3_AFFECTED_MIRNAS.png",
    description = "miRNAs with the highest number of filtered values. Helps identify miRNAs that may have technical issues.",
    category = "Quality Control"
  ),
  list(
    id = "QC4",
    title = "Data Quality Before vs After VAF Filter",
    filename = "QC_FIG4_BEFORE_AFTER.png",
    description = "Comparison of total valid values before and after VAF filtering. Shows the impact of filtering on dataset size.",
    category = "Quality Control"
  ),
  # Diagnostic Figures (7)
  list(
    id = "D1",
    title = "SNVs by Position - VAF-Filtered",
    filename = "STEP1.5_FIG1_HEATMAP_SNVS.png",
    description = "Heatmap showing the number of SNVs by position and mutation type after VAF filtering. G>T (oxidation) is highlighted in red.",
    category = "Diagnostic"
  ),
  list(
    id = "D2",
    title = "Total Counts by Position - VAF-Filtered",
    filename = "STEP1.5_FIG2_HEATMAP_COUNTS.png",
    description = "Heatmap of sequencing depth (total counts) by position and mutation type. Log scale to visualize patterns across different orders of magnitude.",
    category = "Diagnostic"
  ),
  list(
    id = "D3",
    title = "G Transversions - SNVs by Position",
    filename = "STEP1.5_FIG3_G_TRANSVERSIONS_SNVS.png",
    description = "Comparison of G>T (oxidation), G>A, and G>C mutations across positions. Shows the specificity of oxidative damage (8-oxoG) relative to other G mutations.",
    category = "Diagnostic"
  ),
  list(
    id = "D4",
    title = "G Transversions - Counts by Position",
    filename = "STEP1.5_FIG4_G_TRANSVERSIONS_COUNTS.png",
    description = "Sequencing depth for G transversions across positions. Provides context for the abundance of each G mutation type.",
    category = "Diagnostic"
  ),
  list(
    id = "D5",
    title = "SNVs vs Counts Bubble Plot",
    filename = "STEP1.5_FIG5_BUBBLE_PLOT.png",
    description = "Bubble plot showing the relationship between mean SNVs per sample and mean total counts per sample. Bubble size represents variability (SD). G>T is shown as a diamond.",
    category = "Diagnostic"
  ),
  list(
    id = "D6",
    title = "Complete Distributions - Violin Plots",
    filename = "STEP1.5_FIG6_VIOLIN_DISTRIBUTIONS.png",
    description = "Violin plots showing the distribution of SNVs and counts per sample for the top 8 mutation types. Includes boxplots and mean markers.",
    category = "Diagnostic"
  ),
  list(
    id = "D7",
    title = "Fold Change vs G>T",
    filename = "STEP1.5_FIG7_FOLD_CHANGE.png",
    description = "Fold change of each mutation type relative to G>T. Shows the relative abundance of other mutations compared to oxidative damage (G>T).",
    category = "Diagnostic"
  )
)

# ============================================================================
# HELPER FUNCTION: Encode image to base64
# ============================================================================

encode_image_base64 <- function(image_path) {
  if (!file.exists(image_path)) {
    return(NULL)
  }
  tryCatch({
    image_data <- readBin(image_path, "raw", file.info(image_path)$size)
    base64_data <- base64encode(image_data)
    ext <- tools::file_ext(image_path)
    mime_type <- switch(tolower(ext),
      "png" = "image/png",
      "jpg" = "image/jpeg",
      "jpeg" = "image/jpeg",
      "svg" = "image/svg+xml",
      "image/png"  # default
    )
    return(paste0("data:", mime_type, ";base64,", base64_data))
  }, error = function(e) {
    cat("   ⚠️  Warning: Could not encode", image_path, ":", e$message, "\n")
    return(NULL)
  })
}

# ============================================================================
# COLLECT FIGURES AND TABLES
# ============================================================================

cat("📊 Collecting figures and tables...\n")

available_panels <- list()
for (panel in panels) {
  fig_path <- file.path(figures_dir, panel$filename)
  
  if (file.exists(fig_path)) {
    panel$figure_path <- fig_path
    panel$figure_base64 <- encode_image_base64(fig_path)
    available_panels[[length(available_panels) + 1]] <- panel
    cat("   ✅", panel$id, "-", panel$title, "\n")
  } else {
    cat("   ⚠️ ", panel$id, "- Figure not found:", fig_path, "\n")
  }
}

if (length(available_panels) == 0) {
  stop("❌ No figures found! Cannot generate viewer.")
}

cat("\n✅ Found", length(available_panels), "panels with figures\n\n")

# Separate QC and Diagnostic panels
qc_panels <- Filter(function(p) p$category == "Quality Control", available_panels)
diag_panels <- Filter(function(p) p$category == "Diagnostic", available_panels)

# ============================================================================
# GENERATE HTML CONTENT
# ============================================================================

cat("🌐 Generating HTML content...\n")

html_content <- paste0('<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>📊 STEP 1.5: VAF Quality Control</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, \'Segoe UI\', Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            background: linear-gradient(135deg, #2CA02C 0%, #667eea 100%);
            padding: 20px;
        }
        
        .container {
            max-width: 1800px;
            margin: 0 auto;
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            padding: 50px;
        }
        
        header {
            text-align: center;
            margin-bottom: 50px;
            padding-bottom: 30px;
            border-bottom: 4px solid #2CA02C;
        }
        
        h1 {
            color: #2CA02C;
            font-size: 3em;
            margin-bottom: 15px;
            font-weight: 800;
        }
        
        .subtitle {
            color: #666;
            font-size: 1.3em;
            margin: 10px 0;
        }
        
        .section {
            margin: 40px 0;
            padding: 30px;
            background: #f8f9fa;
            border-radius: 15px;
            border-left: 5px solid #2CA02C;
        }
        
        .section.qc {
            border-left-color: #D62728;
        }
        
        .section.diag {
            border-left-color: #667eea;
        }
        
        .grid-2 {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 30px;
            margin: 30px 0;
        }
        
        .grid-3 {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 30px;
            margin: 30px 0;
        }
        
        .figure-container {
            background: white;
            border: 2px solid #e9ecef;
            border-radius: 15px;
            padding: 25px;
            text-align: center;
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
            transition: transform 0.3s ease;
        }
        
        .figure-container:hover {
            transform: translateY(-5px);
            box-shadow: 0 10px 25px rgba(0,0,0,0.15);
        }
        
        .figure-title {
            font-weight: 700;
            color: #2CA02C;
            font-size: 1.2em;
            margin-bottom: 15px;
        }
        
        .figure-container img {
            max-width: 100%;
            height: auto;
            border-radius: 10px;
            box-shadow: 0 3px 10px rgba(0,0,0,0.1);
        }
        
        .figure-description {
            color: #555;
            font-size: 0.95em;
            margin-top: 15px;
            line-height: 1.5;
        }
        
        .category-badge {
            display: inline-block;
            padding: 5px 12px;
            border-radius: 20px;
            font-size: 0.8em;
            font-weight: 600;
            margin-bottom: 10px;
        }
        
        .badge-qc {
            background: #D62728;
            color: white;
        }
        
        .badge-diag {
            background: #667eea;
            color: white;
        }
        
        .footer {
            text-align: center;
            margin-top: 50px;
            padding-top: 30px;
            border-top: 2px solid #e9ecef;
            color: #666;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>📊 STEP 1.5: VAF Quality Control</h1>
            <div class="subtitle">Variant Allele Frequency Filtering & Diagnostic Analysis</div>
            <div class="subtitle" style="font-size: 1em; margin-top: 10px;">
                Generated: ', Sys.Date(), '
            </div>
        </header>
        
        <div class="section">
            <h2 style="color: #2CA02C; margin-bottom: 20px;">Overview</h2>
            <p style="font-size: 1.1em; color: #555; line-height: 1.8;">
                This step applies <strong>Variant Allele Frequency (VAF) filtering</strong> to remove technical artifacts.
                Values with VAF >= 0.5 (≥50% of reads showing the variant) are considered technical artifacts and removed.
                The viewer shows both <strong>Quality Control figures</strong> (demonstrating filter impact) and <strong>Diagnostic figures</strong>
                (showing the cleaned dataset equivalent to Step 1 analysis but with artifacts removed).
            </p>
        </div>')

# Add QC Figures section
if (length(qc_panels) > 0) {
  html_content <- paste0(html_content, '
        <div class="section qc">
            <h2 style="color: #D62728; margin-bottom: 30px;">🔍 Quality Control Figures (', length(qc_panels), ')</h2>
            <p style="margin-bottom: 20px; color: #666;">
                These figures demonstrate the impact of VAF filtering and help validate the quality control process.
            </p>
            <div class="grid-2">')
  
  for (panel in qc_panels) {
    img_tag <- if (!is.null(panel$figure_base64)) {
      paste0('<img src="', panel$figure_base64, '" alt="', panel$title, '">')
    } else {
      paste0('<div style="padding: 40px; color: #999;">Figure not available</div>')
    }
    
    html_content <- paste0(html_content, '
                <div class="figure-container">
                    <span class="category-badge badge-qc">QC</span>
                    <div class="figure-title">', panel$title, '</div>
                    ', img_tag, '
                    <div class="figure-description">', panel$description, '</div>
                </div>')
  }
  
  html_content <- paste0(html_content, '
            </div>
        </div>')
}

# Add Diagnostic Figures section
if (length(diag_panels) > 0) {
  html_content <- paste0(html_content, '
        <div class="section diag">
            <h2 style="color: #667eea; margin-bottom: 30px;">📈 Diagnostic Figures (', length(diag_panels), ')</h2>
            <p style="margin-bottom: 20px; color: #666;">
                These figures replicate the Step 1 exploratory analysis but on VAF-filtered data (artifacts removed).
                Compare these with Step 1 figures to see the impact of quality control.
            </p>
            <div class="grid-2">')
  
  for (panel in diag_panels) {
    img_tag <- if (!is.null(panel$figure_base64)) {
      paste0('<img src="', panel$figure_base64, '" alt="', panel$title, '">')
    } else {
      paste0('<div style="padding: 40px; color: #999;">Figure not available</div>')
    }
    
    html_content <- paste0(html_content, '
                <div class="figure-container">
                    <span class="category-badge badge-diag">Diagnostic</span>
                    <div class="figure-title">', panel$title, '</div>
                    ', img_tag, '
                    <div class="figure-description">', panel$description, '</div>
                </div>')
  }
  
  html_content <- paste0(html_content, '
            </div>
        </div>')
}

# Add tables section
html_content <- paste0(html_content, '
        <div class="section">
            <h2 style="color: #2CA02C; margin-bottom: 20px;">📋 Summary Tables</h2>
            <p style="margin-bottom: 20px; color: #666;">
                The following tables are available in the outputs/tables/ directory:
            </p>
            <ul style="line-height: 2; color: #555; font-size: 1.05em;">
                <li><strong>ALL_MUTATIONS_VAF_FILTERED.csv</strong> - Main dataset with VAF-filtered values (NAs)</li>
                <li><strong>vaf_filter_report.csv</strong> - Detailed log of all filtered values</li>
                <li><strong>vaf_statistics_by_type.csv</strong> - Statistics by mutation type</li>
                <li><strong>vaf_statistics_by_mirna.csv</strong> - Statistics by miRNA</li>
                <li><strong>sample_metrics_vaf_filtered.csv</strong> - Metrics per sample</li>
                <li><strong>position_metrics_vaf_filtered.csv</strong> - Metrics per position</li>
                <li><strong>mutation_type_summary_vaf_filtered.csv</strong> - Summary by mutation type</li>
            </ul>
        </div>
        
        <div class="footer">
            <p>Pipeline: Snakemake | Step 1.5: VAF Quality Control</p>
            <p style="font-size: 0.9em; margin-top: 10px;">
                Total figures: ', length(available_panels), ' (', length(qc_panels), ' QC + ', length(diag_panels), ' Diagnostic) | Generated: ', format(Sys.time(), "%Y-%m-%d %H:%M:%S"), '
            </p>
        </div>
    </div>
</body>
</html>')

# ============================================================================
# WRITE HTML FILE
# ============================================================================

cat("💾 Writing HTML file...\n")
writeLines(html_content, output_html)
cat("   ✅ HTML viewer saved:", output_html, "\n")
cat("   📄 File size:", format(file.info(output_html)$size, big.mark = ","), "bytes\n\n")

cat("═══════════════════════════════════════════════════════════════════\n")
cat("✅ STEP 1.5 HTML VIEWER COMPLETE!\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

# ============================================================================
# BUILD STEP 1.5 HTML VIEWER (Snakemake version)
# ============================================================================
# Generates an HTML viewer with all Step 1.5 figures and tables
# Uses Snakemake input/output structure

suppressPackageStartupMessages({
  library(base64enc)
})

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  🌐 BUILDING STEP 1.5 HTML VIEWER\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# ============================================================================
# GET SNAKEMAKE PARAMETERS
# ============================================================================

# Get paths from Snakemake
output_html <- snakemake@output[["html"]]
figures_dir <- snakemake@params[["figures_dir"]]
tables_dir <- snakemake@params[["tables_dir"]]

cat("📋 Parameters:\n")
cat("   Output HTML:", output_html, "\n")
cat("   Figures dir:", figures_dir, "\n")
cat("   Tables dir:", tables_dir, "\n\n")

# ============================================================================
# DEFINE FIGURES AND DESCRIPTIONS
# ============================================================================

panels <- list(
  # QC Figures (4)
  list(
    id = "QC1",
    title = "VAF Distribution of Filtered Values",
    filename = "QC_FIG1_VAF_DISTRIBUTION.png",
    description = "Distribution of Variant Allele Frequencies (VAF) for all values that were filtered (VAF >= 0.5). These represent technical artifacts that would skew downstream analyses.",
    category = "Quality Control"
  ),
  list(
    id = "QC2",
    title = "Filter Impact by Mutation Type",
    filename = "QC_FIG2_FILTER_IMPACT.png",
    description = "Number of filtered values per mutation type. Shows which mutation types were most affected by the VAF filter.",
    category = "Quality Control"
  ),
  list(
    id = "QC3",
    title = "Top 20 Most Affected miRNAs",
    filename = "QC_FIG3_AFFECTED_MIRNAS.png",
    description = "miRNAs with the highest number of filtered values. Helps identify miRNAs that may have technical issues.",
    category = "Quality Control"
  ),
  list(
    id = "QC4",
    title = "Data Quality Before vs After VAF Filter",
    filename = "QC_FIG4_BEFORE_AFTER.png",
    description = "Comparison of total valid values before and after VAF filtering. Shows the impact of filtering on dataset size.",
    category = "Quality Control"
  ),
  # Diagnostic Figures (7)
  list(
    id = "D1",
    title = "SNVs by Position - VAF-Filtered",
    filename = "STEP1.5_FIG1_HEATMAP_SNVS.png",
    description = "Heatmap showing the number of SNVs by position and mutation type after VAF filtering. G>T (oxidation) is highlighted in red.",
    category = "Diagnostic"
  ),
  list(
    id = "D2",
    title = "Total Counts by Position - VAF-Filtered",
    filename = "STEP1.5_FIG2_HEATMAP_COUNTS.png",
    description = "Heatmap of sequencing depth (total counts) by position and mutation type. Log scale to visualize patterns across different orders of magnitude.",
    category = "Diagnostic"
  ),
  list(
    id = "D3",
    title = "G Transversions - SNVs by Position",
    filename = "STEP1.5_FIG3_G_TRANSVERSIONS_SNVS.png",
    description = "Comparison of G>T (oxidation), G>A, and G>C mutations across positions. Shows the specificity of oxidative damage (8-oxoG) relative to other G mutations.",
    category = "Diagnostic"
  ),
  list(
    id = "D4",
    title = "G Transversions - Counts by Position",
    filename = "STEP1.5_FIG4_G_TRANSVERSIONS_COUNTS.png",
    description = "Sequencing depth for G transversions across positions. Provides context for the abundance of each G mutation type.",
    category = "Diagnostic"
  ),
  list(
    id = "D5",
    title = "SNVs vs Counts Bubble Plot",
    filename = "STEP1.5_FIG5_BUBBLE_PLOT.png",
    description = "Bubble plot showing the relationship between mean SNVs per sample and mean total counts per sample. Bubble size represents variability (SD). G>T is shown as a diamond.",
    category = "Diagnostic"
  ),
  list(
    id = "D6",
    title = "Complete Distributions - Violin Plots",
    filename = "STEP1.5_FIG6_VIOLIN_DISTRIBUTIONS.png",
    description = "Violin plots showing the distribution of SNVs and counts per sample for the top 8 mutation types. Includes boxplots and mean markers.",
    category = "Diagnostic"
  ),
  list(
    id = "D7",
    title = "Fold Change vs G>T",
    filename = "STEP1.5_FIG7_FOLD_CHANGE.png",
    description = "Fold change of each mutation type relative to G>T. Shows the relative abundance of other mutations compared to oxidative damage (G>T).",
    category = "Diagnostic"
  )
)

# ============================================================================
# HELPER FUNCTION: Encode image to base64
# ============================================================================

encode_image_base64 <- function(image_path) {
  if (!file.exists(image_path)) {
    return(NULL)
  }
  tryCatch({
    image_data <- readBin(image_path, "raw", file.info(image_path)$size)
    base64_data <- base64encode(image_data)
    ext <- tools::file_ext(image_path)
    mime_type <- switch(tolower(ext),
      "png" = "image/png",
      "jpg" = "image/jpeg",
      "jpeg" = "image/jpeg",
      "svg" = "image/svg+xml",
      "image/png"  # default
    )
    return(paste0("data:", mime_type, ";base64,", base64_data))
  }, error = function(e) {
    cat("   ⚠️  Warning: Could not encode", image_path, ":", e$message, "\n")
    return(NULL)
  })
}

# ============================================================================
# COLLECT FIGURES AND TABLES
# ============================================================================

cat("📊 Collecting figures and tables...\n")

available_panels <- list()
for (panel in panels) {
  fig_path <- file.path(figures_dir, panel$filename)
  
  if (file.exists(fig_path)) {
    panel$figure_path <- fig_path
    panel$figure_base64 <- encode_image_base64(fig_path)
    available_panels[[length(available_panels) + 1]] <- panel
    cat("   ✅", panel$id, "-", panel$title, "\n")
  } else {
    cat("   ⚠️ ", panel$id, "- Figure not found:", fig_path, "\n")
  }
}

if (length(available_panels) == 0) {
  stop("❌ No figures found! Cannot generate viewer.")
}

cat("\n✅ Found", length(available_panels), "panels with figures\n\n")

# Separate QC and Diagnostic panels
qc_panels <- Filter(function(p) p$category == "Quality Control", available_panels)
diag_panels <- Filter(function(p) p$category == "Diagnostic", available_panels)

# ============================================================================
# GENERATE HTML CONTENT
# ============================================================================

cat("🌐 Generating HTML content...\n")

html_content <- paste0('<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>📊 STEP 1.5: VAF Quality Control</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, \'Segoe UI\', Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            background: linear-gradient(135deg, #2CA02C 0%, #667eea 100%);
            padding: 20px;
        }
        
        .container {
            max-width: 1800px;
            margin: 0 auto;
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            padding: 50px;
        }
        
        header {
            text-align: center;
            margin-bottom: 50px;
            padding-bottom: 30px;
            border-bottom: 4px solid #2CA02C;
        }
        
        h1 {
            color: #2CA02C;
            font-size: 3em;
            margin-bottom: 15px;
            font-weight: 800;
        }
        
        .subtitle {
            color: #666;
            font-size: 1.3em;
            margin: 10px 0;
        }
        
        .section {
            margin: 40px 0;
            padding: 30px;
            background: #f8f9fa;
            border-radius: 15px;
            border-left: 5px solid #2CA02C;
        }
        
        .section.qc {
            border-left-color: #D62728;
        }
        
        .section.diag {
            border-left-color: #667eea;
        }
        
        .grid-2 {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 30px;
            margin: 30px 0;
        }
        
        .grid-3 {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 30px;
            margin: 30px 0;
        }
        
        .figure-container {
            background: white;
            border: 2px solid #e9ecef;
            border-radius: 15px;
            padding: 25px;
            text-align: center;
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
            transition: transform 0.3s ease;
        }
        
        .figure-container:hover {
            transform: translateY(-5px);
            box-shadow: 0 10px 25px rgba(0,0,0,0.15);
        }
        
        .figure-title {
            font-weight: 700;
            color: #2CA02C;
            font-size: 1.2em;
            margin-bottom: 15px;
        }
        
        .figure-container img {
            max-width: 100%;
            height: auto;
            border-radius: 10px;
            box-shadow: 0 3px 10px rgba(0,0,0,0.1);
        }
        
        .figure-description {
            color: #555;
            font-size: 0.95em;
            margin-top: 15px;
            line-height: 1.5;
        }
        
        .category-badge {
            display: inline-block;
            padding: 5px 12px;
            border-radius: 20px;
            font-size: 0.8em;
            font-weight: 600;
            margin-bottom: 10px;
        }
        
        .badge-qc {
            background: #D62728;
            color: white;
        }
        
        .badge-diag {
            background: #667eea;
            color: white;
        }
        
        .footer {
            text-align: center;
            margin-top: 50px;
            padding-top: 30px;
            border-top: 2px solid #e9ecef;
            color: #666;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>📊 STEP 1.5: VAF Quality Control</h1>
            <div class="subtitle">Variant Allele Frequency Filtering & Diagnostic Analysis</div>
            <div class="subtitle" style="font-size: 1em; margin-top: 10px;">
                Generated: ', Sys.Date(), '
            </div>
        </header>
        
        <div class="section">
            <h2 style="color: #2CA02C; margin-bottom: 20px;">Overview</h2>
            <p style="font-size: 1.1em; color: #555; line-height: 1.8;">
                This step applies <strong>Variant Allele Frequency (VAF) filtering</strong> to remove technical artifacts.
                Values with VAF >= 0.5 (≥50% of reads showing the variant) are considered technical artifacts and removed.
                The viewer shows both <strong>Quality Control figures</strong> (demonstrating filter impact) and <strong>Diagnostic figures</strong>
                (showing the cleaned dataset equivalent to Step 1 analysis but with artifacts removed).
            </p>
        </div>')

# Add QC Figures section
if (length(qc_panels) > 0) {
  html_content <- paste0(html_content, '
        <div class="section qc">
            <h2 style="color: #D62728; margin-bottom: 30px;">🔍 Quality Control Figures (', length(qc_panels), ')</h2>
            <p style="margin-bottom: 20px; color: #666;">
                These figures demonstrate the impact of VAF filtering and help validate the quality control process.
            </p>
            <div class="grid-2">')
  
  for (panel in qc_panels) {
    img_tag <- if (!is.null(panel$figure_base64)) {
      paste0('<img src="', panel$figure_base64, '" alt="', panel$title, '">')
    } else {
      paste0('<div style="padding: 40px; color: #999;">Figure not available</div>')
    }
    
    html_content <- paste0(html_content, '
                <div class="figure-container">
                    <span class="category-badge badge-qc">QC</span>
                    <div class="figure-title">', panel$title, '</div>
                    ', img_tag, '
                    <div class="figure-description">', panel$description, '</div>
                </div>')
  }
  
  html_content <- paste0(html_content, '
            </div>
        </div>')
}

# Add Diagnostic Figures section
if (length(diag_panels) > 0) {
  html_content <- paste0(html_content, '
        <div class="section diag">
            <h2 style="color: #667eea; margin-bottom: 30px;">📈 Diagnostic Figures (', length(diag_panels), ')</h2>
            <p style="margin-bottom: 20px; color: #666;">
                These figures replicate the Step 1 exploratory analysis but on VAF-filtered data (artifacts removed).
                Compare these with Step 1 figures to see the impact of quality control.
            </p>
            <div class="grid-2">')
  
  for (panel in diag_panels) {
    img_tag <- if (!is.null(panel$figure_base64)) {
      paste0('<img src="', panel$figure_base64, '" alt="', panel$title, '">')
    } else {
      paste0('<div style="padding: 40px; color: #999;">Figure not available</div>')
    }
    
    html_content <- paste0(html_content, '
                <div class="figure-container">
                    <span class="category-badge badge-diag">Diagnostic</span>
                    <div class="figure-title">', panel$title, '</div>
                    ', img_tag, '
                    <div class="figure-description">', panel$description, '</div>
                </div>')
  }
  
  html_content <- paste0(html_content, '
            </div>
        </div>')
}

# Add tables section
html_content <- paste0(html_content, '
        <div class="section">
            <h2 style="color: #2CA02C; margin-bottom: 20px;">📋 Summary Tables</h2>
            <p style="margin-bottom: 20px; color: #666;">
                The following tables are available in the outputs/tables/ directory:
            </p>
            <ul style="line-height: 2; color: #555; font-size: 1.05em;">
                <li><strong>ALL_MUTATIONS_VAF_FILTERED.csv</strong> - Main dataset with VAF-filtered values (NAs)</li>
                <li><strong>vaf_filter_report.csv</strong> - Detailed log of all filtered values</li>
                <li><strong>vaf_statistics_by_type.csv</strong> - Statistics by mutation type</li>
                <li><strong>vaf_statistics_by_mirna.csv</strong> - Statistics by miRNA</li>
                <li><strong>sample_metrics_vaf_filtered.csv</strong> - Metrics per sample</li>
                <li><strong>position_metrics_vaf_filtered.csv</strong> - Metrics per position</li>
                <li><strong>mutation_type_summary_vaf_filtered.csv</strong> - Summary by mutation type</li>
            </ul>
        </div>
        
        <div class="footer">
            <p>Pipeline: Snakemake | Step 1.5: VAF Quality Control</p>
            <p style="font-size: 0.9em; margin-top: 10px;">
                Total figures: ', length(available_panels), ' (', length(qc_panels), ' QC + ', length(diag_panels), ' Diagnostic) | Generated: ', format(Sys.time(), "%Y-%m-%d %H:%M:%S"), '
            </p>
        </div>
    </div>
</body>
</html>')

# ============================================================================
# WRITE HTML FILE
# ============================================================================

cat("💾 Writing HTML file...\n")
writeLines(html_content, output_html)
cat("   ✅ HTML viewer saved:", output_html, "\n")
cat("   📄 File size:", format(file.info(output_html)$size, big.mark = ","), "bytes\n\n")

cat("═══════════════════════════════════════════════════════════════════\n")
cat("✅ STEP 1.5 HTML VIEWER COMPLETE!\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

