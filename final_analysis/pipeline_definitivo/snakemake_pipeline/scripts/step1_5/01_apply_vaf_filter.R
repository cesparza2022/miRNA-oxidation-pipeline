#!/usr/bin/env Rscript
# ============================================================================
# 🎯 STEP 1.5: VAF QUALITY CONTROL - APPLY VAF FILTER (Snakemake version)
# ============================================================================
# Purpose: Filter out technical artifacts (VAF >= 0.5)
# 
# Snakemake parameters:
#   input: Path to original data CSV
#   output: 4 CSV tables (filtered data + reports)
# ============================================================================

library(dplyr)
library(tidyr)
library(readr)

cat("╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║     🎯 STEP 1.5: VAF QUALITY CONTROL - APPLY FILTER                ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

# ============================================================================
# GET SNAKEMAKE PARAMETERS
# ============================================================================

input_file <- snakemake@input[["data"]]
output_filtered <- snakemake@output[["filtered_data"]]
output_report <- snakemake@output[["filter_report"]]
output_stats_type <- snakemake@output[["stats_by_type"]]
output_stats_mirna <- snakemake@output[["stats_by_mirna"]]

cat("📋 Parameters:\n")
cat("   Input:", input_file, "\n")
cat("   Output filtered:", output_filtered, "\n")
cat("   Output report:", output_report, "\n\n")

# ============================================================================
# VALIDATE INPUT
# ============================================================================

# Source validation functions if not already loaded
if (!exists("validate_step1_5_input")) {
  # Try to source validate_input.R
  validate_path <- "scripts/utils/validate_input.R"
  if (file.exists(validate_path)) {
    source(validate_path, local = TRUE)
  }
}

if (exists("validate_step1_5_input")) {
  validate_step1_5_input(input_file)
} else if (exists("validate_input")) {
  validate_input(input_file, 
                expected_format = "csv",
                required_columns = c("miRNA name", "pos:mut"))
}

# ============================================================================
# 1. LOAD DATA
# ============================================================================

cat("📊 Loading collapsed data...\n")
data <- read.csv(input_file, check.names = FALSE)

cat(sprintf("   ✅ Rows: %s\n", format(nrow(data), big.mark = ",")))
cat(sprintf("   ✅ Columns: %d\n", ncol(data)))

# Get column types
sample_cols <- grep("^Magen", names(data), value = TRUE)
total_cols <- grep("\\(PM\\+1MM\\+2MM\\)$", names(data), value = TRUE)
snv_cols <- setdiff(sample_cols, total_cols)

cat(sprintf("   ✅ SNV columns: %d\n", length(snv_cols)))
cat(sprintf("   ✅ Total columns: %d\n", length(total_cols)))

# ============================================================================
# 2. CALCULATE VAF AND IDENTIFY ARTIFACTS (VECTORIZED - MUCH FASTER)
# ============================================================================

cat("\n📊 Calculating VAF for all mutations (vectorized method)...\n")

# Extract miRNA and position info
data_with_info <- data %>%
  mutate(
    miRNA = `miRNA name`,
    pos_mut = `pos:mut`
  )

# Get ID columns (non-sample columns)
id_cols <- c("miRNA name", "pos:mut", "miRNA", "pos_mut")

# Pivot to long format for vectorized processing
cat("📊 Converting to long format for vectorized processing...\n")

long_data <- data_with_info %>%
  pivot_longer(
    cols = -all_of(id_cols),
    names_to = "Sample",
    values_to = "Count"
  ) %>%
  mutate(
    # Identify if this is SNV or Total column
    is_total = grepl("\\(PM\\+1MM\\+2MM\\)$", Sample),
    Sample_Base = ifelse(is_total, 
                        gsub(" \\(PM\\+1MM\\+2MM\\)$", "", Sample),
                        Sample)
  ) %>%
  # Separate SNV and Total counts
  pivot_wider(
    id_cols = c(`miRNA name`, `pos:mut`, miRNA, pos_mut, Sample_Base),
    names_from = is_total,
    values_from = Count,
    names_prefix = "Count_"
  ) %>%
  rename(
    SNV_Count = Count_FALSE,
    Total_Count = Count_TRUE
  )

cat(sprintf("   ✅ Long format: %s rows\n", format(nrow(long_data), big.mark = ",")))

# Vectorized VAF calculation and filtering
cat("📊 Calculating VAF and filtering (vectorized)...\n")

long_data_filtered <- long_data %>%
  mutate(
    # Calculate VAF for all rows at once (vectorized)
    VAF = ifelse(!is.na(Total_Count) & Total_Count > 0,
                 SNV_Count / Total_Count,
                 NA),
    # Mark filtered values (VAF >= 0.5) as NA
    SNV_Count_Filtered = ifelse(!is.na(VAF) & VAF >= 0.5, NA, SNV_Count)
  )

# Extract filter log (only filtered values)
filter_df <- long_data_filtered %>%
  filter(!is.na(VAF) & VAF >= 0.5) %>%
  select(miRNA, pos_mut, Sample = Sample_Base, SNV_Count, Total_Count, VAF)

total_filtered <- nrow(filter_df)

cat(sprintf("\n   ✅ Total values filtered (VAF >= 0.5): %s\n", format(total_filtered, big.mark = ",")))

# Convert back to wide format for output
cat("📊 Converting back to wide format...\n")

data_filtered <- long_data_filtered %>%
  select(`miRNA name`, `pos:mut`, Sample = Sample_Base, SNV_Count = SNV_Count_Filtered) %>%
  pivot_wider(
    id_cols = c(`miRNA name`, `pos:mut`),
    names_from = Sample,
    values_from = SNV_Count
  ) %>%
  # Merge back with Total columns (not filtered, just need to preserve structure)
  left_join(
    data_with_info %>%
      select(`miRNA name`, `pos:mut`, all_of(total_cols)),
    by = c("miRNA name", "pos:mut")
  )

# ============================================================================
# 3. PREPARE OUTPUT DATA
# ============================================================================

cat("\n📊 Preparing output data...\n")

# Remove helper columns if they exist
data_output <- data_filtered %>%
  select(-any_of(c("miRNA", "pos_mut")))

cat(sprintf("   ✅ Output rows: %s\n", format(nrow(data_output), big.mark = ",")))
cat(sprintf("   ✅ Output columns: %d\n", ncol(data_output)))

# ============================================================================
# 4. GENERATE FILTER REPORT
# ============================================================================

cat("\n📊 Generating filter report...\n")

if (nrow(filter_df) > 0) {
  # Add mutation type for statistics
  filter_df <- filter_df %>%
    mutate(
      Mutation_Type = gsub(".*:", "", pos_mut),
      Mutation_Type = gsub('"', '', Mutation_Type)
    )
  
  # Statistics by mutation type
  stats_by_type <- filter_df %>%
    group_by(Mutation_Type) %>%
    summarise(
      N_Filtered = n(),
      Mean_VAF = mean(VAF, na.rm = TRUE),
      Min_VAF = min(VAF, na.rm = TRUE),
      Max_VAF = max(VAF, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    arrange(desc(N_Filtered))
  
  # Statistics by miRNA
  stats_by_mirna <- filter_df %>%
    group_by(miRNA) %>%
    summarise(
      N_Filtered = n(),
      Mean_VAF = mean(VAF, na.rm = TRUE),
      Samples_Affected = n_distinct(Sample),
      .groups = "drop"
    ) %>%
    arrange(desc(N_Filtered))
  
  cat(sprintf("   ✅ Filter report: %s entries\n", format(nrow(filter_df), big.mark = ",")))
  cat(sprintf("   ✅ Mutation types affected: %d\n", nrow(stats_by_type)))
  cat(sprintf("   ✅ miRNAs affected: %d\n", nrow(stats_by_mirna)))
} else {
  # No filtered values - create empty data frames
  filter_df <- data.frame(
    miRNA = character(0),
    pos_mut = character(0),
    Sample = character(0),
    SNV_Count = numeric(0),
    Total_Count = numeric(0),
    VAF = numeric(0),
    stringsAsFactors = FALSE
  )
  
  stats_by_type <- data.frame(
    Mutation_Type = character(0),
    N_Filtered = integer(0),
    Mean_VAF = numeric(0),
    Min_VAF = numeric(0),
    Max_VAF = numeric(0),
    stringsAsFactors = FALSE
  )
  
  stats_by_mirna <- data.frame(
    miRNA = character(0),
    N_Filtered = integer(0),
    Mean_VAF = numeric(0),
    Samples_Affected = integer(0),
    stringsAsFactors = FALSE
  )
  
  cat("   ⚠️  No values filtered (all VAFs < 0.5)\n")
}

# ============================================================================
# 5. SAVE OUTPUTS
# ============================================================================

cat("\n💾 Saving outputs...\n")

# Create output directory if needed
output_dir <- dirname(output_filtered)
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# SAVE FILTERED DATASET
write.csv(data_output, output_filtered, row.names = FALSE)
cat("   ✅ Filtered dataset:", output_filtered, "\n")

# SAVE FILTER REPORT
write.csv(filter_df, output_report, row.names = FALSE)
cat("   ✅ Filter report:", output_report, "\n")

# SAVE STATISTICS
write.csv(stats_by_type, output_stats_type, row.names = FALSE)
cat("   ✅ Stats by type:", output_stats_type, "\n")

write.csv(stats_by_mirna, output_stats_mirna, row.names = FALSE)
cat("   ✅ Stats by miRNA:", output_stats_mirna, "\n")

# ============================================================================
# SUMMARY
# ============================================================================

cat("\n╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║                    ✅ FILTERING COMPLETE                               ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

cat("📊 Summary:\n")
cat(sprintf("   • Input rows: %s\n", format(nrow(data), big.mark = ",")))
cat(sprintf("   • Output rows: %s\n", format(nrow(data_output), big.mark = ",")))
cat(sprintf("   • Values filtered (VAF >= 0.5): %s\n", format(total_filtered, big.mark = ",")))
cat(sprintf("   • Filter rate: %.2f%%\n", (total_filtered / (nrow(data) * length(snv_cols))) * 100))

cat("\n🚀 NEXT: Generate diagnostic figures\n\n")


# 🎯 STEP 1.5: VAF QUALITY CONTROL - APPLY VAF FILTER (Snakemake version)
# ============================================================================
# Purpose: Filter out technical artifacts (VAF >= 0.5)
# 
# Snakemake parameters:
#   input: Path to original data CSV
#   output: 4 CSV tables (filtered data + reports)
# ============================================================================

library(dplyr)
library(tidyr)
library(readr)

cat("╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║     🎯 STEP 1.5: VAF QUALITY CONTROL - APPLY FILTER                ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

# ============================================================================
# GET SNAKEMAKE PARAMETERS
# ============================================================================

input_file <- snakemake@input[["data"]]
output_filtered <- snakemake@output[["filtered_data"]]
output_report <- snakemake@output[["filter_report"]]
output_stats_type <- snakemake@output[["stats_by_type"]]
output_stats_mirna <- snakemake@output[["stats_by_mirna"]]

cat("📋 Parameters:\n")
cat("   Input:", input_file, "\n")
cat("   Output filtered:", output_filtered, "\n")
cat("   Output report:", output_report, "\n\n")

# ============================================================================
# VALIDATE INPUT
# ============================================================================

# Source validation functions if not already loaded
if (!exists("validate_step1_5_input")) {
  # Try to source validate_input.R
  validate_path <- "scripts/utils/validate_input.R"
  if (file.exists(validate_path)) {
    source(validate_path, local = TRUE)
  }
}

if (exists("validate_step1_5_input")) {
  validate_step1_5_input(input_file)
} else if (exists("validate_input")) {
  validate_input(input_file, 
                expected_format = "csv",
                required_columns = c("miRNA name", "pos:mut"))
}

# ============================================================================
# 1. LOAD DATA
# ============================================================================

cat("📊 Loading collapsed data...\n")
data <- read.csv(input_file, check.names = FALSE)

cat(sprintf("   ✅ Rows: %s\n", format(nrow(data), big.mark = ",")))
cat(sprintf("   ✅ Columns: %d\n", ncol(data)))

# Get column types
sample_cols <- grep("^Magen", names(data), value = TRUE)
total_cols <- grep("\\(PM\\+1MM\\+2MM\\)$", names(data), value = TRUE)
snv_cols <- setdiff(sample_cols, total_cols)

cat(sprintf("   ✅ SNV columns: %d\n", length(snv_cols)))
cat(sprintf("   ✅ Total columns: %d\n", length(total_cols)))

# ============================================================================
# 2. CALCULATE VAF AND IDENTIFY ARTIFACTS (VECTORIZED - MUCH FASTER)
# ============================================================================

cat("\n📊 Calculating VAF for all mutations (vectorized method)...\n")

# Extract miRNA and position info
data_with_info <- data %>%
  mutate(
    miRNA = `miRNA name`,
    pos_mut = `pos:mut`
  )

# Get ID columns (non-sample columns)
id_cols <- c("miRNA name", "pos:mut", "miRNA", "pos_mut")

# Pivot to long format for vectorized processing
cat("📊 Converting to long format for vectorized processing...\n")

long_data <- data_with_info %>%
  pivot_longer(
    cols = -all_of(id_cols),
    names_to = "Sample",
    values_to = "Count"
  ) %>%
  mutate(
    # Identify if this is SNV or Total column
    is_total = grepl("\\(PM\\+1MM\\+2MM\\)$", Sample),
    Sample_Base = ifelse(is_total, 
                        gsub(" \\(PM\\+1MM\\+2MM\\)$", "", Sample),
                        Sample)
  ) %>%
  # Separate SNV and Total counts
  pivot_wider(
    id_cols = c(`miRNA name`, `pos:mut`, miRNA, pos_mut, Sample_Base),
    names_from = is_total,
    values_from = Count,
    names_prefix = "Count_"
  ) %>%
  rename(
    SNV_Count = Count_FALSE,
    Total_Count = Count_TRUE
  )

cat(sprintf("   ✅ Long format: %s rows\n", format(nrow(long_data), big.mark = ",")))

# Vectorized VAF calculation and filtering
cat("📊 Calculating VAF and filtering (vectorized)...\n")

long_data_filtered <- long_data %>%
  mutate(
    # Calculate VAF for all rows at once (vectorized)
    VAF = ifelse(!is.na(Total_Count) & Total_Count > 0,
                 SNV_Count / Total_Count,
                 NA),
    # Mark filtered values (VAF >= 0.5) as NA
    SNV_Count_Filtered = ifelse(!is.na(VAF) & VAF >= 0.5, NA, SNV_Count)
  )

# Extract filter log (only filtered values)
filter_df <- long_data_filtered %>%
  filter(!is.na(VAF) & VAF >= 0.5) %>%
  select(miRNA, pos_mut, Sample = Sample_Base, SNV_Count, Total_Count, VAF)

total_filtered <- nrow(filter_df)

cat(sprintf("\n   ✅ Total values filtered (VAF >= 0.5): %s\n", format(total_filtered, big.mark = ",")))

# Convert back to wide format for output
cat("📊 Converting back to wide format...\n")

data_filtered <- long_data_filtered %>%
  select(`miRNA name`, `pos:mut`, Sample = Sample_Base, SNV_Count = SNV_Count_Filtered) %>%
  pivot_wider(
    id_cols = c(`miRNA name`, `pos:mut`),
    names_from = Sample,
    values_from = SNV_Count
  ) %>%
  # Merge back with Total columns (not filtered, just need to preserve structure)
  left_join(
    data_with_info %>%
      select(`miRNA name`, `pos:mut`, all_of(total_cols)),
    by = c("miRNA name", "pos:mut")
  )

# ============================================================================
# 3. PREPARE OUTPUT DATA
# ============================================================================

cat("\n📊 Preparing output data...\n")

# Remove helper columns if they exist
data_output <- data_filtered %>%
  select(-any_of(c("miRNA", "pos_mut")))

cat(sprintf("   ✅ Output rows: %s\n", format(nrow(data_output), big.mark = ",")))
cat(sprintf("   ✅ Output columns: %d\n", ncol(data_output)))

# ============================================================================
# 4. GENERATE FILTER REPORT
# ============================================================================

cat("\n📊 Generating filter report...\n")

if (nrow(filter_df) > 0) {
  # Add mutation type for statistics
  filter_df <- filter_df %>%
    mutate(
      Mutation_Type = gsub(".*:", "", pos_mut),
      Mutation_Type = gsub('"', '', Mutation_Type)
    )
  
  # Statistics by mutation type
  stats_by_type <- filter_df %>%
    group_by(Mutation_Type) %>%
    summarise(
      N_Filtered = n(),
      Mean_VAF = mean(VAF, na.rm = TRUE),
      Min_VAF = min(VAF, na.rm = TRUE),
      Max_VAF = max(VAF, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    arrange(desc(N_Filtered))
  
  # Statistics by miRNA
  stats_by_mirna <- filter_df %>%
    group_by(miRNA) %>%
    summarise(
      N_Filtered = n(),
      Mean_VAF = mean(VAF, na.rm = TRUE),
      Samples_Affected = n_distinct(Sample),
      .groups = "drop"
    ) %>%
    arrange(desc(N_Filtered))
  
  cat(sprintf("   ✅ Filter report: %s entries\n", format(nrow(filter_df), big.mark = ",")))
  cat(sprintf("   ✅ Mutation types affected: %d\n", nrow(stats_by_type)))
  cat(sprintf("   ✅ miRNAs affected: %d\n", nrow(stats_by_mirna)))
} else {
  # No filtered values - create empty data frames
  filter_df <- data.frame(
    miRNA = character(0),
    pos_mut = character(0),
    Sample = character(0),
    SNV_Count = numeric(0),
    Total_Count = numeric(0),
    VAF = numeric(0),
    stringsAsFactors = FALSE
  )
  
  stats_by_type <- data.frame(
    Mutation_Type = character(0),
    N_Filtered = integer(0),
    Mean_VAF = numeric(0),
    Min_VAF = numeric(0),
    Max_VAF = numeric(0),
    stringsAsFactors = FALSE
  )
  
  stats_by_mirna <- data.frame(
    miRNA = character(0),
    N_Filtered = integer(0),
    Mean_VAF = numeric(0),
    Samples_Affected = integer(0),
    stringsAsFactors = FALSE
  )
  
  cat("   ⚠️  No values filtered (all VAFs < 0.5)\n")
}

# ============================================================================
# 5. SAVE OUTPUTS
# ============================================================================

cat("\n💾 Saving outputs...\n")

# Create output directory if needed
output_dir <- dirname(output_filtered)
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# SAVE FILTERED DATASET
write.csv(data_output, output_filtered, row.names = FALSE)
cat("   ✅ Filtered dataset:", output_filtered, "\n")

# SAVE FILTER REPORT
write.csv(filter_df, output_report, row.names = FALSE)
cat("   ✅ Filter report:", output_report, "\n")

# SAVE STATISTICS
write.csv(stats_by_type, output_stats_type, row.names = FALSE)
cat("   ✅ Stats by type:", output_stats_type, "\n")

write.csv(stats_by_mirna, output_stats_mirna, row.names = FALSE)
cat("   ✅ Stats by miRNA:", output_stats_mirna, "\n")

# ============================================================================
# SUMMARY
# ============================================================================

cat("\n╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║                    ✅ FILTERING COMPLETE                               ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

cat("📊 Summary:\n")
cat(sprintf("   • Input rows: %s\n", format(nrow(data), big.mark = ",")))
cat(sprintf("   • Output rows: %s\n", format(nrow(data_output), big.mark = ",")))
cat(sprintf("   • Values filtered (VAF >= 0.5): %s\n", format(total_filtered, big.mark = ",")))
cat(sprintf("   • Filter rate: %.2f%%\n", (total_filtered / (nrow(data) * length(snv_cols))) * 100))

cat("\n🚀 NEXT: Generate diagnostic figures\n\n")


# 🎯 STEP 1.5: VAF QUALITY CONTROL - APPLY VAF FILTER (Snakemake version)
# ============================================================================
# Purpose: Filter out technical artifacts (VAF >= 0.5)
# 
# Snakemake parameters:
#   input: Path to original data CSV
#   output: 4 CSV tables (filtered data + reports)
# ============================================================================

library(dplyr)
library(tidyr)
library(readr)

cat("╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║     🎯 STEP 1.5: VAF QUALITY CONTROL - APPLY FILTER                ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

# ============================================================================
# GET SNAKEMAKE PARAMETERS
# ============================================================================

input_file <- snakemake@input[["data"]]
output_filtered <- snakemake@output[["filtered_data"]]
output_report <- snakemake@output[["filter_report"]]
output_stats_type <- snakemake@output[["stats_by_type"]]
output_stats_mirna <- snakemake@output[["stats_by_mirna"]]

cat("📋 Parameters:\n")
cat("   Input:", input_file, "\n")
cat("   Output filtered:", output_filtered, "\n")
cat("   Output report:", output_report, "\n\n")

# ============================================================================
# VALIDATE INPUT
# ============================================================================

# Source validation functions if not already loaded
if (!exists("validate_step1_5_input")) {
  # Try to source validate_input.R
  validate_path <- "scripts/utils/validate_input.R"
  if (file.exists(validate_path)) {
    source(validate_path, local = TRUE)
  }
}

if (exists("validate_step1_5_input")) {
  validate_step1_5_input(input_file)
} else if (exists("validate_input")) {
  validate_input(input_file, 
                expected_format = "csv",
                required_columns = c("miRNA name", "pos:mut"))
}

# ============================================================================
# 1. LOAD DATA
# ============================================================================

cat("📊 Loading collapsed data...\n")
data <- read.csv(input_file, check.names = FALSE)

cat(sprintf("   ✅ Rows: %s\n", format(nrow(data), big.mark = ",")))
cat(sprintf("   ✅ Columns: %d\n", ncol(data)))

# Get column types
sample_cols <- grep("^Magen", names(data), value = TRUE)
total_cols <- grep("\\(PM\\+1MM\\+2MM\\)$", names(data), value = TRUE)
snv_cols <- setdiff(sample_cols, total_cols)

cat(sprintf("   ✅ SNV columns: %d\n", length(snv_cols)))
cat(sprintf("   ✅ Total columns: %d\n", length(total_cols)))

# ============================================================================
# 2. CALCULATE VAF AND IDENTIFY ARTIFACTS (VECTORIZED - MUCH FASTER)
# ============================================================================

cat("\n📊 Calculating VAF for all mutations (vectorized method)...\n")

# Extract miRNA and position info
data_with_info <- data %>%
  mutate(
    miRNA = `miRNA name`,
    pos_mut = `pos:mut`
  )

# Get ID columns (non-sample columns)
id_cols <- c("miRNA name", "pos:mut", "miRNA", "pos_mut")

# Pivot to long format for vectorized processing
cat("📊 Converting to long format for vectorized processing...\n")

long_data <- data_with_info %>%
  pivot_longer(
    cols = -all_of(id_cols),
    names_to = "Sample",
    values_to = "Count"
  ) %>%
  mutate(
    # Identify if this is SNV or Total column
    is_total = grepl("\\(PM\\+1MM\\+2MM\\)$", Sample),
    Sample_Base = ifelse(is_total, 
                        gsub(" \\(PM\\+1MM\\+2MM\\)$", "", Sample),
                        Sample)
  ) %>%
  # Separate SNV and Total counts
  pivot_wider(
    id_cols = c(`miRNA name`, `pos:mut`, miRNA, pos_mut, Sample_Base),
    names_from = is_total,
    values_from = Count,
    names_prefix = "Count_"
  ) %>%
  rename(
    SNV_Count = Count_FALSE,
    Total_Count = Count_TRUE
  )

cat(sprintf("   ✅ Long format: %s rows\n", format(nrow(long_data), big.mark = ",")))

# Vectorized VAF calculation and filtering
cat("📊 Calculating VAF and filtering (vectorized)...\n")

long_data_filtered <- long_data %>%
  mutate(
    # Calculate VAF for all rows at once (vectorized)
    VAF = ifelse(!is.na(Total_Count) & Total_Count > 0,
                 SNV_Count / Total_Count,
                 NA),
    # Mark filtered values (VAF >= 0.5) as NA
    SNV_Count_Filtered = ifelse(!is.na(VAF) & VAF >= 0.5, NA, SNV_Count)
  )

# Extract filter log (only filtered values)
filter_df <- long_data_filtered %>%
  filter(!is.na(VAF) & VAF >= 0.5) %>%
  select(miRNA, pos_mut, Sample = Sample_Base, SNV_Count, Total_Count, VAF)

total_filtered <- nrow(filter_df)

cat(sprintf("\n   ✅ Total values filtered (VAF >= 0.5): %s\n", format(total_filtered, big.mark = ",")))

# Convert back to wide format for output
cat("📊 Converting back to wide format...\n")

data_filtered <- long_data_filtered %>%
  select(`miRNA name`, `pos:mut`, Sample = Sample_Base, SNV_Count = SNV_Count_Filtered) %>%
  pivot_wider(
    id_cols = c(`miRNA name`, `pos:mut`),
    names_from = Sample,
    values_from = SNV_Count
  ) %>%
  # Merge back with Total columns (not filtered, just need to preserve structure)
  left_join(
    data_with_info %>%
      select(`miRNA name`, `pos:mut`, all_of(total_cols)),
    by = c("miRNA name", "pos:mut")
  )

# ============================================================================
# 3. PREPARE OUTPUT DATA
# ============================================================================

cat("\n📊 Preparing output data...\n")

# Remove helper columns if they exist
data_output <- data_filtered %>%
  select(-any_of(c("miRNA", "pos_mut")))

cat(sprintf("   ✅ Output rows: %s\n", format(nrow(data_output), big.mark = ",")))
cat(sprintf("   ✅ Output columns: %d\n", ncol(data_output)))

# ============================================================================
# 4. GENERATE FILTER REPORT
# ============================================================================

cat("\n📊 Generating filter report...\n")

if (nrow(filter_df) > 0) {
  # Add mutation type for statistics
  filter_df <- filter_df %>%
    mutate(
      Mutation_Type = gsub(".*:", "", pos_mut),
      Mutation_Type = gsub('"', '', Mutation_Type)
    )
  
  # Statistics by mutation type
  stats_by_type <- filter_df %>%
    group_by(Mutation_Type) %>%
    summarise(
      N_Filtered = n(),
      Mean_VAF = mean(VAF, na.rm = TRUE),
      Min_VAF = min(VAF, na.rm = TRUE),
      Max_VAF = max(VAF, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    arrange(desc(N_Filtered))
  
  # Statistics by miRNA
  stats_by_mirna <- filter_df %>%
    group_by(miRNA) %>%
    summarise(
      N_Filtered = n(),
      Mean_VAF = mean(VAF, na.rm = TRUE),
      Samples_Affected = n_distinct(Sample),
      .groups = "drop"
    ) %>%
    arrange(desc(N_Filtered))
  
  cat(sprintf("   ✅ Filter report: %s entries\n", format(nrow(filter_df), big.mark = ",")))
  cat(sprintf("   ✅ Mutation types affected: %d\n", nrow(stats_by_type)))
  cat(sprintf("   ✅ miRNAs affected: %d\n", nrow(stats_by_mirna)))
} else {
  # No filtered values - create empty data frames
  filter_df <- data.frame(
    miRNA = character(0),
    pos_mut = character(0),
    Sample = character(0),
    SNV_Count = numeric(0),
    Total_Count = numeric(0),
    VAF = numeric(0),
    stringsAsFactors = FALSE
  )
  
  stats_by_type <- data.frame(
    Mutation_Type = character(0),
    N_Filtered = integer(0),
    Mean_VAF = numeric(0),
    Min_VAF = numeric(0),
    Max_VAF = numeric(0),
    stringsAsFactors = FALSE
  )
  
  stats_by_mirna <- data.frame(
    miRNA = character(0),
    N_Filtered = integer(0),
    Mean_VAF = numeric(0),
    Samples_Affected = integer(0),
    stringsAsFactors = FALSE
  )
  
  cat("   ⚠️  No values filtered (all VAFs < 0.5)\n")
}

# ============================================================================
# 5. SAVE OUTPUTS
# ============================================================================

cat("\n💾 Saving outputs...\n")

# Create output directory if needed
output_dir <- dirname(output_filtered)
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# SAVE FILTERED DATASET
write.csv(data_output, output_filtered, row.names = FALSE)
cat("   ✅ Filtered dataset:", output_filtered, "\n")

# SAVE FILTER REPORT
write.csv(filter_df, output_report, row.names = FALSE)
cat("   ✅ Filter report:", output_report, "\n")

# SAVE STATISTICS
write.csv(stats_by_type, output_stats_type, row.names = FALSE)
cat("   ✅ Stats by type:", output_stats_type, "\n")

write.csv(stats_by_mirna, output_stats_mirna, row.names = FALSE)
cat("   ✅ Stats by miRNA:", output_stats_mirna, "\n")

# ============================================================================
# SUMMARY
# ============================================================================

cat("\n╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║                    ✅ FILTERING COMPLETE                               ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

cat("📊 Summary:\n")
cat(sprintf("   • Input rows: %s\n", format(nrow(data), big.mark = ",")))
cat(sprintf("   • Output rows: %s\n", format(nrow(data_output), big.mark = ",")))
cat(sprintf("   • Values filtered (VAF >= 0.5): %s\n", format(total_filtered, big.mark = ",")))
cat(sprintf("   • Filter rate: %.2f%%\n", (total_filtered / (nrow(data) * length(snv_cols))) * 100))

cat("\n🚀 NEXT: Generate diagnostic figures\n\n")

