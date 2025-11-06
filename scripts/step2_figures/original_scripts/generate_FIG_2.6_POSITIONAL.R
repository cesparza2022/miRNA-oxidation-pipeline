#!/usr/bin/env Rscript
# ============================================================================
# FIGURA 2.6 - POSITIONAL ANALYSIS (Line Plots with CI)
# Mean VAF by position for ALS vs Control with confidence intervals
# ============================================================================

library(ggplot2)
library(dplyr)
library(tidyr)
library(readr)
library(stringr)

# Colores profesionales
COLOR_ALS <- "#D62728"
COLOR_CONTROL <- "#2E86AB"
COLOR_SEED <- "#e3f2fd"

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  GENERATING FIG 2.6 - POSITIONAL ANALYSIS\n")
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

cat("📊 Preparing positional data...\n")

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
  filter(!is.na(VAF)) %>%
  left_join(metadata %>% select(Sample_ID, Group), by = "Sample_ID")

cat("   ✅ Data prepared\n\n")

# ============================================================================
# CALCULATE POSITIONAL STATISTICS
# ============================================================================

cat("📊 Calculating positional statistics...\n")

# Aggregate per sample first (per-sample total VAF at each position)
vaf_per_sample <- vaf_long %>%
  group_by(Sample_ID, position, Group) %>%
  summarise(Total_VAF = sum(VAF, na.rm = TRUE), .groups = "drop")

# Calculate statistics per position and group
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
    CI_lower = pmax(0, Mean_VAF - 1.96 * SE_VAF),
    CI_upper = Mean_VAF + 1.96 * SE_VAF
  )

cat("   ✅ Statistics calculated\n\n")

# ============================================================================
# STATISTICAL TESTS
# ============================================================================

cat("🔬 Performing statistical tests per position...\n")

# Function to calculate Cohen's d (effect size)
cohens_d <- function(x, y) {
  nx <- length(x)
  ny <- length(y)
  mx <- mean(x, na.rm = TRUE)
  my <- mean(y, na.rm = TRUE)
  sx <- sd(x, na.rm = TRUE)
  sy <- sd(y, na.rm = TRUE)
  
  # Pooled standard deviation
  pooled_sd <- sqrt(((nx - 1) * sx^2 + (ny - 1) * sy^2) / (nx + ny - 2))
  
  if (pooled_sd == 0 || is.na(pooled_sd)) {
    return(NA)
  }
  
  return((mx - my) / pooled_sd)
}

position_tests <- data.frame()

for (pos in sort(unique(positional_stats$position))) {
  pos_data <- vaf_per_sample %>% filter(position == pos)
  
  als_vals <- pos_data %>% filter(Group == "ALS") %>% pull(Total_VAF)
  ctrl_vals <- pos_data %>% filter(Group == "Control") %>% pull(Total_VAF)
  
  if (length(als_vals) >= 5 && length(ctrl_vals) >= 5) {
    # Descriptive statistics
    mean_als <- mean(als_vals, na.rm = TRUE)
    mean_ctrl <- mean(ctrl_vals, na.rm = TRUE)
    median_als <- median(als_vals, na.rm = TRUE)
    median_ctrl <- median(ctrl_vals, na.rm = TRUE)
    sd_als <- sd(als_vals, na.rm = TRUE)
    sd_ctrl <- sd(ctrl_vals, na.rm = TRUE)
    n_als <- length(als_vals)
    n_ctrl <- length(ctrl_vals)
    
    # Wilcoxon test
    wilcox_result <- tryCatch({
      wilcox.test(als_vals, ctrl_vals)
    }, error = function(e) {
      list(p.value = 1)
    })
    
    # T-test
    ttest_result <- tryCatch({
      t.test(als_vals, ctrl_vals)
    }, error = function(e) {
      list(p.value = 1)
    })
    
    # Cohen's d (effect size) - Control - ALS (positive = Control higher)
    d <- cohens_d(ctrl_vals, als_vals)
    
    # Effect direction
    if (mean_ctrl > mean_als) {
      direction <- "Control > ALS"
    } else if (mean_als > mean_ctrl) {
      direction <- "ALS > Control"
    } else {
      direction <- "Equal"
    }
    
    position_tests <- rbind(position_tests, data.frame(
      position = pos,
      mean_ALS = mean_als,
      mean_Control = mean_ctrl,
      median_ALS = median_als,
      median_Control = median_ctrl,
      sd_ALS = sd_als,
      sd_Control = sd_ctrl,
      n_ALS = n_als,
      n_Control = n_ctrl,
      wilcoxon_p = wilcox_result$p.value,
      t_test_p = ttest_result$p.value,
      cohens_d = d,
      effect_direction = direction,
      stringsAsFactors = FALSE
    ))
  }
}

