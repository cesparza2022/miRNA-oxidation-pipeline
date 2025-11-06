#!/usr/bin/env Rscript
# ==============================================================================
# FIGURE 2.7 IMPROVED: PCA WITH PERMANOVA AND STATISTICAL RIGOR
# ==============================================================================
# Date: 2025-10-27
# Purpose: PCA analysis with proper statistical testing
# Improvements:
#   1. PERMANOVA test (quantify group separation)
#   2. Fixed point sizes (remove bias)
#   3. Scree plot (show variance distribution)
#   4. PC-Group correlation analysis
#   5. Loadings analysis (identify driver miRNAs)
#   6. Complete statistical output
# ==============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(vegan)     # For PERMANOVA
  library(patchwork) # For combining plots
})

# ============================================================================
# CONFIGURATION
# ============================================================================

input_file <- "final_processed_data_CLEAN.csv"
metadata_file <- "metadata.csv"
ranking_file <- "SEED_GT_miRNAs_CLEAN_RANKING.csv"
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
    legend.position = "right",
    panel.grid.minor = element_blank(),
    panel.border = element_rect(fill = NA, color = "gray80")
  )

cat("\n")
cat(paste(rep("=", 80), collapse = ""), "\n")
cat("📊 FIGURE 2.7 PCA - IMPROVED VERSION\n")
cat(paste(rep("=", 80), collapse = ""), "\n\n")

# ============================================================================
# LOAD DATA
# ============================================================================

cat("📂 Loading data...\n")

data <- read.csv(input_file, check.names = FALSE)
metadata <- read.csv(metadata_file)
seed_ranking <- read.csv(ranking_file)

all_seed_mirnas <- seed_ranking$miRNA_name
sample_cols <- metadata$Sample_ID

cat(sprintf("✅ Loaded:\n"))
cat(sprintf("   • %d SNVs\n", nrow(data)))
cat(sprintf("   • %d samples (%d ALS, %d Control)\n", 
            nrow(metadata),
            sum(metadata$Group == "ALS"),
            sum(metadata$Group == "Control")))
cat(sprintf("   • %d seed G>T miRNAs\n\n", length(all_seed_mirnas)))

# ============================================================================
# PREPARE DATA FOR PCA
# ============================================================================

cat("📊 Preparing data for PCA...\n")

