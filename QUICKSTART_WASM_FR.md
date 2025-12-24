# Guide de démarrage rapide - reVC WASM

Ce guide vous explique comment builder et lancer reVC en version WebAssembly dans votre navigateur.

## Prérequis

- **Node.js** (v16 ou supérieur)
- **Une copie légale de GTA Vice City** (pour les assets)
- **Linux, macOS ou Windows avec WSL/Git Bash**

## Étapes rapides

### 1️⃣ Installer Emscripten (première fois uniquement)

```bash
./scripts/setup-emsdk.sh
source .emsdk/emsdk_env.sh
```

> 💡 Vous devrez exécuter `source .emsdk/emsdk_env.sh` dans chaque nouveau terminal.

### 2️⃣ Initialiser les sous-modules Git (première fois uniquement)

```bash
git submodule update --init --recursive
```

### 3️⃣ Importer les assets GTA Vice City ⚠️ **OBLIGATOIRE**

#### Option A : Téléchargement automatique depuis Vercel Blob (recommandé) 🚀

Le moyen le plus simple et rapide :

```bash
./scripts/download-gta3-blob.sh
```

Ce script télécharge automatiquement `gta3.img` depuis notre blob Vercel hébergé (~500 MB).

> 💡 **Note** : Le build WASM (`./scripts/build-wasm.sh`) télécharge automatiquement `gta3.img` s'il est manquant, vous pouvez donc sauter cette étape !

#### Option B : Import depuis votre installation GTA

Si vous avez GTA Vice City installé sur votre machine :

```bash
./scripts/import-assets.sh "/chemin/vers/votre/GTA Vice City"
```

**Exemples de chemins courants :**

- **Windows (Steam)** :
  ```bash
  ./scripts/import-assets.sh "/c/Program Files (x86)/Steam/steamapps/common/Grand Theft Auto Vice City"
  ```

- **Linux (Steam)** :
  ```bash
  ./scripts/import-assets.sh ~/.steam/steam/steamapps/common/Grand\ Theft\ Auto\ Vice\ City
  ```

- **Mac (Steam)** :
  ```bash
  ./scripts/import-assets.sh ~/Library/Application\ Support/Steam/steamapps/common/Grand\ Theft\ Auto\ Vice\ City
  ```

#### Option C : Téléchargement manuel depuis une URL

Si vous avez un fichier `gta3.img` téléchargé depuis une source externe :

```bash
./scripts/download-assets.sh
```

Le script vous demandera l'URL du fichier à télécharger.

> ⚠️ **Avertissement légal** : Assurez-vous de posséder une copie légale du jeu avant d'utiliser des assets téléchargés.

#### Option D : Copie manuelle

Si vous préférez copier manuellement :

```bash
cp "/chemin/vers/GTA Vice City/models/gta3.img" ./gamefiles/models/
```

### 4️⃣ Vérifier les assets

```bash
./scripts/verify-assets.sh
```

Vous devriez voir :
```
✓ gta3.img (550M) - Présent
✓ Tous les assets nécessaires sont présents !
```

### 5️⃣ Builder le projet WASM

```bash
./scripts/build-wasm.sh
```

Cette étape prend environ 5-10 minutes. Les fichiers générés sont :
- `server/public/game/index.html`
- `server/public/game/index.js`
- `server/public/game/index.wasm`
- `server/public/game/index.data` (contient les assets)

### 6️⃣ Installer les dépendances du serveur (première fois uniquement)

```bash
cd server
npm install
```

### 7️⃣ Compiler le serveur TypeScript

```bash
npm run build
```

### 8️⃣ Lancer le serveur

```bash
npm start
```

Le serveur démarre sur **http://localhost:8080**

### 9️⃣ Ouvrir dans le navigateur

Ouvrez votre navigateur et accédez à :

**http://localhost:8080/stats.html**

Le jeu devrait se charger et s'afficher dans votre navigateur ! 🎮

## Commandes récapitulatives

