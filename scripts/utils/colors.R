# ============================================================================
# STANDARDIZED COLORS FOR PIPELINE
# ============================================================================
# Purpose: Provide consistent colors across all pipeline figures
# Usage: Source this file in scripts to use standardized colors
# ============================================================================

suppressPackageStartupMessages({
  library(stringr)
})

# ============================================================================
# PRIMARY COLORS
# ============================================================================

# G>T oxidation (primary biomarker)
COLOR_GT <- "#D62728"  # Red

# Group colors
COLOR_ALS <- "#D62728"      # Red (same as G>T for consistency)
COLOR_CONTROL <- "grey60"   # Grey

# ============================================================================
# MUTATION TYPE COLORS
# ============================================================================

# G>X mutations
COLOR_GC <- "#2E86AB"      # Blue
COLOR_GA <- "#7D3C98"      # Purple
COLOR_GT <- COLOR_GT       # Red (already defined above)

# Other mutation types (if needed)
COLOR_OTHER <- "grey50"

# Region colors (Seed vs Non-seed)
COLOR_SEED <- "#FFD700"      # Gold for seed region
COLOR_SEED_BACKGROUND <- "#FFF9C4"  # Light yellow for seed region background (Panel E)
COLOR_SEED_HIGHLIGHT <- "#e3f2fd"   # Light blue for seed region highlight (Panel B, C)
COLOR_NONSEED <- "#6c757d"   # Grey for non-seed region

# ============================================================================
# QUALITATIVE PALETTE
# ============================================================================

# Standard color palette for categorical data
# Used when you need distinct colors for multiple categories (e.g., multiple miRNA families)
# Based on ColorBrewer Set1 palette - colorblind-friendly and publication-ready
COLORS_QUALITATIVE <- c(
  "#1f77b4",  # Blue
  "#ff7f0e",  # Orange
  "#2ca02c",  # Green
  "#d62728",  # Red
  "#9467bd",  # Purple
  "#8c564b",  # Brown
  "#e377c2",  # Pink
  "#7f7f7f",  # Grey
  "#bcbd22",  # Yellow-green
  "#17becf"   # Cyan
)

# ============================================================================
# SEQUENTIAL PALETTE (for gradients)
# ============================================================================

# Sequential palettes are used for continuous data (e.g., VAF values, read counts)
# Colors progress from light (low values) to dark (high values)

# Standard sequential: White to red (emphasizes G>T oxidation)
COLORS_SEQUENTIAL_LOW <- "white"  # Low values (white background)
COLORS_SEQUENTIAL_LOW_PINK <- "#FFEBEE"  # Light pink for gradient start (Panel E - G-content landscape)
COLORS_SEQUENTIAL_MID <- "#FF7F0E"  # Orange (medium values)
COLORS_SEQUENTIAL_HIGH <- COLOR_GT  # Red (high values - G>T color)
COLORS_SEQUENTIAL_HIGH_DARK <- "#B71C1C"  # Dark red for gradient end (Panel E - emphasizes high G>T burden)

# Alternative sequential: White to purple (for alternative visualizations)
COLORS_SEQUENTIAL_PURPLE_LOW <- "white"  # Low values
COLORS_SEQUENTIAL_PURPLE_MID <- "#9467BD"  # Purple (medium values)
COLORS_SEQUENTIAL_PURPLE_HIGH <- COLOR_GT  # Red (high values - maintains G>T emphasis)

# Effect size colors (Cohen's d categories)
# Used in Step 2.3 for visualizing effect size magnitudes
COLOR_EFFECT_LARGE <- COLOR_GT  # Red (same as G>T for consistency) - |d| >= 0.8
COLOR_EFFECT_MEDIUM <- COLORS_SEQUENTIAL_MID  # Orange - 0.5 <= |d| < 0.8
COLOR_EFFECT_SMALL <- "#FFBB78"  # Light orange/peach - 0.2 <= |d| < 0.5
COLOR_EFFECT_NEGLIGIBLE <- "grey80"  # Grey - |d| < 0.2

# Volcano plot colors (Step 2.2)
# Used for categorizing points in volcano plots based on significance and fold change
COLOR_DOWNREGULATED <- "#2E86AB"  # Blue for downregulated (lower in group1 than group2)
COLOR_SIGNIFICANT_LOW_FC <- "#F77F00"  # Orange for significant but low fold change

# Clustering colors (Step 3)
# Used for visualizing cluster assignments in hierarchical clustering
COLOR_CLUSTER_1 <- "#FF6B6B"  # Coral red for cluster 1
COLOR_CLUSTER_2 <- "#4ECDC4"  # Turquoise for cluster 2

# Pathway/Functional analysis colors (Step 4)
# Used for distinguishing different functional annotation sources
COLOR_GO <- "#2E86AB"  # Blue for GO Biological Process
COLOR_KEGG <- "#A23B72"  # Purple for KEGG Pathway

