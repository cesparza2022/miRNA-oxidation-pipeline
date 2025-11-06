#!/usr/bin/env Rscript
# ============================================================================
# STEP 6: Complex Functional Visualization (Part of Functional Analysis)
# ============================================================================
# Purpose: Create separate comprehensive figures showing functional impact.
#          Part of Step 6 which runs after Step 2, in parallel with structure discovery.
#
# This script generates 4 separate figures:
# 1. Panel A: Top Enriched Pathways (barplot)
# 2. Panel B: Disease-Relevant Genes Impact (bubble plot)
# 3. Panel C: Target Comparison (grouped barplot)
# 4. Panel D: Position-Specific Functional Impact (barplot)
#
# Snakemake parameters:
#   input: Multiple enrichment and target analysis results from Step 6.1-3.2
#   output: 4 separate figure files
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
  library(readr)
  library(patchwork)
  library(scales)
  library(ggrepel)
})

# Load common functions and theme
source(snakemake@params[["functions"]], local = TRUE)
# Theme is loaded via functions_common.R

# Initialize logging
log_file <- if (length(snakemake@log) > 0) snakemake@log[[1]] else {
  file.path(dirname(snakemake@output[[1]]), "complex_functional_viz.log")
}
initialize_logging(log_file, context = "Step 6.3 - Complex Functional Visualization")

log_section("STEP 6: Complex Functional Visualization (Part of Functional Analysis)")

# ============================================================================
# GET SNAKEMAKE PARAMETERS
# ============================================================================

input_targets <- snakemake@input[["targets"]]
input_go <- snakemake@input[["go_enrichment"]]
input_kegg <- snakemake@input[["kegg_enrichment"]]
input_als_genes <- snakemake@input[["als_genes"]]
input_target_comp <- snakemake@input[["target_comparison"]]
output_figure_a <- snakemake@output[["figure_a"]]
output_figure_b <- snakemake@output[["figure_b"]]
output_figure_c <- snakemake@output[["figure_c"]]
output_figure_d <- snakemake@output[["figure_d"]]

config <- snakemake@config
alpha <- if (!is.null(config$analysis$alpha)) config$analysis$alpha else 0.05
seed_start <- if (!is.null(config$analysis$seed_region$start)) config$analysis$seed_region$start else 2
seed_end <- if (!is.null(config$analysis$seed_region$end)) config$analysis$seed_region$end else 8
color_gt <- if (!is.null(config$analysis$colors$gt)) config$analysis$colors$gt else "#D62728"
color_control <- if (!is.null(config$analysis$colors$control)) config$analysis$colors$control else "grey60"
fig_width <- if (!is.null(config$analysis$figure$width)) config$analysis$figure$width else 12
fig_height <- if (!is.null(config$analysis$figure$height)) config$analysis$figure$height else 10
fig_dpi <- if (!is.null(config$analysis$figure$dpi)) config$analysis$figure$dpi else 300

log_info(paste("Output figures:", output_figure_a, output_figure_b, output_figure_c, output_figure_d))
ensure_output_dir(dirname(output_figure_a))

# ============================================================================
# LOAD DATA
# ============================================================================

log_subsection("Loading functional analysis data")

# Validate file existence before reading
input_files <- list(
  targets = input_targets,
  go = input_go,
  kegg = input_kegg,
  als_genes = input_als_genes,
  target_comparison = input_target_comp
)

for (name in names(input_files)) {
  if (!file.exists(input_files[[name]])) {
    # Capitalize first letter for error message
    name_capitalized <- paste0(toupper(substr(name, 1, 1)), substr(name, 2, nchar(name)))
    handle_error(
      paste(name_capitalized, "file not found:", input_files[[name]]),
      context = "Step 6.3 - Data Loading",
      exit_code = 1,
      log_file = log_file
    )
  }
}

target_data <- tryCatch({
  result <- read_csv(input_targets, show_col_types = FALSE)
  log_success(paste("Loaded target data:", nrow(result), "miRNA-target pairs"))
  result
}, error = function(e) {
  handle_error(e, context = "Step 6.3 - Loading target data", exit_code = 1, log_file = log_file)
})

