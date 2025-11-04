#!/usr/bin/env Rscript
# ============================================================================
# 🎯 STEP 1.5: GENERATE DIAGNOSTIC FIGURES - VAF-FILTERED DATA (Snakemake)
# ============================================================================
# Purpose: Generate diagnostic figures with VAF-cleaned data
# 
# Snakemake parameters:
#   input: 4 CSV tables (from Script 1)
#   output: 11 figures PNG + 3 tables CSV
# ============================================================================

library(ggplot2)
library(dplyr)
library(tidyr)
library(patchwork)
library(tibble)
library(scales)

cat("╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║     🎯 STEP 1.5: DIAGNOSTIC FIGURES - VAF-FILTERED DATA            ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

# ============================================================================
# GET SNAKEMAKE PARAMETERS
# ============================================================================

# Inputs (from Script 1)
input_filtered_data <- snakemake@input[["filtered_data"]]
input_filter_report <- snakemake@input[["filter_report"]]
input_stats_by_type <- snakemake@input[["stats_by_type"]]
input_stats_by_mirna <- snakemake@input[["stats_by_mirna"]]

# Outputs (11 figures + 3 tables)
output_qc_fig1 <- snakemake@output[["qc_fig1"]]
output_qc_fig2 <- snakemake@output[["qc_fig2"]]
output_qc_fig3 <- snakemake@output[["qc_fig3"]]
output_qc_fig4 <- snakemake@output[["qc_fig4"]]
output_diag_fig1 <- snakemake@output[["diag_fig1"]]
output_diag_fig2 <- snakemake@output[["diag_fig2"]]
output_diag_fig3 <- snakemake@output[["diag_fig3"]]
output_diag_fig4 <- snakemake@output[["diag_fig4"]]
output_diag_fig5 <- snakemake@output[["diag_fig5"]]
output_diag_fig6 <- snakemake@output[["diag_fig6"]]
output_diag_fig7 <- snakemake@output[["diag_fig7"]]
output_sample_metrics <- snakemake@output[["sample_metrics"]]
output_position_metrics <- snakemake@output[["position_metrics"]]
output_mutation_summary <- snakemake@output[["mutation_summary"]]

cat("📋 Parameters:\n")
cat("   Input filtered data:", input_filtered_data, "\n")
cat("   Input filter report:", input_filter_report, "\n")
cat("   Outputs: 11 figures + 3 tables\n\n")

# Ensure output directories exist
dir.create(dirname(output_qc_fig1), showWarnings = FALSE, recursive = TRUE)
dir.create(dirname(output_sample_metrics), showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# 1. LOAD VAF-FILTERED DATA
# ============================================================================

cat("📊 Loading VAF-filtered data...\n")
data <- read.csv(input_filtered_data, check.names = FALSE)

cat(sprintf("   ✅ Total rows: %s\n", format(nrow(data), big.mark = ",")))
cat(sprintf("   ✅ Columns: %d\n", ncol(data)))

# Load filter report
filter_report <- read.csv(input_filter_report)
cat(sprintf("   ✅ Filtered events: %s\n", format(nrow(filter_report), big.mark = ",")))

# Clean and prepare data (same as Step 1)
data_clean <- data %>%
  filter(`pos:mut` != "PM") %>%
  mutate(
    miRNA = `miRNA name`,
    pos_mut = `pos:mut`,
    Position = as.numeric(gsub(":.*", "", pos_mut)),
    Mutation_Type = gsub(".*:", "", pos_mut),
    Mutation_Type = gsub('"', '', Mutation_Type),
    Region = ifelse(Position >= 2 & Position <= 8, "Seed", "Non-Seed")
  ) %>%
  filter(!is.na(Position), Mutation_Type != "")

# Get sample columns
sample_cols <- setdiff(names(data), c("miRNA name", "pos:mut"))

# Convert to long format (ignoring NAs from VAF filter)
data_long <- data_clean %>%
  select(miRNA, Position, Mutation_Type, Region, all_of(sample_cols)) %>%
  pivot_longer(
    cols = all_of(sample_cols),
    names_to = "Sample",
    values_to = "Count"
  ) %>%
  filter(!is.na(Count), Count > 0)  # NAs are filtered values

cat(sprintf("   ✅ Long format: %s rows (after removing NAs from VAF filter)\n", 
            format(nrow(data_long), big.mark = ",")))

# Calculate metrics
sample_metrics <- data_long %>%
  group_by(Sample, Mutation_Type) %>%
  summarise(
    N_SNVs = n(),
    Total_Counts = sum(Count),
    Mean_Count = mean(Count),
    SD_Count = sd(Count),
    Max_Count = max(Count),
    .groups = "drop"
  )

position_metrics <- data_long %>%
  group_by(Position, Mutation_Type) %>%
  summarise(
    N_SNVs = n(),
    Total_Counts = sum(Count),
    Mean_Count = mean(Count),
    SD_Count = sd(Count),
    .groups = "drop"
  )

# ============================================================================
# 2. QC FIGURES (4 figures showing filter impact)
# ============================================================================

cat("\n🎨 Generating QC Figures...\n")

# QC FIG 1: VAF Distribution (before filtering)
cat("   [1/4] VAF distribution...\n")

qc_fig1 <- ggplot(filter_report, aes(x = VAF)) +
  geom_histogram(bins = 50, fill = "#D62728", alpha = 0.7, color = "white") +
  geom_vline(xintercept = 0.5, linetype = "dashed", color = "#2c3e50", linewidth = 1.2) +
  annotate("rect", xmin = 0.5, xmax = 1, ymin = -Inf, ymax = Inf, 
           fill = "#D62728", alpha = 0.15) +
  annotate("text", x = 0.75, y = Inf, label = "FILTERED\n(Artifacts)", 
           vjust = 1.5, fontface = "bold", size = 5, color = "#D62728") +
  scale_x_continuous(labels = percent) +
  theme_classic(base_size = 14) +
  theme(
    axis.title = element_text(face = "bold", size = 15),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 17),
    plot.subtitle = element_text(hjust = 0.5, size = 13, color = "gray40")
  ) +
  labs(
    title = "QC FIGURE 1: VAF Distribution of Filtered Values",
    subtitle = sprintf("%s values with VAF >= 0.5 removed as artifacts", 
                      format(nrow(filter_report), big.mark = ",")),
    x = "Variant Allele Frequency (VAF)",
    y = "Count"
  )

ggsave(output_qc_fig1, qc_fig1, width = 14, height = 9, dpi = 150)

# QC FIG 2: Filter impact by mutation type
cat("   [2/4] Filter impact by type...\n")

stats_by_type <- read.csv(input_stats_by_type)

qc_fig2 <- ggplot(stats_by_type, aes(x = reorder(Mutation_Type, -N_Filtered), y = N_Filtered)) +
  geom_bar(stat = "identity", fill = "#667eea", alpha = 0.85) +
  geom_text(aes(label = format(N_Filtered, big.mark = ",")), 
            vjust = -0.5, fontface = "bold", size = 4) +
  theme_classic(base_size = 14) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold"),
    axis.title = element_text(face = "bold", size = 15),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 17),
    plot.subtitle = element_text(hjust = 0.5, size = 13, color = "gray40")
  ) +
  labs(
    title = "QC FIGURE 2: Filter Impact by Mutation Type",
    subtitle = "Number of filtered values (VAF >= 0.5) per mutation type",
    x = "Mutation Type",
    y = "# Filtered Values"
  )

ggsave(output_qc_fig2, qc_fig2, width = 14, height = 9, dpi = 150)

# QC FIG 3: Top affected miRNAs
cat("   [3/4] Top affected miRNAs...\n")

stats_by_mirna <- read.csv(input_stats_by_mirna)

qc_fig3 <- stats_by_mirna %>%
  arrange(desc(N_Filtered)) %>%
  slice(1:20) %>%
  ggplot(aes(x = reorder(miRNA, N_Filtered), y = N_Filtered)) +
  geom_bar(stat = "identity", fill = "#764ba2", alpha = 0.85) +
  geom_text(aes(label = N_Filtered), hjust = -0.3, fontface = "bold", size = 3.5) +
  coord_flip() +
  theme_classic(base_size = 13) +
  theme(
    axis.title = element_text(face = "bold", size = 14),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 16),
    plot.subtitle = element_text(hjust = 0.5, size = 12, color = "gray40")
  ) +
  labs(
    title = "QC FIGURE 3: Top 20 Most Affected miRNAs",
    subtitle = "miRNAs with most filtered values",
    x = "miRNA",
    y = "# Filtered Values"
  )

ggsave(output_qc_fig3, qc_fig3, width = 12, height = 10, dpi = 150)

# QC FIG 4: Before/After comparison
cat("   [4/4] Before/After comparison...\n")

comparison_data <- data.frame(
  Dataset = c("Original (Step 1)", "VAF-Filtered (Step 1.5)"),
  Total_Values = c(
    nrow(data_clean) * length(sample_cols),  # Approximate original
    nrow(data_long)  # After filtering (NAs removed)
  )
) %>%
  mutate(
    Pct_Remaining = Total_Values / max(Total_Values) * 100,
    Filtered = max(Total_Values) - Total_Values
  )

