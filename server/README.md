## Serveur Web (WASM) + WebSocket (massive-friendly)

Ce dossier ajoute un serveur **HTTP** (pour servir le build WASM) + un serveur **WebSocket** (pour le multijoueur compatible navigateur).

### Démarrage local

Depuis `server/` :

```bash
npm install
npm run build
npm run start
```

Par défaut :
- **HTTP**: `:8080`
- **WebSocket**: `/ws`
- **Static**: `server/public/` (copie ici ton build wasm : `index.html`, `.js`, `.wasm`, assets, etc.)

Pages utiles :
- `GET /healthz` : métriques serveur (joueurs, cellules, tick, etc.)
- `GET /stats.html` : page “statistiques + lancement WASM” (le jeu est attendu par défaut dans `/game/`)

Variables d’environnement utiles :
- `PORT` (défaut `8080`)
- `WS_PATH` (défaut `/ws`)
- `STATIC_DIR` (défaut `./public`)
- `TICK_MS` (défaut `50`)
- `CELL_SIZE` (défaut `100`)
- `MAX_SNAPSHOT_PLAYERS` (défaut `512`)
- `MAX_BUFFERED_AMOUNT` (défaut `2097152`)

### Protocole réseau (binaire)

Header (big-endian) :
- `u32 magic` = `MPVC`
- `u16 size` = taille totale du message
- `u8 version` = `1`
- `u8 type`
- `u32 seq`
- `u32 senderId`

Messages :
- **WELCOME (2)** : payload `u32 assignedId`
- **STATE (3)** : payload `f32 x, f32 y, f32 z, f32 heading`
- **SNAPSHOT (4)** : payload `u32 count` puis `count * (u32 id, f32 x,y,z, f32 heading)`
- **LEAVE (5)** : payload `u32 leftId`

### “Plusieurs dizaines de milliers” de joueurs

Point clé : **un seul serveur ne tient pas 50k joueurs dans un même espace** si tu diffuses l’état à tout le monde.

Ce serveur inclut déjà un **interest management** simple :
- grille spatiale 2D (cellules `CELL_SIZE`)
- snapshots envoyés uniquement aux joueurs dans la cellule + 8 voisines

Pour vraiment scaler :
- **CDN** pour servir le WASM (ne pas servir les assets depuis le serveur temps réel)
- **WebSocket gateways** stateless (TLS termination + rate-limit + auth)
- **matchmaker** (assignation shard/instance)
- **sharding** (par région/monde/zone) + **migration** entre shards
- **delta compression** + quantization (positions int16/int32) + snapshot rate adaptative
- **persistence** (DB) découplée du realtime

Ce repo contient maintenant une base “mono-shard” pour dev; l’étape suivante est de brancher le client WASM sur ce protocole WebSocket (au lieu d’UDP).

