#!/bin/sh
# Rebuild the icon and make macOS actually show it.
#
# Replacing the icns in place is not enough and never was. The Dock keeps its
# own rendered tiles in com.apple.dock.iconcache, and it is keyed on the bundle,
# not on the file's mtime, so a correct icns sits there being ignored. Three
# things together are what works: delete the bundle, delete that cache, and put
# it back with a bumped CFBundleVersion so LaunchServices re-reads it.
#
# A glob will not find that cache from zsh (an unmatched glob is an error, not
# an empty list, so the rm never runs); find does.
set -e
D=$(cd "$(dirname "$0")" && pwd)
APP="$HOME/Applications/Jack & Jill.app"
LSR=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
VER="${1:-$(date +%Y.%m.%d.%H%M)}"

/usr/bin/python3 "$D/gen-icon.py"
TMP=$(mktemp -d)/jj.iconset; mkdir -p "$TMP"
for pair in 16:icon_16x16 32:icon_16x16@2x 32:icon_32x32 64:icon_32x32@2x \
            128:icon_128x128 256:icon_128x128@2x 256:icon_256x256 \
            512:icon_256x256@2x 512:icon_512x512; do
  SZ=${pair%%:*}; NM=${pair##*:}
  sips -z "$SZ" "$SZ" "$D/icon-light.png" --out "$TMP/$NM.png" >/dev/null
done
cp "$D/icon-light.png" "$TMP/icon_512x512@2x.png"
iconutil -c icns "$TMP" -o "$D/applet.icns"

"$LSR" -u "$APP" 2>/dev/null || true
rm -rf "$APP"
killall Dock 2>/dev/null || true
find "$(getconf DARWIN_USER_CACHE_DIR)" -maxdepth 2 \
     \( -name 'com.apple.iconservices*' -o -name '*.iconcache' \) -exec rm -rf {} + 2>/dev/null || true

mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cat > "$APP/Contents/MacOS/jj" <<'APPSH'
#!/bin/sh
OUT=$("$HOME/.claude/themes/terminal-app/jj-ground.sh" cycle 2>&1)
if [ $? -ne 0 ]; then
  JJOUT="$OUT" /usr/bin/osascript -e 'display alert "Jack & Jill" message (system attribute "JJOUT") as warning'
  exit 1
fi
JJOUT="$OUT" /usr/bin/osascript -e 'display notification (system attribute "JJOUT") with title "Jack & Jill"'
APPSH
chmod +x "$APP/Contents/MacOS/jj"
cp "$D/applet.icns" "$APP/Contents/Resources/icon.icns"
printf 'APPL????' > "$APP/Contents/PkgInfo"
VER="$VER" /usr/bin/python3 - "$APP/Contents/Info.plist" <<'INFOPY'
import os, plistlib, sys
v = os.environ["VER"]
plistlib.dump({
    "CFBundleName": "Jack & Jill", "CFBundleDisplayName": "Jack & Jill",
    "CFBundleExecutable": "jj", "CFBundleIconFile": "icon",
    "CFBundleIdentifier": "ai.jackandjill.terminal-ground",
    "CFBundleInfoDictionaryVersion": "6.0", "CFBundlePackageType": "APPL",
    "CFBundleShortVersionString": v, "CFBundleVersion": v,
    "LSMinimumSystemVersion": "11.0", "LSUIElement": True,
    "NSHighResolutionCapable": True,
}, open(sys.argv[1], "wb"))
INFOPY
codesign --force --deep -s - "$APP" >/dev/null 2>&1 || true
"$LSR" -f "$APP"
killall Dock 2>/dev/null || true
echo "icon rebuilt and the Dock's cache cleared (bundle version $VER)"