qc_fig4 <- ggplot(comparison_data, aes(x = Dataset, y = Total_Values / 1e6, fill = Dataset)) +
  geom_bar(stat = "identity", alpha = 0.85, width = 0.6) +
  geom_text(aes(label = sprintf("%.1fM\n(%.1f%%)", Total_Values/1e6, Pct_Remaining)), 
            vjust = -0.5, fontface = "bold", size = 5) +
  scale_fill_manual(values = c("Original (Step 1)" = "gray60", 
                               "VAF-Filtered (Step 1.5)" = "#2CA02C")) +
  theme_classic(base_size = 14) +
  theme(
    axis.title = element_text(face = "bold", size = 15),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 17),
    plot.subtitle = element_text(hjust = 0.5, size = 13, color = "gray40"),
    legend.position = "none"
  ) +
  labs(
    title = "QC FIGURE 4: Data Quality Before vs After VAF Filter",
    subtitle = sprintf("%s values filtered (%.1f%% of original)", 
                      format(nrow(filter_report), big.mark = ","),
                      nrow(filter_report) / (comparison_data$Total_Values[1]) * 100),
    x = NULL,
    y = "Total Valid Values (Millions)"
  )

ggsave(output_qc_fig4, qc_fig4, width = 12, height = 9, dpi = 150)

cat("   ✅ 4 QC figures saved\n")

# ============================================================================
# 3. DIAGNOSTIC FIGURES (same as Step 1, but with VAF-cleaned data)
# ============================================================================

cat("\n🎨 Generating Diagnostic Figures (same as Step 1)...\n")

# Ensure all mutation types present
all_types <- c("AT", "AG", "AC", "GC", "GT", "GA", "CG", "CA", "CT", "TA", "TG", "TC")
position_all <- position_metrics %>%
  complete(Position, Mutation_Type = all_types, fill = list(N_SNVs = 0, Total_Counts = 0))

# Order by frequency
type_order <- position_all %>%
  group_by(Mutation_Type) %>%
  summarise(Total = sum(N_SNVs, na.rm = TRUE)) %>%
  arrange(desc(Total)) %>%
  pull(Mutation_Type)

position_all$Mutation_Type <- factor(position_all$Mutation_Type, levels = type_order)

# FIG 1: Heatmap SNVs
cat("   [1/7] Heatmap SNVs...\n")

fig1 <- ggplot(position_all, aes(x = factor(Position), y = Mutation_Type, fill = N_SNVs)) +
  geom_tile(color = "white", size = 0.8) +
  geom_text(aes(label = ifelse(N_SNVs > 200, round(N_SNVs, 0), "")), 
            color = "white", fontface = "bold", size = 3) +
  scale_fill_gradient2(
    low = "white", mid = "#FF7F0E", high = "#D62728",
    midpoint = median(position_all$N_SNVs[position_all$N_SNVs > 0]),
    name = "# SNVs",
    labels = comma
  ) +
  theme_minimal(base_size = 13) +
  theme(
    axis.text.x = element_text(angle = 0, hjust = 0.5, face = "bold", size = 12),
    axis.text.y = element_text(face = "bold", size = 13, 
                              color = ifelse(levels(position_all$Mutation_Type) == "GT", "#D62728", "black")),
    axis.title = element_text(face = "bold", size = 15),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 17),
    plot.subtitle = element_text(hjust = 0.5, size = 13, color = "gray40"),
    panel.grid = element_blank(),
    legend.position = "right"
  ) +
  labs(
    title = "FIGURE 1: SNVs by Position - VAF-Filtered Data",
    subtitle = "12 mutation types | VAF >= 0.5 removed | G>T highlighted",
    x = "Position",
    y = "Mutation Type"
  )

ggsave(output_diag_fig1, fig1, width = 16, height = 10, dpi = 150)

# FIG 2: Heatmap Counts
cat("   [2/7] Heatmap Counts...\n")

fig2 <- ggplot(position_all, aes(x = factor(Position), y = Mutation_Type, fill = log10(Total_Counts + 1))) +
  geom_tile(color = "white", size = 0.8) +
  scale_fill_gradient2(
    low = "white", mid = "#9467BD", high = "#D62728",
    midpoint = median(log10(position_all$Total_Counts[position_all$Total_Counts > 0] + 1)),
    name = "log10(Counts)",
    labels = comma
  ) +
  theme_minimal(base_size = 13) +
  theme(
    axis.text.x = element_text(angle = 0, hjust = 0.5, face = "bold", size = 12),
    axis.text.y = element_text(face = "bold", size = 13,
                              color = ifelse(levels(position_all$Mutation_Type) == "GT", "#D62728", "black")),
    axis.title = element_text(face = "bold", size = 15),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 17),
    plot.subtitle = element_text(hjust = 0.5, size = 13, color = "gray40"),
    panel.grid = element_blank(),
    legend.position = "right"
  ) +
  labs(
    title = "FIGURE 2: Total Counts by Position - VAF-Filtered Data",
    subtitle = "Sequencing depth | Log scale | VAF >= 0.5 removed",
    x = "Position",
    y = "Mutation Type"
  )

ggsave(output_diag_fig2, fig2, width = 16, height = 10, dpi = 150)

# FIG 3 & 4: G Transversions
cat("   [3/7] G transversions - SNVs...\n")

g_only <- position_all %>%
  filter(Mutation_Type %in% c("GT", "GA", "GC"))

fig3 <- ggplot(g_only, aes(x = factor(Position), y = N_SNVs, fill = Mutation_Type)) +
  geom_bar(stat = "identity", position = "dodge", alpha = 0.85, width = 0.8) +
  geom_text(aes(label = ifelse(N_SNVs > 100, round(N_SNVs, 0), "")), 
            position = position_dodge(width = 0.8), vjust = -0.5, 
            fontface = "bold", size = 3) +
  scale_fill_manual(
    values = c("GT" = "#D62728", "GA" = "#1F77B4", "GC" = "#2CA02C"),
    labels = c("GT" = "G>T (Oxidation)", "GA" = "G>A", "GC" = "G>C"),
    name = "Mutation Type"
  ) +
  theme_classic(base_size = 14) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold"),
    axis.title = element_text(face = "bold", size = 15),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 17),
    plot.subtitle = element_text(hjust = 0.5, size = 13, color = "gray40"),
    legend.position = "bottom"
  ) +
  labs(
    title = "FIGURE 3: G Transversions - SNVs by Position",
    subtitle = "VAF-filtered data | G>T vs G>A vs G>C",
    x = "Position",
    y = "Number of SNVs"
  )

ggsave(output_diag_fig3, fig3, width = 16, height = 9, dpi = 150)

cat("   [4/7] G transversions - Counts...\n")

fig4 <- ggplot(g_only, aes(x = factor(Position), y = Total_Counts, fill = Mutation_Type)) +
  geom_bar(stat = "identity", position = "dodge", alpha = 0.85, width = 0.8) +
  scale_fill_manual(
    values = c("GT" = "#D62728", "GA" = "#1F77B4", "GC" = "#2CA02C"),
    labels = c("GT" = "G>T (Oxidation)", "GA" = "G>A", "GC" = "G>C"),
    name = "Mutation Type"
  ) +
  scale_y_continuous(labels = comma) +
  theme_classic(base_size = 14) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold"),
    axis.title = element_text(face = "bold", size = 15),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 17),
    plot.subtitle = element_text(hjust = 0.5, size = 13, color = "gray40"),
    legend.position = "bottom"
  ) +
  labs(
    title = "FIGURE 4: G Transversions - Counts by Position",
    subtitle = "VAF-filtered data | Sequencing depth",
    x = "Position",
    y = "Total Counts"
  )

ggsave(output_diag_fig4, fig4, width = 16, height = 9, dpi = 150)

# FIG 5: Bubble Plot
cat("   [5/7] Bubble plot...\n")

bubble_data <- sample_metrics %>%
  group_by(Mutation_Type) %>%
  summarise(
    Mean_SNVs = mean(N_SNVs),
    SD_SNVs = sd(N_SNVs),
    Mean_Counts = mean(Total_Counts),
    N_Samples = n(),
    .groups = "drop"
  ) %>%
  mutate(
    Is_GT = Mutation_Type == "GT",
    Category = case_when(
      Mutation_Type == "GT" ~ "G>T (Oxidation)",
      Mutation_Type %in% c("GA", "GC") ~ "Other G transv.",
      TRUE ~ "Other mutations"
    )
  )

fig5 <- ggplot(bubble_data, aes(x = Mean_SNVs, y = Mean_Counts, 
                                 size = SD_SNVs, color = Category, shape = Is_GT)) +
  geom_point(alpha = 0.75) +
  geom_text(aes(label = Mutation_Type), vjust = -2, fontface = "bold", size = 5, show.legend = FALSE) +
  scale_size_continuous(range = c(8, 30), name = "SD of SNVs\n(Variability)") +
  scale_color_manual(
    values = c("G>T (Oxidation)" = "#D62728", "Other G transv." = "#FF7F0E", "Other mutations" = "gray50"),
    name = "Category"
  ) +
  scale_shape_manual(values = c("TRUE" = 18, "FALSE" = 16), guide = "none") +
  scale_x_continuous(labels = comma) +
  scale_y_continuous(labels = comma) +
  theme_classic(base_size = 14) +
  theme(
    axis.title = element_text(face = "bold", size = 15),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 17),
    plot.subtitle = element_text(hjust = 0.5, size = 13, color = "gray40"),
    legend.position = "bottom",
    legend.box = "vertical"
  ) +
  labs(
    title = "FIGURE 5: SNVs vs Counts - VAF-Filtered Data",
    subtitle = "Size = SD | Diamond = G>T | After VAF QC",
    x = "Mean SNVs per Sample",
    y = "Mean Total Counts per Sample"
  )

ggsave(output_diag_fig5, fig5, width = 14, height = 11, dpi = 150)

# FIG 6: Violin Plots
cat("   [6/7] Violin plots...\n")

top8 <- bubble_data %>% arrange(desc(Mean_SNVs)) %>% slice(1:8) %>% pull(Mutation_Type)

