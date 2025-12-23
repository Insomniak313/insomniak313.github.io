import http from "node:http";
import path from "node:path";
import crypto from "node:crypto";

import express from "express";
import { WebSocketServer } from "ws";

import {
  MsgType,
  NET_MAGIC,
  NET_VERSION,
  PlayerState,
  ServerConfig,
  makeHeaderByteLength,
  readF32BE,
  readU16BE,
  readU32BE,
  readU8,
  writeF32BE,
  writeU16BE,
  writeU32BE,
  writeU8,
} from "./protocol.js";
import { cellKey, neighborKeys, worldToCell } from "./spatialGrid.js";

type Ws = import("ws").WebSocket;

const defaultConfig: ServerConfig = {
  httpPort: Number(process.env.PORT ?? "8080"),
  wsPath: process.env.WS_PATH ?? "/ws",
  staticDir: process.env.STATIC_DIR ?? path.resolve(process.cwd(), "public"),
  tickMs: Number(process.env.TICK_MS ?? "50"),
  cellSize: Number(process.env.CELL_SIZE ?? "100"),
  maxSnapshotPlayers: Number(process.env.MAX_SNAPSHOT_PLAYERS ?? "512"),
  maxBufferedAmount: Number(process.env.MAX_BUFFERED_AMOUNT ?? `${2 * 1024 * 1024}`),
};

const headerLen = makeHeaderByteLength();

function nowMs(): number {
  return Date.now();
}

function toU32(n: number): number {
  return n >>> 0;
}

function parsePacket(data: ArrayBuffer): { type: number; senderId: number; payloadOffset: number; payloadEnd: number } | null {
  if (data.byteLength < headerLen) return null;
  const view = new DataView(data);
  let offset = 0;

  const magic = view.getUint32(offset, false);
  offset += 4;
  if (magic !== NET_MAGIC) return null;

  const size = view.getUint16(offset, false);
  offset += 2;
  if (size < headerLen || size > data.byteLength) return null;

  const version = view.getUint8(offset);
  offset += 1;
  if (version !== NET_VERSION) return null;

  const type = view.getUint8(offset);
  offset += 1;

  // seq (unused)
  offset += 4;

  const senderId = view.getUint32(offset, false);
  offset += 4;

  return { type, senderId, payloadOffset: offset, payloadEnd: size };
}

function buildWelcome(seq: number, assignedId: number): ArrayBuffer {
  const size = headerLen + 4;
  const buf = new ArrayBuffer(size);
  const view = new DataView(buf);
  let o = 0;
  o = writeU32BE(view, o, NET_MAGIC);
  o = writeU16BE(view, o, size);
  o = writeU8(view, o, NET_VERSION);
  o = writeU8(view, o, MsgType.Welcome);
  o = writeU32BE(view, o, seq);
  o = writeU32BE(view, o, 0);
  o = writeU32BE(view, o, assignedId);
  return buf;
}

function buildLeave(seq: number, leftId: number): ArrayBuffer {
  const size = headerLen + 4;
  const buf = new ArrayBuffer(size);
  const view = new DataView(buf);
  let o = 0;
  o = writeU32BE(view, o, NET_MAGIC);
  o = writeU16BE(view, o, size);
  o = writeU8(view, o, NET_VERSION);
  o = writeU8(view, o, MsgType.Leave);
  o = writeU32BE(view, o, seq);
  o = writeU32BE(view, o, 0);
  o = writeU32BE(view, o, leftId);
  return buf;
}

function buildSnapshot(seq: number, receiverId: number, players: PlayerState[]): ArrayBuffer {
  const entryLen = 4 + 4 + 4 + 4 + 4; // id + x y z heading
  const count = players.length;
  const size = headerLen + 4 + count * entryLen;
  const buf = new ArrayBuffer(size);
  const view = new DataView(buf);
  let o = 0;
  o = writeU32BE(view, o, NET_MAGIC);
  o = writeU16BE(view, o, size);
  o = writeU8(view, o, NET_VERSION);
  o = writeU8(view, o, MsgType.Snapshot);
  o = writeU32BE(view, o, seq);
  o = writeU32BE(view, o, 0); // server
  o = writeU32BE(view, o, count);

  for (const p of players) {
    o = writeU32BE(view, o, p.id);
    o = writeF32BE(view, o, p.x);
    o = writeF32BE(view, o, p.y);
    o = writeF32BE(view, o, p.z);
    o = writeF32BE(view, o, p.heading);
  }

  // sanity
  if (o !== size) throw new Error(`snapshot size mismatch: wrote=${o} size=${size} receiver=${receiverId}`);
  return buf;
}

