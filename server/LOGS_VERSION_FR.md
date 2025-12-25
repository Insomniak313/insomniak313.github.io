# 📊 Logs de diagnostic pour la version du protocole réseau

## ✅ Modifications apportées

J'ai ajouté des logs complets pour diagnostiquer les problèmes liés à la version du protocole réseau (NET_VERSION).

### 🔍 Logs ajoutés

#### 1. **Erreur critique : Version incompatible** (console.error)

Lorsqu'un paquet est reçu avec une version différente de `NET_VERSION`, un log d'erreur détaillé est maintenant affiché :

```json
{
  "msg": "VERSION DU PROTOCOLE INCOMPATIBLE - PAQUET REJETÉ",
  "receivedVersion": 2,
  "expectedVersion": 1,
  "severity": "CRITICAL",
  "hint": "Le client utilise une version différente du protocole réseau"
}
```

#### 2. **Logs d'avertissement**

- **Paquet trop petit** :
  ```json
  {
    "msg": "Paquet trop petit ignoré",
    "receivedBytes": 10,
    "expectedMinBytes": 16
  }
  ```

- **Magic number invalide** :
  ```json
  {
    "msg": "Magic number invalide",
    "receivedMagic": "0x12345678",
    "expectedMagic": "0x4d505643"
  }
  ```

- **Taille de paquet invalide** :
  ```json
  {
    "msg": "Taille de paquet invalide",
    "receivedSize": 100,
    "dataByteLength": 50,
    "minExpected": 16
  }
  ```

#### 3. **Logs de connexion/déconnexion**

- **Nouvelle connexion** :
  ```json
  {
    "msg": "Nouvelle connexion établie",
    "playerId": 1,
    "protocolVersion": 1,
    "totalPlayers": 1
  }
  ```

- **Déconnexion** :
  ```json
  {
    "msg": "Joueur déconnecté",
    "playerId": 1,
    "lastPosition": { "x": 100.5, "y": 200.3, "z": 10.0 },
    "cell": "1,2",
    "remainingPlayers": 0
  }
  ```

#### 4. **Logs de traçabilité**

- **Changement de cellule** :
  ```json
  {
    "msg": "Joueur a changé de cellule",
    "playerId": 1,
    "fromCell": "0,0",
    "toCell": "1,1",
    "position": { "x": 150.5, "y": 150.3, "z": 10.0 }
  }
  ```

- **Message reçu avec succès** :
  ```json
  {
    "msg": "Message reçu avec succès",
    "playerId": 1,
    "messageType": 3,
    "dataSize": 32
  }
  ```

## 🚀 Comment tester

### 1. Lancer le serveur

```bash
cd /workspace/server
npm run build
npm start
```

### 2. Observer les logs

Les logs apparaîtront dans la console au format JSON. Exemples de cas :

#### ✅ Connexion réussie (version correcte)

```
{"msg":"Nouvelle connexion établie","playerId":1,"protocolVersion":1,"totalPlayers":1}
```

#### ❌ Connexion échouée (version incompatible)

```
{"msg":"VERSION DU PROTOCOLE INCOMPATIBLE - PAQUET REJETÉ","receivedVersion":2,"expectedVersion":1,"severity":"CRITICAL","hint":"Le client utilise une version différente du protocole réseau"}
```

### 3. Filtrer les logs

Vous pouvez filtrer les logs par niveau :

```bash
# Tous les logs
npm start

# Uniquement les erreurs critiques
npm start 2>&1 | grep "CRITICAL"

# Logs de version
npm start 2>&1 | grep "VERSION"

# Logs de connexion
npm start 2>&1 | grep "connexion"
```

## 🔧 Diagnostic des problèmes

### Problème : Les clients ne peuvent pas se connecter

**Vérifiez les logs pour :**

1. **Erreur "VERSION DU PROTOCOLE INCOMPATIBLE"**
   - **Cause** : Le client utilise une version différente du protocole
   - **Solution** : Mettez à jour le client ou le serveur pour utiliser la même version

2. **Erreur "Magic number invalide"**
   - **Cause** : Le paquet n'est pas au bon format ou corrompu
   - **Solution** : Vérifiez que le client envoie bien des paquets au format binaire attendu

3. **Erreur "Paquet trop petit"**
   - **Cause** : Le paquet reçu est incomplet
   - **Solution** : Vérifiez la connexion réseau et la transmission des données

### Problème : Certains clients se déconnectent de manière inattendue

**Vérifiez les logs pour :**

- Logs de déconnexion avec la dernière position du joueur
- Timeout (actuellement fixé à 60 secondes sans activité)

## 📝 Format des logs

Tous les logs sont au **format JSON** pour faciliter :

- Le parsing automatique
- L'intégration avec des outils de monitoring (Datadog, Elastic, etc.)
- La recherche et le filtrage

### Niveaux de logs

- `console.log` : Informations normales (connexions, messages)
- `console.warn` : Avertissements (paquets invalides, joueurs inexistants)
- `console.error` : Erreurs critiques (version incompatible)

## 🎯 Prochaines étapes

Si vous souhaitez améliorer encore le système de logs :

1. **Ajouter un système de log rotatif** avec Winston ou Pino
2. **Envoyer les logs vers un service externe** (Datadog, Elastic, etc.)
3. **Ajouter des métriques** (nombre de paquets rejetés, temps de latence, etc.)
4. **Créer un dashboard** pour visualiser les logs en temps réel

## ✨ Résumé

- ✅ Logs détaillés pour la vérification de version
- ✅ Logs pour toutes les erreurs de parsing de paquets
- ✅ Logs de connexion/déconnexion avec détails
- ✅ Logs de traçabilité pour les mouvements
- ✅ Format JSON structuré et facile à parser
- ✅ Compilation réussie sans erreurs

**Tous les logs sont maintenant actifs !** Si la version ne fonctionne pas, vous verrez immédiatement dans la console pourquoi.