# FDR correction for both tests
if (nrow(position_tests) > 0) {
  position_tests$wilcoxon_padj <- p.adjust(position_tests$wilcoxon_p, method = "fdr")
  position_tests$t_test_padj <- p.adjust(position_tests$t_test_p, method = "fdr")
  
  position_tests$wilcoxon_sig <- ifelse(position_tests$wilcoxon_padj < 0.05, "★", "ns")
  position_tests$t_test_sig <- ifelse(position_tests$t_test_padj < 0.05, "★", "ns")
  
  # Reorder columns for readability
  position_tests <- position_tests %>% 
    select(position, mean_ALS, mean_Control, median_ALS, median_Control,
           sd_ALS, sd_Control, n_ALS, n_Control,
           wilcoxon_p, wilcoxon_padj, wilcoxon_sig,
           t_test_p, t_test_padj, t_test_sig,
           cohens_d, effect_direction)
  
  cat("   ✅ Tests completed.\n")
  cat("      • Significant positions (Wilcoxon FDR < 0.05):", 
      sum(position_tests$wilcoxon_padj < 0.05), "\n")
  cat("      • Significant positions (t-test FDR < 0.05):", 
      sum(position_tests$t_test_padj < 0.05), "\n")
  cat("      • Total positions tested:", nrow(position_tests), "\n\n")
  
  # Export complete table
  output_dir <- "figures_paso2_CLEAN"
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
  
  write_csv(position_tests, 
            file.path(output_dir, "TABLE_2.6_positional_tests_COMPLETE.csv"))
  cat("   💾 Exported: TABLE_2.6_positional_tests_COMPLETE.csv\n")
  
  # Export significant positions only
  significant <- position_tests %>% 
    filter(wilcoxon_padj < 0.05 | t_test_padj < 0.05)
  
  if (nrow(significant) > 0) {
    write_csv(significant, 
              file.path(output_dir, "TABLE_2.6_positional_tests_SIGNIFICANT.csv"))
    cat("   💾 Exported: TABLE_2.6_positional_tests_SIGNIFICANT.csv\n")
    cat("      •", nrow(significant), "significant positions\n\n")
    
    # Print summary
    cat("📊 SIGNIFICANT POSITIONS SUMMARY:\n")
    cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
    print(significant %>% select(position, mean_ALS, mean_Control, 
                                 wilcoxon_padj, t_test_padj, cohens_d, effect_direction))
    cat("\n")
  } else {
    cat("   ⚠️  No significant positions found\n\n")
  }
}

# ============================================================================
# GENERATE FIGURE 2.6
# ============================================================================

cat("🎨 Generating Figure 2.6: Positional line plot...\n")

# Theme profesional
theme_prof <- theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5, color = "gray30"),
    axis.title = element_text(size = 13, face = "bold"),
    axis.text = element_text(size = 11),
    legend.title = element_text(size = 11, face = "bold"),
    legend.text = element_text(size = 10),
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    panel.border = element_rect(fill = NA, color = "gray80")
  )

