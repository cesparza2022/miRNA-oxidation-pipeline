#!/usr/bin/env Rscript
# ==============================================================================
# FIGURE 2.6 CORRECTED: POSITIONAL G>T BURDEN ANALYSIS
# ==============================================================================
# Date: 2025-10-27
# Purpose: Create positional analysis with proper statistics
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
output_dir <- "figures_paso2_CLEAN"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# Colors
COLOR_ALS <- "#d32f2f"
COLOR_CONTROL <- "#1976d2"
COLOR_SEED <- "#bbdefb"

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

cat("📂 Loading data...\n")

# ============================================================================
# LOAD DATA
# ============================================================================

data <- read.csv(input_file, check.names = FALSE)
sample_cols <- names(data)[3:ncol(data)]

# Filter G>T only
vaf_gt <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^\\d+"))) %>%
  filter(!is.na(position), position <= 22)

cat(sprintf("✅ Loaded %d G>T SNVs\n\n", nrow(vaf_gt)))

# ============================================================================
# TRANSFORM TO LONG FORMAT
# ============================================================================

cat("📊 Transforming data...\n")

vaf_long <- vaf_gt %>%
  select(miRNA_name, position, all_of(sample_cols)) %>%
  pivot_longer(cols = all_of(sample_cols), 
               names_to = "Sample_ID", 
               values_to = "VAF") %>%
  filter(!is.na(VAF))

# Add metadata (CORRECTED pattern matching)
metadata <- data.frame(
  Sample_ID = sample_cols,
  Group = ifelse(grepl("\\.ALS\\.", sample_cols), "ALS", "Control"),
  stringsAsFactors = FALSE
)

vaf_long <- vaf_long %>%
  left_join(metadata, by = "Sample_ID")

cat(sprintf("✅ Data transformed: %d observations\n\n", nrow(vaf_long)))

# ============================================================================
# AGGREGATE PER SAMPLE FIRST (CORRECT METHOD)
# ============================================================================

cat("📊 Calculating per-sample statistics...\n")

vaf_per_sample <- vaf_long %>%
  group_by(Sample_ID, position, Group) %>%
  summarise(Total_VAF = sum(VAF, na.rm = TRUE),
            N_SNVs = n(),
            .groups = "drop")

cat(sprintf("✅ Per-sample aggregation complete\n\n"))

# ============================================================================
# CALCULATE POSITIONAL STATS
# ============================================================================

cat("📊 Calculating positional statistics...\n")

positional_stats <- vaf_per_sample %>%
  group_by(position, Group) %>%
  summarise(
    Mean_VAF = mean(Total_VAF, na.rm = TRUE),
    Median_VAF = median(Total_VAF, na.rm = TRUE),
    SD_VAF = sd(Total_VAF, na.rm = TRUE),
    SE_VAF = sd(Total_VAF, na.rm = TRUE) / sqrt(n()),
    N_samples = n(),
    .groups = "drop"
  ) %>%
  mutate(
    CI_lower = Mean_VAF - 1.96 * SE_VAF,
    CI_upper = Mean_VAF + 1.96 * SE_VAF
  )

cat("✅ Positional stats calculated\n\n")

# ============================================================================
# STATISTICAL TESTS
# ============================================================================

cat("🔬 Performing Wilcoxon tests per position...\n")

position_tests <- list()

for (pos in sort(unique(positional_stats$position))) {
  pos_data <- vaf_per_sample %>% filter(position == pos)
  
  als_vals <- pos_data %>% filter(Group == "ALS") %>% pull(Total_VAF)
  ctrl_vals <- pos_data %>% filter(Group == "Control") %>% pull(Total_VAF)
  
  if (length(als_vals) >= 5 && length(ctrl_vals) >= 5) {
    test_result <- tryCatch({
      wilcox.test(ctrl_vals, als_vals)
    }, error = function(e) {
      list(p.value = 1)
    })
    
    position_tests[[as.character(pos)]] <- data.frame(
      position = pos,
      pvalue = test_result$p.value,
      mean_ALS = mean(als_vals, na.rm = TRUE),
      mean_Control = mean(ctrl_vals, na.rm = TRUE),
      n_ALS = length(als_vals),
      n_Control = length(ctrl_vals)
    )
  }
}

position_tests_df <- bind_rows(position_tests)

