#!/usr/bin/env python3
"""Jack & Jill status line for Claude Code.

Every colour here is an ANSI SGR code, never a hex: the codes point at the
profile's 16 slots, so this strip is brand-exact on Terminal.app (which
approximates 24-bit colour into its 256 cube) and follows the ground when the
theme flips, without knowing anything about which ground is on.

The payload's exact nesting is not documented, so nothing here indexes a fixed
path: `dig` walks the object for the first key that matches, and every field has
a fallback. The first run writes the payload to statusline-payload.json (once,
then never again) so the shape can be read rather than assumed.
"""
import json, os, subprocess, sys
from pathlib import Path

HOME = Path.home()
DIR = HOME / ".claude/themes/terminal-app"

# slot -> SGR. Named for the slot, not the colour, because the colour is the
# profile's business: `red` is Flame on Black and a re-lit Flame on Paper.
SGR = {
    "black": 30, "red": 31, "green": 32, "yellow": 33, "blue": 34,
    "magenta": 35, "cyan": 36, "white": 37,
    "blackBright": 90, "redBright": 91, "greenBright": 92, "yellowBright": 93,
    "blueBright": 94, "magentaBright": 95, "cyanBright": 96, "whiteBright": 97,
}
def c(slot, text):
    return f"\033[{SGR[slot]}m{text}\033[0m"


def dig(obj, *keys):
    """First value under any of `keys`, breadth-first. Survives re-nesting."""
    queue = [obj]
    while queue:
        node = queue.pop(0)
        if isinstance(node, dict):
            for k in keys:
                if k in node and node[k] not in (None, ""):
                    return node[k]
            queue.extend(node.values())
        elif isinstance(node, list):
            queue.extend(node)
    return None


def git(cwd, *args, timeout=0.4):
    try:
        r = subprocess.run(["git", *args], cwd=cwd, capture_output=True,
                           text=True, timeout=timeout)
        return r.stdout.strip() if r.returncode == 0 else None
    except Exception:
        return None


def _active():
    try:
        return (HOME / ".claude/themes/jack-and-jill.json").read_text()
    except Exception:
        return ""


def audit():
    """Every slot this strip draws with, measured against both grounds. A field
    whose colour is chosen wrongly for the ground shows up here as a number
    under 4.5 rather than as an invisible word on someone's screen."""
    pal = json.loads((DIR / "palette-data.json").read_text())
    def lum(h):
        f = lambda i: (lambda c: c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4)(int(h[i:i+2], 16) / 255)
        return 0.2126 * f(1) + 0.7152 * f(3) + 0.0722 * f(5)
    def cr(a, b):
        la, lb = lum(a), lum(b)
        hi, lo = max(la, lb), min(la, lb)
        return (hi + 0.05) / (lo + 0.05)
    fields = [("mark", "redBright"), ("model", None), ("project", "blackBright"),
              ("branch clean", "green"), ("branch dirty", "yellow"),
              ("context", "blue"), ("context low", "red"), ("spend", "blackBright"),
              ("added", "green"), ("removed", "red"), ("ground", "magenta")]
    bad = 0
    for slug, t in pal.items():
        light = t["base"] == "light-ansi"
        ground, slots = t["ground"], t["slots"]
        print(f"{t['name']}  ground {ground}")
        for name, slot in fields:
            s = ("black" if light else "white") if slot is None else slot
            r = cr(slots[s], ground)
            flag = "" if r >= 4.5 else "   BELOW 4.5"
            if r < 4.5: bad += 1
            print(f"   {name:14} {s:12} {slots[s]}  {r:6.2f}:1{flag}")
    return 1 if bad else 0


def main():
    try:
        raw = sys.stdin.read()
        d = json.loads(raw) if raw.strip() else {}
    except Exception:
        d = {}

    dump = DIR / "statusline-payload.json"
    if d and not dump.exists():
        try:
            dump.write_text(json.dumps(d, indent=2) + "\n")
        except Exception:
            pass

    # Which ground is on decides the primary ink. Hardcoding `white` put the
    # model name at 1.07:1 on Paper: Clay on Paper is invisible. Every slot this
    # strip uses is now chosen by ground, and --audit measures all of them.
    light = "light-ansi" in _active()
    INK = "black" if light else "white"

    parts = []

    # The mark, in Claude's own accent: Coral on Black, burnt Coral on Paper.
    model = dig(d, "display_name", "displayName") or dig(d, "model") or ""
    if isinstance(model, dict):
        model = model.get("display_name") or model.get("id") or ""
    parts.append(c("redBright", "✻") + " " + c(INK, str(model) or "Claude"))

    # Where you are. The project's own name, not the whole path.
    cwd = dig(d, "current_dir", "cwd", "project_dir") or os.getcwd()
    parts.append(c("blackBright", Path(str(cwd)).name))

    # The branch, and whether it is dirty. Honey for dirty is the brand's
    # warning colour; a clean tree gets Emerald.
    branch = dig(d, "branch") or git(cwd, "rev-parse", "--abbrev-ref", "HEAD")
    if branch:
        dirty = git(cwd, "status", "--porcelain", "--untracked-files=no")
        mark = "*" if dirty else ""
        parts.append(c("yellow" if dirty else "green", f"{branch}{mark}"))

    # Context left, as mass rather than a number alone: eight cells of matrix.
    pct = dig(d, "remaining_percentage")
    if pct is None:
        used = dig(d, "used_percentage")
        if used is not None:
            try: pct = 100 - float(used)
            except Exception: pct = None
    if pct is None:
        tot = dig(d, "context_window_size")
        cur = dig(d, "current_usage", "total_input_tokens")
        try:
            if tot and cur is not None: pct = 100 * (1 - float(cur) / float(tot))
        except Exception:
            pct = None
    if pct is not None:
        pct = max(0.0, min(100.0, float(pct)))
        filled = int(round(pct / 100 * 8))
        bar = "▓" * filled + "░" * (8 - filled)
        slot = "red" if pct < 15 else ("yellow" if pct < 30 else "blue")
        parts.append(c(slot, bar) + " " + c(slot, f"{pct:.0f}%"))

    # What the session has spent and moved.
    cost = dig(d, "total_cost_usd")
    if cost is not None:
        try: parts.append(c("blackBright", f"${float(cost):.2f}"))
        except Exception: pass
    add, rem = dig(d, "total_lines_added"), dig(d, "total_lines_removed")
    if add or rem:
        parts.append(c("green", f"+{add or 0}") + " " + c("red", f"-{rem or 0}"))

    # Which ground is on, so the strip says what the last flip did.
    parts.append(c("magenta", "☀" if light else "☾"))

    sys.stdout.write(c("blackBright", "  ").join(parts))


if "--audit" in sys.argv:
    sys.exit(audit())
main()
