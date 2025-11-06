#!/usr/bin/env Rscript
# ============================================================================
# STEP 8.1: TRINUCLEOTIDE CONTEXT ANALYSIS (XGY)
# ============================================================================
# Purpose: Analyze trinucleotide context (XGY) around G>T mutations
#          Similar to reference paper: "Widespread 8-oxoguanine modifications..."
#          Identifies enrichment of GG, CG, AG, UG contexts
# ============================================================================
# Input: VAF-filtered data from Step 1.5
# Output: Enrichment tables and figures
# ============================================================================

# Suppress renv messages
options(renv.verbose = FALSE)

# ============================================================================
# SETUP AND LOAD DEPENDENCIES
# ============================================================================

# Get Snakemake parameters
input_vaf_filtered <- snakemake@input[["vaf_filtered"]]
output_enrichment <- snakemake@output[["enrichment_table"]]
output_summary <- snakemake@output[["context_summary"]]
output_figure <- snakemake@output[["figure"]]
seed_start <- as.integer(snakemake@params[["seed_start"]])
seed_end <- as.integer(snakemake@params[["seed_end"]])

# Source common functions
source(snakemake@input[["functions"]])

# Load required packages
required_packages <- c("dplyr", "tidyr", "readr", "stringr", "ggplot2", 
                       "patchwork", "purrr", "Biostrings")
for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    if (pkg %in% c("Biostrings")) {
      if (!require("BiocManager", quietly = TRUE)) {
        install.packages("BiocManager", repos = "https://cran.r-project.org", quiet = TRUE)
      }
      BiocManager::install("Biostrings", quiet = TRUE, update = FALSE)
      library(Biostrings, character.only = TRUE)
    } else {
      install.packages(pkg, repos = "https://cran.r-project.org", quiet = TRUE)
      library(pkg, character.only = TRUE)
    }
  }
}

log_info("═══════════════════════════════════════════════════════════════════")
log_info("  STEP 8.1: TRINUCLEOTIDE CONTEXT ANALYSIS (XGY)")
log_info("═══════════════════════════════════════════════════════════════════")
log_info("")
log_info(paste("Input VAF-filtered data:", input_vaf_filtered))
log_info(paste("Seed region: positions", seed_start, "-", seed_end))
log_info("")

# ============================================================================
# LOAD DATA
# ============================================================================

log_subsection("Loading VAF-filtered data")

data <- read_csv(input_vaf_filtered, show_col_types = FALSE)

# Normalize column names (handle both "miRNA name" and "miRNA_name")
# Use explicit column indexing to avoid evaluation issues
col_names <- names(data)
if ("miRNA name" %in% col_names) {
  col_names[col_names == "miRNA name"] <- "miRNA_name"
  names(data) <- col_names
} else if (!"miRNA_name" %in% col_names) {
  stop("ERROR: Neither 'miRNA name' nor 'miRNA_name' column found in data!")
}

col_names <- names(data)
if ("pos:mut" %in% col_names) {
  col_names[col_names == "pos:mut"] <- "pos.mut"
  names(data) <- col_names
} else if (!"pos.mut" %in% col_names) {
  stop("ERROR: Neither 'pos:mut' nor 'pos.mut' column found in data!")
}

# Verify required columns exist
if (!"miRNA_name" %in% names(data)) {
  stop("ERROR: miRNA_name column not found after normalization!")
}
if (!"pos.mut" %in% names(data)) {
  stop("ERROR: pos.mut column not found after normalization!")
}

log_info(paste("Data loaded:", nrow(data), "rows"))
log_info(paste("Columns:", paste(names(data)[1:min(5, length(names(data)))], collapse = ", "), "..."))

# Filter G>T mutations in seed region
gt_seed <- data %>%
  filter(
    str_detect(pos.mut, ":GT$"),
    !is.na(miRNA_name)
  ) %>%
  mutate(
    position = as.numeric(str_extract(pos.mut, "^\\d+")),
    in_seed = position >= seed_start & position <= seed_end
  ) %>%
  filter(in_seed == TRUE) %>%
  distinct(miRNA_name, pos.mut, .keep_all = TRUE)

log_info(paste("G>T mutations in seed region:", nrow(gt_seed), "unique mutations"))

# ============================================================================
# GET miRNA SEQUENCES (miRBase)
# ============================================================================

log_subsection("Obtaining miRNA sequences from miRBase")

