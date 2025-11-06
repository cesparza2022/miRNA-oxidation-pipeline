#!/usr/bin/env Rscript
# ==============================================================================
# FIGURE 2.11: COMPLETE MUTATION SPECTRUM (12 TYPES)
# ==============================================================================
# Date: 2025-10-27
# Purpose: Analyze complete mutation spectrum beyond G>T
# Questions:
#   1. What is the distribution of ALL 12 mutation types?
#   2. Are there differences in mutation spectrum between ALS and Control?
#   3. Beyond G>T, which mutations are enriched in each group?
#   4. Is the mutation spectrum consistent with oxidative damage hypothesis?
#
# LOGIC & RATIONALE:
#   - We've focused on G>T (oxidation marker)
#   - BUT: Other mutations may reveal additional mechanisms
#   - Complete spectrum provides context for G>T dominance
#   - Chi-square test for spectrum differences between groups
#
# BIOLOGICAL CONTEXT:
#   - G>T = Oxidative damage (8-oxoG)
#   - C>T = Deamination (common in aging)
#   - T>C = UV damage (less relevant for miRNA)
#   - Other transversions = Various mechanisms
# ==============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggpubr)
  library(patchwork)
  library(scales)
})

# ============================================================================
# CONFIGURATION
# ============================================================================

input_file <- "final_processed_data_CLEAN.csv"
metadata_file <- "metadata.csv"
output_dir <- "figures_paso2_CLEAN"

dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# Define 12 mutation types
MUTATION_TYPES <- c("AT", "AG", "AC", 
                    "GT", "GA", "GC",
                    "CT", "CA", "CG",
                    "TA", "TG", "TC")

# Mutation categories
TRANSITIONS <- c("AG", "GA", "CT", "TC")  # Purine↔Purine, Pyrimidine↔Pyrimidine
TRANSVERSIONS <- c("AT", "AC", "GT", "GC", "CA", "CG", "TA", "TG")

# Color scheme (professional)
COLOR_ALS <- "#d32f2f"
COLOR_CONTROL <- "#1976d2"
COLOR_GT <- "#FF6B35"      # G>T (oxidation)
COLOR_CT <- "#4ECDC4"      # C>T (deamination)
COLOR_TRANSITION <- "#95E1D3"
COLOR_TRANSVERSION <- "#FFB6C1"

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
cat("📊 FIGURE 2.11: COMPLETE MUTATION SPECTRUM ANALYSIS\n")
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
# EXTRACT ALL 12 MUTATION TYPES
# ============================================================================

cat("📊 Extracting ALL mutation types...\n")

# Extract position and mutation type
data <- data %>%
  mutate(
    position = as.numeric(str_extract(pos.mut, "^[0-9]+")),
    mutation_type = str_extract(pos.mut, "[ACGT]+$")
  )

# Filter only the 12 standard mutation types
all_mutations <- data %>%
  filter(mutation_type %in% MUTATION_TYPES)

cat(sprintf("✅ Total mutations: %d SNVs\n\n", nrow(all_mutations)))

# Count by type
mutation_counts <- all_mutations %>%
  count(mutation_type) %>%
  arrange(desc(n)) %>%
  mutate(
    Proportion = n / sum(n) * 100,
    Category = case_when(
      mutation_type %in% TRANSITIONS ~ "Transition",
      mutation_type %in% TRANSVERSIONS ~ "Transversion",
      TRUE ~ "Other"
    )
  )

cat("📊 Mutation type distribution (SNV counts):\n")
print(as.data.frame(mutation_counts))
cat("\n")

# ============================================================================
# TRANSFORM TO LONG FORMAT WITH GROUPS
# ============================================================================

cat("📊 Transforming to long format...\n")