sample_top8 <- sample_metrics %>%
  filter(Mutation_Type %in% top8) %>%
  mutate(
    Mutation_Type = factor(Mutation_Type, levels = rev(top8)),
    Category = case_when(
      Mutation_Type == "GT" ~ "G>T (Oxidation)",
      Mutation_Type %in% c("GA", "GC") ~ "Other G transv.",
      TRUE ~ "Other mutations"
    )
  )

p_viol_snvs <- ggplot(sample_top8, aes(x = Mutation_Type, y = N_SNVs, fill = Category)) +
  geom_violin(alpha = 0.7, trim = FALSE) +
  geom_boxplot(width = 0.2, alpha = 0.8, outlier.size = 0.5) +
  stat_summary(fun = mean, geom = "point", shape = 23, size = 3.5, fill = "white", color = "black") +
  scale_fill_manual(
    values = c("G>T (Oxidation)" = "#D62728", "Other G transv." = "#FF7F0E", "Other mutations" = "gray60"),
    name = ""
  ) +
  coord_flip() +
  theme_classic(base_size = 13) +
  theme(
    axis.title = element_text(face = "bold", size = 14),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 15),
    legend.position = "top"
  ) +
  labs(
    title = "A. SNVs Distribution per Sample (VAF-Filtered)",
    y = "# SNVs per Sample",
    x = "Mutation Type"
  )

p_viol_counts <- ggplot(sample_top8, aes(x = Mutation_Type, y = Total_Counts, fill = Category)) +
  geom_violin(alpha = 0.7, trim = FALSE) +
  geom_boxplot(width = 0.2, alpha = 0.8, outlier.size = 0.5) +
  stat_summary(fun = mean, geom = "point", shape = 23, size = 3.5, fill = "white", color = "black") +
  scale_fill_manual(
    values = c("G>T (Oxidation)" = "#D62728", "Other G transv." = "#FF7F0E", "Other mutations" = "gray60"),
    name = ""
  ) +
  scale_y_log10(labels = comma) +
  coord_flip() +
  theme_classic(base_size = 13) +
  theme(
    axis.title = element_text(face = "bold", size = 14),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 15),
    legend.position = "top"
  ) +
  labs(
    title = "B. Counts Distribution per Sample (log scale)",
    y = "Total Counts per Sample",
    x = "Mutation Type"
  )

fig6 <- p_viol_snvs / p_viol_counts +
  plot_annotation(
    title = "FIGURE 6: Complete Distributions - VAF-Filtered Data",
    theme = theme(
      plot.title = element_text(size = 17, face = "bold", hjust = 0.5)
    )
  )

ggsave(output_diag_fig6, fig6, width = 14, height = 11, dpi = 150)

# FIG 7: Fold Change
cat("   [7/7] Fold Change...\n")

gt_baseline <- bubble_data %>% filter(Mutation_Type == "GT")

fold_data <- bubble_data %>%
  mutate(
    Fold_SNVs = Mean_SNVs / gt_baseline$Mean_SNVs,
    Fold_Counts = Mean_Counts / gt_baseline$Mean_Counts
  ) %>%
  arrange(desc(Fold_SNVs))

fold_long <- fold_data %>%
  slice(1:10) %>%
  select(Mutation_Type, Category, Fold_SNVs, Fold_Counts) %>%
  pivot_longer(
    cols = c(Fold_SNVs, Fold_Counts),
    names_to = "Metric",
    values_to = "Fold"
  ) %>%
  mutate(
    Metric = factor(Metric, levels = c("Fold_SNVs", "Fold_Counts"),
                   labels = c("Fold SNVs", "Fold Counts"))
  )

fig7 <- ggplot(fold_long, aes(x = reorder(Mutation_Type, -Fold), y = Fold, fill = Metric)) +
  geom_bar(stat = "identity", position = "dodge", alpha = 0.85, width = 0.75) +
  geom_hline(yintercept = 1, linetype = "dashed", color = "#D62728", size = 1.3) +
  annotate("text", x = 8.5, y = 1.2, label = "G>T level", 
           color = "#D62728", fontface = "bold", size = 5) +
  scale_fill_manual(values = c("Fold SNVs" = "#667eea", "Fold Counts" = "#764ba2"), name = "") +
  theme_classic(base_size = 14) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold"),
    axis.title = element_text(face = "bold", size = 15),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 17),
    plot.subtitle = element_text(hjust = 0.5, size = 13, color = "gray40"),
    legend.position = "top"
  ) +
  labs(
    title = "FIGURE 7: Fold Change vs G>T - VAF-Filtered Data",
    subtitle = "Relative context after VAF QC | Top 10 types",
    x = "Mutation Type",
    y = "Fold Change (relative to G>T)"
  )

ggsave(output_diag_fig7, fig7, width = 16, height = 9, dpi = 150)

cat("   ✅ 7 diagnostic figures saved\n")

# ============================================================================
# 4. SAVE SUMMARY TABLES
# ============================================================================

cat("\n💾 Saving summary tables...\n")

write.csv(sample_metrics, output_sample_metrics, row.names = FALSE)
cat("   ✅", output_sample_metrics, "\n")

write.csv(position_metrics, output_position_metrics, row.names = FALSE)
cat("   ✅", output_position_metrics, "\n")

write.csv(bubble_data, output_mutation_summary, row.names = FALSE)
cat("   ✅", output_mutation_summary, "\n")

cat("   ✅ 3 summary tables saved\n")

# ============================================================================
# 5. FINAL SUMMARY
# ============================================================================

cat("\n╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║          ✅ STEP 1.5 FIGURES COMPLETED                              ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

cat("📊 FIGURES GENERATED:\n\n")
cat("   QC FIGURES (4):\n")
cat("   • QC_FIG1_VAF_DISTRIBUTION.png\n")
cat("   • QC_FIG2_FILTER_IMPACT.png\n")
cat("   • QC_FIG3_AFFECTED_MIRNAS.png\n")
cat("   • QC_FIG4_BEFORE_AFTER.png\n\n")

cat("   DIAGNOSTIC FIGURES (7):\n")
cat("   • STEP1.5_FIG1_HEATMAP_SNVS.png\n")
cat("   • STEP1.5_FIG2_HEATMAP_COUNTS.png\n")
cat("   • STEP1.5_FIG3_G_TRANSVERSIONS_SNVS.png\n")
cat("   • STEP1.5_FIG4_G_TRANSVERSIONS_COUNTS.png\n")
cat("   • STEP1.5_FIG5_BUBBLE_PLOT.png\n")
cat("   • STEP1.5_FIG6_VIOLIN_DISTRIBUTIONS.png\n")
cat("   • STEP1.5_FIG7_FOLD_CHANGE.png\n\n")

cat("✅ TOTAL: 11 figures + 3 tables generated\n\n")


# 🎯 STEP 1.5: GENERATE DIAGNOSTIC FIGURES - VAF-FILTERED DATA (Snakemake)
# ============================================================================
# Purpose: Generate diagnostic figures with VAF-cleaned data
# 
# Snakemake parameters:
#   input: 4 CSV tables (from Script 1)
#   output: 11 figures PNG + 3 tables CSV
# ============================================================================

library(ggplot2)
library(dplyr)
library(tidyr)
library(patchwork)
library(tibble)
library(scales)

cat("╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║     🎯 STEP 1.5: DIAGNOSTIC FIGURES - VAF-FILTERED DATA            ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

# ============================================================================
# GET SNAKEMAKE PARAMETERS
# ============================================================================

# Inputs (from Script 1)
input_filtered_data <- snakemake@input[["filtered_data"]]
input_filter_report <- snakemake@input[["filter_report"]]
input_stats_by_type <- snakemake@input[["stats_by_type"]]
input_stats_by_mirna <- snakemake@input[["stats_by_mirna"]]

# Outputs (11 figures + 3 tables)
output_qc_fig1 <- snakemake@output[["qc_fig1"]]
output_qc_fig2 <- snakemake@output[["qc_fig2"]]
output_qc_fig3 <- snakemake@output[["qc_fig3"]]
output_qc_fig4 <- snakemake@output[["qc_fig4"]]
output_diag_fig1 <- snakemake@output[["diag_fig1"]]
output_diag_fig2 <- snakemake@output[["diag_fig2"]]
output_diag_fig3 <- snakemake@output[["diag_fig3"]]
output_diag_fig4 <- snakemake@output[["diag_fig4"]]
output_diag_fig5 <- snakemake@output[["diag_fig5"]]
output_diag_fig6 <- snakemake@output[["diag_fig6"]]
output_diag_fig7 <- snakemake@output[["diag_fig7"]]
output_sample_metrics <- snakemake@output[["sample_metrics"]]
output_position_metrics <- snakemake@output[["position_metrics"]]
output_mutation_summary <- snakemake@output[["mutation_summary"]]

cat("📋 Parameters:\n")
cat("   Input filtered data:", input_filtered_data, "\n")
cat("   Input filter report:", input_filter_report, "\n")
cat("   Outputs: 11 figures + 3 tables\n\n")

# Ensure output directories exist
dir.create(dirname(output_qc_fig1), showWarnings = FALSE, recursive = TRUE)
dir.create(dirname(output_sample_metrics), showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# 1. LOAD VAF-FILTERED DATA
# ============================================================================

cat("📊 Loading VAF-filtered data...\n")
data <- read.csv(input_filtered_data, check.names = FALSE)

cat(sprintf("   ✅ Total rows: %s\n", format(nrow(data), big.mark = ",")))
cat(sprintf("   ✅ Columns: %d\n", ncol(data)))

# Load filter report
filter_report <- read.csv(input_filter_report)
cat(sprintf("   ✅ Filtered events: %s\n", format(nrow(filter_report), big.mark = ",")))

# Clean and prepare data (same as Step 1)
data_clean <- data %>%
  filter(`pos:mut` != "PM") %>%
  mutate(
    miRNA = `miRNA name`,
    pos_mut = `pos:mut`,
    Position = as.numeric(gsub(":.*", "", pos_mut)),
    Mutation_Type = gsub(".*:", "", pos_mut),
    Mutation_Type = gsub('"', '', Mutation_Type),
    Region = ifelse(Position >= 2 & Position <= 8, "Seed", "Non-Seed")
  ) %>%
  filter(!is.na(Position), Mutation_Type != "")

# Get sample columns
sample_cols <- setdiff(names(data), c("miRNA name", "pos:mut"))

# Convert to long format (ignoring NAs from VAF filter)
data_long <- data_clean %>%
  select(miRNA, Position, Mutation_Type, Region, all_of(sample_cols)) %>%
  pivot_longer(
    cols = all_of(sample_cols),
    names_to = "Sample",
    values_to = "Count"
  ) %>%
  filter(!is.na(Count), Count > 0)  # NAs are filtered values

cat(sprintf("   ✅ Long format: %s rows (after removing NAs from VAF filter)\n", 
            format(nrow(data_long), big.mark = ",")))

# Calculate metrics
sample_metrics <- data_long %>%
  group_by(Sample, Mutation_Type) %>%
  summarise(
    N_SNVs = n(),
    Total_Counts = sum(Count),
    Mean_Count = mean(Count),
    SD_Count = sd(Count),
    Max_Count = max(Count),
    .groups = "drop"
  )

position_metrics <- data_long %>%
  group_by(Position, Mutation_Type) %>%
  summarise(
    N_SNVs = n(),
    Total_Counts = sum(Count),
    Mean_Count = mean(Count),
    SD_Count = sd(Count),
    .groups = "drop"
  )

# ============================================================================
# 2. QC FIGURES (4 figures showing filter impact)
# ============================================================================

cat("\n🎨 Generating QC Figures...\n")

# QC FIG 1: VAF Distribution (before filtering)
cat("   [1/4] VAF distribution...\n")

qc_fig1 <- ggplot(filter_report, aes(x = VAF)) +
  geom_histogram(bins = 50, fill = "#D62728", alpha = 0.7, color = "white") +
  geom_vline(xintercept = 0.5, linetype = "dashed", color = "#2c3e50", linewidth = 1.2) +
  annotate("rect", xmin = 0.5, xmax = 1, ymin = -Inf, ymax = Inf, 
           fill = "#D62728", alpha = 0.15) +
  annotate("text", x = 0.75, y = Inf, label = "FILTERED\n(Artifacts)", 
           vjust = 1.5, fontface = "bold", size = 5, color = "#D62728") +
  scale_x_continuous(labels = percent) +
  theme_classic(base_size = 14) +
  theme(
    axis.title = element_text(face = "bold", size = 15),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 17),
    plot.subtitle = element_text(hjust = 0.5, size = 13, color = "gray40")
  ) +
  labs(
    title = "QC FIGURE 1: VAF Distribution of Filtered Values",
    subtitle = sprintf("%s values with VAF >= 0.5 removed as artifacts", 
                      format(nrow(filter_report), big.mark = ",")),
    x = "Variant Allele Frequency (VAF)",
    y = "Count"
  )

ggsave(output_qc_fig1, qc_fig1, width = 14, height = 9, dpi = 150)

# QC FIG 2: Filter impact by mutation type
cat("   [2/4] Filter impact by type...\n")

stats_by_type <- read.csv(input_stats_by_type)

qc_fig2 <- ggplot(stats_by_type, aes(x = reorder(Mutation_Type, -N_Filtered), y = N_Filtered)) +
  geom_bar(stat = "identity", fill = "#667eea", alpha = 0.85) +
  geom_text(aes(label = format(N_Filtered, big.mark = ",")), 
            vjust = -0.5, fontface = "bold", size = 4) +
  theme_classic(base_size = 14) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold"),
    axis.title = element_text(face = "bold", size = 15),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 17),
    plot.subtitle = element_text(hjust = 0.5, size = 13, color = "gray40")
  ) +
  labs(
    title = "QC FIGURE 2: Filter Impact by Mutation Type",
    subtitle = "Number of filtered values (VAF >= 0.5) per mutation type",
    x = "Mutation Type",
    y = "# Filtered Values"
  )

