#!/bin/sh
# Jack & Jill for the terminal — the whole thing, in one command.
#
#   curl -fsSL https://raw.githubusercontent.com/heyimjames/jj-brand/main/bootstrap.sh | sh
#
# Read it first if you like; it is short on purpose. What it touches, all backed
# up and all idempotent:
#
#   ~/.claude/themes/            the theme and the terminal kit
#   ~/.claude/settings.json      the theme selection and the status line
#   ~/.zshrc                     one sourced line for the shell palette
#   git --global color.*         only keys you have not already set
#   ~/Applications               the Dock app (skip with --no-extras)
#
# Pass --no-extras to leave out the Dock icon and the flashing cursor.
set -e
REPO=https://github.com/heyimjames/jj-brand.git
EXTRAS=--all
[ "$1" = "--no-extras" ] && EXTRAS=""

say() { printf '%s\n' "$1"; }
say "Jack & Jill for the terminal"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
if command -v git >/dev/null 2>&1; then
  git clone --depth 1 --quiet "$REPO" "$WORK/jj"
else
  say "  git is required"; exit 1
fi
PLUGIN="$WORK/jj/plugins/jj-brand"

# 1. the terminal half: profiles, status line, shell palette, git colours, and
#    the Dock app unless it was declined
sh "$PLUGIN/install.sh" $EXTRAS

# 2. the two pinned grounds, as user themes, so nobody needs the plugin at all
mkdir -p "$HOME/.claude/themes"
cp "$PLUGIN/themes/"*.json "$HOME/.claude/themes/"

# 3. select it, unless a custom theme is already chosen. /theme is then a
#    preference rather than a step in the install.
/usr/bin/python3 - <<'PY'
import json, pathlib, shutil
p = pathlib.Path.home()/".claude/settings.json"
d = json.loads(p.read_text()) if p.exists() else {}
cur = d.get("theme", "")
if cur.startswith("custom:"):
    print(f"  theme: leaving your own choice alone ({cur})")
else:
    if p.exists(): shutil.copy(p, str(p) + ".bak-before-jj")
    d["theme"] = "custom:jack-and-jill"
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(d, indent=2) + "\n")
    print("  theme: selected Jack & Jill")
PY

/usr/bin/python3 "$HOME/.claude/themes/terminal-app/jj-welcome.py" 2>/dev/null || {
  say ""
  say "Done. Restart Claude Code and it is already wearing it."
  say "Open a new terminal tab, or run: exec zsh"
}
