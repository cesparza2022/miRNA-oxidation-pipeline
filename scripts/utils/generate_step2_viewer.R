#!/usr/bin/env Rscript
# ============================================================================
# GENERATE STEP 2 VIEWER HTML (Standalone)
# ============================================================================
# Standalone script to generate Step 2 viewer with all figures including clustering
# ============================================================================

suppressPackageStartupMessages({
  library(readr)
  library(stringr)
})

# Paths (relative to snakemake_pipeline directory)
results_dir <- "results/step2"
viewers_dir <- "viewers"

# Inputs
comparisons_file <- file.path(results_dir, "tables/statistical_results/S2_statistical_comparisons.csv")
volcano_plot <- file.path(results_dir, "figures/step2_volcano_plot.png")
effect_size_plot <- file.path(results_dir, "figures/step2_effect_size_distribution.png")
clustering_all_gt <- file.path(results_dir, "figures/step2_clustering_all_gt.png")
clustering_seed_gt <- file.path(results_dir, "figures/step2_clustering_seed_gt.png")
clustering_all_summary <- file.path(results_dir, "tables/statistical_results/S2_clustering_all_gt_summary.csv")
clustering_seed_summary <- file.path(results_dir, "tables/statistical_results/S2_clustering_seed_gt_summary.csv")

output_html <- file.path(viewers_dir, "STEP2_VIEWER.html")

# Create viewers directory if needed
dir.create(viewers_dir, showWarnings = FALSE, recursive = TRUE)

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  GENERATING STEP 2 VIEWER HTML\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# Encode images as base64
encode_image <- function(image_path) {
  if (!file.exists(image_path)) {
    cat("   ⚠️  Image not found:", image_path, "\n")
    return("")
  }
  
  if (!requireNamespace("base64enc", quietly = TRUE)) {
    cat("   ⚠️  base64enc not available, using relative path\n")
    return(image_path)
  }
  
  library(base64enc)
  con <- file(image_path, "rb")
  img_data <- readBin(con, "raw", file.info(image_path)$size)
  close(con)
  base64_data <- base64enc::base64encode(img_data)
  return(paste0("data:image/png;base64,", base64_data))
}

# Load comparison results
if (file.exists(comparisons_file)) {
  comparisons <- read_csv(comparisons_file, show_col_types = FALSE)
  n_total <- nrow(comparisons)
  n_significant <- sum(comparisons$significant, na.rm = TRUE)
  n_up <- sum(comparisons$significant & !is.na(comparisons$log2_fold_change) & 
              comparisons$log2_fold_change > 0, na.rm = TRUE)
  n_down <- sum(comparisons$significant & !is.na(comparisons$log2_fold_change) & 
                comparisons$log2_fold_change < 0, na.rm = TRUE)
  cat("✅ Comparisons loaded:", n_total, "SNVs\n")
} else {
  cat("⚠️  Comparisons file not found, using defaults\n")
  n_total <- 0
  n_significant <- 0
  n_up <- 0
  n_down <- 0
}

# Load clustering summaries
clustering_all_info <- NULL
clustering_seed_info <- NULL

if (file.exists(clustering_all_summary)) {
  clustering_all_info <- read_csv(clustering_all_summary, show_col_types = FALSE)
  cat("✅ Clustering all G>T summary loaded\n")
}

if (file.exists(clustering_seed_summary)) {
  clustering_seed_info <- read_csv(clustering_seed_summary, show_col_types = FALSE)
  cat("✅ Clustering seed G>T summary loaded\n")
}

# Encode images
cat("\n📸 Encoding images...\n")
volcano_img <- encode_image(volcano_plot)
effect_img <- encode_image(effect_size_plot)
clustering_all_img <- encode_image(clustering_all_gt)
clustering_seed_img <- encode_image(clustering_seed_gt)

cat("   ✅ Images encoded\n")

# Helper function to generate image HTML
generate_img_html <- function(img_data, alt_text) {
  if (img_data != "" && str_starts(img_data, "data:")) {
    return(paste0('<img src="', img_data, '" alt="', alt_text, '">'))
  } else if (img_data != "") {
    return(paste0('<img src="', img_data, '" alt="', alt_text, '">'))
  } else {
    return(paste0('<p style="color: red;">⚠️ ', alt_text, ' not found</p>'))
  }
}