if (nrow(position_tests_df) > 0) {
  position_tests_df$padj <- p.adjust(position_tests_df$pvalue, method = "fdr")
  position_tests_df$difference <- position_tests_df$mean_Control - position_tests_df$mean_ALS
  
  position_tests_df$significance <- case_when(
    position_tests_df$padj < 0.001 ~ "***",
    position_tests_df$padj < 0.01 ~ "**",
    position_tests_df$padj < 0.05 ~ "*",
    TRUE ~ "ns"
  )
  
  cat(sprintf("✅ Tests completed: %d positions tested\n", nrow(position_tests_df)))
  cat(sprintf("   Significant (FDR < 0.05): %d positions\n\n",
              sum(position_tests_df$padj < 0.05)))
} else {
  cat("⚠️ No tests performed\n\n")
}

# ============================================================================
# FIGURE 2.6A: LINE PLOT WITH CI
# ============================================================================

cat("📊 Creating Figure 2.6A: Line plot with 95% CI...\n")

# Merge stats with tests
if (nrow(position_tests_df) > 0) {
  plot_data <- positional_stats %>%
    left_join(position_tests_df, by = "position")
} else {
  plot_data <- positional_stats %>%
    mutate(padj = NA, significance = "ns")
}

# Get max for significance markers
y_max <- max(plot_data$CI_upper, na.rm = TRUE) * 1.05

fig_2_6a <- ggplot(plot_data, aes(x = position, y = Mean_VAF, 
                                   color = Group, fill = Group)) +
  # Seed region background
  annotate("rect", xmin = 2, xmax = 8, ymin = -Inf, ymax = Inf, 
           fill = COLOR_SEED, alpha = 0.3) +
  
  # CI ribbons
  geom_ribbon(aes(ymin = CI_lower, ymax = CI_upper), 
              alpha = 0.2, color = NA) +
  
  # Lines and points
  geom_line(linewidth = 1.3) +
  geom_point(size = 3, shape = 21, fill = "white", stroke = 1.2) +
  
  # Seed markers
  geom_vline(xintercept = c(2, 8), linetype = "dashed", 
             color = "#1565c0", linewidth = 0.7) +
  
  # Significance markers (if any)
  {if(nrow(position_tests_df) > 0 && sum(position_tests_df$padj < 0.05, na.rm=TRUE) > 0)
    geom_text(data = plot_data %>% 
                filter(!is.na(significance), significance != "ns") %>%
                group_by(position) %>% slice(1),
              aes(x = position, y = y_max, label = significance),
              color = "black", size = 6, inherit.aes = FALSE)
  } +
  
  scale_x_continuous(breaks = seq(1, 22, by = 2)) +
  scale_color_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  
  labs(
    title = "A. G>T VAF by Position (Mean ± 95% CI)",
    subtitle = "Wilcoxon test per position with FDR correction",
    x = "Position in miRNA",
    y = "Mean VAF (per sample)",
    caption = "Shaded = seed region (2-8). * p<0.05, ** p<0.01, *** p<0.001 (FDR-adj)"
  ) +
  
  theme_professional +
  theme(legend.title = element_blank())

ggsave(file.path(output_dir, "FIG_2.6A_LINE_CI_IMPROVED.png"),
       plot = fig_2_6a, width = 14, height = 8, dpi = 300)

cat("✅ Figure 2.6A saved\n\n")

# ============================================================================
# FIGURE 2.6B: DIFFERENTIAL PLOT
# ============================================================================

cat("📊 Creating Figure 2.6B: Differential plot...\n")

# Calculate differential
als_stats <- positional_stats %>% filter(Group == "ALS") %>%
  select(position, Mean_ALS = Mean_VAF, SE_ALS = SE_VAF)

ctrl_stats <- positional_stats %>% filter(Group == "Control") %>%
  select(position, Mean_Control = Mean_VAF, SE_Control = SE_VAF)

differential_data <- als_stats %>%
  full_join(ctrl_stats, by = "position") %>%
  mutate(
    Difference = Mean_Control - Mean_ALS,
    SE_combined = sqrt(SE_Control^2 + SE_ALS^2),
    CI_lower = Difference - 1.96 * SE_combined,
    CI_upper = Difference + 1.96 * SE_combined
  )

if (nrow(position_tests_df) > 0) {
  differential_data <- differential_data %>%
    left_join(position_tests_df %>% select(position, padj, significance), 
              by = "position")
} else {
  differential_data$significance <- "ns"
}

