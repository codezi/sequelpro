#!/bin/bash
# Verify the app and every embedded Mach-O, including framework helper tools.
set -euo pipefail

app=${1:?Usage: verify-native.sh /path/to/Sequel Pro.app}
if [[ ! -d "$app/Contents/MacOS" ]]; then
    echo "Not an application bundle: $app" >&2
    exit 1
fi

if [[ -e "$app/Contents/Frameworks/Sparkle.framework" ]] ||
   /usr/bin/plutil -extract SUFeedURL raw "$app/Contents/Info.plist" >/dev/null 2>&1; then
    echo "The retired upstream updater is still present in $app" >&2
    exit 1
fi

count=0
while IFS= read -r -d '' binary; do
    description=$(/usr/bin/file -b "$binary")
    [[ "$description" == *Mach-O* ]] || continue
    /usr/bin/lipo -verify_arch arm64 "$binary"
    # A portable app must not depend on the build machine's Homebrew libraries.
    if /usr/bin/otool -L "$binary" | /usr/bin/grep -Eq '^[[:space:]]+(/opt/homebrew/|/usr/local/|/Users/|/private/tmp/|/tmp/)'; then
        echo "Non-portable dependency in $binary" >&2
        /usr/bin/otool -L "$binary" >&2
        exit 1
    fi
    printf 'arm64: %s\n' "${binary#"$app"/}"
    count=$((count + 1))
done < <(/usr/bin/find "$app" -type f -print0)

if [[ "$count" -eq 0 ]]; then
    echo "No Mach-O executables found in $app" >&2
    exit 1
fi
/usr/bin/codesign --verify --deep --strict "$app"
printf 'Verified %s native binaries and the app signature.\n' "$count"
