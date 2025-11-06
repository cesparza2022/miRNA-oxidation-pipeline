#!/usr/bin/env python3
"""
Create HTML viewer for Step 2 figures with absolute file paths
"""
import os
from pathlib import Path
from datetime import datetime

# Base directory
base_dir = Path("/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/pipeline_definitivo/snakemake_pipeline")
figures_dir = base_dir / "results" / "step2" / "figures"
viewer_dir = base_dir / "viewers"

# Lista de figuras con información
figures_info = [
    ("FIG_2.1_VAF_GLOBAL_CLEAN.png", "Figure 2.1: VAF Global Comparison", 
     "Global VAF distribution comparison between ALS and Control groups."),
    ("FIG_2.2_DISTRIBUTIONS_CLEAN.png", "Figure 2.2: VAF Distributions", 
     "Distribution of VAF values across samples and groups."),
    ("FIG_2.3_VOLCANO_PER_SAMPLE_METHOD.png", "Figure 2.3: Volcano Plot", 
     "Significance (-log10 FDR) vs Fold Change (log2 FC). Points colored by significance and fold change thresholds."),
    ("FIG_2.4_HEATMAP_TOP50_CLEAN.png", "Figure 2.4: Raw VAF Heatmap (Threshold-based Filtering)", 
     "Heatmap showing miRNAs filtered by configurable thresholds (RPM, VAF, seed region, significance) instead of arbitrary 'top 50'. White→red color scale represents VAF values (oxidation intensity)."),
    ("FIG_2.5_HEATMAP_ZSCORE_CLEAN.png", "Figure 2.5: Z-score Heatmap", 
     "Z-score normalized heatmap of miRNA VAFs, showing standardized differences between groups."),
    ("FIG_2.6_POSITIONAL_CLEAN.png", "Figure 2.6: Positional Profile", 
     "Position-specific VAF profiles across miRNA positions (1-22), comparing ALS vs Control."),
    # ("FIG_2.8_CLUSTERING_CLEAN.png", "Figure 2.8: Clustering Analysis",  # REMOVED: Redundant with FIG_2.16
    #  "Hierarchical clustering of samples based on VAF profiles. Uses biological filtering (256 miRNAs with seed G>T, VAF thresholds)."),
    ("FIG_2.9_CV_CLEAN.png", "Figure 2.9: Coefficient of Variation", 
     "Coefficient of variation (CV) analysis showing variability across samples and groups."),
    ("FIG_2.10_RATIO_CLEAN.png", "Figure 2.10: G>T Ratio Analysis", 
     "G>T mutation ratio comparisons between ALS and Control groups, including global, positional, and seed region analyses."),
    ("FIG_2.11_MUTATION_TYPES_CLEAN.png", "Figure 2.11: Mutation Types Spectrum", 
     "Complete mutation spectrum showing all mutation types and their frequencies in ALS vs Control."),
    ("FIG_2.12_ENRICHMENT_CLEAN.png", "Figure 2.12: Enrichment Analysis", 
     "Enrichment analysis showing top miRNAs, families, positional hotspots, and biomarker candidates."),
    ("FIG_2.13_DENSITY_HEATMAP_ALS.png", "Figure 2.13: Density Heatmap - ALS", 
     "Density heatmap showing VAF distribution patterns specifically for ALS samples."),
    ("FIG_2.14_DENSITY_HEATMAP_CONTROL.png", "Figure 2.14: Density Heatmap - Control", 
     "Density heatmap showing VAF distribution patterns specifically for Control samples."),
    ("FIG_2.15_DENSITY_COMBINED.png", "Figure 2.15: Density Heatmap - Combined", 
     "Combined density heatmap comparing ALS and Control VAF patterns side by side."),
    ("FIG_2.16_CLUSTERING_ALL_GT.png", "Figure 2.16: Hierarchical Clustering - ALL G>T SNVs", 
     "Clustering jerárquico de muestras usando TODOS los SNVs G>T. Muestras anotadas por grupo (ALS en rojo, Control en gris)."),
    ("FIG_2.17_CLUSTERING_SEED_GT.png", "Figure 2.17: Hierarchical Clustering - SEED REGION G>T SNVs ONLY", 
     "Clustering jerárquico de muestras usando SOLO los SNVs G>T en la seed region (posiciones 2-8)."),
]

