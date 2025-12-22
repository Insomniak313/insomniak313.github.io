export const NET_MAGIC = 0x4d505643; // 'MPVC'
export const NET_VERSION = 1;

export const enum MsgType {
  Hello = 1,
  Welcome = 2,
  State = 3,
  Snapshot = 4,
  Leave = 5,
}

export interface PlayerState {
  id: number;
  x: number;
  y: number;
  z: number;
  heading: number;
  lastSeenMs: number;
}

export interface ServerConfig {
  httpPort: number;
  wsPath: string;
  staticDir: string;
  tickMs: number;
  cellSize: number;
  maxSnapshotPlayers: number;
  maxBufferedAmount: number;
}

export function writeU32BE(view: DataView, offset: number, value: number): number {
  view.setUint32(offset, value >>> 0, false);
  return offset + 4;
}

export function writeU16BE(view: DataView, offset: number, value: number): number {
  view.setUint16(offset, value & 0xffff, false);
  return offset + 2;
}

export function writeU8(view: DataView, offset: number, value: number): number {
  view.setUint8(offset, value & 0xff);
  return offset + 1;
}

export function writeF32BE(view: DataView, offset: number, value: number): number {
  view.setFloat32(offset, value, false);
  return offset + 4;
}

export function readU32BE(view: DataView, offset: number): { value: number; offset: number } {
  return { value: view.getUint32(offset, false), offset: offset + 4 };
}

export function readU16BE(view: DataView, offset: number): { value: number; offset: number } {
  return { value: view.getUint16(offset, false), offset: offset + 2 };
}

export function readU8(view: DataView, offset: number): { value: number; offset: number } {
  return { value: view.getUint8(offset), offset: offset + 1 };
}

export function readF32BE(view: DataView, offset: number): { value: number; offset: number } {
  return { value: view.getFloat32(offset, false), offset: offset + 4 };
}

export function makeHeaderByteLength(): number {
  // magic u32 + size u16 + version u8 + type u8 + seq u32 + senderId u32
  return 4 + 2 + 1 + 1 + 4 + 4;
}

