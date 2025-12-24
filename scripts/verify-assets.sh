#!/usr/bin/env bash
# Script pour vérifier l'intégrité et la présence des assets GTA Vice City
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
GAMEFILES_DIR="${PROJECT_ROOT}/gamefiles"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  Vérification des assets GTA Vice City${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

check_file_exists() {
    local file="$1"
    local status="$2"  # REQUIRED, RECOMMENDED, OPTIONAL
    local basename="$(basename "$file")"
    
    if [ -f "$file" ]; then
        local size=$(du -h "$file" | cut -f1)
        print_success "$basename ($size) - Présent"
        return 0
    else
        case "$status" in
            REQUIRED)
                print_error "$basename - MANQUANT (OBLIGATOIRE)"
                return 1
                ;;
            RECOMMENDED)
                print_warning "$basename - Manquant (recommandé)"
                return 2
                ;;
            OPTIONAL)
                print_info "$basename - Absent (optionnel)"
                return 3
                ;;
        esac
    fi
}

check_file_size() {
    local file="$1"
    local min_size_mb="$2"
    
    if [ ! -f "$file" ]; then
        return 1
    fi
    
    # Obtenir la taille en MB
    local size_bytes=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
    local size_mb=$((size_bytes / 1024 / 1024))
    
    if [ $size_mb -lt $min_size_mb ]; then
        print_warning "$(basename "$file") semble trop petit (${size_mb}MB, attendu >${min_size_mb}MB)"
        return 1
    fi
    
    return 0
}

print_header

ERRORS=0
WARNINGS=0
SUCCESS=0

echo -e "${YELLOW}Fichiers OBLIGATOIRES:${NC}"
echo ""

# gta3.img
if check_file_exists "${GAMEFILES_DIR}/models/gta3.img" "REQUIRED"; then
    SUCCESS=$((SUCCESS + 1))
    check_file_size "${GAMEFILES_DIR}/models/gta3.img" 300 || WARNINGS=$((WARNINGS + 1))
else
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo -e "${YELLOW}Fichiers RECOMMANDÉS:${NC}"
echo ""

# gta3.dir
if check_file_exists "${GAMEFILES_DIR}/models/gta3.dir" "RECOMMENDED"; then
    SUCCESS=$((SUCCESS + 1))
else
    ret=$?
    [ $ret -eq 2 ] && WARNINGS=$((WARNINGS + 1))
fi

# default.dat
if check_file_exists "${GAMEFILES_DIR}/data/default.dat" "RECOMMENDED"; then
    SUCCESS=$((SUCCESS + 1))
else
    ret=$?
    [ $ret -eq 2 ] && WARNINGS=$((WARNINGS + 1))
fi

# default.ide
if check_file_exists "${GAMEFILES_DIR}/data/default.ide" "RECOMMENDED"; then
    SUCCESS=$((SUCCESS + 1))
else
    ret=$?
    [ $ret -eq 2 ] && WARNINGS=$((WARNINGS + 1))
fi

echo ""
echo -e "${YELLOW}Fichiers OPTIONNELS:${NC}"
echo ""

# txd.img
check_file_exists "${GAMEFILES_DIR}/models/txd.img" "OPTIONAL"

# txd.dir
check_file_exists "${GAMEFILES_DIR}/models/txd.dir" "OPTIONAL"

echo ""
echo -e "${YELLOW}Fichiers reVC (déjà fournis):${NC}"
echo ""

# Vérifier les fichiers fournis par le projet
REVC_FILES=(
    "models/fonts_r.txd"
    "models/generic.txd"
    "models/particle.txd"
    "TEXT/french.gxt"
    "TEXT/american.gxt"
    "neo/neo.txd"
)

REVC_OK=0
for file in "${REVC_FILES[@]}"; do
    if [ -f "${GAMEFILES_DIR}/${file}" ]; then
        REVC_OK=$((REVC_OK + 1))
    fi
done

if [ $REVC_OK -eq ${#REVC_FILES[@]} ]; then
    print_success "Tous les fichiers reVC sont présents (${REVC_OK}/${#REVC_FILES[@]})"
else
    print_warning "Certains fichiers reVC sont manquants (${REVC_OK}/${#REVC_FILES[@]})"
fi

echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}Résumé:${NC}"
echo ""

if [ $ERRORS -gt 0 ]; then
    echo -e "  ${RED}✗ Erreurs: $ERRORS${NC}"
fi

if [ $WARNINGS -gt 0 ]; then
    echo -e "  ${YELLOW}⚠ Avertissements: $WARNINGS${NC}"
fi

echo -e "  ${GREEN}✓ Succès: $SUCCESS${NC}"
echo ""

if [ $ERRORS -gt 0 ]; then
    print_error "Des fichiers OBLIGATOIRES sont manquants !"
    echo ""
    print_info "Actions recommandées:"
    echo "  1. Utilisez le script d'import: ./scripts/import-assets.sh <chemin_gta_vc>"
    echo "  2. Ou copiez manuellement gta3.img dans gamefiles/models/"
    echo "  3. Consultez: gamefiles/models/README.md"
    echo ""
    echo -e "${BLUE}============================================${NC}"
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    print_warning "Des fichiers recommandés sont manquants."
    print_info "Le jeu devrait fonctionner, mais certaines fonctionnalités pourraient être limitées."
    echo ""
    echo -e "${BLUE}============================================${NC}"
    exit 0
else
    print_success "Tous les assets nécessaires sont présents !"
    echo ""
    print_info "Vous pouvez maintenant:"
    echo "  1. Builder WASM: ./scripts/build-wasm.sh"
    echo "  2. Lancer le serveur: cd server && npm install && npm start"
    echo ""
    echo -e "${BLUE}============================================${NC}"
    exit 0
fi
