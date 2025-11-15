# ============================================================================
# PROFESSIONAL THEME FOR FIGURES
# ============================================================================
# Consistent styling across all pipeline figures
#
# This theme provides a standardized look for all visualizations:
# - Clean, minimal design suitable for publications
# - Consistent text sizes and spacing
# - Professional color scheme (grey tones for axes/grids)
# - Bold titles and axis labels for clarity
# - Appropriate margins and padding for figures
#
# Usage:
#   library(ggplot2)
#   source("scripts/utils/theme_professional.R")
#   ggplot(data, aes(x, y)) + geom_point() + theme_professional

suppressPackageStartupMessages({
  library(ggplot2)
})

#' Professional ggplot2 theme for pipeline figures
#' 
#' A standardized theme providing consistent styling across all pipeline visualizations.
#' Based on `theme_minimal()` with customizations for publication-quality figures.
#' 
#' Features:
#' - Clean, minimal design suitable for publications
#' - Consistent text sizes (title: 13pt, subtitle: 10pt, axis: 11pt)
#' - Professional color scheme (grey tones for non-data elements)
#' - Bold titles and axis labels for clarity
#' - Appropriate margins and padding
#' 
#' @format An object of class `theme` (from ggplot2)
#' @examples
#' library(ggplot2)
#' ggplot(mtcars, aes(mpg, hp)) + 
#'   geom_point() + 
#'   theme_professional
theme_professional <- theme_minimal(base_size = 11) +
  theme(
    # Text
    plot.title = element_text(size = 13, face = "bold", hjust = 0.5, margin = margin(b = 8)),
    plot.subtitle = element_text(size = 10, color = "grey40", hjust = 0.5, margin = margin(b = 12)),
    plot.caption = element_text(size = 9, color = "grey50", hjust = 1),
    axis.title = element_text(size = 11, face = "bold"),
    axis.text = element_text(size = 10, color = "grey30"),
    legend.title = element_text(size = 10, face = "bold"),
    legend.text = element_text(size = 9),
    
    # Grid
    panel.grid.major = element_line(color = "grey90", linewidth = 0.5),
    panel.grid.minor = element_line(color = "grey95", linewidth = 0.25),
    panel.background = element_rect(fill = "white", color = NA),
    
    # Borders
    axis.line = element_line(color = "grey40", linewidth = 0.5),
    axis.ticks = element_line(color = "grey40", linewidth = 0.5),
    
    # Spacing
    plot.margin = margin(15, 15, 10, 15),
    legend.margin = margin(0, 0, 0, 0),
    legend.box.margin = margin(0, 0, 0, 0)
  )

