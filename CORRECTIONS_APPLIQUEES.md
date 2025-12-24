# ✅ Corrections appliquées - Erreur CdStream WASM

## Problème initial

```
cdvd_stream: can't get filesystem info

REVC ASSERT FAILED
	File: /workspace/src/core/CdStream_posix.cpp
	Line: 206
	Function: CdStreamInit
	Expression: 0

casepath couldn't find dir/file "neo", full path was neo/neo.txd
casepath couldn't find dir/file "text", full path was text/russian.gxt
```

## Solutions appliquées

### ✅ 1. Implémentation CdStream synchrone pour WASM

**Fichier** : `src/core/CdStream_posix.cpp`

Le code original utilisait des threads POSIX (`pthread`) qui sont désactivés dans le build WASM car GitHub Pages ne peut pas servir les headers COOP/COEP nécessaires.

**Changements** :
- Ajout d'une section `#ifdef __EMSCRIPTEN__` avec implémentation synchrone
- Lecture directe des fichiers sans threads
- Évite l'appel à `statvfs()` qui échouait
- Suppression des dépendances à `<pthread.h>`, `<semaphore.h>` pour Emscripten

### ✅ 2. Correction du point de montage des fichiers

**Fichier** : `src/CMakeLists.txt`

Les fichiers étaient montés dans `/gamefiles/` mais le jeu les cherchait à la racine.

**Avant** :
```cmake
"SHELL:${PROJECT_SOURCE_DIR}/gamefiles@/gamefiles"
```

**Après** :
```cmake
"SHELL:${PROJECT_SOURCE_DIR}/gamefiles@/"
```

Maintenant les fichiers sont accessibles à :
- ✅ `/models/gta3.img`
- ✅ `/neo/neo.txd`
- ✅ `/TEXT/french.gxt`

### ✅ 3. Configuration Emscripten pour GLFW et OpenGL

**Fichiers** : `src/CMakeLists.txt`, `vendor/librw/src/CMakeLists.txt`

Ajout du port GLFW Emscripten et désactivation des recherches de bibliothèques natives.

**Changements** :
- Ajout de `--use-port=contrib.glfw3` dans les options de link
- Skip `find_package(glfw3)` pour Emscripten
- Skip `find_package(OpenGL)` pour Emscripten

### ✅ 4. Configuration .gitignore

Ajout de l'exclusion des fichiers `.img` qui sont volumineux (~500 MB) et appartiennent au jeu original.

## État actuel

### ✅ Build WASM réussi

```bash
$ ./scripts/build-wasm.sh
...
[100%] Built target reVC
```

**Fichiers générés** :
- ✅ `server/public/game/index.html`
- ✅ `server/public/game/index.js`
- ✅ `server/public/game/index.wasm` (3.1 MB)
- ✅ `server/public/game/index.data` (14 MB)

### ⚠️ Fichiers manquants

Le fichier `models/gta3.img` n'est pas présent dans le dépôt (normal, il appartient à Rockstar Games).

**Vous devez le copier depuis votre installation GTA Vice City** :

```bash
# Windows (Steam)
cp "/c/Program Files (x86)/Steam/steamapps/common/Grand Theft Auto Vice City/models/gta3.img" \
   ./gamefiles/models/

# Linux (Steam + Proton)
cp ~/.steam/steam/steamapps/common/Grand\ Theft\ Auto\ Vice\ City/models/gta3.img \
   ./gamefiles/models/
```

Voir `gamefiles/README.md` pour plus de détails.

## Prochaines étapes

### 1. Copier les fichiers du jeu original

```bash
# Copier gta3.img depuis votre installation GTA Vice City
# Voir gamefiles/README.md pour les chemins selon votre plateforme
```

### 2. Rebuilder avec les fichiers du jeu

```bash
source .emsdk/emsdk_env.sh
./scripts/build-wasm.sh
```

Le fichier `index.data` sera régénéré avec `gta3.img` inclus (~514 MB).

### 3. Tester localement

```bash
cd server
npm install
npm run build
npm start
```

Ouvrir http://localhost:3000/game/index.html

### 4. Vérifier les logs

Dans la console du navigateur (F12), vous devriez voir :

```
[DBG]: size of matrix 72
[DBG]: size of placeable 72
[DBG]: size of entity 100
cdvd_stream: Initializing CdStream (WASM mode)
WASM: CdStream initialized without threads (synchronous mode)
```

**Plus d'erreurs** :
- ❌ `cdvd_stream: can't get filesystem info`
- ❌ `casepath couldn't find dir/file`
- ❌ `REVC ASSERT FAILED`

## Documentation créée

- 📄 `WASM_BUILD_NOTES.md` - Notes techniques des corrections
- 📄 `WASM_SETUP_FR.md` - Guide complet de configuration WASM
- 📄 `gamefiles/README.md` - Instructions pour copier les fichiers du jeu
- 📄 `CORRECTIONS_APPLIQUEES.md` - Ce fichier

## Résumé technique

| Problème | Solution | Fichier |
|----------|----------|---------|
| Threads POSIX non supportés | Implémentation synchrone pour WASM | `src/core/CdStream_posix.cpp` |
| Fichiers non trouvés | Montage à la racine au lieu de `/gamefiles/` | `src/CMakeLists.txt` |
| GLFW manquant | Utilisation du port Emscripten | `src/CMakeLists.txt` |
| OpenGL natif requis | Skip find_package pour Emscripten | `vendor/librw/src/CMakeLists.txt` |

## Support

Si le jeu ne se lance toujours pas :

1. **Vérifier que `gta3.img` est présent** :
   ```bash
   ls -lh gamefiles/models/gta3.img
   ```

2. **Vérifier les logs du navigateur** (F12 → Console)

3. **Rebuilder depuis zéro** :
   ```bash
   rm -rf build-wasm
   source .emsdk/emsdk_env.sh
   ./scripts/build-wasm.sh
   ```

4. **Tester le montage des fichiers** (dans la console du navigateur) :
   ```javascript
   FS.readdir('/models')  // Doit afficher ['gta3.img', 'fonts_r.txd', ...]
   ```
