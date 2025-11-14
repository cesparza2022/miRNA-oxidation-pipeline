#!/usr/bin/env Rscript
# ============================================================================
# STEP 0: DATASET OVERVIEW
# ============================================================================
# Purpose: Produce descriptive statistics and visualizations of the processed
# miRNA dataset prior to any oxidation-specific filtering.
# 
# Key Distinctions:
#   - "Number of SNVs" (n_snvs): Count of unique SNV events (rows in dataset)
#   - "SNV Counts" (total_counts): Sum of read counts across all samples
#   - G>T mutations are ALWAYS highlighted in red (#D62728)
# 
# Style: Following Step 1.5 approach with heatmaps, bubble plots, violin plots
# Outputs:
#   - Sample-level summaries (SNVs detected, total reads, affected miRNAs)
#   - miRNA-level summaries (number of SNVs per miRNA, total reads)
#   - Mutation-type analysis with complex visualizations (heatmaps, bubble plots)
#   - Dataset coverage analysis (complementary to Step 1 positional analysis)
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(readr)
  library(stringr)
  library(RColorBrewer)
  library(scales)
  library(patchwork)
})

# Load shared helpers / logging utilities
source(snakemake@params[["functions"]], local = TRUE)

# Initialise logging ---------------------------------------------------------
log_file <- if (length(snakemake@log) > 0) snakemake@log[[1]] else {
  file.path(tempdir(), "step0_overview.log")
}
ensure_output_dir(dirname(log_file))
initialize_logging(log_file, context = "Step 0 - Dataset Overview")
log_section("STEP 0: Dataset Overview")

# I/O ------------------------------------------------------------------------
input_data <- snakemake@input[["data"]]
output_fig_samples   <- snakemake@output[["fig_samples"]]
output_fig_samples_box <- snakemake@output[["fig_samples_box"]]
output_fig_samples_group <- snakemake@output[["fig_samples_group"]]
output_fig_miRNA     <- snakemake@output[["fig_miRNA"]]
output_fig_mutation_bar  <- snakemake@output[["fig_mutation_bar"]]
output_fig_mutation_pie_snvs <- snakemake@output[["fig_mutation_pie_snvs"]]
output_fig_mutation_pie_counts <- snakemake@output[["fig_mutation_pie_counts"]]
output_fig_coverage  <- snakemake@output[["fig_coverage"]] # Replaces positional density
output_table_samples <- snakemake@output[["table_samples"]]
output_table_sample_group <- snakemake@output[["table_sample_group"]]
output_table_miRNA   <- snakemake@output[["table_miRNA"]]
output_table_mutation <- snakemake@output[["table_mutation"]]

ensure_output_dir(dirname(output_fig_samples))
ensure_output_dir(dirname(output_table_samples))

log_info(paste("Input file:", input_data))

# Load dataset ---------------------------------------------------------------
log_subsection("Loading processed dataset")
processed <- read_csv(input_data, show_col_types = FALSE)
log_success(paste("Loaded", nrow(processed), "rows and", ncol(processed), "columns"))

required_cols <- c("miRNA_name", "pos.mut")
missing_cols <- setdiff(required_cols, names(processed))
if (length(missing_cols) > 0) {
  handle_error(paste("Missing required columns:", paste(missing_cols, collapse = ", ")), 
               context = "Step 0 - Dataset Overview", exit_code = 1, log_file = log_file)
}

# Separate counts vs VAF columns --------------------------------------------
# ✅ DOCUMENTADO: processed_clean.csv contains:
#   - miRNA_name, pos.mut: Identification columns
#   - Sample columns: SNV counts (number of reads supporting each specific SNV)
#   - VAF_* columns: Variant Allele Frequency (if present)
# IMPORTANT: Sample columns contain SNV counts (not total miRNA counts)
# Each row represents one unique SNV event, and sample columns contain read counts for that specific SNV

count_cols <- names(processed)[
  !(names(processed) %in% required_cols) &
    !str_detect(names(processed), "^VAF_")
]

vaf_cols <- names(processed)[str_detect(names(processed), "^VAF_")]

if (length(count_cols) == 0) {
  handle_error("No count columns detected (columns without VAF_ prefix).", 
               context = "Step 0 - Dataset Overview", exit_code = 1, log_file = log_file)
}

