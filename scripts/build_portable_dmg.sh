#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "build_portable_dmg.sh is retained as a compatibility alias; using the verified Xcode archive workflow." >&2
exec "$ROOT_DIR/scripts/build_dmg.sh"
