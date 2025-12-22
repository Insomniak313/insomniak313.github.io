## Multijoueur (LAN natif + WASM/WebSocket)

Ce dépôt contient une implémentation **minimaliste** du multijoueur :
- **Build natif (Windows/Linux/macOS/…):** transport **UDP** (LAN) en modèle **host/client**
- **Build WASM (navigateur):** transport **WebSocket** via `server/` (HTTP + WS)

L’objectif est d’avoir un socle simple : synchronisation **position + heading**, création des joueurs distants, et lancement depuis le **menu principal**.

---

### Lancer une partie depuis le menu

Depuis le **menu initial** :
- **Host** (natif uniquement) : **Héberger**
- **Client** : **Rejoindre**

Notes :
- En **WASM**, “Rejoindre” utilise par défaut `ws(s)://<host>/ws` (même origine que la page).
- En **natif**, “Rejoindre” se connecte à `127.0.0.1:7777` si aucun paramètre n’est fourni.

---

### Build natif (UDP LAN)

#### Host

Lance un hôte UDP sur le port 7777 (par défaut) :

```bash
./reVC --host --port=7777
```

#### Client

Lance un client UDP vers un hôte LAN :

```bash
./reVC --connect=192.168.1.10 --port=7777
```

---

### Build WASM (WebSocket)

Le serveur est dans `server/` (HTTP + WebSocket). Il sert :
- les assets WASM (static)
- le WS `/ws` (multijoueur navigateur)

#### Serveur + page stats

Depuis `server/` :

```bash
npm install
npm run build
npm run start
```

Par défaut :
- `http://localhost:8080/stats.html` : **statistiques + lancement**
- `GET /healthz` : métriques serveur
- `WS /ws` : websocket multijoueur

Place ton build WASM du jeu dans :
- `server/public/game/` (ex: `index.html`, `.js`, `.wasm`, assets…)

Puis ouvre :
- `http://localhost:8080/stats.html`

---

### Protocole réseau (binaire, big-endian)

Header :
- `u32 magic` = `MPVC`
- `u16 size`
- `u8 version` = `1`
- `u8 type`
- `u32 seq`
- `u32 senderId`

Messages :
- **WELCOME (2)** :
  - **UDP** : `u32 token, u32 assignedId`
  - **WebSocket** : `u32 assignedId`
- **STATE (3)** :
  - **UDP** : `u32 token, f32 x, f32 y, f32 z, f32 heading`
  - **WebSocket** : `f32 x, f32 y, f32 z, f32 heading`
- **SNAPSHOT (4)** : `u32 count` puis `count * (u32 id, f32 x, f32 y, f32 z, f32 heading)`
- **LEAVE (5)** : `u32 leftId` (WebSocket)

---

### Scalabilité (ordre d’idée)

Le serveur WebSocket inclut déjà un **interest management** (grille 2D + voisinage 3x3) pour réduire le fan-out.

Pour viser “plusieurs dizaines de milliers” :
- sharding/instances (par zone/monde/région)
- gateways WS stateless + rate-limit
- CDN pour servir le WASM
- snapshots delta/quantization + tick adaptatif