log_info(paste("Detected", length(count_cols), "count columns and", length(vaf_cols), "VAF columns"))
log_info("NOTE: Count columns contain SNV counts (reads supporting each specific SNV), not total miRNA counts")

counts_matrix <- as.matrix(processed[count_cols])
counts_matrix[is.na(counts_matrix)] <- 0

# Helper to infer sample groups from column names ---------------------------
infer_sample_group <- function(sample_ids) {
  dplyr::case_when(
    str_detect(sample_ids, regex("longitudinal", ignore_case = TRUE)) ~ "ALS_longitudinal",
    str_detect(sample_ids, regex("ALS", ignore_case = TRUE)) ~ "ALS",
    str_detect(sample_ids, regex("control", ignore_case = TRUE)) ~ "Control",
    TRUE ~ "Unknown"
  )
}

group_labels <- infer_sample_group(count_cols)

# Sample-level summary ------------------------------------------------------
log_subsection("Computing sample-level summary")

# IMPORTANT: Distinguish between:
# - snvs_detected: NUMBER of unique SNVs (rows with count > 0)
# - total_counts: SUM of read counts (total reads)
sample_summary <- tibble(
  sample_id = count_cols,
  group = group_labels,
  total_read_counts = colSums(counts_matrix, na.rm = TRUE),  # Total reads
  n_snvs_detected = colSums(counts_matrix > 0, na.rm = TRUE),  # Number of unique SNVs
  n_mirnas_affected = apply(counts_matrix, 2, function(col) {
    sum(tapply(col > 0, processed$miRNA_name, any))
  })
)

write_csv(sample_summary, output_table_samples)
log_success(paste("Sample summary table written:", output_table_samples))

sample_group_summary <- sample_summary %>%
  group_by(group) %>%
  summarise(
    n_samples = n(),
    total_read_counts = sum(total_read_counts, na.rm = TRUE),
    mean_n_snvs = mean(n_snvs_detected, na.rm = TRUE),
    mean_n_mirnas = mean(n_mirnas_affected, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(n_samples))

write_csv(sample_group_summary, output_table_sample_group)
log_success(paste("Sample group summary table written:", output_table_sample_group))

# Create histogram facets - DISTINGUISHING counts vs number of SNVs
sample_summary_long <- sample_summary %>%
  pivot_longer(cols = c(total_read_counts, n_snvs_detected, n_mirnas_affected),
               names_to = "metric", values_to = "value") %>%
  mutate(metric = recode(metric,
                         total_read_counts = "Total read counts (sum of reads)",
                         n_snvs_detected = "Number of SNVs detected (unique SNV events)",
                         n_mirnas_affected = "Number of miRNAs with SNVs"),
         value = value + 1)  # offset for log scale

fig_samples <- ggplot(sample_summary_long, aes(x = value, fill = group)) +
  geom_histogram(alpha = 0.75, bins = 40, position = "identity") +
  scale_x_log10(labels = scales::comma) +
  scale_fill_brewer(palette = "Set2") +  # ✅ CORREGIDO: Usar Set2 para consistencia con fig_samples_group
  facet_wrap(~metric, scales = "free_y", ncol = 1) +
  labs(
    title = "Sample-level Distribution",
    subtitle = "Distinguishing: Total read counts (sum) vs Number of SNVs (unique events) vs Affected miRNAs",
    x = "Value (log10 scale)",
    y = "Number of samples",
    fill = "Group",
    caption = "Note: 'Number of SNVs' = count of unique SNV events per sample\n'Total read counts' = sum of all read counts per sample"
  ) +
  theme_professional +
  theme(plot.caption = element_text(size = 9, hjust = 0, color = "grey40"))

ggsave(output_fig_samples, fig_samples, width = 10, height = 12, dpi = 300, bg = "white")
log_success(paste("Sample summary figure saved:", output_fig_samples))

# Boxplot: Number of SNVs per sample by group
fig_samples_box <- sample_summary %>%
  mutate(group = forcats::fct_infreq(group), 
         n_snvs_plot = n_snvs_detected + 1) %>%
  ggplot(aes(x = group, y = n_snvs_plot, fill = group)) +
  geom_boxplot(alpha = 0.75, outlier.alpha = 0.4) +
  scale_y_log10(labels = scales::comma) +
  scale_fill_brewer(palette = "Set2") +  # ✅ CORREGIDO: Usar Set2 para consistencia con fig_samples_group
  labs(
    title = "Number of SNVs per Sample (by Group)",
    subtitle = "Number of unique SNV events detected per sample (log10 scale)",
    x = "Group",
    y = "Number of SNVs detected (log10)",
    fill = "Group",
    caption = "This shows the COUNT of unique SNV events, not the sum of read counts"
  ) +
  theme_professional +
  theme(legend.position = "none",
        plot.caption = element_text(size = 9, hjust = 0, color = "grey40"))

ggsave(output_fig_samples_box, fig_samples_box, width = 8, height = 6, dpi = 300, bg = "white")
log_success(paste("Sample boxplot figure saved:", output_fig_samples_box))

# Pie chart: Sample distribution by group
fig_samples_group <- sample_group_summary %>%
  mutate(prop = n_samples / sum(n_samples),
         label = sprintf("%.1f%%\n(n=%s)", prop * 100, comma(n_samples))) %>%  # ✅ CORREGIDO: Agregar porcentajes y conteos
  ggplot(aes(x = "", y = prop, fill = group)) +
  geom_col(width = 1, color = "white", linewidth = 0.5) +
  geom_text(aes(label = label), position = position_stack(vjust = 0.5), 
            color = "white", fontface = "bold", size = 4.5) +  # ✅ CORREGIDO: Agregar porcentajes en segmentos
  coord_polar(theta = "y") +
  scale_fill_brewer(palette = "Set2") +
  labs(
    title = "Proportion of Samples by Group",
    subtitle = "Distribution of samples across experimental groups",
    fill = "Group"
  ) +
  theme_void() +
  theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
        plot.subtitle = element_text(hjust = 0.5, size = 11, color = "grey50"))