fig_2_6b <- ggplot(differential_data, aes(x = position, y = Difference)) +
  annotate("rect", xmin = 2, xmax = 8, ymin = -Inf, ymax = Inf, 
           fill = COLOR_SEED, alpha = 0.3) +
  geom_hline(yintercept = 0, linetype = "solid", color = "gray40", linewidth = 0.8) +
  geom_ribbon(aes(ymin = CI_lower, ymax = CI_upper), 
              alpha = 0.25, fill = "gray50") +
  geom_line(color = "gray20", linewidth = 1.3) +
  geom_point(aes(color = significance), size = 3.5, shape = 16) +
  geom_vline(xintercept = c(2, 8), linetype = "dashed", 
             color = "#1565c0", linewidth = 0.7) +
  scale_color_manual(
    values = c("***" = "#d32f2f", "**" = "#f57c00", 
               "*" = "#fbc02d", "ns" = "gray60"),
    name = "Significance (FDR-adj)"
  ) +
  scale_x_continuous(breaks = seq(1, 22, by = 2)) +
  labs(
    title = "B. Differential G>T Burden (Control - ALS)",
    subtitle = "Mean difference with 95% confidence intervals",
    x = "Position in miRNA",
    y = "Difference in Mean VAF\n(Control - ALS)",
    caption = "Positive = Control > ALS. CI crossing zero = not significant."
  ) +
  theme_professional

ggsave(file.path(output_dir, "FIG_2.6B_DIFFERENTIAL_IMPROVED.png"),
       plot = fig_2_6b, width = 14, height = 8, dpi = 300)

cat("✅ Figure 2.6B saved\n\n")

# ============================================================================
# FIGURE 2.6C: SEED VS NON-SEED (RECOMMENDED!)
# ============================================================================

cat("📊 Creating Figure 2.6C: Seed vs Non-seed comparison...\n")

vaf_regions <- vaf_per_sample %>%
  mutate(Region = case_when(
    position >= 2 & position <= 8 ~ "Seed (2-8)",
    position == 1 ~ "5' Terminal",
    TRUE ~ "Non-seed (9-22)"
  ))

# Filter out terminal position
vaf_regions_main <- vaf_regions %>%
  filter(Region != "5' Terminal")

fig_2_6c <- ggplot(vaf_regions_main, 
                   aes(x = Group, y = Total_VAF, fill = Group)) +
  geom_violin(alpha = 0.4, draw_quantiles = c(0.25, 0.5, 0.75)) +
  geom_boxplot(width = 0.3, alpha = 0.8, outlier.alpha = 0.4) +
  stat_compare_means(method = "wilcox.test", 
                     label = "p.format",
                     size = 5.5,
                     label.x = 1.5,
                     label.y.npc = 0.92) +
  facet_wrap(~Region, scales = "free_y") +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  labs(
    title = "C. G>T Burden: Seed vs Non-Seed Regions",
    subtitle = "Direct test of positional specificity (excludes position 1)",
    x = "Group",
    y = "Total G>T VAF per sample",
    caption = "Wilcoxon rank-sum test. Violin shows distribution, box shows quartiles."
  ) +
  theme_professional +
  theme(legend.position = "none",
        strip.text = element_text(face = "bold", size = 12))

ggsave(file.path(output_dir, "FIG_2.6C_SEED_VS_NONSEED_IMPROVED.png"),
       plot = fig_2_6c, width = 13, height = 7, dpi = 300)

cat("✅ Figure 2.6C saved\n\n")

# ============================================================================
# FIGURE 2.6D: COMBINED
# ============================================================================

cat("📊 Creating combined figure...\n")

fig_2_6_combined <- (fig_2_6a / fig_2_6b) + 
  plot_annotation(
    title = "Figure 2.6: Positional Analysis of G>T Burden (Improved)",
    theme = theme(plot.title = element_text(face = "bold", size = 16))
  )

ggsave(file.path(output_dir, "FIG_2.6_COMBINED_IMPROVED.png"),
       plot = fig_2_6_combined, width = 15, height = 14, dpi = 300)

cat("✅ Combined figure saved\n\n")

# ============================================================================
# SAVE STATISTICS
# ============================================================================

cat("💾 Saving statistical results...\n")

if (nrow(position_tests_df) > 0) {
  write.csv(position_tests_df, 
            file.path(output_dir, "TABLE_2.6_position_tests.csv"),
            row.names = FALSE)
  cat("✅ Position tests saved\n")
}

