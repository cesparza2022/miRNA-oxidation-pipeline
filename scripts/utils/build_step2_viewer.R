#!/usr/bin/env Rscript
# ============================================================================
# BUILD STEP 2 VIEWER HTML
# ============================================================================
# Generates HTML viewer for Step 2 results including ALL 17 figures
# FIG_2.1 to FIG_2.17 (including hierarchical clustering analyses)
# ============================================================================

suppressPackageStartupMessages({
  library(readr)
  library(stringr)
})

# Get Snakemake inputs
comparisons_file <- snakemake@input[["comparisons"]]
effect_size_table <- snakemake@input[["effect_sizes"]]

# All Step 2 figures
fig_2_1 <- snakemake@input[["fig_2_1"]]
fig_2_2 <- snakemake@input[["fig_2_2"]]
fig_2_3 <- snakemake@input[["fig_2_3"]]
fig_2_4 <- snakemake@input[["fig_2_4"]]
fig_2_5 <- snakemake@input[["fig_2_5"]]
fig_2_6 <- snakemake@input[["fig_2_6"]]
fig_2_8 <- snakemake@input[["fig_2_8"]]
fig_2_9 <- snakemake@input[["fig_2_9"]]
fig_2_10 <- snakemake@input[["fig_2_10"]]
fig_2_11 <- snakemake@input[["fig_2_11"]]
fig_2_12 <- snakemake@input[["fig_2_12"]]
fig_2_13 <- snakemake@input[["fig_2_13"]]
fig_2_14 <- snakemake@input[["fig_2_14"]]
fig_2_15 <- snakemake@input[["fig_2_15"]]
fig_2_16 <- snakemake@input[["fig_2_16"]]
fig_2_17 <- snakemake@input[["fig_2_17"]]

# Clustering summaries
clustering_all_summary <- snakemake@input[["clustering_all_summary"]]
clustering_seed_summary <- snakemake@input[["clustering_seed_summary"]]

output_html <- snakemake@output[["viewer"]]

# Load comparison results for summary
comparisons <- read_csv(comparisons_file, show_col_types = FALSE)

# Calculate summary statistics
n_total <- nrow(comparisons)
n_significant <- sum(comparisons$significant, na.rm = TRUE)
n_up <- sum(comparisons$significant & !is.na(comparisons$log2_fold_change) & comparisons$log2_fold_change > 0, na.rm = TRUE)
n_down <- sum(comparisons$significant & !is.na(comparisons$log2_fold_change) & comparisons$log2_fold_change < 0, na.rm = TRUE)

# Load clustering summaries if available
clustering_all_info <- NULL
clustering_seed_info <- NULL
if (file.exists(clustering_all_summary)) {
  clustering_all_info <- read_csv(clustering_all_summary, show_col_types = FALSE)
}
if (file.exists(clustering_seed_summary)) {
  clustering_seed_info <- read_csv(clustering_seed_summary, show_col_types = FALSE)
}

# Get relative path from viewer to image
get_relative_path <- function(image_path, viewer_path) {
  if (!file.exists(image_path)) {
    return("")
  }
  
  # Get absolute paths
  image_abs <- normalizePath(image_path, mustWork = FALSE)
  viewer_dir <- normalizePath(dirname(viewer_path), mustWork = FALSE)
  
  # Split paths
  image_parts <- strsplit(image_abs, "/")[[1]]
  viewer_parts <- strsplit(viewer_dir, "/")[[1]]
  
  # Find common prefix
  min_len <- min(length(image_parts), length(viewer_parts))
  common_len <- 0
  for (i in 1:min_len) {
    if (image_parts[i] == viewer_parts[i]) {
      common_len <- i
    } else {
      break
    }
  }
  
  # Build relative path
  if (common_len > 0) {
    # Go up from viewer directory
    up_levels <- length(viewer_parts) - common_len
    up_path <- if (up_levels > 0) paste(rep("..", up_levels), collapse = "/") else ""
    
    # Get remaining image path
    remaining <- image_parts[(common_len + 1):length(image_parts)]
    remaining_path <- paste(remaining, collapse = "/")
    
    # Combine
    if (up_path != "") {
      return(paste0(up_path, "/", remaining_path))
    } else {
      return(remaining_path)
    }
  } else {
    # No common path, use absolute as fallback
    return(image_abs)
  }
}