ggsave(output_qc_fig2, qc_fig2, width = 14, height = 9, dpi = 150)

# QC FIG 3: Top affected miRNAs
cat("   [3/4] Top affected miRNAs...\n")

stats_by_mirna <- read.csv(input_stats_by_mirna)

qc_fig3 <- stats_by_mirna %>%
  arrange(desc(N_Filtered)) %>%
  slice(1:20) %>%
  ggplot(aes(x = reorder(miRNA, N_Filtered), y = N_Filtered)) +
  geom_bar(stat = "identity", fill = "#764ba2", alpha = 0.85) +
  geom_text(aes(label = N_Filtered), hjust = -0.3, fontface = "bold", size = 3.5) +
  coord_flip() +
  theme_classic(base_size = 13) +
  theme(
    axis.title = element_text(face = "bold", size = 14),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 16),
    plot.subtitle = element_text(hjust = 0.5, size = 12, color = "gray40")
  ) +
  labs(
    title = "QC FIGURE 3: Top 20 Most Affected miRNAs",
    subtitle = "miRNAs with most filtered values",
    x = "miRNA",
    y = "# Filtered Values"
  )

ggsave(output_qc_fig3, qc_fig3, width = 12, height = 10, dpi = 150)

# QC FIG 4: Before/After comparison
cat("   [4/4] Before/After comparison...\n")

comparison_data <- data.frame(
  Dataset = c("Original (Step 1)", "VAF-Filtered (Step 1.5)"),
  Total_Values = c(
    nrow(data_clean) * length(sample_cols),  # Approximate original
    nrow(data_long)  # After filtering (NAs removed)
  )
) %>%
  mutate(
    Pct_Remaining = Total_Values / max(Total_Values) * 100,
    Filtered = max(Total_Values) - Total_Values
  )

qc_fig4 <- ggplot(comparison_data, aes(x = Dataset, y = Total_Values / 1e6, fill = Dataset)) +
  geom_bar(stat = "identity", alpha = 0.85, width = 0.6) +
  geom_text(aes(label = sprintf("%.1fM\n(%.1f%%)", Total_Values/1e6, Pct_Remaining)), 
            vjust = -0.5, fontface = "bold", size = 5) +
  scale_fill_manual(values = c("Original (Step 1)" = "gray60", 
                               "VAF-Filtered (Step 1.5)" = "#2CA02C")) +
  theme_classic(base_size = 14) +
  theme(
    axis.title = element_text(face = "bold", size = 15),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 17),
    plot.subtitle = element_text(hjust = 0.5, size = 13, color = "gray40"),
    legend.position = "none"
  ) +
  labs(
    title = "QC FIGURE 4: Data Quality Before vs After VAF Filter",
    subtitle = sprintf("%s values filtered (%.1f%% of original)", 
                      format(nrow(filter_report), big.mark = ","),
                      nrow(filter_report) / (comparison_data$Total_Values[1]) * 100),
    x = NULL,
    y = "Total Valid Values (Millions)"
  )

ggsave(output_qc_fig4, qc_fig4, width = 12, height = 9, dpi = 150)

cat("   ✅ 4 QC figures saved\n")

# ============================================================================
# 3. DIAGNOSTIC FIGURES (same as Step 1, but with VAF-cleaned data)
# ============================================================================

cat("\n🎨 Generating Diagnostic Figures (same as Step 1)...\n")

# Ensure all mutation types present
all_types <- c("AT", "AG", "AC", "GC", "GT", "GA", "CG", "CA", "CT", "TA", "TG", "TC")
position_all <- position_metrics %>%
  complete(Position, Mutation_Type = all_types, fill = list(N_SNVs = 0, Total_Counts = 0))

# Order by frequency
type_order <- position_all %>%
  group_by(Mutation_Type) %>%
  summarise(Total = sum(N_SNVs, na.rm = TRUE)) %>%
  arrange(desc(Total)) %>%
  pull(Mutation_Type)

position_all$Mutation_Type <- factor(position_all$Mutation_Type, levels = type_order)

# FIG 1: Heatmap SNVs
cat("   [1/7] Heatmap SNVs...\n")

fig1 <- ggplot(position_all, aes(x = factor(Position), y = Mutation_Type, fill = N_SNVs)) +
  geom_tile(color = "white", size = 0.8) +
  geom_text(aes(label = ifelse(N_SNVs > 200, round(N_SNVs, 0), "")), 
            color = "white", fontface = "bold", size = 3) +
  scale_fill_gradient2(
    low = "white", mid = "#FF7F0E", high = "#D62728",
    midpoint = median(position_all$N_SNVs[position_all$N_SNVs > 0]),
    name = "# SNVs",
    labels = comma
  ) +
  theme_minimal(base_size = 13) +
  theme(
    axis.text.x = element_text(angle = 0, hjust = 0.5, face = "bold", size = 12),
    axis.text.y = element_text(face = "bold", size = 13, 
                              color = ifelse(levels(position_all$Mutation_Type) == "GT", "#D62728", "black")),
    axis.title = element_text(face = "bold", size = 15),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 17),
    plot.subtitle = element_text(hjust = 0.5, size = 13, color = "gray40"),
    panel.grid = element_blank(),
    legend.position = "right"
  ) +
  labs(
    title = "FIGURE 1: SNVs by Position - VAF-Filtered Data",
    subtitle = "12 mutation types | VAF >= 0.5 removed | G>T highlighted",
    x = "Position",
    y = "Mutation Type"
  )

ggsave(output_diag_fig1, fig1, width = 16, height = 10, dpi = 150)

# FIG 2: Heatmap Counts
cat("   [2/7] Heatmap Counts...\n")

