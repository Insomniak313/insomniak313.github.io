# Assets GTA Vice City - Instructions d'installation

⚠️ **IMPORTANT** : Ce projet nécessite les assets originaux de GTA Vice City. Vous devez posséder une copie légale du jeu.

## Fichiers requis

Pour que le jeu WASM fonctionne, vous devez placer les fichiers suivants dans ce dossier (`gamefiles/models/`) :

### Fichier principal (OBLIGATOIRE)
- **`gta3.img`** (environ 400-700 MB) - Archive contenant tous les modèles 3D et textures du jeu

### Fichiers supplémentaires recommandés
- `gta3.dir` - Index pour gta3.img (si disponible)
- `default.ide` - Définitions des objets
- `txd.img` et `txd.dir` - Textures additionnelles (si présents dans votre version)

## Comment obtenir ces fichiers

### Option 1 : Depuis votre installation Steam de GTA Vice City

1. Localisez votre installation GTA Vice City (généralement dans `C:\Program Files (x86)\Steam\steamapps\common\Grand Theft Auto Vice City\`)
2. Copiez le fichier `models/gta3.img` vers ce dossier
3. Copiez également `models/gta3.dir` s'il existe

### Option 2 : Depuis une autre installation légitime

1. Trouvez le dossier d'installation de GTA Vice City
2. Allez dans le sous-dossier `models/`
3. Copiez `gta3.img` (et `gta3.dir` si présent) vers ce dossier

### Option 3 : Utiliser le script d'import automatique

Nous fournissons un script shell pour automatiser la copie :

```bash
# Depuis la racine du projet
./scripts/import-assets.sh "/chemin/vers/votre/GTA Vice City"
```

## Téléchargement depuis des sites tiers

Si vous ne possédez pas le jeu mais souhaitez utiliser des assets disponibles publiquement :

1. **Téléchargez manuellement** le fichier `gta3.img` depuis une source légitime (comme celle mentionnée dans votre ticket)
2. Placez le fichier téléchargé dans ce dossier (`gamefiles/models/`)
3. Vérifiez l'intégrité du fichier :

```bash
# Depuis la racine du projet
./scripts/verify-assets.sh
```

## Vérification

Une fois les fichiers copiés, votre dossier `gamefiles/models/` devrait contenir au minimum :

```
gamefiles/models/
├── gta3.img          ← OBLIGATOIRE (400-700 MB)
├── gta3.dir          ← Recommandé
├── fonts_r.txd
├── generic.txd
├── particle.txd
└── ... (autres fichiers déjà présents)
```

## Rebuild WASM

Après avoir ajouté les assets, vous devez rebuilder le projet WASM :

```bash
# Depuis la racine du projet
source .emsdk/emsdk_env.sh
./scripts/build-wasm.sh
```

Les assets seront automatiquement empaquetés dans `server/public/game/index.data`.

## Dépannage

### "Can't open gta3.img"
- Vérifiez que le fichier existe bien dans `gamefiles/models/gta3.img`
- Vérifiez les permissions du fichier (doit être lisible)

### "Corrupted IMG file"
- Le fichier téléchargé est peut-être corrompu
- Essayez de télécharger à nouveau
- Vérifiez l'intégrité avec MD5/SHA256

### Le jeu se lance mais crashe
- Assurez-vous d'utiliser la version PC du fichier `gta3.img`
- Les versions PS2/Xbox ne sont pas compatibles sans conversion

## Taille attendue

- `gta3.img` : environ **400-700 MB** (varie selon la version du jeu)
- Le fichier `index.data` généré après le build WASM fera environ **450-750 MB**

## Support

Si vous rencontrez des problèmes, consultez :
- [README principal du projet](../../README.md)
- [Notes de build WASM](../../WASM_BUILD_NOTES.md)
- [Issues GitHub](https://github.com/mrxenginner/reVC/issues)
