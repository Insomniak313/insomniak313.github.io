# 🚀 Installation ultra-rapide - reVC WASM

## Pour télécharger depuis Liberty City (le plus simple)

```bash
# 1. Télécharger et installer les assets (guidé, interactif)
./scripts/download-libertycity.sh

# 2. Setup Emscripten (première fois)
./scripts/setup-emsdk.sh
source .emsdk/emsdk_env.sh

# 3. Initialiser les sous-modules (première fois)
git submodule update --init --recursive

# 4. Builder WASM
./scripts/build-wasm.sh

# 5. Setup et démarrer le serveur
cd server
npm install
npm run build
npm start
```

**C'est tout !** Ouvrez http://localhost:8080/stats.html dans votre navigateur.

---

## Détails du processus

### Étape 1 : Assets (guidé)

Le script `./scripts/download-libertycity.sh` va :
1. ✓ Vous donner le lien Liberty City à ouvrir
2. ✓ Vous guider pour télécharger le fichier
3. ✓ Détecter automatiquement le fichier téléchargé
4. ✓ L'extraire si c'est une archive
5. ✓ Le copier au bon endroit
6. ✓ Vérifier que tout est OK

**Temps estimé : 5-10 minutes** (selon votre connexion)

### Étape 2-3 : Setup (une fois)

Installation d'Emscripten et des dépendances.

**Temps estimé : 5 minutes**

### Étape 4 : Build WASM

Compilation du jeu en WebAssembly.

**Temps estimé : 5-10 minutes**

### Étape 5 : Serveur

Installation des dépendances Node.js et démarrage.

**Temps estimé : 2 minutes**

---

## Vérifier l'état à tout moment

```bash
./scripts/status.sh
```

Ce script affiche l'état complet du projet et vous dit exactement quoi faire.

---

## En cas de problème

### Le téléchargement ne fonctionne pas

Si Liberty City nécessite une authentification ou un CAPTCHA :
1. Téléchargez manuellement via votre navigateur
2. Une fois téléchargé, relancez le script qui détectera automatiquement le fichier

### Le fichier est dans une archive

Le script gère automatiquement les formats `.zip`, `.rar`, et `.7z`.

### Le build échoue

```bash
# Nettoyer et rebuilder
rm -rf build-wasm
./scripts/build-wasm.sh
```

### Autres problèmes

Consultez les guides détaillés :
- 📖 [`QUICKSTART_WASM_FR.md`](QUICKSTART_WASM_FR.md) - Guide complet
- 📖 [`gamefiles/models/README.md`](gamefiles/models/README.md) - Guide assets
- 💬 [Discord](https://discord.gg/RFNbjsUMGg) - Support communautaire

---

## Alternative : Import depuis Steam

Si vous avez GTA Vice City sur Steam :

```bash
./scripts/import-assets.sh "/chemin/vers/GTA Vice City"
```

C'est encore plus simple et légal ! 😊
