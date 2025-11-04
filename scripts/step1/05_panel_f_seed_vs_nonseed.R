#!/usr/bin/env Rscript
# ============================================================================
# PANEL F: Seed vs Non-seed Comparison (Snakemake version)
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
  library(readr)
  library(stringr)
  library(scales)
})

source(snakemake@params[["functions"]], local = TRUE)

# Initialize logging
log_file <- if (length(snakemake@log) > 0) snakemake@log[[1]] else {
  file.path(dirname(snakemake@output[[1]]), "..", "logs", "panel_f.log")
}
initialize_logging(log_file, context = "Panel F")

log_section("PANEL F: Seed vs Non-seed Comparison")

input_file <- snakemake@input[["data"]]
output_figure <- snakemake@output[["figure"]]
output_table <- snakemake@output[["table"]]

log_info(paste("Input file:", input_file))
log_info(paste("Output figure:", output_figure))
log_info(paste("Output table:", output_table))

ensure_output_dir(dirname(output_figure))
ensure_output_dir(dirname(output_table))

# ============================================================================
# VALIDATE INPUT
# ============================================================================

if (exists("validate_processed_clean")) {
  validate_processed_clean(input_file)
} else if (exists("validate_input")) {
  validate_input(input_file, 
                expected_format = "csv",
                required_columns = c("miRNA name", "pos:mut"))
}

# ============================================================================
# LOAD DATA
# ============================================================================

log_subsection("Loading data")
data <- tryCatch({
  result <- load_processed_data(input_file)
  log_success(paste("Data loaded:", nrow(result), "rows,", ncol(result), "columns"))
  result
}, error = function(e) {
  handle_error(e, context = "Panel F - Data Loading", exit_code = 1, log_file = log_file)
})

sample_cols <- setdiff(names(data), c("miRNA_name", "pos.mut"))

log_subsection("Processing seed vs non-seed comparison")

seed_min <- 2; seed_max <- 8

snv <- data %>%
  filter(str_detect(pos.mut, "^\\d+:[ACGT][ACGT]$")) %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^\\d+"))) %>%
  filter(!is.na(position), position >= 1, position <= 23) %>%
  rowwise() %>%
  mutate(total_row_count = sum(c_across(all_of(sample_cols)), na.rm = TRUE)) %>%
  ungroup() %>%
  mutate(region = ifelse(position >= seed_min & position <= seed_max, "Seed", "Non-seed"))

summary_tbl <- snv %>%
  group_by(region) %>%
  summarise(
    total_mutations = sum(total_row_count, na.rm = TRUE),
    n_SNVs = n(),
    .groups = 'drop'
  ) %>%
  mutate(fraction = total_mutations / sum(total_mutations) * 100)

write_csv(summary_tbl, output_table)
log_success(paste("Table exported:", output_table))

p <- ggplot(summary_tbl, aes(x = region, y = total_mutations, fill = region)) +
  geom_col(width = 0.6, alpha = 0.9) +
  scale_fill_manual(values = c("Seed" = "#FFD700", "Non-seed" = "#6c757d")) +
  scale_y_continuous(labels = scales::comma) +
  labs(title = "Seed vs Non-seed: Mutation Burden",
       subtitle = "Absolute burden (summed counts across samples)",
       x = "Region", y = "Total Mutation Burden (counts)",
       caption = "Combined analysis (ALS + Control, no VAF filtering)") +
  theme_professional

log_subsection("Generating figure")
ggsave(output_figure, p, width = 10, height = 7, dpi = 300, bg = "white")
log_success(paste("Figure saved:", output_figure))

log_success("Panel F completed successfully")
log_info(paste("Execution completed at", get_timestamp()))


# PANEL F: Seed vs Non-seed Comparison (Snakemake version)
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
  library(readr)
  library(stringr)
  library(scales)
})

source(snakemake@params[["functions"]], local = TRUE)

# Initialize logging
log_file <- if (length(snakemake@log) > 0) snakemake@log[[1]] else {
  file.path(dirname(snakemake@output[[1]]), "..", "logs", "panel_f.log")
}
initialize_logging(log_file, context = "Panel F")

log_section("PANEL F: Seed vs Non-seed Comparison")

input_file <- snakemake@input[["data"]]
output_figure <- snakemake@output[["figure"]]
output_table <- snakemake@output[["table"]]

log_info(paste("Input file:", input_file))
log_info(paste("Output figure:", output_figure))
log_info(paste("Output table:", output_table))

ensure_output_dir(dirname(output_figure))
ensure_output_dir(dirname(output_table))

# ============================================================================
# VALIDATE INPUT
# ============================================================================

if (exists("validate_processed_clean")) {
  validate_processed_clean(input_file)
} else if (exists("validate_input")) {
  validate_input(input_file, 
                expected_format = "csv",
                required_columns = c("miRNA name", "pos:mut"))
}

# ============================================================================
# LOAD DATA
# ============================================================================

log_subsection("Loading data")
data <- tryCatch({
  result <- load_processed_data(input_file)
  log_success(paste("Data loaded:", nrow(result), "rows,", ncol(result), "columns"))
  result
}, error = function(e) {
  handle_error(e, context = "Panel F - Data Loading", exit_code = 1, log_file = log_file)
})

sample_cols <- setdiff(names(data), c("miRNA_name", "pos.mut"))

