# ============================================================================
# PROFESSIONAL THEME FOR FIGURES
# ============================================================================
# Consistent styling across all pipeline figures

suppressPackageStartupMessages({
  library(ggplot2)
})

# Professional theme (consistent with pipeline style)
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

