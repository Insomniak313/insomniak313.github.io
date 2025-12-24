#!/usr/bin/env bash
# Script pour installer automatiquement gta3.img depuis le dossier Downloads
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
GAMEFILES_DIR="${PROJECT_ROOT}/gamefiles"
DEST_FILE="${GAMEFILES_DIR}/models/gta3.img"

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  ${BOLD}Installation automatique des assets GTA VC${NC}${CYAN}        ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Si le fichier existe déjà
if [ -f "$DEST_FILE" ]; then
    SIZE=$(du -h "$DEST_FILE" | cut -f1)
    echo -e "${GREEN}✓${NC} gta3.img est déjà installé ($SIZE)"
    echo ""
    echo -e "${YELLOW}Voulez-vous le remplacer ?${NC}"
    echo "  1. Non, garder le fichier actuel"
    echo "  2. Oui, chercher et installer un nouveau fichier"
    echo ""
    read -p "Choix (1 ou 2): " choice
    
    if [ "$choice" != "2" ]; then
        echo ""
        echo -e "${BLUE}ℹ${NC} Fichier actuel conservé. Lancement de la vérification..."
        "${SCRIPT_DIR}/verify-assets.sh"
        exit 0
    fi
    echo ""
fi

# Chercher le fichier dans différents emplacements
echo -e "${BLUE}ℹ${NC} Recherche de gta3.img dans vos téléchargements..."
echo ""

SEARCH_LOCATIONS=(
    "$HOME/Downloads"
    "$HOME/Téléchargements"
    "$HOME/Desktop"
    "$HOME/Bureau"
    "/tmp"
    "/workspace"
    "/c/Users/$USER/Downloads"
    "/c/Users/$USER/Desktop"
)

FOUND_FILES=()

for location in "${SEARCH_LOCATIONS[@]}"; do
    if [ -d "$location" ]; then
        while IFS= read -r -d '' file; do
            FOUND_FILES+=("$file")
        done < <(find "$location" -maxdepth 2 -type f \( -name "gta3.img" -o -name "GTA3.img" -o -name "*gta3*.img" \) -print0 2>/dev/null || true)
    fi
done

# Chercher aussi les archives
for location in "${SEARCH_LOCATIONS[@]}"; do
    if [ -d "$location" ]; then
        while IFS= read -r -d '' file; do
            if [[ "$(basename "$file")" == *gta3* ]]; then
                FOUND_FILES+=("$file")
            fi
        done < <(find "$location" -maxdepth 2 -type f \( -name "*.zip" -o -name "*.rar" -o -name "*.7z" \) -print0 2>/dev/null || true)
    fi
done

