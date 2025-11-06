#!/usr/bin/env Rscript
# ============================================================================
# FIGURAS 2.13-2.15 - DENSITY HEATMAPS
# Density of SNVs and VAF distribution by position
# Fig 2.13: ALS only
# Fig 2.14: Control only
# Fig 2.15: Combined (side-by-side)
# ============================================================================

library(ggplot2)
library(dplyr)
library(tidyr)
library(readr)
library(stringr)
library(patchwork)

# Colores profesionales
COLOR_ALS <- "#D62728"
COLOR_CONTROL <- "#2E86AB"

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  GENERATING FIGS 2.13-2.15 - DENSITY HEATMAPS\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# ============================================================================
# LOAD DATA
# ============================================================================

cat("📂 Loading data...\n")
data <- read_csv("final_processed_data_CLEAN.csv", show_col_types = FALSE)
metadata <- read_csv("metadata.csv", show_col_types = FALSE)
sample_cols <- metadata$Sample_ID

cat("   ✅ Data loaded:", nrow(data), "SNVs,", length(sample_cols), "samples\n\n")

# ============================================================================
# PREPARE DATA
# ============================================================================

cat("📊 Preparing density data...\n")

# Filter G>T only
vaf_gt <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^\\d+"))) %>%
  filter(!is.na(position), position <= 23)

# Transform to long format
vaf_long <- vaf_gt %>%
  select(miRNA_name, position, all_of(sample_cols)) %>%
  pivot_longer(cols = all_of(sample_cols), 
               names_to = "Sample_ID", 
               values_to = "VAF") %>%
  filter(!is.na(VAF), VAF > 0) %>%
  left_join(metadata %>% select(Sample_ID, Group), by = "Sample_ID")

cat("   ✅ Data prepared:", nrow(vaf_long), "non-zero VAF observations\n\n")

# ============================================================================
# CALCULATE DENSITY PER POSITION
# ============================================================================

cat("📊 Calculating SNV density per position...\n")

# Count SNVs per position
snv_density <- vaf_long %>%
  group_by(position, Group) %>%
  summarise(
    N_SNVs = n(),
    Mean_VAF = mean(VAF),
    Median_VAF = median(VAF),
    .groups = "drop"
  )

cat("   ✅ Density calculated\n\n")

# ============================================================================
# FUNCTION TO CREATE DENSITY HEATMAP
# ============================================================================

create_density_heatmap <- function(group_name, color_main) {
  
  # Filter data for this group
  group_data <- vaf_long %>% filter(Group == group_name)
  density_data <- snv_density %>% filter(Group == group_name)
  
  # Bin VAF values for heatmap
  group_data_binned <- group_data %>%
    mutate(
      VAF_bin = cut(VAF, 
                    breaks = c(0, 0.001, 0.01, 0.05, 0.1, 0.2, 1),
                    labels = c("0-0.001", "0.001-0.01", "0.01-0.05", 
                              "0.05-0.1", "0.1-0.2", ">0.2"),
                    include.lowest = TRUE)
    )
  
  # Count per position and VAF bin
  heatmap_counts <- group_data_binned %>%
    group_by(position, VAF_bin) %>%
    summarise(Count = n(), .groups = "drop")
  
  # Main heatmap
  p_heatmap <- ggplot(heatmap_counts, aes(x = as.factor(position), y = VAF_bin, fill = Count)) +
    geom_tile(color = "white", linewidth = 0.5) +
    scale_fill_viridis_c(option = "plasma", name = "SNV\nCount") +
    labs(
      x = NULL,
      y = "VAF Range"
    ) +
    theme_minimal(base_size = 11) +
    theme(
      axis.text.x = element_blank(),
      axis.ticks.x = element_blank(),
      panel.grid = element_blank(),
      legend.position = "right"
    )
  
  # Density barplot (top)
  p_density <- ggplot(density_data, aes(x = as.factor(position), y = N_SNVs)) +
    geom_col(fill = color_main, alpha = 0.8) +
    labs(
      title = paste("Density Heatmap:", group_name),
      subtitle = "SNV count and VAF distribution by position",
      y = "Total SNVs"
    ) +
    theme_minimal(base_size = 11) +
    theme(
      axis.text.x = element_blank(),
      axis.title.x = element_blank(),
      axis.ticks.x = element_blank(),
      panel.grid.minor = element_blank(),
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(size = 10, color = "gray30")
    )
  
  # Position labels (bottom)
  p_labels <- ggplot(density_data, aes(x = as.factor(position), y = 1)) +
    geom_text(aes(label = position), size = 3.5, vjust = 0.5) +
    labs(x = "Position in miRNA", y = NULL) +
    theme_void() +
    theme(
      axis.title.x = element_text(face = "bold", size = 11, margin = margin(t = 10)),
      axis.text.x = element_blank(),
      plot.margin = margin(5, 5, 10, 5)
    )
  
  # Combine with patchwork
  combined <- p_density / p_heatmap / p_labels +
    plot_layout(heights = c(2, 5, 0.5))
  
  return(combined)
}

