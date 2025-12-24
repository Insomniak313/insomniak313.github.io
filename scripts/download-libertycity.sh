#!/usr/bin/env bash
# Script pour guider le téléchargement depuis Liberty City ou sites similaires
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
GAMEFILES_DIR="${PROJECT_ROOT}/gamefiles"

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
    echo -e "${CYAN}║    ${BOLD}Téléchargement des assets GTA Vice City${NC}${CYAN}         ║${NC}"
    echo -e "${CYAN}║                                                        ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
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

print_step() {
    echo -e "${CYAN}➜${NC} ${BOLD}$1${NC}"
}

print_header

cat <<EOF
${BOLD}Ce script vous guide pour télécharger gta3.img depuis Liberty City.${NC}

${YELLOW}Note:${NC} Liberty City nécessite un téléchargement manuel via navigateur.
Ce script vous guidera dans le processus étape par étape.

${BLUE}Lien recommandé:${NC}
  https://libertycity.net/files/gta-vice-city/57988-original-gta3.img.html

EOF

read -p "Appuyez sur Entrée pour continuer..."
echo ""

# Étape 1
print_step "Étape 1/5 : Ouvrir le site de téléchargement"
echo ""
print_info "Ouvrez ce lien dans votre navigateur:"
echo ""
echo -e "  ${BLUE}${BOLD}https://libertycity.net/files/gta-vice-city/57988-original-gta3.img.html${NC}"
echo ""
print_info "Ou utilisez cette commande (Linux/Mac):"
echo ""
echo -e "  ${CYAN}xdg-open 'https://libertycity.net/files/gta-vice-city/57988-original-gta3.img.html'${NC}"
echo ""

read -p "Appuyez sur Entrée une fois sur la page..."
echo ""

# Étape 2
print_step "Étape 2/5 : Télécharger le fichier"
echo ""
print_info "Sur la page Liberty City:"
echo "  1. Cliquez sur le bouton de téléchargement"
echo "  2. Attendez que le téléchargement se termine"
echo "  3. Le fichier devrait faire environ ${BOLD}400-700 MB${NC}"
echo ""
print_warning "Si le fichier est dans une archive (.zip, .rar, .7z), vous devrez l'extraire."
echo ""

read -p "Le téléchargement est-il terminé ? (oui/non): " download_done

if [ "$download_done" != "oui" ]; then
    print_warning "Revenez à ce script une fois le téléchargement terminé."
    exit 0
fi

echo ""

# Étape 3
print_step "Étape 3/5 : Localiser le fichier téléchargé"
echo ""
print_info "Le fichier est probablement dans votre dossier Téléchargements:"
echo ""
echo "  - Windows: C:\\Users\\VotreNom\\Downloads\\"
echo "  - Linux:   ~/Downloads/"
echo "  - Mac:     ~/Downloads/"
echo ""

# Essayer de détecter le fichier
POSSIBLE_LOCATIONS=(
    "$HOME/Downloads/gta3.img"
    "$HOME/Downloads/original-gta3.img"
    "$HOME/Téléchargements/gta3.img"
    "/c/Users/$USER/Downloads/gta3.img"
)

FOUND_FILE=""
for location in "${POSSIBLE_LOCATIONS[@]}"; do
    if [ -f "$location" ]; then
        FOUND_FILE="$location"
        print_success "Fichier trouvé automatiquement: $location"
        break
    fi
done

if [ -z "$FOUND_FILE" ]; then
    print_info "Entrez le chemin complet du fichier téléchargé:"
    read -p "Chemin: " FOUND_FILE
    
    if [ ! -f "$FOUND_FILE" ]; then
        print_error "Fichier non trouvé: $FOUND_FILE"
        exit 1
    fi
fi

echo ""

# Vérifier si c'est une archive
FILENAME=$(basename "$FOUND_FILE")
EXTENSION="${FILENAME##*.}"

