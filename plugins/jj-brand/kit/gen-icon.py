#!/usr/bin/env python3
"""The app icon: every brand chip in a grid, generated from brand.ts.

Twenty cells for nineteen swatches, and the twentieth is the split — half Black,
half Paper — because that is what one click on this icon does. It is the only
cell that is not a colour, which is what makes it read as the verb in a grid of
nouns.

Grouped by family down the grid (neutrals, tints and muteds, cores, magic) so
the icon reads as a palette sheet rather than as confetti, and every chip keeps
a hairline ring: without it White and Paper dissolve into each other and Black
dissolves into the ground.
"""
import json, re, subprocess, sys
from pathlib import Path

D = Path(__file__).resolve().parent
STUDIO = Path(__import__("os").environ.get("JJ_STUDIO", str(Path.home() / "Documents/Projects/jj-grid-studio")))

src = (STUDIO / "src/lib/brand.ts").read_text()
swatch = {m[0]: m[1] for m in re.findall(r'\{\s*name:\s*"([^"]+)",\s*hex:\s*"(#[0-9a-f]{6})"\s*\}', src)}

ROWS = [
    ["Black", "Dove", "Clay", "Paper", "White"],          # the neutrals
    ["Ice", "Mint", "Butter", "Sage", "Khaki"],           # tints and muteds
    ["Cobalt", "Leaf", "Flame", "Coral", "Honey"],        # cores, into the magic
    ["Emerald", "Sky", "Periwinkle", "Orchid", None],     # magic, then the split
]
missing = [n for row in ROWS for n in row if n and n not in swatch]
if missing:
    sys.exit(f"brand.ts has no swatch named {missing}")

# The card, then the grid inset INSIDE it. The first version put the grid at the
# card's own edge and the corner radius ate the corner chips: a rounded rect
# only contains a corner point if it sits within `rad` of the arc centre, so the
# grid needs an inset of its own, not just a shared padding.
R, MARGIN, INSET = 1024, 56, 112
PAD = MARGIN + INSET
CARD = R - 2 * MARGIN
r = R - 2 * PAD
rad = int(CARD * 0.235)
COLS, NROWS = 5, 4
gap = r * 0.026
cw = (r - gap * (COLS - 1)) / COLS
chh = (r - gap * (NROWS - 1)) / NROWS
crad = cw * 0.16

cells = []
for ri, row in enumerate(ROWS):
    for ci, name in enumerate(row):
        x = PAD + ci * (cw + gap)
        y = PAD + ri * (chh + gap)
        if name is None:
            # the verb: half Black, half Paper, one rounded chip
            cells.append(
                f'<g><clipPath id="sp"><rect x="{x:.1f}" y="{y:.1f}" width="{cw:.1f}" '
                f'height="{chh:.1f}" rx="{crad:.1f}"/></clipPath>'
                f'<g clip-path="url(#sp)">'
                f'<rect x="{x:.1f}" y="{y:.1f}" width="{cw/2:.1f}" height="{chh:.1f}" fill="{swatch["Black"]}"/>'
                f'<rect x="{x+cw/2:.1f}" y="{y:.1f}" width="{cw/2:.1f}" height="{chh:.1f}" fill="{swatch["Paper"]}"/>'
                f'</g></g>')
        else:
            cells.append(
                f'<rect x="{x:.1f}" y="{y:.1f}" width="{cw:.1f}" height="{chh:.1f}" '
                f'rx="{crad:.1f}" fill="{swatch[name]}"/>')
        cells.append(
            f'<rect x="{x:.1f}" y="{y:.1f}" width="{cw:.1f}" height="{chh:.1f}" rx="{crad:.1f}" '
            f'fill="none" stroke="#010101" stroke-opacity="0.30" stroke-width="2.5"/>')

svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="{R}" height="{R}" viewBox="0 0 {R} {R}">
 <defs><clipPath id="card"><rect x="{MARGIN}" y="{MARGIN}" width="{CARD}" height="{CARD}" rx="{rad}"/></clipPath></defs>
 <g clip-path="url(#card)">
  <rect x="{MARGIN}" y="{MARGIN}" width="{CARD}" height="{CARD}" fill="{swatch["Clay"]}"/>
  {''.join(cells)}
 </g>
 <rect x="{MARGIN}" y="{MARGIN}" width="{CARD}" height="{CARD}" rx="{rad}"
       fill="none" stroke="#010101" stroke-opacity="0.16" stroke-width="3"/>
</svg>'''

(D / "icon.html").write_text('<style>html,body{margin:0;background:transparent}</style>' + svg)
print("wrote", D / "icon.html")

CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars",
                "--default-background-color=00000000", f"--screenshot={D}/icon.png",
                "--window-size=1024,1024", str(D / "icon.html")],
               capture_output=True, cwd=str(D))
print("wrote", D / "icon.png")