# Significance category colors (Step 5 - miRNA families)
# Used for categorizing statistical significance levels
COLOR_SIGNIFICANCE_HIGH <- COLOR_GT  # Red (same as G>T for consistency) - High significance
COLOR_SIGNIFICANCE_MEDIUM <- COLORS_SEQUENTIAL_MID  # Orange - Medium significance
COLOR_SIGNIFICANCE_LOW <- "#2CA02C"  # Green - Low significance
COLOR_SIGNIFICANCE_NONE <- "grey70"  # Grey - Not significant

# AUC category colors (Step 7 - biomarker analysis)
# Used for categorizing Area Under Curve (AUC) values in ROC analysis
COLOR_AUC_EXCELLENT <- COLOR_GT  # Red - AUC >= 0.9 (excellent classifier)
COLOR_AUC_GOOD <- COLORS_SEQUENTIAL_MID  # Orange - 0.8 <= AUC < 0.9 (good classifier)
COLOR_AUC_FAIR <- COLOR_SIGNIFICANCE_LOW  # Green - 0.7 <= AUC < 0.8 (fair classifier)
COLOR_AUC_POOR <- "grey70"  # Grey - AUC < 0.7 (poor classifier)

# Gradient colors for heatmaps (alternative blue-to-red)
# Used in clustering and functional analysis visualizations
# Blue (low) → white (zero/medium) → red (high) provides intuitive visualization
COLOR_GRADIENT_LOW_BLUE <- COLOR_GO  # Blue for low values in blue-red gradients

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

#' Get color for a specific group
#' 
#' @param group_name Name of the group (e.g., "ALS", "Control")
#' @return Color code for the group
get_group_color <- function(group_name) {
  if (is.null(group_name)) return("grey50")
  
  group_lower <- tolower(group_name)
  if (stringr::str_detect(group_lower, "als|disease|case")) {
    return(COLOR_ALS)
  } else if (stringr::str_detect(group_lower, "control|ctrl|normal|healthy")) {
    return(COLOR_CONTROL)
  } else {
    return("grey50")
  }
}

#' Get colors for multiple groups
#' 
#' @param group_names Vector of group names
#' @return Named vector of colors
get_group_colors <- function(group_names) {
  colors <- sapply(group_names, get_group_color)
  names(colors) <- group_names
  return(colors)
}

#' Get color for mutation type
#' 
#' @param mutation_type Mutation type (e.g., "G>T", "G>C", "G>A")
#' @return Color code for the mutation type
get_mutation_color <- function(mutation_type) {
  if (is.null(mutation_type)) return(COLOR_OTHER)
  
  mutation_upper <- toupper(mutation_type)
  switch(mutation_upper,
    "G>T" = COLOR_GT,
    "G>C" = COLOR_GC,
    "G>A" = COLOR_GA,
    COLOR_OTHER
  )
}

#' Get heatmap gradient colors for VAF visualization
#' 
#' Generates a smooth gradient from white to red for visualizing VAF values.
#' The gradient emphasizes G>T oxidation (red).
#' 
#' @param n Number of colors in the gradient (default: 100)
#' @return Vector of color codes for the gradient
get_heatmap_gradient <- function(n = 100) {
  # Create smooth gradient from white to red
  # Intermediate colors provide smooth transition
  # Use grDevices::colorRampPalette for consistency
  grDevices::colorRampPalette(c(
    "white",      # White for low VAF
    "#FFE5E5",    # Very light pink
    "#FF9999",    # Light pink
    "#FF6666",    # Medium pink-red
    "#FF3333",    # Bright red
    COLOR_GT      # Dark red (G>T color)
  ))(n)
}

#' Get blue-to-red heatmap gradient colors for clustering/functional analysis
#' 
#' Generates a smooth gradient from blue (low) through white (medium) to red (high).
#' Used for visualizing differential patterns in clustering and functional analysis.
#' 
#' @param n Number of colors in the gradient (default: 100)
#' @return Vector of color codes for the gradient
get_blue_red_heatmap_gradient <- function(n = 100) {
  # Create smooth gradient from blue (low) through white (medium) to red (high)
  # Use grDevices::colorRampPalette for consistency
  grDevices::colorRampPalette(c(
    COLOR_GRADIENT_LOW_BLUE,  # Blue for low values
    "white",                  # White for medium/zero values
    COLOR_GT                  # Red for high values (G>T color)
  ))(n)
}

# ============================================================================
# COMPATIBILITY ALIASES (for backward compatibility)
# ============================================================================

# Allow both COLOR_GT and color_gt (lowercase)
color_gt <- COLOR_GT
color_als <- COLOR_ALS
color_control <- COLOR_CONTROL

# Aliases for convenience
COLOR_OTHERS <- COLOR_OTHER  # For "Other G transversions" in Panel G

