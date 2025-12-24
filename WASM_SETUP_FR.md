# Configuration WASM pour reVC

## Problème résolu : Erreur CdStream

L'erreur `cdvd_stream: can't get filesystem info` a été corrigée en implémentant une version synchrone du système de streaming pour Emscripten (WASM sans threads).

## Prérequis

1. **Posséder GTA Vice City** - Les fichiers du jeu original sont nécessaires
2. **Node.js 20+** pour le serveur
3. **Emscripten SDK** pour compiler en WASM

## Installation des fichiers du jeu

### Étape 1 : Copier les fichiers IMG

Les fichiers `.img` contiennent tous les modèles et textures du jeu. Ils doivent être copiés depuis votre installation de GTA Vice City :

```bash
# Depuis votre installation GTA Vice City (Windows)
# Copier vers le dossier gamefiles/models/ de reVC

cp "C:/Program Files (x86)/Steam/steamapps/common/Grand Theft Auto Vice City/models/gta3.img" \
   /workspace/gamefiles/models/

# Ou sur Linux/Mac si vous avez GTA VC via Wine/Proton
cp ~/.steam/steam/steamapps/common/Grand\ Theft\ Auto\ Vice\ City/models/gta3.img \
   /workspace/gamefiles/models/
```

**Fichiers IMG requis :**
- `models/gta3.img` - Modèles et textures principaux (~ 500 MB)
- Optionnel : `models/txd.img` - Textures additionnelles si présent

### Étape 2 : Vérifier la structure

```
gamefiles/
├── models/
│   ├── gta3.img          ← REQUIS (du jeu original)
│   ├── fonts_r.txd       ← Déjà présent
│   ├── frontend_*.txd    ← Déjà présent
│   └── ...
├── data/
│   └── freeroam_miami.scm
├── neo/
│   ├── neo.txd
│   └── ...
└── TEXT/
    ├── french.gxt
    └── ...
```

## Build WASM

### 1. Installer Emscripten (une seule fois)

```bash
./scripts/setup-emsdk.sh
source .emsdk/emsdk_env.sh
```

### 2. Initialiser les sous-modules (une seule fois)

```bash
git submodule update --init --recursive
```

### 3. Builder

```bash
./scripts/build-wasm.sh
```

Les fichiers générés :
- `server/public/game/index.html` - Page de lancement
- `server/public/game/index.js` - Code JavaScript
- `server/public/game/index.wasm` - Module WebAssembly
- `server/public/game/index.data` - Fichiers empaquetés (~14 MB)

## Lancer le jeu

### Mode serveur local

```bash
cd server
npm install
npm run build
npm start
```

Ouvrir http://localhost:3000/game/index.html

### Déployer sur GitHub Pages

Le workflow `.github/workflows/deploy.yml` build et déploie automatiquement :

1. Push sur la branche `miami`
2. Le workflow compile le WASM
3. Les fichiers sont publiés sur GitHub Pages
4. Accès via `https://<user>.github.io/<repo>/game/index.html`

**⚠️ Important** : Les fichiers `.img` sont volumineux. Vous devrez peut-être :
- Les héberger séparément et les charger dynamiquement
- Ou les compresser dans le package WASM (augmente le temps de chargement initial)

## Vérification du build

### Tester que les fichiers sont montés correctement

Le code JavaScript dans la console du navigateur :

```javascript
// Dans la console du navigateur (F12)
FS.readdir('/models')  // Devrait afficher ['gta3.img', 'fonts_r.txd', ...]
FS.stat('/models/gta3.img')  // Devrait afficher les infos du fichier
```

### Logs attendus (succès)

```
[DBG]: size of matrix 72
[DBG]: size of placeable 72
[DBG]: size of entity 100
[DBG]: size of building 100
[DBG]: size of dummy 104
cdvd_stream: Initializing CdStream (WASM mode)
WASM: CdStream initialized without threads (synchronous mode)
```

### Erreurs courantes

**Erreur** : `casepath couldn't find dir/file "models", full path was models/gta3.img`
- **Cause** : Le fichier `gta3.img` n'existe pas dans `gamefiles/models/`
- **Solution** : Copier le fichier depuis votre installation GTA Vice City

**Erreur** : `REVC ASSERT FAILED - CdStreamInit`
- **Cause** : Ancienne version du code (avant les corrections)
- **Solution** : Recompiler avec `./scripts/build-wasm.sh`

**Erreur** : `SharedArrayBuffer is not defined`
- **Cause** : Headers COOP/COEP manquants (GitHub Pages)
- **Solution** : C'est normal, le build utilise `-sUSE_PTHREADS=0` pour éviter ce problème

## Modifications techniques apportées

### 1. `src/core/CdStream_posix.cpp`
- Ajout d'une implémentation synchrone pour `__EMSCRIPTEN__`
- Lecture directe des fichiers sans threads
- Évite `statvfs()` qui n'est pas nécessaire sur un FS virtuel

### 2. `src/CMakeLists.txt`
- Correction du point de montage : `gamefiles@/` au lieu de `gamefiles@/gamefiles`
- Ajout de `--use-port=contrib.glfw3` pour GLFW Emscripten

### 3. `vendor/librw/src/CMakeLists.txt`
- Skip `find_package(glfw3)` et `find_package(OpenGL)` pour Emscripten
- Les bibliothèques sont fournies par les ports Emscripten

## Performance

**Temps de build** : ~3-5 minutes (après installation SDK)
**Taille du bundle** :
- `index.wasm` : ~3 MB
- `index.data` : ~14 MB (gamefiles + assets)
- **Total avec gta3.img** : ~500 MB (temps de chargement initial élevé)

**Recommandations** :
- Héberger les gros fichiers `.img` sur un CDN
- Les charger à la demande via `FS.lazy_load` d'Emscripten
- Ou utiliser un système de streaming progressif

## Support

Si vous rencontrez des problèmes :
1. Vérifiez que `gamefiles/models/gta3.img` existe
2. Vérifiez les logs dans la console du navigateur (F12)
3. Recompilez depuis zéro : `rm -rf build-wasm && ./scripts/build-wasm.sh`
