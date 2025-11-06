#!/bin/bash
# ============================================================================
# SETUP SCRIPT - miRNA Oxidation Pipeline
# ============================================================================
# Purpose: Automated setup of the pipeline environment
# Usage: bash setup.sh [--conda|--mamba]
# ============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  🧬 miRNA Oxidation Pipeline - Setup${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
echo ""

# Check for conda/mamba
if command -v mamba &> /dev/null; then
    PACKAGE_MANAGER="mamba"
    echo -e "${GREEN}✅ Mamba found${NC}"
elif command -v conda &> /dev/null; then
    PACKAGE_MANAGER="conda"
    echo -e "${GREEN}✅ Conda found${NC}"
else
    echo -e "${RED}❌ Error: Neither conda nor mamba found${NC}"
    echo "Please install Miniconda or Mamba:"
    echo "  - Miniconda: https://docs.conda.io/en/latest/miniconda.html"
    echo "  - Mamba: https://mamba.readthedocs.io/en/latest/installation.html"
    exit 1
fi

# Override with command line argument
if [[ "${1:-}" == "--conda" ]]; then
    PACKAGE_MANAGER="conda"
elif [[ "${1:-}" == "--mamba" ]]; then
    PACKAGE_MANAGER="mamba"
fi

ENV_NAME="mirna_oxidation_pipeline"
ENV_FILE="envs/r_analysis.yaml"

echo -e "${BLUE}📦 Package Manager: ${PACKAGE_MANAGER}${NC}"
echo -e "${BLUE}🌐 Environment: ${ENV_NAME}${NC}"
echo ""

# Check if environment exists
if ${PACKAGE_MANAGER} env list | grep -q "^${ENV_NAME} "; then
    echo -e "${YELLOW}⚠️  Environment '${ENV_NAME}' already exists${NC}"
    read -p "Do you want to update it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}🔄 Updating environment...${NC}"
        ${PACKAGE_MANAGER} env update -f "${ENV_FILE}" --name "${ENV_NAME}" --prune
    else
        echo -e "${YELLOW}⏭️  Skipping environment creation${NC}"
    fi
else
    echo -e "${BLUE}📦 Creating environment...${NC}"
    ${PACKAGE_MANAGER} env create -f "${ENV_FILE}" --name "${ENV_NAME}"
fi

# Check if envs/r_base.yaml exists and create base environment too
if [[ -f "envs/r_base.yaml" ]]; then
    BASE_ENV_NAME="mirna_oxidation_pipeline_base"
    if ! ${PACKAGE_MANAGER} env list | grep -q "^${BASE_ENV_NAME} "; then
        echo -e "${BLUE}📦 Creating base environment...${NC}"
        ${PACKAGE_MANAGER} env create -f "envs/r_base.yaml" --name "${BASE_ENV_NAME}"
    fi
fi

# Create output directory structure
echo ""
echo -e "${BLUE}📁 Creating output directory structure...${NC}"
if command -v Rscript &> /dev/null; then
    Rscript scripts/utils/create_output_structure.R results
else
    # Fallback: create manually
    mkdir -p results/{step1,step1_5,step2}/{final,intermediate}/{figures,tables,logs}
    mkdir -p results/{pipeline_info,summary,validation,viewers}
    echo -e "${YELLOW}⚠️  Rscript not found, created structure manually${NC}"
fi

# Create config.yaml from example if it doesn't exist
if [[ ! -f "config/config.yaml" ]]; then
    if [[ -f "config/config.yaml.example" ]]; then
        echo -e "${BLUE}📝 Creating config.yaml from example...${NC}"
        cp "config/config.yaml.example" "config/config.yaml"
        echo -e "${YELLOW}⚠️  Please edit config/config.yaml with your data paths${NC}"
    else
        echo -e "${YELLOW}⚠️  config/config.yaml.example not found${NC}"
    fi
else
    echo -e "${GREEN}✅ config/config.yaml already exists${NC}"
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Setup completed successfully!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}📋 Next steps:${NC}"
echo "  1. Activate environment:"
echo "     ${GREEN}conda activate ${ENV_NAME}${NC}"
echo ""
echo "  2. Configure your data paths in config/config.yaml"
echo ""
echo "  3. Test the pipeline (dry-run):"
echo "     ${GREEN}snakemake -n${NC}"
echo ""
echo "  4. Run the pipeline:"
echo "     ${GREEN}snakemake -j 4${NC}"
echo ""
echo -e "${BLUE}📚 For more information, see README.md${NC}"
echo ""