```bash
# Setup complet (première fois)
./scripts/setup-emsdk.sh
source .emsdk/emsdk_env.sh
git submodule update --init --recursive
./scripts/import-assets.sh "/chemin/vers/GTA Vice City"
./scripts/verify-assets.sh
./scripts/build-wasm.sh
cd server && npm install && npm run build

# Lancer le serveur
cd server && npm start

# Rebuild après modification du code C++
source .emsdk/emsdk_env.sh
./scripts/build-wasm.sh
```

## Dépannage

### ❌ "Emscripten (emcmake) n'est pas disponible"

Solution :
```bash
source .emsdk/emsdk_env.sh
```

### ❌ "gta3.img est MANQUANT (OBLIGATOIRE)"

Solution : Vous devez importer les assets du jeu original. Voir étape 3.

### ❌ Le jeu ne se charge pas dans le navigateur

1. Vérifiez que le serveur est bien démarré (`npm start` dans `server/`)
2. Ouvrez la console du navigateur (F12) pour voir les erreurs
3. Vérifiez que `index.data` existe dans `server/public/game/`
4. Vérifiez que les assets ont bien été importés avec `./scripts/verify-assets.sh`

### ❌ "Can't open gta3.img"

Le jeu cherche le fichier `gta3.img` mais ne le trouve pas. Vérifiez :
```bash
ls -lh gamefiles/models/gta3.img
```

Si le fichier n'existe pas, retournez à l'étape 3.

### ❌ Le build WASM échoue

Essayez de nettoyer et rebuilder :
```bash
rm -rf build-wasm
./scripts/build-wasm.sh
```

### ❌ Le serveur ne démarre pas

Vérifiez que Node.js est installé :
```bash
node --version  # Devrait afficher v16 ou supérieur
```

Réinstallez les dépendances :
```bash
cd server
rm -rf node_modules package-lock.json
npm install
npm run build
npm start
```

## Performance

- Le build WASM peut être lent sur les machines modestes
- Le chargement initial dans le navigateur prend environ 10-30 secondes
- Pour de meilleures performances, utilisez Chrome ou Edge (meilleur support WebAssembly)

## Multijoueur

Le serveur inclut un système de multijoueur via WebSocket. Plusieurs joueurs peuvent se connecter simultanément à `http://localhost:8080/stats.html`.

Pour plus d'informations sur le multijoueur, consultez [`MULTIPLAYER.md`](MULTIPLAYER.md).

## Structure du projet

```
reVC/
├── gamefiles/              # Assets du jeu (à importer)
│   ├── models/
│   │   ├── gta3.img       ← À importer depuis GTA VC
│   │   └── README.md      ← Instructions détaillées
│   ├── data/
│   ├── neo/
│   └── TEXT/
├── scripts/
│   ├── setup-emsdk.sh     # Installer Emscripten
│   ├── build-wasm.sh      # Builder le projet WASM
│   ├── import-assets.sh   # Importer les assets automatiquement
│   ├── verify-assets.sh   # Vérifier les assets
│   └── download-assets.sh # Télécharger les assets manuellement
├── server/
│   ├── src/               # Code serveur TypeScript
│   ├── public/
│   │   ├── game/          # Fichiers WASM générés
│   │   └── stats.html     # Page de statistiques/lancement
│   └── package.json
└── src/                   # Code source C++ de reVC
```

## Ressources

- **README principal** : [`README.md`](README.md)
- **Notes de build WASM** : [`WASM_BUILD_NOTES.md`](WASM_BUILD_NOTES.md)
- **Guide d'import des assets** : [`gamefiles/models/README.md`](gamefiles/models/README.md)
- **Documentation serveur** : [`server/README.md`](server/README.md)
- **Multijoueur** : [`MULTIPLAYER.md`](MULTIPLAYER.md)

## Support

- **Issues GitHub** : https://github.com/mrxenginner/reVC/issues
- **Discord** : https://discord.gg/RFNbjsUMGg

---

**Bon jeu ! 🎮**
