#!/bin/bash
# ============================================================================
# 🚀 Script para Conectar y Subir Código a GitHub
# ============================================================================
# Uso: ./push_to_github.sh <URL_DEL_REPOSITORIO>
#
# Ejemplo:
#   ./push_to_github.sh https://github.com/USERNAME/als-mirna-oxidation-pipeline.git
# ============================================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Verificar que se pasó la URL
if [ -z "$1" ]; then
    echo -e "${RED}❌ Error: Necesitas proporcionar la URL del repositorio${NC}"
    echo ""
    echo "Uso: ./push_to_github.sh <URL>"
    echo ""
    echo "Ejemplo:"
    echo "  ./push_to_github.sh https://github.com/USERNAME/als-mirna-oxidation-pipeline.git"
    exit 1
fi

REPO_URL="$1"

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   🚀 Conectando con GitHub${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Verificar que estamos en un repositorio git
if [ ! -d ".git" ]; then
    echo -e "${RED}❌ Error: No estás en un repositorio git${NC}"
    exit 1
fi

# Verificar que hay commits
if ! git rev-parse HEAD > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: No hay commits en el repositorio${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 Repositorio URL: ${REPO_URL}${NC}"
echo ""

# Verificar si ya existe un remote origin
if git remote get-url origin > /dev/null 2>&1; then
    CURRENT_URL=$(git remote get-url origin)
    echo -e "${YELLOW}⚠️  Ya existe un remote 'origin':${NC}"
    echo "   $CURRENT_URL"
    echo ""
    read -p "¿Quieres reemplazarlo? (s/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        git remote remove origin
        echo -e "${GREEN}✅ Remote anterior eliminado${NC}"
    else
        echo -e "${YELLOW}Cancelado. Usando remote existente.${NC}"
        REPO_URL="$CURRENT_URL"
    fi
fi

# Agregar remote
if ! git remote get-url origin > /dev/null 2>&1; then
    echo -e "${YELLOW}📡 Agregando remote 'origin'...${NC}"
    git remote add origin "$REPO_URL"
    echo -e "${GREEN}✅ Remote agregado${NC}"
fi

# Verificar branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo -e "${YELLOW}🔄 Renombrando branch a 'main'...${NC}"
    git branch -M main
    echo -e "${GREEN}✅ Branch renombrado a 'main'${NC}"
fi

# Push inicial
echo ""
echo -e "${YELLOW}📤 Subiendo código a GitHub...${NC}"
echo ""

if git push -u origin main; then
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}   ✅ ¡Código subido exitosamente a GitHub!${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}🎉 Tu repositorio está disponible en:${NC}"
    REPO_WEB_URL=$(echo "$REPO_URL" | sed 's/\.git$//' | sed 's/git@github\.com:/https:\/\/github.com\//')
    echo -e "   ${BLUE}$REPO_WEB_URL${NC}"
    echo ""
    echo -e "${GREEN}📋 Próximos pasos:${NC}"
    echo "   1. Ve a tu repositorio en GitHub"
    echo "   2. Verifica que todos los archivos estén ahí"
    echo "   3. Ahora puedes trabajar normalmente:"
    echo "      • git add ."
    echo "      • git commit -m \"mensaje\""
    echo "      • git push"
    echo ""
else
    echo ""
    echo -e "${RED}❌ Error al hacer push${NC}"
    echo ""
    echo "Posibles causas:"
    echo "   • URL incorrecta"
    echo "   • Problemas de autenticación"
    echo "   • El repositorio no existe o no tienes permisos"
    echo ""
    echo "Solución:"
    echo "   1. Verifica que la URL sea correcta"
    echo "   2. Verifica que el repositorio existe en GitHub"
    echo "   3. Si es privado, asegúrate de estar autenticado"
    exit 1
fi

# ============================================================================
# 🚀 Script para Conectar y Subir Código a GitHub
# ============================================================================
# Uso: ./push_to_github.sh <URL_DEL_REPOSITORIO>
#
# Ejemplo:
#   ./push_to_github.sh https://github.com/USERNAME/als-mirna-oxidation-pipeline.git
# ============================================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Verificar que se pasó la URL
if [ -z "$1" ]; then
    echo -e "${RED}❌ Error: Necesitas proporcionar la URL del repositorio${NC}"
    echo ""
    echo "Uso: ./push_to_github.sh <URL>"
    echo ""
    echo "Ejemplo:"
    echo "  ./push_to_github.sh https://github.com/USERNAME/als-mirna-oxidation-pipeline.git"
    exit 1
fi

REPO_URL="$1"

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   🚀 Conectando con GitHub${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Verificar que estamos en un repositorio git
if [ ! -d ".git" ]; then
    echo -e "${RED}❌ Error: No estás en un repositorio git${NC}"
    exit 1
fi

# Verificar que hay commits
if ! git rev-parse HEAD > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: No hay commits en el repositorio${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 Repositorio URL: ${REPO_URL}${NC}"
echo ""

# Verificar si ya existe un remote origin
if git remote get-url origin > /dev/null 2>&1; then
    CURRENT_URL=$(git remote get-url origin)
    echo -e "${YELLOW}⚠️  Ya existe un remote 'origin':${NC}"
    echo "   $CURRENT_URL"
    echo ""
    read -p "¿Quieres reemplazarlo? (s/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        git remote remove origin
        echo -e "${GREEN}✅ Remote anterior eliminado${NC}"
    else
        echo -e "${YELLOW}Cancelado. Usando remote existente.${NC}"
        REPO_URL="$CURRENT_URL"
    fi
fi

# Agregar remote
if ! git remote get-url origin > /dev/null 2>&1; then
    echo -e "${YELLOW}📡 Agregando remote 'origin'...${NC}"
    git remote add origin "$REPO_URL"
    echo -e "${GREEN}✅ Remote agregado${NC}"
fi

# Verificar branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo -e "${YELLOW}🔄 Renombrando branch a 'main'...${NC}"
    git branch -M main
    echo -e "${GREEN}✅ Branch renombrado a 'main'${NC}"
fi

# Push inicial
echo ""
echo -e "${YELLOW}📤 Subiendo código a GitHub...${NC}"
echo ""

if git push -u origin main; then
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}   ✅ ¡Código subido exitosamente a GitHub!${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}🎉 Tu repositorio está disponible en:${NC}"
    REPO_WEB_URL=$(echo "$REPO_URL" | sed 's/\.git$//' | sed 's/git@github\.com:/https:\/\/github.com\//')
    echo -e "   ${BLUE}$REPO_WEB_URL${NC}"
    echo ""
    echo -e "${GREEN}📋 Próximos pasos:${NC}"
    echo "   1. Ve a tu repositorio en GitHub"
    echo "   2. Verifica que todos los archivos estén ahí"
    echo "   3. Ahora puedes trabajar normalmente:"
    echo "      • git add ."
    echo "      • git commit -m \"mensaje\""
    echo "      • git push"
    echo ""
else
    echo ""
    echo -e "${RED}❌ Error al hacer push${NC}"
    echo ""
    echo "Posibles causas:"
    echo "   • URL incorrecta"
    echo "   • Problemas de autenticación"
    echo "   • El repositorio no existe o no tienes permisos"
    echo ""
    echo "Solución:"
    echo "   1. Verifica que la URL sea correcta"
    echo "   2. Verifica que el repositorio existe en GitHub"
    echo "   3. Si es privado, asegúrate de estar autenticado"
    exit 1
fi

# ============================================================================
# 🚀 Script para Conectar y Subir Código a GitHub
# ============================================================================
# Uso: ./push_to_github.sh <URL_DEL_REPOSITORIO>
#
# Ejemplo:
#   ./push_to_github.sh https://github.com/USERNAME/als-mirna-oxidation-pipeline.git
# ============================================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Verificar que se pasó la URL
if [ -z "$1" ]; then
    echo -e "${RED}❌ Error: Necesitas proporcionar la URL del repositorio${NC}"
    echo ""
    echo "Uso: ./push_to_github.sh <URL>"
    echo ""
    echo "Ejemplo:"
    echo "  ./push_to_github.sh https://github.com/USERNAME/als-mirna-oxidation-pipeline.git"
    exit 1
fi

REPO_URL="$1"

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   🚀 Conectando con GitHub${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Verificar que estamos en un repositorio git
if [ ! -d ".git" ]; then
    echo -e "${RED}❌ Error: No estás en un repositorio git${NC}"
    exit 1
fi

# Verificar que hay commits
if ! git rev-parse HEAD > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: No hay commits en el repositorio${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 Repositorio URL: ${REPO_URL}${NC}"
echo ""

# Verificar si ya existe un remote origin
if git remote get-url origin > /dev/null 2>&1; then
    CURRENT_URL=$(git remote get-url origin)
    echo -e "${YELLOW}⚠️  Ya existe un remote 'origin':${NC}"
    echo "   $CURRENT_URL"
    echo ""
    read -p "¿Quieres reemplazarlo? (s/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        git remote remove origin
        echo -e "${GREEN}✅ Remote anterior eliminado${NC}"
    else
        echo -e "${YELLOW}Cancelado. Usando remote existente.${NC}"
        REPO_URL="$CURRENT_URL"
    fi
fi

# Agregar remote
if ! git remote get-url origin > /dev/null 2>&1; then
    echo -e "${YELLOW}📡 Agregando remote 'origin'...${NC}"
    git remote add origin "$REPO_URL"
    echo -e "${GREEN}✅ Remote agregado${NC}"
fi

# Verificar branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo -e "${YELLOW}🔄 Renombrando branch a 'main'...${NC}"
    git branch -M main
    echo -e "${GREEN}✅ Branch renombrado a 'main'${NC}"
fi

# Push inicial
echo ""
echo -e "${YELLOW}📤 Subiendo código a GitHub...${NC}"
echo ""

if git push -u origin main; then
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}   ✅ ¡Código subido exitosamente a GitHub!${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}🎉 Tu repositorio está disponible en:${NC}"
    REPO_WEB_URL=$(echo "$REPO_URL" | sed 's/\.git$//' | sed 's/git@github\.com:/https:\/\/github.com\//')
    echo -e "   ${BLUE}$REPO_WEB_URL${NC}"
    echo ""
    echo -e "${GREEN}📋 Próximos pasos:${NC}"
    echo "   1. Ve a tu repositorio en GitHub"
    echo "   2. Verifica que todos los archivos estén ahí"
    echo "   3. Ahora puedes trabajar normalmente:"
    echo "      • git add ."
    echo "      • git commit -m \"mensaje\""
    echo "      • git push"
    echo ""
else
    echo ""
    echo -e "${RED}❌ Error al hacer push${NC}"
    echo ""
    echo "Posibles causas:"
    echo "   • URL incorrecta"
    echo "   • Problemas de autenticación"
    echo "   • El repositorio no existe o no tienes permisos"
    echo ""
    echo "Solución:"
    echo "   1. Verifica que la URL sea correcta"
    echo "   2. Verifica que el repositorio existe en GitHub"
    echo "   3. Si es privado, asegúrate de estar autenticado"
    exit 1
fi

