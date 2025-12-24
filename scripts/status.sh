#!/usr/bin/env bash
# Script pour afficher l'état du projet et guider l'utilisateur
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                        ║${NC}"
    echo -e "${CYAN}║          ${BOLD}reVC - Status du projet WASM${NC}${CYAN}              ║${NC}"
    echo -e "${CYAN}║                                                        ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

check_status() {
    local status="$1"
    if [ "$status" = "OK" ]; then
        echo -e "${GREEN}✓${NC}"
    elif [ "$status" = "WARNING" ]; then
        echo -e "${YELLOW}⚠${NC}"
    else
        echo -e "${RED}✗${NC}"
    fi
}

print_step() {
    local num="$1"
    local title="$2"
    local status="$3"
    local detail="$4"
    
    echo -e "${BOLD}${num}.${NC} ${title}"
    echo -e "   Status: $(check_status "$status") ${detail}"
    echo ""
}

print_action() {
    local action="$1"
    echo -e "   ${CYAN}→${NC} ${action}"
}

print_header

# 1. Vérifier Emscripten
echo -e "${BOLD}Vérification de l'environnement...${NC}"
echo ""

EMSDK_STATUS="ERROR"
EMSDK_DETAIL="Non installé"
if [ -d "${PROJECT_ROOT}/.emsdk" ]; then
    if command -v emcc >/dev/null 2>&1; then
        EMCC_VERSION=$(emcc --version | head -n1 | grep -oP '\d+\.\d+\.\d+' || echo "?")
        EMSDK_STATUS="OK"
        EMSDK_DETAIL="Version ${EMCC_VERSION}"
    else
        EMSDK_STATUS="WARNING"
        EMSDK_DETAIL="Installé mais pas activé"
    fi
fi

print_step "1" "Emscripten (SDK WASM)" "$EMSDK_STATUS" "$EMSDK_DETAIL"

if [ "$EMSDK_STATUS" = "ERROR" ]; then
    print_action "Installer: ./scripts/setup-emsdk.sh"
elif [ "$EMSDK_STATUS" = "WARNING" ]; then
    print_action "Activer: source .emsdk/emsdk_env.sh"
fi

# 2. Vérifier les sous-modules Git
SUBMODULE_STATUS="ERROR"
SUBMODULE_DETAIL="Non initialisés"
if [ -f "${PROJECT_ROOT}/vendor/librw/CMakeLists.txt" ]; then
    SUBMODULE_STATUS="OK"
    SUBMODULE_DETAIL="Initialisés"
fi

print_step "2" "Sous-modules Git" "$SUBMODULE_STATUS" "$SUBMODULE_DETAIL"

if [ "$SUBMODULE_STATUS" = "ERROR" ]; then
    print_action "Initialiser: git submodule update --init --recursive"
fi

# 3. Vérifier les assets
ASSETS_STATUS="ERROR"
ASSETS_DETAIL="gta3.img manquant"
if [ -f "${PROJECT_ROOT}/gamefiles/models/gta3.img" ]; then
    FILE_SIZE=$(du -h "${PROJECT_ROOT}/gamefiles/models/gta3.img" | cut -f1)
    SIZE_MB=$(du -m "${PROJECT_ROOT}/gamefiles/models/gta3.img" | cut -f1)
    
    if [ "$SIZE_MB" -lt 300 ]; then
        ASSETS_STATUS="WARNING"
        ASSETS_DETAIL="Présent mais trop petit (${FILE_SIZE})"
    else
        ASSETS_STATUS="OK"
        ASSETS_DETAIL="Présent (${FILE_SIZE})"
    fi
fi

print_step "3" "Assets GTA Vice City" "$ASSETS_STATUS" "$ASSETS_DETAIL"

