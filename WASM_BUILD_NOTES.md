# Notes de build WASM - reVC

## Corrections apportées pour résoudre l'erreur de CdStream

### Problème initial
```
cdvd_stream: can't get filesystem info
REVC ASSERT FAILED
	File: /workspace/src/core/CdStream_posix.cpp
	Line: 206
```

### Cause
Le code utilisait des threads POSIX (`pthreads`) qui sont désactivés dans le build WASM (`-sUSE_PTHREADS=0`) car GitHub Pages ne peut pas servir les headers COOP/COEP nécessaires pour les SharedArrayBuffer.

### Solution
1. **Implémentation synchrone pour WASM** : Créé une version de `CdStream` sans threads dans `CdStream_posix.cpp`
2. **Correction des chemins** : Les fichiers `gamefiles/` sont maintenant montés à la racine du filesystem virtuel
3. **Configuration Emscripten** : Ajout du port GLFW et désactivation des vérifications OpenGL natives

## Build WASM

```bash
# 1. Installer Emscripten (une seule fois)
./scripts/setup-emsdk.sh
source .emsdk/emsdk_env.sh

# 2. Initialiser les sous-modules Git (une seule fois)
git submodule update --init --recursive

# 3. Importer les assets GTA Vice City (OBLIGATOIRE)
# Option A - Import automatique depuis votre installation GTA VC
./scripts/import-assets.sh "/chemin/vers/GTA Vice City"

# Option B - Téléchargement manuel
./scripts/download-assets.sh

# Option C - Copie manuelle
cp "/chemin/vers/GTA Vice City/models/gta3.img" ./gamefiles/models/

# Vérifier que les assets sont présents
./scripts/verify-assets.sh

# 4. Builder le projet WASM
./scripts/build-wasm.sh
```

Les fichiers générés se trouvent dans `server/public/game/`:
- `index.html` - Page HTML
- `index.js` - Code JavaScript
- `index.wasm` - Module WebAssembly
- `index.data` - Fichiers de jeu empaquetés

## Lancer le serveur

```bash
cd server
npm install
npm run build
npm start
```

Le serveur démarre sur http://localhost:3000

## Vérification

Les fichiers de jeu (textures, modèles, etc.) sont maintenant accessibles depuis la racine:
- `/models/gta3.img` ✅
- `/neo/neo.txd` ✅
- `/text/french.gxt` ✅

Au lieu de:
- `/gamefiles/models/gta3.img` ❌
- `/gamefiles/neo/neo.txd` ❌
- `/gamefiles/text/french.gxt` ❌

## Fichiers modifiés

- `src/core/CdStream_posix.cpp` - Ajout implémentation WASM synchrone
- `src/CMakeLists.txt` - Correction point de montage + port GLFW
- `vendor/librw/src/CMakeLists.txt` - Désactivation dépendances OpenGL pour WASM
