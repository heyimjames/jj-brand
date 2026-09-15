#!/usr/bin/env python3
"""Build AppIcon.icon and compile it, so macOS has a real dark variant.

macOS 26 serves light and dark app icons from an asset catalogue compiled out of
Icon Composer's `.icon` format. The format is undocumented, so it was read off a
real one on this machine (/Applications/Readout.app) and the appearance key was
found by compiling candidates and diffing the output:

  "dark"       ignored silently — the catalogue came back byte-identical
  "dark-color" honoured — a different colour produces a different catalogue

That difference is the whole reason this file exists rather than a guess: an
ignored key looks exactly like a working one until someone switches appearance.

The artwork is the CHIPS ALONE on a transparent ground. macOS draws the rounded
card itself from `fill`, which is what lets one set of chips sit on Paper in
light and on Black in dark.
"""
import json, shutil, subprocess, sys
from pathlib import Path

D = Path(__file__).resolve().parent
WHITE = "srgb:1.00000,1.00000,1.00000,1.00000"
INK = "srgb:0.00392,0.00392,0.00392,1.00000"   # brand Black #010101

icon = D / "AppIcon.icon"
shutil.rmtree(icon, ignore_errors=True)
(icon / "Assets").mkdir(parents=True)
shutil.copy(D / "icon-chips.png", icon / "Assets/chips.png")
(icon / "icon.json").write_text(json.dumps({
    "fill": {"solid": WHITE},
    "appearances": {"dark-color": {"fill": {"solid": INK}}},
    "groups": [{
        "layers": [{"image-name": "chips.png", "name": "chips",
                    "position": {"scale": 1.0, "translation-in-points": [0, 0]}}],
        "shadow": {"kind": "neutral", "opacity": 0},
        "specular": False,
        "translucency": {"enabled": False, "value": 0.5},
    }],
    "supported-platforms": {"squares": "shared"},
}, indent=1) + "\n")

out = D / ".appicon-build"
shutil.rmtree(out, ignore_errors=True)
out.mkdir()
r = subprocess.run(["xcrun", "actool", str(icon), "--compile", str(out),
                    "--app-icon", "AppIcon", "--platform", "macosx",
                    "--minimum-deployment-target", "26.0",
                    "--output-partial-info-plist", str(out / "partial.plist")],
                   capture_output=True, text=True)
car = out / "Assets.car"
if not car.exists():
    sys.exit(f"actool produced no catalogue:\n{r.stdout}\n{r.stderr}")

info = json.loads(subprocess.run(["/usr/bin/assetutil", "--info", str(car)],
                                 capture_output=True, text=True).stdout)
appearances = sorted({e.get("Appearance") for e in info
                      if isinstance(e, dict) and e.get("Appearance")})
if "NSAppearanceNameDarkAqua" not in appearances:
    sys.exit(f"no dark appearance in the catalogue: {appearances}")
print(f"  compiled: {car.stat().st_size}B, appearances {appearances}")
