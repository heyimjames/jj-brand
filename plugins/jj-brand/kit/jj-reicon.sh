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
# A REAL BINARY, not a script. A bundle whose executable is a shell script makes
# macOS ask to install Rosetta: there is no Mach-O header to read an
# architecture from, so LaunchServices assumes x86_64. Built for both, so a
# teammate on Intel gets a native launch too. If clang is missing the script
# stands in and the prompt comes back, which the message says out loud.
if command -v clang >/dev/null 2>&1; then
  clang -arch arm64 -arch x86_64 -O2 -o "$APP/Contents/MacOS/jj" "$D/jj-launcher.c"
else
  echo "  clang not found: falling back to a script executable, which will ask for Rosetta"
  cp "$D/jj-app.sh" "$APP/Contents/MacOS/jj"
fi
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
    "LSRequiresNativeExecution": True,
    "LSArchitecturePriority": ["arm64", "x86_64"],
    "NSHighResolutionCapable": True,
}, open(sys.argv[1], "wb"))
INFOPY
codesign --force --deep -s - "$APP" >/dev/null 2>&1 || true
"$LSR" -f "$APP"
killall Dock 2>/dev/null || true
echo "icon rebuilt and the Dock's cache cleared (bundle version $VER)"
