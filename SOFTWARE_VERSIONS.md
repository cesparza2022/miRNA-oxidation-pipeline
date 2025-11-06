# 📦 Software Versions and Environment Setup

This document lists all software versions used in the pipeline to ensure reproducibility.

## 🔧 System Requirements

### Operating System
- **macOS**: 10.15+ (tested on macOS 14.1)
- **Linux**: Ubuntu 20.04+ or similar (compatible)
- **Windows**: Not directly supported (use WSL or Docker)

### Package Managers
- **Conda/Mamba**: Required for environment management
  - Recommended: Mamba (faster) or Conda (miniconda/anaconda)
  - Install: https://docs.conda.io/en/latest/miniconda.html

---

## 🐍 Python and Snakemake

### Python
- **Version**: 3.10.*
- **Source**: conda-forge

### Snakemake
- **Version**: >=7.0, <10.0
- **Tested Version**: 9.13.4
- **Source**: conda-forge
- **Installation**: `conda install -c conda-forge snakemake`

---

## 📊 R and R Packages

### R Base
- **Version**: 4.3.2
- **Platform**: aarch64-apple-darwin20 (Mac M1/M2) or x86_64 (Intel)
- **Source**: conda-forge

### R Packages (Core)

| Package | Version | Purpose |
|---------|---------|---------|
| **tidyverse** | >=2.0.0 | Core data manipulation suite |
| **ggplot2** | >=3.4.0 | Data visualization |
| **dplyr** | >=1.1.0 | Data manipulation |
| **tidyr** | >=1.3.0 | Data reshaping |
| **readr** | >=2.1.0 | Fast CSV/TSV reading |
| **stringr** | >=1.5.0 | String manipulation |
| **tibble** | >=3.2.0 | Modern data frames |
| **scales** | >=1.2.0 | Scale functions for plots |
| **purrr** | >=1.0.0 | Functional programming |
| **forcats** | >=1.0.0 | Factor manipulation |

### R Packages (Visualization)

| Package | Version | Purpose |
|---------|---------|---------|
| **patchwork** | >=1.1.0 | Combine multiple ggplot2 plots |
| **ggrepel** | >=0.9.0 | Text labels that don't overlap |
| **pheatmap** | >=1.0.12 | Professional heatmaps |
| **viridis** | >=0.6.0 | Color scales for plots |
| **RColorBrewer** | >=1.1.3 | Color palettes |
| **reshape2** | >=1.4.4 | Data reshaping (melt/cast) |

### R Packages (Statistics)

| Package | Version | Purpose |
|---------|---------|---------|
| **pROC** | >=1.18.0 | ROC curve analysis (Step 4) |
| **e1071** | >=1.7.13 | Statistical functions |
| **cluster** | >=2.1.4 | Clustering algorithms (Step 7) |
| **factoextra** | >=1.0.7 | Extract and visualize clustering results (Step 7) |
| **stats** | Built-in | Base R statistical functions |

### R Packages (Utilities)

| Package | Version | Purpose |
|---------|---------|---------|
| **yaml** | >=2.3.7 | Parse config.yaml files |
| **jsonlite** | >=1.8.7 | JSON parsing (optional, for metadata) |
| **base64enc** | >=0.1.3 | Base64 encoding (optional) |

---

## 🚀 Quick Environment Setup

### Option 1: Using Conda/Mamba (Recommended)

```bash
# Clone repository
git clone https://github.com/cesparza2022/miRNA-oxidation-pipeline.git
cd miRNA-oxidation-pipeline

# Create environment from environment.yml
conda env create -f environment.yml

# Activate environment
conda activate mirna_oxidation_pipeline

# Verify installations
R --version  # Should show R 4.3.2
snakemake --version  # Should show >=7.0

# Verify R packages
R --slave -e "library(tidyverse); library(ggplot2); library(pROC); cat('All packages loaded successfully\n')"
```

### Option 2: Manual Installation

If you prefer to install manually:

```bash
# Install R and Python
conda install -c conda-forge r-base=4.3.2 python=3.10

# Install Snakemake
conda install -c conda-forge snakemake>=7.0

# Install R packages
R --slave -e "
install.packages(c(
  'tidyverse', 'ggplot2', 'readr', 'stringr', 'scales',
  'patchwork', 'ggrepel', 'pheatmap', 'RColorBrewer',
  'pROC', 'dplyr', 'tidyr', 'jsonlite', 'base64enc',
  'yaml', 'reshape2', 'viridis', 'e1071', 'cluster', 'factoextra'
), repos='https://cran.rstudio.com/')
"
```

---

## 📋 Package Usage by Step

### Step 1: Exploratory Analysis
- `tidyverse`, `ggplot2`, `readr`, `stringr`, `scales`

### Step 1.5: VAF Quality Control
- `tidyverse`, `ggplot2`, `readr`, `stringr`, `scales`, `pheatmap`, `RColorBrewer`

### Step 2: Statistical Comparisons
- `tidyverse`, `ggplot2`, `readr`, `scales`, `dplyr`, `tidyr`

### Step 3: Functional Analysis
- `tidyverse`, `ggplot2`, `readr`, `stringr`, `patchwork`, `scales`, `ggrepel`, `pheatmap`, `RColorBrewer`

### Step 4: Biomarker Analysis
- `tidyverse`, `ggplot2`, `readr`, `pROC`, `patchwork`, `scales`

### Step 5: miRNA Family Analysis
- `tidyverse`, `ggplot2`, `readr`, `stringr`, `pheatmap`, `RColorBrewer`, `scales`

### Step 6: Expression vs Oxidation Correlation
- `tidyverse`, `ggplot2`, `readr`, `stringr`, `scales`, `ggrepel`

### Step 7: Clustering Analysis
- `tidyverse`, `readr`, `stringr`, `pheatmap`, `RColorBrewer`, `cluster`, `factoextra` (optional)

---

## 🔍 Verifying Your Environment

After setup, verify all packages are installed:

```bash
# Check R version
R --version

# Check Snakemake version
snakemake --version

# Check R packages
R --slave -e "
required <- c('tidyverse', 'ggplot2', 'readr', 'stringr', 'scales',
              'patchwork', 'ggrepel', 'pheatmap', 'RColorBrewer',
              'pROC', 'dplyr', 'tidyr', 'yaml')
missing <- c()
for(pkg in required) {
  if(!requireNamespace(pkg, quietly=TRUE)) {
    missing <- c(missing, pkg)
  }
}
if(length(missing) == 0) {
  cat('✅ All required packages are installed\n')
} else {
  cat('❌ Missing packages:', paste(missing, collapse=', '), '\n')
}
"
```

---

## 📝 Notes

- **R 4.3.2** is the minimum tested version. R 4.4.3 should also work.
- **Snakemake 7.0+** is required. Tested with 9.13.4.
- All R packages are available from CRAN (no Bioconductor required for core pipeline).
- If you encounter issues, try updating packages: `conda update --all` or `R --slave -e "update.packages(ask=FALSE)"`.

---

**Last Updated**: 2025-11-03  
**Tested On**: macOS 14.1, R 4.4.3, Snakemake 9.13.4

