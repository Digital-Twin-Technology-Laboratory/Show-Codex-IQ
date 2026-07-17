#!/bin/bash

set -euo pipefail

if [[ $# -ne 3 ]]; then
    echo "Usage: $0 /path/to/Codex\ Toolbox.app /path/to/output.dmg 'Volume Name'" >&2
    exit 2
fi

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
OUTPUT_DMG="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"
VOL_NAME="$3"
BACKGROUND_SOURCE="$ROOT_DIR/design/dmg/CodexToolbox-dmg-background.png"
GUIDE_SOURCE="$ROOT_DIR/docs/distribution/DMG安装与升级说明.txt"
BUILD_DIR="$(mktemp -d "${TMPDIR%/}/CodexToolbox-package-dmg.XXXXXX")"
STAGE_DIR="$BUILD_DIR/dmg-root"
RW_DMG="$BUILD_DIR/CodexToolbox-installer-rw.dmg"
BUILD_VOL_NAME="Codex Toolbox Build $$"
DEVICE=""

cleanup() {
    if [[ -n "$DEVICE" ]]; then
        diskutil eject "$DEVICE" >/dev/null 2>&1 || true
    fi
    rm -rf "$BUILD_DIR"
}
trap cleanup EXIT

test -d "$APP_PATH"
test -f "$BACKGROUND_SOURCE"
test -f "$GUIDE_SOURCE"

mkdir -p "$STAGE_DIR/.background" "$(dirname "$OUTPUT_DMG")"
ditto --noextattr --noqtn --noacl "$APP_PATH" "$STAGE_DIR/Codex Toolbox.app"
ln -s /Applications "$STAGE_DIR/Applications"
ditto --noextattr --noqtn --noacl "$GUIDE_SOURCE" "$STAGE_DIR/DMG安装与升级说明.txt"
ditto --noextattr --noqtn --noacl \
    "$BACKGROUND_SOURCE" \
    "$STAGE_DIR/.background/CodexToolbox-dmg-background.png"
codesign --verify --deep --strict --verbose=2 "$STAGE_DIR/Codex Toolbox.app"

rm -f "$OUTPUT_DMG" "$OUTPUT_DMG.sha256"
diskutil image create blank \
    --format RAW \
    --size 200m \
    --volumeName "$BUILD_VOL_NAME" \
    --fs APFS \
    "$RW_DMG"

ATTACH_OUTPUT="$(diskutil image attach "$RW_DMG")"
DEVICE="$(printf '%s\n' "$ATTACH_OUTPUT" | awk '/GUID_partition_scheme/ {print $1; exit}')"
MOUNT_DIR="$(printf '%s\n' "$ATTACH_OUTPUT" | awk -F '\t' '/\/Volumes\// {print $NF; exit}')"
MOUNT_DIR="${MOUNT_DIR#${MOUNT_DIR%%[![:space:]]*}}"

if [[ -z "$DEVICE" || -z "$MOUNT_DIR" ]]; then
    echo "Unable to determine mounted DMG device or volume" >&2
    exit 1
fi

ditto --noextattr --noqtn --noacl "$STAGE_DIR" "$MOUNT_DIR"
sleep 1

/usr/bin/osascript <<APPLESCRIPT
tell application "Finder"
    tell disk "$BUILD_VOL_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set pathbar visible of container window to false
        set sidebar width of container window to 0
        set the bounds of container window to {120, 120, 780, 540}

        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 104
        set text size of viewOptions to 13
        set background picture of viewOptions to file ".background:CodexToolbox-dmg-background.png"

        set position of item "Codex Toolbox.app" of container window to {165, 218}
        set position of item "Applications" of container window to {495, 218}

        set selection of application "Finder" to {}
        update without registering applications
        delay 2
        close container window
    end tell
end tell
APPLESCRIPT

test -f "$MOUNT_DIR/.DS_Store"
sync
diskutil rename "$MOUNT_DIR" "$VOL_NAME" >/dev/null
diskutil eject "$DEVICE"
DEVICE=""

diskutil image create from \
    --format UDZO \
    "$RW_DMG" \
    "$OUTPUT_DMG"

echo "Created: $OUTPUT_DMG"