ggsave(output_fig_samples_group, fig_samples_group, width = 6, height = 6, dpi = 300, bg = "white")
log_success(paste("Sample group pie chart saved:", output_fig_samples_group))

# miRNA-level summary -------------------------------------------------------
log_subsection("Computing miRNA-level summary")
row_indices <- split(seq_len(nrow(processed)), processed$miRNA_name)

# IMPORTANT: Distinguish between:
# - n_snvs: NUMBER of unique SNVs per miRNA (rows)
# - total_counts: SUM of read counts per miRNA (total reads)
mirna_summary <- tibble(
  miRNA_name = names(row_indices),
  n_snvs = lengths(row_indices),  # Number of unique SNVs
  total_read_counts = vapply(row_indices, function(idx) {
    sum(counts_matrix[idx, , drop = FALSE], na.rm = TRUE)
  }, numeric(1)),  # Sum of read counts
  n_samples_with_snv = vapply(row_indices, function(idx) {
    sum(colSums(counts_matrix[idx, , drop = FALSE] > 0) > 0)
  }, numeric(1))
) %>%
  arrange(desc(n_snvs))

write_csv(mirna_summary, output_table_miRNA)
log_success(paste("miRNA summary table written:", output_table_miRNA))

# Histogram: Distribution of number of SNVs per miRNA
fig_miRNA <- mirna_summary %>%
  mutate(n_snvs_plot = n_snvs + 1) %>%
  ggplot(aes(x = n_snvs_plot)) +
  geom_histogram(fill = "#6c757d", alpha = 0.8, bins = 40) +  # ✅ CORREGIDO: Color neutro (gris) en lugar de rojo, ya que no es específico de G>T
  scale_x_log10(breaks = scales::trans_breaks("log10", function(x) 10^x),
                labels = scales::trans_format("log10", scales::math_format(10^.x))) +
  labs(
    title = "Distribution of Number of SNVs per miRNA",
    subtitle = "Number of unique SNV events per miRNA (log10 scale)",
    x = "Number of SNVs per miRNA (log10)",
    y = "Number of miRNAs",
    caption = "This shows the COUNT of unique SNV events per miRNA, not the sum of read counts"
  ) +
  theme_professional +
  theme(plot.caption = element_text(size = 9, hjust = 0, color = "grey40"))