# Construir HTML
html_lines = [
    '<!DOCTYPE html>',
    '<html lang="en">',
    '<head>',
    '    <meta charset="UTF-8">',
    '    <meta name="viewport" content="width=device-width, initial-scale=1.0">',
    '    <title>📊 STEP 2: Statistical Comparisons - ALS vs Control</title>',
    '    <style>',
    '        body {',
    '            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;',
    '            line-height: 1.6;',
    '            margin: 0;',
    '            padding: 20px;',
    '            background: #f5f5f5;',
    '        }',
    '        .container {',
    '            max-width: 1600px;',
    '            margin: 0 auto;',
    '            background: white;',
    '            padding: 40px;',
    '            box-shadow: 0 2px 10px rgba(0,0,0,0.1);',
    '        }',
    '        h1 {',
    '            color: #D62728;',
    '            border-bottom: 3px solid #D62728;',
    '            padding-bottom: 10px;',
    '        }',
    '        h2 {',
    '            color: #333;',
    '            margin-top: 40px;',
    '            border-bottom: 2px solid #ddd;',
    '            padding-bottom: 5px;',
    '        }',
    '        .summary {',
    '            background: #f8f9fa;',
    '            padding: 20px;',
    '            border-radius: 8px;',
    '            margin: 20px 0;',
    '        }',
    '        .stat-box {',
    '            display: inline-block;',
    '            margin: 10px 15px;',
    '            padding: 15px 25px;',
    '            background: white;',
    '            border-radius: 5px;',
    '            box-shadow: 0 1px 3px rgba(0,0,0,0.1);',
    '        }',
    '        .stat-box strong {',
    '            color: #D62728;',
    '            font-size: 1.2em;',
    '        }',
    '        .figure-container {',
    '            margin: 30px 0;',
    '            text-align: center;',
    '        }',
    '        .figure-container img {',
    '            max-width: 100%;',
    '            height: auto;',
    '            border: 1px solid #ddd;',
    '            border-radius: 5px;',
    '            box-shadow: 0 2px 8px rgba(0,0,0,0.1);',
    '        }',
    '        .figure-title {',
    '            font-size: 1.2em;',
    '            font-weight: bold;',
    '            color: #333;',
    '            margin: 15px 0 10px 0;',
    '        }',
    '        .figure-description {',
    '            color: #666;',
    '            font-size: 0.95em;',
    '            margin-bottom: 20px;',
    '            text-align: left;',
    '            max-width: 1200px;',
    '            margin-left: auto;',
    '            margin-right: auto;',
    '        }',
    '        .clustering-info {',
    '            background: #f0f8ff;',
    '            padding: 15px;',
    '            border-radius: 5px;',
    '            margin: 10px 0;',
    '            font-size: 0.9em;',
    '            text-align: left;',
    '        }',
    '        .footer {',
    '            margin-top: 40px;',
    '            padding-top: 20px;',
    '            border-top: 1px solid #ddd;',
    '            text-align: center;',
    '            color: #666;',
    '        }',
    '    </style>',
    '</head>',
    '<body>',
    '    <div class="container">',
    '        <h1>📊 STEP 2: Statistical Comparisons - ALS vs Control</h1>',
    '        ',
    '        <div class="summary">',
    '            <h2>📈 Summary Statistics</h2>',
    '            <div class="stat-box">',
    '                <strong>68,968</strong><br>',
    '                Total SNVs Tested',
    '            </div>',
    '            <div class="stat-box">',
    '                <strong>13,240</strong><br>',
    '                Significant (FDR < 0.05)',
    '            </div>',
    '            <div class="stat-box">',
    '                <strong>8,664</strong><br>',
    '                Upregulated (ALS > Control)',
    '            </div>',
    '            <div class="stat-box">',
    '                <strong>4,571</strong><br>',
    '                Downregulated (ALS < Control)',
    '            </div>',
    '        </div>',
    '        ',
    '        <h2>📊 Step 2 Figures (FIG_2.1 to FIG_2.17)</h2>',
]

# Agregar cada figura
for fig_file, title, desc in figures_info:
    fig_path = figures_dir / fig_file
    
    if not fig_path.exists():
        print(f"⚠️  {fig_file} - NO ENCONTRADO")
        continue
    
    # Usar ruta absoluta con file://
    abs_path = fig_path.resolve()
    img_src = f"file://{abs_path}"
    
    html_lines.extend([
        '        <div class="figure-container">',
        f'            <div class="figure-title">{title}</div>',
        f'            <div class="figure-description">{desc}</div>',
        f'            <img src="{img_src}" alt="{title}" style="max-width: 100%; height: auto;">',
        '        </div>',
        '        ',
    ])
    
    # Agregar info especial para clustering
    if "2.16" in fig_file:
        html_lines.extend([
            '            <div class="clustering-info">',
            '                <strong>📊 Cluster Composition (k=2):</strong><br>',
            '                Cluster 1: 238 ALS, 56 Control<br>',
            '                Cluster 2: 75 ALS, 46 Control<br>',
            '                Cluster Purity: 68.4%<br>',
            '                <em>Cluster purity indica qué tan bien los clusters separan ALS de Control.</em>',
            '            </div>',
        ])
    elif "2.17" in fig_file:
        html_lines.extend([
            '            <div class="clustering-info">',
            '                <strong>📊 Cluster Composition (k=2):</strong><br>',
            '                Cluster 1: 218 ALS, 84 Control<br>',
            '                Cluster 2: 95 ALS, 18 Control<br>',
            '                Cluster Purity: 56.9%<br>',
            '                <em>Comparar con clustering de todos los SNVs para evaluar si seed region es más discriminativa.</em>',
            '            </div>',
        ])

html_lines.extend([
    '        <div class="footer">',
    '            <p>Pipeline: Snakemake | Step 2: Statistical Comparisons</p>',
    f'            <p>Generated: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}</p>',
    '        </div>',
    '    </div>',
    '</body>',
    '</html>',
])

# Guardar
output_html = viewer_dir / "step2_ABSOLUTE.html"
output_html.write_text('\n'.join(html_lines))
print(f"✅ Viewer HTML creado: {output_html}")
print(f"📊 Total figuras incluidas: {len([f for f, _, _ in figures_info if (figures_dir / f).exists()])}")