# Generate HTML
cat("\n📝 Generating HTML...\n")

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
        h2 {
            color: #333;
            margin-top: 30px;
            border-bottom: 2px solid #ddd;
            padding-bottom: 5px;
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
            border-bottom: none;
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
        .clustering-info {
            background: #f0f8ff;
            padding: 15px;
            border-radius: 5px;
            margin: 10px 0;
            font-size: 0.9em;
            text-align: left;
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
        
        <h2>📊 Statistical Visualizations</h2>
        
        <div class="figure-container">
            <div class="figure-title">Figure 2.1: Volcano Plot</div>
            <div class="figure-description">
                Significance (-log10 FDR) vs Fold Change (log2 FC). 
                Points colored by significance and fold change thresholds.
            </div>
            ', generate_img_html(volcano_img, "Volcano Plot"), '
        </div>
        
        <div class="figure-container">
            <div class="figure-title">Figure 2.2: Effect Size Distribution</div>
            <div class="figure-description">
                Distribution of Cohen\'s d effect sizes. Categories: Large (|d| ≥ 0.8), 
                Medium (0.5 ≤ |d| < 0.8), Small (0.2 ≤ |d| < 0.5), Negligible (|d| < 0.2).
            </div>
            ', generate_img_html(effect_img, "Effect Size Distribution"), '
        </div>
        
        <h2>🌳 Hierarchical Clustering Analyses</h2>
        <p style="color: #666; font-size: 0.95em; margin-bottom: 20px;">
            <strong>Propósito:</strong> Clustering jerárquico de MUESTRAS usando VAFs de SNVs G>T para entender 
            cómo se agrupan las muestras (ALS vs Control). Esto sirve como guía para 
            el análisis y puede revelar patrones de agrupación que informan las comparaciones estadísticas.
        </p>
        
        <div class="figure-container">
            <div class="figure-title">Figure 2.6: Hierarchical Clustering - ALL G>T SNVs</div>
            <div class="figure-description">
                Clustering jerárquico de muestras usando TODOS los SNVs G>T (n = ',
                if (!is.null(clustering_all_info) && "Total_SNVs" %in% names(clustering_all_info)) {
                  format(clustering_all_info$Total_SNVs[1], big.mark = ",")
                } else {
                  "~5,000"
                }, ' SNVs). Muestras anotadas por grupo (ALS en rojo, Control en gris). 
                El dendrograma muestra cómo se agrupan las muestras basándose en sus 
                perfiles de oxidación G>T completos. Las muestras con patrones similares 
                de oxidación se agrupan juntas.
            </div>
            ', if (!is.null(clustering_all_info) && nrow(clustering_all_info) > 0) {
              paste0('<div class="clustering-info">',
                     '<strong>📊 Cluster Composition (k=2):</strong><br>',
                     'Cluster 1: ', clustering_all_info$Cluster_k2_1_ALS[1], ' ALS, ', 
                     clustering_all_info$Cluster_k2_1_Control[1], ' Control<br>',
                     'Cluster 2: ', clustering_all_info$Cluster_k2_2_ALS[1], ' ALS, ', 
                     clustering_all_info$Cluster_k2_2_Control[1], ' Control<br>',
                     'Cluster Purity: ', round(clustering_all_info$Cluster_Purity_k2[1] * 100, 1), '%<br>',
                     '<em>Cluster purity indica qué tan bien los clusters separan ALS de Control.</em></div>')
            } else {
              ""
            }, '
            ', generate_img_html(clustering_all_img, "Clustering All G>T SNVs"), '
        </div>
        
        <div class="figure-container">
            <div class="figure-title">Figure 2.7: Hierarchical Clustering - SEED REGION G>T SNVs ONLY</div>
            <div class="figure-description">
                Clustering jerárquico de muestras usando SOLO los SNVs G>T en la seed region 
                (posiciones 2-8, n = ',
                if (!is.null(clustering_seed_info) && "Total_SNVs" %in% names(clustering_seed_info)) {
                  format(clustering_seed_info$Total_SNVs[1], big.mark = ",")
                } else {
                  "~1,000"
                }, ' SNVs). Este análisis se enfoca en los patrones de oxidación en la 
                región más crítica para el reconocimiento de targets. Comparar con el 
                clustering de todos los SNVs puede revelar si los patrones en seed region 
                son más discriminativos entre grupos.
            </div>
            ', if (!is.null(clustering_seed_info) && nrow(clustering_seed_info) > 0) {
              paste0('<div class="clustering-info">',
                     '<strong>📊 Cluster Composition (k=2):</strong><br>',
                     'Cluster 1: ', clustering_seed_info$Cluster_k2_1_ALS[1], ' ALS, ', 
                     clustering_seed_info$Cluster_k2_1_Control[1], ' Control<br>',
                     'Cluster 2: ', clustering_seed_info$Cluster_k2_2_ALS[1], ' ALS, ', 
                     clustering_seed_info$Cluster_k2_2_Control[1], ' Control<br>',
                     'Cluster Purity: ', round(clustering_seed_info$Cluster_Purity_k2[1] * 100, 1), '%<br>',
                     '<em>Comparar con clustering de todos los SNVs para evaluar si seed region es más discriminativa.</em></div>')
            } else {
              ""
            }, '
            ', generate_img_html(clustering_seed_img, "Clustering Seed Region G>T SNVs"), '
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
cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("✅ Step 2 viewer generated:", output_html, "\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

