# 📡 Instructions pour environnement Cloud/Distant

Vous travaillez actuellement dans un **environnement de développement cloud/distant**.

## 🎯 Comment intégrer les assets dans cet environnement

### Option 1 : Upload du fichier gta3.img (RECOMMANDÉ pour cloud)

1. **Téléchargez** `gta3.img` sur votre machine locale depuis :
   - Votre installation GTA Vice City (Steam/Rockstar)
   - Ou depuis Liberty City : https://libertycity.net/files/gta-vice-city/57988-original-gta3.img.html

2. **Uploadez** le fichier dans ce workspace :
   - Dans VSCode/Cursor : Glissez-déposez `gta3.img` dans le dossier `gamefiles/models/`
   - Via ligne de commande (si vous avez accès SSH) : `scp gta3.img user@remote:/workspace/gamefiles/models/`

3. **Vérifiez** que le fichier est bien présent :
   ```bash
   ls -lh /workspace/gamefiles/models/gta3.img
   ```

4. **Lancez la vérification** :
   ```bash
   ./scripts/verify-assets.sh
   ```

5. **Buildez** le projet :
   ```bash
   source .emsdk/emsdk_env.sh
   ./scripts/build-wasm.sh
   ```

### Option 2 : Copie depuis un chemin réseau/monté

Si vous avez monté un volume ou un chemin réseau avec GTA Vice City :

```bash
cp /chemin/monte/GTA_Vice_City/models/gta3.img ./gamefiles/models/
./scripts/verify-assets.sh
```

### Option 3 : Travail en local (sortir du cloud)

Pour un contrôle total, clonez le projet sur votre machine locale :

```bash
# Sur votre machine locale
git clone https://github.com/mrxenginner/reVC.git
cd reVC
git checkout cursor/gta-3-asset-integration-3590

# Installer les assets automatiquement
./scripts/auto-install-assets.sh

# Ou depuis votre installation GTA VC
./scripts/import-assets.sh "/chemin/vers/GTA Vice City"

# Builder et lancer
./scripts/setup-emsdk.sh
source .emsdk/emsdk_env.sh
./scripts/build-wasm.sh
cd server && npm install && npm run build && npm start
```

## 🔍 Vérifier l'état actuel

À tout moment, vérifiez l'état du projet :

```bash
./scripts/status.sh
```

Cela vous dira exactement ce qui manque et quoi faire.

## 📦 Taille du fichier attendue

- `gta3.img` : **400-700 MB** (varie selon la version)
- Si votre fichier fait moins de 300 MB, il est probablement corrompu

## ⚡ Upload via interface Web

Si vous utilisez Cursor/VSCode dans le navigateur :

1. Ouvrez l'explorateur de fichiers (panneau gauche)
2. Naviguez vers `gamefiles/models/`
3. Clic droit → "Upload..."
4. Sélectionnez votre fichier `gta3.img`
5. Attendez que l'upload se termine (peut prendre quelques minutes vu la taille)

## 🚀 Après l'installation des assets

Une fois `gta3.img` en place dans `gamefiles/models/` :

```bash
# 1. Vérifier
./scripts/verify-assets.sh

# 2. Setup Emscripten (si première fois)
./scripts/setup-emsdk.sh
source .emsdk/emsdk_env.sh

# 3. Initialiser sous-modules (si première fois)
git submodule update --init --recursive

# 4. Builder WASM
./scripts/build-wasm.sh

# 5. Setup serveur
cd server
npm install
npm run build
npm start
```

Puis ouvrez : **http://localhost:8080/stats.html**

## 🆘 Besoin d'aide ?

- 📖 Guide rapide : `cat INSTALLATION_RAPIDE_FR.md`
- 📖 Guide complet : `cat QUICKSTART_WASM_FR.md`
- 🔍 État du projet : `./scripts/status.sh`
- 💬 Discord : https://discord.gg/RFNbjsUMGg
