# Intégration du téléchargement automatique de gta3.img

## Résumé

Le jeu **télécharge automatiquement** `gta3.img` (~500 MB) depuis Vercel Blob au démarrage dans le navigateur.

## Avantages

✅ **Build ultra-léger** : ~20 MB au lieu de ~500 MB  
✅ **Pas besoin d'assets locaux** : Le build fonctionne sans avoir GTA Vice City installé  
✅ **CDN rapide** : Les assets sont servis depuis Vercel Blob Storage  
✅ **Mise en cache** : Le navigateur garde `gta3.img` en mémoire après le premier téléchargement  
✅ **Logs détaillés** : Barre de progression + logs en cas d'erreur  

## Comment ça fonctionne

### 1. Build WASM

Le fichier `src/CMakeLists.txt` exclut maintenant `gta3.img` du bundle :

```cmake
"SHELL:--exclude-file=*.img"
```

Seuls les petits assets (textures, fonts, scripts) sont inclus dans `index.data`.

### 2. Runtime dans le navigateur

Au démarrage, le fichier `wasm-shell.html` exécute un `preRun` qui :

1. Télécharge `gta3.img` depuis : `https://3px5m57ackbno8gi.public.blob.vercel-storage.com/gta3.img`
2. Affiche une barre de progression en temps réel
3. Écrit le fichier dans le système de fichiers virtuel Emscripten (`/gamefiles/models/gta3.img`)
4. Lance le jeu une fois le téléchargement terminé

### 3. Gestion des crashes

Le système de logs a été amélioré pour afficher :

- ❌ Les erreurs JavaScript avec stack trace complète
- ❌ Les erreurs WebGL (contexte perdu)
- ❌ Les erreurs d'abort avec informations de debugging
- 📥 La progression du téléchargement de `gta3.img`

## Commandes

```bash
# Build WASM (plus besoin d'avoir gta3.img localement !)
./scripts/build-wasm.sh

# Lancer le serveur
cd server
npm install
npm run build
npm start

# Ouvrir le navigateur
# http://localhost:8080/stats.html
```

## Fichiers modifiés

1. **`src/CMakeLists.txt`** : Exclusion de `*.img` du bundle préchargé
2. **`server/public/wasm-shell.html`** : Téléchargement automatique de `gta3.img` + amélioration des logs de crash
3. **`scripts/build-wasm.sh`** : Suppression de la vérification de `gta3.img`
4. **Documentation** : `README.md`, `QUICKSTART_WASM_FR.md`

## URL du blob Vercel

```
https://3px5m57ackbno8gi.public.blob.vercel-storage.com/gta3.img
```

Ce fichier doit être hébergé de manière permanente et accessible publiquement.

## Troubleshooting

### Le téléchargement échoue

1. Vérifier que l'URL du blob est accessible
2. Vérifier la console du navigateur (F12) pour voir les erreurs réseau
3. Vérifier que le CORS est bien configuré sur le blob Vercel

### Le jeu crash après le téléchargement

1. Ouvrir la console (F12) et consulter les logs
2. Vérifier que `gta3.img` a bien été téléchargé (taille ~500 MB)
3. Les logs de crash détaillés sont affichés automatiquement dans l'interface

## Prochaines étapes possibles

- [ ] Ajouter un système de retry automatique en cas d'échec du téléchargement
- [ ] Compresser `gta3.img` avec gzip/brotli pour réduire le temps de téléchargement
- [ ] Ajouter une vérification de hash (MD5/SHA256) pour garantir l'intégrité
- [ ] Permettre le téléchargement par chunks pour reprendre en cas d'interruption
