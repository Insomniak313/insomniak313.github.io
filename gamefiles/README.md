# Fichiers de jeu GTA Vice City

Ce dossier contient les fichiers nécessaires pour faire fonctionner reVC.

## Fichiers manquants requis

**⚠️ IMPORTANT** : Les fichiers suivants doivent être copiés depuis votre installation originale de GTA Vice City :

### models/gta3.img (~500 MB)
Le fichier principal contenant tous les modèles 3D et textures du jeu.

**Où le trouver :**
- **Windows (Steam)** : `C:\Program Files (x86)\Steam\steamapps\common\Grand Theft Auto Vice City\models\gta3.img`
- **Windows (Rockstar)** : `C:\Program Files\Rockstar Games\Grand Theft Auto Vice City\models\gta3.img`
- **Linux (Proton/Wine)** : `~/.steam/steam/steamapps/common/Grand Theft Auto Vice City/models/gta3.img`

**Commande pour copier :**
```bash
# Windows (Git Bash / WSL)
cp "/c/Program Files (x86)/Steam/steamapps/common/Grand Theft Auto Vice City/models/gta3.img" \
   ./gamefiles/models/

# Linux
cp ~/.steam/steam/steamapps/common/Grand\ Theft\ Auto\ Vice\ City/models/gta3.img \
   ./gamefiles/models/

# Mac (si installé via Wine/CrossOver)
cp ~/Library/Application\ Support/Steam/steamapps/common/Grand\ Theft\ Auto\ Vice\ City/models/gta3.img \
   ./gamefiles/models/
```

### Optionnel : models/txd.img
Fichier de textures additionnelles (si présent dans votre version).

## Structure complète

Après avoir copié `gta3.img`, la structure devrait être :

```
gamefiles/
├── README.md (ce fichier)
├── data/
│   └── freeroam_miami.scm
├── models/
│   ├── gta3.img          ← À COPIER depuis le jeu original
│   ├── fonts_r.txd       ← Déjà présent
│   ├── frontend_*.txd    ← Déjà présent
│   ├── generic.txd
│   ├── particle.txd
│   └── ...
├── neo/
│   ├── neo.txd
│   ├── carTweakingTable.dat
│   └── ...
└── TEXT/
    ├── french.gxt
    ├── american.gxt
    └── ...
```

## Vérification

Pour vérifier que les fichiers sont bien copiés :

```bash
ls -lh gamefiles/models/gta3.img
# Devrait afficher : -rw-r--r-- 1 user user 550M ... gamefiles/models/gta3.img
```

## Build WASM

Une fois les fichiers copiés, vous pouvez builder le jeu en WASM :

```bash
./scripts/build-wasm.sh
```

Les fichiers seront empaquetés dans `server/public/game/index.data` (~14 MB + taille de gta3.img).

## Licence

Ces fichiers (`gta3.img`, etc.) appartiennent à Rockstar Games et ne peuvent pas être redistribués.
Vous devez posséder une copie légale de GTA Vice City pour les utiliser.

reVC est un projet de décompilation à but éducatif et de modding uniquement.
