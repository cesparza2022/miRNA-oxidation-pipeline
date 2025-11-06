#!/usr/bin/env Rscript
# ==============================================================================
# FIGURE 2.6 IMPROVED: POSITIONAL G>T BURDEN ANALYSIS
# ==============================================================================
# Date: 2025-10-27
# Purpose: Create comprehensive positional analysis with statistical rigor
# Improvements:
#   1. Proper error bars (SE or 95% CI)
#   2. Statistical tests per position (Wilcoxon + FDR correction)
#   3. Multiple visualization options
#   4. Seed vs non-seed direct comparison
#   5. Coverage tracking
#   6. Enhanced annotations
# ==============================================================================

library(tidyverse)
library(ggpubr)
library(patchwork)

# ============================================================================
# CONFIGURATION
# ============================================================================

# Input file
input_file <- "final_processed_data_CLEAN.csv"
output_dir <- "figures_paso2_CLEAN"

# Create output directory
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# Colors
COLOR_ALS <- "#d32f2f"
COLOR_CONTROL <- "#1976d2"
COLOR_SEED <- "#bbdefb"
COLOR_SEED_LINE <- "#1565c0"

# Theme
theme_professional <- theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 11, color = "gray30"),
    axis.title = element_text(face = "bold"),
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    panel.border = element_rect(fill = NA, color = "gray80")
  )

# ============================================================================
# LOAD AND PREPARE DATA
# ============================================================================

cat("📂 Loading data...\n")
data <- read.csv(input_file, check.names = FALSE)

# Get sample columns
sample_cols <- names(data)[3:ncol(data)]

# Filter: G>T mutations only
vaf_gt <- data %>%
  filter(str_detect(pos.mut, ":GT$"))

# Extract position
vaf_gt <- vaf_gt %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^\\d+"))) %>%
  filter(!is.na(position), position <= 22)

# Transform to long format
vaf_long <- vaf_gt %>%
  select(miRNA_name, position, all_of(sample_cols)) %>%
  pivot_longer(cols = all_of(sample_cols), 
               names_to = "Sample_ID", 
               values_to = "VAF") %>%
  filter(!is.na(VAF))

# Add metadata
metadata <- data.frame(
  Sample_ID = sample_cols,
  Group = ifelse(grepl("^ALS", sample_cols), "ALS", "Control")
)

vaf_long <- vaf_long %>%
  left_join(metadata, by = "Sample_ID")

cat(sprintf("✅ Data loaded: %d SNVs, %d samples\n\n", 
            nrow(vaf_gt), length(sample_cols)))

# ============================================================================
# CALCULATE POSITIONAL STATISTICS
# ============================================================================

cat("📊 Calculating positional statistics...\n")

# Aggregate per sample first (CORRECT METHOD)
vaf_per_sample <- vaf_long %>%
  group_by(Sample_ID, position, Group) %>%
  summarise(Total_VAF = sum(VAF, na.rm = TRUE),
            N_SNVs = n(),
            .groups = "drop")

# Calculate statistics per position and group
positional_stats <- vaf_per_sample %>%
  group_by(position, Group) %>%
  summarise(
    Mean_VAF = mean(Total_VAF, na.rm = TRUE),
    Median_VAF = median(Total_VAF, na.rm = TRUE),
    SD_VAF = sd(Total_VAF, na.rm = TRUE),
    SE_VAF = sd(Total_VAF, na.rm = TRUE) / sqrt(n()),
    N_samples = n(),
    N_SNVs_total = sum(N_SNVs),
    .groups = "drop"
  ) %>%
  mutate(
    CI_lower = Mean_VAF - 1.96 * SE_VAF,
    CI_upper = Mean_VAF + 1.96 * SE_VAF
  )

# ============================================================================
# STATISTICAL TESTS PER POSITION
# ============================================================================

cat("🔬 Performing statistical tests per position...\n")

position_tests <- data.frame()

