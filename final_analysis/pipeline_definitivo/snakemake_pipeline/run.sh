#!/bin/bash
# ============================================================================
# 🚀 Pipeline ALS miRNA Oxidation Analysis - Script Ejecutor Simple
# ============================================================================
# Uso: ./run.sh [input_file.csv]
#
# Ejemplo:
#   ./run.sh /ruta/a/tu/datos/miRNA_count.Q33.txt
#   ./run.sh                            # Usa configuración por defecto
# ============================================================================

set -e  # Salir si hay error

# Directorio del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   🚀 Pipeline ALS miRNA Oxidation Analysis${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# ============================================================================
# 1. VERIFICAR INPUT
# ============================================================================

if [ -n "$1" ]; then
    INPUT_FILE="$1"
    
    if [ ! -f "$INPUT_FILE" ]; then
        echo -e "${YELLOW}⚠️  Archivo no encontrado: $INPUT_FILE${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}📊 Input file: $INPUT_FILE${NC}"
    
    # Actualizar configuración
    # (Por ahora solo muestra el archivo, la actualización automática sería en una versión futura)
    echo -e "${YELLOW}ℹ️  Nota: Actualiza 'config/config.yaml' con esta ruta si es necesario${NC}"
else
    echo -e "${GREEN}📊 Usando configuración por defecto (config/config.yaml)${NC}"
fi

echo ""

# ============================================================================
# 2. VERIFICAR DEPENDENCIAS
# ============================================================================

echo -e "${BLUE}🔍 Verificando dependencias...${NC}"

# Verificar Snakemake
if ! command -v snakemake &> /dev/null; then
    echo -e "${YELLOW}⚠️  Snakemake no encontrado. Instalando...${NC}"
    pip install snakemake || {
        echo -e "${YELLOW}❌ Error instalando Snakemake. Instala manualmente: pip install snakemake${NC}"
        exit 1
    }
fi

echo -e "${GREEN}✅ Snakemake: $(snakemake --version | head -1)${NC}"

# Verificar R
if ! command -v Rscript &> /dev/null; then
    echo -e "${YELLOW}⚠️  R no encontrado. Por favor instala R manualmente.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ R: $(Rscript --version 2>&1 | head -1)${NC}"

echo ""

# ============================================================================
# 3. VALIDAR CONFIGURACIÓN
# ============================================================================

echo -e "${BLUE}⚙️  Validando configuración...${NC}"

if [ ! -f "config/config.yaml" ]; then
    echo -e "${YELLOW}⚠️  config/config.yaml no encontrado${NC}"
    if [ -f "config/config.yaml.example" ]; then
        echo -e "${YELLOW}   Copiando config/config.yaml.example a config/config.yaml${NC}"
        cp config/config.yaml.example config/config.yaml
        echo -e "${YELLOW}   ⚠️  IMPORTANTE: Edita config/config.yaml con tus rutas antes de continuar${NC}"
        exit 1
    else
        echo -e "${YELLOW}❌ Error: No se encontró config/config.yaml ni config/config.yaml.example${NC}"
        exit 1
    fi
fi

# Validar configuración con script R (si está disponible)
if command -v Rscript &> /dev/null && [ -f "scripts/validate_config.R" ]; then
    echo -e "${GREEN}   Ejecutando validación de configuración...${NC}"
    if Rscript scripts/validate_config.R config/config.yaml 2>&1; then
        echo -e "${GREEN}✅ Configuración válida${NC}"
    else
        echo -e "${YELLOW}⚠️  Advertencias en la configuración (continuando...)${NC}"
    fi
else
    echo -e "${YELLOW}   ⚠️  No se pudo validar configuración (Rscript no disponible o script no encontrado)${NC}"
    echo -e "${YELLOW}   Continuando sin validación...${NC}"
fi

echo ""

# ============================================================================
# 4. PREPARAR AMBIENTE
# ============================================================================

echo -e "${BLUE}📦 Preparando ambiente...${NC}"

# Crear directorios de output si no existen
mkdir -p outputs/step1/{figures,tables,logs}
mkdir -p outputs/step1_5/{figures,tables,logs,data}
mkdir -p outputs/step2/{figures,tables,logs}
mkdir -p viewers

echo -e "${GREEN}✅ Directorios creados${NC}"

echo ""

# ============================================================================
# 5. EJECUTAR PIPELINE
# ============================================================================

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   🎯 Iniciando Pipeline${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Detectar número de cores
CORES=$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo "4")

echo -e "${GREEN}🚀 Ejecutando con $CORES cores...${NC}"
echo ""

# Ejecutar pipeline
snakemake -j "$CORES" \
    --use-conda \
    --conda-frontend conda \
    --printshellcmds \
    --reason

# ============================================================================
# 6. RESUMEN
# ============================================================================

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   ✅ Pipeline Completado${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${GREEN}📊 Outputs generados:${NC}"
echo ""
echo "   📈 Figuras Step 1:"
echo "      $(ls -1 outputs/step1/figures/*.png 2>/dev/null | wc -l | tr -d ' ') figuras"
echo ""
echo "   📈 Figuras Step 1.5:"
echo "      $(ls -1 outputs/step1_5/figures/*.png 2>/dev/null | wc -l | tr -d ' ') figuras"
echo ""
echo "   📋 Tablas:"
echo "      $(ls -1 outputs/step1/tables/*.csv outputs/step1_5/tables/*.csv 2>/dev/null | wc -l | tr -d ' ') tablas"
echo ""
echo -e "${GREEN}📄 Viewers HTML:${NC}"
echo ""
if [ -f "viewers/step1.html" ]; then
    echo -e "   ✅ viewers/step1.html"
fi
if [ -f "viewers/step1_5.html" ]; then
    echo -e "   ✅ viewers/step1_5.html"
fi
echo ""
echo -e "${BLUE}💡 Para ver los resultados:${NC}"
echo "   open viewers/step1.html"
echo "   open viewers/step1_5.html"
echo ""

