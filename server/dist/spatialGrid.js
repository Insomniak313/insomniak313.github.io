export function worldToCell(value, cellSize) {
    return Math.floor(value / cellSize);
}
export function cellKey(cx, cy) {
    return `${cx},${cy}`;
}
export function neighborKeys(cx, cy) {
    const out = [];
    for (let dy = -1; dy <= 1; dy++) {
        for (let dx = -1; dx <= 1; dx++) {
            out.push(cellKey(cx + dx, cy + dy));
        }
    }
    return out;
}
//# sourceMappingURL=spatialGrid.js.map