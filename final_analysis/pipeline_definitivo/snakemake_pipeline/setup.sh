#!/bin/bash
###############################################################################
# Setup Script for ALS miRNA Oxidation Analysis Pipeline
# 
# This script automates the environment setup for the Snakemake pipeline.
# It checks prerequisites, creates conda/mamba environment, and verifies 
# installation.
#
# Usage:
#   bash setup.sh          # Interactive setup
#   bash setup.sh --conda  # Use conda (default)
#   bash setup.sh --mamba # Use mamba (faster)
#   bash setup.sh --check  # Only check existing installation
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Defaults
USE_MAMBA=false
CHECK_ONLY=false
ENV_NAME="als_mirna_pipeline"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --mamba)
            USE_MAMBA=true
            shift
            ;;
        --conda)
            USE_MAMBA=false
            shift
            ;;
        --check)
            CHECK_ONLY=true
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Usage: $0 [--conda|--mamba|--check]"
            exit 1
            ;;
    esac
done

# Functions
print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

check_command() {
    if command -v "$1" &> /dev/null; then
        VERSION=$($1 --version 2>&1 | head -n 1)
        print_success "$1 encontrado: $VERSION"
        return 0
    else
        print_error "$1 no encontrado"
        return 1
    fi
}

# Main execution
main() {
    print_header "🚀 Setup del Pipeline ALS miRNA Oxidation Analysis"
    
    # Detect package manager
    if [ "$USE_MAMBA" = true ]; then
        if check_command mamba; then
            PKG_MANAGER="mamba"
        else
            print_error "Mamba no encontrado. Instala mamba o usa --conda"
            exit 1
        fi
    else
        if check_command conda; then
            PKG_MANAGER="conda"
            # Check if mamba is available (faster alternative)
            if command -v mamba &> /dev/null; then
                print_warning "Mamba está disponible y es más rápido. Considera usar: bash setup.sh --mamba"
            fi
        else
            print_error "Conda no encontrado. Por favor instala Miniconda o Anaconda primero."
            echo "Visita: https://docs.conda.io/en/latest/miniconda.html"
            exit 1
        fi
    fi
    
    # If check only, verify installation and exit
    if [ "$CHECK_ONLY" = true ]; then
        print_header "🔍 Verificando Instalación"
        
        # Check if environment exists
        if $PKG_MANAGER env list | grep -q "^${ENV_NAME} "; then
            print_success "Ambiente '$ENV_NAME' existe"
            
            # Activate and check tools
            eval "$(${PKG_MANAGER} shell.bash hook)"
            conda activate "$ENV_NAME" 2>/dev/null || source activate "$ENV_NAME" 2>/dev/null
            
            check_command snakemake || print_error "Snakemake no encontrado en el ambiente"
            check_command python || print_error "Python no encontrado en el ambiente"
            check_command R || print_error "R no encontrado en el ambiente"
            
            # Check R packages
            echo ""
            print_header "Verificando Paquetes R"
            Rscript -e "
            packages <- c('ggplot2', 'dplyr', 'pheatmap', 'patchwork', 'ggrepel', 'viridis')
            missing <- packages[!packages %in% installed.packages()[,'Package']]
            if(length(missing) == 0) {
                cat('✅ Todos los paquetes R críticos están instalados\n')
            } else {
                cat('❌ Paquetes R faltantes:', paste(missing, collapse=', '), '\n')
                quit(status=1)
            }
            " || print_error "Algunos paquetes R no están instalados"
            
            exit 0
        else
            print_error "Ambiente '$ENV_NAME' no existe. Ejecuta setup.sh sin --check primero."
            exit 1
        fi
    fi
    
    # Check if environment already exists
    if $PKG_MANAGER env list | grep -q "^${ENV_NAME} "; then
        print_warning "El ambiente '$ENV_NAME' ya existe."
        read -p "¿Actualizar el ambiente existente? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_header "🔄 Actualizando Ambiente"
            $PKG_MANAGER env update -f environment.yaml --name "$ENV_NAME" --prune
            print_success "Ambiente actualizado"
        else
            print_warning "Instalación cancelada. El ambiente existe pero no se actualizó."
            exit 0
        fi
    else
        # Create environment
        print_header "📦 Creando Ambiente con $PKG_MANAGER"
        echo "Esto puede tardar 10-15 minutos (5-8 minutos con mamba)..."
        
        $PKG_MANAGER env create -f environment.yaml --name "$ENV_NAME"
        
        print_success "Ambiente '$ENV_NAME' creado exitosamente"
    fi
    
    # Verify installation
    print_header "✅ Verificando Instalación"
    
    # Activate environment
    eval "$(${PKG_MANAGER} shell.bash hook)"
    conda activate "$ENV_NAME" 2>/dev/null || source activate "$ENV_NAME" 2>/dev/null
    
    # Check tools
    echo ""
    check_command snakemake
    check_command python
    check_command R
    
    # Check R packages
    echo ""
    print_header "Verificando Paquetes R"
    Rscript -e "
    packages <- c('ggplot2', 'dplyr', 'pheatmap', 'patchwork', 'ggrepel', 'viridis', 'base64enc')
    missing <- packages[!packages %in% installed.packages()[,'Package']]
    if(length(missing) == 0) {
        cat('✅ Todos los paquetes R críticos están instalados\n')
    } else {
        cat('⚠️  Paquetes faltantes:', paste(missing, collapse=', '), '\n')
        cat('Instalando paquetes faltantes...\n')
        install.packages(missing, repos='https://cloud.r-project.org')
    }
    "
    
    # Final instructions
    print_header "🎉 Instalación Completada"
    echo ""
    echo "Para usar el pipeline:"
    echo ""
    echo "  1. Activa el ambiente:"
    echo "     conda activate $ENV_NAME"
    echo "     # o con mamba:"
    echo "     mamba activate $ENV_NAME"
    echo ""
    echo "  2. Configura los datos en config/config.yaml:"
    echo "     cp config/config.yaml.example config/config.yaml"
    echo "     nano config/config.yaml"
    echo ""
    echo "  3. Prueba el pipeline (dry-run):"
    echo "     snakemake -n"
    echo ""
    echo "  4. Ejecuta el pipeline:"
    echo "     snakemake -j 4"
    echo ""
    echo "Para más información, consulta SETUP.md o README.md"
    echo ""
    print_success "¡Listo para usar el pipeline!"
}

# Run main function
main "$@"

