export interface GridKey {
  cx: number;
  cy: number;
}

export function worldToCell(value: number, cellSize: number): number {
  return Math.floor(value / cellSize);
}

export function cellKey(cx: number, cy: number): string {
  return `${cx},${cy}`;
}

export function neighborKeys(cx: number, cy: number): string[] {
  const out: string[] = [];
  for (let dy = -1; dy <= 1; dy++) {
    for (let dx = -1; dx <= 1; dx++) {
      out.push(cellKey(cx + dx, cy + dy));
    }
  }
  return out;
}

