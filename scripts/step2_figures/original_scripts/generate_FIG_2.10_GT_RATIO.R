#!/usr/bin/env Rscript
# ==============================================================================
# FIGURE 2.10: G>T RATIO ANALYSIS
# ==============================================================================
# Date: 2025-10-27
# Purpose: Analyze proportion of G>T among all G>X mutations
# Questions:
#   1. What proportion of G mutations are G>T (oxidation)?
#   2. Is this proportion consistent between ALS and Control?
#   3. Are there positional differences in G>T ratio?
#   4. Is seed region G>T ratio different?
# ==============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggpubr)
  library(patchwork)
})

# ============================================================================
# CONFIGURATION
# ============================================================================

input_file <- "final_processed_data_CLEAN.csv"
metadata_file <- "metadata.csv"
output_dir <- "figures_paso2_CLEAN"

dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# Colors
COLOR_ALS <- "#d32f2f"
COLOR_CONTROL <- "#1976d2"
COLOR_GT <- "#FF6B35"  # Orange for G>T
COLOR_GA <- "#4ECDC4"  # Teal for G>A
COLOR_GC <- "#95E1D3"  # Light green for G>C

# Seed positions
SEED_POSITIONS <- 2:8

# Theme
theme_professional <- theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 10, color = "gray30"),
    axis.title = element_text(face = "bold"),
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    panel.border = element_rect(fill = NA, color = "gray80")
  )

cat("\n")
cat(paste(rep("=", 80), collapse = ""), "\n")
cat("📊 FIGURE 2.10: G>T RATIO ANALYSIS\n")
cat(paste(rep("=", 80), collapse = ""), "\n\n")

# ============================================================================
# LOAD DATA
# ============================================================================

cat("📂 Loading data...\n")

data <- read.csv(input_file, check.names = FALSE)
metadata <- read.csv(metadata_file)
sample_cols <- metadata$Sample_ID

cat(sprintf("✅ Loaded: %d SNVs, %d samples\n\n", nrow(data), length(sample_cols)))

# ============================================================================
# EXTRACT G>X MUTATIONS
# ============================================================================

cat("📊 Extracting G>X mutations...\n")

# Extract position from pos.mut (format: "position:mutation")
data <- data %>%
  mutate(
    position = as.numeric(str_extract(pos.mut, "^[0-9]+")),
    mutation_type = str_extract(pos.mut, "[ACGT]+$")
  )

# Filter only G>X mutations (G>T, G>A, G>C)
gx_data <- data %>%
  filter(str_detect(pos.mut, "^[0-9]+:G[TAC]$"))

cat(sprintf("✅ G>X mutations: %d SNVs\n", nrow(gx_data)))
cat(sprintf("   G>T: %d\n", sum(gx_data$mutation_type == "GT")))
cat(sprintf("   G>A: %d\n", sum(gx_data$mutation_type == "GA")))
cat(sprintf("   G>C: %d\n\n", sum(gx_data$mutation_type == "GC")))

# ============================================================================
# CALCULATE G>T RATIO PER SAMPLE
# ============================================================================

cat("📊 Calculating G>T ratio per sample...\n")