if [ ${#FOUND_FILES[@]} -eq 0 ]; then
    echo -e "${YELLOW}⚠${NC} Aucun fichier gta3.img trouvé automatiquement"
    echo ""
    echo -e "${BOLD}Instructions :${NC}"
    echo ""
    echo "  ${CYAN}1.${NC} Téléchargez gta3.img depuis :"
    echo "     ${BLUE}https://libertycity.net/files/gta-vice-city/57988-original-gta3.img.html${NC}"
    echo ""
    echo "  ${CYAN}2.${NC} Une fois téléchargé, relancez ce script :"
    echo "     ${BLUE}./scripts/auto-install-assets.sh${NC}"
    echo ""
    echo "  ${CYAN}Ou${NC} spécifiez le chemin manuellement :"
    echo "     ${BLUE}cp /chemin/vers/gta3.img ./gamefiles/models/${NC}"
    echo ""
    exit 1
fi

echo -e "${GREEN}✓${NC} ${#FOUND_FILES[@]} fichier(s) trouvé(s) :"
echo ""

# Afficher les fichiers trouvés
for i in "${!FOUND_FILES[@]}"; do
    file="${FOUND_FILES[$i]}"
    size=$(du -h "$file" | cut -f1)
    echo "  $((i+1)). $(basename "$file") ($size)"
    echo "     ${CYAN}→${NC} $file"
done

echo ""

# Sélection automatique ou manuelle
if [ ${#FOUND_FILES[@]} -eq 1 ]; then
    SELECTED_FILE="${FOUND_FILES[0]}"
    echo -e "${BLUE}ℹ${NC} Utilisation automatique du seul fichier trouvé"
else
    read -p "Choisissez un fichier (1-${#FOUND_FILES[@]}): " choice
    idx=$((choice - 1))
    
    if [ $idx -lt 0 ] || [ $idx -ge ${#FOUND_FILES[@]} ]; then
        echo -e "${RED}✗${NC} Choix invalide"
        exit 1
    fi
    
    SELECTED_FILE="${FOUND_FILES[$idx]}"
fi

echo ""
echo -e "${BLUE}ℹ${NC} Fichier sélectionné: $(basename "$SELECTED_FILE")"
echo ""

# Vérifier si c'est une archive
EXTENSION="${SELECTED_FILE##*.}"

if [[ "$EXTENSION" == "zip" ]] || [[ "$EXTENSION" == "rar" ]] || [[ "$EXTENSION" == "7z" ]]; then
    echo -e "${YELLOW}⚠${NC} Le fichier est une archive ($EXTENSION)"
    echo -e "${BLUE}ℹ${NC} Extraction en cours..."
    
    EXTRACT_DIR="/tmp/gta3_extract_$$"
    mkdir -p "$EXTRACT_DIR"
    
    case "$EXTENSION" in
        zip)
            if command -v unzip >/dev/null 2>&1; then
                unzip -q "$SELECTED_FILE" -d "$EXTRACT_DIR"
                echo -e "${GREEN}✓${NC} Archive extraite"
            else
                echo -e "${RED}✗${NC} unzip non installé"
                echo "  Installez avec: sudo apt-get install unzip"
                rm -rf "$EXTRACT_DIR"
                exit 1
            fi
            ;;
        rar)
            if command -v unrar >/dev/null 2>&1; then
                unrar x "$SELECTED_FILE" "$EXTRACT_DIR" >/dev/null
                echo -e "${GREEN}✓${NC} Archive extraite"
            else
                echo -e "${RED}✗${NC} unrar non installé"
                echo "  Installez avec: sudo apt-get install unrar"
                rm -rf "$EXTRACT_DIR"
                exit 1
            fi
            ;;
        7z)
            if command -v 7z >/dev/null 2>&1; then
                7z x "$SELECTED_FILE" -o"$EXTRACT_DIR" >/dev/null
                echo -e "${GREEN}✓${NC} Archive extraite"
            else
                echo -e "${RED}✗${NC} 7z non installé"
                echo "  Installez avec: sudo apt-get install p7zip-full"
                rm -rf "$EXTRACT_DIR"
                exit 1
            fi
            ;;
    esac
    
    # Chercher gta3.img dans le dossier extrait
    SELECTED_FILE=$(find "$EXTRACT_DIR" -name "gta3.img" -o -name "GTA3.img" | head -n1)
    
    if [ -z "$SELECTED_FILE" ]; then
        echo -e "${RED}✗${NC} gta3.img non trouvé dans l'archive"
        rm -rf "$EXTRACT_DIR"
        exit 1
    fi
    
    echo -e "${GREEN}✓${NC} gta3.img trouvé dans l'archive"
fi

# Vérifier la taille
FILE_SIZE=$(stat -f%z "$SELECTED_FILE" 2>/dev/null || stat -c%s "$SELECTED_FILE" 2>/dev/null || echo "0")
FILE_SIZE_MB=$((FILE_SIZE / 1024 / 1024))

echo ""
echo -e "${BLUE}ℹ${NC} Vérification du fichier..."
echo -e "${BLUE}ℹ${NC} Taille: ${FILE_SIZE_MB} MB"

if [ $FILE_SIZE_MB -lt 100 ]; then
    echo -e "${RED}✗${NC} Fichier trop petit (< 100 MB)"
    echo -e "${RED}✗${NC} gta3.img doit faire environ 400-700 MB"
    [ -d "/tmp/gta3_extract_$$" ] && rm -rf "/tmp/gta3_extract_$$"
    exit 1
elif [ $FILE_SIZE_MB -lt 300 ]; then
    echo -e "${YELLOW}⚠${NC} Fichier petit (< 300 MB) - attendu: 400-700 MB"
else
    echo -e "${GREEN}✓${NC} Taille correcte"
fi

# Copier le fichier
echo ""
echo -e "${BLUE}ℹ${NC} Installation en cours..."

mkdir -p "${GAMEFILES_DIR}/models"
cp "$SELECTED_FILE" "$DEST_FILE"

# Nettoyer le dossier temporaire si nécessaire
[ -d "/tmp/gta3_extract_$$" ] && rm -rf "/tmp/gta3_extract_$$"

if [ -f "$DEST_FILE" ]; then
    FINAL_SIZE=$(du -h "$DEST_FILE" | cut -f1)
    echo -e "${GREEN}✓${NC} Fichier installé avec succès !"
    echo ""
    echo -e "${BLUE}ℹ${NC} Emplacement: $DEST_FILE"
    echo -e "${BLUE}ℹ${NC} Taille: $FINAL_SIZE"
else
    echo -e "${RED}✗${NC} Échec de l'installation"
    exit 1
fi

# Vérifier les assets
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Installation terminée avec succès !${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo ""

if [ -x "${SCRIPT_DIR}/verify-assets.sh" ]; then
    "${SCRIPT_DIR}/verify-assets.sh"
fi

echo ""
echo -e "${BOLD}Prochaines étapes:${NC}"
echo ""
echo -e "  ${CYAN}1.${NC} Builder le projet WASM:"
echo -e "     ${BLUE}source .emsdk/emsdk_env.sh${NC}"
echo -e "     ${BLUE}./scripts/build-wasm.sh${NC}"
echo ""
echo -e "  ${CYAN}2.${NC} Lancer le serveur:"
echo -e "     ${BLUE}cd server && npm install && npm run build && npm start${NC}"
echo ""
echo -e "  ${CYAN}3.${NC} Ouvrir dans le navigateur:"
echo -e "     ${BLUE}http://localhost:8080/stats.html${NC}"
echo ""
