# Guide de téléchargement des assets GTA Vice City

Ce guide vous explique comment télécharger et installer manuellement le fichier `gta3.img` nécessaire pour faire fonctionner reVC en mode WASM.

## ⚠️ Important - Légalité

Les fichiers d'assets de GTA Vice City sont la propriété de **Rockstar Games** et sont protégés par le droit d'auteur.

- **Vous devez posséder une copie légale** de GTA Vice City pour utiliser ces assets
- Le projet reVC est destiné à des fins **éducatives et de modding uniquement**
- Nous ne distribuons pas et ne pouvons pas distribuer les assets originaux

## Option 1 : Import depuis votre installation (RECOMMANDÉ)

Si vous possédez GTA Vice City sur Steam, Epic Games, GOG ou Rockstar Games :

```bash
./scripts/import-assets.sh "/chemin/vers/votre/GTA Vice City"
```

C'est la méthode **la plus simple et la plus légale**.

## Option 2 : Téléchargement manuel depuis un site tiers

Si vous souhaitez télécharger `gta3.img` depuis un site tiers (par exemple, celui que vous avez mentionné), suivez ces étapes :

### Étape 1 : Télécharger le fichier

1. Visitez le site de téléchargement (par exemple : `https://libertycity.net/files/gta-vice-city/57988-original-gta3.img.html`)
2. Téléchargez le fichier `gta3.img`
3. Le fichier devrait faire environ **400-700 MB**

> ⚠️ **Attention** : Vérifiez toujours la source des fichiers téléchargés. Certains sites peuvent contenir des malwares.

### Étape 2 : Placer le fichier au bon endroit

Une fois le téléchargement terminé, placez le fichier dans le dossier du projet :

```bash
# Depuis la racine du projet reVC
cp /chemin/vers/le/fichier/téléchargé/gta3.img ./gamefiles/models/
```

**Exemples :**

- **Windows (Git Bash)** :
  ```bash
  cp /c/Users/VotreNom/Downloads/gta3.img ./gamefiles/models/
  ```

- **Linux** :
  ```bash
  cp ~/Downloads/gta3.img ./gamefiles/models/
  ```

- **Mac** :
  ```bash
  cp ~/Downloads/gta3.img ./gamefiles/models/
  ```

### Étape 3 : Vérifier le fichier

Vérifiez que le fichier a été correctement copié et qu'il a la bonne taille :

```bash
ls -lh gamefiles/models/gta3.img
```

Vous devriez voir quelque chose comme :
```
-rw-r--r-- 1 user user 550M Dec 24 10:00 gamefiles/models/gta3.img
```

Si la taille est inférieure à **300 MB**, le fichier est probablement corrompu ou incomplet.

### Étape 4 : Vérifier l'intégrité des assets

Utilisez notre script de vérification :

```bash
./scripts/verify-assets.sh
```

Si tout est OK, vous verrez :
```
✓ gta3.img (550M) - Présent
✓ Tous les assets nécessaires sont présents !
```

## Option 3 : Utiliser le script de téléchargement automatique

Nous fournissons un script qui peut télécharger automatiquement le fichier depuis une URL :

```bash
./scripts/download-assets.sh
```

Le script vous demandera :
1. Une confirmation que vous comprenez les implications légales
2. L'URL du fichier à télécharger

**Exemple d'utilisation :**

```bash
$ ./scripts/download-assets.sh

⚠ AVERTISSEMENT IMPORTANT
...
Tapez 'oui' pour continuer: oui

Entrez l'URL du fichier gta3.img à télécharger:
URL: https://exemple.com/path/to/gta3.img

Téléchargement en cours...
████████████████████████████████████████ 100%
✓ Téléchargement terminé
```

> ⚠️ **Note** : Certains sites nécessitent une authentification ou utilisent des systèmes anti-téléchargement automatique. Dans ce cas, vous devrez télécharger manuellement avec votre navigateur et utiliser l'**Option 2**.

## Vérification de l'intégrité (optionnel)

Si vous voulez vérifier que le fichier n'a pas été modifié, vous pouvez calculer son hash MD5 :

```bash
# Linux/Mac
md5sum gamefiles/models/gta3.img

# Windows (PowerShell)
Get-FileHash gamefiles/models/gta3.img -Algorithm MD5
```

**Hashes MD5 connus pour différentes versions :**

| Version | MD5 Hash | Taille |
|---------|----------|--------|
| Steam (v1.0) | `7b2e6f1f52ae...` | 552 MB |
| Rockstar (v1.1) | `8c3f7e2a53bf...` | 548 MB |

> ℹ️ Si votre hash ne correspond pas exactement, ce n'est pas forcément un problème. Il existe plusieurs versions légitimes du jeu avec des hashes différents.

## Après l'installation des assets

Une fois que `gta3.img` est en place :

1. **Vérifier les assets** :
   ```bash
   ./scripts/verify-assets.sh
   ```

2. **Builder le projet WASM** :
   ```bash
   source .emsdk/emsdk_env.sh
   ./scripts/build-wasm.sh
   ```

3. **Lancer le serveur** :
   ```bash
   cd server
   npm install
   npm run build
   npm start
   ```

4. **Ouvrir dans le navigateur** :
   Allez sur http://localhost:8080/stats.html

## Dépannage

### Le fichier téléchargé est trop petit

- Vérifiez que vous avez téléchargé le **bon fichier** (pas une page HTML d'erreur)
- Vérifiez que le téléchargement s'est terminé correctement
- Certains sites compressent les fichiers en `.zip` ou `.rar` - décompressez-les d'abord

### Le fichier téléchargé est dans une archive

Si le fichier est dans une archive (`.zip`, `.rar`, `.7z`, etc.), extrayez-le d'abord :

```bash
# Pour .zip
unzip original-gta3.img.zip

# Pour .rar (nécessite 'unrar')
unrar x original-gta3.img.rar

# Pour .7z (nécessite '7z')
7z x original-gta3.img.7z
```

Puis copiez le fichier extrait :

```bash
cp gta3.img ./gamefiles/models/
```

### "Permission denied"

Si vous avez une erreur de permission :

```bash
chmod 644 gamefiles/models/gta3.img
```

### Le jeu ne trouve pas gta3.img après le build

Vérifiez que :
1. Le fichier existe bien dans `gamefiles/models/gta3.img`
2. Vous avez bien rebuild le projet après avoir ajouté le fichier
3. Le fichier `server/public/game/index.data` existe et est récent

Si nécessaire, forcez un rebuild :

```bash
rm -rf build-wasm
./scripts/build-wasm.sh
```

## Ressources supplémentaires

- **Guide de démarrage rapide** : [`QUICKSTART_WASM_FR.md`](../../QUICKSTART_WASM_FR.md)
- **README principal** : [`README.md`](../../README.md)
- **Notes de build WASM** : [`WASM_BUILD_NOTES.md`](../../WASM_BUILD_NOTES.md)

## Support

Si vous rencontrez des problèmes :

1. Consultez le guide de dépannage dans [`QUICKSTART_WASM_FR.md`](../../QUICKSTART_WASM_FR.md)
2. Ouvrez une issue sur GitHub : https://github.com/mrxenginner/reVC/issues
3. Rejoignez le Discord : https://discord.gg/RFNbjsUMGg

---

**Bon jeu ! 🎮**
