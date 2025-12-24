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

echo "ℹ️  gta3.img sera téléchargé automatiquement depuis Vercel Blob au runtime"
echo "   Pas besoin de l'avoir localement pour le build !"
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

