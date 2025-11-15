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

# Low to high gradient (white to red for G>T emphasis)
COLORS_SEQUENTIAL_LOW <- "white"
COLORS_SEQUENTIAL_LOW_PINK <- "#FFEBEE"  # Light pink for gradient start (Panel E)
COLORS_SEQUENTIAL_MID <- "#FF7F0E"  # Orange
COLORS_SEQUENTIAL_HIGH <- COLOR_GT  # Red
COLORS_SEQUENTIAL_HIGH_DARK <- "#B71C1C"  # Dark red for gradient end (Panel E)

# Alternative sequential (white to purple)
COLORS_SEQUENTIAL_PURPLE_LOW <- "white"
COLORS_SEQUENTIAL_PURPLE_MID <- "#9467BD"  # Purple
COLORS_SEQUENTIAL_PURPLE_HIGH <- COLOR_GT  # Red

# Effect size colors
COLOR_EFFECT_LARGE <- COLOR_GT  # Red (same as G>T for consistency)
COLOR_EFFECT_MEDIUM <- COLORS_SEQUENTIAL_MID  # Orange
COLOR_EFFECT_SMALL <- "#FFBB78"  # Light orange/peach
COLOR_EFFECT_NEGLIGIBLE <- "grey80"

# Volcano plot colors
COLOR_DOWNREGULATED <- "#2E86AB"  # Blue for downregulated
COLOR_SIGNIFICANT_LOW_FC <- "#F77F00"  # Orange for significant but low FC

# Clustering colors
COLOR_CLUSTER_1 <- "#FF6B6B"  # Coral red for cluster 1
COLOR_CLUSTER_2 <- "#4ECDC4"  # Turquoise for cluster 2

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

# ============================================================================
# COMPATIBILITY ALIASES (for backward compatibility)
# ============================================================================

# Allow both COLOR_GT and color_gt (lowercase)
color_gt <- COLOR_GT
color_als <- COLOR_ALS
color_control <- COLOR_CONTROL

# Aliases for convenience
COLOR_OTHERS <- COLOR_OTHER  # For "Other G transversions" in Panel G