fig2 <- ggplot(position_all, aes(x = factor(Position), y = Mutation_Type, fill = log10(Total_Counts + 1))) +
  geom_tile(color = "white", size = 0.8) +
  scale_fill_gradient2(
    low = "white", mid = "#9467BD", high = "#D62728",
    midpoint = median(log10(position_all$Total_Counts[position_all$Total_Counts > 0] + 1)),
    name = "log10(Counts)",
    labels = comma
  ) +
  theme_minimal(base_size = 13) +
  theme(
    axis.text.x = element_text(angle = 0, hjust = 0.5, face = "bold", size = 12),
    axis.text.y = element_text(face = "bold", size = 13,
                              color = ifelse(levels(position_all$Mutation_Type) == "GT", "#D62728", "black")),
    axis.title = element_text(face = "bold", size = 15),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 17),
    plot.subtitle = element_text(hjust = 0.5, size = 13, color = "gray40"),
    panel.grid = element_blank(),
    legend.position = "right"
  ) +
  labs(
    title = "FIGURE 2: Total Counts by Position - VAF-Filtered Data",
    subtitle = "Sequencing depth | Log scale | VAF >= 0.5 removed",
    x = "Position",
    y = "Mutation Type"
  )

ggsave(output_diag_fig2, fig2, width = 16, height = 10, dpi = 150)

# FIG 3 & 4: G Transversions
cat("   [3/7] G transversions - SNVs...\n")

g_only <- position_all %>%
  filter(Mutation_Type %in% c("GT", "GA", "GC"))

fig3 <- ggplot(g_only, aes(x = factor(Position), y = N_SNVs, fill = Mutation_Type)) +
  geom_bar(stat = "identity", position = "dodge", alpha = 0.85, width = 0.8) +
  geom_text(aes(label = ifelse(N_SNVs > 100, round(N_SNVs, 0), "")), 
            position = position_dodge(width = 0.8), vjust = -0.5, 
            fontface = "bold", size = 3) +
  scale_fill_manual(
    values = c("GT" = "#D62728", "GA" = "#1F77B4", "GC" = "#2CA02C"),
    labels = c("GT" = "G>T (Oxidation)", "GA" = "G>A", "GC" = "G>C"),
    name = "Mutation Type"
  ) +
  theme_classic(base_size = 14) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold"),
    axis.title = element_text(face = "bold", size = 15),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 17),
    plot.subtitle = element_text(hjust = 0.5, size = 13, color = "gray40"),
    legend.position = "bottom"
  ) +
  labs(
    title = "FIGURE 3: G Transversions - SNVs by Position",
    subtitle = "VAF-filtered data | G>T vs G>A vs G>C",
    x = "Position",
    y = "Number of SNVs"
  )

ggsave(output_diag_fig3, fig3, width = 16, height = 9, dpi = 150)

cat("   [4/7] G transversions - Counts...\n")

fig4 <- ggplot(g_only, aes(x = factor(Position), y = Total_Counts, fill = Mutation_Type)) +
  geom_bar(stat = "identity", position = "dodge", alpha = 0.85, width = 0.8) +
  scale_fill_manual(
    values = c("GT" = "#D62728", "GA" = "#1F77B4", "GC" = "#2CA02C"),
    labels = c("GT" = "G>T (Oxidation)", "GA" = "G>A", "GC" = "G>C"),
    name = "Mutation Type"
  ) +
  scale_y_continuous(labels = comma) +
  theme_classic(base_size = 14) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold"),
    axis.title = element_text(face = "bold", size = 15),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 17),
    plot.subtitle = element_text(hjust = 0.5, size = 13, color = "gray40"),
    legend.position = "bottom"
  ) +
  labs(
    title = "FIGURE 4: G Transversions - Counts by Position",
    subtitle = "VAF-filtered data | Sequencing depth",
    x = "Position",
    y = "Total Counts"
  )

ggsave(output_diag_fig4, fig4, width = 16, height = 9, dpi = 150)

# FIG 5: Bubble Plot
cat("   [5/7] Bubble plot...\n")

bubble_data <- sample_metrics %>%
  group_by(Mutation_Type) %>%
  summarise(
    Mean_SNVs = mean(N_SNVs),
    SD_SNVs = sd(N_SNVs),
    Mean_Counts = mean(Total_Counts),
    N_Samples = n(),
    .groups = "drop"
  ) %>%
  mutate(
    Is_GT = Mutation_Type == "GT",
    Category = case_when(
      Mutation_Type == "GT" ~ "G>T (Oxidation)",
      Mutation_Type %in% c("GA", "GC") ~ "Other G transv.",
      TRUE ~ "Other mutations"
    )
  )

fig5 <- ggplot(bubble_data, aes(x = Mean_SNVs, y = Mean_Counts, 
                                 size = SD_SNVs, color = Category, shape = Is_GT)) +
  geom_point(alpha = 0.75) +
  geom_text(aes(label = Mutation_Type), vjust = -2, fontface = "bold", size = 5, show.legend = FALSE) +
  scale_size_continuous(range = c(8, 30), name = "SD of SNVs\n(Variability)") +
  scale_color_manual(
    values = c("G>T (Oxidation)" = "#D62728", "Other G transv." = "#FF7F0E", "Other mutations" = "gray50"),
    name = "Category"
  ) +
  scale_shape_manual(values = c("TRUE" = 18, "FALSE" = 16), guide = "none") +
  scale_x_continuous(labels = comma) +
  scale_y_continuous(labels = comma) +
  theme_classic(base_size = 14) +
  theme(
    axis.title = element_text(face = "bold", size = 15),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 17),
    plot.subtitle = element_text(hjust = 0.5, size = 13, color = "gray40"),
    legend.position = "bottom",
    legend.box = "vertical"
  ) +
  labs(
    title = "FIGURE 5: SNVs vs Counts - VAF-Filtered Data",
    subtitle = "Size = SD | Diamond = G>T | After VAF QC",
    x = "Mean SNVs per Sample",
    y = "Mean Total Counts per Sample"
  )

ggsave(output_diag_fig5, fig5, width = 14, height = 11, dpi = 150)

# FIG 6: Violin Plots
cat("   [6/7] Violin plots...\n")

top8 <- bubble_data %>% arrange(desc(Mean_SNVs)) %>% slice(1:8) %>% pull(Mutation_Type)

sample_top8 <- sample_metrics %>%
  filter(Mutation_Type %in% top8) %>%
  mutate(
    Mutation_Type = factor(Mutation_Type, levels = rev(top8)),
    Category = case_when(
      Mutation_Type == "GT" ~ "G>T (Oxidation)",
      Mutation_Type %in% c("GA", "GC") ~ "Other G transv.",
      TRUE ~ "Other mutations"
    )
  )

p_viol_snvs <- ggplot(sample_top8, aes(x = Mutation_Type, y = N_SNVs, fill = Category)) +
  geom_violin(alpha = 0.7, trim = FALSE) +
  geom_boxplot(width = 0.2, alpha = 0.8, outlier.size = 0.5) +
  stat_summary(fun = mean, geom = "point", shape = 23, size = 3.5, fill = "white", color = "black") +
  scale_fill_manual(
    values = c("G>T (Oxidation)" = "#D62728", "Other G transv." = "#FF7F0E", "Other mutations" = "gray60"),
    name = ""
  ) +
  coord_flip() +
  theme_classic(base_size = 13) +
  theme(
    axis.title = element_text(face = "bold", size = 14),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 15),
    legend.position = "top"
  ) +
  labs(
    title = "A. SNVs Distribution per Sample (VAF-Filtered)",
    y = "# SNVs per Sample",
    x = "Mutation Type"
  )

p_viol_counts <- ggplot(sample_top8, aes(x = Mutation_Type, y = Total_Counts, fill = Category)) +
  geom_violin(alpha = 0.7, trim = FALSE) +
  geom_boxplot(width = 0.2, alpha = 0.8, outlier.size = 0.5) +
  stat_summary(fun = mean, geom = "point", shape = 23, size = 3.5, fill = "white", color = "black") +
  scale_fill_manual(
    values = c("G>T (Oxidation)" = "#D62728", "Other G transv." = "#FF7F0E", "Other mutations" = "gray60"),
    name = ""
  ) +
  scale_y_log10(labels = comma) +
  coord_flip() +
  theme_classic(base_size = 13) +
  theme(
    axis.title = element_text(face = "bold", size = 14),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 15),
    legend.position = "top"
  ) +
  labs(
    title = "B. Counts Distribution per Sample (log scale)",
    y = "Total Counts per Sample",
    x = "Mutation Type"
  )

fig6 <- p_viol_snvs / p_viol_counts +
  plot_annotation(
    title = "FIGURE 6: Complete Distributions - VAF-Filtered Data",
    theme = theme(
      plot.title = element_text(size = 17, face = "bold", hjust = 0.5)
    )
  )

ggsave(output_diag_fig6, fig6, width = 14, height = 11, dpi = 150)

# FIG 7: Fold Change
cat("   [7/7] Fold Change...\n")

gt_baseline <- bubble_data %>% filter(Mutation_Type == "GT")

fold_data <- bubble_data %>%
  mutate(
    Fold_SNVs = Mean_SNVs / gt_baseline$Mean_SNVs,
    Fold_Counts = Mean_Counts / gt_baseline$Mean_Counts
  ) %>%
  arrange(desc(Fold_SNVs))

fold_long <- fold_data %>%
  slice(1:10) %>%
  select(Mutation_Type, Category, Fold_SNVs, Fold_Counts) %>%
  pivot_longer(
    cols = c(Fold_SNVs, Fold_Counts),
    names_to = "Metric",
    values_to = "Fold"
  ) %>%
  mutate(
    Metric = factor(Metric, levels = c("Fold_SNVs", "Fold_Counts"),
                   labels = c("Fold SNVs", "Fold Counts"))
  )

