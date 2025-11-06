#!/usr/bin/env Rscript
# ============================================================================
# STEP 8.4: Individual miRNA Analysis
# ============================================================================
# Purpose: Generate detailed plots for top interesting miRNAs
#          - Positional profiles per miRNA
#          - ALS vs Control comparison per miRNA
#          - Context enrichment per miRNA
# ============================================================================

# Suppress renv messages
options(renv.verbose = FALSE)

# Load required libraries
suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(stringr)
  library(ggplot2)
  library(patchwork)
})

# Get Snakemake parameters
input_vaf_filtered <- snakemake@input[["vaf_filtered"]]
input_context_summary <- snakemake@input[["context_summary"]]
input_statistical <- snakemake@input[["statistical"]]
output_figures_dir <- snakemake@params[["output_figures"]]
functions_common <- snakemake@input[["functions"]]

# Load common functions
source(functions_common, local = TRUE)

# Get config
config <- snakemake@config
seed_start <- if (!is.null(config$analysis$seed_region$start)) config$analysis$seed_region$start else 2
seed_end <- if (!is.null(config$analysis$seed_region$end)) config$analysis$seed_region$end else 8
color_gt <- if (!is.null(config$analysis$colors$gt)) config$analysis$colors$gt else "#D62728"
color_als <- if (!is.null(config$analysis$colors$als)) config$analysis$colors$als else "#D62728"
color_control <- if (!is.null(config$analysis$colors$control)) config$analysis$colors$control else "grey60"
top_n_mirnas <- if (!is.null(config$analysis$top_n_mirnas)) config$analysis$top_n_mirnas else 10

log_info("═══════════════════════════════════════════════════════════")
log_info("  STEP 8.4: Individual miRNA Analysis")
log_info("═══════════════════════════════════════════════════════════")

# ============================================================================
# LOAD DATA
# ============================================================================

log_subsection("Loading data")

data <- read_csv(input_vaf_filtered, show_col_types = FALSE)
context_summary <- read_csv(input_context_summary, show_col_types = FALSE)
statistical <- read_csv(input_statistical, show_col_types = FALSE)

# Normalize column names
if ("miRNA name" %in% colnames(data) && !"miRNA_name" %in% colnames(data)) {
  data$miRNA_name <- data$`miRNA name`
}
if ("pos:mut" %in% colnames(data) && !"pos.mut" %in% colnames(data)) {
  data$pos.mut <- data$`pos:mut`
}

# Identify sample columns
metadata_cols <- c("miRNA_name", "miRNA name", "pos.mut", "pos:mut", 
                   "mutation_type", "position")
all_cols <- colnames(data)
sample_cols <- all_cols[!all_cols %in% metadata_cols]

# Generate metadata
metadata <- data.frame(
  Sample_ID = sample_cols,
  Group = ifelse(
    grepl("Magen-ALS|ALS|als|Amyotrophic|motor", sample_cols, ignore.case = TRUE),
    "ALS",
    ifelse(
      grepl("Magen-control|Magen-Control|Control|control|Ctrl|CTRL|healthy|Healthy|Normal|normal", 
            sample_cols, ignore.case = TRUE),
      "Control",
      "Unknown"
    )
  ),
  stringsAsFactors = FALSE
)

log_success(paste("Data loaded:", nrow(data), "SNVs,", length(sample_cols), "samples"))

# ============================================================================
# IDENTIFY TOP INTERESTING miRNAs
# ============================================================================

log_subsection("Identifying top interesting miRNAs")

# Criteria 1: Most G>T mutations in seed region
gt_seed <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^[0-9]+"))) %>%
  filter(position >= seed_start, position <= seed_end) %>%
  group_by(miRNA_name) %>%
  summarise(n_gt_mutations = n(), .groups = "drop") %>%
  arrange(desc(n_gt_mutations))