for (pos in 1:22) {
  pos_data <- vaf_per_sample %>% filter(position == pos)
  
  als_vals <- pos_data %>% filter(Group == "ALS") %>% pull(Total_VAF)
  ctrl_vals <- pos_data %>% filter(Group == "Control") %>% pull(Total_VAF)
  
  if (length(als_vals) >= 5 && length(ctrl_vals) >= 5) {
    # Wilcoxon rank-sum test
    test_result <- tryCatch({
      wilcox.test(als_vals, ctrl_vals)
    }, error = function(e) {
      list(p.value = 1)
    })
    
    # Effect size (Cohen's d)
    pooled_sd <- sqrt(((length(als_vals) - 1) * var(als_vals) + 
                       (length(ctrl_vals) - 1) * var(ctrl_vals)) / 
                      (length(als_vals) + length(ctrl_vals) - 2))
    cohens_d <- (mean(als_vals) - mean(ctrl_vals)) / pooled_sd
    
    position_tests <- rbind(position_tests, data.frame(
      position = pos,
      pvalue = test_result$p.value,
      mean_ALS = mean(als_vals),
      mean_Control = mean(ctrl_vals),
      difference = mean(als_vals) - mean(ctrl_vals),
      cohens_d = cohens_d,
      n_ALS = length(als_vals),
      n_Control = length(ctrl_vals)
    ))
  }
}

# FDR correction (only if we have results)
if (nrow(position_tests) > 0) {
  position_tests$padj <- p.adjust(position_tests$pvalue, method = "fdr")
  
  # Significance levels
  position_tests$significance <- case_when(
    position_tests$padj < 0.001 ~ "***",
    position_tests$padj < 0.01 ~ "**",
    position_tests$padj < 0.05 ~ "*",
    TRUE ~ "ns"
  )
  
  cat(sprintf("✅ Tests completed. Significant positions (FDR < 0.05): %d\n\n",
              sum(position_tests$padj < 0.05)))
} else {
  cat("⚠️ No statistical tests could be performed (insufficient data)\n\n")
  # Create empty dataframe with expected columns
  position_tests <- data.frame(
    position = integer(),
    pvalue = numeric(),
    mean_ALS = numeric(),
    mean_Control = numeric(),
    difference = numeric(),
    cohens_d = numeric(),
    n_ALS = integer(),
    n_Control = integer(),
    padj = numeric(),
    significance = character()
  )
}

# ============================================================================
# FIGURE 2.6A: LINE PLOT WITH CONFIDENCE INTERVALS
# ============================================================================

cat("📊 Creating Figure 2.6A: Line plot with CI...\n")

# Prepare data for plotting
if (nrow(position_tests) > 0) {
  plot_data_2_6a <- positional_stats %>%
    left_join(position_tests %>% select(position, padj, significance), 
              by = "position")
} else {
  plot_data_2_6a <- positional_stats %>%
    mutate(padj = NA, significance = "ns")
}

# Maximum y value for significance markers
y_max <- max(plot_data_2_6a$CI_upper, na.rm = TRUE) * 1.1

fig_2_6a <- ggplot(plot_data_2_6a, aes(x = position, y = Mean_VAF, 
                                        color = Group, fill = Group)) +
  # Seed region background
  annotate("rect", xmin = 2, xmax = 8, ymin = -Inf, ymax = Inf, 
           fill = COLOR_SEED, alpha = 0.3) +
  
  # Confidence intervals (ribbons)
  geom_ribbon(aes(ymin = CI_lower, ymax = CI_upper), 
              alpha = 0.2, color = NA) +
  
  # Lines and points
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5, shape = 21, fill = "white", stroke = 1.5) +
  
  # Seed region markers
  geom_vline(xintercept = c(2, 8), linetype = "dashed", 
             color = COLOR_SEED_LINE, linewidth = 0.8) +
  
  # Statistical significance markers
  geom_text(data = plot_data_2_6a %>% filter(significance != "ns") %>%
              group_by(position) %>% slice(1),
            aes(x = position, y = y_max, label = significance),
            color = "black", size = 5, inherit.aes = FALSE) +
  
  # Scales and labels
  scale_x_continuous(breaks = c(1, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22)) +
  scale_color_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  
  labs(
    title = "A. G>T VAF by Position (Mean ± 95% CI)",
    subtitle = sprintf("Wilcoxon test per position, FDR correction (n_ALS=%d, n_Control=%d)",
                      max(plot_data_2_6a$n_ALS, na.rm = TRUE),
                      max(plot_data_2_6a$n_Control, na.rm = TRUE)),
    x = "Position in miRNA",
    y = "Mean VAF",
    caption = "Shaded region = seed (positions 2-8). * p<0.05, ** p<0.01, *** p<0.001 (FDR-adjusted)"
  ) +
  
  theme_professional +
  theme(legend.title = element_blank())

ggsave(file.path(output_dir, "FIG_2.6A_POSITIONAL_LINE_CI.png"),
       plot = fig_2_6a, width = 12, height = 7, dpi = 300)