fig7 <- ggplot(fold_long, aes(x = reorder(Mutation_Type, -Fold), y = Fold, fill = Metric)) +
  geom_bar(stat = "identity", position = "dodge", alpha = 0.85, width = 0.75) +
  geom_hline(yintercept = 1, linetype = "dashed", color = "#D62728", size = 1.3) +
  annotate("text", x = 8.5, y = 1.2, label = "G>T level", 
           color = "#D62728", fontface = "bold", size = 5) +
  scale_fill_manual(values = c("Fold SNVs" = "#667eea", "Fold Counts" = "#764ba2"), name = "") +
  theme_classic(base_size = 14) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold"),
    axis.title = element_text(face = "bold", size = 15),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 17),
    plot.subtitle = element_text(hjust = 0.5, size = 13, color = "gray40"),
    legend.position = "top"
  ) +
  labs(
    title = "FIGURE 7: Fold Change vs G>T - VAF-Filtered Data",
    subtitle = "Relative context after VAF QC | Top 10 types",
    x = "Mutation Type",
    y = "Fold Change (relative to G>T)"
  )

ggsave(output_diag_fig7, fig7, width = 16, height = 9, dpi = 150)

cat("   ✅ 7 diagnostic figures saved\n")

# ============================================================================
# 4. SAVE SUMMARY TABLES
# ============================================================================

cat("\n💾 Saving summary tables...\n")

write.csv(sample_metrics, output_sample_metrics, row.names = FALSE)
cat("   ✅", output_sample_metrics, "\n")

write.csv(position_metrics, output_position_metrics, row.names = FALSE)
cat("   ✅", output_position_metrics, "\n")

write.csv(bubble_data, output_mutation_summary, row.names = FALSE)
cat("   ✅", output_mutation_summary, "\n")

cat("   ✅ 3 summary tables saved\n")

# ============================================================================
# 5. FINAL SUMMARY
# ============================================================================

cat("\n╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║          ✅ STEP 1.5 FIGURES COMPLETED                              ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

cat("📊 FIGURES GENERATED:\n\n")
cat("   QC FIGURES (4):\n")
cat("   • QC_FIG1_VAF_DISTRIBUTION.png\n")
cat("   • QC_FIG2_FILTER_IMPACT.png\n")
cat("   • QC_FIG3_AFFECTED_MIRNAS.png\n")
cat("   • QC_FIG4_BEFORE_AFTER.png\n\n")

cat("   DIAGNOSTIC FIGURES (7):\n")
cat("   • STEP1.5_FIG1_HEATMAP_SNVS.png\n")
cat("   • STEP1.5_FIG2_HEATMAP_COUNTS.png\n")
cat("   • STEP1.5_FIG3_G_TRANSVERSIONS_SNVS.png\n")
cat("   • STEP1.5_FIG4_G_TRANSVERSIONS_COUNTS.png\n")
cat("   • STEP1.5_FIG5_BUBBLE_PLOT.png\n")
cat("   • STEP1.5_FIG6_VIOLIN_DISTRIBUTIONS.png\n")
cat("   • STEP1.5_FIG7_FOLD_CHANGE.png\n\n")

cat("✅ TOTAL: 11 figures + 3 tables generated\n\n")


# 🎯 STEP 1.5: GENERATE DIAGNOSTIC FIGURES - VAF-FILTERED DATA (Snakemake)
# ============================================================================
# Purpose: Generate diagnostic figures with VAF-cleaned data
# 
# Snakemake parameters:
#   input: 4 CSV tables (from Script 1)
#   output: 11 figures PNG + 3 tables CSV
# ============================================================================

library(ggplot2)
library(dplyr)
library(tidyr)
library(patchwork)
library(tibble)
library(scales)

cat("╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║     🎯 STEP 1.5: DIAGNOSTIC FIGURES - VAF-FILTERED DATA            ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

# ============================================================================
# GET SNAKEMAKE PARAMETERS
# ============================================================================

# Inputs (from Script 1)
input_filtered_data <- snakemake@input[["filtered_data"]]
input_filter_report <- snakemake@input[["filter_report"]]
input_stats_by_type <- snakemake@input[["stats_by_type"]]
input_stats_by_mirna <- snakemake@input[["stats_by_mirna"]]

# Outputs (11 figures + 3 tables)
output_qc_fig1 <- snakemake@output[["qc_fig1"]]
output_qc_fig2 <- snakemake@output[["qc_fig2"]]
output_qc_fig3 <- snakemake@output[["qc_fig3"]]
output_qc_fig4 <- snakemake@output[["qc_fig4"]]
output_diag_fig1 <- snakemake@output[["diag_fig1"]]
output_diag_fig2 <- snakemake@output[["diag_fig2"]]
output_diag_fig3 <- snakemake@output[["diag_fig3"]]
output_diag_fig4 <- snakemake@output[["diag_fig4"]]
output_diag_fig5 <- snakemake@output[["diag_fig5"]]
output_diag_fig6 <- snakemake@output[["diag_fig6"]]
output_diag_fig7 <- snakemake@output[["diag_fig7"]]
output_sample_metrics <- snakemake@output[["sample_metrics"]]
output_position_metrics <- snakemake@output[["position_metrics"]]
output_mutation_summary <- snakemake@output[["mutation_summary"]]

cat("📋 Parameters:\n")
cat("   Input filtered data:", input_filtered_data, "\n")
cat("   Input filter report:", input_filter_report, "\n")
cat("   Outputs: 11 figures + 3 tables\n\n")

# Ensure output directories exist
dir.create(dirname(output_qc_fig1), showWarnings = FALSE, recursive = TRUE)
dir.create(dirname(output_sample_metrics), showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# 1. LOAD VAF-FILTERED DATA
# ============================================================================

cat("📊 Loading VAF-filtered data...\n")
data <- read.csv(input_filtered_data, check.names = FALSE)

cat(sprintf("   ✅ Total rows: %s\n", format(nrow(data), big.mark = ",")))
cat(sprintf("   ✅ Columns: %d\n", ncol(data)))

# Load filter report
filter_report <- read.csv(input_filter_report)
cat(sprintf("   ✅ Filtered events: %s\n", format(nrow(filter_report), big.mark = ",")))

# Clean and prepare data (same as Step 1)
data_clean <- data %>%
  filter(`pos:mut` != "PM") %>%
  mutate(
    miRNA = `miRNA name`,
    pos_mut = `pos:mut`,
    Position = as.numeric(gsub(":.*", "", pos_mut)),
    Mutation_Type = gsub(".*:", "", pos_mut),
    Mutation_Type = gsub('"', '', Mutation_Type),
    Region = ifelse(Position >= 2 & Position <= 8, "Seed", "Non-Seed")
  ) %>%
  filter(!is.na(Position), Mutation_Type != "")

# Get sample columns
sample_cols <- setdiff(names(data), c("miRNA name", "pos:mut"))

# Convert to long format (ignoring NAs from VAF filter)
data_long <- data_clean %>%
  select(miRNA, Position, Mutation_Type, Region, all_of(sample_cols)) %>%
  pivot_longer(
    cols = all_of(sample_cols),
    names_to = "Sample",
    values_to = "Count"
  ) %>%
  filter(!is.na(Count), Count > 0)  # NAs are filtered values

cat(sprintf("   ✅ Long format: %s rows (after removing NAs from VAF filter)\n", 
            format(nrow(data_long), big.mark = ",")))

# Calculate metrics
sample_metrics <- data_long %>%
  group_by(Sample, Mutation_Type) %>%
  summarise(
    N_SNVs = n(),
    Total_Counts = sum(Count),
    Mean_Count = mean(Count),
    SD_Count = sd(Count),
    Max_Count = max(Count),
    .groups = "drop"
  )

position_metrics <- data_long %>%
  group_by(Position, Mutation_Type) %>%
  summarise(
    N_SNVs = n(),
    Total_Counts = sum(Count),
    Mean_Count = mean(Count),
    SD_Count = sd(Count),
    .groups = "drop"
  )

# ============================================================================
# 2. QC FIGURES (4 figures showing filter impact)
# ============================================================================

cat("\n🎨 Generating QC Figures...\n")

# QC FIG 1: VAF Distribution (before filtering)
cat("   [1/4] VAF distribution...\n")

qc_fig1 <- ggplot(filter_report, aes(x = VAF)) +
  geom_histogram(bins = 50, fill = "#D62728", alpha = 0.7, color = "white") +
  geom_vline(xintercept = 0.5, linetype = "dashed", color = "#2c3e50", linewidth = 1.2) +
  annotate("rect", xmin = 0.5, xmax = 1, ymin = -Inf, ymax = Inf, 
           fill = "#D62728", alpha = 0.15) +
  annotate("text", x = 0.75, y = Inf, label = "FILTERED\n(Artifacts)", 
           vjust = 1.5, fontface = "bold", size = 5, color = "#D62728") +
  scale_x_continuous(labels = percent) +
  theme_classic(base_size = 14) +
  theme(
    axis.title = element_text(face = "bold", size = 15),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 17),
    plot.subtitle = element_text(hjust = 0.5, size = 13, color = "gray40")
  ) +
  labs(
    title = "QC FIGURE 1: VAF Distribution of Filtered Values",
    subtitle = sprintf("%s values with VAF >= 0.5 removed as artifacts", 
                      format(nrow(filter_report), big.mark = ",")),
    x = "Variant Allele Frequency (VAF)",
    y = "Count"
  )

ggsave(output_qc_fig1, qc_fig1, width = 14, height = 9, dpi = 150)

# QC FIG 2: Filter impact by mutation type
cat("   [2/4] Filter impact by type...\n")

stats_by_type <- read.csv(input_stats_by_type)

qc_fig2 <- ggplot(stats_by_type, aes(x = reorder(Mutation_Type, -N_Filtered), y = N_Filtered)) +
  geom_bar(stat = "identity", fill = "#667eea", alpha = 0.85) +
  geom_text(aes(label = format(N_Filtered, big.mark = ",")), 
            vjust = -0.5, fontface = "bold", size = 4) +
  theme_classic(base_size = 14) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold"),
    axis.title = element_text(face = "bold", size = 15),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 17),
    plot.subtitle = element_text(hjust = 0.5, size = 13, color = "gray40")
  ) +
  labs(
    title = "QC FIGURE 2: Filter Impact by Mutation Type",
    subtitle = "Number of filtered values (VAF >= 0.5) per mutation type",
    x = "Mutation Type",
    y = "# Filtered Values"
  )

