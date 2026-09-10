#!/bin/sh
# Jack & Jill terminal kit — installer.
#
# What it touches, all of it backed up and idempotent:
#   ~/.claude/themes/terminal-app/   the kit itself
#   ~/.claude/themes/jack-and-jill.json   the toggled theme (the plugin serves
#                                         the two pinned ones itself)
#   ~/.claude/settings.json          the status line, only if none is set
#   ~/.zshrc                         one sourced line for the shell palette
#   git --global color.*             only keys you have not already set
# Optional, behind flags:
#   --dock     builds the one-click ground toggle and pins it to the Dock
#   --cursor   installs the agent that walks the cursor through the magic six
#   --all      both
set -e
SRC=$(cd "$(dirname "$0")" && pwd)
KIT="$SRC/kit"
DEST="$HOME/.claude/themes/terminal-app"
DOCK=0; CURSOR=0
for a in "$@"; do
  case "$a" in
    --dock) DOCK=1 ;;
    --cursor) CURSOR=1 ;;
    --all) DOCK=1; CURSOR=1 ;;
    *) echo "unknown flag: $a" >&2; exit 2 ;;
  esac
done
say() { printf '  %s\n' "$1"; }

echo "Jack & Jill terminal kit"
mkdir -p "$DEST"
cp -R "$KIT/." "$DEST/"
chmod +x "$DEST"/*.sh "$DEST/dist/shell/jj-git-colors.sh" 2>/dev/null || true
say "kit -> $DEST"

# The toggled theme: one entry in /theme whichever ground is on. The plugin
# serves Jack & Jill Dark and Light as pinned entries beside it.
/usr/bin/python3 - "$DEST/sources/dark.json" "$HOME/.claude/themes/jack-and-jill.json" <<'PY'
import json, sys, pathlib
t = json.load(open(sys.argv[1])); t["name"] = "Jack & Jill"
p = pathlib.Path(sys.argv[2])
if not p.exists():
    p.write_text(json.dumps(t, indent=2) + "\n")
PY
say "theme  -> ~/.claude/themes/jack-and-jill.json  (pick it with /theme)"

# ------------------------------------------------------------- Terminal.app
if [ "$(uname)" = "Darwin" ] && [ -d "/System/Applications/Utilities/Terminal.app" ]; then
  for L in Dark Light; do
    HAVE=$(osascript -e "tell application \"Terminal\" to return (exists settings set \"Jack-and-Jill-$L\")" 2>/dev/null || echo false)
    if [ "$HAVE" != "true" ]; then
      open "$DEST/Jack-and-Jill-$L.terminal" 2>/dev/null || true
      sleep 2
    fi
  done
  osascript -e 'tell application "Terminal" to set default settings to settings set "Jack-and-Jill-Dark"' 2>/dev/null || true
  say "Terminal.app profiles installed, Dark set as default"
fi

# -------------------------------------------------------------- status line
/usr/bin/python3 - <<'PY'
import json, pathlib, shutil
p = pathlib.Path.home()/".claude/settings.json"
d = json.loads(p.read_text()) if p.exists() else {}
if "statusLine" in d:
    print("  status line: you already have one, left alone")
else:
    shutil.copy(p, str(p) + ".bak-before-jj") if p.exists() else None
    d["statusLine"] = {"type": "command",
        "command": "/usr/bin/python3 " + str(pathlib.Path.home()/".claude/themes/terminal-app/jj_statusline.py"),
        "padding": 0}
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(d, indent=2) + "\n")
    print("  status line installed")
PY

# -------------------------------------------------------------------- shell
for RC in "$HOME/.zshrc" "$HOME/.bashrc"; do
  [ -f "$RC" ] || continue
  if grep -q "jj-shell-colors" "$RC" 2>/dev/null; then
    say "$(basename "$RC"): already sourced"
  else
    cp "$RC" "$RC.bak-before-jj"
    cat >> "$RC" <<'RCB'

# --- Jack & Jill terminal palette -------------------------------------------
[ -f ~/.claude/themes/terminal-app/dist/shell/jj-shell-colors.sh ] && \
  . ~/.claude/themes/terminal-app/dist/shell/jj-shell-colors.sh
# ----------------------------------------------------------------------------
RCB
    say "$(basename "$RC"): palette sourced (backup alongside)"
  fi
done
sh "$DEST/dist/shell/jj-git-colors.sh" >/dev/null 2>&1 && say "git colours set (existing keys kept)"

# --------------------------------------------------------------- the Dock app
if [ "$DOCK" -eq 1 ]; then
  APP="$HOME/Applications/Jack & Jill Theme.app"
  mkdir -p "$HOME/Applications"
  rm -rf "$APP"
  osacompile -o "$APP" "$DEST/jj-theme-toggle.applescript"
  ICON=$(mktemp -d)/jj.iconset; mkdir -p "$ICON"
  for pair in "16 icon_16x16" "32 icon_16x16@2x" "32 icon_32x32" "64 icon_32x32@2x" \
              "128 icon_128x128" "256 icon_128x128@2x" "256 icon_256x256" \
              "512 icon_256x256@2x" "512 icon_512x512"; do
    SZ=$(echo "$pair" | cut -d' ' -f1); NM=$(echo "$pair" | cut -d' ' -f2)
    sips -z "$SZ" "$SZ" "$DEST/icon.png" --out "$ICON/$NM.png" >/dev/null
  done
  cp "$DEST/icon.png" "$ICON/icon_512x512@2x.png"
  iconutil -c icns "$ICON" -o "$APP/Contents/Resources/applet.icns"
  /usr/bin/python3 - "$APP/Contents/Info.plist" <<'PY'
import plistlib, sys
p = sys.argv[1]; d = plistlib.load(open(p, 'rb'))
d["LSUIElement"] = True          # a click must not steal focus from Terminal
d["CFBundleName"] = "Jack & Jill Theme"
plistlib.dump(d, open(p, 'wb'))
PY
  codesign --force --deep -s - "$APP" >/dev/null 2>&1 || true
  /usr/bin/python3 - "$APP" <<'PY'
import plistlib, subprocess, sys, os
APP = sys.argv[1]
url = "file://" + APP.replace(" ", "%20").replace("&", "%26") + "/"
d = plistlib.loads(subprocess.run(["defaults","export","com.apple.dock","-"],
                                  capture_output=True, check=True).stdout)
apps = d.get("persistent-apps", [])
lbl = lambda e: e.get("tile-data", {}).get("file-data", {}).get("_CFURLString") or ""
entry = {"GUID": 0, "tile-data": {"file-data": {"_CFURLString": url, "_CFURLStringType": 15},
         "file-label": "Jack & Jill Theme", "file-type": 41, "is-beta": False},
         "tile-type": "file-tile"}
hits = [i for i, e in enumerate(apps) if "Jack" in lbl(e) and "Theme" in lbl(e)]
for i in hits: apps[i] = entry
if not hits: apps.append(entry)
d["persistent-apps"] = apps
open("/tmp/jj-dock.plist","wb").write(plistlib.dumps(d))
subprocess.run(["defaults","import","com.apple.dock","/tmp/jj-dock.plist"], check=True)
PY
  killall Dock 2>/dev/null || true
  say "Dock icon installed (one click flips the ground)"
fi

# ------------------------------------------------------------- cursor agent
if [ "$CURSOR" -eq 1 ]; then
  /usr/bin/python3 - <<'PY'
import plistlib, pathlib
D = pathlib.Path.home()/".claude/themes/terminal-app"
p = pathlib.Path.home()/"Library/LaunchAgents/com.jackandjill.cursorcycle.plist"
p.parent.mkdir(parents=True, exist_ok=True)
plistlib.dump({"Label": "com.jackandjill.cursorcycle",
  "ProgramArguments": ["/usr/bin/osascript", str(D/"jj-cursor-cycle.applescript"), "1.0"],
  "RunAtLoad": True, "KeepAlive": True, "ProcessType": "Background",
  "StandardErrorPath": str(D/"cursor-cycle.log")}, open(p, "wb"))
PY
  sh "$DEST/jj-cursor.sh" start >/dev/null 2>&1 || true
  say "cursor agent running (a magic colour per blink)"
fi

echo
echo "Next:"
echo "  1. /theme  ->  Jack & Jill"
case "${TERM_PROGRAM:-}" in
  Apple_Terminal) echo "  2. Terminal is already wearing it (new windows too)" ;;
  iTerm.app)      echo "  2. iTerm2: Settings > Profiles > Colors > Import  ->  $DEST/dist/iterm2/" ;;
  ghostty)        echo "  2. Ghostty: add  config-file = $DEST/dist/ghostty/jack-and-jill-dark  to your config" ;;
  WezTerm)        echo "  2. WezTerm: return the table in $DEST/dist/wezterm/jack-and-jill-dark.lua as your colors" ;;
  *)              echo "  2. Your terminal's config is in $DEST/dist/ (ghostty, iterm2, kitty, alacritty, wezterm, vscode)" ;;
esac
echo "  3. exec zsh   (or open a new tab) for the shell palette"