# Region statistics
region_stats <- vaf_regions_main %>%
  group_by(Region, Group) %>%
  summarise(
    N_samples = n(),
    Mean_VAF = mean(Total_VAF, na.rm = TRUE),
    Median_VAF = median(Total_VAF, na.rm = TRUE),
    SD_VAF = sd(Total_VAF, na.rm = TRUE),
    SE_VAF = sd(Total_VAF, na.rm = TRUE) / sqrt(n()),
    .groups = "drop"
  )

write.csv(region_stats,
          file.path(output_dir, "TABLE_2.6_region_stats.csv"),
          row.names = FALSE)

cat("✅ Region stats saved\n\n")

# ============================================================================
# SEED VS NON-SEED TESTS (BY GROUP)
# ============================================================================

cat("🔬 Testing Seed vs Non-seed within each group...\n")

seed_vs_nonseed_results <- data.frame()

for (grp in c("ALS", "Control")) {
  seed_vals <- vaf_regions_main %>% 
    filter(Region == "Seed (2-8)", Group == grp) %>% 
    pull(Total_VAF)
  
  nonseed_vals <- vaf_regions_main %>% 
    filter(Region == "Non-seed (9-22)", Group == grp) %>% 
    pull(Total_VAF)
  
  if (length(seed_vals) > 0 && length(nonseed_vals) > 0) {
    test <- wilcox.test(seed_vals, nonseed_vals)
    
    seed_vs_nonseed_results <- rbind(seed_vs_nonseed_results, data.frame(
      Group = grp,
      Seed_mean = mean(seed_vals, na.rm = TRUE),
      NonSeed_mean = mean(nonseed_vals, na.rm = TRUE),
      Difference = mean(seed_vals, na.rm = TRUE) - mean(nonseed_vals, na.rm = TRUE),
      pvalue = test$p.value
    ))
  }
}

write.csv(seed_vs_nonseed_results,
          file.path(output_dir, "TABLE_2.6_seed_vs_nonseed_tests.csv"),
          row.names = FALSE)

cat("✅ Seed vs non-seed tests saved\n\n")

# ============================================================================
# SUMMARY REPORT
# ============================================================================

cat("\n")
cat(paste(rep("=", 80), collapse = ""), "\n")
cat("📊 FIGURE 2.6 GENERATION COMPLETE\n")
cat(paste(rep("=", 80), collapse = ""), "\n\n")

cat("✅ Generated figures:\n")
cat("   • FIG_2.6A_LINE_CI_IMPROVED.png         - Line plot with 95% CI\n")
cat("   • FIG_2.6B_DIFFERENTIAL_IMPROVED.png    - Differential (Control-ALS)\n")
cat("   • FIG_2.6C_SEED_VS_NONSEED_IMPROVED.png - Seed vs Non-seed ⭐ RECOMMENDED\n")
cat("   • FIG_2.6_COMBINED_IMPROVED.png         - Combined panels A+B\n\n")

cat("✅ Statistical tables:\n")
if (nrow(position_tests_df) > 0) {
  cat(sprintf("   • TABLE_2.6_position_tests.csv (%d positions)\n", nrow(position_tests_df)))
}
cat("   • TABLE_2.6_region_stats.csv\n")
cat("   • TABLE_2.6_seed_vs_nonseed_tests.csv\n\n")

cat("📊 Key Results:\n")
if (nrow(position_tests_df) > 0) {
  n_sig <- sum(position_tests_df$padj < 0.05, na.rm = TRUE)
  cat(sprintf("   • Significant positions (FDR < 0.05): %d / %d\n", 
              n_sig, nrow(position_tests_df)))
}

cat(sprintf("   • Overall mean difference (Control - ALS): %.6f\n",
            mean(position_tests_df$difference, na.rm = TRUE)))

if (nrow(seed_vs_nonseed_results) > 0) {
  cat("\n   Seed vs Non-seed tests:\n")
  for (i in 1:nrow(seed_vs_nonseed_results)) {
    row <- seed_vs_nonseed_results[i,]
    cat(sprintf("   • %s: Seed=%.5f, Non-seed=%.5f, p=%.4f\n",
                row$Group, row$Seed_mean, row$NonSeed_mean, row$pvalue))
  }
}

cat("\n")
cat(paste(rep("=", 80), collapse = ""), "\n")
cat("✅ ALL FILES SAVED TO:", output_dir, "\n")
cat(paste(rep("=", 80), collapse = ""), "\n\n")

