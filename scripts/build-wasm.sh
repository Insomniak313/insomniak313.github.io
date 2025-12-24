#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${ROOT_DIR}/build-wasm"
OUT_DIR="${ROOT_DIR}/server/public/game"

if ! command -v emcmake >/dev/null 2>&1; then
  cat <<EOF
Emscripten (emcmake) n'est pas disponible dans ce shell.

Installe/active d'abord emsdk :

  ./scripts/setup-emsdk.sh
  source "${ROOT_DIR}/.emsdk/emsdk_env.sh"

Puis relance :
  ./scripts/build-wasm.sh
EOF
  exit 1
fi

# Vérifier si gta3.img existe, sinon le télécharger automatiquement
GTA3_IMG="${ROOT_DIR}/gamefiles/models/gta3.img"
if [ ! -f "${GTA3_IMG}" ]; then
  echo "⚠️  gta3.img n'est pas présent dans gamefiles/models/"
  echo "📥 Téléchargement automatique depuis Vercel Blob..."
  echo ""
  
  if [ -x "${ROOT_DIR}/scripts/download-gta3-blob.sh" ]; then
    "${ROOT_DIR}/scripts/download-gta3-blob.sh"
  else
    echo "❌ Erreur: le script download-gta3-blob.sh n'est pas exécutable"
    exit 1
  fi
  
  # Vérifier à nouveau si le téléchargement a réussi
  if [ ! -f "${GTA3_IMG}" ]; then
    echo "❌ Erreur: gta3.img n'a pas pu être téléchargé"
    exit 1
  fi
  echo ""
fi

echo "✓ gta3.img est présent ($(du -h "${GTA3_IMG}" | cut -f1))"
echo ""

cmake -E make_directory "${OUT_DIR}"

emcmake cmake -S "${ROOT_DIR}" -B "${BUILD_DIR}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DLIBRW_PLATFORM=GL3 \
  -DLIBRW_GL3_GFXLIB=GLFW \
  -DREVC_AUDIO=NULL \
  -DREVC_WITH_OPUS=OFF \
  -DREVC_WITH_LIBSNDFILE=OFF

cmake --build "${BUILD_DIR}" -j

echo "Build WASM généré dans ${OUT_DIR} (index.html / index.js / index.wasm / index.data)."