log_subsection("Processing seed vs non-seed comparison")

seed_min <- 2; seed_max <- 8

snv <- data %>%
  filter(str_detect(pos.mut, "^\\d+:[ACGT][ACGT]$")) %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^\\d+"))) %>%
  filter(!is.na(position), position >= 1, position <= 23) %>%
  rowwise() %>%
  mutate(total_row_count = sum(c_across(all_of(sample_cols)), na.rm = TRUE)) %>%
  ungroup() %>%
  mutate(region = ifelse(position >= seed_min & position <= seed_max, "Seed", "Non-seed"))

summary_tbl <- snv %>%
  group_by(region) %>%
  summarise(
    total_mutations = sum(total_row_count, na.rm = TRUE),
    n_SNVs = n(),
    .groups = 'drop'
  ) %>%
  mutate(fraction = total_mutations / sum(total_mutations) * 100)

write_csv(summary_tbl, output_table)
log_success(paste("Table exported:", output_table))

p <- ggplot(summary_tbl, aes(x = region, y = total_mutations, fill = region)) +
  geom_col(width = 0.6, alpha = 0.9) +
  scale_fill_manual(values = c("Seed" = "#FFD700", "Non-seed" = "#6c757d")) +
  scale_y_continuous(labels = scales::comma) +
  labs(title = "Seed vs Non-seed: Mutation Burden",
       subtitle = "Absolute burden (summed counts across samples)",
       x = "Region", y = "Total Mutation Burden (counts)",
       caption = "Combined analysis (ALS + Control, no VAF filtering)") +
  theme_professional

log_subsection("Generating figure")
ggsave(output_figure, p, width = 10, height = 7, dpi = 300, bg = "white")
log_success(paste("Figure saved:", output_figure))

log_success("Panel F completed successfully")
log_info(paste("Execution completed at", get_timestamp()))


# PANEL F: Seed vs Non-seed Comparison (Snakemake version)
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
  library(readr)
  library(stringr)
  library(scales)
})

source(snakemake@params[["functions"]], local = TRUE)

# Initialize logging
log_file <- if (length(snakemake@log) > 0) snakemake@log[[1]] else {
  file.path(dirname(snakemake@output[[1]]), "..", "logs", "panel_f.log")
}
initialize_logging(log_file, context = "Panel F")

log_section("PANEL F: Seed vs Non-seed Comparison")

input_file <- snakemake@input[["data"]]
output_figure <- snakemake@output[["figure"]]
output_table <- snakemake@output[["table"]]

log_info(paste("Input file:", input_file))
log_info(paste("Output figure:", output_figure))
log_info(paste("Output table:", output_table))

ensure_output_dir(dirname(output_figure))
ensure_output_dir(dirname(output_table))

# ============================================================================
# VALIDATE INPUT
# ============================================================================

if (exists("validate_processed_clean")) {
  validate_processed_clean(input_file)
} else if (exists("validate_input")) {
  validate_input(input_file, 
                expected_format = "csv",
                required_columns = c("miRNA name", "pos:mut"))
}

# ============================================================================
# LOAD DATA
# ============================================================================

log_subsection("Loading data")
data <- tryCatch({
  result <- load_processed_data(input_file)
  log_success(paste("Data loaded:", nrow(result), "rows,", ncol(result), "columns"))
  result
}, error = function(e) {
  handle_error(e, context = "Panel F - Data Loading", exit_code = 1, log_file = log_file)
})

sample_cols <- setdiff(names(data), c("miRNA_name", "pos.mut"))

log_subsection("Processing seed vs non-seed comparison")

seed_min <- 2; seed_max <- 8

snv <- data %>%
  filter(str_detect(pos.mut, "^\\d+:[ACGT][ACGT]$")) %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^\\d+"))) %>%
  filter(!is.na(position), position >= 1, position <= 23) %>%
  rowwise() %>%
  mutate(total_row_count = sum(c_across(all_of(sample_cols)), na.rm = TRUE)) %>%
  ungroup() %>%
  mutate(region = ifelse(position >= seed_min & position <= seed_max, "Seed", "Non-seed"))

summary_tbl <- snv %>%
  group_by(region) %>%
  summarise(
    total_mutations = sum(total_row_count, na.rm = TRUE),
    n_SNVs = n(),
    .groups = 'drop'
  ) %>%
  mutate(fraction = total_mutations / sum(total_mutations) * 100)

write_csv(summary_tbl, output_table)
log_success(paste("Table exported:", output_table))

p <- ggplot(summary_tbl, aes(x = region, y = total_mutations, fill = region)) +
  geom_col(width = 0.6, alpha = 0.9) +
  scale_fill_manual(values = c("Seed" = "#FFD700", "Non-seed" = "#6c757d")) +
  scale_y_continuous(labels = scales::comma) +
  labs(title = "Seed vs Non-seed: Mutation Burden",
       subtitle = "Absolute burden (summed counts across samples)",
       x = "Region", y = "Total Mutation Burden (counts)",
       caption = "Combined analysis (ALS + Control, no VAF filtering)") +
  theme_professional

log_subsection("Generating figure")
ggsave(output_figure, p, width = 10, height = 7, dpi = 300, bg = "white")
log_success(paste("Figure saved:", output_figure))

log_success("Panel F completed successfully")
log_info(paste("Execution completed at", get_timestamp()))

