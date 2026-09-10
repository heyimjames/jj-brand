#!/usr/bin/env python3
"""Every other place the palette has to land, generated from palette-data.json.

One source, many syntaxes. A teammate on Ghostty, iTerm2, WezTerm, Kitty or
Alacritty gets the same sixteen slots, so the Claude Code theme's `ansi:` values
resolve to the brand for them too. Anything hand-copied would drift the moment
brand.ts changed.
"""
import json, plistlib
from pathlib import Path

D = Path(__file__).resolve().parent
DIST = D / "dist"
data = json.loads((D / "palette-data.json").read_text())
SLOTS = ["black","red","green","yellow","blue","magenta","cyan","white",
         "blackBright","redBright","greenBright","yellowBright",
         "blueBright","magentaBright","cyanBright","whiteBright"]

def rgb(h): return tuple(int(h[i:i+2], 16) for i in (1, 3, 5))

GROUNDS = {}
for slug, t in data.items():
    label = "Dark" if t["base"] == "dark-ansi" else "Light"
    theme = t["theme"]
    sel = theme["selectionBg"]
    GROUNDS[label] = {
        "slots": t["slots"],
        "bg": t["ground"],
        "fg": t["slots"]["white"] if label == "Dark" else t["slots"]["black"],
        "bold": t["slots"]["whiteBright"] if label == "Dark" else t["slots"]["black"],
        "cursor": json.loads((D / "cursors.json").read_text())["real"][0]["hex"],
        "sel": "#%02x%02x%02x" % tuple(int(x) for x in sel[4:-1].split(",")),
    }

def write(rel, text):
    p = DIST / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(text)
    return p

for label, G in GROUNDS.items():
    s, low = G["slots"], label.lower()

    # ---------------------------------------------------------------- Ghostty
    lines = [f"# Jack & Jill {label}", f"background = {G['bg']}",
             f"foreground = {G['fg']}", f"bold-is-bright = false",
             f"cursor-color = {G['cursor']}",
             f"selection-background = {G['sel']}",
             f"selection-foreground = {G['fg']}"]
    for i, n in enumerate(SLOTS):
        lines.append(f"palette = {i}={s[n]}")
    write(f"ghostty/jack-and-jill-{low}", "\n".join(lines) + "\n")

    # ---------------------------------------------------------------- Kitty
    k = [f"# Jack & Jill {label}", f"background {G['bg']}", f"foreground {G['fg']}",
         f"cursor {G['cursor']}", f"selection_background {G['sel']}",
         f"selection_foreground {G['fg']}"]
    for i, n in enumerate(SLOTS):
        k.append(f"color{i} {s[n]}")
    write(f"kitty/jack-and-jill-{low}.conf", "\n".join(k) + "\n")

    # ---------------------------------------------------------------- Alacritty
    a = [f"# Jack & Jill {label}", "[colors.primary]",
         f'background = "{G["bg"]}"', f'foreground = "{G["fg"]}"',
         "", "[colors.cursor]", f'cursor = "{G["cursor"]}"', f'text = "{G["bg"]}"',
         "", "[colors.selection]", f'background = "{G["sel"]}"', f'text = "{G["fg"]}"', ""]
    for tier, off in (("normal", 0), ("bright", 8)):
        a.append(f"[colors.{tier}]")
        for n in SLOTS[off:off+8]:
            a.append(f'{n.replace("Bright","")} = "{s[n]}"')
        a.append("")
    write(f"alacritty/jack-and-jill-{low}.toml", "\n".join(a))

    # ---------------------------------------------------------------- WezTerm
    ansi = ", ".join(f'"{s[n]}"' for n in SLOTS[:8])
    brights = ", ".join(f'"{s[n]}"' for n in SLOTS[8:])
    write(f"wezterm/jack-and-jill-{low}.lua", f'''-- Jack & Jill {label}
return {{
  foreground = "{G['fg']}",
  background = "{G['bg']}",
  cursor_bg = "{G['cursor']}",
  cursor_fg = "{G['bg']}",
  cursor_border = "{G['cursor']}",
  selection_bg = "{G['sel']}",
  selection_fg = "{G['fg']}",
  ansi = {{ {ansi} }},
  brights = {{ {brights} }},
}}
''')

    # ---------------------------------------------------------------- iTerm2
    def comp(h):
        r, g, b = rgb(h)
        return {"Color Space": "sRGB", "Red Component": r/255,
                "Green Component": g/255, "Blue Component": b/255}
    it = {f"Ansi {i} Color": comp(s[n]) for i, n in enumerate(SLOTS)}
    it.update({"Background Color": comp(G["bg"]), "Foreground Color": comp(G["fg"]),
               "Bold Color": comp(G["bold"]), "Cursor Color": comp(G["cursor"]),
               "Cursor Text Color": comp(G["bg"]), "Selection Color": comp(G["sel"]),
               "Selected Text Color": comp(G["fg"]),
               "Link Color": comp(s["blue"]), "Badge Color": comp(s["redBright"])})
    p = DIST / f"iterm2/Jack & Jill {label}.itermcolors"
    p.parent.mkdir(parents=True, exist_ok=True)
    with open(p, "wb") as fh:
        plistlib.dump(it, fh, fmt=plistlib.FMT_XML)

    # ------------------------------------------------- VS Code / Cursor snippet
    vs = {"workbench.colorCustomizations": {
        "terminal.background": G["bg"], "terminal.foreground": G["fg"],
        "terminalCursor.background": G["bg"], "terminalCursor.foreground": G["cursor"],
        "terminal.selectionBackground": G["sel"],
        # VS Code puts "Bright" FIRST (terminal.ansiBrightBlack), which the
        # slot names do not, so the name is rebuilt rather than transformed.
        **{("terminal.ansiBright" + n[:-6].capitalize()) if n.endswith("Bright")
           else ("terminal.ansi" + n.capitalize()): s[n]
           for n in SLOTS},
    }}
    write(f"vscode/settings-{low}.json", json.dumps(vs, indent=2) + "\n")

