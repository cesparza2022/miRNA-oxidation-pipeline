#!/usr/bin/env Rscript
# ============================================================================
# PANEL G: G>T Specificity (Overall) (Snakemake version)
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
  file.path(dirname(snakemake@output[[1]]), "..", "logs", "panel_g.log")
}
initialize_logging(log_file, context = "Panel G")

log_section("PANEL G: G>T Specificity (Overall)")

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
  handle_error(e, context = "Panel G - Data Loading", exit_code = 1, log_file = log_file)
})

sample_cols <- setdiff(names(data), c("miRNA_name", "pos.mut"))

log_subsection("Processing G>T specificity")

COLOR_OTHERS <- "#6c757d"

g_mut <- data %>%
  filter(str_detect(pos.mut, "^\\d+:G[TCAG]$")) %>%
  rowwise() %>%
  mutate(total_row_count = sum(c_across(all_of(sample_cols)), na.rm = TRUE)) %>%
  ungroup() %>%
  mutate(type = case_when(
    str_ends(pos.mut, ":GT") ~ "G>T",
    str_ends(pos.mut, ":GC") ~ "G>C",
    str_ends(pos.mut, ":GA") ~ "G>A",
    TRUE ~ NA_character_
  )) %>%
  filter(!is.na(type))

spec_tbl <- g_mut %>%
  group_by(type) %>%
  summarise(total = sum(total_row_count, na.rm = TRUE), .groups = 'drop') %>%
  mutate(category = ifelse(type == "G>T", "G>T", "Other G transversions")) %>%
  group_by(category) %>%
  summarise(total = sum(total), .groups = 'drop') %>%
  mutate(percentage = total / sum(total) * 100)

write_csv(spec_tbl, output_table)
log_success(paste("Table exported:", output_table))

p <- ggplot(spec_tbl, aes(x = category, y = percentage, fill = category)) +
  geom_col(width = 0.6, alpha = 0.9) +
  scale_fill_manual(values = c("G>T" = COLOR_GT, "Other G transversions" = COLOR_OTHERS)) +
  scale_y_continuous(limits = c(0, 100), expand = expansion(mult = c(0, 0.02))) +
  labs(title = "G>T Specificity (Overall)",
       subtitle = "Percentage of G mutations that are G>T vs other G transversions",
       x = NULL, y = "Percentage (%)",
       caption = "Combined analysis (ALS + Control, no VAF filtering)") +
  theme_professional +
  theme(legend.position = "none")

log_subsection("Generating figure")
ggsave(output_figure, p, width = 9, height = 7, dpi = 300, bg = "white")
log_success(paste("Figure saved:", output_figure))

log_success("Panel G completed successfully")
log_info(paste("Execution completed at", get_timestamp()))


# PANEL G: G>T Specificity (Overall) (Snakemake version)
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
  file.path(dirname(snakemake@output[[1]]), "..", "logs", "panel_g.log")
}
initialize_logging(log_file, context = "Panel G")

log_section("PANEL G: G>T Specificity (Overall)")

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
  handle_error(e, context = "Panel G - Data Loading", exit_code = 1, log_file = log_file)
})

sample_cols <- setdiff(names(data), c("miRNA_name", "pos.mut"))

log_subsection("Processing G>T specificity")

COLOR_OTHERS <- "#6c757d"

g_mut <- data %>%
  filter(str_detect(pos.mut, "^\\d+:G[TCAG]$")) %>%
  rowwise() %>%
  mutate(total_row_count = sum(c_across(all_of(sample_cols)), na.rm = TRUE)) %>%
  ungroup() %>%
  mutate(type = case_when(
    str_ends(pos.mut, ":GT") ~ "G>T",
    str_ends(pos.mut, ":GC") ~ "G>C",
    str_ends(pos.mut, ":GA") ~ "G>A",
    TRUE ~ NA_character_
  )) %>%
  filter(!is.na(type))