# Function to get sequence from miRBase (using a curated database)
# In a full implementation, this would download from miRBase or use a package
get_mirbase_sequence <- function(mirna_name) {
  # Try to extract mature sequence from miRBase
  # For now, we'll use a curated list of common sequences
  # TODO: In production, use miRBaseConverter or download mature.fa
  
  # Common miRNA sequences (can be expanded)
  mirbase_db <- list(
    "hsa-miR-16-5p" = "UAGCAGCACGUAAAUAUUGGCG",
    "hsa-let-7a-5p" = "UGAGGUAGUAGGUUGUAUAGUU",
    "hsa-let-7b-5p" = "UGAGGUAGUAGGUUGUGUGGUU",
    "hsa-let-7c-5p" = "UGAGGUAGUAGGUUGUAUGGUU",
    "hsa-let-7d-5p" = "AGAGGUAGUAGGUUGCAUAGUU",
    "hsa-let-7e-5p" = "UGAGGUAGGAGGUUGUAUAGUU",
    "hsa-let-7f-5p" = "UGAGGUAGUAGAUUGUAUAGUU",
    "hsa-let-7g-5p" = "UGAGGUAGUAGUUUGUACAGUU",
    "hsa-let-7i-5p" = "UGAGGUAGUAGUUUGUGCUGUU",
    "hsa-miR-1-3p" = "UGGAAUGUAAAGAAGUAUGUAU",
    "hsa-miR-21-5p" = "UAGCUUAUCAGACUGAUGUUGA",
    "hsa-miR-122-5p" = "UGGAGUGUGACAAUGGUGUUUG",
    "hsa-miR-191-5p" = "CAACGGAAUCCCAAAAGCAGCUG",
    "hsa-miR-103a-3p" = "AGCAGCAUUGUACAGGGCUAUGA",
    "hsa-miR-486-5p" = "UCCUGUACUGAGCUGCCCCGAG",
    "hsa-miR-93-5p" = "CAAAGUGCUGUUCGUGCAGGUAG",
    "hsa-miR-423-5p" = "UGAGGGGCAGAGAGCGAGACUUU"
  )
  
  # Try exact match first
  if (mirna_name %in% names(mirbase_db)) {
    return(mirbase_db[[mirna_name]])
  }
  
  # Try without hsa- prefix
  mirna_short <- stringr::str_replace(mirna_name, "^hsa-", "")
  if (mirna_short %in% names(mirbase_db)) {
    return(mirbase_db[[mirna_short]])
  }
  
  # Return NA if not found
  return(NA_character_)
}

# Get sequences for all unique miRNAs
unique_mirnas <- unique(gt_seed$miRNA_name)
gt_seed <- gt_seed %>%
  mutate(
    mature_sequence = map_chr(miRNA_name, get_mirbase_sequence),
    has_sequence = !is.na(mature_sequence)
  )

n_with_sequence <- sum(gt_seed$has_sequence)
log_info(paste("miRNAs with sequences found:", n_with_sequence, "/", length(unique_mirnas)))

# Filter to only those with sequences
gt_seed <- gt_seed %>%
  filter(has_sequence == TRUE)

# ============================================================================
# EXTRACT TRINUCLEOTIDE CONTEXT (XGY)
# ============================================================================

log_subsection("Extracting trinucleotide context (XGY)")

trinucleotide_data <- gt_seed %>%
  mutate(
    # Extract seed region (positions 2-8, which is indices 2-8 in 1-based)
    seed_sequence = substr(mature_sequence, 2, 8),
    
    # Get position in full sequence (position from pos.mut)
    # Position in seed = position - 1 (because seed starts at position 2)
    position_in_seed = position - 1,
    
    # Extract trinucleotide context (XGY)
    # X = nucleotide before G (position - 1 in seed)
    # G = the G being oxidized (position in seed)
    # Y = nucleotide after G (position + 1 in seed)
    context_before = if_else(position_in_seed > 1,
                            substr(seed_sequence, position_in_seed - 1, position_in_seed - 1),
                            NA_character_),
    context_after = if_else(position_in_seed < nchar(seed_sequence),
                            substr(seed_sequence, position_in_seed + 1, position_in_seed + 1),
                            NA_character_),
    
    # Create trinucleotide string (XGY)
    trinucleotide = if_else(
      !is.na(context_before) & !is.na(context_after),
      paste0(context_before, "G", context_after),
      NA_character_
    ),
    
    # Classify context type
    context_type = case_when(
      context_before == "G" ~ "GpG",
      context_before == "C" ~ "CpG",
      context_before == "A" ~ "ApG",
      context_before == "U" ~ "UpG",
      TRUE ~ "Unknown"
    ),
    
    # Context category (for analysis)
    context_category = case_when(
      context_type == "GpG" ~ "High Oxidation (GpG)",
      context_type == "CpG" ~ "Moderate (CpG)",
      context_type %in% c("ApG", "UpG") ~ "Low Oxidation",
      TRUE ~ "Unknown"
    )
  ) %>%
  filter(!is.na(trinucleotide))

log_info(paste("Trinucleotide contexts extracted:", nrow(trinucleotide_data)))

# ============================================================================
# CALCULATE ENRICHMENT
# ============================================================================