if [[ "$EXTENSION" == "zip" ]] || [[ "$EXTENSION" == "rar" ]] || [[ "$EXTENSION" == "7z" ]]; then
    print_warning "Le fichier est une archive ($EXTENSION)"
    print_info "Extraction en cours..."
    echo ""
    
    EXTRACT_DIR=$(dirname "$FOUND_FILE")
    
    case "$EXTENSION" in
        zip)
            if command -v unzip >/dev/null 2>&1; then
                unzip -q "$FOUND_FILE" -d "$EXTRACT_DIR"
                print_success "Archive extraite"
            else
                print_error "unzip n'est pas installé"
                print_info "Extrayez manuellement l'archive et relancez ce script"
                exit 1
            fi
            ;;
        rar)
            if command -v unrar >/dev/null 2>&1; then
                unrar x "$FOUND_FILE" "$EXTRACT_DIR"
                print_success "Archive extraite"
            else
                print_error "unrar n'est pas installé"
                print_info "Extrayez manuellement l'archive et relancez ce script"
                exit 1
            fi
            ;;
        7z)
            if command -v 7z >/dev/null 2>&1; then
                7z x "$FOUND_FILE" -o"$EXTRACT_DIR"
                print_success "Archive extraite"
            else
                print_error "7z n'est pas installé"
                print_info "Extrayez manuellement l'archive et relancez ce script"
                exit 1
            fi
            ;;
    esac
    
    # Chercher gta3.img dans le dossier extrait
    FOUND_FILE=$(find "$EXTRACT_DIR" -name "gta3.img" -o -name "GTA3.img" | head -n1)
    
    if [ -z "$FOUND_FILE" ]; then
        print_error "Impossible de trouver gta3.img dans l'archive extraite"
        exit 1
    fi
    
    print_info "Fichier extrait: $FOUND_FILE"
    echo ""
fi

# Étape 4
print_step "Étape 4/5 : Vérifier le fichier"
echo ""

FILE_SIZE=$(stat -f%z "$FOUND_FILE" 2>/dev/null || stat -c%s "$FOUND_FILE" 2>/dev/null || echo "0")
FILE_SIZE_MB=$((FILE_SIZE / 1024 / 1024))

print_info "Taille du fichier: ${FILE_SIZE_MB} MB"

if [ $FILE_SIZE_MB -lt 100 ]; then
    print_error "Le fichier est trop petit (< 100 MB)"
    print_error "gta3.img devrait faire environ 400-700 MB"
    print_info "Vérifiez que vous avez téléchargé le bon fichier."
    exit 1
elif [ $FILE_SIZE_MB -lt 300 ]; then
    print_warning "Le fichier semble petit (< 300 MB)"
    print_warning "gta3.img fait généralement 400-700 MB"
    echo ""
    read -p "Voulez-vous continuer quand même ? (oui/non): " continue_anyway
    
    if [ "$continue_anyway" != "oui" ]; then
        exit 1
    fi
else
    print_success "Taille du fichier correcte"
fi

echo ""

# Étape 5
print_step "Étape 5/5 : Copier le fichier dans le projet"
echo ""

mkdir -p "${GAMEFILES_DIR}/models"

DEST_FILE="${GAMEFILES_DIR}/models/gta3.img"

print_info "Copie en cours..."
cp "$FOUND_FILE" "$DEST_FILE"

if [ -f "$DEST_FILE" ]; then
    print_success "Fichier copié avec succès !"
    echo ""
    print_info "Emplacement: $DEST_FILE"
else
    print_error "Échec de la copie"
    exit 1
fi

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Installation des assets terminée avec succès !${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo ""

# Vérifier les assets
print_info "Vérification des assets..."
echo ""

if [ -x "${SCRIPT_DIR}/verify-assets.sh" ]; then
    "${SCRIPT_DIR}/verify-assets.sh"
else
    print_success "gta3.img installé dans gamefiles/models/"
fi

echo ""
echo -e "${BOLD}Prochaines étapes:${NC}"
echo ""
echo -e "  ${CYAN}1.${NC} Builder le projet WASM:"
echo -e "     ${BLUE}source .emsdk/emsdk_env.sh${NC}"
echo -e "     ${BLUE}./scripts/build-wasm.sh${NC}"
echo ""
echo -e "  ${CYAN}2.${NC} Installer et lancer le serveur:"
echo -e "     ${BLUE}cd server && npm install && npm run build${NC}"
echo -e "     ${BLUE}npm start${NC}"
echo ""
echo -e "  ${CYAN}3.${NC} Ouvrir dans le navigateur:"
echo -e "     ${BLUE}http://localhost:8080/stats.html${NC}"
echo ""
