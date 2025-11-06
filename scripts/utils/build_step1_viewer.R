#!/usr/bin/env Rscript
# ============================================================================
# BUILD STEP 1 HTML VIEWER (Snakemake version)
# ============================================================================
# Generates an HTML viewer with all Step 1 figures and tables
# Uses Snakemake input/output structure

suppressPackageStartupMessages({
  library(base64enc)
})

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  🌐 BUILDING STEP 1 HTML VIEWER\n")
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
  list(
    id = "B",
    title = "G>T Count by Position",
    filename = "step1_panelB_gt_count_by_position.png",
    description = "Absolute count of G>T mutations across all miRNA positions (1-23). Shows distribution of oxidation events throughout the miRNA sequence.",
    table = "TABLE_1.B_gt_counts_by_position.csv"
  ),
  list(
    id = "C",
    title = "G>X Mutation Spectrum by Position",
    filename = "step1_panelC_gx_spectrum.png",
    description = "Distribution of all G mutations (G>T, G>C, G>A) across positions. Highlights the prevalence of G>T (oxidation) compared to other G transversions.",
    table = "TABLE_1.C_gx_spectrum_by_position.csv"
  ),
  list(
    id = "D",
    title = "Positional Fraction of Mutations",
    filename = "step1_panelD_positional_fraction.png",
    description = "Proportion of ALL SNVs occurring at each position (relative to total). Shows which positions accumulate the most mutations overall.",
    table = "TABLE_1.D_positional_fractions.csv"
  ),
  list(
    id = "E",
    title = "G-Content Landscape",
    filename = "step1_panelE_gcontent.png",
    description = "Bubble plot showing the relationship between G-content (number of Guanines) per position and G>T mutation counts. Larger bubbles indicate higher mutation counts.",
    table = "TABLE_1.E_gcontent_landscape.csv"
  ),
  list(
    id = "F",
    title = "Seed vs Non-seed Comparison",
    filename = "step1_panelF_seed_interaction.png",
    description = "Comparison of G>T mutations between seed region (positions 1-7) and non-seed region (positions 8-23). Critical for understanding functional impact.",
    table = "TABLE_1.F_seed_vs_nonseed.csv"
  ),
  list(
    id = "G",
    title = "G>T Specificity (Overall)",
    filename = "step1_panelG_gt_specificity.png",
    description = "Proportion of G>T mutations relative to all G>X mutations. Shows the specificity of oxidative damage (8-oxoG) among all possible G mutations.",
    table = "TABLE_1.G_gt_specificity.csv"
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
  table_path <- file.path(tables_dir, panel$table)
  
  if (file.exists(fig_path)) {
    panel$figure_path <- fig_path
    panel$figure_base64 <- encode_image_base64(fig_path)
    panel$table_exists <- file.exists(table_path)
    panel$table_path <- table_path
    available_panels[[length(available_panels) + 1]] <- panel
    cat("   ✅ Panel", panel$id, "-", panel$title, "\n")
  } else {
    cat("   ⚠️  Panel", panel$id, "- Figure not found:", fig_path, "\n")
  }
}

if (length(available_panels) == 0) {
  stop("❌ No figures found! Cannot generate viewer.")
}

cat("\n✅ Found", length(available_panels), "panels with figures\n\n")

# ============================================================================
# GENERATE HTML CONTENT
# ============================================================================

cat("🌐 Generating HTML content...\n")

