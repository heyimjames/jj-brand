#!/bin/sh
# The ground, in one place: which one is on, why, and how to change it.
#
#   jj-ground.sh              flip to the other ground and PIN it
#   jj-ground.sh cycle        auto -> dark -> light -> auto   (what the Dock does)
#   jj-ground.sh auto         follow the system appearance from now on
#   jj-ground.sh dark|light   pin one
#   jj-ground.sh sync         apply the mode; silent no-op if already right
#
# Claude Code's own `theme` setting accepts "auto", but it resolves to a BUILT-IN
# theme, so it cannot auto-switch between two custom ones. Hence this: the mode
# lives in a file, and `sync` is called on a tick by the cursor agent, which
# already has permission to drive Terminal. Rewriting the theme file is what
# makes a running Claude Code session repaint, so an appearance change reaches
# every open session without anyone touching anything.
set -e
D=$(cd "$(dirname "$0")" && pwd)
MODEF="$D/.ground-mode"
ACTIVE="$HOME/.claude/themes/jack-and-jill.json"

mode() { if [ -f "$MODEF" ]; then cat "$MODEF"; else echo auto; fi; }
system_ground() {
  # read natively, no subprocess of its own inside the agent's tick loop
  if osascript -e 'tell application "System Events" to tell appearance preferences to get dark mode' 2>/dev/null | /usr/bin/grep -q true
  then echo dark; else echo light; fi
}
current_ground() {
  if [ -f "$ACTIVE" ] && /usr/bin/grep -q '"base": *"light-ansi"' "$ACTIVE"
  then echo light; else echo dark; fi
}
target_ground() {
  case "$(mode)" in
    auto) system_ground ;;
    dark) echo dark ;;
    light) echo light ;;
    *) system_ground ;;
  esac
}

apply() {   # $1 = dark|light
  GROUND="$1"
  PLAN=$("$D/jj-toggle.sh" plan "$GROUND")
  MODE=$(printf '%s' "$PLAN" | cut -d'|' -f1)
  LABEL=$(printf '%s' "$PLAN" | cut -d'|' -f2)
  CURSOR=$(printf '%s' "$PLAN" | cut -d'|' -f3)
  IX=$(printf '%s' "$PLAN" | cut -d'|' -f4)
  R=$(printf '%d' "0x$(printf '%s' "$CURSOR" | cut -c2-3)")
  G=$(printf '%d' "0x$(printf '%s' "$CURSOR" | cut -c4-5)")
  B=$(printf '%d' "0x$(printf '%s' "$CURSOR" | cut -c6-7)")

  osascript <<OS
tell application "Terminal"
  set names to name of every settings set
  set found to missing value
  -- EXACT first. Re-importing a .terminal file does not replace a profile of
  -- the same name, it appends " 1", so a contains-match can pick a superseded
  -- copy depending on list order. The exact canonical name is the only
  -- deterministic answer; contains is the fallback for a renamed profile.
  repeat with cand in {"Jack & Jill $LABEL", "Jack-and-Jill-$LABEL"}
    repeat with n in names
      if (n as text) is (cand as text) then set found to (n as text)
    end repeat
    if found is not missing value then exit repeat
  end repeat
  if found is missing value then
    repeat with n in names
      set nt to n as text
      if nt contains "Jack" and nt contains "$LABEL" then set found to nt
    end repeat
  end if
  if found is missing value then
    do shell script "open " & quoted form of "$D/Jack-and-Jill-$LABEL.terminal"
    repeat 24 times
      delay 0.5
      set names to name of every settings set
      repeat with n in names
        set nt to n as text
        if nt contains "Jack" and nt contains "$LABEL" then set found to nt
      end repeat
      if found is not missing value then exit repeat
    end repeat
  end if
  if found is missing value then error "no Jack & Jill $LABEL profile installed"
  set targetSet to settings set found
  set default settings to targetSet
  set startup settings to targetSet
  repeat with w in windows
    try
      repeat with t in tabs of w
        set current settings of t to targetSet
        set cursor color of t to {$((R * 257)), $((G * 257)), $((B * 257))}
      end repeat
    end try
  end repeat
end tell
OS
  # commit-last: a terminal that refused to change leaves Claude Code alone
  "$D/jj-toggle.sh" commit "$MODE" "$IX" >/dev/null
  printf '%s' "$LABEL"
}

case "${1:-flip}" in
  cycle)
    case "$(mode)" in
      auto)  NEW=dark ;;
      dark)  NEW=light ;;
      light) NEW=auto ;;
      *)     NEW=auto ;;
    esac
    printf '%s\n' "$NEW" > "$MODEF"
    T=$(target_ground); L=$(apply "$T")
    if [ "$NEW" = auto ]; then printf 'Auto, following the system: %s\n' "$L"
    else printf 'Pinned %s\n' "$L"; fi ;;
  auto|dark|light)
    printf '%s\n' "$1" > "$MODEF"
    T=$(target_ground); L=$(apply "$T")
    if [ "$1" = auto ]; then printf 'Auto, following the system: %s\n' "$L"
    else printf 'Pinned %s\n' "$L"; fi ;;
  sync)
    T=$(target_ground)
    [ "$T" = "$(current_ground)" ] && exit 0
    L=$(apply "$T"); printf 'System changed: %s\n' "$L" ;;
  flip)
    # a plain flip pins what it lands on, or the next sync would undo it
    if [ "$(current_ground)" = light ]; then NEW=dark; else NEW=light; fi
    printf '%s\n' "$NEW" > "$MODEF"
    L=$(apply "$NEW"); printf 'Pinned %s\n' "$L" ;;
  mode) mode ;;
  *) echo "usage: jj-ground.sh [cycle|auto|dark|light|sync|flip|mode]" >&2; exit 2 ;;
esac
