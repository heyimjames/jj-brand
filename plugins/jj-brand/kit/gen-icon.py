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

COLUMNS = [("Coral", "Sky"), ("Honey", "Periwinkle"), ("Emerald", "Orchid")]
missing = [n for col in COLUMNS for n in col if n not in swatch]
if missing:
    sys.exit(f"brand.ts has no swatch named {missing}")

R, MARGIN = 1024, 56
CARD = R - 2 * MARGIN
rad = int(CARD * 0.235)

# MASONRY, not scatter. Random offsets read as a wonky grid rather than as a
# considered one, and at Dock size they read as nothing at all. So the columns
# are strictly aligned and the block is flush on all four sides; what varies is
# where each column's SEAM falls. Every chip is a different height, the grid is
# obvious, and nothing looks like a mistake.
INSET = 104
BW = R - 2 * (MARGIN + INSET)              # block width
gap = BW * 0.085
cw = (BW - gap * 2) / 3
BH = BW * 1.06                             # a touch taller than wide
left, top = (R - BW) / 2, (R - BH) / 2
crad = cw * 0.19


def seam(name):
    """Where this column splits, 0.36..0.64 of its height, from its own name.
    Seeded rather than chosen so a rebuild cannot ship a different mark."""
    h = hashlib.sha256(f"seam:{name}".encode()).digest()
    return 0.36 + (int.from_bytes(h[:4], "big") / 0xFFFFFFFF) * 0.28


def build(ground, hairline, path):
    cells = []
    for ci, (upper, lower) in enumerate(COLUMNS):
        x = left + ci * (cw + gap)
        inner = BH - gap
        h1 = inner * seam(upper)
        for name, y, hh in ((upper, top, h1), (lower, top + h1 + gap, inner - h1)):
            cells.append(f'<rect x="{x:.1f}" y="{y:.1f}" width="{cw:.1f}" height="{hh:.1f}" '
                         f'rx="{crad:.1f}" fill="{swatch[name]}"/>')
            cells.append(f'<rect x="{x:.1f}" y="{y:.1f}" width="{cw:.1f}" height="{hh:.1f}" '
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