# ------------------------------------------------------------------ the shell
# BAT_THEME=ansi and delta's syntax-theme=ansi are the whole trick: both have a
# mode that draws with the terminal's own sixteen slots, so they inherit the
# brand exactly instead of needing a generated theme file each.
write("shell/jj-shell-colors.sh", '''# Jack & Jill for the shell. Source from ~/.zshrc:
#   [ -f ~/.claude/themes/terminal-app/dist/shell/jj-shell-colors.sh ] && . ~/.claude/themes/terminal-app/dist/shell/jj-shell-colors.sh
#
# Every value here is an ANSI SLOT NUMBER, never a hex, so all of it follows the
# terminal profile and flips ground with it. Directories take Periwinkle, links
# Sky, executables Emerald, archives Coral, media Orchid, a broken link Flame.

# GNU ls / eza / most modern tools
export LS_COLORS='di=34:ln=36:so=35:pi=33:ex=32:bd=33;1:cd=33:su=31:sg=31:tw=34:ow=34:or=31;1:mi=31:\
*.tar=91:*.tgz=91:*.zip=91:*.gz=91:*.bz2=91:*.xz=91:*.7z=91:*.dmg=91:\
*.png=95:*.jpg=95:*.jpeg=95:*.gif=95:*.svg=95:*.mp4=95:*.mov=95:*.webm=95:*.pdf=95:\
*.ts=37:*.tsx=37:*.js=37:*.jsx=37:*.json=93:*.md=93:*.css=37:*.html=37:\
*.sh=32:*.zsh=32:*.py=32'
export EZA_COLORS="$LS_COLORS"

# BSD ls, which macOS ships: eleven pairs, dir blue, link cyan, exec green
export LSCOLORS='exgxcxdxbxegedabagacad'
export CLICOLOR=1

# bat and delta both have an "ansi" mode that draws with the terminal's slots
export BAT_THEME=ansi

# fzf, by slot number so it follows the ground
export FZF_DEFAULT_OPTS="--color=fg:-1,bg:-1,hl:4,fg+:15,bg+:-1,hl+:12,\\
info:3,prompt:9,pointer:9,marker:2,spinner:5,header:8,border:8"

# less, so man pages stop being blue-on-black
export LESS_TERMCAP_md=$'\\033[91m'   # headings: Coral
export LESS_TERMCAP_us=$'\\033[36m'   # underline: Sky
export LESS_TERMCAP_so=$'\\033[33m'   # search hit: Honey
export LESS_TERMCAP_me=$'\\033[0m'
export LESS_TERMCAP_ue=$'\\033[0m'
export LESS_TERMCAP_se=$'\\033[0m'
''')

write("shell/jj-git-colors.sh", '''#!/bin/sh
# Points git's own colours at the sixteen slots. Idempotent, and it never
# overwrites a key you have already set: run with --force to overrule that.
set -e
FORCE=0
[ "$1" = "--force" ] && FORCE=1
set_if_absent() {
  if [ "$FORCE" -eq 0 ] && git config --global --get "$1" >/dev/null 2>&1; then
    echo "  kept    $1 = $(git config --global --get "$1")"
  else
    git config --global "$1" "$2"; echo "  set     $1 = $2"
  fi
}
echo "git colours:"
set_if_absent color.ui auto
set_if_absent color.diff.new green
set_if_absent color.diff.old red
set_if_absent color.diff.frag cyan
set_if_absent color.diff.meta yellow
set_if_absent color.diff.commit "brightred"
set_if_absent color.status.added green
set_if_absent color.status.changed yellow
set_if_absent color.status.untracked "brightblack"
set_if_absent color.status.branch "green"
set_if_absent color.branch.current "green"
set_if_absent color.branch.remote "cyan"
set_if_absent color.decorate.branch "green"
set_if_absent color.decorate.HEAD "brightred"
set_if_absent color.decorate.tag "magenta"
# delta, if it is installed: its "ansi" syntax theme draws with the slots
if command -v delta >/dev/null 2>&1; then
  set_if_absent delta.syntax-theme ansi
  set_if_absent delta.hunk-header-style "line-number syntax"
  set_if_absent delta.line-numbers true
fi
''')

print("wrote:")
for p in sorted(DIST.rglob("*")):
    if p.is_file():
        print("  ", p.relative_to(DIST))