# Criteria 2: Highest GpG context (from context summary)
gpg_top <- context_summary %>%
  filter(context_type == "GpG") %>%
  group_by(miRNA_name) %>%
  summarise(total_gpg = sum(n_mutations, na.rm = TRUE), .groups = "drop") %>%
  arrange(desc(total_gpg))

# Criteria 3: Highest statistical significance (from statistical results)
if ("log2_fold_change" %in% colnames(statistical) && "t_test_fdr" %in% colnames(statistical)) {
  sig_top <- statistical %>%
    filter(str_detect(pos.mut, ":GT$")) %>%
    mutate(position = as.numeric(str_extract(pos.mut, "^[0-9]+"))) %>%
    filter(position >= seed_start, position <= seed_end) %>%
    group_by(miRNA_name) %>%
    summarise(
      max_log2fc = max(abs(log2_fold_change), na.rm = TRUE),
      min_fdr = min(t_test_fdr, na.rm = TRUE),
      n_significant = sum(t_test_fdr < 0.05, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    arrange(desc(n_significant), desc(max_log2fc))
} else {
  sig_top <- tibble(miRNA_name = character(), max_log2fc = numeric(), min_fdr = numeric(), n_significant = numeric())
}

# Combine criteria (weighted scoring)
top_mirnas <- gt_seed %>%
  left_join(gpg_top, by = "miRNA_name") %>%
  left_join(sig_top, by = "miRNA_name") %>%
  mutate(
    total_gpg = ifelse(is.na(total_gpg), 0, total_gpg),
    max_log2fc = ifelse(is.na(max_log2fc), 0, max_log2fc),
    n_significant = ifelse(is.na(n_significant), 0, n_significant),
    # Combined score: mutations + GpG + significance
    combined_score = n_gt_mutations * 2 + total_gpg * 1.5 + n_significant * 3 + max_log2fc * 2
  ) %>%
  arrange(desc(combined_score)) %>%
  head(top_n_mirnas)

log_success(paste("Top", nrow(top_mirnas), "miRNAs identified"))

# ============================================================================
# GENERATE INDIVIDUAL miRNA PLOTS
# ============================================================================

log_subsection("Generating individual miRNA plots")

# Prepare data for plotting
data_long <- data %>%
  filter(miRNA_name %in% top_mirnas$miRNA_name) %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^[0-9]+"))) %>%
  select(miRNA_name, pos.mut, position, all_of(sample_cols)) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  left_join(metadata, by = "Sample_ID") %>%
  filter(!is.na(VAF), VAF > 0, Group != "Unknown")

# Create output directory
dir.create(output_figures_dir, showWarnings = FALSE, recursive = TRUE)

# Generate plot for each top miRNA
for (i in 1:min(nrow(top_mirnas), top_n_mirnas)) {
  mirna <- top_mirnas$miRNA_name[i]
  
  cat("\n📊 Generating plots for:", mirna, "\n")
  
  mirna_data <- data_long %>% filter(miRNA_name == mirna)
  
  if (nrow(mirna_data) == 0) next
  
  # Panel A: Positional profile (ALS vs Control)
  panel_a <- mirna_data %>%
    filter(position >= seed_start, position <= seed_end) %>%
    group_by(position, Group) %>%
    summarise(
      mean_vaf = mean(VAF, na.rm = TRUE),
      median_vaf = median(VAF, na.rm = TRUE),
      n_samples = n(),
      .groups = "drop"
    ) %>%
    ggplot(aes(x = position, y = mean_vaf, fill = Group)) +
    geom_bar(stat = "identity", position = "dodge", alpha = 0.8) +
    scale_fill_manual(values = c("ALS" = color_als, "Control" = color_control)) +
    labs(
      title = paste0("Positional G>T Profile: ", mirna),
      subtitle = paste("Seed region (positions", seed_start, "-", seed_end, ")"),
      x = "Position",
      y = "Mean VAF",
      fill = "Group"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 12, face = "bold"),
      plot.subtitle = element_text(size = 10, color = "grey50")
    )
  
  # Panel B: Context distribution for this miRNA
  mirna_context <- context_summary %>%
    filter(miRNA_name == mirna) %>%
    group_by(context_type) %>%
    summarise(total = sum(n_mutations, na.rm = TRUE), .groups = "drop")
  
  if (nrow(mirna_context) > 0) {
    panel_b <- mirna_context %>%
      ggplot(aes(x = reorder(context_type, total), y = total, fill = context_type)) +
      geom_bar(stat = "identity", alpha = 0.8) +
      scale_fill_manual(values = c("GpG" = color_gt, "ApG" = "#FF7F0E", "UpG" = "#2CA02C", "CpG" = "#1F77B4")) +
      coord_flip() +
      labs(
        title = paste0("Context Distribution: ", mirna),
        x = "Context Type",
        y = "Number of Mutations",
        fill = "Context"
      ) +
      theme_minimal() +
      theme(
        plot.title = element_text(size = 12, face = "bold"),
        legend.position = "none"
      )
  } else {
    panel_b <- ggplot() + annotate("text", x = 0.5, y = 0.5, label = "No context data") + theme_void()
  }
  
  # Combine panels
  combined <- panel_a / panel_b + plot_layout(heights = c(2, 1))
  
  # Save individual figure (optional, we'll save summary comparison instead)
  # output_file <- file.path(output_figures_dir, paste0("S8_individual_", gsub("[^A-Za-z0-9]", "_", mirna), ".png"))
  # ggsave(output_file, combined, width = 12, height = 10, dpi = 300, bg = "white")
  
  cat("   ✅ Processed:", mirna, "\n")
}

# Save summary comparison plot
output_summary <- snakemake@output[["top_mirnas_comparison"]]

# ============================================================================
# GENERATE SUMMARY COMPARISON PLOT
# ============================================================================

log_subsection("Generating summary comparison plot")

# All top miRNAs comparison
summary_data <- data_long %>%
  filter(position >= seed_start, position <= seed_end) %>%
  group_by(miRNA_name, Group) %>%
  summarise(
    mean_vaf = mean(VAF, na.rm = TRUE),
    total_mutations = n(),
    .groups = "drop"
  ) %>%
  pivot_wider(names_from = Group, values_from = mean_vaf, values_fill = 0) %>%
  mutate(
    vaf_diff = ALS - Control,
    log2_fc = log2((ALS + 0.001) / (Control + 0.001))
  ) %>%
  left_join(top_mirnas %>% select(miRNA_name, n_gt_mutations, total_gpg, combined_score), by = "miRNA_name") %>%
  arrange(desc(combined_score))

# Plot: Top miRNAs comparison
summary_plot <- summary_data %>%
  head(15) %>%
  ggplot(aes(x = reorder(miRNA_name, combined_score), y = vaf_diff, fill = vaf_diff > 0)) +
  geom_bar(stat = "identity", alpha = 0.8) +
  scale_fill_manual(values = c("TRUE" = color_als, "FALSE" = color_control), guide = "none") +
  coord_flip() +
  labs(
    title = "Top miRNAs: ALS vs Control VAF Difference",
    subtitle = paste("Seed region (positions", seed_start, "-", seed_end, ") | Top 15 by combined score"),
    x = "miRNA",
    y = "VAF Difference (ALS - Control)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 12, face = "bold"),
    plot.subtitle = element_text(size = 10, color = "grey50")
  )

ggsave(output_summary, summary_plot, width = 12, height = 10, dpi = 300, bg = "white")

log_success(paste("Summary comparison saved:", output_summary))

# Save top miRNAs table
output_table <- snakemake@output[["top_mirnas_table"]]
dir.create(dirname(output_table), showWarnings = FALSE, recursive = TRUE)
write_csv(summary_data, output_table)

log_success("Step 8.4 completed successfully")