go_data <- tryCatch({
  result <- read_csv(input_go, show_col_types = FALSE)
  log_success(paste("Loaded GO enrichment:", nrow(result), "GO terms"))
  result
}, error = function(e) {
  handle_error(e, context = "Step 6.3 - Loading GO data", exit_code = 1, log_file = log_file)
})

kegg_data <- tryCatch({
  result <- read_csv(input_kegg, show_col_types = FALSE)
  log_success(paste("Loaded KEGG enrichment:", nrow(result), "pathways"))
  result
}, error = function(e) {
  handle_error(e, context = "Step 6.3 - Loading KEGG data", exit_code = 1, log_file = log_file)
})

als_genes_data <- tryCatch({
  result <- read_csv(input_als_genes, show_col_types = FALSE)
  log_success(paste("Loaded ALS genes data:", nrow(result), "genes"))
  result
}, error = function(e) {
  handle_error(e, context = "Step 6.3 - Loading ALS genes data", exit_code = 1, log_file = log_file)
})

target_comp <- tryCatch({
  result <- read_csv(input_target_comp, show_col_types = FALSE)
  log_success(paste("Loaded target comparison:", nrow(result), "comparisons"))
  result
}, error = function(e) {
  handle_error(e, context = "Step 6.3 - Loading target comparison", exit_code = 1, log_file = log_file)
})

# ============================================================================
# PANEL A: Top Enriched Pathways (Barplot)
# ============================================================================

log_subsection("Creating Panel A: Pathway Enrichment (separate figure)")

top_pathways <- bind_rows(
  go_data %>% 
    mutate(Type = "GO Biological Process", Pathway_Label = Description) %>% 
    head(10),
  kegg_data %>% 
    mutate(Type = "KEGG Pathway", Pathway_Label = Pathway_Name) %>% 
    head(10)
) %>%
  arrange(p.adjust) %>%
  head(15) %>%
  mutate(
    Pathway_Label = ifelse(is.na(Pathway_Label), Description, Pathway_Label),
    Pathway_Label = ifelse(is.na(Pathway_Label), Pathway_Name, Pathway_Label),
    Pathway_Label = ifelse(nchar(Pathway_Label) > 50, 
                          paste0(str_sub(Pathway_Label, 1, 47), "..."),
                          Pathway_Label)
  )

    # Get statistics for caption
    n_significant_go <- sum(go_data$p.adjust < alpha, na.rm = TRUE)
    n_significant_kegg <- sum(kegg_data$p.adjust < alpha, na.rm = TRUE)
top_richfactor <- round(max(top_pathways$RichFactor, na.rm = TRUE), 2)

panel_a <- ggplot(top_pathways, aes(x = reorder(Pathway_Label, -log10(p.adjust)), 
                                     y = -log10(p.adjust), fill = RichFactor)) +
  geom_bar(stat = "identity", alpha = 0.85, width = 0.7) +
  scale_fill_gradient(low = "white", high = color_gt, name = "Rich\nFactor") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
  coord_flip() +
  labs(
    title = "Top Enriched Pathways: Targets of Oxidized miRNAs",
    subtitle = paste("GO Biological Process & KEGG Pathways | Top 15 by significance |",
                     n_significant_go, "GO terms,", n_significant_kegg, "KEGG pathways significant (p.adj < ", alpha, ")"),
    x = "",
    y = "-Log10 Adjusted p-value",
    caption = paste("Max RichFactor =", top_richfactor, "| Analysis based on targets of",
                   nrow(target_data), "oxidized miRNAs in seed region")
  ) +
  theme_professional +
  theme(
    legend.position = "right",
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 11, color = "grey50")
  )

# Validate output directory exists
ensure_output_dir(dirname(output_figure_a))

ggsave(output_figure_a, panel_a, 
       width = fig_width, height = fig_height, dpi = fig_dpi, bg = "white")
