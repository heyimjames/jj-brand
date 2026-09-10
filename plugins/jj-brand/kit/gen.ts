/* ============================================================================
 * JACK & JILL — a Claude Code theme and a Terminal.app profile, derived.
 *
 * The brand hexes are read out of src/lib/brand.ts rather than restated, and
 * every colour is measured with the studio's own contrastRatio, so this file
 * cannot claim a ratio the renderer will not deliver.
 *
 * TWO GROUNDS, ONE RULE, and the rule is the studio's own: the brand value is
 * kept EXACTLY whenever it clears its floor, and re-lighting is the fallback —
 * hue preserved, lightness derived (the `tierLighting` / `autoBaseColor` move).
 * On Black that fallback almost never fires: the magic six were lit for a dark
 * ground in the first place. On Paper it fires for nearly all of them, which
 * is the whole reason this file measures rather than assumes.
 * ========================================================================= */
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import {
  contrastRatio,
  maxSrgbChroma,
  oklchToHex,
  relativeLuminance,
  toOklch,
} from "/Users/james/Documents/Projects/jj-grid-studio/src/lib/grid/color";

const REPO = "/Users/james/Documents/Projects/jj-grid-studio";
const OUT = "/private/tmp/claude-501/-Users-james-Documents-Projects-jj-grid-studio/ac99f680-eb59-46fb-a709-2af4b84b1e47/scratchpad/jj/out";

/* ---------------------------------------------------------------- the brand */
/* Parsed, not transcribed: a change to brand.ts reaches the terminal on the
 * next run, and a typo here would be a colour the brand does not have. */