cat("✅ Figure 2.6A saved\n\n")

# ============================================================================
# FIGURE 2.6B: DIFFERENTIAL PLOT (CONTROL - ALS)
# ============================================================================

cat("📊 Creating Figure 2.6B: Differential plot...\n")

# Calculate differential
differential_data <- positional_stats %>%
  select(position, Group, Mean_VAF, SE_VAF) %>%
  pivot_wider(names_from = Group, 
              values_from = c(Mean_VAF, SE_VAF)) %>%
  mutate(
    Difference = Mean_VAF_Control - Mean_VAF_ALS,
    SE_combined = sqrt(SE_VAF_Control^2 + SE_VAF_ALS^2),
    CI_lower = Difference - 1.96 * SE_combined,
    CI_upper = Difference + 1.96 * SE_combined
  ) %>%
  left_join(position_tests %>% select(position, padj, significance), 
            by = "position")

fig_2_6b <- ggplot(differential_data, aes(x = position, y = Difference)) +
  # Seed region background
  annotate("rect", xmin = 2, xmax = 8, ymin = -Inf, ymax = Inf, 
           fill = COLOR_SEED, alpha = 0.3) +
  
  # Zero line
  geom_hline(yintercept = 0, linetype = "solid", color = "gray50") +
  
  # CI ribbon
  geom_ribbon(aes(ymin = CI_lower, ymax = CI_upper), 
              alpha = 0.3, fill = "gray60") +
  
  # Line and points
  geom_line(color = "gray20", linewidth = 1.2) +
  geom_point(aes(color = significance), size = 3, shape = 16) +
  
  # Seed markers
  geom_vline(xintercept = c(2, 8), linetype = "dashed", 
             color = COLOR_SEED_LINE, linewidth = 0.8) +
  
  # Color by significance
  scale_color_manual(
    values = c("***" = "#d32f2f", "**" = "#f57c00", 
               "*" = "#fbc02d", "ns" = "gray60"),
    name = "Significance",
    breaks = c("***", "**", "*", "ns")
  ) +
  
  scale_x_continuous(breaks = c(1, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22)) +
  
  labs(
    title = "B. Differential G>T Burden (Control - ALS)",
    subtitle = "Mean difference with 95% confidence intervals",
    x = "Position in miRNA",
    y = "Difference in Mean VAF\n(Control - ALS)",
    caption = "Positive values = Control > ALS. Points colored by FDR-adjusted significance."
  ) +
  
  theme_professional

ggsave(file.path(output_dir, "FIG_2.6B_DIFFERENTIAL_PLOT.png"),
       plot = fig_2_6b, width = 12, height = 7, dpi = 300)

cat("✅ Figure 2.6B saved\n\n")

# ============================================================================
# FIGURE 2.6C: SEED VS NON-SEED COMPARISON (RECOMMENDED!)
# ============================================================================

cat("📊 Creating Figure 2.6C: Seed vs Non-seed comparison...\n")

# Classify positions
vaf_per_sample_regions <- vaf_per_sample %>%
  mutate(Region = case_when(
    position >= 2 & position <= 8 ~ "Seed (2-8)",
    position == 1 ~ "Terminal 5'",
    position >= 9 ~ "Non-seed (9-22)"
  ))

# Statistical comparison
comparison_list <- list(c("Seed (2-8)", "Non-seed (9-22)"))

fig_2_6c <- ggplot(vaf_per_sample_regions %>% filter(Region != "Terminal 5'"),
                   aes(x = Group, y = Total_VAF, fill = Group)) +
  
  geom_boxplot(alpha = 0.7, outlier.alpha = 0.3) +
  geom_violin(alpha = 0.3, draw_quantiles = c(0.25, 0.5, 0.75)) +
  
  stat_compare_means(method = "wilcox.test", 
                     label = "p.format",
                     label.x = 1.5,
                     label.y.npc = 0.95,
                     size = 5) +
  
  facet_wrap(~Region, scales = "free_y") +
  
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  
  labs(
    title = "C. G>T Burden: Seed vs Non-Seed Regions",
    subtitle = "Direct test of seed region specificity hypothesis",
    x = "Group",
    y = "Total VAF per sample",
    caption = "Wilcoxon rank-sum test. Excludes position 1 (terminal artifact)."
  ) +
  
  theme_professional +
  theme(legend.position = "none")

ggsave(file.path(output_dir, "FIG_2.6C_SEED_VS_NONSEED.png"),
       plot = fig_2_6c, width = 12, height = 7, dpi = 300)