# Transform to long format
gx_long <- gx_data %>%
  select(all_of(c("miRNA_name", "position", "mutation_type", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), 
               names_to = "Sample_ID", 
               values_to = "VAF") %>%
  left_join(metadata, by = "Sample_ID") %>%
  filter(!is.na(VAF), VAF > 0)

cat(sprintf("✅ Transformed: %d observations (VAF > 0)\n\n", nrow(gx_long)))

# Calculate total G>X counts per sample
gx_counts <- gx_long %>%
  group_by(Sample_ID, Group, mutation_type) %>%
  summarise(
    Total_VAF = sum(VAF),
    N_mutations = n(),
    .groups = "drop"
  ) %>%
  pivot_wider(
    names_from = mutation_type,
    values_from = c(Total_VAF, N_mutations),
    values_fill = list(Total_VAF = 0, N_mutations = 0)
  )

# Calculate G>T ratio (proportion)
gx_counts <- gx_counts %>%
  mutate(
    Total_GX_VAF = Total_VAF_GT + Total_VAF_GA + Total_VAF_GC,
    Total_GX_N = N_mutations_GT + N_mutations_GA + N_mutations_GC,
    GT_ratio_VAF = Total_VAF_GT / Total_GX_VAF * 100,
    GT_ratio_N = N_mutations_GT / Total_GX_N * 100
  )

cat("📊 Sample statistics:\n")
cat(sprintf("   Samples: %d\n", nrow(gx_counts)))
cat(sprintf("   ALS: %d\n", sum(gx_counts$Group == "ALS")))
cat(sprintf("   Control: %d\n\n", sum(gx_counts$Group == "Control")))

# ============================================================================
# STATISTICAL TEST: GLOBAL G>T RATIO
# ============================================================================

cat("🔬 Testing global G>T ratio difference...\n")

# Test using VAF-based ratio
wilcox_vaf <- wilcox.test(GT_ratio_VAF ~ Group, data = gx_counts)
t_test_vaf <- t.test(GT_ratio_VAF ~ Group, data = gx_counts)

# Test using count-based ratio
wilcox_n <- wilcox.test(GT_ratio_N ~ Group, data = gx_counts)
t_test_n <- t.test(GT_ratio_N ~ Group, data = gx_counts)

# Effect size
cohen_d_vaf <- (mean(gx_counts$GT_ratio_VAF[gx_counts$Group == "ALS"]) - 
                mean(gx_counts$GT_ratio_VAF[gx_counts$Group == "Control"])) /
               sd(gx_counts$GT_ratio_VAF)

cat("✅ Global G>T ratio tests:\n")
cat(sprintf("   VAF-based ratio:\n"))
cat(sprintf("     Wilcoxon: p = %s\n", format.pval(wilcox_vaf$p.value, digits = 3)))
cat(sprintf("     t-test:   p = %s\n", format.pval(t_test_vaf$p.value, digits = 3)))
cat(sprintf("   Count-based ratio:\n"))
cat(sprintf("     Wilcoxon: p = %s\n", format.pval(wilcox_n$p.value, digits = 3)))
cat(sprintf("     t-test:   p = %s\n", format.pval(t_test_n$p.value, digits = 3)))
cat(sprintf("   Effect size (Cohen's d): %.3f\n\n", cohen_d_vaf))

# Summary statistics
ratio_summary <- gx_counts %>%
  group_by(Group) %>%
  summarise(
    N = n(),
    Mean_ratio_VAF = mean(GT_ratio_VAF, na.rm = TRUE),
    SD_ratio_VAF = sd(GT_ratio_VAF, na.rm = TRUE),
    Median_ratio_VAF = median(GT_ratio_VAF, na.rm = TRUE),
    Mean_ratio_N = mean(GT_ratio_N, na.rm = TRUE),
    SD_ratio_N = sd(GT_ratio_N, na.rm = TRUE),
    .groups = "drop"
  )

cat("📊 Group summary:\n")
print(ratio_summary)
cat("\n")

# ============================================================================
# CALCULATE G>T RATIO PER POSITION
# ============================================================================

cat("📊 Calculating G>T ratio per position...\n")

# Calculate per position per group
position_ratios <- gx_long %>%
  group_by(position, Group, mutation_type) %>%
  summarise(
    Total_VAF = sum(VAF),
    N_mutations = n(),
    .groups = "drop"
  ) %>%
  pivot_wider(
    names_from = mutation_type,
    values_from = c(Total_VAF, N_mutations),
    values_fill = list(Total_VAF = 0, N_mutations = 0)
  ) %>%
  mutate(
    Total_GX_VAF = Total_VAF_GT + Total_VAF_GA + Total_VAF_GC,
    Total_GX_N = N_mutations_GT + N_mutations_GA + N_mutations_GC,
    GT_ratio_VAF = Total_VAF_GT / Total_GX_VAF * 100,
    GT_ratio_N = N_mutations_GT / Total_GX_N * 100
  )

cat(sprintf("✅ Calculated ratios for %d positions\n\n", 
            length(unique(position_ratios$position))))

# ============================================================================
# CALCULATE SEED VS NON-SEED RATIO
# ============================================================================

cat("📊 Calculating seed vs non-seed G>T ratio...\n")

gx_long_region <- gx_long %>%
  mutate(Region = ifelse(position %in% SEED_POSITIONS, "Seed", "Non-seed"))

seed_ratios <- gx_long_region %>%
  group_by(Region, Group, mutation_type) %>%
  summarise(
    Total_VAF = sum(VAF),
    N_mutations = n(),
    .groups = "drop"
  ) %>%
  pivot_wider(
    names_from = mutation_type,
    values_from = c(Total_VAF, N_mutations),
    values_fill = list(Total_VAF = 0, N_mutations = 0)
  ) %>%
  mutate(
    Total_GX_VAF = Total_VAF_GT + Total_VAF_GA + Total_VAF_GC,
    Total_GX_N = N_mutations_GT + N_mutations_GA + N_mutations_GC,
    GT_ratio_VAF = Total_VAF_GT / Total_GX_VAF * 100,
    GT_ratio_N = N_mutations_GT / Total_GX_N * 100
  )

cat("✅ Seed vs Non-seed ratios:\n")
print(seed_ratios %>% select(Region, Group, GT_ratio_VAF, GT_ratio_N))
cat("\n")

# ============================================================================
# FIGURE 2.10A: GLOBAL G>T RATIO COMPARISON
# ============================================================================

cat("📊 Creating Figure 2.10A: Global ratio comparison...\n")

fig_2_10a <- ggplot(gx_counts, aes(x = Group, y = GT_ratio_VAF, fill = Group)) +
  
  # Violin + box
  geom_violin(alpha = 0.4, trim = FALSE) +
  geom_boxplot(width = 0.2, alpha = 0.8, outlier.size = 2) +
  
  # Mean point
  stat_summary(fun = mean, geom = "point", shape = 23, size = 4, 
               fill = "yellow", color = "black", stroke = 1.2) +
  
  # Significance annotation
  annotate("text", x = 1.5, y = max(gx_counts$GT_ratio_VAF) * 1.05,
           label = ifelse(wilcox_vaf$p.value < 0.001, "***",
                         ifelse(wilcox_vaf$p.value < 0.01, "**",
                               ifelse(wilcox_vaf$p.value < 0.05, "*", "ns"))),
           size = 10) +
  
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  
  labs(
    title = "A. Global G>T Ratio",
    subtitle = sprintf("Wilcoxon: p = %s | t-test: p = %s | Cohen's d = %.2f",
                      format.pval(wilcox_vaf$p.value, digits = 3),
                      format.pval(t_test_vaf$p.value, digits = 3),
                      cohen_d_vaf),
    x = "Group",
    y = "G>T / (G>T + G>A + G>C) (%)",
    caption = sprintf("ALS: n=%d | Control: n=%d\nYellow diamond = mean",
                     sum(gx_counts$Group == "ALS"),
                     sum(gx_counts$Group == "Control"))
  ) +
  
  theme_professional +
  theme(legend.position = "none")

ggsave(file.path(output_dir, "FIG_2.10A_GLOBAL_RATIO.png"),
       plot = fig_2_10a, width = 8, height = 7, dpi = 300)

cat("✅ Figure 2.10A saved\n\n")

# ============================================================================
# FIGURE 2.10B: POSITIONAL G>T RATIO HEATMAP
# ============================================================================

cat("📊 Creating Figure 2.10B: Positional ratio heatmap...\n")

# Prepare data for heatmap
position_ratios_wide <- position_ratios %>%
  select(position, Group, GT_ratio_VAF) %>%
  pivot_wider(names_from = Group, values_from = GT_ratio_VAF)

fig_2_10b <- ggplot(position_ratios, aes(x = position, y = Group, fill = GT_ratio_VAF)) +
  geom_tile(color = "white", linewidth = 0.5) +
  
  # Add text values
  geom_text(aes(label = sprintf("%.1f", GT_ratio_VAF)), size = 3, color = "white") +
  
  # Highlight seed region
  annotate("rect", xmin = 1.5, xmax = 8.5, ymin = 0.5, ymax = 2.5,
           fill = NA, color = "gold", linewidth = 1.5, linetype = "dashed") +
  
  scale_fill_gradient2(
    low = "blue", mid = "white", high = "red",
    midpoint = 50,
    limits = c(0, 100),
    name = "G>T\nRatio (%)"
  ) +
  
  scale_x_continuous(breaks = 1:22) +
  
  labs(
    title = "B. Positional G>T Ratio",
    subtitle = "G>T proportion by position | Seed region highlighted (2-8)",
    x = "miRNA Position",
    y = "Group"
  ) +
  
  theme_professional +
  theme(
    panel.grid = element_blank(),
    axis.text.x = element_text(size = 9)
  )

ggsave(file.path(output_dir, "FIG_2.10B_POSITIONAL_RATIO.png"),
       plot = fig_2_10b, width = 12, height = 5, dpi = 300)

cat("✅ Figure 2.10B saved\n\n")

# ============================================================================
# FIGURE 2.10C: SEED VS NON-SEED RATIO
# ============================================================================

cat("📊 Creating Figure 2.10C: Seed vs non-seed ratio...\n")

fig_2_10c <- ggplot(seed_ratios, aes(x = Region, y = GT_ratio_VAF, fill = Group)) +
  geom_col(position = "dodge", alpha = 0.8, width = 0.7) +
  
  # Add value labels
  geom_text(aes(label = sprintf("%.1f%%", GT_ratio_VAF)),
            position = position_dodge(width = 0.7),
            vjust = -0.5, size = 3.5) +
  
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  
  coord_cartesian(ylim = c(0, max(seed_ratios$GT_ratio_VAF) * 1.15)) +
  
  labs(
    title = "C. G>T Ratio by Region",
    subtitle = "Seed (positions 2-8) vs Non-seed comparison",
    x = "miRNA Region",
    y = "G>T / (G>T + G>A + G>C) (%)",
    fill = "Group"
  ) +
  
  theme_professional

ggsave(file.path(output_dir, "FIG_2.10C_SEED_RATIO.png"),
       plot = fig_2_10c, width = 9, height = 7, dpi = 300)

cat("✅ Figure 2.10C saved\n\n")

# ============================================================================
# FIGURE 2.10D: MUTATION TYPE BREAKDOWN
# ============================================================================

cat("📊 Creating Figure 2.10D: Mutation type breakdown...\n")

# Calculate proportions globally
mut_breakdown <- gx_long %>%
  group_by(Group, mutation_type) %>%
  summarise(
    Total_VAF = sum(VAF),
    N = n(),
    .groups = "drop"
  ) %>%
  group_by(Group) %>%
  mutate(
    Proportion = Total_VAF / sum(Total_VAF) * 100
  )

fig_2_10d <- ggplot(mut_breakdown, aes(x = Group, y = Proportion, fill = mutation_type)) +
  geom_col(alpha = 0.8, width = 0.6) +
  
  # Add percentage labels
  geom_text(aes(label = sprintf("%.1f%%", Proportion)),
            position = position_stack(vjust = 0.5),
            size = 4, color = "white", fontface = "bold") +
  
  scale_fill_manual(
    values = c("GT" = COLOR_GT, "GA" = COLOR_GA, "GC" = COLOR_GC),
    labels = c("GT" = "G>T (oxidation)", "GA" = "G>A", "GC" = "G>C"),
    name = "Mutation Type"
  ) +
  
  labs(
    title = "D. G>X Mutation Spectrum",
    subtitle = "Proportion of each G mutation type (VAF-weighted)",
    x = "Group",
    y = "Proportion (%)"
  ) +
  
  theme_professional

ggsave(file.path(output_dir, "FIG_2.10D_MUTATION_BREAKDOWN.png"),
       plot = fig_2_10d, width = 9, height = 7, dpi = 300)

cat("✅ Figure 2.10D saved\n\n")

# ============================================================================
# FIGURE 2.10_COMBINED: PUBLICATION VERSION
# ============================================================================

cat("📊 Creating combined figure...\n")

fig_2_10_combined <- (fig_2_10a | fig_2_10b) / (fig_2_10c | fig_2_10d) +
  plot_annotation(
    title = "Figure 2.10: G>T Ratio Analysis",
    subtitle = "Proportion of G>T among all G>X mutations",
    theme = theme(plot.title = element_text(face = "bold", size = 16))
  )

ggsave(file.path(output_dir, "FIG_2.10_COMBINED.png"),
       plot = fig_2_10_combined, width = 18, height = 14, dpi = 300)

cat("✅ Combined figure saved\n\n")

# ============================================================================
# SAVE STATISTICAL RESULTS
# ============================================================================

cat("💾 Saving statistical results...\n")

# 1. Global ratio summary
write.csv(ratio_summary,
          file.path(output_dir, "TABLE_2.10_global_ratio_summary.csv"),
          row.names = FALSE)

# 2. Statistical tests
test_results <- data.frame(
  Test = c("Wilcoxon (VAF)", "t-test (VAF)", "Wilcoxon (Count)", "t-test (Count)"),
  Statistic = c(wilcox_vaf$statistic, t_test_vaf$statistic, 
                wilcox_n$statistic, t_test_n$statistic),
  Pvalue = c(wilcox_vaf$p.value, t_test_vaf$p.value, 
             wilcox_n$p.value, t_test_n$p.value),
  Interpretation = c(
    ifelse(wilcox_vaf$p.value < 0.05, "Significant", "Not significant"),
    ifelse(t_test_vaf$p.value < 0.05, "Significant", "Not significant"),
    ifelse(wilcox_n$p.value < 0.05, "Significant", "Not significant"),
    ifelse(t_test_n$p.value < 0.05, "Significant", "Not significant")
  )
)

write.csv(test_results,
          file.path(output_dir, "TABLE_2.10_statistical_tests.csv"),
          row.names = FALSE)

# 3. Positional ratios
write.csv(position_ratios,
          file.path(output_dir, "TABLE_2.10_positional_ratios.csv"),
          row.names = FALSE)

# 4. Seed vs non-seed
write.csv(seed_ratios,
          file.path(output_dir, "TABLE_2.10_seed_ratios.csv"),
          row.names = FALSE)

# 5. Per-sample ratios
write.csv(gx_counts,
          file.path(output_dir, "TABLE_2.10_per_sample_ratios.csv"),
          row.names = FALSE)

cat("✅ All statistical results saved\n\n")

# ============================================================================
# SUMMARY REPORT
# ============================================================================

cat("\n")
cat(paste(rep("=", 80), collapse = ""), "\n")
cat("📊 FIGURE 2.10 GENERATION COMPLETE\n")
cat(paste(rep("=", 80), collapse = ""), "\n\n")

cat("✅ Generated figures:\n")
cat("   • FIG_2.10A_GLOBAL_RATIO.png        - Global G>T ratio comparison\n")
cat("   • FIG_2.10B_POSITIONAL_RATIO.png    - Positional heatmap\n")
cat("   • FIG_2.10C_SEED_RATIO.png          - Seed vs non-seed\n")
cat("   • FIG_2.10D_MUTATION_BREAKDOWN.png  - G>X spectrum\n")
cat("   • FIG_2.10_COMBINED.png             - Combined (all 4) ⭐\n\n")

cat("✅ Statistical tables:\n")
cat("   • TABLE_2.10_global_ratio_summary.csv\n")
cat("   • TABLE_2.10_statistical_tests.csv\n")
cat("   • TABLE_2.10_positional_ratios.csv\n")
cat("   • TABLE_2.10_seed_ratios.csv\n")
cat("   • TABLE_2.10_per_sample_ratios.csv\n\n")

cat("📊 Key Results:\n")
cat(sprintf("   ALS:     G>T ratio = %.1f%% (SD = %.1f%%)\n",
            ratio_summary$Mean_ratio_VAF[ratio_summary$Group == "ALS"],
            ratio_summary$SD_ratio_VAF[ratio_summary$Group == "ALS"]))
cat(sprintf("   Control: G>T ratio = %.1f%% (SD = %.1f%%)\n",
            ratio_summary$Mean_ratio_VAF[ratio_summary$Group == "Control"],
            ratio_summary$SD_ratio_VAF[ratio_summary$Group == "Control"]))
cat(sprintf("   Difference: %.1f%%\n\n",
            abs(ratio_summary$Mean_ratio_VAF[ratio_summary$Group == "ALS"] -
                ratio_summary$Mean_ratio_VAF[ratio_summary$Group == "Control"])))

cat("📊 Statistical Interpretation:\n")

if (wilcox_vaf$p.value < 0.05) {
  cat("   ✅ Significant difference in G>T ratio (p < 0.05)\n")
  if (ratio_summary$Mean_ratio_VAF[ratio_summary$Group == "ALS"] > 
      ratio_summary$Mean_ratio_VAF[ratio_summary$Group == "Control"]) {
    cat("   → ALS has HIGHER G>T proportion\n")
  } else {
    cat("   → Control has HIGHER G>T proportion\n")
  }
} else {
  cat("   ⚠️ No significant difference in G>T ratio (p ≥ 0.05)\n")
  cat("   → Both groups have similar oxidation specificity\n")
}

cat("\n")
cat(paste(rep("=", 80), collapse = ""), "\n")
cat("✅ ALL FILES SAVED TO:", output_dir, "\n")
cat(paste(rep("=", 80), collapse = ""), "\n\n")

