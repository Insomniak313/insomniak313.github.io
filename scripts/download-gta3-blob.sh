#!/usr/bin/env bash
# Script pour télécharger automatiquement gta3.img depuis le blob Vercel
set -euo pipefail

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GAMEFILES_DIR="${ROOT_DIR}/gamefiles"
DEST_FILE="${GAMEFILES_DIR}/models/gta3.img"
GTA3_BLOB_URL="https://3px5m57ackbno8gi.public.blob.vercel-storage.com/gta3.img"

echo -e "${BOLD}${BLUE}=== Téléchargement de gta3.img depuis Vercel Blob ===${NC}\n"

# Créer le dossier si nécessaire
mkdir -p "${GAMEFILES_DIR}/models"

# Vérifier si le fichier existe déjà
if [ -f "${DEST_FILE}" ]; then
    FILE_SIZE=$(du -h "${DEST_FILE}" | cut -f1)
    SIZE_MB=$(du -m "${DEST_FILE}" | cut -f1)
    
    echo -e "${GREEN}✓${NC} gta3.img est déjà présent (${FILE_SIZE})"
    
    # Vérifier la taille (devrait être entre 400 et 700 MB)
    if [ "$SIZE_MB" -lt 300 ]; then
        echo -e "${YELLOW}⚠${NC}  Le fichier semble trop petit (${SIZE_MB}MB). Re-téléchargement recommandé."
        read -p "Voulez-vous re-télécharger ? (o/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Oo]$ ]]; then
            echo -e "${BLUE}ℹ${NC}  Utilisation du fichier existant."
            exit 0
        fi
        rm -f "${DEST_FILE}"
    else
        echo -e "${GREEN}✓${NC} La taille du fichier est correcte (${SIZE_MB}MB)."
        exit 0
    fi
fi

echo -e "${BLUE}ℹ${NC}  Téléchargement depuis: ${CYAN}${GTA3_BLOB_URL}${NC}"
echo -e "${BLUE}ℹ${NC}  Destination: ${CYAN}${DEST_FILE}${NC}\n"

TEMP_FILE="${DEST_FILE}.tmp"

# Vérifier si curl ou wget est disponible
if command -v curl >/dev/null 2>&1; then
    echo -e "${BLUE}→${NC} Téléchargement avec curl...\n"
    if curl -L --progress-bar -o "${TEMP_FILE}" "${GTA3_BLOB_URL}"; then
        echo -e "\n${GREEN}✓${NC} Téléchargement réussi !"
    else
        echo -e "\n${RED}✗${NC} Erreur lors du téléchargement avec curl"
        rm -f "${TEMP_FILE}"
        exit 1
    fi
elif command -v wget >/dev/null 2>&1; then
    echo -e "${BLUE}→${NC} Téléchargement avec wget...\n"
    if wget --show-progress -O "${TEMP_FILE}" "${GTA3_BLOB_URL}"; then
        echo -e "\n${GREEN}✓${NC} Téléchargement réussi !"
    else
        echo -e "\n${RED}✗${NC} Erreur lors du téléchargement avec wget"
        rm -f "${TEMP_FILE}"
        exit 1
    fi
else
    echo -e "${RED}✗${NC} Erreur: ni curl ni wget n'est disponible sur ce système"
    exit 1
fi

# Vérifier la taille du fichier téléchargé
if [ ! -f "${TEMP_FILE}" ]; then
    echo -e "${RED}✗${NC} Le fichier téléchargé n'existe pas"
    exit 1
fi

FILE_SIZE=$(du -h "${TEMP_FILE}" | cut -f1)
SIZE_MB=$(du -m "${TEMP_FILE}" | cut -f1)

echo -e "${BLUE}ℹ${NC}  Taille du fichier téléchargé: ${FILE_SIZE} (${SIZE_MB}MB)"

# Vérifier que la taille est raisonnable (au moins 100 MB pour éviter une erreur HTML)
if [ "$SIZE_MB" -lt 100 ]; then
    echo -e "${RED}✗${NC} Le fichier téléchargé semble corrompu (trop petit: ${SIZE_MB}MB)"
    echo -e "${YELLOW}⚠${NC}  Contenu du fichier:"
    head -n 20 "${TEMP_FILE}"
    rm -f "${TEMP_FILE}"
    exit 1
fi

# Déplacer le fichier temporaire vers la destination finale
mv "${TEMP_FILE}" "${DEST_FILE}"

echo -e "${GREEN}✓${NC} gta3.img installé avec succès dans ${CYAN}gamefiles/models/${NC}"
echo -e "\n${BOLD}${GREEN}Terminé !${NC} Vous pouvez maintenant lancer le build WASM:"
echo -e "  ${CYAN}./scripts/build-wasm.sh${NC}"