interface Connection {
  ws: Ws;
  id: number;
  lastSeenMs: number;
  x: number;
  y: number;
  z: number;
  heading: number;
  cell: string;
}

const connectionsById = new Map<number, Connection>();
const idByWs = new WeakMap<Ws, number>();
const grid = new Map<string, Set<number>>();

let nextId = 1;
let seq = 1;

function allocId(): number {
  // 32-bit id space, avoid 0.
  const id = nextId++;
  if (nextId >= 0x7fffffff) nextId = 1;
  return id;
}

function ensureGridCell(cell: string): Set<number> {
  const existing = grid.get(cell);
  if (existing) return existing;
  const created = new Set<number>();
  grid.set(cell, created);
  return created;
}

function moveToCell(id: number, fromCell: string, toCell: string): void {
  if (fromCell === toCell) return;
  const fromSet = grid.get(fromCell);
  if (fromSet) {
    fromSet.delete(id);
    if (fromSet.size === 0) grid.delete(fromCell);
  }
  ensureGridCell(toCell).add(id);
}

function wsSendBinary(ws: Ws, buf: ArrayBuffer, maxBufferedAmount: number): void {
  if (ws.readyState !== ws.OPEN) return;
  if (ws.bufferedAmount > maxBufferedAmount) return;
  ws.send(buf, { binary: true });
}

function pickVisiblePlayers(selfId: number, cell: string, maxPlayers: number): PlayerState[] {
  const [cxStr, cyStr] = cell.split(",");
  const cx = Number(cxStr);
  const cy = Number(cyStr);
  const keys = neighborKeys(cx, cy);

  const players: PlayerState[] = [];
  for (const key of keys) {
    const set = grid.get(key);
    if (!set) continue;

    for (const id of set) {
      if (id === selfId) continue;
      const c = connectionsById.get(id);
      if (!c) continue;
      players.push({
        id: c.id,
        x: c.x,
        y: c.y,
        z: c.z,
        heading: c.heading,
        lastSeenMs: c.lastSeenMs,
      });
      if (players.length >= maxPlayers) return players;
    }
  }

  return players;
}

function handleBinaryMessage(ws: Ws, data: ArrayBuffer, cfg: ServerConfig): void {
  const parsed = parsePacket(data);
  if (!parsed) return;

  const id = idByWs.get(ws);
  if (!id) return;

  if (parsed.type === MsgType.State) {
    // payload: x y z heading (f32 x4)
    const view = new DataView(data);
    let offset = parsed.payloadOffset;
    const rx = readF32BE(view, offset);
    offset = rx.offset;
    const ry = readF32BE(view, offset);
    offset = ry.offset;
    const rz = readF32BE(view, offset);
    offset = rz.offset;
    const rh = readF32BE(view, offset);
    offset = rh.offset;

    const c = connectionsById.get(id);
    if (!c) return;

    c.x = rx.value;
    c.y = ry.value;
    c.z = rz.value;
    c.heading = rh.value;
    c.lastSeenMs = nowMs();

    const newCell = cellKey(worldToCell(c.x, cfg.cellSize), worldToCell(c.y, cfg.cellSize));
    if (newCell !== c.cell) {
      moveToCell(id, c.cell, newCell);
      c.cell = newCell;
    }
  }
}

function onDisconnect(id: number, cfg: ServerConfig): void {
  const c = connectionsById.get(id);
  if (!c) return;

  const cellSet = grid.get(c.cell);
  if (cellSet) {
    cellSet.delete(id);
    if (cellSet.size === 0) grid.delete(c.cell);
  }

  connectionsById.delete(id);

  // Notifier "leave" aux voisins proches (best-effort).
  const [cxStr, cyStr] = c.cell.split(",");
  const cx = Number(cxStr);
  const cy = Number(cyStr);
  const keys = neighborKeys(cx, cy);
  const leaveBuf = buildLeave(seq++, id);
  for (const key of keys) {
    const set = grid.get(key);
    if (!set) continue;
    for (const otherId of set) {
      const other = connectionsById.get(otherId);
      if (!other) continue;
      wsSendBinary(other.ws, leaveBuf, cfg.maxBufferedAmount);
    }
  }
}