ggsave(output_fig_miRNA, fig_miRNA, width = 10, height = 6, dpi = 300, bg = "white")
log_success(paste("miRNA summary figure saved:", output_fig_miRNA))

# Mutation-type counts ------------------------------------------------------
log_subsection("Computing mutation-type distribution")
mutation_counts <- processed %>%
  mutate(
    mutation = str_to_upper(str_replace_na(str_extract(pos.mut, "(?<=:)[A-Z>]+"))),
    mutation = if_else(mutation == "PM", NA_character_, mutation),
    position = suppressWarnings(as.numeric(str_extract(pos.mut, "^[0-9]+")))
  )

row_total_counts <- rowSums(counts_matrix, na.rm = TRUE)

# IMPORTANT: Distinguish between:
# - n_snvs: NUMBER of unique SNVs (rows) per mutation type
# - total_counts: SUM of read counts per mutation type
mutation_summary <- tibble(
  mutation = mutation_counts$mutation,
  total_read_counts = row_total_counts,
  position = mutation_counts$position
) %>%
  filter(!is.na(mutation)) %>%
  group_by(mutation) %>%
  summarise(
    n_snvs = n(),  # Number of unique SNVs
    total_read_counts = sum(total_read_counts, na.rm = TRUE),  # Sum of read counts
    .groups = "drop"
  ) %>%
  arrange(desc(n_snvs))

write_csv(mutation_summary, output_table_mutation)
log_success(paste("Mutation summary table written:", output_table_mutation))

# Bar chart: Number of SNVs by mutation type (G>T highlighted in red)
mutation_colors <- ifelse(mutation_summary$mutation == "G>T", COLOR_GT, COLOR_CONTROL)
names(mutation_colors) <- mutation_summary$mutation

fig_mutation_bar <- mutation_summary %>%
  mutate(mutation = fct_reorder(mutation, n_snvs)) %>%
  ggplot(aes(x = mutation, y = n_snvs, fill = mutation)) +
  geom_col() +
  scale_fill_manual(values = mutation_colors) +
  coord_flip() +
  labs(
    title = "Number of SNVs by Mutation Type",
    subtitle = "Count of unique SNV events (not read counts)",
    x = "Mutation type",
    y = "Number of SNVs (unique events)",
    caption = "G>T (oxidation) highlighted in red. This shows the COUNT of unique SNV events, not the sum of read counts."
  ) +
  theme_professional +
  theme(legend.position = "none",
        plot.caption = element_text(size = 9, hjust = 0, color = "grey40"))

ggsave(output_fig_mutation_bar, fig_mutation_bar, width = 10, height = 8, dpi = 300, bg = "white")
log_success(paste("Mutation distribution figure saved:", output_fig_mutation_bar))

# ============================================================================
# COMPLEX VISUALIZATIONS: Overview-level (complementing Step 1.5, NOT repeating)
# ============================================================================
# Step 0: Overview SIN filtros - distribuciones, proporciones, caracterización básica
# Step 1.5: Diagnóstico CON filtros VAF - bubble plots, violin plots, heatmaps detallados
# 
# Step 0 NO debe tener:
#   - Bubble plots (eso es Step 1.5 FIG 5)
#   - Violin plots (eso es Step 1.5 FIG 6)
#   - Heatmaps por posición (eso es Step 1.5 FIG 1-2)
#
# Step 0 SÍ debe tener:
#   - Proporciones y porcentajes mejorados
#   - Comparaciones de representación (SNVs vs Counts)
#   - Visualizaciones de distribución general

# Create a professional color palette for mutations
get_mutation_palette <- function(mutations) {
  professional_colors <- c(
    "#2E86AB", "#A23B72", "#F18F01", "#C73E1D", "#6A994E", "#BC4749",
    "#8B5A3C", "#4A90A4", "#9B59B6", "#E67E22", "#1ABC9C", "#34495E"
  )
  palette <- character(length(mutations))
  names(palette) <- mutations
  palette[mutations == "G>T"] <- COLOR_GT
  other_mutations <- mutations[mutations != "G>T"]
  if (length(other_mutations) > 0) {
    palette[other_mutations] <- professional_colors[seq_along(other_mutations)]
  }
  return(palette)
}

