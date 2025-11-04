#!/bin/bash
# ============================================================================
# 🔧 Script para Preparar Repositorio para GitHub
# ============================================================================
# Este script inicializa el repositorio git y prepara todo para GitHub
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   🔧 Preparación para GitHub${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# ============================================================================
# 1. VERIFICAR QUE config.yaml NO SE SUBIRÁ
# ============================================================================

echo -e "${YELLOW}1. Verificando que config.yaml está en .gitignore...${NC}"

if grep -q "config/config.yaml" .gitignore; then
    echo -e "${GREEN}   ✅ config.yaml está en .gitignore${NC}"
else
    echo -e "${YELLOW}   ⚠️  Agregando config.yaml a .gitignore${NC}"
    echo "config/config.yaml" >> .gitignore
fi

# ============================================================================
# 2. VERIFICAR GIT
# ============================================================================

echo -e "${YELLOW}2. Verificando estado de git...${NC}"

if [ ! -d ".git" ]; then
    echo -e "${YELLOW}   Inicializando repositorio git...${NC}"
    git init
    echo -e "${GREEN}   ✅ Repositorio inicializado${NC}"
else
    echo -e "${GREEN}   ✅ Repositorio git ya existe${NC}"
fi

# ============================================================================
# 3. VERIFICAR ARCHIVOS IMPORTANTES
# ============================================================================

echo -e "${YELLOW}3. Verificando archivos importantes...${NC}"

REQUIRED_FILES=(
    "README.md"
    "Snakefile"
    "config/config.yaml.example"
    ".gitignore"
)

MISSING=0
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}   ✅ $file${NC}"
    else
        echo -e "${YELLOW}   ❌ $file NO encontrado${NC}"
        MISSING=1
    fi
done

if [ $MISSING -eq 1 ]; then
    echo -e "${YELLOW}   ⚠️  Faltan algunos archivos requeridos${NC}"
    exit 1
fi

# ============================================================================
# 4. STATUS DE GIT
# ============================================================================

echo ""
echo -e "${YELLOW}4. Estado actual del repositorio:${NC}"
echo ""
git status --short | head -20 || echo "   (Nuevo repositorio, sin commits aún)"
echo ""

# ============================================================================
# 5. INSTRUCCIONES
# ============================================================================

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   📋 Próximos Pasos${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}Para subir a GitHub, ejecuta:${NC}"
echo ""
echo "1. Agregar archivos:"
echo -e "   ${YELLOW}git add .${NC}"
echo ""
echo "2. Primer commit:"
echo -e "   ${YELLOW}git commit -m \"Initial commit: ALS miRNA oxidation analysis pipeline\"${NC}"
echo ""
echo "3. Crear repositorio en GitHub:"
echo "   - Ve a https://github.com/new"
echo "   - Nombre sugerido: als-mirna-oxidation-pipeline"
echo "   - NO inicialices con README"
echo ""
echo "4. Conectar y subir:"
echo -e "   ${YELLOW}git remote add origin https://github.com/USERNAME/REPO_NAME.git${NC}"
echo -e "   ${YELLOW}git branch -M main${NC}"
echo -e "   ${YELLOW}git push -u origin main${NC}"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Preparación completada${NC}"
echo ""

# ============================================================================
# 🔧 Script para Preparar Repositorio para GitHub
# ============================================================================
# Este script inicializa el repositorio git y prepara todo para GitHub
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   🔧 Preparación para GitHub${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# ============================================================================
# 1. VERIFICAR QUE config.yaml NO SE SUBIRÁ
# ============================================================================

echo -e "${YELLOW}1. Verificando que config.yaml está en .gitignore...${NC}"

if grep -q "config/config.yaml" .gitignore; then
    echo -e "${GREEN}   ✅ config.yaml está en .gitignore${NC}"
else
    echo -e "${YELLOW}   ⚠️  Agregando config.yaml a .gitignore${NC}"
    echo "config/config.yaml" >> .gitignore
fi

# ============================================================================
# 2. VERIFICAR GIT
# ============================================================================

echo -e "${YELLOW}2. Verificando estado de git...${NC}"

if [ ! -d ".git" ]; then
    echo -e "${YELLOW}   Inicializando repositorio git...${NC}"
    git init
    echo -e "${GREEN}   ✅ Repositorio inicializado${NC}"
else
    echo -e "${GREEN}   ✅ Repositorio git ya existe${NC}"
fi

# ============================================================================
# 3. VERIFICAR ARCHIVOS IMPORTANTES
# ============================================================================

echo -e "${YELLOW}3. Verificando archivos importantes...${NC}"

REQUIRED_FILES=(
    "README.md"
    "Snakefile"
    "config/config.yaml.example"
    ".gitignore"
)

MISSING=0
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}   ✅ $file${NC}"
    else
        echo -e "${YELLOW}   ❌ $file NO encontrado${NC}"
        MISSING=1
    fi