# Filter G>T mutations
vaf_gt <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  select(all_of(c("miRNA_name", "pos.mut", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), 
               names_to = "Sample_ID", 
               values_to = "VAF") %>%
  left_join(metadata, by = "Sample_ID") %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^[0-9]+"))) %>%
  filter(!is.na(position), position <= 22)

# Create PCA matrix: samples (rows) × miRNAs (columns)
pca_matrix <- vaf_gt %>%
  filter(miRNA_name %in% all_seed_mirnas) %>%
  group_by(Sample_ID, miRNA_name) %>%
  summarise(Total_VAF = sum(VAF, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = miRNA_name, 
              values_from = Total_VAF, 
              values_fill = 0)

pca_samples <- pca_matrix$Sample_ID
pca_data <- as.matrix(pca_matrix[, -1])
rownames(pca_data) <- pca_samples

cat(sprintf("✅ PCA matrix created: %d samples × %d miRNAs\n", 
            nrow(pca_data), ncol(pca_data)))

# Filter low-variance miRNAs
col_vars <- apply(pca_data, 2, var, na.rm = TRUE)
pca_data_filt <- pca_data[, col_vars > 0.001]

n_removed <- ncol(pca_data) - ncol(pca_data_filt)
cat(sprintf("✅ Variance filtering: %d miRNAs kept, %d removed (var < 0.001)\n\n", 
            ncol(pca_data_filt), n_removed))

# ============================================================================
# RUN PCA
# ============================================================================

cat("🔬 Running PCA...\n")

pca_result <- prcomp(pca_data_filt, scale. = TRUE, center = TRUE)

# Extract coordinates
pca_coords <- data.frame(
  Sample_ID = pca_samples,
  PC1 = pca_result$x[, 1],
  PC2 = pca_result$x[, 2],
  PC3 = pca_result$x[, 3],
  PC4 = pca_result$x[, 4]
) %>%
  left_join(metadata, by = "Sample_ID")

# Calculate variance explained
var_exp <- summary(pca_result)$importance[2, ] * 100
cum_var <- var_exp[1] + var_exp[2]

cat(sprintf("✅ PCA complete:\n"))
cat(sprintf("   • PC1 explains: %.1f%% variance\n", var_exp[1]))
cat(sprintf("   • PC2 explains: %.1f%% variance\n", var_exp[2]))
cat(sprintf("   • PC1+PC2 total: %.1f%% variance\n\n", cum_var))

# ============================================================================
# PERMANOVA: TEST GROUP SEPARATION
# ============================================================================

cat("🔬 Performing PERMANOVA test...\n")

# Prepare metadata for PERMANOVA
permanova_meta <- metadata %>%
  filter(Sample_ID %in% rownames(pca_data_filt)) %>%
  arrange(match(Sample_ID, rownames(pca_data_filt)))

# Run PERMANOVA
permanova_result <- adonis2(pca_data_filt ~ Group, 
                            data = permanova_meta,
                            method = "euclidean",
                            permutations = 9999)

r2_value <- permanova_result$R2[1]
p_value <- permanova_result$`Pr(>F)`[1]

cat(sprintf("✅ PERMANOVA results:\n"))
cat(sprintf("   • R² = %.4f (Group explains %.1f%% of variance)\n", 
            r2_value, r2_value * 100))
cat(sprintf("   • p-value = %s\n", format.pval(p_value, digits = 3)))

if (p_value < 0.05) {
  cat("   • ✅ Significant separation (p < 0.05)\n\n")
} else {
  cat("   • ⚠️ No significant separation (p ≥ 0.05)\n\n")
}

# ============================================================================
# PC-GROUP CORRELATION ANALYSIS
# ============================================================================

cat("🔬 Analyzing PC-Group correlations...\n")

group_numeric <- as.numeric(pca_coords$Group == "ALS")

pc_correlations <- data.frame()
for (i in 1:min(10, ncol(pca_result$x))) {
  pc_values <- pca_result$x[, i]
  cor_result <- cor.test(pc_values, group_numeric)
  
  pc_correlations <- rbind(pc_correlations, data.frame(
    PC = i,
    Correlation = cor_result$estimate,
    Pvalue = cor_result$p.value,
    Variance_Explained = var_exp[i]
  ))
}

cat("✅ PC-Group correlations (top 5):\n")
print(head(pc_correlations, 5))
cat("\n")

# Find PC with strongest group correlation
best_pc <- pc_correlations %>% 
  arrange(desc(abs(Correlation))) %>% 
  head(1)

cat(sprintf("   • Strongest correlation: PC%d (r = %.3f, p = %s)\n\n",
            best_pc$PC, best_pc$Correlation, format.pval(best_pc$Pvalue, digits = 3)))

# ============================================================================
# LOADINGS ANALYSIS
# ============================================================================

cat("🔬 Analyzing loadings (driver miRNAs)...\n")

# Top 10 miRNAs contributing to PC1
loadings_pc1 <- pca_result$rotation[, 1]
top_10_pc1 <- names(sort(abs(loadings_pc1), decreasing = TRUE)[1:10])

loadings_pc2 <- pca_result$rotation[, 2]
top_10_pc2 <- names(sort(abs(loadings_pc2), decreasing = TRUE)[1:10])

cat("✅ Top 5 miRNAs driving PC1:\n")
cat(paste("   •", head(top_10_pc1, 5), collapse = "\n"), "\n\n")

cat("✅ Top 5 miRNAs driving PC2:\n")
cat(paste("   •", head(top_10_pc2, 5), collapse = "\n"), "\n\n")

# ============================================================================
# FIGURE 2.7A: MAIN PCA PLOT (PC1 vs PC2)
# ============================================================================

cat("📊 Creating Figure 2.7A: Main PCA plot...\n")

fig_2_7a <- ggplot(pca_coords, aes(x = PC1, y = PC2, color = Group)) +
  
  # 95% confidence ellipses
  stat_ellipse(aes(fill = Group), geom = "polygon", 
               alpha = 0.15, level = 0.95, show.legend = FALSE,
               linewidth = 1) +
  
  # Points (FIXED size - no bias!)
  geom_point(alpha = 0.7, size = 2.5) +
  
  # Colors
  scale_color_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  
  # Labels
  labs(
    title = "A. PCA: Sample Clustering by G>T Profile",
    subtitle = sprintf("PERMANOVA: R² = %.3f, p = %s | %d miRNAs (variance > 0.001)",
                      r2_value, format.pval(p_value, digits = 3), ncol(pca_data_filt)),
    x = sprintf("PC1 (%.1f%% variance)", var_exp[1]),
    y = sprintf("PC2 (%.1f%% variance)", var_exp[2]),
    caption = sprintf("95%% confidence ellipses shown. PC1+PC2 = %.1f%% total variance. n_ALS=%d, n_Control=%d",
                     cum_var, sum(metadata$Group == "ALS"), sum(metadata$Group == "Control"))
  ) +
  
  theme_professional +
  theme(legend.title = element_blank())

ggsave(file.path(output_dir, "FIG_2.7A_PCA_MAIN_IMPROVED.png"),
       plot = fig_2_7a, width = 12, height = 10, dpi = 300)

cat("✅ Figure 2.7A saved\n\n")

# ============================================================================
# FIGURE 2.7B: SCREE PLOT
# ============================================================================

cat("📊 Creating Figure 2.7B: Scree plot...\n")

scree_data <- data.frame(
  PC = 1:min(15, length(var_exp)),
  Variance = var_exp[1:min(15, length(var_exp))],
  Cumulative = cumsum(var_exp)[1:min(15, length(var_exp))]
)

fig_2_7b <- ggplot(scree_data, aes(x = PC, y = Variance)) +
  geom_bar(stat = "identity", fill = "steelblue", alpha = 0.7) +
  geom_line(aes(y = Cumulative/5), color = "#d32f2f", linewidth = 1.2, group = 1) +
  geom_point(aes(y = Cumulative/5), color = "#d32f2f", size = 3) +
  scale_y_continuous(
    name = "Variance Explained (%)",
    sec.axis = sec_axis(~.*5, name = "Cumulative Variance (%)")
  ) +
  scale_x_continuous(breaks = 1:15) +
  geom_hline(yintercept = 5, linetype = "dashed", color = "gray50") +
  labs(
    title = "B. Scree Plot: Variance by Principal Component",
    subtitle = sprintf("PC1+PC2 = %.1f%% | Dashed line = 5%% threshold", cum_var),
    caption = "Red line = cumulative variance"
  ) +
  theme_professional

ggsave(file.path(output_dir, "FIG_2.7B_SCREE_PLOT.png"),
       plot = fig_2_7b, width = 10, height = 7, dpi = 300)

cat("✅ Figure 2.7B saved\n\n")

# ============================================================================
# FIGURE 2.7C: LOADINGS (TOP miRNAs for PC1 and PC2)
# ============================================================================

cat("📊 Creating Figure 2.7C: Loadings plot...\n")

loadings_data <- data.frame(
  miRNA = c(top_10_pc1, top_10_pc2),
  PC = c(rep("PC1", 10), rep("PC2", 10)),
  Loading = c(loadings_pc1[top_10_pc1], loadings_pc2[top_10_pc2])
) %>%
  mutate(miRNA = factor(miRNA, levels = unique(miRNA)))

fig_2_7c <- ggplot(loadings_data, aes(x = reorder(miRNA, Loading), 
                                       y = Loading, fill = PC)) +
  geom_bar(stat = "identity", alpha = 0.8) +
  coord_flip() +
  facet_wrap(~PC, scales = "free_y", ncol = 1) +
  scale_fill_manual(values = c("PC1" = "#1976d2", "PC2" = "#d32f2f")) +
  labs(
    title = "C. Top 10 Driver miRNAs per Principal Component",
    subtitle = "miRNAs with highest absolute loadings",
    x = "miRNA",
    y = "Loading (contribution to PC)"
  ) +
  theme_professional +
  theme(legend.position = "none")

ggsave(file.path(output_dir, "FIG_2.7C_LOADINGS.png"),
       plot = fig_2_7c, width = 10, height = 10, dpi = 300)

cat("✅ Figure 2.7C saved\n\n")

# ============================================================================
# FIGURE 2.7D: PC3 vs PC4 (in case signal is there)
# ============================================================================

cat("📊 Creating Figure 2.7D: PC3 vs PC4...\n")

fig_2_7d <- ggplot(pca_coords, aes(x = PC3, y = PC4, color = Group)) +
  stat_ellipse(aes(fill = Group), geom = "polygon", 
               alpha = 0.15, level = 0.95, show.legend = FALSE,
               linewidth = 1) +
  geom_point(alpha = 0.7, size = 2.5) +
  scale_color_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  labs(
    title = "D. PCA: PC3 vs PC4",
    subtitle = sprintf("Checking if disease signal is in higher PCs (PC3=%.1f%%, PC4=%.1f%%)",
                      var_exp[3], var_exp[4]),
    x = sprintf("PC3 (%.1f%% variance)", var_exp[3]),
    y = sprintf("PC4 (%.1f%% variance)", var_exp[4])
  ) +
  theme_professional +
  theme(legend.title = element_blank())

ggsave(file.path(output_dir, "FIG_2.7D_PC3_PC4.png"),
       plot = fig_2_7d, width = 12, height = 10, dpi = 300)

cat("✅ Figure 2.7D saved\n\n")

# ============================================================================
# FIGURE 2.7_COMBINED: MAIN FIGURE WITH SCREE PLOT
# ============================================================================

cat("📊 Creating combined figure...\n")

fig_2_7_combined <- fig_2_7a + 
  inset_element(fig_2_7b, left = 0.55, bottom = 0.55, right = 0.98, top = 0.98) +
  plot_annotation(
    title = "Figure 2.7: PCA Analysis of G>T Mutational Profiles",
    theme = theme(plot.title = element_text(face = "bold", size = 16))
  )

ggsave(file.path(output_dir, "FIG_2.7_COMBINED_WITH_SCREE.png"),
       plot = fig_2_7_combined, width = 14, height = 10, dpi = 300)

cat("✅ Combined figure saved\n\n")

# ============================================================================
# SAVE STATISTICAL RESULTS
# ============================================================================

cat("💾 Saving statistical results...\n")

# 1. PERMANOVA results
permanova_summary <- data.frame(
  Test = "PERMANOVA",
  R2 = r2_value,
  F_statistic = permanova_result$F[1],
  Df = permanova_result$Df[1],
  Pvalue = p_value,
  Permutations = 9999
)

write.csv(permanova_summary,
          file.path(output_dir, "TABLE_2.7_PERMANOVA_results.csv"),
          row.names = FALSE)

# 2. PC-Group correlations
write.csv(pc_correlations,
          file.path(output_dir, "TABLE_2.7_PC_correlations.csv"),
          row.names = FALSE)

# 3. Top loadings
loadings_pc1_df <- data.frame(
  miRNA = names(loadings_pc1),
  Loading_PC1 = loadings_pc1,
  Abs_Loading_PC1 = abs(loadings_pc1)
) %>%
  arrange(desc(Abs_Loading_PC1)) %>%
  head(20)

loadings_pc2_df <- data.frame(
  miRNA = names(loadings_pc2),
  Loading_PC2 = loadings_pc2,
  Abs_Loading_PC2 = abs(loadings_pc2)
) %>%
  arrange(desc(Abs_Loading_PC2)) %>%
  head(20)

write.csv(loadings_pc1_df,
          file.path(output_dir, "TABLE_2.7_PC1_top_loadings.csv"),
          row.names = FALSE)

write.csv(loadings_pc2_df,
          file.path(output_dir, "TABLE_2.7_PC2_top_loadings.csv"),
          row.names = FALSE)

# 4. Variance summary
variance_summary <- data.frame(
  PC = 1:min(15, length(var_exp)),
  Variance_Explained = var_exp[1:min(15, length(var_exp))],
  Cumulative_Variance = cumsum(var_exp)[1:min(15, length(var_exp))]
)

write.csv(variance_summary,
          file.path(output_dir, "TABLE_2.7_variance_explained.csv"),
          row.names = FALSE)

cat("✅ All statistical results saved\n\n")

# ============================================================================
# SUMMARY REPORT
# ============================================================================

cat("\n")
cat(paste(rep("=", 80), collapse = ""), "\n")
cat("📊 FIGURE 2.7 GENERATION COMPLETE\n")
cat(paste(rep("=", 80), collapse = ""), "\n\n")

cat("✅ Generated figures:\n")
cat("   • FIG_2.7A_PCA_MAIN_IMPROVED.png      - Main PCA (PC1 vs PC2)\n")
cat("   • FIG_2.7B_SCREE_PLOT.png             - Variance by PC\n")
cat("   • FIG_2.7C_LOADINGS.png               - Top driver miRNAs\n")
cat("   • FIG_2.7D_PC3_PC4.png                - Alternative view\n")
cat("   • FIG_2.7_COMBINED_WITH_SCREE.png     - Main + Scree inset ⭐\n\n")

cat("✅ Statistical tables:\n")
cat("   • TABLE_2.7_PERMANOVA_results.csv     - Group separation test\n")
cat("   • TABLE_2.7_PC_correlations.csv       - PC-Group correlations\n")
cat("   • TABLE_2.7_PC1_top_loadings.csv      - Top 20 miRNAs (PC1)\n")
cat("   • TABLE_2.7_PC2_top_loadings.csv      - Top 20 miRNAs (PC2)\n")
cat("   • TABLE_2.7_variance_explained.csv    - Variance by PC\n\n")

cat("📊 Key Results:\n")
cat(sprintf("   • Total variance captured (PC1+PC2): %.1f%%\n", cum_var))
cat(sprintf("   • Group separation (PERMANOVA R²): %.3f (%.1f%% variance)\n", 
            r2_value, r2_value * 100))
cat(sprintf("   • Statistical significance: p = %s\n", format.pval(p_value, digits = 3)))
cat(sprintf("   • miRNAs used in PCA: %d (after variance filtering)\n", ncol(pca_data_filt)))
cat(sprintf("   • Strongest PC-Group correlation: PC%d (r = %.3f)\n\n", 
            best_pc$PC, best_pc$Correlation))

# ============================================================================
# INTERPRETATION GUIDE
# ============================================================================

cat("💡 Interpretation:\n")

if (cum_var < 20) {
  cat("   ⚠️ WARNING: Low variance captured (<20%)\n")
  cat("      → Most data structure NOT in PC1-PC2\n")
  cat("      → 2D plot may be misleading\n")
  cat("      → Consider: t-SNE, UMAP, or higher PCs\n\n")
} else if (cum_var < 40) {
  cat("   ⚠️ Moderate variance captured (20-40%)\n")
  cat("      → PC1-PC2 show partial picture\n")
  cat("      → Substantial variance in higher PCs\n")
  cat("      → Check PC3-PC4 for additional patterns\n\n")
} else {
  cat("   ✅ Good variance captured (>40%)\n")
  cat("      → PC1-PC2 represent data well\n")
  cat("      → 2D plot is informative\n\n")
}

if (p_value < 0.001) {
  cat("   ✅ Highly significant group separation (p < 0.001)\n")
  cat("      → ALS and Control have distinct profiles\n")
} else if (p_value < 0.05) {
  cat("   ✅ Significant group separation (p < 0.05)\n")
  cat("      → Groups differ, but effect may be small\n")
  cat(sprintf("      → R² = %.3f means Group explains only %.1f%% of variance\n", 
              r2_value, r2_value * 100))
} else {
  cat("   ⚠️ No significant group separation (p ≥ 0.05)\n")
  cat("      → G>T profile does NOT predict disease status\n")
  cat("      → Individual variation >> group difference\n")
}

cat("\n")
cat(paste(rep("=", 80), collapse = ""), "\n")
cat("✅ ALL FILES SAVED TO:", output_dir, "\n")
cat(paste(rep("=", 80), collapse = ""), "\n\n")

# ============================================================================
# VISUAL INSPECTION HELPER
# ============================================================================

cat("🔍 Quick visual inspection summary:\n\n")

# Count samples in each quadrant
q1 <- sum(pca_coords$PC1 > 0 & pca_coords$PC2 > 0)
q2 <- sum(pca_coords$PC1 < 0 & pca_coords$PC2 > 0)
q3 <- sum(pca_coords$PC1 < 0 & pca_coords$PC2 < 0)
q4 <- sum(pca_coords$PC1 > 0 & pca_coords$PC2 < 0)

cat("   Samples per quadrant:\n")
cat(sprintf("      Q1 (PC1+, PC2+): %d samples\n", q1))
cat(sprintf("      Q2 (PC1-, PC2+): %d samples\n", q2))
cat(sprintf("      Q3 (PC1-, PC2-): %d samples\n", q3))
cat(sprintf("      Q4 (PC1+, PC2-): %d samples\n\n", q4))

# Group distribution in PC1 direction
als_mean_pc1 <- mean(pca_coords$PC1[pca_coords$Group == "ALS"])
ctrl_mean_pc1 <- mean(pca_coords$PC1[pca_coords$Group == "Control"])

cat("   Group means on PC1:\n")
cat(sprintf("      ALS mean: %.2f\n", als_mean_pc1))
cat(sprintf("      Control mean: %.2f\n", ctrl_mean_pc1))
cat(sprintf("      Difference: %.2f\n\n", ctrl_mean_pc1 - als_mean_pc1))

if (abs(ctrl_mean_pc1 - als_mean_pc1) > 0.5) {
  cat("   ✓ Groups have different PC1 centers (potential separation)\n")
} else {
  cat("   ⚠️ Groups have similar PC1 centers (likely overlap)\n")
}

cat("\n✅ Script complete!\n\n")