function brand(): Record<string, string> {
  const src = readFileSync(join(REPO, "src/lib/brand.ts"), "utf8");
  const out: Record<string, string> = {};
  for (const m of src.matchAll(/\{\s*name:\s*"([^"]+)",\s*hex:\s*"(#[0-9a-f]{6})"\s*\}/g)) {
    out[m[1]] = m[2];
  }
  return out;
}
const B = brand();
const need = (n: string) => {
  const v = B[n];
  if (!v) throw new Error(`brand.ts has no swatch named ${n}`);
  return v;
};

/* --------------------------------------------------------------- re-lighting
 * Walk lightness away from the ground until the floor is met, keeping the hue
 * exactly and holding chroma up so a darkened colour does not go muddy. The
 * FIRST passing step wins, so a re-lit colour is the closest to the brand's
 * own brightness that the floor allows. */
function relight(hex: string, ground: string, floor: number): string {
  if (contrastRatio(hex, ground) >= floor) return hex; /* brand, untouched */
  const { L: L0, C: C0, H } = toOklch(hex);
  const groundLight = relativeLuminance(ground) > 0.35;
  const step = groundLight ? -0.004 : 0.004;
  for (let L = L0 + step; L > 0.04 && L < 0.99; L += step) {
    /* A chroma floor keeps a darkened HUE from going muddy, but applied to a
     * near-neutral it invents one: Dove at C 0.02 came back as violet. Below
     * C 0.04 the hue angle is a lottery, so the floor stands down. */
    const C = Math.min(maxSrgbChroma(L, H), C0 < 0.04 ? C0 : Math.max(C0, 0.18));
    const cand = oklchToHex(L, C, H);
    if (contrastRatio(cand, ground) >= floor) return cand;
  }
  throw new Error(`cannot reach ${floor}:1 for ${hex} on ${ground}`);
}

/**
 * The dimmest colour that still clears a floor: walk out from the GROUND and
 * stop at the first passing step. Re-lighting an already-passing ink cannot do
 * this — it returns the ink untouched, which is how `subtle` first came back
 * identical to `inactive` on both grounds and stopped being subtle.
 */
function dimAt(ground: string, target: number, hue: number, chroma = 0.014): string {
  const g = toOklch(ground);
  const light = relativeLuminance(ground) > 0.35;
  const step = light ? -0.004 : 0.004;
  for (let L = g.L + step; L > 0.04 && L < 0.99; L += step) {
    const cand = oklchToHex(L, Math.min(maxSrgbChroma(L, hue), chroma), hue);
    if (contrastRatio(cand, ground) >= target) return cand;
  }
  throw new Error(`cannot reach ${target}:1 from ${ground}`);
}

/** A near-ground surface: the ground's own hue, stepped in lightness, so a
 * message block or a selection reads as elevation rather than as a colour. */
function surface(ground: string, dL: number, tintHue?: number, tintC = 0.02): string {
  const g = toOklch(ground);
  const light = relativeLuminance(ground) > 0.35;
  const L = Math.min(0.98, Math.max(0.06, g.L + (light ? -dL : dL)));
  const H = tintHue ?? g.H;
  const C = Math.min(maxSrgbChroma(L, H), tintHue === undefined ? g.C : tintC);
  return oklchToHex(L, C, H);
}

/* ------------------------------------------------------------- the 16 slots */
type Slots = Record<string, string>;
const SLOT_NAMES = [
  "black", "red", "green", "yellow", "blue", "magenta", "cyan", "white",
  "blackBright", "redBright", "greenBright", "yellowBright",
  "blueBright", "magentaBright", "cyanBright", "whiteBright",
] as const;

/* On Black the palette is the brand, near enough literally: 14 of 16 slots are
 * brand hexes. The two exceptions are the pale ends of Orchid and Sky, which
 * the palette simply does not carry a light tint of. */
function darkSlots(): Slots {
  const lighten = (hex: string, L: number) => {
    const { C, H } = toOklch(hex);
    return oklchToHex(L, Math.min(maxSrgbChroma(L, H), C * 0.55), H);
  };
  return {
    black: need("Black"),
    red: need("Flame"),
    green: need("Emerald"),
    yellow: need("Honey"),
    blue: need("Periwinkle"),
    magenta: need("Orchid"),
    cyan: need("Sky"),
    white: need("Clay"),
    blackBright: need("Dove"),
    redBright: need("Coral"),
    greenBright: need("Mint"),
    yellowBright: need("Butter"),
    blueBright: need("Ice"),
    magentaBright: lighten(need("Orchid"), 0.88),
    cyanBright: lighten(need("Sky"), 0.88),
    whiteBright: need("White"),
  };
}

/* On Paper every hue has to be re-lit, and the BRIGHT tier is the DARKER one —
 * on a light ground "stronger" means more ink, not more light. Normal tier
 * lands on the AA text floor (4.5), bright on AAA (7), so every colour slot on
 * this palette clears 4.5 and the two tiers are still told apart. */
function lightSlots(): Slots {
  const g = need("Paper");
  const aa = (n: string) => relight(need(n), g, 4.5);
  const aaa = (n: string) => relight(need(n), g, 7);
  return {
    black: need("Black"),
    red: aa("Flame"),
    green: aa("Leaf"),
    yellow: aa("Honey"),
    blue: aa("Cobalt"),
    magenta: aa("Orchid"),
    cyan: aa("Sky"),
    white: need("Clay"),
    blackBright: relight(need("Dove"), g, 4.5),
    redBright: aaa("Coral"),
    greenBright: aaa("Emerald"),
    yellowBright: aaa("Butter"),
    blueBright: aaa("Periwinkle"),
    magentaBright: aaa("Orchid"),
    cyanBright: aaa("Sky"),
    whiteBright: need("White"),
  };
}

/* ------------------------------------------------- roles → slots and surfaces
 * `ansi:<slot>` is a REFERENCE, not a colour: Terminal.app renders its own
 * palette exactly, where a 24-bit value would be approximated into its 256
 * cube. So every accent role points at a slot, and only the surfaces — large
 * areas where a shade of a shade is imperceptible — are written as rgb(). */
const A = (s: (typeof SLOT_NAMES)[number]) => `ansi:${s}`;

interface Ground {
  name: string;
  slug: string;
  base: "dark-ansi" | "light-ansi";
  ground: string;
  slots: Slots;
}

function overrides(G: Ground): { theme: Record<string, string>; audit: Audit[] } {
  const s = G.slots;
  const dark = G.base === "dark-ansi";
  const ink = dark ? s.whiteBright : s.black;

  /* Surfaces, all derived from the ground. A diff is a tint of its own verdict
   * hue rather than a saturated block, because the words on top of it have to
   * clear 4.5 against it — a full-strength green background cannot carry
   * either colour of text. */
  const hueOf = (hex: string) => toOklch(hex).H;
  const raised = surface(G.ground, 0.075);
  const raisedHover = surface(G.ground, 0.115);
  const sidebar = surface(G.ground, 0.05);
  const bashBg = surface(G.ground, 0.075, hueOf(s.magenta), 0.035);
  const memoryBg = surface(G.ground, 0.075, hueOf(s.cyan), 0.035);
  const selection = surface(G.ground, dark ? 0.24 : 0.16, hueOf(s.blue), 0.05);
  const diffAdd = surface(G.ground, dark ? 0.2 : 0.09, hueOf(s.green), 0.07);
  const diffDel = surface(G.ground, dark ? 0.2 : 0.09, hueOf(s.red), 0.07);
  const diffAddDim = surface(G.ground, dark ? 0.11 : 0.05, hueOf(s.green), 0.04);
  const diffDelDim = surface(G.ground, dark ? 0.11 : 0.05, hueOf(s.red), 0.04);
  /* Borders and placeholders are the one place the 3:1 UI floor is spent, and
   * it is spent on purpose: `subtle` has to recede or it is not subtle. */
  const doveHue = toOklch(need("Dove")).H;
  const subtle = dimAt(G.ground, 3, doveHue);
  const promptBorder = dimAt(G.ground, 3.6, doveHue);
  const rateEmpty = surface(G.ground, 0.14);

  const rgb = (hex: string) => {
    const n = parseInt(hex.slice(1), 16);
    return `rgb(${(n >> 16) & 255},${(n >> 8) & 255},${n & 255})`;
  };

  const theme: Record<string, string> = {
    /* Claude's own accent is a terracotta; Coral is the brand's word for it,
     * and Honey is its neighbour on the magic wheel, so the spinner shimmers
     * along the palette rather than off it. */
    claude: A("redBright"),
    claudeShimmer: A("yellowBright"),
    briefLabelClaude: A("redBright"),
    clawd_body: A("redBright"),
    clawd_background: A("black"),

    bashBorder: A("magenta"),
    skill: A("magentaBright"),
    autoAccept: A("magentaBright"),
    autoAcceptShimmer: A("magentaBright"),
    merged: A("magentaBright"),
    effortUltra: A("magentaBright"),

    permission: A("blue"),
    permissionShimmer: A("blueBright"),
    suggestion: A("blue"),
    remember: A("blue"),
    briefLabelYou: A("blue"),
    claudeBlue_FOR_SYSTEM_SPINNER: A("blue"),
    claudeBlueShimmer_FOR_SYSTEM_SPINNER: A("blueBright"),
    professionalBlue: A("blue"),
    rate_limit_fill: A("blue"),
    rate_limit_empty: rgb(rateEmpty),

    planMode: A("cyan"),
    ide: A("cyan"),
    background: A("cyan"),

    success: A("green"),
    error: A("red"),
    warning: A("yellow"),
    warningShimmer: A("yellowBright"),
    chromeYellow: A("yellow"),
    fastMode: A("redBright"),
    fastModeShimmer: A("yellowBright"),

    text: dark ? A("whiteBright") : A("black"),
    inverseText: dark ? A("black") : A("whiteBright"),
    inactive: rgb(dimAt(G.ground, 4.5, doveHue)),
    inactiveShimmer: dark ? A("white") : A("black"),
    subtle: rgb(subtle),
    promptBorder: rgb(promptBorder),
    promptBorderShimmer: A("blackBright"),

    diffAdded: rgb(diffAdd),
    diffRemoved: rgb(diffDel),
    diffAddedDimmed: rgb(diffAddDim),
    diffRemovedDimmed: rgb(diffDelDim),
    diffAddedWord: A(dark ? "greenBright" : "greenBright"),
    diffRemovedWord: A(dark ? "redBright" : "redBright"),

    /* Eight parallel agents want eight tellable-apart labels, so these take
     * the magic six plus both ends of the red family. */
    red_FOR_SUBAGENTS_ONLY: A("red"),
    orange_FOR_SUBAGENTS_ONLY: A("redBright"),
    yellow_FOR_SUBAGENTS_ONLY: A("yellow"),
    green_FOR_SUBAGENTS_ONLY: A("green"),
    blue_FOR_SUBAGENTS_ONLY: A("blue"),
    cyan_FOR_SUBAGENTS_ONLY: A("cyan"),
    purple_FOR_SUBAGENTS_ONLY: A("magentaBright"),
    pink_FOR_SUBAGENTS_ONLY: A("magenta"),

    rainbow_red: A("red"),
    rainbow_orange: A("redBright"),
    rainbow_yellow: A("yellow"),
    rainbow_green: A("green"),
    rainbow_blue: A("cyan"),
    rainbow_indigo: A("blue"),
    rainbow_violet: A("magenta"),
    rainbow_red_shimmer: A("redBright"),
    rainbow_orange_shimmer: A("yellow"),
    rainbow_yellow_shimmer: A("yellowBright"),
    rainbow_green_shimmer: A("greenBright"),
    rainbow_blue_shimmer: A("cyanBright"),
    rainbow_indigo_shimmer: A("blueBright"),
    rainbow_violet_shimmer: A("magentaBright"),

    userMessageBackground: rgb(raised),
    userMessageBackgroundHover: rgb(raisedHover),
    composerSidebarBackground: rgb(sidebar),
    bashMessageBackgroundColor: rgb(bashBg),
    memoryBackgroundColor: rgb(memoryBg),
    selectionBg: rgb(selection),
  };

  /* ------------------------------------------------------------- the audit */
  const audit: Audit[] = [];
  const resolve = (v: string) =>
    v.startsWith("ansi:") ? s[v.slice(5)] : "#" + v.slice(4, -1).split(",").map((n) => (+n).toString(16).padStart(2, "0")).join("");

  /* Every accent slot against the ground it is drawn on. */
  const TEXT_ROLES = new Set([
    "claude", "claudeShimmer", "success", "error", "warning", "text",
    "inactive", "permission", "suggestion", "remember", "planMode", "skill",
    "diffAddedWord", "diffRemovedWord", "briefLabelYou", "briefLabelClaude",
    "red_FOR_SUBAGENTS_ONLY", "orange_FOR_SUBAGENTS_ONLY",
    "yellow_FOR_SUBAGENTS_ONLY", "green_FOR_SUBAGENTS_ONLY",
    "blue_FOR_SUBAGENTS_ONLY", "cyan_FOR_SUBAGENTS_ONLY",
    "purple_FOR_SUBAGENTS_ONLY", "pink_FOR_SUBAGENTS_ONLY",
  ]);
  const SURFACES = new Set([
    "userMessageBackground", "userMessageBackgroundHover",
    "composerSidebarBackground", "bashMessageBackgroundColor",
    "memoryBackgroundColor", "selectionBg", "diffAdded", "diffRemoved",
    "diffAddedDimmed", "diffRemovedDimmed", "rate_limit_empty",
    "inverseText", "clawd_background",
  ]);
  for (const [role, value] of Object.entries(theme)) {
    if (SURFACES.has(role)) continue;
    const hex = resolve(value);
    const floor = TEXT_ROLES.has(role) ? 4.5 : 3;
    audit.push({ what: role, fg: hex, bg: G.ground, floor, ratio: contrastRatio(hex, G.ground) });
  }
  /* Text on every surface, and the diff words on their own diff grounds. */
  for (const role of SURFACES) {
    if (role === "inverseText" || role === "clawd_background") continue;
    const bg = resolve(theme[role]);
    audit.push({ what: `text on ${role}`, fg: ink, bg, floor: 4.5, ratio: contrastRatio(ink, bg) });
  }
  /* A chip is an accent block with inverseText on it, so the accents are
   * squeezed from BOTH sides: dark enough to read on the ground, light enough
   * to carry the inverse ink. Measured, because on a light ground those two
   * demands very nearly meet. */
  for (const role of ["claude", "permission", "autoAccept", "error", "success", "warning"]) {
    const chip = resolve(theme[role]);
    audit.push({ what: `inverseText on ${role}`, fg: resolve(theme.inverseText), bg: chip, floor: 4.5, ratio: contrastRatio(resolve(theme.inverseText), chip) });
  }
  audit.push({ what: "addedWord on diffAdded", fg: resolve(theme.diffAddedWord), bg: diffAdd, floor: 3, ratio: contrastRatio(resolve(theme.diffAddedWord), diffAdd) });
  audit.push({ what: "removedWord on diffRemoved", fg: resolve(theme.diffRemovedWord), bg: diffDel, floor: 3, ratio: contrastRatio(resolve(theme.diffRemovedWord), diffDel) });
  return { theme, audit };
}

interface Audit { what: string; fg: string; bg: string; floor: number; ratio: number }

/* -------------------------------------------------------------------- emit */
const GROUNDS: Ground[] = [
  { name: "Jack & Jill Dark", slug: "jack-and-jill-dark", base: "dark-ansi", ground: need("Black"), slots: darkSlots() },
  { name: "Jack & Jill Light", slug: "jack-and-jill-light", base: "light-ansi", ground: need("Paper"), slots: lightSlots() },
];

const KEYS: string[] = JSON.parse(readFileSync(join(OUT, "..", "keys.json"), "utf8"));
mkdirSync(OUT, { recursive: true });
const themesDir = join(homedir(), ".claude", "themes");
mkdirSync(themesDir, { recursive: true });

let failures = 0;
const spec: Record<string, unknown> = {};
const dump: Record<string, unknown> = {};
for (const G of GROUNDS) {
  const { theme, audit } = overrides(G);
  for (const k of Object.keys(theme)) {
    if (!KEYS.includes(k)) throw new Error(`${k} is not a Claude Code theme key — it would be dropped silently`);
  }
  writeFileSync(
    join(themesDir, `${G.slug}.json`),
    JSON.stringify({ name: G.name, base: G.base, overrides: theme }, null, 2) + "\n",
  );
  spec[G.slug] = { name: G.name, ground: G.ground, slots: G.slots, cursor: relight(need("Coral"), G.ground, 4.5), text: G.base === "dark-ansi" ? G.slots.whiteBright : G.slots.black, bold: G.base === "dark-ansi" ? G.slots.white : G.slots.black, selection: (theme.selectionBg as string) };

  console.log(`\n\x1b[1m${G.name}\x1b[0m  base ${G.base}  ground ${G.ground}  (${Object.keys(theme).length} roles)`);
  console.log("  slots:");
  for (const n of SLOT_NAMES) {
    const hex = G.slots[n];
    const r = contrastRatio(hex, G.ground);
    const brandName = Object.entries(B).find(([, v]) => v === hex)?.[0];
    console.log(`    ${n.padEnd(14)} ${hex}  ${r.toFixed(2).padStart(6)}:1  ${brandName ?? "derived"}`);
  }
  dump[G.slug] = { name: G.name, base: G.base, ground: G.ground, slots: G.slots, theme, audit, brand: B,
    slotBrand: Object.fromEntries(SLOT_NAMES.map((n) => [n, Object.entries(B).find(([, v]) => v === G.slots[n])?.[0] ?? null])) };
  const bad = audit.filter((a) => a.ratio < a.floor);
  const worst = [...audit].sort((a, b) => a.ratio - b.ratio).slice(0, 6);
  console.log(`  audit: ${audit.length} pairs, ${bad.length} below floor`);
  if (process.env.JJ_FULL) for (const a of audit) console.log(`    ${a.what.padEnd(34)} ${a.ratio.toFixed(2).padStart(6)}:1  floor ${a.floor}`);
  for (const a of worst) console.log(`    tightest ${a.what.padEnd(30)} ${a.ratio.toFixed(2)}:1  (floor ${a.floor})`);
  for (const a of bad) { failures++; console.log(`    \x1b[31mFAIL\x1b[0m ${a.what} ${a.fg} on ${a.bg} = ${a.ratio.toFixed(2)}:1 < ${a.floor}`); }
  /* A block cursor draws the glyph beneath it in the GROUND colour, so the
   * pair that has to stay legible is ground-on-cursor — which is why the
   * cursor answers to the 4.5 text floor and not the 3.0 UI one. */
  const cur = (spec[G.slug] as { cursor: string }).cursor;
  const curR = contrastRatio(G.ground, cur);
  console.log(`  cursor ${cur}  glyph under it ${curR.toFixed(2)}:1 (floor 4.5)`);
  if (curR < 4.5) { failures++; console.log("    \x1b[31mFAIL\x1b[0m cursor"); }
}
writeFileSync(join(OUT, "dump.json"), JSON.stringify(dump, null, 1));
writeFileSync(join(OUT, "profiles.json"), JSON.stringify(spec, null, 2));
console.log(`\nwrote ${themesDir}/jack-and-jill-{dark,light}.json and ${OUT}/profiles.json`);
if (failures) { console.log(`\n${failures} contrast failures`); process.exit(1); }
console.log("every measured pair clears its floor");