# ============================================================================
# GENERATE FIGURES
# ============================================================================

cat("🎨 Generating Figure 2.13: ALS density heatmap...\n")
fig_2_13 <- create_density_heatmap("ALS", COLOR_ALS)
ggsave("figures_paso2_CLEAN/FIG_2.13_DENSITY_HEATMAP_ALS.png", 
       fig_2_13, width = 14, height = 10, dpi = 300, bg = "white")
cat("   ✅ Figure saved: FIG_2.13_DENSITY_HEATMAP_ALS.png\n\n")

cat("🎨 Generating Figure 2.14: Control density heatmap...\n")
fig_2_14 <- create_density_heatmap("Control", COLOR_CONTROL)
ggsave("figures_paso2_CLEAN/FIG_2.14_DENSITY_HEATMAP_CONTROL.png", 
       fig_2_14, width = 14, height = 10, dpi = 300, bg = "white")
cat("   ✅ Figure saved: FIG_2.14_DENSITY_HEATMAP_CONTROL.png\n\n")

# ============================================================================
# FIGURE 2.15: COMBINED (SIDE-BY-SIDE)
# ============================================================================

cat("🎨 Generating Figure 2.15: Combined density heatmap...\n")

# Prepare combined data for side-by-side comparison
group_data_binned <- vaf_long %>%
  mutate(
    VAF_bin = cut(VAF, 
                  breaks = c(0, 0.001, 0.01, 0.05, 0.1, 0.2, 1),
                  labels = c("0-0.001", "0.001-0.01", "0.01-0.05", 
                            "0.05-0.1", "0.1-0.2", ">0.2"),
                  include.lowest = TRUE)
  )

# Count per position, VAF bin, and group
heatmap_counts_combined <- group_data_binned %>%
  group_by(position, VAF_bin, Group) %>%
  summarise(Count = n(), .groups = "drop")

# Combined heatmap
p_combined_heatmap <- ggplot(heatmap_counts_combined, 
                             aes(x = as.factor(position), y = VAF_bin, fill = Count)) +
  geom_tile(color = "white", linewidth = 0.5) +
  facet_wrap(~Group, ncol = 2) +
  scale_fill_viridis_c(option = "plasma", name = "SNV\nCount") +
  labs(
    x = "Position in miRNA",
    y = "VAF Range"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid = element_blank(),
    legend.position = "right",
    strip.text = element_text(size = 12, face = "bold"),
    strip.background = element_rect(fill = "gray90", color = "gray50"),
    axis.text.x = element_text(angle = 0, hjust = 0.5)
  )

# Density barplot (top) - combined
p_combined_density <- ggplot(snv_density, aes(x = as.factor(position), y = N_SNVs, fill = Group)) +
  geom_col(position = "dodge", alpha = 0.8) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  facet_wrap(~Group, ncol = 2) +
  labs(
    title = "Density Heatmaps: ALS vs Control Comparison",
    subtitle = "SNV count and VAF distribution by position",
    y = "Total SNVs"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    axis.text.x = element_blank(),
    axis.title.x = element_blank(),
    axis.ticks.x = element_blank(),
    panel.grid.minor = element_blank(),
    strip.text = element_text(size = 12, face = "bold"),
    strip.background = element_rect(fill = "gray90", color = "gray50"),
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 10, color = "gray30"),
    legend.position = "none"
  )

# Combine
fig_2_15 <- p_combined_density / p_combined_heatmap +
  plot_layout(heights = c(2, 5))

ggsave("figures_paso2_CLEAN/FIG_2.15_DENSITY_COMBINED.png", 
       fig_2_15, width = 16, height = 10, dpi = 300, bg = "white")

cat("   ✅ Figure saved: FIG_2.15_DENSITY_COMBINED.png\n\n")

# ============================================================================
# SUMMARY STATISTICS
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("📊 DENSITY SUMMARY:\n\n")

density_summary <- snv_density %>%
  group_by(Group) %>%
  summarise(
    Total_SNVs = sum(N_SNVs),
    Mean_per_position = mean(N_SNVs),
    Max_position = position[which.max(N_SNVs)][1],
    Max_N = max(N_SNVs),
    .groups = "drop"
  )

print(density_summary)
cat("\n")

# Hotspots
hotspots <- snv_density %>%
  group_by(position) %>%
  summarise(Total = sum(N_SNVs), .groups = "drop") %>%
  arrange(desc(Total)) %>%
  head(5)

cat("TOP 5 HOTSPOT POSITIONS:\n")
print(hotspots)
cat("\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("✅ ALL 3 DENSITY FIGURES GENERATED SUCCESSFULLY\n\n")

