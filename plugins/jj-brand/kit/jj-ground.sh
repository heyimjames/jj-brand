#!/bin/sh
# Flip the ground from a shell (the Dock app does the same thing).
#
# Commit-last, like the app: if Terminal cannot be changed, Claude Code's theme
# file is left alone, so the two can never disagree.
set -e
D=$(cd "$(dirname "$0")" && pwd)
PLAN=$("$D/jj-toggle.sh" plan)
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
  repeat with n in names
    set nt to n as text
    if nt contains "Jack" and nt contains "$LABEL" then set found to nt
  end repeat
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

"$D/jj-toggle.sh" commit "$MODE" "$IX" >/dev/null
printf 'Jack & Jill %s  ground applied to every window, cursor %s\n' "$LABEL" "$CURSOR"