function startServer(cfg: ServerConfig): void {
  const app = express();
  app.disable("x-powered-by");

  // WASM (Emscripten) est plus fiable avec cross-origin isolation + bons MIME types.
  // - COOP/COEP: requis pour SharedArrayBuffer (threads), et sans impact pour un build single-thread.
  // - Content-Type .wasm: permet WebAssembly.instantiateStreaming (perf + compat).
  app.use((_req, res, next) => {
    res.setHeader("Cross-Origin-Opener-Policy", "same-origin");
    res.setHeader("Cross-Origin-Embedder-Policy", "require-corp");
    next();
  });

  app.get("/healthz", (_req, res) => {
    res.json({
      ok: true,
      nowMs: nowMs(),
      players: connectionsById.size,
      cells: grid.size,
      tickMs: cfg.tickMs,
      cellSize: cfg.cellSize,
    });
  });

  app.use(
    "/",
    express.static(cfg.staticDir, {
      fallthrough: true,
      maxAge: "1h",
      etag: true,
      immutable: false,
      setHeaders: (res, filePath) => {
        // Certains environnements ne servent pas .wasm correctement par défaut.
        if (filePath.endsWith(".wasm")) {
          res.setHeader("Content-Type", "application/wasm");
        }

        // Fichier packager Emscripten: binaire opaque, mais mieux vaut être explicite.
        if (filePath.endsWith(".data")) {
          res.setHeader("Content-Type", "application/octet-stream");
        }
      },
    })
  );

  const server = http.createServer(app);
  const wss = new WebSocketServer({ server, path: cfg.wsPath, perMessageDeflate: false });

  wss.on("connection", (ws) => {
    // Assigner un id et initialiser à (0,0,0)
    const id = allocId();
    idByWs.set(ws, id);

    const initialCell = cellKey(0, 0);
    const c: Connection = {
      ws,
      id,
      lastSeenMs: nowMs(),
      x: 0,
      y: 0,
      z: 0,
      heading: 0,
      cell: initialCell,
    };
    connectionsById.set(id, c);
    ensureGridCell(initialCell).add(id);

    // Welcome binaire
    wsSendBinary(ws, buildWelcome(seq++, id), cfg.maxBufferedAmount);

    ws.on("message", (msg) => {
      if (typeof msg === "string") return;
      // ws lib donne Buffer | ArrayBuffer | Buffer[]
      const data = (() => {
        if (msg instanceof ArrayBuffer) return msg;
        if (Array.isArray(msg)) {
          // Rare: fragments array — on concat en un seul Buffer
          const joined = Buffer.concat(msg);
          return joined.buffer.slice(joined.byteOffset, joined.byteOffset + joined.byteLength);
        }
        // Buffer / TypedArray
        const view = msg as ArrayBufferView;
        return view.buffer.slice(view.byteOffset, view.byteOffset + view.byteLength);
      })();
      handleBinaryMessage(ws, data as ArrayBuffer, cfg);
    });

    ws.on("close", () => {
      onDisconnect(id, cfg);
    });
  });

  // Tick snapshots (interest management)
  setInterval(() => {
    const t = nowMs();
    for (const c of connectionsById.values()) {
      // Anti-surcharge: si le client est en backpressure, on skip ce tick
      if (c.ws.bufferedAmount > cfg.maxBufferedAmount) continue;

      const visible = pickVisiblePlayers(c.id, c.cell, cfg.maxSnapshotPlayers);
      const snapshot = buildSnapshot(seq++, c.id, visible);
      wsSendBinary(c.ws, snapshot, cfg.maxBufferedAmount);

      // Option: timeouts (utile derrière proxies)
      if (t - c.lastSeenMs > 60_000) {
        try {
          c.ws.close();
        } catch {
          // ignore
        }
      }
    }
  }, cfg.tickMs);

  server.listen(cfg.httpPort, () => {
    // eslint-disable-next-line no-console
    console.log(
      JSON.stringify({
        msg: "reVC WASM server listening",
        httpPort: cfg.httpPort,
        wsPath: cfg.wsPath,
        staticDir: cfg.staticDir,
        tickMs: cfg.tickMs,
        cellSize: cfg.cellSize,
      })
    );
  });
}

// Petit “jitter” au démarrage pour éviter thundering herd en déploiements groupés
const jitter = crypto.randomInt(0, 50);
setTimeout(() => startServer(defaultConfig), jitter);