mutation_palette <- get_mutation_palette(mutation_summary$mutation)

# ============================================================================
# FIGURE 1: Proportional Representation Analysis
# ============================================================================
# Shows how SNVs and Counts are distributed - identifies over/under-representation
# This is DIFFERENT from Step 1.5: focuses on proportions, not per-sample variability

mutation_summary_prop <- mutation_summary %>%
  mutate(
    prop_snvs = n_snvs / sum(n_snvs),
    prop_counts = total_read_counts / sum(total_read_counts),
    ratio_prop = prop_counts / prop_snvs,  # >1 = over-represented in counts
    mutation = fct_reorder(mutation, n_snvs)
  )

# Create stacked area or proportional comparison
fig_prop_comparison <- mutation_summary_prop %>%
  select(mutation, prop_snvs, prop_counts) %>%
  pivot_longer(cols = c(prop_snvs, prop_counts), names_to = "metric", values_to = "proportion") %>%
  mutate(metric = recode(metric,
                         prop_snvs = "Proportion of SNVs",
                         prop_counts = "Proportion of Read Counts")) %>%
  ggplot(aes(x = mutation, y = proportion, fill = mutation)) +
  geom_col(alpha = 0.85, position = "dodge") +
  facet_wrap(~metric, ncol = 1) +
  scale_fill_manual(values = mutation_palette) +
  scale_y_continuous(labels = percent_format()) +
  coord_flip() +
  labs(
    title = "Proportional Representation: SNVs vs Read Counts",
    subtitle = "Comparing what % of total SNVs vs what % of total counts each mutation type represents",
    x = "Mutation Type",
    y = "Proportion (%)",
    caption = "If proportions differ, the mutation is over/under-represented in read counts relative to SNV events.\nG>T (oxidation) highlighted in red. This shows OVERALL proportions, not per-sample analysis."
  ) +
  theme_professional +
  theme(legend.position = "none",
        strip.text = element_text(size = 11, face = "bold", color = "#2E86AB"),
        strip.background = element_rect(fill = "#f0f4f8", color = NA))

ggsave(output_fig_mutation_pie_snvs, fig_prop_comparison, width = 10, height = 10, dpi = 300, bg = "white")
log_success(paste("Mutation proportional comparison saved:", output_fig_mutation_pie_snvs))

# ============================================================================
# FIGURE 2: Ratio Analysis - Counts per SNV Event
# ============================================================================
# Shows how many reads each SNV type has on average
# This identifies which mutations have more/fewer reads per unique event

mutation_summary_ratio <- mutation_summary %>%
  mutate(
    ratio_counts_per_snv = total_read_counts / n_snvs,
    mutation = fct_reorder(mutation, ratio_counts_per_snv)
  )

fig_ratio_analysis <- mutation_summary_ratio %>%
  ggplot(aes(x = mutation, y = ratio_counts_per_snv, fill = mutation)) +
  geom_col(alpha = 0.85) +
  geom_hline(yintercept = mean(mutation_summary_ratio$ratio_counts_per_snv), 
             linetype = "dashed", color = "grey40", linewidth = 1) +
  annotate("text", x = nrow(mutation_summary_ratio) * 0.75,  # ✅ CORREGIDO: Mejorar posición (0.75 en lugar de 0.7)
           y = mean(mutation_summary_ratio$ratio_counts_per_snv) * 1.15,  # ✅ CORREGIDO: Mejorar posición vertical (1.15 en lugar de 1.1)
           label = "Overall average", color = "grey30", fontface = "bold", size = 4, hjust = 0) +  # ✅ CORREGIDO: Agregar hjust = 0 para mejor alineación
  scale_fill_manual(values = mutation_palette) +
  scale_y_continuous(labels = comma) +
  coord_flip() +
  labs(
    title = "Read Counts per SNV Event",
    subtitle = "Average number of sequencing reads per unique SNV event for each mutation type",
    x = "Mutation Type",
    y = "Read Counts per SNV Event",
    caption = "Higher values = more reads per unique SNV event. This shows sequencing depth per mutation type.\nG>T (oxidation) highlighted in red. Dashed line = overall average."
  ) +
  theme_professional +
  theme(legend.position = "none",
        plot.caption = element_text(size = 9, hjust = 0, color = "grey40"))

