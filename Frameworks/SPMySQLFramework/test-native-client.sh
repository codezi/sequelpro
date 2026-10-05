#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $(basename "$0") /path/to/SPMySQL.framework /path/to/disposable-server.sock" >&2
    exit 1
fi
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FRAMEWORK_DIR="$(cd "$(dirname "$1")" && pwd)"
SMOKE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/spmysql-native-smoke.XXXXXX")"
trap 'rm -rf "$SMOKE_DIR"' EXIT

xcrun lipo -verify_arch arm64 "$FRAMEWORK_DIR/SPMySQL.framework/SPMySQL"
xcrun clang -arch arm64 -mmacosx-version-min=12.0 \
    -F "$FRAMEWORK_DIR" -framework Cocoa -framework SPMySQL \
    "$SCRIPT_DIR/SPMySQL Unit Tests/NativeClientSmoke.m" \
    -o "$SMOKE_DIR/native-client-smoke"
DYLD_FRAMEWORK_PATH="$FRAMEWORK_DIR" "$SMOKE_DIR/native-client-smoke" "$2"