validate_output_file(output_figure_a, min_size_bytes = 5000, context = "Step 6.3 - Panel A")
log_success(paste("Panel A saved:", output_figure_a))

# ============================================================================
# PANEL B: ALS-Relevant Genes Impact
# ============================================================================

log_subsection("Creating Panel B: ALS-Relevant Genes Impact (separate figure)")

als_summary <- als_genes_data %>%
  group_by(miRNA_name) %>%
  summarise(
    total_impact = sum(abs(functional_impact_score), na.rm = TRUE),
    n_als_genes = sum(als_genes_count, na.rm = TRUE),
    avg_position = mean(position, na.rm = TRUE),
    n_mutations = n(),
    .groups = "drop"
  ) %>%
  arrange(desc(total_impact)) %>%
  head(20)  # Top 20 for better visibility

# Get statistics
total_als_genes_affected <- sum(als_summary$n_als_genes, na.rm = TRUE)
top_mirna <- als_summary$miRNA_name[1]
top_impact <- round(max(als_summary$total_impact, na.rm = TRUE), 2)

panel_b <- ggplot(als_summary, aes(x = reorder(miRNA_name, total_impact), 
                                   y = total_impact, 
                                   size = n_als_genes,
                                   color = avg_position)) +
  geom_point(alpha = 0.8, stroke = 1.5) +
  scale_color_gradient(low = "#2E86AB", high = color_gt, 
                      name = "Avg\nPosition", guide = "legend") +
  scale_size_continuous(range = c(4, 12), name = "ALS\nGenes") +
  scale_y_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.1))) +
  coord_flip() +
  labs(
    title = "Impact on ALS-Relevant Genes",
    subtitle = paste("Functional impact score of oxidized miRNAs on ALS genes |",
                     "Top 20 miRNAs | Total", total_als_genes_affected, "ALS gene interactions"),
    x = "miRNA",
    y = "Functional Impact Score",
    caption = paste("Top miRNA:", top_mirna, "(Impact =", top_impact, ") |",
                   "Position color: lower = more critical seed positions (2-8)")
  ) +
  theme_professional +
  theme(
    legend.position = "right",
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 11, color = "grey50")
  )

# Validate output directory exists
ensure_output_dir(dirname(output_figure_b))

ggsave(output_figure_b, panel_b, 
       width = fig_width, height = fig_height, dpi = fig_dpi, bg = "white")
validate_output_file(output_figure_b, min_size_bytes = 5000, context = "Step 6.3 - Panel B")
log_success(paste("Panel B saved:", output_figure_b))

# ============================================================================
# PANEL C: Target Comparison (Canonical vs Oxidized)
# ============================================================================

log_subsection("Creating Panel C: Target Comparison (separate figure)")

target_comp_long <- target_comp %>%
  select(miRNA_name, canonical_targets_estimate, oxidized_targets_estimate) %>%
  pivot_longer(cols = c(canonical_targets_estimate, oxidized_targets_estimate),
              names_to = "Target_Type", values_to = "n_targets") %>%
  mutate(
    Target_Type = case_when(
      Target_Type == "canonical_targets_estimate" ~ "Canonical",
      TRUE ~ "Oxidized (G>T)"
    )
  ) %>%
  arrange(desc(n_targets)) %>%
  head(30)  # Top 15 miRNAs (2 bars each = 30 rows)

# Get statistics
avg_canonical <- round(mean(target_comp$canonical_targets_estimate, na.rm = TRUE), 1)
avg_oxidized <- round(mean(target_comp$oxidized_targets_estimate, na.rm = TRUE), 1)
avg_loss <- round(avg_canonical - avg_oxidized, 1)