html_content <- paste0('<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>📊 STEP 1: Exploratory Analysis of miRNA G>T Mutations</title>
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
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
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
            border-bottom: 4px solid #667eea;
        }
        
        h1 {
            color: #667eea;
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
            border-left: 5px solid #667eea;
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
            color: #667eea;
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
        
        .metadata {
            background: #e9ecef;
            padding: 15px;
            border-radius: 10px;
            margin-top: 20px;
            font-size: 0.9em;
            color: #666;
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
            <h1>📊 STEP 1: Exploratory Analysis</h1>
            <div class="subtitle">miRNA G>T Mutation Analysis Pipeline</div>
            <div class="subtitle" style="font-size: 1em; margin-top: 10px;">
                Generated: ', Sys.Date(), '
            </div>
        </header>
        
        <div class="section">
            <h2 style="color: #667eea; margin-bottom: 20px;">Overview</h2>
            <p style="font-size: 1.1em; color: #555; line-height: 1.8;">
                This viewer presents the exploratory analysis of G>T (8-oxoguanine) mutations across miRNA sequences.
                G>T mutations are biomarkers of oxidative stress and can alter miRNA function, especially in the seed region.
                All analyses shown here are performed on the complete dataset before group comparisons.
            </p>
        </div>')

# Add panels in grid
html_content <- paste0(html_content, '
        <div class="section">
            <h2 style="color: #667eea; margin-bottom: 30px;">Panels</h2>
            <div class="grid-2">')

for (panel in available_panels) {
  img_tag <- if (!is.null(panel$figure_base64)) {
    paste0('<img src="', panel$figure_base64, '" alt="Panel ', panel$id, ': ', panel$title, '">')
  } else {
    paste0('<div style="padding: 40px; color: #999;">Figure not available</div>')
  }
  
  html_content <- paste0(html_content, '
                <div class="figure-container">
                    <div class="figure-title">Panel ', panel$id, ': ', panel$title, '</div>
                    ', img_tag, '
                    <div class="figure-description">', panel$description, '</div>
                    ', if (panel$table_exists) {
                      paste0('<div class="metadata">📋 Table: ', panel$table, '</div>')
                    } else {
                      ''
                    }, '
                </div>')
}

html_content <- paste0(html_content, '
            </div>
        </div>
        
        <div class="footer">
            <p>Pipeline: Snakemake | Step 1: Exploratory Analysis</p>
            <p style="font-size: 0.9em; margin-top: 10px;">
                Total panels: ', length(available_panels), ' | Generated: ', format(Sys.time(), "%Y-%m-%d %H:%M:%S"), '
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
cat("✅ STEP 1 HTML VIEWER COMPLETE!\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

# ============================================================================
# BUILD STEP 1 HTML VIEWER (Snakemake version)
# ============================================================================
# Generates an HTML viewer with all Step 1 figures and tables
# Uses Snakemake input/output structure

suppressPackageStartupMessages({
  library(base64enc)
})

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  🌐 BUILDING STEP 1 HTML VIEWER\n")
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
  list(
    id = "B",
    title = "G>T Count by Position",
    filename = "step1_panelB_gt_count_by_position.png",
    description = "Absolute count of G>T mutations across all miRNA positions (1-23). Shows distribution of oxidation events throughout the miRNA sequence.",
    table = "TABLE_1.B_gt_counts_by_position.csv"
  ),
  list(
    id = "C",
    title = "G>X Mutation Spectrum by Position",
    filename = "step1_panelC_gx_spectrum.png",
    description = "Distribution of all G mutations (G>T, G>C, G>A) across positions. Highlights the prevalence of G>T (oxidation) compared to other G transversions.",
    table = "TABLE_1.C_gx_spectrum_by_position.csv"
  ),
  list(
    id = "D",
    title = "Positional Fraction of Mutations",
    filename = "step1_panelD_positional_fraction.png",
    description = "Proportion of ALL SNVs occurring at each position (relative to total). Shows which positions accumulate the most mutations overall.",
    table = "TABLE_1.D_positional_fractions.csv"
  ),
  list(
    id = "E",
    title = "G-Content Landscape",
    filename = "step1_panelE_gcontent.png",
    description = "Bubble plot showing the relationship between G-content (number of Guanines) per position and G>T mutation counts. Larger bubbles indicate higher mutation counts.",
    table = "TABLE_1.E_gcontent_landscape.csv"
  ),
  list(
    id = "F",
    title = "Seed vs Non-seed Comparison",
    filename = "step1_panelF_seed_interaction.png",
    description = "Comparison of G>T mutations between seed region (positions 1-7) and non-seed region (positions 8-23). Critical for understanding functional impact.",
    table = "TABLE_1.F_seed_vs_nonseed.csv"
  ),
  list(
    id = "G",
    title = "G>T Specificity (Overall)",
    filename = "step1_panelG_gt_specificity.png",
    description = "Proportion of G>T mutations relative to all G>X mutations. Shows the specificity of oxidative damage (8-oxoG) among all possible G mutations.",
    table = "TABLE_1.G_gt_specificity.csv"
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
  table_path <- file.path(tables_dir, panel$table)
  
  if (file.exists(fig_path)) {
    panel$figure_path <- fig_path
    panel$figure_base64 <- encode_image_base64(fig_path)
    panel$table_exists <- file.exists(table_path)
    panel$table_path <- table_path
    available_panels[[length(available_panels) + 1]] <- panel
    cat("   ✅ Panel", panel$id, "-", panel$title, "\n")
  } else {
    cat("   ⚠️  Panel", panel$id, "- Figure not found:", fig_path, "\n")
  }
}

if (length(available_panels) == 0) {
  stop("❌ No figures found! Cannot generate viewer.")
}

cat("\n✅ Found", length(available_panels), "panels with figures\n\n")

# ============================================================================
# GENERATE HTML CONTENT
# ============================================================================

cat("🌐 Generating HTML content...\n")

html_content <- paste0('<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>📊 STEP 1: Exploratory Analysis of miRNA G>T Mutations</title>
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
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
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
            border-bottom: 4px solid #667eea;
        }
        
        h1 {
            color: #667eea;
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
            border-left: 5px solid #667eea;
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
            color: #667eea;
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
        
        .metadata {
            background: #e9ecef;
            padding: 15px;
            border-radius: 10px;
            margin-top: 20px;
            font-size: 0.9em;
            color: #666;
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
            <h1>📊 STEP 1: Exploratory Analysis</h1>
            <div class="subtitle">miRNA G>T Mutation Analysis Pipeline</div>
            <div class="subtitle" style="font-size: 1em; margin-top: 10px;">
                Generated: ', Sys.Date(), '
            </div>
        </header>
        
        <div class="section">
            <h2 style="color: #667eea; margin-bottom: 20px;">Overview</h2>
            <p style="font-size: 1.1em; color: #555; line-height: 1.8;">
                This viewer presents the exploratory analysis of G>T (8-oxoguanine) mutations across miRNA sequences.
                G>T mutations are biomarkers of oxidative stress and can alter miRNA function, especially in the seed region.
                All analyses shown here are performed on the complete dataset before group comparisons.
            </p>
        </div>')

# Add panels in grid
html_content <- paste0(html_content, '
        <div class="section">
            <h2 style="color: #667eea; margin-bottom: 30px;">Panels</h2>
            <div class="grid-2">')

for (panel in available_panels) {
  img_tag <- if (!is.null(panel$figure_base64)) {
    paste0('<img src="', panel$figure_base64, '" alt="Panel ', panel$id, ': ', panel$title, '">')
  } else {
    paste0('<div style="padding: 40px; color: #999;">Figure not available</div>')
  }
  
  html_content <- paste0(html_content, '
                <div class="figure-container">
                    <div class="figure-title">Panel ', panel$id, ': ', panel$title, '</div>
                    ', img_tag, '
                    <div class="figure-description">', panel$description, '</div>
                    ', if (panel$table_exists) {
                      paste0('<div class="metadata">📋 Table: ', panel$table, '</div>')
                    } else {
                      ''
                    }, '
                </div>')
}

html_content <- paste0(html_content, '
            </div>
        </div>
        
        <div class="footer">
            <p>Pipeline: Snakemake | Step 1: Exploratory Analysis</p>
            <p style="font-size: 0.9em; margin-top: 10px;">
                Total panels: ', length(available_panels), ' | Generated: ', format(Sys.time(), "%Y-%m-%d %H:%M:%S"), '
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
cat("✅ STEP 1 HTML VIEWER COMPLETE!\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

# ============================================================================
# BUILD STEP 1 HTML VIEWER (Snakemake version)
# ============================================================================
# Generates an HTML viewer with all Step 1 figures and tables
# Uses Snakemake input/output structure

suppressPackageStartupMessages({
  library(base64enc)
})

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  🌐 BUILDING STEP 1 HTML VIEWER\n")
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
  list(
    id = "B",
    title = "G>T Count by Position",
    filename = "step1_panelB_gt_count_by_position.png",
    description = "Absolute count of G>T mutations across all miRNA positions (1-23). Shows distribution of oxidation events throughout the miRNA sequence.",
    table = "TABLE_1.B_gt_counts_by_position.csv"
  ),
  list(
    id = "C",
    title = "G>X Mutation Spectrum by Position",
    filename = "step1_panelC_gx_spectrum.png",
    description = "Distribution of all G mutations (G>T, G>C, G>A) across positions. Highlights the prevalence of G>T (oxidation) compared to other G transversions.",
    table = "TABLE_1.C_gx_spectrum_by_position.csv"
  ),
  list(
    id = "D",
    title = "Positional Fraction of Mutations",
    filename = "step1_panelD_positional_fraction.png",
    description = "Proportion of ALL SNVs occurring at each position (relative to total). Shows which positions accumulate the most mutations overall.",
    table = "TABLE_1.D_positional_fractions.csv"
  ),
  list(
    id = "E",
    title = "G-Content Landscape",
    filename = "step1_panelE_gcontent.png",
    description = "Bubble plot showing the relationship between G-content (number of Guanines) per position and G>T mutation counts. Larger bubbles indicate higher mutation counts.",
    table = "TABLE_1.E_gcontent_landscape.csv"
  ),
  list(
    id = "F",
    title = "Seed vs Non-seed Comparison",
    filename = "step1_panelF_seed_interaction.png",
    description = "Comparison of G>T mutations between seed region (positions 1-7) and non-seed region (positions 8-23). Critical for understanding functional impact.",
    table = "TABLE_1.F_seed_vs_nonseed.csv"
  ),
  list(
    id = "G",
    title = "G>T Specificity (Overall)",
    filename = "step1_panelG_gt_specificity.png",
    description = "Proportion of G>T mutations relative to all G>X mutations. Shows the specificity of oxidative damage (8-oxoG) among all possible G mutations.",
    table = "TABLE_1.G_gt_specificity.csv"
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
  table_path <- file.path(tables_dir, panel$table)
  
  if (file.exists(fig_path)) {
    panel$figure_path <- fig_path
    panel$figure_base64 <- encode_image_base64(fig_path)
    panel$table_exists <- file.exists(table_path)
    panel$table_path <- table_path
    available_panels[[length(available_panels) + 1]] <- panel
    cat("   ✅ Panel", panel$id, "-", panel$title, "\n")
  } else {
    cat("   ⚠️  Panel", panel$id, "- Figure not found:", fig_path, "\n")
  }
}

if (length(available_panels) == 0) {
  stop("❌ No figures found! Cannot generate viewer.")
}

cat("\n✅ Found", length(available_panels), "panels with figures\n\n")

# ============================================================================
# GENERATE HTML CONTENT
# ============================================================================

cat("🌐 Generating HTML content...\n")

html_content <- paste0('<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>📊 STEP 1: Exploratory Analysis of miRNA G>T Mutations</title>
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
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
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
            border-bottom: 4px solid #667eea;
        }
        
        h1 {
            color: #667eea;
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
            border-left: 5px solid #667eea;
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
            color: #667eea;
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
        
        .metadata {
            background: #e9ecef;
            padding: 15px;
            border-radius: 10px;
            margin-top: 20px;
            font-size: 0.9em;
            color: #666;
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
            <h1>📊 STEP 1: Exploratory Analysis</h1>
            <div class="subtitle">miRNA G>T Mutation Analysis Pipeline</div>
            <div class="subtitle" style="font-size: 1em; margin-top: 10px;">
                Generated: ', Sys.Date(), '
            </div>
        </header>
        
        <div class="section">
            <h2 style="color: #667eea; margin-bottom: 20px;">Overview</h2>
            <p style="font-size: 1.1em; color: #555; line-height: 1.8;">
                This viewer presents the exploratory analysis of G>T (8-oxoguanine) mutations across miRNA sequences.
                G>T mutations are biomarkers of oxidative stress and can alter miRNA function, especially in the seed region.
                All analyses shown here are performed on the complete dataset before group comparisons.
            </p>
        </div>')

# Add panels in grid
html_content <- paste0(html_content, '
        <div class="section">
            <h2 style="color: #667eea; margin-bottom: 30px;">Panels</h2>
            <div class="grid-2">')

for (panel in available_panels) {
  img_tag <- if (!is.null(panel$figure_base64)) {
    paste0('<img src="', panel$figure_base64, '" alt="Panel ', panel$id, ': ', panel$title, '">')
  } else {
    paste0('<div style="padding: 40px; color: #999;">Figure not available</div>')
  }
  
  html_content <- paste0(html_content, '
                <div class="figure-container">
                    <div class="figure-title">Panel ', panel$id, ': ', panel$title, '</div>
                    ', img_tag, '
                    <div class="figure-description">', panel$description, '</div>
                    ', if (panel$table_exists) {
                      paste0('<div class="metadata">📋 Table: ', panel$table, '</div>')
                    } else {
                      ''
                    }, '
                </div>')
}

html_content <- paste0(html_content, '
            </div>
        </div>
        
        <div class="footer">
            <p>Pipeline: Snakemake | Step 1: Exploratory Analysis</p>
            <p style="font-size: 0.9em; margin-top: 10px;">
                Total panels: ', length(available_panels), ' | Generated: ', format(Sys.time(), "%Y-%m-%d %H:%M:%S"), '
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
cat("✅ STEP 1 HTML VIEWER COMPLETE!\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

