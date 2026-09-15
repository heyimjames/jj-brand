#!/usr/bin/env python3
"""The finish message, in the brand's own colours.

24-bit rather than the ANSI slots, deliberately: the shell that ran the
installer is still wearing its old profile, so slot references would print in
whatever palette it had. The literal hexes show the real thing before the
profile has been picked up.

The PROSE stays uncoloured — the same rule the status line follows. The ground
is unknown at this moment (it may be a light terminal, a dark one, or somebody
else's theme entirely), so only the marks take colour, and they are chosen to
read on either. Text takes the terminal's own foreground, which is right by
definition.

The matrix is sparse for the reason DEFAULT_MAGIC is: a line of colour in every
cell is confetti, and says the opposite of "these ones matter".
"""
import json, os, sys
from pathlib import Path

KIT = Path(__file__).resolve().parent
# JJ_FORCE_COLOR exists so the message can be checked when it is piped, which
# is the only way to read the escapes rather than trust them.
PLAIN = ((not sys.stdout.isatty()) and not os.environ.get("JJ_FORCE_COLOR")) \
        or os.environ.get("NO_COLOR")


def rgb(hex_, s):
    if PLAIN:
        return s
    r, g, b = (int(hex_[i:i+2], 16) for i in (1, 3, 5))
    return f"\033[38;2;{r};{g};{b}m{s}\033[0m"


try:
    magic = [c["hex"] for c in json.loads((KIT / "cursors.json").read_text())["real"]]
except Exception:
    magic = ["#ff8042", "#ffd862", "#27d271", "#00ccfa", "#88a5ff", "#f97cde"]

DOVE = "#8a8b96"        # reads on either ground, which is the whole job here
CORAL = magic[0]

# A band of the matrix: mostly resting, a few cells that found something. The
# positions are fixed rather than random so the message is the same every time.
WIDTH = 34
# Six lit cells in 102: 5.9%, which is DEFAULT_MAGIC's 0.06 almost exactly, and
# that is the point rather than a coincidence. One cell per hue, at fixed
# positions so the message is identical every time it prints.
LIT = {(3, 0): 0, (9, 2): 1, (14, 1): 2, (21, 0): 3, (27, 2): 4, (31, 1): 5}
rows = []
for r in range(3):
    cells = [rgb(magic[LIT[(c, r)]], "\u25aa") if (c, r) in LIT else rgb(DOVE, "\u25aa")
             for c in range(WIDTH)]
    rows.append("  " + " ".join(cells))

out = [
    "",
    "  " + rgb(CORAL, "✻") + "  Jack & Jill for the terminal",
    "",
    *rows,
    "",
    "  Two grounds, sixteen slots, seventy-two roles, every pair measured.",
    "",
    "  " + rgb(DOVE, "Next") + "   Restart Claude Code. It is already wearing it.",
    "         Open a new tab, or run exec zsh, for the shell palette.",
    "",
    "  " + rgb(DOVE, "Then") + "   One click on the Dock icon cycles auto, dark and light.",
    "         The cursor takes a different magic colour on every blink.",
    "",
]
print("\n".join(out))