if [ "$ASSETS_STATUS" = "ERROR" ]; then
    print_action "Import auto: ./scripts/import-assets.sh '/chemin/vers/GTA VC'"
    print_action "Téléchargement: ./scripts/download-assets.sh"
    print_action "Copie manuelle: cp '/chemin/gta3.img' ./gamefiles/models/"
    print_action "Guide détaillé: gamefiles/models/README.md"
elif [ "$ASSETS_STATUS" = "WARNING" ]; then
    print_action "Vérifier: ./scripts/verify-assets.sh"
fi

# 4. Vérifier le build WASM
WASM_STATUS="ERROR"
WASM_DETAIL="Non généré"
if [ -f "${PROJECT_ROOT}/server/public/game/index.wasm" ] && \
   [ -f "${PROJECT_ROOT}/server/public/game/index.data" ]; then
    WASM_SIZE=$(du -h "${PROJECT_ROOT}/server/public/game/index.wasm" | cut -f1)
    DATA_SIZE=$(du -h "${PROJECT_ROOT}/server/public/game/index.data" | cut -f1)
    WASM_STATUS="OK"
    WASM_DETAIL="Généré (WASM: ${WASM_SIZE}, DATA: ${DATA_SIZE})"
    
    # Vérifier si le build est récent
    WASM_TIME=$(stat -f%m "${PROJECT_ROOT}/server/public/game/index.wasm" 2>/dev/null || stat -c%Y "${PROJECT_ROOT}/server/public/game/index.wasm" 2>/dev/null || echo "0")
    CURRENT_TIME=$(date +%s)
    AGE_HOURS=$(( (CURRENT_TIME - WASM_TIME) / 3600 ))
    
    if [ "$AGE_HOURS" -gt 24 ]; then
        WASM_STATUS="WARNING"
        WASM_DETAIL="Généré mais ancien (${AGE_HOURS}h)"
    fi
elif [ -d "${PROJECT_ROOT}/build-wasm" ]; then
    WASM_STATUS="WARNING"
    WASM_DETAIL="Build en cours ou échoué"
fi

print_step "4" "Build WASM" "$WASM_STATUS" "$WASM_DETAIL"

if [ "$WASM_STATUS" = "ERROR" ]; then
    print_action "Builder: ./scripts/build-wasm.sh"
    print_action "(Prérequis: Emscripten activé + assets présents)"
elif [ "$WASM_STATUS" = "WARNING" ] && [ "$AGE_HOURS" -gt 24 ]; then
    print_action "Rebuilder: ./scripts/build-wasm.sh"
fi

# 5. Vérifier Node.js et les dépendances
NODE_STATUS="ERROR"
NODE_DETAIL="Node.js non installé"
if command -v node >/dev/null 2>&1; then
    NODE_VERSION=$(node --version)
    NODE_MAJOR=$(echo "$NODE_VERSION" | cut -d. -f1 | tr -d 'v')
    
    if [ "$NODE_MAJOR" -ge 16 ]; then
        NODE_STATUS="OK"
        NODE_DETAIL="Version ${NODE_VERSION}"
    else
        NODE_STATUS="WARNING"
        NODE_DETAIL="Version ${NODE_VERSION} (< v16)"
    fi
fi

print_step "5" "Node.js" "$NODE_STATUS" "$NODE_DETAIL"

if [ "$NODE_STATUS" = "ERROR" ]; then
    print_action "Installer Node.js v16+: https://nodejs.org/"
elif [ "$NODE_STATUS" = "WARNING" ]; then
    print_action "Mettre à jour Node.js vers v16+"
fi

# 6. Vérifier les dépendances npm
NPM_STATUS="ERROR"
NPM_DETAIL="Non installées"
if [ -d "${PROJECT_ROOT}/server/node_modules" ]; then
    NPM_STATUS="OK"
    NPM_DETAIL="Installées"
fi

print_step "6" "Dépendances npm (serveur)" "$NPM_STATUS" "$NPM_DETAIL"

