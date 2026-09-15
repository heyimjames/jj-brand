#!/usr/bin/env python3
"""The app icon: the magic six as chips, generated from brand.ts.

Six, not nineteen. The whole palette read as a swatch sheet at full size and as
mush at 32px, which is the size that matters — a Dock icon is a silhouette and a
colour, not an inventory. The magic six are the set anyone recognises as Jack &
Jill, and at three across they stay six distinct squares in the Dock.

White card rather than Clay: the chips are the subject, so the ground gets out of
their way. Each chip keeps a hairline, or Honey and the card边 blur together at
small sizes.
"""
import re, subprocess, sys
from pathlib import Path
import os

D = Path(__file__).resolve().parent
STUDIO = Path(os.environ.get("JJ_STUDIO", str(Path.home() / "Documents/Projects/jj-grid-studio")))

src = (STUDIO / "src/lib/brand.ts").read_text()
swatch = {m[0]: m[1] for m in re.findall(r'\{\s*name:\s*"([^"]+)",\s*hex:\s*"(#[0-9a-f]{6})"\s*\}', src)}

ROWS = [
    ["Coral", "Honey", "Emerald"],
    ["Sky", "Periwinkle", "Orchid"],
]
missing = [n for row in ROWS for n in row if n not in swatch]
if missing:
    sys.exit(f"brand.ts has no swatch named {missing}")

R, MARGIN, INSET = 1024, 56, 112
PAD = MARGIN + INSET
CARD = R - 2 * MARGIN
r = R - 2 * PAD
rad = int(CARD * 0.235)
COLS, NROWS = 3, 2
gap = r * 0.075
cw = (r - gap * (COLS - 1)) / COLS
chh = cw                                  # square chips; the grid centres itself
crad = cw * 0.2
gridH = chh * NROWS + gap * (NROWS - 1)
top = (R - gridH) / 2

cells = []
for ri, row in enumerate(ROWS):
    for ci, name in enumerate(row):
        x = PAD + ci * (cw + gap)
        y = top + ri * (chh + gap)
        cells.append(f'<rect x="{x:.1f}" y="{y:.1f}" width="{cw:.1f}" height="{chh:.1f}" '
                     f'rx="{crad:.1f}" fill="{swatch[name]}"/>')
        cells.append(f'<rect x="{x:.1f}" y="{y:.1f}" width="{cw:.1f}" height="{chh:.1f}" '
                     f'rx="{crad:.1f}" fill="none" stroke="#010101" stroke-opacity="0.16" '
                     f'stroke-width="2.5"/>')

svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="{R}" height="{R}" viewBox="0 0 {R} {R}">
 <rect x="{MARGIN}" y="{MARGIN}" width="{CARD}" height="{CARD}" rx="{rad}" fill="#ffffff"/>
 {''.join(cells)}
 <rect x="{MARGIN}" y="{MARGIN}" width="{CARD}" height="{CARD}" rx="{rad}"
       fill="none" stroke="#010101" stroke-opacity="0.12" stroke-width="3"/>
</svg>'''

(D / "icon.html").write_text('<style>html,body{margin:0;background:transparent}</style>' + svg)
subprocess.run(["/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
                "--headless=new", "--disable-gpu", "--hide-scrollbars",
                "--default-background-color=00000000", f"--screenshot={D}/icon.png",
                "--window-size=1024,1024", str(D / "icon.html")],
               capture_output=True, cwd=str(D))
print("wrote", D / "icon.png")