mut_long <- all_mutations %>%
  select(all_of(c("miRNA_name", "position", "mutation_type", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), 
               names_to = "Sample_ID", 
               values_to = "VAF") %>%
  left_join(metadata, by = "Sample_ID") %>%
  filter(!is.na(VAF), VAF > 0)

cat(sprintf("✅ Transformed: %d observations (VAF > 0)\n\n", nrow(mut_long)))

# ============================================================================
# CALCULATE SPECTRUM BY GROUP
# ============================================================================

cat("📊 Calculating mutation spectrum by group...\n")

# VAF-weighted (burden)
spectrum_vaf <- mut_long %>%
  group_by(Group, mutation_type) %>%
  summarise(
    Total_VAF = sum(VAF),
    N_mutations = n(),
    .groups = "drop"
  ) %>%
  group_by(Group) %>%
  mutate(
    Proportion_VAF = Total_VAF / sum(Total_VAF) * 100,
    Proportion_N = N_mutations / sum(N_mutations) * 100
  ) %>%
  ungroup()

cat("📊 Spectrum by group (VAF-weighted):\n")
spectrum_summary <- spectrum_vaf %>%
  arrange(Group, desc(Proportion_VAF)) %>%
  select(Group, mutation_type, Proportion_VAF, Proportion_N)

print(as.data.frame(spectrum_summary))
cat("\n")

# ============================================================================
# STATISTICAL TEST: CHI-SQUARE
# ============================================================================

cat("🔬 Testing spectrum difference between groups...\n")

# Create contingency table (VAF counts)
spectrum_table_vaf <- mut_long %>%
  group_by(Group, mutation_type) %>%
  summarise(Total_VAF = sum(VAF), .groups = "drop") %>%
  pivot_wider(names_from = Group, values_from = Total_VAF, values_fill = 0)

# Chi-square test (requires counts, so use N_mutations)
spectrum_table_n <- mut_long %>%
  group_by(Group, mutation_type) %>%
  summarise(N = n(), .groups = "drop") %>%
  pivot_wider(names_from = Group, values_from = N, values_fill = 0)

# Prepare matrix for chi-square
chi_matrix <- as.matrix(spectrum_table_n[, c("ALS", "Control")])
rownames(chi_matrix) <- spectrum_table_n$mutation_type

# Chi-square test
chi_test <- chisq.test(chi_matrix)

cat("✅ Chi-square test:\n")
cat(sprintf("   X² = %.2f, df = %d, p = %s\n",
            chi_test$statistic, chi_test$parameter, 
            format.pval(chi_test$p.value, digits = 3)))

if (chi_test$p.value < 0.05) {
  cat("   ✅ Significant difference in mutation spectrum\n\n")
} else {
  cat("   ⚠️ No significant difference in mutation spectrum\n\n")
}

# ============================================================================
# IDENTIFY TOP DIFFERENTIAL MUTATIONS
# ============================================================================

cat("📊 Identifying differential mutations...\n")

# Calculate fold-change (ALS vs Control)
spectrum_diff <- spectrum_vaf %>%
  select(Group, mutation_type, Proportion_VAF) %>%
  pivot_wider(names_from = Group, values_from = Proportion_VAF) %>%
  mutate(
    log2FC = log2((ALS + 0.01) / (Control + 0.01)),
    Difference = ALS - Control,
    Direction = ifelse(ALS > Control, "ALS enriched", "Control enriched")
  ) %>%
  arrange(desc(abs(Difference)))

cat("📊 Top differential mutations (by difference):\n")
print(as.data.frame(head(spectrum_diff, 10)))
cat("\n")

# ============================================================================
# TRANSITIONS VS TRANSVERSIONS
# ============================================================================

cat("📊 Analyzing transitions vs transversions...\n")

ts_tv <- mut_long %>%
  mutate(
    Category = case_when(
      mutation_type %in% TRANSITIONS ~ "Transition",
      mutation_type %in% TRANSVERSIONS ~ "Transversion",
      TRUE ~ "Other"
    )
  ) %>%
  group_by(Group, Category) %>%
  summarise(
    Total_VAF = sum(VAF),
    N = n(),
    .groups = "drop"
  ) %>%
  group_by(Group) %>%
  mutate(
    Proportion_VAF = Total_VAF / sum(Total_VAF) * 100,
    Proportion_N = N / sum(N) * 100
  )

cat("📊 Transitions vs Transversions:\n")
print(as.data.frame(ts_tv))
cat("\n")

# Calculate Ts/Tv ratio
ts_tv_ratio <- ts_tv %>%
  filter(Category != "Other") %>%
  select(Group, Category, Proportion_VAF) %>%
  pivot_wider(names_from = Category, values_from = Proportion_VAF) %>%
  mutate(Ts_Tv_ratio = Transition / Transversion)

cat("📊 Ts/Tv ratios:\n")
print(as.data.frame(ts_tv_ratio))
cat("\n")

# ============================================================================
# FIGURE 2.11A: COMPLETE SPECTRUM (STACKED BAR)
# ============================================================================

cat("📊 Creating Figure 2.11A: Complete spectrum...\n")

# Prepare data with ordering
spectrum_plot <- spectrum_vaf %>%
  mutate(
    mutation_type = factor(mutation_type, levels = MUTATION_TYPES)
  )

fig_2_11a <- ggplot(spectrum_plot, aes(x = Group, y = Proportion_VAF, fill = mutation_type)) +
  geom_col(alpha = 0.85, width = 0.6) +
  
  # Add percentage labels for major mutations (>5%)
  geom_text(data = spectrum_plot %>% filter(Proportion_VAF > 5),
            aes(label = sprintf("%.1f%%", Proportion_VAF)),
            position = position_stack(vjust = 0.5),
            size = 3, color = "white", fontface = "bold") +
  
  scale_fill_manual(
    values = c(
      "GT" = "#FF6B35",  # G>T (oxidation) - Orange
      "GA" = "#4ECDC4",  # G>A - Teal
      "GC" = "#95E1D3",  # G>C - Light green
      "CT" = "#F38181",  # C>T (deamination) - Pink
      "CA" = "#AA96DA",  # C>A - Purple
      "CG" = "#FCBAD3",  # C>G - Light pink
      "AT" = "#A8D8EA",  # A>T - Light blue
      "AG" = "#FFCCBC",  # A>G - Peach
      "AC" = "#C5E1A5",  # A>C - Light lime
      "TA" = "#FFE082",  # T>A - Yellow
      "TG" = "#BCAAA4",  # T>G - Brown
      "TC" = "#B0BEC5"   # T>C - Grey
    ),
    name = "Mutation Type"
  ) +
  
  labs(
    title = "A. Complete Mutation Spectrum",
    subtitle = sprintf("Chi-square: X² = %.1f, p = %s | All 12 mutation types",
                      chi_test$statistic, format.pval(chi_test$p.value, digits = 3)),
    x = "Group",
    y = "Proportion (%)",
    caption = "VAF-weighted proportions. G>T in orange (oxidation marker)."
  ) +
  
  theme_professional +
  guides(fill = guide_legend(nrow = 2))

ggsave(file.path(output_dir, "FIG_2.11A_COMPLETE_SPECTRUM.png"),
       plot = fig_2_11a, width = 10, height = 8, dpi = 300)

cat("✅ Figure 2.11A saved\n\n")

# ============================================================================
# FIGURE 2.11B: G-MUTATIONS DETAIL
# ============================================================================

cat("📊 Creating Figure 2.11B: G-mutations detail...\n")

g_mutations <- spectrum_vaf %>%
  filter(str_detect(mutation_type, "^G")) %>%
  mutate(
    mutation_type = factor(mutation_type, levels = c("GT", "GA", "GC"))
  )

fig_2_11b <- ggplot(g_mutations, aes(x = mutation_type, y = Proportion_VAF, fill = Group)) +
  geom_col(position = "dodge", alpha = 0.85, width = 0.7) +
  
  geom_text(aes(label = sprintf("%.1f%%", Proportion_VAF)),
            position = position_dodge(width = 0.7),
            vjust = -0.5, size = 3.5) +
  
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  
  coord_cartesian(ylim = c(0, max(g_mutations$Proportion_VAF) * 1.15)) +
  
  labs(
    title = "B. G-based Mutations Detail",
    subtitle = "Focus on oxidation-relevant mutations (G>T, G>A, G>C)",
    x = "Mutation Type",
    y = "Proportion (%)",
    fill = "Group"
  ) +
  
  theme_professional

ggsave(file.path(output_dir, "FIG_2.11B_G_MUTATIONS.png"),
       plot = fig_2_11b, width = 9, height = 7, dpi = 300)

cat("✅ Figure 2.11B saved\n\n")

# ============================================================================
# FIGURE 2.11C: TRANSITIONS VS TRANSVERSIONS
# ============================================================================

cat("📊 Creating Figure 2.11C: Ts vs Tv...\n")

fig_2_11c <- ggplot(ts_tv %>% filter(Category != "Other"), 
                    aes(x = Group, y = Proportion_VAF, fill = Category)) +
  geom_col(position = "fill", alpha = 0.85, width = 0.6) +
  
  geom_text(aes(label = sprintf("%.1f%%", Proportion_VAF)),
            position = position_fill(vjust = 0.5),
            size = 4, color = "white", fontface = "bold") +
  
  scale_fill_manual(
    values = c("Transition" = COLOR_TRANSITION, "Transversion" = COLOR_TRANSVERSION),
    name = "Category"
  ) +
  
  scale_y_continuous(labels = percent_format()) +
  
  labs(
    title = "C. Transitions vs Transversions",
    subtitle = sprintf("Ts/Tv ratio: ALS = %.2f, Control = %.2f",
                      ts_tv_ratio$Ts_Tv_ratio[ts_tv_ratio$Group == "ALS"],
                      ts_tv_ratio$Ts_Tv_ratio[ts_tv_ratio$Group == "Control"]),
    x = "Group",
    y = "Proportion",
    caption = "Transitions: A↔G, C↔T | Transversions: All others"
  ) +
  
  theme_professional

ggsave(file.path(output_dir, "FIG_2.11C_TS_TV.png"),
       plot = fig_2_11c, width = 9, height = 7, dpi = 300)

cat("✅ Figure 2.11C saved\n\n")

# ============================================================================
# FIGURE 2.11D: TOP 10 MUTATIONS RANKED
# ============================================================================

cat("📊 Creating Figure 2.11D: Top mutations ranking...\n")

top_mutations <- mutation_counts %>%
  arrange(desc(n)) %>%
  head(10) %>%
  mutate(
    mutation_type = factor(mutation_type, levels = rev(mutation_type)),
    Color = case_when(
      mutation_type == "GT" ~ "G>T (Oxidation)",
      mutation_type == "CT" ~ "C>T (Deamination)",
      TRUE ~ "Other"
    )
  )

fig_2_11d <- ggplot(top_mutations, aes(x = mutation_type, y = n, fill = Color)) +
  geom_col(alpha = 0.85, width = 0.7) +
  
  geom_text(aes(label = sprintf("%d\n(%.1f%%)", n, Proportion)),
            hjust = -0.1, size = 3.5) +
  
  coord_flip() +
  
  scale_fill_manual(
    values = c(
      "G>T (Oxidation)" = COLOR_GT,
      "C>T (Deamination)" = COLOR_CT,
      "Other" = "gray70"
    ),
    name = "Category"
  ) +
  
  coord_cartesian(xlim = c(0.5, 10.5), expand = FALSE) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  
  labs(
    title = "D. Top 10 Mutations Ranked",
    subtitle = "By total SNV count across all samples",
    x = "Mutation Type",
    y = "Number of SNVs"
  ) +
  
  theme_professional

ggsave(file.path(output_dir, "FIG_2.11D_TOP_MUTATIONS.png"),
       plot = fig_2_11d, width = 10, height = 7, dpi = 300)

cat("✅ Figure 2.11D saved\n\n")

# ============================================================================
# FIGURE 2.11_COMBINED
# ============================================================================

cat("📊 Creating combined figure...\n")

fig_2_11_combined <- (fig_2_11a | fig_2_11b) / (fig_2_11c | fig_2_11d) +
  plot_annotation(
    title = "Figure 2.11: Complete Mutation Spectrum Analysis",
    subtitle = "Distribution of all 12 mutation types",
    theme = theme(plot.title = element_text(face = "bold", size = 16))
  )

ggsave(file.path(output_dir, "FIG_2.11_COMBINED.png"),
       plot = fig_2_11_combined, width = 18, height = 14, dpi = 300)

cat("✅ Combined figure saved\n\n")

# ============================================================================
# SAVE STATISTICAL RESULTS
# ============================================================================

cat("💾 Saving statistical results...\n")

# 1. Complete spectrum by group
write.csv(spectrum_vaf,
          file.path(output_dir, "TABLE_2.11_spectrum_by_group.csv"),
          row.names = FALSE)

# 2. Chi-square test results
chi_results <- data.frame(
  Test = "Chi-square",
  Statistic = chi_test$statistic,
  DF = chi_test$parameter,
  Pvalue = chi_test$p.value,
  Interpretation = ifelse(chi_test$p.value < 0.05, 
                         "Significant difference", 
                         "No significant difference")
)

write.csv(chi_results,
          file.path(output_dir, "TABLE_2.11_chi_square_test.csv"),
          row.names = FALSE)

# 3. Differential mutations
write.csv(spectrum_diff,
          file.path(output_dir, "TABLE_2.11_differential_mutations.csv"),
          row.names = FALSE)

# 4. Ts/Tv ratios
write.csv(ts_tv_ratio,
          file.path(output_dir, "TABLE_2.11_ts_tv_ratios.csv"),
          row.names = FALSE)

# 5. Overall counts
write.csv(mutation_counts,
          file.path(output_dir, "TABLE_2.11_mutation_counts.csv"),
          row.names = FALSE)

cat("✅ All statistical results saved\n\n")

# ============================================================================
# SUMMARY REPORT
# ============================================================================

cat("\n")
cat(paste(rep("=", 80), collapse = ""), "\n")
cat("📊 FIGURE 2.11 GENERATION COMPLETE\n")
cat(paste(rep("=", 80), collapse = ""), "\n\n")

cat("✅ Generated figures:\n")
cat("   • FIG_2.11A_COMPLETE_SPECTRUM.png  - All 12 types (stacked)\n")
cat("   • FIG_2.11B_G_MUTATIONS.png        - G>T, G>A, G>C detail\n")
cat("   • FIG_2.11C_TS_TV.png              - Transitions vs Transversions\n")
cat("   • FIG_2.11D_TOP_MUTATIONS.png      - Top 10 ranked\n")
cat("   • FIG_2.11_COMBINED.png            - Combined (all 4) ⭐\n\n")

cat("✅ Statistical tables:\n")
cat("   • TABLE_2.11_spectrum_by_group.csv\n")
cat("   • TABLE_2.11_chi_square_test.csv\n")
cat("   • TABLE_2.11_differential_mutations.csv\n")
cat("   • TABLE_2.11_ts_tv_ratios.csv\n")
cat("   • TABLE_2.11_mutation_counts.csv\n\n")

cat("📊 Key Results:\n")
cat(sprintf("   G>T dominance: %.1f%% of all mutations\n",
            mutation_counts$Proportion[mutation_counts$mutation_type == "GT"]))
cat(sprintf("   Ts/Tv ratio ALS: %.2f\n",
            ts_tv_ratio$Ts_Tv_ratio[ts_tv_ratio$Group == "ALS"]))
cat(sprintf("   Ts/Tv ratio Control: %.2f\n",
            ts_tv_ratio$Ts_Tv_ratio[ts_tv_ratio$Group == "Control"]))
cat(sprintf("   Chi-square p-value: %s\n\n",
            format.pval(chi_test$p.value, digits = 3)))

cat("📊 Biological Interpretation:\n")

top_3 <- head(mutation_counts, 3)
cat(sprintf("   Top 3 mutations: %s (%.1f%%), %s (%.1f%%), %s (%.1f%%)\n",
            top_3$mutation_type[1], top_3$Proportion[1],
            top_3$mutation_type[2], top_3$Proportion[2],
            top_3$mutation_type[3], top_3$Proportion[3]))

if (mutation_counts$mutation_type[1] == "GT") {
  cat("   ✅ G>T is #1 mutation → Oxidation is dominant mechanism\n")
}

if (chi_test$p.value < 0.05) {
  cat("   ✅ Spectrum differs between groups → Different mechanisms\n")
} else {
  cat("   ⚠️ Spectrum similar between groups → Same mechanisms\n")
}

cat("\n")
cat(paste(rep("=", 80), collapse = ""), "\n")
cat("✅ ALL FILES SAVED TO:", output_dir, "\n")
cat(paste(rep("=", 80), collapse = ""), "\n\n")

