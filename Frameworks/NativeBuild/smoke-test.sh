#!/bin/bash
# Load actual arm64 libraries and check APIs used by the application and tests.
set -euo pipefail
script_dir=$(cd "$(dirname "$0")" && pwd)
frameworks_dir=${1:-"$script_dir/.."}
frameworks_dir=$(cd "$frameworks_dir" && pwd)
developer_dir=${DEVELOPER_DIR:-$(xcode-select -p)}
smoke_dir=$(mktemp -d "${TMPDIR:-/tmp}/sequelpro-framework-smoke.XXXXXX")
trap 'rm -rf "$smoke_dir"' EXIT
xcrun clang -arch arm64 -mmacosx-version-min=12.0 -fno-objc-arc \
    -Wno-deprecated-declarations -F "$frameworks_dir" \
    -Wl,-rpath,"$developer_dir/Platforms/MacOSX.platform/Developer/Library/Frameworks" \
    -Wl,-rpath,"$developer_dir/Platforms/MacOSX.platform/Developer/usr/lib" \
    -framework Foundation -framework AppKit -framework UniversalDetector \
    -framework ShortcutRecorder -framework FeedbackReporter -framework Growl \
    -framework OCMock "$script_dir/smoke-test.m" \
    -o "$smoke_dir/framework-smoke"
DYLD_FRAMEWORK_PATH="$frameworks_dir" "$smoke_dir/framework-smoke"
