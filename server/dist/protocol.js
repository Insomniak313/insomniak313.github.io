export const NET_MAGIC = 0x4d505643; // 'MPVC'
export const NET_VERSION = 1;
export function writeU32BE(view, offset, value) {
    view.setUint32(offset, value >>> 0, false);
    return offset + 4;
}
export function writeU16BE(view, offset, value) {
    view.setUint16(offset, value & 0xffff, false);
    return offset + 2;
}
export function writeU8(view, offset, value) {
    view.setUint8(offset, value & 0xff);
    return offset + 1;
}
export function writeF32BE(view, offset, value) {
    view.setFloat32(offset, value, false);
    return offset + 4;
}
export function readU32BE(view, offset) {
    return { value: view.getUint32(offset, false), offset: offset + 4 };
}
export function readU16BE(view, offset) {
    return { value: view.getUint16(offset, false), offset: offset + 2 };
}
export function readU8(view, offset) {
    return { value: view.getUint8(offset), offset: offset + 1 };
}
export function readF32BE(view, offset) {
    return { value: view.getFloat32(offset, false), offset: offset + 4 };
}
export function makeHeaderByteLength() {
    // magic u32 + size u16 + version u8 + type u8 + seq u32 + senderId u32
    return 4 + 2 + 1 + 1 + 4 + 4;
}
//# sourceMappingURL=protocol.js.map