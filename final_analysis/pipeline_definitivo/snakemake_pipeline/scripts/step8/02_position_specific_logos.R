#!/usr/bin/env Rscript
# ============================================================================
# STEP 8.2: POSITION-SPECIFIC SEQUENCE LOGOS
# ============================================================================
# Purpose: Generate sequence logos for miRNAs with G>T mutations at specific positions
#          Similar to reference paper: shows conserved motifs around oxidized Gs
# ============================================================================
# Input: VAF-filtered data from Step 1.5
# Output: Sequence logos for hotspot positions (2, 3, 5)
# ============================================================================

# Suppress renv messages
options(renv.verbose = FALSE)

# ============================================================================
# SETUP AND LOAD DEPENDENCIES
# ============================================================================

# Get Snakemake parameters
input_vaf_filtered <- snakemake@input[["vaf_filtered"]]
output_logo_pos2 <- snakemake@output[["logo_pos2"]]
output_logo_pos3 <- snakemake@output[["logo_pos3"]]
output_logo_pos5 <- snakemake@output[["logo_pos5"]]
output_summary <- snakemake@output[["logo_summary"]]
seed_start <- as.integer(snakemake@params[["seed_start"]])
seed_end <- as.integer(snakemake@params[["seed_end"]])
hotspot_positions <- as.integer(strsplit(snakemake@params[["hotspot_positions"]], ",")[[1]])

# Source common functions
source(snakemake@input[["functions"]])

# Load required packages
required_packages <- c("dplyr", "tidyr", "readr", "stringr", "ggplot2", 
                       "ggseqlogo", "purrr", "Biostrings")
for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    if (pkg %in% c("Biostrings")) {
      if (!require("BiocManager", quietly = TRUE)) {
        install.packages("BiocManager", repos = "https://cran.r-project.org", quiet = TRUE)
      }
      BiocManager::install("Biostrings", quiet = TRUE, update = FALSE)
      library(Biostrings, character.only = TRUE)
    } else if (pkg == "ggseqlogo") {
      install.packages("ggseqlogo", repos = "https://cran.r-project.org", quiet = TRUE)
      library(ggseqlogo, character.only = TRUE)
    } else {
      install.packages(pkg, repos = "https://cran.r-project.org", quiet = TRUE)
      library(pkg, character.only = TRUE)
    }
  }
}

log_info("═══════════════════════════════════════════════════════════════════")
log_info("  STEP 8.2: POSITION-SPECIFIC SEQUENCE LOGOS")
log_info("═══════════════════════════════════════════════════════════════════")
log_info("")
log_info(paste("Input VAF-filtered data:", input_vaf_filtered))
log_info(paste("Seed region: positions", seed_start, "-", seed_end))
log_info(paste("Hotspot positions:", paste(hotspot_positions, collapse = ", ")))
log_info("")

# ============================================================================
# LOAD DATA
# ============================================================================

log_subsection("Loading VAF-filtered data")

data <- read_csv(input_vaf_filtered, show_col_types = FALSE)

# Normalize column names (use explicit column indexing to avoid evaluation issues)
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

log_info(paste("Data loaded:", nrow(data), "rows"))

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
# GET miRNA SEQUENCES (same function as Step 8.1)
# ============================================================================

log_subsection("Obtaining miRNA sequences from miRBase")

# Function to get sequence from miRBase (same as Step 8.1)
get_mirbase_sequence <- function(mirna_name) {
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
  
  if (mirna_name %in% names(mirbase_db)) {
    return(mirbase_db[[mirna_name]])
  }
  
  mirna_short <- stringr::str_replace(mirna_name, "^hsa-", "")
  if (mirna_short %in% names(mirbase_db)) {
    return(mirbase_db[[mirna_short]])
  }
  
  return(NA_character_)
}

# Get sequences
unique_mirnas <- unique(gt_seed$miRNA_name)
gt_seed <- gt_seed %>%
  mutate(
    mature_sequence = map_chr(miRNA_name, get_mirbase_sequence),
    has_sequence = !is.na(mature_sequence)
  ) %>%
  filter(has_sequence == TRUE)

n_with_sequence <- sum(gt_seed$has_sequence)
log_info(paste("miRNAs with sequences:", n_with_sequence))

# ============================================================================
# EXTRACT WINDOWS AROUND EACH POSITION
# ============================================================================

log_subsection("Extracting sequence windows around G positions")

# Function to extract window around a position
extract_window <- function(sequence, position, window_size = 3) {
  # position is 1-based in full sequence
  # Extract window ±window_size around position
  start_pos <- max(1, position - window_size)
  end_pos <- min(nchar(sequence), position + window_size)
  
  window_seq <- substr(sequence, start_pos, end_pos)
  
  # Pad if necessary to ensure consistent length
  total_length <- 2 * window_size + 1
  if (nchar(window_seq) < total_length) {
    if (position - window_size < 1) {
      # Pad at beginning
      window_seq <- paste0(strrep("N", total_length - nchar(window_seq)), window_seq)
    } else {
      # Pad at end
      window_seq <- paste0(window_seq, strrep("N", total_length - nchar(window_seq)))
    }
  }
  
  return(window_seq)
}

# Create windows for each position
logo_data <- gt_seed %>%
  filter(position %in% hotspot_positions) %>%
  mutate(
    seed_sequence = substr(mature_sequence, 2, 8),
    window_sequence = map2_chr(mature_sequence, position, extract_window, window_size = 3)
  ) %>%
  filter(!is.na(window_sequence), nchar(window_sequence) >= 5)

log_info(paste("Sequence windows extracted:", nrow(logo_data)))

# ============================================================================
# GENERATE LOGOS FOR EACH POSITION
# ============================================================================

log_subsection("Generating sequence logos")

logo_summary <- tibble()

for (pos in hotspot_positions) {
  log_info(paste("Generating logo for position", pos))
  
  # Get sequences for this position
  pos_data <- logo_data %>%
    filter(position == pos)
  
  if (nrow(pos_data) == 0) {
    log_warning(paste("No sequences found for position", pos, "- skipping"))
    next
  }
  
  # Extract sequences
  sequences <- pos_data$window_sequence
  
  # Create logo plot
  logo_plot <- ggseqlogo(sequences, method = "bits") +
    labs(
      title = paste("Sequence Logo: Position", pos, "G>T Mutations"),
      subtitle = paste("Window ±3 around position", pos, "| n =", length(sequences), "miRNAs"),
      x = "Position (relative to G)",
      y = "Bits"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 12, face = "bold"),
      plot.subtitle = element_text(size = 10, color = "grey50"),
      axis.text = element_text(size = 9)
    )
  
  # Save logo
  output_file <- switch(as.character(pos),
                        "2" = output_logo_pos2,
                        "3" = output_logo_pos3,
                        "5" = output_logo_pos5,
                        NA_character_)
  
  if (!is.na(output_file)) {
    ggsave(output_file, logo_plot,
           width = 10, height = 6, dpi = 300, bg = "white")
    log_success(paste("Logo saved:", output_file))
  }
  
  # Add to summary
  logo_summary <- bind_rows(
    logo_summary,
    tibble(
      position = pos,
      n_mirnas = length(sequences),
      sequences = paste(sequences, collapse = ";"),
      unique_sequences = n_distinct(sequences)
    )
  )
}

# ============================================================================
# SAVE SUMMARY TABLE
# ============================================================================

write_csv(logo_summary, output_summary)
log_success(paste("Logo summary saved:", output_summary))

log_success("Step 8.2 completed successfully")