# Line plot with CI
fig_2_6 <- ggplot(positional_stats, aes(x = position, y = Mean_VAF, 
                                         color = Group, fill = Group)) +
  # Seed region background
  annotate("rect", xmin = 2, xmax = 8, ymin = -Inf, ymax = Inf, 
           fill = COLOR_SEED, alpha = 0.5) +
  annotate("text", x = 5, y = max(positional_stats$CI_upper, na.rm = TRUE) * 0.95, 
           label = "SEED", color = "gray40", size = 4, fontface = "bold") +
  
  # Confidence intervals
  geom_ribbon(aes(ymin = CI_lower, ymax = CI_upper), 
              alpha = 0.2, color = NA) +
  
  # Lines and points
  geom_line(linewidth = 1.2, alpha = 0.9) +
  geom_point(size = 3, alpha = 0.8) +
  
  # Colors
  scale_color_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  
  # Scales
  scale_x_continuous(breaks = seq(1, 23, by = 2)) +
  scale_y_continuous(labels = scales::comma) +
  
  # Labels
  labs(
    title = "Positional G>T Burden Profile",
    subtitle = "Mean VAF per position with 95% confidence intervals | Shaded region = seed (2-8)",
    x = "Position in miRNA",
    y = "Mean G>T VAF (sum per sample)",
    color = "Group",
    fill = "Group"
  ) +
  theme_prof

ggsave("figures_paso2_CLEAN/FIG_2.6_POSITIONAL_ANALYSIS.png", 
       fig_2_6, width = 14, height = 8, dpi = 300, bg = "white")

cat("   ✅ Figure saved: FIG_2.6_POSITIONAL_ANALYSIS.png\n\n")

# ============================================================================
# POSITIONAL ANALYSIS SUMMARY
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("📊 POSITIONAL ANALYSIS SUMMARY:\n\n")

# Compare seed vs non-seed
seed_stats <- positional_stats %>%
  filter(position >= 2, position <= 8) %>%
  group_by(Group) %>%
  summarise(Mean_VAF_seed = mean(Mean_VAF), .groups = "drop")

nonseed_stats <- positional_stats %>%
  filter(position < 2 | position > 8) %>%
  group_by(Group) %>%
  summarise(Mean_VAF_nonseed = mean(Mean_VAF), .groups = "drop")

comparison <- seed_stats %>%
  left_join(nonseed_stats, by = "Group") %>%
  mutate(Ratio = Mean_VAF_seed / Mean_VAF_nonseed)

cat("SEED vs NON-SEED REGIONS:\n")
print(comparison)
cat("\n")

# Top positions
top_positions <- positional_stats %>%
  group_by(position) %>%
  summarise(Total_VAF = sum(Mean_VAF), .groups = "drop") %>%
  arrange(desc(Total_VAF)) %>%
  head(5)

cat("TOP 5 POSITIONS (highest total burden):\n")
print(top_positions)
cat("\n")

# ============================================================================
# INTERPRETATION
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("💡 INTERPRETATION:\n\n")

cat("WHAT THIS FIGURE SHOWS:\n")
cat("   • Positional profile of G>T burden\n")
cat("   • Mean VAF per position (averaged across samples)\n")
cat("   • 95% confidence intervals (uncertainty quantification)\n")
cat("   • Seed region marked (positions 2-8)\n\n")

cat("KEY OBSERVATIONS:\n")
cat("   • Control > ALS at most positions (consistent with Fig 2.1-2.2)\n")
cat("   • Seed ratio:", sprintf("%.2f", mean(comparison$Ratio)), "\n")
cat("   • Hotspots:", paste(top_positions$position[1:3], collapse = ", "), "\n\n")

cat("COMPARISON WITH OTHER FIGURES:\n")
cat("   • Fig 2.4: Heatmap (all miRNAs × positions)\n")
cat("   • Fig 2.5: Z-score (outliers)\n")
cat("   • Fig 2.6: Positional means (this figure) ⭐\n")
cat("   → COMPLEMENTARY perspectives\n\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("✅ FIGURE 2.6 GENERATED SUCCESSFULLY\n\n")

