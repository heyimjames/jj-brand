#!/bin/sh
# Re-import the Terminal profiles after a PALETTE change.
#
# The sixteen ANSI slots are the one part of a profile AppleScript cannot set,
# so a palette change has to go through Terminal's importer — and importing
# does not replace a profile of the same name, it appends " 1". So this imports,
# then renames: the superseded copy steps aside and the fresh one takes the
# canonical name, which keeps every lookup deterministic. The old copy is left
# in the list because AppleScript cannot delete a settings set; remove it in
# Terminal > Settings > Profiles if you want it gone.
set -e
D=$(cd "$(dirname "$0")" && pwd)
for L in Dark Light; do
  CANON="Jack-and-Jill-$L"
  HAD=$(osascript -e "tell application \"Terminal\" to return (exists settings set \"$CANON\")")
  open "$D/Jack-and-Jill-$L.terminal"
  sleep 3
  if [ "$HAD" = "true" ]; then
    osascript <<OS || true
tell application "Terminal"
  if exists settings set "$CANON 1" then
    set name of settings set "$CANON" to "Jack and Jill $L (superseded)"
    set name of settings set "$CANON 1" to "$CANON"
  end if
end tell
OS
    echo "  $CANON refreshed (old copy renamed aside)"
  else
    echo "  $CANON imported"
  fi
done
echo "Now: jj-ground.sh sync   to put the refreshed profile on every window"
