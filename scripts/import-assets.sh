#!/usr/bin/env bash
# Script pour importer automatiquement les assets GTA Vice City
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
GAMEFILES_DIR="${PROJECT_ROOT}/gamefiles"

# Couleurs pour l'output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  Import des assets GTA Vice City${NC}"
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

check_file() {
    local file="$1"
    local dest="$2"
    
    if [ -f "$file" ]; then
        local size=$(du -h "$file" | cut -f1)
        print_info "Trouvé: $(basename "$file") ($size)"
        
        # Copier le fichier
        cp "$file" "$dest"
        print_success "Copié vers: $dest"
        return 0
    else
        print_warning "Non trouvé: $(basename "$file")"
        return 1
    fi
}

print_header

# Vérifier les arguments
if [ $# -eq 0 ]; then
    cat <<EOF
${YELLOW}Usage:${NC}
  $0 <chemin_installation_gta_vc>

${YELLOW}Exemples:${NC}
  # Windows (Git Bash/WSL)
  $0 "/c/Program Files (x86)/Steam/steamapps/common/Grand Theft Auto Vice City"
  
  # Linux
  $0 ~/.steam/steam/steamapps/common/Grand\ Theft\ Auto\ Vice\ City
  
  # Mac
  $0 ~/Library/Application\ Support/Steam/steamapps/common/Grand\ Theft\ Auto\ Vice\ City

${YELLOW}Chemins d'installation courants:${NC}
  Windows (Steam)    : C:\Program Files (x86)\Steam\steamapps\common\Grand Theft Auto Vice City
  Windows (Rockstar) : C:\Program Files\Rockstar Games\Grand Theft Auto Vice City
  Linux (Steam)      : ~/.steam/steam/steamapps/common/Grand Theft Auto Vice City

EOF
    exit 1
fi

GTA_DIR="$1"

# Vérifier que le dossier existe
if [ ! -d "$GTA_DIR" ]; then
    print_error "Le dossier '$GTA_DIR' n'existe pas"
    exit 1
fi

print_info "Source: $GTA_DIR"
print_info "Destination: $GAMEFILES_DIR"
echo ""

# Créer les dossiers si nécessaire
mkdir -p "${GAMEFILES_DIR}/models"
mkdir -p "${GAMEFILES_DIR}/data"
mkdir -p "${GAMEFILES_DIR}/audio"

# Compteurs
COPIED=0
MISSING=0

echo -e "${YELLOW}Fichiers OBLIGATOIRES:${NC}"
echo ""

# gta3.img (OBLIGATOIRE)
if check_file "${GTA_DIR}/models/gta3.img" "${GAMEFILES_DIR}/models/gta3.img"; then
    COPIED=$((COPIED + 1))
else
    print_error "Le fichier gta3.img est OBLIGATOIRE pour que le jeu fonctionne !"
    MISSING=$((MISSING + 1))
fi

echo ""
echo -e "${YELLOW}Fichiers RECOMMANDÉS:${NC}"
echo ""

# gta3.dir (recommandé)
if check_file "${GTA_DIR}/models/gta3.dir" "${GAMEFILES_DIR}/models/gta3.dir"; then
    COPIED=$((COPIED + 1))
else
    MISSING=$((MISSING + 1))
fi

# default.dat (utile)
if check_file "${GTA_DIR}/data/default.dat" "${GAMEFILES_DIR}/data/default.dat"; then
    COPIED=$((COPIED + 1))
else
    MISSING=$((MISSING + 1))
fi

# default.ide (utile)
if check_file "${GTA_DIR}/data/default.ide" "${GAMEFILES_DIR}/data/default.ide"; then
    COPIED=$((COPIED + 1))
else
    MISSING=$((MISSING + 1))
fi

echo ""
echo -e "${YELLOW}Fichiers OPTIONNELS:${NC}"
echo ""

# txd.img (optionnel)
if check_file "${GTA_DIR}/models/txd.img" "${GAMEFILES_DIR}/models/txd.img"; then
    COPIED=$((COPIED + 1))
fi

# txd.dir (optionnel)
if check_file "${GTA_DIR}/models/txd.dir" "${GAMEFILES_DIR}/models/txd.dir"; then
    COPIED=$((COPIED + 1))
fi

echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${GREEN}Résumé:${NC}"
echo -e "  Fichiers copiés: ${GREEN}${COPIED}${NC}"
if [ $MISSING -gt 0 ]; then
    echo -e "  Fichiers manquants: ${YELLOW}${MISSING}${NC}"
fi
echo ""

if [ ! -f "${GAMEFILES_DIR}/models/gta3.img" ]; then
    print_error "ERREUR: gta3.img n'a pas été copié !"
    print_error "Le jeu ne pourra pas fonctionner sans ce fichier."
    echo ""
    print_info "Vérifiez que le chemin d'installation est correct et que le fichier existe."
    exit 1
else
    print_success "Import réussi ! Vous pouvez maintenant builder le projet WASM."
    echo ""
    print_info "Étapes suivantes:"
    echo "  1. Vérifier les assets: ./scripts/verify-assets.sh"
    echo "  2. Builder WASM: ./scripts/build-wasm.sh"
    echo "  3. Lancer le serveur: cd server && npm install && npm start"
fi

echo -e "${BLUE}============================================${NC}"
