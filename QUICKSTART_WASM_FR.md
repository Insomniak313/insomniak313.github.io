# Guide de démarrage rapide - reVC WASM

Ce guide vous explique comment builder et lancer reVC en version WebAssembly dans votre navigateur.

## Prérequis

- **Node.js** (v16 ou supérieur)
- **Linux, macOS ou Windows avec WSL/Git Bash**

> 💡 **Plus besoin d'avoir GTA Vice City installé !** Le jeu télécharge automatiquement les assets depuis Vercel Blob.

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

### 3️⃣ Builder le projet WASM

🎮 **Pas besoin d'importer les assets manuellement !**

Le jeu télécharge automatiquement `gta3.img` depuis Vercel Blob au premier démarrage dans le navigateur.

```bash
./scripts/build-wasm.sh
```

Cette étape prend environ 5-10 minutes. Les fichiers générés sont :
- `server/public/game/index.html`
- `server/public/game/index.js`
- `server/public/game/index.wasm`
- `server/public/game/index.data` (contient les petits assets, ~20 MB)

Le fichier `gta3.img` (~500 MB) sera téléchargé automatiquement depuis Vercel Blob au premier lancement.

### 4️⃣ Installer les dépendances du serveur (première fois uniquement)

```bash
cd server
npm install
```

### 5️⃣ Compiler le serveur TypeScript

```bash
npm run build
```

### 6️⃣ Lancer le serveur

```bash
npm start
```

Le serveur démarre sur **http://localhost:8080**

### 7️⃣ Ouvrir dans le navigateur

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

### ❌ Erreur de téléchargement de gta3.img

Le jeu télécharge automatiquement `gta3.img` depuis Vercel Blob au premier lancement. Si le téléchargement échoue :

1. Vérifiez votre connexion internet
2. Vérifiez que l'URL du blob est accessible : https://3px5m57ackbno8gi.public.blob.vercel-storage.com/gta3.img
3. Consultez les logs dans la console du navigateur (F12)

### ❌ Le jeu ne se charge pas dans le navigateur

1. Vérifiez que le serveur est bien démarré (`npm start` dans `server/`)
2. Ouvrez la console du navigateur (F12) pour voir les erreurs
3. Vérifiez que `index.data` existe dans `server/public/game/`
4. Attendez que le téléchargement de `gta3.img` (~500 MB) soit terminé - cela peut prendre quelques minutes

### ❌ "Can't open gta3.img"

Le jeu n'a pas pu télécharger ou trouver `gta3.img`. Vérifiez :
1. Ouvrez la console du navigateur (F12) pour voir les logs de téléchargement
2. Vérifiez que le téléchargement depuis Vercel Blob a réussi
3. Si le problème persiste, essayez de recharger la page

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

- Le build WASM peut être lent sur les machines modestes (5-10 minutes)
- Le premier chargement dans le navigateur télécharge `gta3.img` (~500 MB) - cela peut prendre quelques minutes
- Le fichier est mis en cache, les prochains lancements sont instantanés
- Le jeu devrait tourner à 30-60 FPS sur un ordinateur moderne
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