done

if [ $MISSING -eq 1 ]; then
    echo -e "${YELLOW}   ⚠️  Faltan algunos archivos requeridos${NC}"
    exit 1
fi

# ============================================================================
# 4. STATUS DE GIT
# ============================================================================

echo ""
echo -e "${YELLOW}4. Estado actual del repositorio:${NC}"
echo ""
git status --short | head -20 || echo "   (Nuevo repositorio, sin commits aún)"
echo ""

# ============================================================================
# 5. INSTRUCCIONES
# ============================================================================

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   📋 Próximos Pasos${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}Para subir a GitHub, ejecuta:${NC}"
echo ""
echo "1. Agregar archivos:"
echo -e "   ${YELLOW}git add .${NC}"
echo ""
echo "2. Primer commit:"
echo -e "   ${YELLOW}git commit -m \"Initial commit: ALS miRNA oxidation analysis pipeline\"${NC}"
echo ""
echo "3. Crear repositorio en GitHub:"
echo "   - Ve a https://github.com/new"
echo "   - Nombre sugerido: als-mirna-oxidation-pipeline"
echo "   - NO inicialices con README"
echo ""
echo "4. Conectar y subir:"
echo -e "   ${YELLOW}git remote add origin https://github.com/USERNAME/REPO_NAME.git${NC}"
echo -e "   ${YELLOW}git branch -M main${NC}"
echo -e "   ${YELLOW}git push -u origin main${NC}"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Preparación completada${NC}"
echo ""

# ============================================================================
# 🔧 Script para Preparar Repositorio para GitHub
# ============================================================================
# Este script inicializa el repositorio git y prepara todo para GitHub
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   🔧 Preparación para GitHub${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# ============================================================================
# 1. VERIFICAR QUE config.yaml NO SE SUBIRÁ
# ============================================================================

echo -e "${YELLOW}1. Verificando que config.yaml está en .gitignore...${NC}"

if grep -q "config/config.yaml" .gitignore; then
    echo -e "${GREEN}   ✅ config.yaml está en .gitignore${NC}"
else
    echo -e "${YELLOW}   ⚠️  Agregando config.yaml a .gitignore${NC}"
    echo "config/config.yaml" >> .gitignore
fi

# ============================================================================
# 2. VERIFICAR GIT
# ============================================================================

echo -e "${YELLOW}2. Verificando estado de git...${NC}"

if [ ! -d ".git" ]; then
    echo -e "${YELLOW}   Inicializando repositorio git...${NC}"
    git init
    echo -e "${GREEN}   ✅ Repositorio inicializado${NC}"
else
    echo -e "${GREEN}   ✅ Repositorio git ya existe${NC}"
fi

# ============================================================================
# 3. VERIFICAR ARCHIVOS IMPORTANTES
# ============================================================================

echo -e "${YELLOW}3. Verificando archivos importantes...${NC}"

REQUIRED_FILES=(
    "README.md"
    "Snakefile"
    "config/config.yaml.example"
    ".gitignore"
)

MISSING=0
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}   ✅ $file${NC}"
    else
        echo -e "${YELLOW}   ❌ $file NO encontrado${NC}"
        MISSING=1
    fi
done

if [ $MISSING -eq 1 ]; then
    echo -e "${YELLOW}   ⚠️  Faltan algunos archivos requeridos${NC}"
    exit 1
fi

# ============================================================================
# 4. STATUS DE GIT
# ============================================================================

echo ""
echo -e "${YELLOW}4. Estado actual del repositorio:${NC}"
echo ""
git status --short | head -20 || echo "   (Nuevo repositorio, sin commits aún)"
echo ""

# ============================================================================
# 5. INSTRUCCIONES
# ============================================================================

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   📋 Próximos Pasos${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}Para subir a GitHub, ejecuta:${NC}"
echo ""
echo "1. Agregar archivos:"
echo -e "   ${YELLOW}git add .${NC}"
echo ""
echo "2. Primer commit:"
echo -e "   ${YELLOW}git commit -m \"Initial commit: ALS miRNA oxidation analysis pipeline\"${NC}"
echo ""
echo "3. Crear repositorio en GitHub:"
echo "   - Ve a https://github.com/new"
echo "   - Nombre sugerido: als-mirna-oxidation-pipeline"
echo "   - NO inicialices con README"
echo ""
echo "4. Conectar y subir:"
echo -e "   ${YELLOW}git remote add origin https://github.com/USERNAME/REPO_NAME.git${NC}"
echo -e "   ${YELLOW}git branch -M main${NC}"
echo -e "   ${YELLOW}git push -u origin main${NC}"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Preparación completada${NC}"
echo ""