if [ "$NPM_STATUS" = "ERROR" ]; then
    print_action "Installer: cd server && npm install"
fi

# 7. Vérifier le build TypeScript du serveur
SERVER_BUILD_STATUS="ERROR"
SERVER_BUILD_DETAIL="Non compilé"
if [ -f "${PROJECT_ROOT}/server/dist/index.js" ]; then
    SERVER_BUILD_STATUS="OK"
    SERVER_BUILD_DETAIL="Compilé"
fi

print_step "7" "Build serveur (TypeScript)" "$SERVER_BUILD_STATUS" "$SERVER_BUILD_DETAIL"

if [ "$SERVER_BUILD_STATUS" = "ERROR" ]; then
    print_action "Compiler: cd server && npm run build"
fi

# Résumé et prochaines étapes
echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo ""

# Compter les statuts
OK_COUNT=0
WARNING_COUNT=0
ERROR_COUNT=0

for status in "$EMSDK_STATUS" "$SUBMODULE_STATUS" "$ASSETS_STATUS" "$WASM_STATUS" "$NODE_STATUS" "$NPM_STATUS" "$SERVER_BUILD_STATUS"; do
    case "$status" in
        OK) OK_COUNT=$((OK_COUNT + 1)) ;;
        WARNING) WARNING_COUNT=$((WARNING_COUNT + 1)) ;;
        ERROR) ERROR_COUNT=$((ERROR_COUNT + 1)) ;;
    esac
done

echo -e "${BOLD}Résumé:${NC}"
echo -e "  ${GREEN}✓${NC} OK: ${GREEN}${OK_COUNT}${NC}/7"
if [ "$WARNING_COUNT" -gt 0 ]; then
    echo -e "  ${YELLOW}⚠${NC} Avertissements: ${YELLOW}${WARNING_COUNT}${NC}/7"
fi
if [ "$ERROR_COUNT" -gt 0 ]; then
    echo -e "  ${RED}✗${NC} Erreurs: ${RED}${ERROR_COUNT}${NC}/7"
fi

echo ""
echo -e "${BOLD}Prochaines étapes:${NC}"
echo ""

if [ "$ERROR_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}Des étapes sont manquantes. Suivez les actions ci-dessus.${NC}"
    echo ""
    echo -e "${BOLD}Guide de démarrage rapide:${NC}"
    print_action "Lire: cat QUICKSTART_WASM_FR.md"
    print_action "Ou: https://github.com/mrxenginner/reVC/blob/miami/QUICKSTART_WASM_FR.md"
elif [ "$WASM_STATUS" = "OK" ] && [ "$SERVER_BUILD_STATUS" = "OK" ]; then
    echo -e "${GREEN}✓ Tout est prêt ! Vous pouvez lancer le serveur.${NC}"
    echo ""
    print_action "cd server && npm start"
    print_action "Puis ouvrir: http://localhost:8080/stats.html"
else
    echo -e "${YELLOW}Presque prêt ! Finalisez le build WASM et le serveur.${NC}"
    if [ "$WASM_STATUS" != "OK" ]; then
        print_action "./scripts/build-wasm.sh"
    fi
    if [ "$NPM_STATUS" != "OK" ]; then
        print_action "cd server && npm install"
    fi
    if [ "$SERVER_BUILD_STATUS" != "OK" ]; then
        print_action "cd server && npm run build"
    fi
    print_action "cd server && npm start"
fi

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BOLD}Ressources:${NC}"
echo -e "  📖 Guide rapide: ${BLUE}QUICKSTART_WASM_FR.md${NC}"
echo -e "  📖 Import assets: ${BLUE}gamefiles/models/README.md${NC}"
echo -e "  📖 Téléchargement: ${BLUE}gamefiles/models/DOWNLOAD_GUIDE_FR.md${NC}"
echo -e "  💬 Discord: ${BLUE}https://discord.gg/RFNbjsUMGg${NC}"
echo ""
