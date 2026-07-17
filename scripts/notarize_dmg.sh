#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/scripts/version.sh"

DMG_PATH="${1:-$ROOT_DIR/dist/Codex-Toolbox-$RELEASE_VERSION-universal.dmg}"
: "${NOTARY_PROFILE:?Set NOTARY_PROFILE to a notarytool keychain profile}"

REQUIRE_DISTRIBUTION_SIGNATURE=1 "$ROOT_DIR/scripts/verify_dmg.sh" "$DMG_PATH"
xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$DMG_PATH"
xcrun stapler validate "$DMG_PATH"
spctl --assess --type open --context context:primary-signature --verbose=4 "$DMG_PATH"

(
    cd "$(dirname "$DMG_PATH")"
    shasum -a 256 "$(basename "$DMG_PATH")" > "$(basename "$DMG_PATH").sha256"
)

echo "Signed, notarized, and stapled DMG is ready: $DMG_PATH"
