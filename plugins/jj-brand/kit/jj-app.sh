#!/bin/sh
# What the Dock app does when clicked. Kept out of the bundle so the bundle's
# executable can be a real Mach-O binary: LaunchServices cannot read an
# architecture out of a shell script, assumes x86_64, and asks for Rosetta.
OUT=$("$HOME/.claude/themes/terminal-app/jj-ground.sh" cycle 2>&1)
if [ $? -ne 0 ]; then
  JJOUT="$OUT" /usr/bin/osascript -e 'display alert "Jack & Jill" message (system attribute "JJOUT") as warning'
  exit 1
fi
JJOUT="$OUT" /usr/bin/osascript -e 'display notification (system attribute "JJOUT") with title "Jack & Jill"'
