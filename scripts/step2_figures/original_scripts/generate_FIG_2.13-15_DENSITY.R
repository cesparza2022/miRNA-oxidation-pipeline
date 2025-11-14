#!/usr/bin/env Rscript
# ============================================================================
# FIGURAS 2.13-2.15 - DENSITY HEATMAPS (ComplexHeatmap format)
# ============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(readr)
  library(ComplexHeatmap)
  library(circlize)
  library(grid)
})

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  GENERATING FIGS 2.13-2.15 - DENSITY HEATMAPS\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# ---------------------------------------------------------------------------
# Load data
# ---------------------------------------------------------------------------

cat("📂 Loading data...\n")
data <- read_csv("final_processed_data_CLEAN.csv", show_col_types = FALSE)
metadata <- read_csv("metadata.csv", show_col_types = FALSE)
sample_cols <- metadata$Sample_ID

cat("   ✅ Data loaded:", nrow(data), "SNVs,", length(sample_cols), "samples\n\n")

vaf_gt <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  mutate(pos = as.numeric(str_extract(pos.mut, "^[0-9]+"))) %>%
  filter(!is.na(pos), pos <= 23)

vaf_long <- vaf_gt %>%
  select(miRNA_name, pos.mut, pos, all_of(sample_cols)) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  filter(!is.na(VAF), VAF > 0) %>%
  left_join(metadata %>% select(Sample_ID, Group), by = "Sample_ID")

cat("   ✅ Observations with groups:", nrow(vaf_long), "\n\n")

prepare_ranked <- function(group_name) {
  vaf_long %>%
    filter(Group == group_name) %>%
    group_by(miRNA_name, pos.mut, pos) %>%
    summarise(avr = mean(VAF, na.rm = TRUE), .groups = "drop") %>%
    arrange(pos, desc(avr))
}

create_heatmap <- function(df_ranked, title_text) {
  if (nrow(df_ranked) == 0) {
    stop("No data available for heatmap: ", title_text)
  }
  df_summary <- df_ranked %>%
    group_by(pos) %>%
    summarise(total_snvs = n(), .groups = "drop")
  max_snvs <- max(df_summary$total_snvs)
  positions <- sort(unique(df_ranked$pos))
  matrix_list <- vector("list", length(positions))
  names(matrix_list) <- as.character(positions)
  for (p in positions) {
    snvs_for_pos <- df_ranked %>%
      filter(pos == p) %>%
      arrange(desc(avr)) %>%
      pull(avr)
    if (length(snvs_for_pos) < max_snvs) {
      snvs_for_pos <- c(snvs_for_pos, rep(NA_real_, max_snvs - length(snvs_for_pos)))
    }
    matrix_list[[as.character(p)]] <- matrix(snvs_for_pos, ncol = 1,
                                             dimnames = list(NULL, as.character(p)))
  }
  mat <- do.call(cbind, matrix_list)
  mat[is.na(mat)] <- 0
  col_fun <- colorRamp2(
    c(0, 2, 4, 6, 8),
    c("#FFFFFF", "#FFCCCC", "#FF9999", "#FF6666", "#CC0000")
  )
  Heatmap(
    mat,
    na_col = "white",
    name = "avr",
    cluster_rows = FALSE,
    cluster_columns = FALSE,
    col = col_fun,
    show_row_names = FALSE,
    show_column_names = TRUE,
    column_title = title_text,
    row_title = paste0("SNVs (", format(nrow(df_ranked), big.mark = ","), ")"),
    use_raster = FALSE,
    column_names_rot = 0,
    column_names_centered = TRUE,
    bottom_annotation = HeatmapAnnotation(
      "SNV Count" = anno_barplot(
        df_summary$total_snvs,
        bar_width = 0.8,
        gp = gpar(fill = "grey50"),
        annotation_name_rot = 0,
        height = unit(2, "cm")
      )
    )
  )
}

save_heatmap_png <- function(ht, file, width = 16, height = 12) {
  png(file, width = width, height = height, units = "in", res = 300, bg = "white")
  draw(ht)
  dev.off()
}

cat("🎨 Generating Figure 2.13 (ALS)...\n")
df_ranked_als <- prepare_ranked("ALS")
ht_als <- create_heatmap(df_ranked_als, "Positional G>T in ALS data")
save_heatmap_png(ht_als, "figures_paso2_CLEAN/FIG_2.13_DENSITY_HEATMAP_ALS.png")
cat("   ✅ Saved FIG_2.13_DENSITY_HEATMAP_ALS.png\n\n")

cat("🎨 Generating Figure 2.14 (Control)...\n")
df_ranked_ctrl <- prepare_ranked("Control")
ht_ctrl <- create_heatmap(df_ranked_ctrl, "Positional G>T in control data")
save_heatmap_png(ht_ctrl, "figures_paso2_CLEAN/FIG_2.14_DENSITY_HEATMAP_CONTROL.png")
cat("   ✅ Saved FIG_2.14_DENSITY_HEATMAP_CONTROL.png\n\n")

cat("🎨 Generating Figure 2.15 (Combined)...\n")
# Combine heatmaps vertically (not horizontally) to avoid row mismatch
# Use %v% operator to stack them vertically (ComplexHeatmap >= 2.0)
tryCatch({
  ht_combined <- ht_als %v% ht_ctrl
  png("figures_paso2_CLEAN/FIG_2.15_DENSITY_COMBINED.png",
      width = 16, height = 20, units = "in", res = 300, bg = "white")
  draw(ht_combined, heatmap_legend_side = "bottom", 
       annotation_legend_side = "right", merge_legend = TRUE)
  dev.off()
  cat("   ✅ Saved FIG_2.15_DENSITY_COMBINED.png\n\n")
}, error = function(e) {
  cat("   ⚠️  Error combining heatmaps:", conditionMessage(e), "\n")
  cat("   ⚠️  Creating side-by-side layout instead...\n")
  # Fallback: Create a simple side-by-side layout using grid
  png("figures_paso2_CLEAN/FIG_2.15_DENSITY_COMBINED.png",
      width = 20, height = 12, units = "in", res = 300, bg = "white")
  grid.newpage()
  pushViewport(viewport(layout = grid.layout(nrow = 1, ncol = 2, 
                                             widths = unit(c(1, 1), "null"))))
  pushViewport(viewport(layout.pos.row = 1, layout.pos.col = 1))
  draw(ht_als, newpage = FALSE)
  popViewport()
  pushViewport(viewport(layout.pos.row = 1, layout.pos.col = 2))
  draw(ht_ctrl, newpage = FALSE)
  popViewport()
  dev.off()
  cat("   ✅ Saved FIG_2.15_DENSITY_COMBINED.png (side-by-side layout)\n\n")
})

cat("✅ ALL DENSITY HEATMAPS GENERATED SUCCESSFULLY\n\n")