panel_c <- ggplot(target_comp_long, aes(x = reorder(miRNA_name, n_targets), 
                                        y = n_targets, fill = Target_Type)) +
  geom_bar(stat = "identity", position = "dodge", alpha = 0.85, width = 0.7) +
  scale_fill_manual(values = c("Canonical" = color_control, 
                               "Oxidized (G>T)" = color_gt),
                   name = "Target Type") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
  coord_flip() +
  labs(
    title = "Target Prediction Comparison: Canonical vs Oxidized miRNAs",
    subtitle = paste("Estimated number of targets | Top 15 miRNAs |",
                     "Avg canonical:", avg_canonical, "| Avg oxidized:", avg_oxidized, 
                     "| Avg loss:", avg_loss, "targets"),
    x = "miRNA",
    y = "Number of Predicted Targets",
    caption = paste("Analysis based on", nrow(target_comp), 
                   "miRNAs with G>T mutations in seed region")
  ) +
  theme_professional +
  theme(
    legend.position = "right",
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 11, color = "grey50")
  )

# Validate output directory exists
ensure_output_dir(dirname(output_figure_c))

ggsave(output_figure_c, panel_c, 
       width = fig_width, height = fig_height, dpi = fig_dpi, bg = "white")
validate_output_file(output_figure_c, min_size_bytes = 5000, context = "Step 6.3 - Panel C")
log_success(paste("Panel C saved:", output_figure_c))

# ============================================================================
# PANEL D: Position-Specific Functional Impact
# ============================================================================

log_subsection("Creating Panel D: Position-Specific Impact (separate figure)")

position_impact <- target_data %>%
  group_by(position) %>%
  summarise(
    n_mutations = n(),
    n_unique_mirnas = n_distinct(miRNA_name),
    avg_impact = mean(functional_impact_score, na.rm = TRUE),
    total_impact = sum(functional_impact_score, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    in_seed = position >= 2 & position <= 8
  ) %>%
  arrange(position)

# Get statistics
seed_impact <- position_impact %>% filter(in_seed) %>% summarise(total = sum(total_impact, na.rm = TRUE)) %>% pull(total)
nonseed_impact <- position_impact %>% filter(!in_seed) %>% summarise(total = sum(total_impact, na.rm = TRUE)) %>% pull(total)
seed_ratio <- if (nonseed_impact > 0) round(seed_impact / nonseed_impact, 2) else Inf

panel_d <- ggplot(position_impact, aes(x = position, y = total_impact)) +
  annotate("rect", xmin = seed_start - 0.5, xmax = seed_end + 0.5, 
           ymin = -Inf, ymax = Inf, 
           fill = "#e3f2fd", alpha = 0.5) +
  annotate("text", x = (seed_start + seed_end) / 2, 
           y = max(position_impact$total_impact) * 0.95, 
           label = paste0("SEED REGION\n(positions ", seed_start, "-", seed_end, ")"), 
           color = "gray40", size = 4, fontface = "bold") +
  geom_bar(stat = "identity", fill = color_gt, alpha = 0.85, width = 0.7) +
  geom_point(aes(size = n_mutations), color = "white", fill = color_gt, 
            shape = 21, stroke = 1.5) +
  scale_size_continuous(range = c(3, 10), name = "Mutations") +
  scale_x_continuous(breaks = seq(1, 23, by = 2)) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
  labs(
    title = "Position-Specific Functional Impact",
    subtitle = paste("Cumulative functional impact by position |",
                     "Seed region (2-8) has", seed_ratio, "x more impact than non-seed |",
                     sum(position_impact$in_seed), "positions in seed region"),
    x = "Position in miRNA",
    y = "Total Functional Impact Score",
    caption = paste("Analysis based on", nrow(target_data), 
                   "G>T mutations | Point size = number of mutations per position")
  ) +
  theme_professional +
  theme(
    legend.position = "right",
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 11, color = "grey50")
  )

# Validate output directory exists
ensure_output_dir(dirname(output_figure_d))

ggsave(output_figure_d, panel_d, 
       width = fig_width, height = fig_height, dpi = fig_dpi, bg = "white")
validate_output_file(output_figure_d, min_size_bytes = 5000, context = "Step 6.3 - Panel D")
log_success(paste("Panel D saved:", output_figure_d))

log_success("Step 6.3 completed successfully - All 4 figures generated separately")