cat("✅ Figure 2.6C saved\n\n")

# ============================================================================
# FIGURE 2.6D: COMBINED PANEL
# ============================================================================

cat("📊 Creating Figure 2.6D: Combined figure...\n")

fig_2_6_combined <- (fig_2_6a / fig_2_6b) + 
  plot_annotation(
    title = "Figure 2.6: Positional Analysis of G>T Burden",
    subtitle = "Comprehensive positional profiling with statistical testing",
    theme = theme(plot.title = element_text(face = "bold", size = 16))
  )

ggsave(file.path(output_dir, "FIG_2.6_COMBINED_AB.png"),
       plot = fig_2_6_combined, width = 14, height = 12, dpi = 300)

cat("✅ Figure 2.6 Combined saved\n\n")

# ============================================================================
# SAVE STATISTICAL RESULTS
# ============================================================================

cat("💾 Saving statistical results...\n")

# Position-level statistics
write.csv(position_tests, 
          file.path(output_dir, "FIG_2.6_position_statistics.csv"),
          row.names = FALSE)

# Region-level statistics
region_stats <- vaf_per_sample_regions %>%
  filter(Region != "Terminal 5'") %>%
  group_by(Region, Group) %>%
  summarise(
    Mean = mean(Total_VAF),
    Median = median(Total_VAF),
    SD = sd(Total_VAF),
    SE = sd(Total_VAF) / sqrt(n()),
    N = n(),
    .groups = "drop"
  )

write.csv(region_stats,
          file.path(output_dir, "FIG_2.6_region_statistics.csv"),
          row.names = FALSE)

cat("✅ Statistical results saved\n\n")

# ============================================================================
# SUMMARY REPORT
# ============================================================================

cat("\n")
cat(paste(rep("=", 70), collapse = ""), "\n")
cat("📊 FIGURE 2.6 GENERATION COMPLETE\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

cat("Generated figures:\n")
cat("  • FIG_2.6A_POSITIONAL_LINE_CI.png     - Line plot with 95% CI\n")
cat("  • FIG_2.6B_DIFFERENTIAL_PLOT.png      - Differential (Control-ALS)\n")
cat("  • FIG_2.6C_SEED_VS_NONSEED.png        - Seed vs Non-seed comparison\n")
cat("  • FIG_2.6_COMBINED_AB.png             - Combined panels A+B\n\n")

cat("Statistical results:\n")
cat(sprintf("  • Significant positions (FDR < 0.05): %d / 22\n",
            sum(position_tests$padj < 0.05, na.rm = TRUE)))
cat(sprintf("  • Mean difference (Control - ALS): %.6f\n",
            mean(differential_data$Difference, na.rm = TRUE)))
cat(sprintf("  • Positions with Control > ALS: %d\n",
            sum(differential_data$Difference > 0, na.rm = TRUE)))
cat(sprintf("  • Positions with ALS > Control: %d\n",
            sum(differential_data$Difference < 0, na.rm = TRUE)))

cat("\n")
cat("Key findings:\n")

# Check if seed is elevated
seed_vs_nonseed_test <- wilcox.test(
  vaf_per_sample_regions %>% filter(Region == "Seed (2-8)", Group == "ALS") %>% pull(Total_VAF),
  vaf_per_sample_regions %>% filter(Region == "Non-seed (9-22)", Group == "ALS") %>% pull(Total_VAF)
)

if (seed_vs_nonseed_test$p.value < 0.05) {
  cat("  ✓ Seed region shows significant difference from non-seed (p < 0.05)\n")
} else {
  cat("  ✗ NO significant difference between seed and non-seed (p = ", 
      sprintf("%.3f", seed_vs_nonseed_test$p.value), ")\n", sep = "")
}

# Check overall pattern
if (all(differential_data$Difference > 0, na.rm = TRUE)) {
  cat("  ✓ Control > ALS at ALL positions (uniform pattern)\n")
} else if (all(differential_data$Difference < 0, na.rm = TRUE)) {
  cat("  ✓ ALS > Control at ALL positions (uniform pattern)\n")
} else {
  cat("  ⚠ Mixed pattern (Control > ALS at some positions, ALS > Control at others)\n")
}

cat("\n")
cat(paste(rep("=", 70), collapse = ""), "\n")
cat("✅ ALL FIGURES SAVED TO:", output_dir, "\n")
cat(paste(rep("=", 70), collapse = ""), "\n")

