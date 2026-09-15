#!/bin/sh
# Take it all back off.
#
#   curl -fsSL https://raw.githubusercontent.com/heyimjames/jj-brand/main/uninstall.sh | sh
#
# Anything with a backup is RESTORED rather than edited, because an installer
# that can only add is half a tool. Two things it cannot do and says so instead:
# AppleScript cannot delete a Terminal profile, and git's colour names are
# ordinary settings that may have been yours already.
# Testing this against a throwaway HOME does NOT sandbox it: launchctl and
# defaults address the user domain, not $HOME, so a rehearsal still stops the
# real agent and removes the real Dock tile. There is no safe dry run; read it
# instead.
set -e
say() { printf '  %s\n' "$1"; }
KIT="$HOME/.claude/themes/terminal-app"
echo "Removing Jack & Jill for the terminal"

# 1. the cursor agent
LABEL=com.jackandjill.cursorcycle
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null && say "cursor agent stopped" || true
rm -f "$HOME/Library/LaunchAgents/$LABEL.plist"

# 2. the Dock app and its tile
APP="$HOME/Applications/Jack & Jill.app"
if [ -d "$APP" ]; then
  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -u "$APP" 2>/dev/null || true
  rm -rf "$APP"
  say "Dock app removed"
fi
rm -rf "$HOME/Applications/Jack & Jill Theme.app" 2>/dev/null || true
/usr/bin/python3 - <<'PY' 2>/dev/null || true
import plistlib, subprocess
d = plistlib.loads(subprocess.run(["defaults","export","com.apple.dock","-"],
                                  capture_output=True, check=True).stdout)
lbl = lambda e: e.get("tile-data", {}).get("file-data", {}).get("_CFURLString") or ""
apps = [e for e in d.get("persistent-apps", []) if "Jack" not in lbl(e)]
if len(apps) != len(d.get("persistent-apps", [])):
    d["persistent-apps"] = apps
    open("/tmp/jj-dock-un.plist","wb").write(plistlib.dumps(d))
    subprocess.run(["defaults","import","com.apple.dock","/tmp/jj-dock-un.plist"], check=True)
    print("  Dock tile removed")
PY
killall Dock 2>/dev/null || true

# 3. settings.json: restore the backup, or drop just our keys
/usr/bin/python3 - <<'PY'
import json, pathlib, shutil
p = pathlib.Path.home()/".claude/settings.json"
bak = pathlib.Path(str(p) + ".bak-before-jj")
if bak.exists():
    shutil.copy(bak, p); print("  settings.json restored from its backup")
elif p.exists():
    d = json.loads(p.read_text()); changed = False
    if str(d.get("theme","")).startswith("custom:jack-and-jill"):
        d.pop("theme"); changed = True
    sl = d.get("statusLine", {})
    if isinstance(sl, dict) and "jj_statusline" in str(sl.get("command","")):
        d.pop("statusLine"); changed = True
    if changed:
        p.write_text(json.dumps(d, indent=2) + "\n"); print("  settings.json: our keys removed")
PY

# 4. the shell block
for RC in "$HOME/.zshrc" "$HOME/.bashrc"; do
  [ -f "$RC" ] || continue
  if [ -f "$RC.bak-before-jj" ]; then
    cp "$RC.bak-before-jj" "$RC"; say "$(basename "$RC") restored from its backup"
  elif grep -q "jj-shell-colors" "$RC" 2>/dev/null; then
    /usr/bin/python3 - "$RC" <<'PY'
import re, sys
p = sys.argv[1]; s = open(p).read()
s = re.sub(r"\n# --- Jack & Jill terminal palette -+\n.*?\n# -+\n", "\n", s, flags=re.S)
open(p, "w").write(s)
print(f"  {p.split('/')[-1]}: palette block removed")
PY
  fi
done

# 5. the themes and the kit
rm -f "$HOME/.claude/themes/jack-and-jill.json" \
      "$HOME/.claude/themes/jack-and-jill-dark.json" \
      "$HOME/.claude/themes/jack-and-jill-light.json"
rm -rf "$KIT"
say "themes and kit removed"

echo
echo "Two things left for you, because nothing can do them for you:"
echo "  Terminal > Settings > Profiles — remove Jack-and-Jill-Dark and -Light,"
echo "  and set whichever profile you used before as Default."
echo "  git's colour settings were left alone: they are ordinary names and may"
echo "  have been yours already. Undo with: git config --global --unset color.ui"