ggsave(output_qc_fig2, qc_fig2, width = 14, height = 9, dpi = 150)

# QC FIG 3: Top affected miRNAs
cat("   [3/4] Top affected miRNAs...\n")

stats_by_mirna <- read.csv(input_stats_by_mirna)

qc_fig3 <- stats_by_mirna %>%
  arrange(desc(N_Filtered)) %>%
  slice(1:20) %>%
  ggplot(aes(x = reorder(miRNA, N_Filtered), y = N_Filtered)) +
  geom_bar(stat = "identity", fill = "#764ba2", alpha = 0.85) +
  geom_text(aes(label = N_Filtered), hjust = -0.3, fontface = "bold", size = 3.5) +
  coord_flip() +
  theme_classic(base_size = 13) +
  theme(
    axis.title = element_text(face = "bold", size = 14),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 16),
    plot.subtitle = element_text(hjust = 0.5, size = 12, color = "gray40")
  ) +
  labs(
    title = "QC FIGURE 3: Top 20 Most Affected miRNAs",
    subtitle = "miRNAs with most filtered values",
    x = "miRNA",
    y = "# Filtered Values"
  )

ggsave(output_qc_fig3, qc_fig3, width = 12, height = 10, dpi = 150)

# QC FIG 4: Before/After comparison
cat("   [4/4] Before/After comparison...\n")

comparison_data <- data.frame(
  Dataset = c("Original (Step 1)", "VAF-Filtered (Step 1.5)"),
  Total_Values = c(
    nrow(data_clean) * length(sample_cols),  # Approximate original
    nrow(data_long)  # After filtering (NAs removed)
  )
) %>%
  mutate(
    Pct_Remaining = Total_Values / max(Total_Values) * 100,
    Filtered = max(Total_Values) - Total_Values
  )

qc_fig4 <- ggplot(comparison_data, aes(x = Dataset, y = Total_Values / 1e6, fill = Dataset)) +
  geom_bar(stat = "identity", alpha = 0.85, width = 0.6) +
  geom_text(aes(label = sprintf("%.1fM\n(%.1f%%)", Total_Values/1e6, Pct_Remaining)), 
            vjust = -0.5, fontface = "bold", size = 5) +
  scale_fill_manual(values = c("Original (Step 1)" = "gray60", 
                               "VAF-Filtered (Step 1.5)" = "#2CA02C")) +
  theme_classic(base_size = 14) +
  theme(
    axis.title = element_text(face = "bold", size = 15),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 17),
    plot.subtitle = element_text(hjust = 0.5, size = 13, color = "gray40"),
    legend.position = "none"
  ) +
  labs(
    title = "QC FIGURE 4: Data Quality Before vs After VAF Filter",
    subtitle = sprintf("%s values filtered (%.1f%% of original)", 
                      format(nrow(filter_report), big.mark = ","),
                      nrow(filter_report) / (comparison_data$Total_Values[1]) * 100),
    x = NULL,
    y = "Total Valid Values (Millions)"
  )

ggsave(output_qc_fig4, qc_fig4, width = 12, height = 9, dpi = 150)

cat("   ✅ 4 QC figures saved\n")

# ============================================================================
# 3. DIAGNOSTIC FIGURES (same as Step 1, but with VAF-cleaned data)
# ============================================================================

cat("\n🎨 Generating Diagnostic Figures (same as Step 1)...\n")

# Ensure all mutation types present
all_types <- c("AT", "AG", "AC", "GC", "GT", "GA", "CG", "CA", "CT", "TA", "TG", "TC")
position_all <- position_metrics %>%
  complete(Position, Mutation_Type = all_types, fill = list(N_SNVs = 0, Total_Counts = 0))

# Order by frequency
type_order <- position_all %>%
  group_by(Mutation_Type) %>%
  summarise(Total = sum(N_SNVs, na.rm = TRUE)) %>%
  arrange(desc(Total)) %>%
  pull(Mutation_Type)

position_all$Mutation_Type <- factor(position_all$Mutation_Type, levels = type_order)

# FIG 1: Heatmap SNVs
cat("   [1/7] Heatmap SNVs...\n")

fig1 <- ggplot(position_all, aes(x = factor(Position), y = Mutation_Type, fill = N_SNVs)) +
  geom_tile(color = "white", size = 0.8) +
  geom_text(aes(label = ifelse(N_SNVs > 200, round(N_SNVs, 0), "")), 
            color = "white", fontface = "bold", size = 3) +
  scale_fill_gradient2(
    low = "white", mid = "#FF7F0E", high = "#D62728",
    midpoint = median(position_all$N_SNVs[position_all$N_SNVs > 0]),
    name = "# SNVs",
    labels = comma
  ) +
  theme_minimal(base_size = 13) +
  theme(
    axis.text.x = element_text(angle = 0, hjust = 0.5, face = "bold", size = 12),
    axis.text.y = element_text(face = "bold", size = 13, 
                              color = ifelse(levels(position_all$Mutation_Type) == "GT", "#D62728", "black")),
    axis.title = element_text(face = "bold", size = 15),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 17),
    plot.subtitle = element_text(hjust = 0.5, size = 13, color = "gray40"),
    panel.grid = element_blank(),
    legend.position = "right"
  ) +
  labs(
    title = "FIGURE 1: SNVs by Position - VAF-Filtered Data",
    subtitle = "12 mutation types | VAF >= 0.5 removed | G>T highlighted",
    x = "Position",
    y = "Mutation Type"
  )

ggsave(output_diag_fig1, fig1, width = 16, height = 10, dpi = 150)

# FIG 2: Heatmap Counts
cat("   [2/7] Heatmap Counts...\n")

fig2 <- ggplot(position_all, aes(x = factor(Position), y = Mutation_Type, fill = log10(Total_Counts + 1))) +
  geom_tile(color = "white", size = 0.8) +
  scale_fill_gradient2(
    low = "white", mid = "#9467BD", high = "#D62728",
    midpoint = median(log10(position_all$Total_Counts[position_all$Total_Counts > 0] + 1)),
    name = "log10(Counts)",
    labels = comma
  ) +
  theme_minimal(base_size = 13) +
  theme(
    axis.text.x = element_text(angle = 0, hjust = 0.5, face = "bold", size = 12),
    axis.text.y = element_text(face = "bold", size = 13,
                              color = ifelse(levels(position_all$Mutation_Type) == "GT", "#D62728", "black")),
    axis.title = element_text(face = "bold", size = 15),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 17),
    plot.subtitle = element_text(hjust = 0.5, size = 13, color = "gray40"),
    panel.grid = element_blank(),
    legend.position = "right"
  ) +
  labs(
    title = "FIGURE 2: Total Counts by Position - VAF-Filtered Data",
    subtitle = "Sequencing depth | Log scale | VAF >= 0.5 removed",
    x = "Position",
    y = "Mutation Type"
  )

ggsave(output_diag_fig2, fig2, width = 16, height = 10, dpi = 150)

# FIG 3 & 4: G Transversions
cat("   [3/7] G transversions - SNVs...\n")

g_only <- position_all %>%
  filter(Mutation_Type %in% c("GT", "GA", "GC"))

fig3 <- ggplot(g_only, aes(x = factor(Position), y = N_SNVs, fill = Mutation_Type)) +
  geom_bar(stat = "identity", position = "dodge", alpha = 0.85, width = 0.8) +
  geom_text(aes(label = ifelse(N_SNVs > 100, round(N_SNVs, 0), "")), 
            position = position_dodge(width = 0.8), vjust = -0.5, 
            fontface = "bold", size = 3) +
  scale_fill_manual(
    values = c("GT" = "#D62728", "GA" = "#1F77B4", "GC" = "#2CA02C"),
    labels = c("GT" = "G>T (Oxidation)", "GA" = "G>A", "GC" = "G>C"),
    name = "Mutation Type"
  ) +
  theme_classic(base_size = 14) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold"),
    axis.title = element_text(face = "bold", size = 15),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 17),
    plot.subtitle = element_text(hjust = 0.5, size = 13, color = "gray40"),
    legend.position = "bottom"
  ) +
  labs(
    title = "FIGURE 3: G Transversions - SNVs by Position",
    subtitle = "VAF-filtered data | G>T vs G>A vs G>C",
    x = "Position",
    y = "Number of SNVs"
  )

ggsave(output_diag_fig3, fig3, width = 16, height = 9, dpi = 150)

cat("   [4/7] G transversions - Counts...\n")