ggsave(output_fig_mutation_pie_counts, fig_ratio_analysis, width = 10, height = 8, dpi = 300, bg = "white")
log_success(paste("Mutation ratio analysis saved:", output_fig_mutation_pie_counts))

# Dataset Coverage Analysis --------------------------------------------------------
# This replaces positional density - shows how well the dataset is "covered" by SNVs
# This is COMPLEMENTARY to Step 1 (which focuses on specific G>T/position analysis)
log_subsection("Computing dataset coverage")

# Calculate coverage metrics
total_unique_mirnas <- length(unique(processed$miRNA_name))
# Count miRNAs that actually have SNVs detected (n_snvs > 0)
mirnas_with_snvs <- sum(mirna_summary$n_snvs > 0)

# Sample coverage
samples_with_snvs <- sum(sample_summary$n_snvs_detected > 0)
total_samples <- nrow(sample_summary)
samples_without_snvs <- total_samples - samples_with_snvs

# miRNA complexity distribution (how many SNVs per miRNA)
mirna_complexity <- mirna_summary %>%
  mutate(complexity_category = case_when(
    n_snvs == 1 ~ "1 SNV",
    n_snvs == 2 ~ "2 SNVs",
    n_snvs == 3 ~ "3 SNVs",
    n_snvs >= 4 & n_snvs <= 10 ~ "4-10 SNVs",
    n_snvs > 10 ~ ">10 SNVs",
    TRUE ~ "Other"
  )) %>%
  count(complexity_category) %>%
  mutate(
    complexity_category = factor(complexity_category, 
                                 levels = c("1 SNV", "2 SNVs", "3 SNVs", "4-10 SNVs", ">10 SNVs")),
    prop = n / sum(n)
  )

# Create coverage visualization
coverage_data <- tibble(
  category = c("miRNAs with SNVs", "Samples with SNVs"),
  n_with = c(mirnas_with_snvs, samples_with_snvs),
  n_total = c(total_unique_mirnas, total_samples),
  prop = c(mirnas_with_snvs / total_unique_mirnas, samples_with_snvs / total_samples)
)

fig_coverage <- coverage_data %>%
  ggplot(aes(x = category, y = prop, fill = category)) +
  geom_col(alpha = 0.85, width = 0.6) +
  geom_text(aes(label = sprintf("%.1f%%\n(%s / %s)", prop * 100, comma(n_with), comma(n_total))),
            vjust = -0.3, size = 4.5, fontface = "bold") +
  scale_fill_manual(values = c("#2E86AB", "#A23B72")) +
  scale_y_continuous(labels = percent_format(), limits = c(0, max(coverage_data$prop) * 1.2)) +
  labs(
    title = "Dataset Coverage: SNV Representation",
    subtitle = "What fraction of miRNAs and samples have detected SNVs?",
    x = "Category",
    y = "Coverage (%)",
    caption = "Shows how well the dataset is 'covered' by SNV detection.\nHigh coverage = most miRNAs/samples have SNVs detected."
  ) +
  theme_professional +
  theme(legend.position = "none",
        plot.caption = element_text(size = 9, hjust = 0, color = "grey40"))

ggsave(output_fig_coverage, fig_coverage, width = 10, height = 6, dpi = 300, bg = "white")
log_success(paste("Dataset coverage figure saved:", output_fig_coverage))

# Summary log ---------------------------------------------------------------
summary_samples <- sample_summary %>% summarise(
  total_samples = n(),
  total_reads = sum(total_read_counts, na.rm = TRUE),
  median_n_snvs = median(n_snvs_detected, na.rm = TRUE),
  median_n_mirnas = median(n_mirnas_affected, na.rm = TRUE)
)

total_miRNAs <- nrow(mirna_summary)
total_snvs <- sum(mirna_summary$n_snvs, na.rm = TRUE)

log_subsection("Summary statistics")
log_info(paste("Total samples:", summary_samples$total_samples[1]))
log_info(paste("Total miRNAs:", total_miRNAs))
log_info(paste("Total SNVs (unique events):", total_snvs))
log_info(paste("Total read counts:", scales::comma(summary_samples$total_reads[1])))
log_success("Step 0 overview completed")
