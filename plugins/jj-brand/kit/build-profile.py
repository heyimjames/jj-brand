#!/usr/bin/env python3
"""Turn the measured palette into two importable Terminal.app profiles.

Terminal stores each colour as an NSKeyedArchiver'd NSColor, which is why a
theme cannot just be a list of hexes. NSColorSpace 1 is calibrated RGB — the
colour-managed space Terminal's own stock profiles use, so the values land on a
P3 display as the sRGB the brand specifies rather than raw and oversaturated
(NSColorSpace 2, device RGB, is the unmanaged one).

The FONT and the window geometry are lifted verbatim out of the user's current
profile: a theme has no business restyling his typography. The one setting it
does overrule is OPACITY. "Clear Dark" runs at alpha 0.95 over a blur, and a
translucent ground makes every measured contrast ratio a fiction — whatever is
behind the window is part of the composite.
"""
import base64, json, plistlib, sys
from pathlib import Path

OUT = Path("out")
spec = json.loads((OUT / "profiles.json").read_text())
cur = plistlib.load(open("../term.plist", "rb"))["Window Settings"]["Clear Dark"]

def nscolor(v: str) -> bytes:
    """Accepts #rrggbb or the rgb(r,g,b) form the theme file uses for surfaces."""
    if v.startswith("rgb("):
        r, g, b = (int(x) / 255 for x in v[4:-1].split(","))
        return _archive(r, g, b)
    hex_ = v
    r = int(hex_[1:3], 16) / 255
    g = int(hex_[3:5], 16) / 255
    b = int(hex_[5:7], 16) / 255
    archive = {
        "$version": 100000,
        "$archiver": "NSKeyedArchiver",
        "$top": {"root": plistlib.UID(1)},
        "$objects": [
            "$null",
            {
                "NSRGB": f"{r:.10g} {g:.10g} {b:.10g}\0".encode("ascii"),
                "NSColorSpace": 1,
                "$class": plistlib.UID(2),
            },
            {"$classname": "NSColor", "$classes": ["NSColor", "NSObject"]},
        ],
    }
    return plistlib.dumps(archive, fmt=plistlib.FMT_BINARY)


def _archive(r, g, b) -> bytes:
    return nscolor("#%02x%02x%02x" % (round(r * 255), round(g * 255), round(b * 255)))

ANSI = {
    "black": "ANSIBlackColor", "red": "ANSIRedColor", "green": "ANSIGreenColor",
    "yellow": "ANSIYellowColor", "blue": "ANSIBlueColor", "magenta": "ANSIMagentaColor",
    "cyan": "ANSICyanColor", "white": "ANSIWhiteColor",
    "blackBright": "ANSIBrightBlackColor", "redBright": "ANSIBrightRedColor",
    "greenBright": "ANSIBrightGreenColor", "yellowBright": "ANSIBrightYellowColor",
    "blueBright": "ANSIBrightBlueColor", "magentaBright": "ANSIBrightMagentaColor",
    "cyanBright": "ANSIBrightCyanColor", "whiteBright": "ANSIBrightWhiteColor",
}

for slug, s in spec.items():
    p = {
        "name": s["name"],
        "type": "Window Settings",
        "ProfileCurrentVersion": 2.09,
        "BackgroundColor": nscolor(s["ground"]),
        "TextColor": nscolor(s["text"]),
        "TextBoldColor": nscolor(s["bold"]),
        "CursorColor": nscolor(s["cursor"]),
        "SelectionColor": nscolor(s["selection"]),
        # False keeps Terminal from "helpfully" nudging ANSI colours it thinks
        # sit too near the background — every one of these was measured.
        "DynamicANSIForegroundColors": False,
        "Font": cur["Font"],
        "FontAntialias": True,
        "FontWidthSpacing": cur.get("FontWidthSpacing", 1),
        "FontHeightSpacing": cur.get("FontHeightSpacing", 1.0),
        "columnCount": cur.get("columnCount", 120),
        "rowCount": cur.get("rowCount", 30),
        "useOptionAsMetaKey": cur.get("useOptionAsMetaKey", True),
        "CursorBlink": cur.get("CursorBlink", True),
        "ShowRepresentedURLInTitle": False,
    }
    for slot, key in ANSI.items():
        p[key] = nscolor(s["slots"][slot])
    dest = OUT / f"{s['name'].replace(' & ', ' and ').replace(' ', '-')}.terminal"
    with open(dest, "wb") as fh:
        plistlib.dump(p, fh, fmt=plistlib.FMT_XML)
    print(f"wrote {dest}  bg {s['ground']}  cursor {s['cursor']}")
