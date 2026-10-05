#!/bin/bash
# Rebuild the checked-in Apple Silicon frameworks from pinned upstream sources.
set -euo pipefail

script_dir=$(cd "$(dirname "$0")" && pwd)
frameworks_dir=$(cd "$script_dir/.." && pwd)
cache_dir=${NATIVE_FRAMEWORK_CACHE:-"$frameworks_dir/../.work/native-frameworks"}
output_dir=${NATIVE_FRAMEWORK_OUTPUT:-"$frameworks_dir"}
mkdir -p "$cache_dir" "$output_dir" "$cache_dir/products"
cache_dir=$(cd "$cache_dir" && pwd)
output_dir=$(cd "$output_dir" && pwd)

fetch_source() {
    local name=$1 url=$2 revision=$3 directory=$4
    if [[ ! -d "$directory/.git" ]]; then
        mkdir -p "$directory"
        git -C "$directory" init -q
        git -C "$directory" remote add origin "$url"
        git -C "$directory" fetch --depth 1 origin "$revision"
        git -C "$directory" checkout --detach FETCH_HEAD
    fi
    if [[ $(git -C "$directory" rev-parse HEAD) != "$revision" ]]; then
        echo "Wrong revision in $directory; use a fresh NATIVE_FRAMEWORK_CACHE." >&2
        exit 1
    fi
    if [[ -f "$script_dir/patches/$name.patch" ]]; then
        if git -C "$directory" apply --check "$script_dir/patches/$name.patch" 2>/dev/null; then
            git -C "$directory" apply "$script_dir/patches/$name.patch"
        else
            # A repeat run may already contain exactly the recorded patch.
            git -C "$directory" apply --reverse --check "$script_dir/patches/$name.patch"
        fi
    fi
    # Reject unrelated edits in cached sources instead of silently rebuilding a
    # different library from the documented revision and compatibility patch.
    local actual_diff="$cache_dir/$name-source.diff"
    git -C "$directory" diff --binary > "$actual_diff"
    if [[ -f "$script_dir/patches/$name.patch" ]]; then
        cmp "$script_dir/patches/$name.patch" "$actual_diff"
    elif [[ -s "$actual_diff" ]]; then
        echo "Unexpected source modifications in $directory; use a fresh cache." >&2
        exit 1
    fi
}

fetch_source FeedbackReporter https://github.com/tcurdt/feedbackreporter.git 92230feade69e1298cd5a8cbc0c8ddd2dc939934 "$cache_dir/FeedbackReporter"
fetch_source ShortcutRecorder https://github.com/Kentzo/ShortcutRecorder.git 7f29c1820861541c4b59890110e8147526f9ac92 "$cache_dir/ShortcutRecorder"
fetch_source UniversalDetector https://github.com/MacPaw/universal-detector.git 4eb832d999628edcd3d134e46bd35357c8c99a85 "$cache_dir/UniversalDetector"
fetch_source Growl https://github.com/growl/growl.git c01798eefb52ff95dd1e548ad5dd24e00f59ef20 "$cache_dir/Growl"
fetch_source ISO8601DateFormatter https://github.com/boredzo/iso-8601-date-formatter.git b1d40da20608ca4613994628bc948207ccfcdfae "$cache_dir/Growl/external_dependencies/iso8601parser"
fetch_source CocoaAsyncSocket https://github.com/robbiehanson/CocoaAsyncSocket.git 5ddba5e72f38e56010dbfac08b44478ee5000c0c "$cache_dir/Growl/external_dependencies/cocoaasyncsocket"
fetch_source OCMock https://github.com/erikdoe/ocmock.git 2c0bfd373289f4a7716db5d6db471640f91a6507 "$cache_dir/OCMock"

build_framework() {
    local name=$1 project=$2 scheme=$3
    echo "Building $name for arm64 (macOS 12+)"
    if ! xcodebuild -project "$project" -scheme "$scheme" \
        -derivedDataPath "$cache_dir/$name-derived" -configuration Release \
        ARCHS=arm64 VALID_ARCHS=arm64 MACOSX_DEPLOYMENT_TARGET=12.0 SDKROOT=macosx \
        CODE_SIGNING_ALLOWED=NO GCC_VERSION=com.apple.compilers.llvm.clang.1_0 \
        GCC_ENABLE_OBJC_GC=unsupported GCC_TREAT_WARNINGS_AS_ERRORS=NO \
        CONFIGURATION_BUILD_DIR="$cache_dir/products" build > "$cache_dir/$name-build.log" 2>&1; then
        tail -80 "$cache_dir/$name-build.log" >&2
        exit 1
    fi
}

build_framework FeedbackReporter "$cache_dir/FeedbackReporter/FeedbackReporter.xcodeproj" FeedbackReporter
build_framework ShortcutRecorder "$cache_dir/ShortcutRecorder/ShortcutRecorder.xcodeproj" ShortcutRecorder.framework
build_framework UniversalDetector "$cache_dir/UniversalDetector/UniversalDetector.xcodeproj" UniversalDetector
build_framework Growl "$cache_dir/Growl/Growl.xcodeproj" Growl.framework
build_framework OCMock "$cache_dir/OCMock/Source/OCMock.xcodeproj" OCMock

sparkle_archive="$cache_dir/Sparkle-1.27.3.tar.xz"
if [[ ! -f "$sparkle_archive" ]]; then
    curl --fail --location https://github.com/sparkle-project/Sparkle/releases/download/1.27.3/Sparkle-1.27.3.tar.xz -o "$sparkle_archive"
fi
printf '%s  %s\n' b4c70198aba86a65dc04550fbd0a97243a9ba3b98d73d138c877347f27920952 "$sparkle_archive" | shasum -a 256 -c -
mkdir -p "$cache_dir/sparkle"
tar -xJf "$sparkle_archive" -C "$cache_dir/sparkle"

# Replace complete bundles so Intel-only helper tools and old signatures cannot linger.
python3 "$script_dir/install.py" "$cache_dir" "$output_dir"
for name in FeedbackReporter ShortcutRecorder UniversalDetector Growl OCMock Sparkle; do
    xcrun lipo -verify_arch arm64 "$output_dir/$name.framework/$name"
done
echo "Native frameworks ready in $output_dir"
