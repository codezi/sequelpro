#!/bin/bash
set -euo pipefail
script_dir=$(cd "$(dirname "$0")" && pwd)
repo_dir=$(cd "$script_dir/../.." && pwd)
products_dir=${1:-"$repo_dir/.build/DerivedData/Build/Products/Release"}
products_dir=$(cd "$products_dir" && pwd)
smoke_dir=$(mktemp -d "${TMPDIR:-/tmp}/sequelpro-tracking-smoke.XXXXXX")
trap 'rm -rf "$smoke_dir"' EXIT
xcrun clang -arch arm64 -mmacosx-version-min=12.0 -fno-objc-arc -Wno-deprecated-declarations \
    -F "$products_dir" -framework AppKit -framework PSMTabBar \
    "$script_dir/tracking-smoke.m" -o "$smoke_dir/tracking-smoke"
DYLD_FRAMEWORK_PATH="$products_dir" "$smoke_dir/tracking-smoke"
