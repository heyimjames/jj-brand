/* The six magic colours as CURSORS. A block cursor draws the glyph beneath it
 * in the ground colour, so each one has to clear 4.5:1 against its ground —
 * which the magic six do untouched on Black and none of them do on Paper. */
import { readFileSync, writeFileSync } from "node:fs";
import { contrastRatio, maxSrgbChroma, oklchToHex, relativeLuminance, toOklch } from "/Users/james/Documents/Projects/jj-grid-studio/src/lib/grid/color";

const src = readFileSync("/Users/james/Documents/Projects/jj-grid-studio/src/lib/brand.ts", "utf8");
const swatches = [...src.matchAll(/\{\s*name:\s*"([^"]+)",\s*hex:\s*"(#[0-9a-f]{6})"\s*\}/g)].map((m) => [m[1], m[2]] as const);
const MAGIC = ["Coral", "Honey", "Emerald", "Sky", "Periwinkle", "Orchid"];
const magic = MAGIC.map((n) => { const s = swatches.find(([k]) => k === n); if (!s) throw new Error(n); return s; });

function relight(hex: string, ground: string, floor: number): string {
  if (contrastRatio(hex, ground) >= floor) return hex;
  const { L: L0, C: C0, H } = toOklch(hex);
  const step = relativeLuminance(ground) > 0.35 ? -0.004 : 0.004;
  for (let L = L0 + step; L > 0.04 && L < 0.99; L += step) {
    const C = Math.min(maxSrgbChroma(L, H), C0 < 0.04 ? C0 : Math.max(C0, 0.18));
    const cand = oklchToHex(L, C, H);
    if (contrastRatio(cand, ground) >= floor) return cand;
  }
  throw new Error(`${hex} cannot reach ${floor} on ${ground}`);
}

const out: Record<string, { name: string; hex: string; ratio: number }[]> = {};

/* THE REAL COLOURS, both grounds. James, 10 Sep: "full saturation, the real
 * colours". On Black the brand values already clear the 4.5:1 a block cursor
 * needs; on Paper they measure 1.4 to 2.4:1, so the cursor is faint there and a
 * glyph under it is hard to read. That is the trade, taken deliberately, and the
 * measured `light` set below stays available behind a flag. */
out.real = magic.map(([name, hex]) => ({
  name, hex,
  ratio: +Math.min(contrastRatio(hex, "#010101"), contrastRatio(hex, "#f9f9f6")).toFixed(2),
}));
console.log("real (worst of the two grounds)");
for (const c of out.real) console.log(`   ${c.name.padEnd(11)} ${c.hex}  ${c.ratio.toFixed(2)}:1`);
for (const [ground, key] of [["#010101", "dark"], ["#f9f9f6", "light"]] as const) {
  out[key] = magic.map(([name, hex]) => {
    const v = relight(hex, ground, 4.5);
    return { name, hex: v, ratio: +contrastRatio(v, ground).toFixed(2) };
  });
  console.log(key, "on", ground);
  for (const c of out[key]) console.log(`   ${c.name.padEnd(11)} ${c.hex}  ${c.ratio.toFixed(2)}:1`);
}
writeFileSync("out/cursors.json", JSON.stringify(out, null, 1));
