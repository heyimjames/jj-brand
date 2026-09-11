#!/bin/sh
# Two phases on purpose: PLAN reads state and writes nothing, COMMIT writes.
#
# The first version wrote the theme file first and then asked Terminal to change
# profile. When the Terminal half failed, Claude Code had already flipped and the
# terminal had not, so the two disagreed and the next click flipped back from the
# wrong place. Committing last means a Terminal failure changes nothing at all.
#
# plan             -> MODE|LABEL|CURSOR|INDEX   (no writes)
# commit MODE IX   -> writes the active theme file and the cursor index
set -e
T="$HOME/.claude/themes"
D="$T/terminal-app"
ACTIVE="$T/jack-and-jill.json"
IX="$D/.cursor-index"

case "$1" in
plan)
  # plan [dark|light] plans that ground; plan with no argument flips to the
  # other one, which is what a click means.
  case "$2" in
    dark)  MODE=dark;  LABEL=Dark ;;
    light) MODE=light; LABEL=Light ;;
    "")
      if [ -f "$ACTIVE" ] && /usr/bin/grep -q '"base": *"light-ansi"' "$ACTIVE"; then
        MODE=dark; LABEL=Dark
      else
        MODE=light; LABEL=Light
      fi ;;
    *) echo "plan takes dark, light, or nothing" >&2; exit 2 ;;
  esac
  # The cursor takes the NEXT magic colour on every flip: a deterministic walk,
  # so shuffling comes back around rather than repeating at random. All twelve
  # values (six hues, two grounds) clear 4.5:1 against their own ground, which
  # is the floor a BLOCK cursor answers to, since Terminal draws the glyph
  # beneath it in the ground colour.
  N=$(cat "$IX" 2>/dev/null || echo -1)
  N=$(( (N + 1) % 6 ))
  CURSOR=$(python3 -c "
import json
print(json.load(open('$D/cursors.json'))['real'][$N]['hex'])")
  printf '%s|%s|%s|%s\n' "$MODE" "$LABEL" "$CURSOR" "$N"
  ;;
commit)
  MODE="$2"; N="$3"
  [ -n "$MODE" ] && [ -n "$N" ] || { echo "commit needs MODE and INDEX" >&2; exit 2; }
  # One name in /theme whichever ground is on: the theme is one thing and the
  # ground is a toggle. Rewriting the file the session already points AT is what
  # makes a running session repaint, because theme files are watched while the
  # settings file may not be.
  python3 - "$D/sources/$MODE.json" "$ACTIVE" <<'PY'
import json, sys
t = json.load(open(sys.argv[1]))
t["name"] = "Jack & Jill"
with open(sys.argv[2], "w") as f:
    json.dump(t, f, indent=2)
    f.write("\n")
PY
  echo "$N" > "$IX"
  echo ok
  ;;
*)
  echo "usage: jj-toggle.sh plan | commit MODE INDEX" >&2; exit 2 ;;
esac