fig4 <- ggplot(g_only, aes(x = factor(Position), y = Total_Counts, fill = Mutation_Type)) +
  geom_bar(stat = "identity", position = "dodge", alpha = 0.85, width = 0.8) +
  scale_fill_manual(
    values = c("GT" = "#D62728", "GA" = "#1F77B4", "GC" = "#2CA02C"),
    labels = c("GT" = "G>T (Oxidation)", "GA" = "G>A", "GC" = "G>C"),
    name = "Mutation Type"
  ) +
  scale_y_continuous(labels = comma) +
  theme_classic(base_size = 14) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold"),
    axis.title = element_text(face = "bold", size = 15),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 17),
    plot.subtitle = element_text(hjust = 0.5, size = 13, color = "gray40"),
    legend.position = "bottom"
  ) +
  labs(
    title = "FIGURE 4: G Transversions - Counts by Position",
    subtitle = "VAF-filtered data | Sequencing depth",
    x = "Position",
    y = "Total Counts"
  )

ggsave(output_diag_fig4, fig4, width = 16, height = 9, dpi = 150)

# FIG 5: Bubble Plot
cat("   [5/7] Bubble plot...\n")

bubble_data <- sample_metrics %>%
  group_by(Mutation_Type) %>%
  summarise(
    Mean_SNVs = mean(N_SNVs),
    SD_SNVs = sd(N_SNVs),
    Mean_Counts = mean(Total_Counts),
    N_Samples = n(),
    .groups = "drop"
  ) %>%
  mutate(
    Is_GT = Mutation_Type == "GT",
    Category = case_when(
      Mutation_Type == "GT" ~ "G>T (Oxidation)",
      Mutation_Type %in% c("GA", "GC") ~ "Other G transv.",
      TRUE ~ "Other mutations"
    )
  )

fig5 <- ggplot(bubble_data, aes(x = Mean_SNVs, y = Mean_Counts, 
                                 size = SD_SNVs, color = Category, shape = Is_GT)) +
  geom_point(alpha = 0.75) +
  geom_text(aes(label = Mutation_Type), vjust = -2, fontface = "bold", size = 5, show.legend = FALSE) +
  scale_size_continuous(range = c(8, 30), name = "SD of SNVs\n(Variability)") +
  scale_color_manual(
    values = c("G>T (Oxidation)" = "#D62728", "Other G transv." = "#FF7F0E", "Other mutations" = "gray50"),
    name = "Category"
  ) +
  scale_shape_manual(values = c("TRUE" = 18, "FALSE" = 16), guide = "none") +
  scale_x_continuous(labels = comma) +
  scale_y_continuous(labels = comma) +
  theme_classic(base_size = 14) +
  theme(
    axis.title = element_text(face = "bold", size = 15),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 17),
    plot.subtitle = element_text(hjust = 0.5, size = 13, color = "gray40"),
    legend.position = "bottom",
    legend.box = "vertical"
  ) +
  labs(
    title = "FIGURE 5: SNVs vs Counts - VAF-Filtered Data",
    subtitle = "Size = SD | Diamond = G>T | After VAF QC",
    x = "Mean SNVs per Sample",
    y = "Mean Total Counts per Sample"
  )

ggsave(output_diag_fig5, fig5, width = 14, height = 11, dpi = 150)

# FIG 6: Violin Plots
cat("   [6/7] Violin plots...\n")

top8 <- bubble_data %>% arrange(desc(Mean_SNVs)) %>% slice(1:8) %>% pull(Mutation_Type)

sample_top8 <- sample_metrics %>%
  filter(Mutation_Type %in% top8) %>%
  mutate(
    Mutation_Type = factor(Mutation_Type, levels = rev(top8)),
    Category = case_when(
      Mutation_Type == "GT" ~ "G>T (Oxidation)",
      Mutation_Type %in% c("GA", "GC") ~ "Other G transv.",
      TRUE ~ "Other mutations"
    )
  )

p_viol_snvs <- ggplot(sample_top8, aes(x = Mutation_Type, y = N_SNVs, fill = Category)) +
  geom_violin(alpha = 0.7, trim = FALSE) +
  geom_boxplot(width = 0.2, alpha = 0.8, outlier.size = 0.5) +
  stat_summary(fun = mean, geom = "point", shape = 23, size = 3.5, fill = "white", color = "black") +
  scale_fill_manual(
    values = c("G>T (Oxidation)" = "#D62728", "Other G transv." = "#FF7F0E", "Other mutations" = "gray60"),
    name = ""
  ) +
  coord_flip() +
  theme_classic(base_size = 13) +
  theme(
    axis.title = element_text(face = "bold", size = 14),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 15),
    legend.position = "top"
  ) +
  labs(
    title = "A. SNVs Distribution per Sample (VAF-Filtered)",
    y = "# SNVs per Sample",
    x = "Mutation Type"
  )

p_viol_counts <- ggplot(sample_top8, aes(x = Mutation_Type, y = Total_Counts, fill = Category)) +
  geom_violin(alpha = 0.7, trim = FALSE) +
  geom_boxplot(width = 0.2, alpha = 0.8, outlier.size = 0.5) +
  stat_summary(fun = mean, geom = "point", shape = 23, size = 3.5, fill = "white", color = "black") +
  scale_fill_manual(
    values = c("G>T (Oxidation)" = "#D62728", "Other G transv." = "#FF7F0E", "Other mutations" = "gray60"),
    name = ""
  ) +
  scale_y_log10(labels = comma) +
  coord_flip() +
  theme_classic(base_size = 13) +
  theme(
    axis.title = element_text(face = "bold", size = 14),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 15),
    legend.position = "top"
  ) +
  labs(
    title = "B. Counts Distribution per Sample (log scale)",
    y = "Total Counts per Sample",
    x = "Mutation Type"
  )

fig6 <- p_viol_snvs / p_viol_counts +
  plot_annotation(
    title = "FIGURE 6: Complete Distributions - VAF-Filtered Data",
    theme = theme(
      plot.title = element_text(size = 17, face = "bold", hjust = 0.5)
    )
  )

ggsave(output_diag_fig6, fig6, width = 14, height = 11, dpi = 150)

# FIG 7: Fold Change
cat("   [7/7] Fold Change...\n")

gt_baseline <- bubble_data %>% filter(Mutation_Type == "GT")

fold_data <- bubble_data %>%
  mutate(
    Fold_SNVs = Mean_SNVs / gt_baseline$Mean_SNVs,
    Fold_Counts = Mean_Counts / gt_baseline$Mean_Counts
  ) %>%
  arrange(desc(Fold_SNVs))

fold_long <- fold_data %>%
  slice(1:10) %>%
  select(Mutation_Type, Category, Fold_SNVs, Fold_Counts) %>%
  pivot_longer(
    cols = c(Fold_SNVs, Fold_Counts),
    names_to = "Metric",
    values_to = "Fold"
  ) %>%
  mutate(
    Metric = factor(Metric, levels = c("Fold_SNVs", "Fold_Counts"),
                   labels = c("Fold SNVs", "Fold Counts"))
  )

fig7 <- ggplot(fold_long, aes(x = reorder(Mutation_Type, -Fold), y = Fold, fill = Metric)) +
  geom_bar(stat = "identity", position = "dodge", alpha = 0.85, width = 0.75) +
  geom_hline(yintercept = 1, linetype = "dashed", color = "#D62728", size = 1.3) +
  annotate("text", x = 8.5, y = 1.2, label = "G>T level", 
           color = "#D62728", fontface = "bold", size = 5) +
  scale_fill_manual(values = c("Fold SNVs" = "#667eea", "Fold Counts" = "#764ba2"), name = "") +
  theme_classic(base_size = 14) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold"),
    axis.title = element_text(face = "bold", size = 15),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 17),
    plot.subtitle = element_text(hjust = 0.5, size = 13, color = "gray40"),
    legend.position = "top"
  ) +
  labs(
    title = "FIGURE 7: Fold Change vs G>T - VAF-Filtered Data",
    subtitle = "Relative context after VAF QC | Top 10 types",
    x = "Mutation Type",
    y = "Fold Change (relative to G>T)"
  )

ggsave(output_diag_fig7, fig7, width = 16, height = 9, dpi = 150)

cat("   ✅ 7 diagnostic figures saved\n")

# ============================================================================
# 4. SAVE SUMMARY TABLES
# ============================================================================

cat("\n💾 Saving summary tables...\n")

write.csv(sample_metrics, output_sample_metrics, row.names = FALSE)
cat("   ✅", output_sample_metrics, "\n")

write.csv(position_metrics, output_position_metrics, row.names = FALSE)
cat("   ✅", output_position_metrics, "\n")

write.csv(bubble_data, output_mutation_summary, row.names = FALSE)
cat("   ✅", output_mutation_summary, "\n")

cat("   ✅ 3 summary tables saved\n")

# ============================================================================
# 5. FINAL SUMMARY
# ============================================================================

cat("\n╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║          ✅ STEP 1.5 FIGURES COMPLETED                              ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

cat("📊 FIGURES GENERATED:\n\n")
cat("   QC FIGURES (4):\n")
cat("   • QC_FIG1_VAF_DISTRIBUTION.png\n")
cat("   • QC_FIG2_FILTER_IMPACT.png\n")
cat("   • QC_FIG3_AFFECTED_MIRNAS.png\n")
cat("   • QC_FIG4_BEFORE_AFTER.png\n\n")

cat("   DIAGNOSTIC FIGURES (7):\n")
cat("   • STEP1.5_FIG1_HEATMAP_SNVS.png\n")
cat("   • STEP1.5_FIG2_HEATMAP_COUNTS.png\n")
cat("   • STEP1.5_FIG3_G_TRANSVERSIONS_SNVS.png\n")
cat("   • STEP1.5_FIG4_G_TRANSVERSIONS_COUNTS.png\n")
cat("   • STEP1.5_FIG5_BUBBLE_PLOT.png\n")
cat("   • STEP1.5_FIG6_VIOLIN_DISTRIBUTIONS.png\n")
cat("   • STEP1.5_FIG7_FOLD_CHANGE.png\n\n")

cat("✅ TOTAL: 11 figures + 3 tables generated\n\n")

