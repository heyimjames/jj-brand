#!/usr/bin/env python3
"""The app icon: the magic six as chips, generated from brand.ts.

Six, not nineteen. The whole palette read as a swatch sheet at full size and as
mush at 32px, which is the size that matters — a Dock icon is a silhouette and a
colour, not an inventory.

The chips are 4:5, the ratio the studio's own cards are drawn at, and each one
sits a little off the grid. The offsets are SEEDED FROM THE SWATCH NAME rather
than drawn at random: the icon has to come back identical every time it is
generated, or a rebuild quietly ships a different mark.

Two grounds, because macOS 26 serves a dark app icon from an asset catalogue's
appearance variants. Paper for light, Black for dark, each with a hairline that
belongs to its own ground: black at low alpha on paper, white at low alpha on
ink, because a tinted neutral reads as dirt on either.
"""
import hashlib, os, re, subprocess, sys
from pathlib import Path

D = Path(__file__).resolve().parent
STUDIO = Path(os.environ.get("JJ_STUDIO", str(Path.home() / "Documents/Projects/jj-grid-studio")))

src = (STUDIO / "src/lib/brand.ts").read_text()
swatch = {m[0]: m[1] for m in re.findall(r'\{\s*name:\s*"([^"]+)",\s*hex:\s*"(#[0-9a-f]{6})"\s*\}', src)}

ROWS = [["Coral", "Honey", "Emerald"], ["Sky", "Periwinkle", "Orchid"]]
missing = [n for row in ROWS for n in row if n not in swatch]
if missing:
    sys.exit(f"brand.ts has no swatch named {missing}")

R, MARGIN = 1024, 56
CARD = R - 2 * MARGIN
rad = int(CARD * 0.235)
COLS, NROWS = 3, 2
CHIP_RATIO = 4 / 5                      # the studio's own card proportion
INSET = 104
r = R - 2 * (MARGIN + INSET)
gapx = r * 0.10
cw = (r - gapx * (COLS - 1)) / COLS
chh = cw / CHIP_RATIO
gapy = cw * 0.16
crad = cw * 0.19
gridH = chh * NROWS + gapy * (NROWS - 1)
left, top = (R - (cw * COLS + gapx * (COLS - 1))) / 2, (R - gridH) / 2


def jitter(name, axis):
    """Deterministic offset in ±1, from the swatch's own name."""
    h = hashlib.sha256(f"{name}:{axis}".encode()).digest()
    return (int.from_bytes(h[:4], "big") / 0xFFFFFFFF) * 2 - 1


def build(ground, hairline, path):
    cells = []
    for ri, row in enumerate(ROWS):
        for ci, name in enumerate(row):
            # The offsets have to survive the Dock: a tile is ~48px, a chip ~11px,
            # so the 8% nudge the first version used was under a pixel and the
            # grid read as perfectly tidy. 20% of a chip is ~2px there, which is
            # the smallest offset that is actually visible at the size that
            # matters, and still reads as hand-placed rather than broken.
            x = left + ci * (cw + gapx) + jitter(name, "x") * cw * 0.20
            y = top + ri * (chh + gapy) + jitter(name, "y") * chh * 0.17
            cells.append(f'<rect x="{x:.1f}" y="{y:.1f}" width="{cw:.1f}" height="{chh:.1f}" '
                         f'rx="{crad:.1f}" fill="{swatch[name]}"/>')
            cells.append(f'<rect x="{x:.1f}" y="{y:.1f}" width="{cw:.1f}" height="{chh:.1f}" '
                         f'rx="{crad:.1f}" fill="none" stroke="{hairline[0]}" '
                         f'stroke-opacity="{hairline[1]}" stroke-width="2.5"/>')
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{R}" height="{R}" viewBox="0 0 {R} {R}">'
           f'<rect x="{MARGIN}" y="{MARGIN}" width="{CARD}" height="{CARD}" rx="{rad}" fill="{ground}"/>'
           + "".join(cells) +
           f'<rect x="{MARGIN}" y="{MARGIN}" width="{CARD}" height="{CARD}" rx="{rad}" fill="none" '
           f'stroke="{hairline[0]}" stroke-opacity="{hairline[1] * 0.8}" stroke-width="3"/></svg>')
    html = D / f".icon-{path}.html"
    html.write_text('<style>html,body{margin:0;background:transparent}</style>' + svg)
    subprocess.run(["/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
                    "--headless=new", "--disable-gpu", "--hide-scrollbars",
                    "--default-background-color=00000000", f"--screenshot={D}/{path}.png",
                    "--window-size=1024,1024", str(html)], capture_output=True, cwd=str(D))
    html.unlink(missing_ok=True)
    print("wrote", D / f"{path}.png")


build("#ffffff", ("#010101", 0.16), "icon-light")
build(swatch["Black"], ("#ffffff", 0.20), "icon-dark")
subprocess.run(["cp", str(D / "icon-light.png"), str(D / "icon.png")])
