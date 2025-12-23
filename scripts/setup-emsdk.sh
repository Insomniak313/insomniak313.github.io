#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EMSDK_DIR="${ROOT_DIR}/.emsdk"

if [[ ! -d "${EMSDK_DIR}/.git" ]]; then
  echo "Clonage de emsdk dans ${EMSDK_DIR}…"
  git clone --depth 1 https://github.com/emscripten-core/emsdk.git "${EMSDK_DIR}"
fi

pushd "${EMSDK_DIR}" >/dev/null
./emsdk install latest
./emsdk activate latest
popd >/dev/null

cat <<EOF

Emscripten est installé. Pour l'activer dans ton shell courant :

  source "${EMSDK_DIR}/emsdk_env.sh"

Ensuite tu peux builder le jeu en WASM :

  ./scripts/build-wasm.sh

EOF