log_subsection("Calculating context enrichment")

# Count contexts
context_counts <- trinucleotide_data %>%
  filter(!is.na(context_type)) %>%
  count(context_type) %>%
  mutate(
    percentage = round(100 * n / sum(n), 2),
    expected_percentage = 25.0  # If random, each context should be 25%
  )

# Test for GpG enrichment (binomial test)
n_GpG <- sum(trinucleotide_data$context_type == "GpG", na.rm = TRUE)
n_total <- sum(!is.na(trinucleotide_data$context_type))

if (n_total > 0 && n_GpG > 0) {
  binom_test <- binom.test(n_GpG, n_total, p = 0.25, alternative = "greater")
  GpG_pvalue <- binom_test$p.value
  GpG_enriched <- binom_test$p.value < 0.05
} else {
  GpG_pvalue <- NA_real_
  GpG_enriched <- FALSE
}

log_info(paste("GpG context:", round(100 * n_GpG / n_total, 1), "%"))
log_info(paste("GpG enrichment p-value:", format(GpG_pvalue, scientific = TRUE, digits = 3)))
log_info(paste("GpG enriched:", ifelse(GpG_enriched, "YES ✅", "NO ❌")))

# Create enrichment table
enrichment_table <- context_counts %>%
  mutate(
    expected_count = round(n_total * 0.25),
    enrichment_ratio = round(n / expected_count, 3),
    p_value = if_else(context_type == "GpG", GpG_pvalue, NA_real_),
    significant = if_else(context_type == "GpG" & GpG_enriched, TRUE, FALSE)
  )

# ============================================================================
# CREATE SUMMARY TABLE
# ============================================================================

context_summary <- trinucleotide_data %>%
  group_by(miRNA_name, position, context_type) %>%
  summarise(
    n_mutations = n(),
    trinucleotide = trinucleotide[1],  # Use indexing instead of first() to avoid Biostrings conflict
    .groups = "drop"
  ) %>%
  arrange(desc(n_mutations))

# ============================================================================
# CREATE VISUALIZATION
# ============================================================================

log_subsection("Creating visualization")

# Panel A: Context distribution
p1 <- ggplot(context_counts, aes(x = reorder(context_type, percentage), y = percentage, fill = context_type)) +
  geom_col(alpha = 0.8) +
  geom_hline(yintercept = 25, linetype = "dashed", color = "grey50", linewidth = 1) +
  scale_fill_manual(
    values = c("GpG" = "#D62728", "CpG" = "#FF7F0E", "ApG" = "#2CA02C", "UpG" = "#1F77B4"),
    guide = "none"
  ) +
  coord_flip() +
  labs(
    title = "Trinucleotide Context Distribution (XGY)",
    subtitle = paste("G>T mutations in seed region (positions", seed_start, "-", seed_end, ")"),
    x = "Context Type",
    y = "Percentage (%)",
    caption = paste("Total contexts:", n_total, "| GpG p-value:", format(GpG_pvalue, scientific = TRUE, digits = 2))
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 12, face = "bold"),
    plot.subtitle = element_text(size = 10, color = "grey50"),
    axis.text = element_text(size = 9)
  )

# Panel B: Enrichment ratio
p2 <- ggplot(enrichment_table, aes(x = reorder(context_type, enrichment_ratio), y = enrichment_ratio, fill = significant)) +
  geom_col(alpha = 0.8) +
  geom_hline(yintercept = 1.0, linetype = "dashed", color = "grey50", linewidth = 1) +
  scale_fill_manual(
    values = c("TRUE" = "#D62728", "FALSE" = "grey70"),
    guide = "none"
  ) +
  coord_flip() +
  labs(
    title = "Context Enrichment Ratio",
    subtitle = "Observed / Expected (expected = 25% if random)",
    x = "Context Type",
    y = "Enrichment Ratio",
    caption = paste("Enrichment > 1 = more frequent than expected")
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 12, face = "bold"),
    plot.subtitle = element_text(size = 10, color = "grey50"),
    axis.text = element_text(size = 9)
  )

# Combine panels
combined_plot <- p1 / p2 +
  plot_annotation(
    title = "Trinucleotide Context Analysis (XGY)",
    subtitle = paste("Analysis of sequence context around G>T mutations | n =", n_total, "contexts")
  )

ggsave(output_figure, combined_plot,
       width = 12, height = 10, dpi = 300, bg = "white")

log_success(paste("Figure saved:", output_figure))

# ============================================================================
# SAVE TABLES
# ============================================================================

write_csv(enrichment_table, output_enrichment)
write_csv(context_summary, output_summary)

log_success(paste("Enrichment table saved:", output_enrichment))
log_success(paste("Context summary saved:", output_summary))

log_success("Step 8.1 completed successfully")

