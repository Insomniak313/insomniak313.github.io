#!/usr/bin/env bash
# Script pour télécharger manuellement un fichier gta3.img depuis une URL fournie par l'utilisateur
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
    echo -e "${BLUE}  Téléchargement manuel d'assets${NC}"
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

print_header

cat <<EOF
${YELLOW}⚠ AVERTISSEMENT IMPORTANT${NC}

Ce script vous aide à télécharger un fichier ${YELLOW}gta3.img${NC} depuis une URL que vous fournissez.

${RED}LÉGALITÉ:${NC}
- Les fichiers d'assets de GTA Vice City sont protégés par le droit d'auteur
- Vous devez posséder une copie légale du jeu pour utiliser ces assets
- Le téléchargement d'assets depuis des sources non officielles peut être illégal

${GREEN}RECOMMANDATION:${NC}
Nous vous recommandons vivement d'utiliser le script d'import depuis votre 
installation légitime du jeu:
  ${BLUE}./scripts/import-assets.sh <chemin_installation_gta_vc>${NC}

${YELLOW}Voulez-vous continuer avec le téléchargement manuel ?${NC}

EOF

read -p "Tapez 'oui' pour continuer: " confirmation

if [ "$confirmation" != "oui" ]; then
    print_info "Téléchargement annulé."
    exit 0
fi

echo ""
print_info "Entrez l'URL du fichier gta3.img à télécharger:"
read -p "URL: " URL

if [ -z "$URL" ]; then
    print_error "URL vide. Abandon."
    exit 1
fi

# Créer le dossier si nécessaire
mkdir -p "${GAMEFILES_DIR}/models"

DEST_FILE="${GAMEFILES_DIR}/models/gta3.img"
TEMP_FILE="${GAMEFILES_DIR}/models/gta3.img.tmp"

print_info "Téléchargement en cours..."
echo ""

# Détecter l'outil de téléchargement disponible
if command -v curl >/dev/null 2>&1; then
    print_info "Utilisation de curl..."
    if curl -L -o "$TEMP_FILE" --progress-bar "$URL"; then
        DOWNLOAD_OK=1
    else
        DOWNLOAD_OK=0
    fi
elif command -v wget >/dev/null 2>&1; then
    print_info "Utilisation de wget..."
    if wget -O "$TEMP_FILE" "$URL"; then
        DOWNLOAD_OK=1
    else
        DOWNLOAD_OK=0
    fi
else
    print_error "Aucun outil de téléchargement trouvé (curl ou wget requis)"
    exit 1
fi

if [ $DOWNLOAD_OK -eq 0 ]; then
    print_error "Échec du téléchargement"
    rm -f "$TEMP_FILE"
    exit 1
fi

echo ""
print_success "Téléchargement terminé"

# Vérifier la taille du fichier
FILE_SIZE=$(stat -f%z "$TEMP_FILE" 2>/dev/null || stat -c%s "$TEMP_FILE" 2>/dev/null || echo "0")
FILE_SIZE_MB=$((FILE_SIZE / 1024 / 1024))

print_info "Taille du fichier: ${FILE_SIZE_MB} MB"

if [ $FILE_SIZE_MB -lt 100 ]; then
    print_warning "Le fichier semble trop petit (< 100 MB)"
    print_warning "gta3.img devrait faire environ 400-700 MB"
    echo ""
    read -p "Voulez-vous quand même continuer ? (oui/non): " continue_anyway
    
    if [ "$continue_anyway" != "oui" ]; then
        print_info "Suppression du fichier téléchargé..."
        rm -f "$TEMP_FILE"
        exit 1
    fi
fi

# Déplacer le fichier temporaire vers la destination finale
mv "$TEMP_FILE" "$DEST_FILE"

print_success "Fichier enregistré: $DEST_FILE"
echo ""

# Vérifier les assets
print_info "Vérification des assets..."
echo ""

if [ -x "${SCRIPT_DIR}/verify-assets.sh" ]; then
    "${SCRIPT_DIR}/verify-assets.sh"
else
    print_warning "Script de vérification non trouvé"
    print_info "Vérifiez manuellement que le fichier est correct"
fi

echo ""
print_success "Téléchargement et installation terminés !"
echo ""
print_info "Étapes suivantes:"
echo "  1. Builder WASM: ./scripts/build-wasm.sh"
echo "  2. Lancer le serveur: cd server && npm install && npm start"
echo ""