spec_tbl <- g_mut %>%
  group_by(type) %>%
  summarise(total = sum(total_row_count, na.rm = TRUE), .groups = 'drop') %>%
  mutate(category = ifelse(type == "G>T", "G>T", "Other G transversions")) %>%
  group_by(category) %>%
  summarise(total = sum(total), .groups = 'drop') %>%
  mutate(percentage = total / sum(total) * 100)

write_csv(spec_tbl, output_table)
log_success(paste("Table exported:", output_table))

p <- ggplot(spec_tbl, aes(x = category, y = percentage, fill = category)) +
  geom_col(width = 0.6, alpha = 0.9) +
  scale_fill_manual(values = c("G>T" = COLOR_GT, "Other G transversions" = COLOR_OTHERS)) +
  scale_y_continuous(limits = c(0, 100), expand = expansion(mult = c(0, 0.02))) +
  labs(title = "G>T Specificity (Overall)",
       subtitle = "Percentage of G mutations that are G>T vs other G transversions",
       x = NULL, y = "Percentage (%)",
       caption = "Combined analysis (ALS + Control, no VAF filtering)") +
  theme_professional +
  theme(legend.position = "none")

log_subsection("Generating figure")
ggsave(output_figure, p, width = 9, height = 7, dpi = 300, bg = "white")
log_success(paste("Figure saved:", output_figure))

log_success("Panel G completed successfully")
log_info(paste("Execution completed at", get_timestamp()))


# PANEL G: G>T Specificity (Overall) (Snakemake version)
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
  file.path(dirname(snakemake@output[[1]]), "..", "logs", "panel_g.log")
}
initialize_logging(log_file, context = "Panel G")

log_section("PANEL G: G>T Specificity (Overall)")

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
  handle_error(e, context = "Panel G - Data Loading", exit_code = 1, log_file = log_file)
})

sample_cols <- setdiff(names(data), c("miRNA_name", "pos.mut"))

log_subsection("Processing G>T specificity")

COLOR_OTHERS <- "#6c757d"

g_mut <- data %>%
  filter(str_detect(pos.mut, "^\\d+:G[TCAG]$")) %>%
  rowwise() %>%
  mutate(total_row_count = sum(c_across(all_of(sample_cols)), na.rm = TRUE)) %>%
  ungroup() %>%
  mutate(type = case_when(
    str_ends(pos.mut, ":GT") ~ "G>T",
    str_ends(pos.mut, ":GC") ~ "G>C",
    str_ends(pos.mut, ":GA") ~ "G>A",
    TRUE ~ NA_character_
  )) %>%
  filter(!is.na(type))

spec_tbl <- g_mut %>%
  group_by(type) %>%
  summarise(total = sum(total_row_count, na.rm = TRUE), .groups = 'drop') %>%
  mutate(category = ifelse(type == "G>T", "G>T", "Other G transversions")) %>%
  group_by(category) %>%
  summarise(total = sum(total), .groups = 'drop') %>%
  mutate(percentage = total / sum(total) * 100)

write_csv(spec_tbl, output_table)
log_success(paste("Table exported:", output_table))

p <- ggplot(spec_tbl, aes(x = category, y = percentage, fill = category)) +
  geom_col(width = 0.6, alpha = 0.9) +
  scale_fill_manual(values = c("G>T" = COLOR_GT, "Other G transversions" = COLOR_OTHERS)) +
  scale_y_continuous(limits = c(0, 100), expand = expansion(mult = c(0, 0.02))) +
  labs(title = "G>T Specificity (Overall)",
       subtitle = "Percentage of G mutations that are G>T vs other G transversions",
       x = NULL, y = "Percentage (%)",
       caption = "Combined analysis (ALS + Control, no VAF filtering)") +
  theme_professional +
  theme(legend.position = "none")

log_subsection("Generating figure")
ggsave(output_figure, p, width = 9, height = 7, dpi = 300, bg = "white")
log_success(paste("Figure saved:", output_figure))

log_success("Panel G completed successfully")
log_info(paste("Execution completed at", get_timestamp()))

