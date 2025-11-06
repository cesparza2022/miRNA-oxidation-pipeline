#!/usr/bin/env Rscript
# ==============================================================================
# FIGURE 2.9 IMPROVED: COEFFICIENT OF VARIATION ANALYSIS
# ==============================================================================
# Date: 2025-10-27
# Purpose: Analyze heterogeneity within groups using CV
# Improvements:
#   1. Proper CV calculation with filtering
#   2. Multiple statistical tests (F-test, Levene's)
#   3. Correlation analysis (CV vs Mean)
#   4. Top variable miRNAs identified
#   5. Visual comparison enhanced
#   6. Complete statistical output
# ==============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggpubr)
  library(patchwork)
  library(car)  # For Levene's test
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
cat("📊 FIGURE 2.9 CV - IMPROVED VERSION\n")
cat(paste(rep("=", 80), collapse = ""), "\n\n")

# ============================================================================
# LOAD DATA
# ============================================================================

cat("📂 Loading data...\n")

data <- read.csv(input_file, check.names = FALSE)
metadata <- read.csv(metadata_file)
sample_cols <- metadata$Sample_ID

# Filter G>T
vaf_gt <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  select(all_of(c("miRNA_name", "pos.mut", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), 
               names_to = "Sample_ID", 
               values_to = "VAF") %>%
  left_join(metadata, by = "Sample_ID") %>%
  filter(!is.na(VAF))

cat(sprintf("✅ Loaded: %d G>T observations\n\n", nrow(vaf_gt)))

# ============================================================================
# CALCULATE CV PER miRNA PER GROUP
# ============================================================================

cat("📊 Calculating Coefficient of Variation...\n")

# Calculate Mean, SD, and CV per miRNA per group
cv_data <- vaf_gt %>%
  group_by(miRNA_name, Group) %>%
  summarise(
    N_samples = n(),
    Mean_VAF = mean(VAF, na.rm = TRUE),
    Median_VAF = median(VAF, na.rm = TRUE),
    SD_VAF = sd(VAF, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    CV = (SD_VAF / Mean_VAF) * 100,
    CV_log = log10(CV + 1)
  )

# Filter invalid CV values
cat(sprintf("   Before filtering: %d observations\n", nrow(cv_data)))

cv_data_clean <- cv_data %>%
  filter(!is.infinite(CV), 
         !is.nan(CV), 
         Mean_VAF > 0.0001,  # Filter very low means
         N_samples >= 5)     # Require minimum sample size

cat(sprintf("   After filtering: %d observations\n", nrow(cv_data_clean)))
cat(sprintf("   Removed: %d (infinite/NA/low mean/low N)\n\n", 
            nrow(cv_data) - nrow(cv_data_clean)))

# ============================================================================
# SUMMARY STATISTICS
# ============================================================================

cat("📊 Calculating summary statistics...\n")

cv_summary <- cv_data_clean %>%
  group_by(Group) %>%
  summarise(
    N_miRNAs = n(),
    Mean_CV = mean(CV, na.rm = TRUE),
    Median_CV = median(CV, na.rm = TRUE),
    SD_CV = sd(CV, na.rm = TRUE),
    SE_CV = sd(CV, na.rm = TRUE) / sqrt(n()),
    Q25_CV = quantile(CV, 0.25, na.rm = TRUE),
    Q75_CV = quantile(CV, 0.75, na.rm = TRUE),
    Min_CV = min(CV, na.rm = TRUE),
    Max_CV = max(CV, na.rm = TRUE),
    .groups = "drop"
  )

cat("✅ Summary statistics:\n")
print(cv_summary)
cat("\n")

# ============================================================================
# STATISTICAL TESTS
# ============================================================================

cat("🔬 Performing statistical tests...\n")

# Test 1: F-test (variance equality)
f_test <- var.test(CV ~ Group, data = cv_data_clean)

# Test 2: Levene's test (more robust)
levene_test <- leveneTest(CV ~ Group, data = cv_data_clean)

# Test 3: Wilcoxon (non-parametric median test)
wilcox_test <- wilcox.test(CV ~ Group, data = cv_data_clean)

cat("✅ Statistical tests completed:\n")
cat(sprintf("   F-test (variance):  F = %.2f, p = %s\n", 
            f_test$statistic, format.pval(f_test$p.value, digits = 3)))
cat(sprintf("   Levene's test:      F = %.2f, p = %s\n", 
            levene_test$`F value`[1], format.pval(levene_test$`Pr(>F)`[1], digits = 3)))
cat(sprintf("   Wilcoxon (median):  p = %s\n\n", 
            format.pval(wilcox_test$p.value, digits = 3)))

# ============================================================================
# CORRELATION ANALYSIS (CV vs MEAN)
# ============================================================================

cat("🔬 Analyzing CV vs Mean correlation...\n")

cv_mean_cor_als <- cor.test(
  cv_data_clean %>% filter(Group == "ALS") %>% pull(Mean_VAF),
  cv_data_clean %>% filter(Group == "ALS") %>% pull(CV)
)

cv_mean_cor_ctrl <- cor.test(
  cv_data_clean %>% filter(Group == "Control") %>% pull(Mean_VAF),
  cv_data_clean %>% filter(Group == "Control") %>% pull(CV)
)

cat(sprintf("   ALS:     r = %.3f, p = %s\n", 
            cv_mean_cor_als$estimate, format.pval(cv_mean_cor_als$p.value, digits = 3)))
cat(sprintf("   Control: r = %.3f, p = %s\n\n", 
            cv_mean_cor_ctrl$estimate, format.pval(cv_mean_cor_ctrl$p.value, digits = 3)))

# ============================================================================
# IDENTIFY TOP VARIABLE miRNAs
# ============================================================================

cat("🔬 Identifying most variable miRNAs...\n")

top_variable_als <- cv_data_clean %>%
  filter(Group == "ALS") %>%
  arrange(desc(CV)) %>%
  head(10)

top_variable_ctrl <- cv_data_clean %>%
  filter(Group == "Control") %>%
  arrange(desc(CV)) %>%
  head(10)

cat("   Top 5 variable miRNAs (ALS):\n")
cat(paste("     ", 1:5, ". ", head(top_variable_als$miRNA_name, 5), 
          " (CV = ", round(head(top_variable_als$CV, 5), 1), "%)", sep = "", collapse = "\n"), "\n\n")

cat("   Top 5 variable miRNAs (Control):\n")
cat(paste("     ", 1:5, ". ", head(top_variable_ctrl$miRNA_name, 5), 
          " (CV = ", round(head(top_variable_ctrl$CV, 5), 1), "%)", sep = "", collapse = "\n"), "\n\n")

# ============================================================================
# FIGURE 2.9A: BARPLOT WITH ERROR BARS
# ============================================================================

cat("📊 Creating Figure 2.9A: Mean CV comparison...\n")

fig_2_9a <- ggplot(cv_summary, aes(x = Group, y = Mean_CV, fill = Group)) +
  geom_col(width = 0.6, alpha = 0.8) +
  geom_errorbar(aes(ymin = Mean_CV - SE_CV, ymax = Mean_CV + SE_CV), 
                width = 0.2, linewidth = 1) +
  
  # Add significance annotation
  annotate("text", x = 1.5, y = max(cv_summary$Mean_CV + cv_summary$SE_CV) * 1.1,
           label = ifelse(f_test$p.value < 0.001, "***",
                         ifelse(f_test$p.value < 0.01, "**",
                               ifelse(f_test$p.value < 0.05, "*", "ns"))),
           size = 10, color = "black") +
  
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  
  labs(
    title = "A. Mean Coefficient of Variation (CV)",
    subtitle = sprintf("F-test: p = %s | Levene's test: p = %s",
                      format.pval(f_test$p.value, digits = 3),
                      format.pval(levene_test$`Pr(>F)`[1], digits = 3)),
    x = "Group",
    y = "Mean CV (%)",
    caption = sprintf("ALS: n=%d miRNAs | Control: n=%d miRNAs",
                     sum(cv_data_clean$Group == "ALS"),
                     sum(cv_data_clean$Group == "Control"))
  ) +
  
  theme_professional +
  theme(legend.position = "none")

ggsave(file.path(output_dir, "FIG_2.9A_MEAN_CV.png"),
       plot = fig_2_9a, width = 8, height = 7, dpi = 300)

cat("✅ Figure 2.9A saved\n\n")

# ============================================================================
# FIGURE 2.9B: CV DISTRIBUTIONS (BOXPLOT + VIOLIN)
# ============================================================================

cat("📊 Creating Figure 2.9B: CV distributions...\n")

fig_2_9b <- ggplot(cv_data_clean, aes(x = Group, y = CV, fill = Group)) +
  
  # Violin plot (distribution shape)
  geom_violin(alpha = 0.4, trim = FALSE, scale = "width") +
  
  # Boxplot overlay
  geom_boxplot(width = 0.2, alpha = 0.8, outlier.size = 2, outlier.alpha = 0.5) +
  
  # Add mean point
  stat_summary(fun = mean, geom = "point", shape = 23, size = 4, 
               fill = "yellow", color = "black", stroke = 1.2) +
  
  # Limits (remove top 5% outliers for clarity)
  coord_cartesian(ylim = c(0, quantile(cv_data_clean$CV, 0.95, na.rm = TRUE))) +
  
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  
  labs(
    title = "B. CV Distribution Across miRNAs",
    subtitle = sprintf("Wilcoxon test (median): p = %s",
                      format.pval(wilcox_test$p.value, digits = 3)),
    x = "Group",
    y = "Coefficient of Variation (%)",
    caption = "Yellow diamond = mean. Violin shows distribution shape. Box = IQR. Top 5% outliers not shown."
  ) +
  
  theme_professional +
  theme(legend.position = "none")

ggsave(file.path(output_dir, "FIG_2.9B_CV_DISTRIBUTION.png"),
       plot = fig_2_9b, width = 9, height = 7, dpi = 300)

cat("✅ Figure 2.9B saved\n\n")

# ============================================================================
# FIGURE 2.9C: CV vs MEAN (CORRELATION)
# ============================================================================

cat("📊 Creating Figure 2.9C: CV vs Mean correlation...\n")

fig_2_9c <- ggplot(cv_data_clean, aes(x = Mean_VAF, y = CV, color = Group)) +
  
  # Points
  geom_point(alpha = 0.6, size = 2.5) +
  
  # Smoothed fit lines
  geom_smooth(method = "lm", se = TRUE, alpha = 0.2, linewidth = 1.2) +
  
  # Log scale for x (VAF is log-distributed)
  scale_x_log10(labels = scales::comma) +
  
  scale_color_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  
  labs(
    title = "C. CV vs Mean VAF",
    subtitle = sprintf("ALS: r = %.3f, p = %s | Control: r = %.3f, p = %s",
                      cv_mean_cor_als$estimate, format.pval(cv_mean_cor_als$p.value, digits = 3),
                      cv_mean_cor_ctrl$estimate, format.pval(cv_mean_cor_ctrl$p.value, digits = 3)),
    x = "Mean VAF (log scale)",
    y = "Coefficient of Variation (%)",
    caption = "Linear fit shown. Positive correlation = higher-burden miRNAs are more variable."
  ) +
  
  theme_professional

ggsave(file.path(output_dir, "FIG_2.9C_CV_VS_MEAN.png"),
       plot = fig_2_9c, width = 11, height = 7, dpi = 300)

cat("✅ Figure 2.9C saved\n\n")

# ============================================================================
# FIGURE 2.9D: TOP VARIABLE miRNAs
# ============================================================================

cat("📊 Creating Figure 2.9D: Top variable miRNAs...\n")

# Combine top 10 from each group
top_variable_combined <- bind_rows(
  top_variable_als %>% mutate(Rank = "ALS_Top10"),
  top_variable_ctrl %>% mutate(Rank = "Control_Top10")
) %>%
  arrange(desc(CV))

fig_2_9d <- ggplot(head(top_variable_combined, 20), 
                   aes(x = reorder(miRNA_name, CV), y = CV, fill = Group)) +
  geom_col(alpha = 0.8) +
  coord_flip() +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  labs(
    title = "D. Top 20 Most Variable miRNAs",
    subtitle = "Highest CV values across both groups",
    x = "miRNA",
    y = "CV (%)"
  ) +
  theme_professional

ggsave(file.path(output_dir, "FIG_2.9D_TOP_VARIABLE.png"),
       plot = fig_2_9d, width = 10, height = 8, dpi = 300)

cat("✅ Figure 2.9D saved\n\n")

# ============================================================================
# FIGURE 2.9_COMBINED: PUBLICATION VERSION
# ============================================================================

cat("📊 Creating combined figure...\n")

fig_2_9_combined <- (fig_2_9a | fig_2_9b) / fig_2_9c +
  plot_annotation(
    title = "Figure 2.9: Coefficient of Variation Analysis",
    subtitle = "Quantifying heterogeneity in G>T burden within groups",
    theme = theme(plot.title = element_text(face = "bold", size = 16))
  )

ggsave(file.path(output_dir, "FIG_2.9_COMBINED_IMPROVED.png"),
       plot = fig_2_9_combined, width = 16, height = 12, dpi = 300)

cat("✅ Combined figure saved\n\n")

# ============================================================================
# SAVE STATISTICAL RESULTS
# ============================================================================

cat("💾 Saving statistical results...\n")

# 1. Summary statistics
write.csv(cv_summary,
          file.path(output_dir, "TABLE_2.9_CV_summary.csv"),
          row.names = FALSE)

# 2. All CV values
write.csv(cv_data_clean,
          file.path(output_dir, "TABLE_2.9_CV_all_miRNAs.csv"),
          row.names = FALSE)

# 3. Statistical tests
test_results <- data.frame(
  Test = c("F-test (variance)", "Levene's test", "Wilcoxon (median)"),
  Statistic = c(f_test$statistic, levene_test$`F value`[1], wilcox_test$statistic),
  Pvalue = c(f_test$p.value, levene_test$`Pr(>F)`[1], wilcox_test$p.value),
  Interpretation = c(
    ifelse(f_test$p.value < 0.05, "Significant difference in variance", "No difference"),
    ifelse(levene_test$`Pr(>F)`[1] < 0.05, "Significant difference (robust)", "No difference"),
    ifelse(wilcox_test$p.value < 0.05, "Significant difference in median CV", "No difference")
  )
)

write.csv(test_results,
          file.path(output_dir, "TABLE_2.9_statistical_tests.csv"),
          row.names = FALSE)

# 4. Top variable miRNAs
top_variable_table <- bind_rows(
  top_variable_als %>% select(Group, miRNA_name, Mean_VAF, SD_VAF, CV) %>% mutate(Rank_in_Group = 1:10),
  top_variable_ctrl %>% select(Group, miRNA_name, Mean_VAF, SD_VAF, CV) %>% mutate(Rank_in_Group = 1:10)
) %>%
  arrange(Group, Rank_in_Group)

write.csv(top_variable_table,
          file.path(output_dir, "TABLE_2.9_top_variable_miRNAs.csv"),
          row.names = FALSE)

# 5. Correlation results
correlation_results <- data.frame(
  Group = c("ALS", "Control"),
  Correlation = c(cv_mean_cor_als$estimate, cv_mean_cor_ctrl$estimate),
  Pvalue = c(cv_mean_cor_als$p.value, cv_mean_cor_ctrl$p.value),
  CI_lower = c(cv_mean_cor_als$conf.int[1], cv_mean_cor_ctrl$conf.int[1]),
  CI_upper = c(cv_mean_cor_als$conf.int[2], cv_mean_cor_ctrl$conf.int[2])
)

write.csv(correlation_results,
          file.path(output_dir, "TABLE_2.9_CV_Mean_correlations.csv"),
          row.names = FALSE)

cat("✅ All statistical results saved\n\n")

# ============================================================================
# SUMMARY REPORT
# ============================================================================

cat("\n")
cat(paste(rep("=", 80), collapse = ""), "\n")
cat("📊 FIGURE 2.9 GENERATION COMPLETE\n")
cat(paste(rep("=", 80), collapse = ""), "\n\n")

cat("✅ Generated figures:\n")
cat("   • FIG_2.9A_MEAN_CV.png              - Mean CV comparison\n")
cat("   • FIG_2.9B_CV_DISTRIBUTION.png      - Distribution (violin + box)\n")
cat("   • FIG_2.9C_CV_VS_MEAN.png           - Correlation analysis\n")
cat("   • FIG_2.9D_TOP_VARIABLE.png         - Top 20 variable miRNAs\n")
cat("   • FIG_2.9_COMBINED_IMPROVED.png     - Combined A+B+C ⭐\n\n")

cat("✅ Statistical tables:\n")
cat("   • TABLE_2.9_CV_summary.csv          - Group statistics\n")
cat("   • TABLE_2.9_CV_all_miRNAs.csv       - All CV values\n")
cat("   • TABLE_2.9_statistical_tests.csv   - Test results\n")
cat("   • TABLE_2.9_top_variable_miRNAs.csv - Top 10 per group\n")
cat("   • TABLE_2.9_CV_Mean_correlations.csv - Correlation results\n\n")

cat("📊 Key Results:\n")
cat(sprintf("   ALS:     Mean CV = %.1f%% (SD = %.1f%%)\n", 
            cv_summary$Mean_CV[cv_summary$Group == "ALS"],
            cv_summary$SD_CV[cv_summary$Group == "ALS"]))
cat(sprintf("   Control: Mean CV = %.1f%% (SD = %.1f%%)\n", 
            cv_summary$Mean_CV[cv_summary$Group == "Control"],
            cv_summary$SD_CV[cv_summary$Group == "Control"]))
cat(sprintf("   Difference: %.1f%%\n\n", 
            abs(cv_summary$Mean_CV[cv_summary$Group == "ALS"] - 
                cv_summary$Mean_CV[cv_summary$Group == "Control"])))

cat("📊 Statistical Interpretation:\n")

if (f_test$p.value < 0.05) {
  cat("   ✅ Significant difference in CV (F-test p < 0.05)\n")
  if (cv_summary$Mean_CV[cv_summary$Group == "ALS"] > 
      cv_summary$Mean_CV[cv_summary$Group == "Control"]) {
    cat("   → ALS is MORE heterogeneous than Control\n")
  } else {
    cat("   → Control is MORE heterogeneous than ALS\n")
  }
} else {
  cat("   ⚠️ No significant difference in CV (F-test p ≥ 0.05)\n")
  cat("   → Both groups have similar heterogeneity\n")
}

cat("\n")

if (abs(cv_mean_cor_als$estimate) > 0.3 || abs(cv_mean_cor_ctrl$estimate) > 0.3) {
  cat("   ✅ CV correlates with Mean VAF (r > 0.3)\n")
  cat("   → High-burden miRNAs are more variable\n")
} else {
  cat("   ⚠️ CV does not strongly correlate with Mean\n")
  cat("   → Variability independent of magnitude\n")
}

cat("\n")
cat(paste(rep("=", 80), collapse = ""), "\n")
cat("✅ ALL FILES SAVED TO:", output_dir, "\n")
cat(paste(rep("=", 80), collapse = ""), "\n\n")