# Get relative paths for all images
cat("📸 Getting relative paths...\n")
all_figures <- list(
  fig_2_1 = get_relative_path(fig_2_1, output_html),
  fig_2_2 = get_relative_path(fig_2_2, output_html),
  fig_2_3 = get_relative_path(fig_2_3, output_html),
  fig_2_4 = get_relative_path(fig_2_4, output_html),
  fig_2_5 = get_relative_path(fig_2_5, output_html),
  fig_2_6 = get_relative_path(fig_2_6, output_html),
  fig_2_8 = get_relative_path(fig_2_8, output_html),
  fig_2_9 = get_relative_path(fig_2_9, output_html),
  fig_2_10 = get_relative_path(fig_2_10, output_html),
  fig_2_11 = get_relative_path(fig_2_11, output_html),
  fig_2_12 = get_relative_path(fig_2_12, output_html),
  fig_2_13 = get_relative_path(fig_2_13, output_html),
  fig_2_14 = get_relative_path(fig_2_14, output_html),
  fig_2_15 = get_relative_path(fig_2_15, output_html),
  fig_2_16 = get_relative_path(fig_2_16, output_html),
  fig_2_17 = get_relative_path(fig_2_17, output_html)
)
cat("   ✅ Relative paths resolved\n")

# Helper function to generate image HTML
generate_img_html <- function(img_path, alt_text) {
  if (img_path != "") {
    return(paste0('<img src="', img_path, '" alt="', alt_text, '" style="max-width: 100%; height: auto;">'))
  } else {
    return(paste0('<p style="color: red;">⚠️ ', alt_text, ' not found</p>'))
  }
}

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
            max-width: 1600px;
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
            margin-top: 40px;
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
            text-align: left;
            max-width: 1200px;
            margin-left: auto;
            margin-right: auto;
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
        
        <h2>📊 Step 2 Figures (FIG_2.1 to FIG_2.17)</h2>
        
        <div class="figure-container">
            <div class="figure-title">Figure 2.1: VAF Global Comparison</div>
            <div class="figure-description">
                Global VAF distribution comparison between ALS and Control groups.
            </div>
            ', generate_img_html(all_figures$fig_2_1, "FIG_2.1 VAF Global"), '
        </div>
        
        <div class="figure-container">
            <div class="figure-title">Figure 2.2: VAF Distributions</div>
            <div class="figure-description">
                Distribution of VAF values across samples and groups.
            </div>
            ', generate_img_html(all_figures$fig_2_2, "FIG_2.2 Distributions"), '
        </div>
        
        <div class="figure-container">
            <div class="figure-title">Figure 2.3: Volcano Plot</div>
            <div class="figure-description">
                Significance (-log10 FDR) vs Fold Change (log2 FC). Points colored by significance and fold change thresholds.
            </div>
            ', generate_img_html(all_figures$fig_2_3, "FIG_2.3 Volcano"), '
        </div>
        
        <div class="figure-container">
            <div class="figure-title">Figure 2.4: Heatmap - Top 50 miRNAs</div>
            <div class="figure-description">
                Heatmap showing top 50 miRNAs by VAF in ALS vs Control samples.
            </div>
            ', generate_img_html(all_figures$fig_2_4, "FIG_2.4 Heatmap Top50"), '
        </div>
        
        <div class="figure-container">
            <div class="figure-title">Figure 2.5: Z-score Heatmap</div>
            <div class="figure-description">
                Z-score normalized heatmap of miRNA VAFs, showing standardized differences between groups.
            </div>
            ', generate_img_html(all_figures$fig_2_5, "FIG_2.5 Z-score Heatmap"), '
        </div>
        
        <div class="figure-container">
            <div class="figure-title">Figure 2.6: Positional Profile</div>
            <div class="figure-description">
                Position-specific VAF profiles across miRNA positions (1-22), comparing ALS vs Control.
            </div>
            ', generate_img_html(all_figures$fig_2_6, "FIG_2.6 Positional"), '
        </div>
        
        <div class="figure-container">
            <div class="figure-title">Figure 2.8: Clustering Analysis</div>
            <div class="figure-description">
                Hierarchical clustering of samples based on VAF profiles.
            </div>
            ', generate_img_html(all_figures$fig_2_8, "FIG_2.8 Clustering"), '
        </div>
        
        <div class="figure-container">
            <div class="figure-title">Figure 2.9: Coefficient of Variation</div>
            <div class="figure-description">
                Coefficient of variation (CV) analysis showing variability across samples and groups.
            </div>
            ', generate_img_html(all_figures$fig_2_9, "FIG_2.9 CV"), '
        </div>
        
        <div class="figure-container">
            <div class="figure-title">Figure 2.10: G>T Ratio Analysis</div>
            <div class="figure-description">
                G>T mutation ratio comparisons between ALS and Control groups, including global, positional, and seed region analyses.
            </div>
            ', generate_img_html(all_figures$fig_2_10, "FIG_2.10 G>T Ratio"), '
        </div>
        
        <div class="figure-container">
            <div class="figure-title">Figure 2.11: Mutation Types Spectrum</div>
            <div class="figure-description">
                Complete mutation spectrum showing all mutation types and their frequencies in ALS vs Control.
            </div>
            ', generate_img_html(all_figures$fig_2_11, "FIG_2.11 Mutation Types"), '
        </div>
        
        <div class="figure-container">
            <div class="figure-title">Figure 2.12: Enrichment Analysis</div>
            <div class="figure-description">
                Enrichment analysis showing top miRNAs, families, positional hotspots, and biomarker candidates.
            </div>
            ', generate_img_html(all_figures$fig_2_12, "FIG_2.12 Enrichment"), '
        </div>
        
        <div class="figure-container">
            <div class="figure-title">Figure 2.13: Density Heatmap - ALS</div>
            <div class="figure-description">
                Density heatmap showing VAF distribution patterns specifically for ALS samples.
            </div>
            ', generate_img_html(all_figures$fig_2_13, "FIG_2.13 Density ALS"), '
        </div>
        
        <div class="figure-container">
            <div class="figure-title">Figure 2.14: Density Heatmap - Control</div>
            <div class="figure-description">
                Density heatmap showing VAF distribution patterns specifically for Control samples.
            </div>
            ', generate_img_html(all_figures$fig_2_14, "FIG_2.14 Density Control"), '
        </div>
        
        <div class="figure-container">
            <div class="figure-title">Figure 2.15: Density Heatmap - Combined</div>
            <div class="figure-description">
                Combined density heatmap comparing ALS and Control VAF patterns side by side.
            </div>
            ', generate_img_html(all_figures$fig_2_15, "FIG_2.15 Density Combined"), '
        </div>
        
        <h2>🌳 Hierarchical Clustering Analyses (Guide for Analysis)</h2>
        <p style="color: #666; font-size: 0.95em; margin-bottom: 20px;">
            <strong>Propósito:</strong> Clustering jerárquico de MUESTRAS usando VAFs de SNVs G>T para entender 
            cómo se agrupan las muestras (ALS vs Control). Esto sirve como guía para 
            el análisis y puede revelar patrones de agrupación que informan las comparaciones estadísticas.
        </p>
        
        <div class="figure-container">
            <div class="figure-title">Figure 2.16: Hierarchical Clustering - ALL G>T SNVs</div>
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
            ', generate_img_html(all_figures$fig_2_16, "FIG_2.16 Clustering All G>T"), '
        </div>
        
        <div class="figure-container">
            <div class="figure-title">Figure 2.17: Hierarchical Clustering - SEED REGION G>T SNVs ONLY</div>
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
            ', generate_img_html(all_figures$fig_2_17, "FIG_2.17 Clustering Seed G>T"), '
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
cat("   Includes all 17 figures (FIG_2.1 to FIG_2.17)\n")
