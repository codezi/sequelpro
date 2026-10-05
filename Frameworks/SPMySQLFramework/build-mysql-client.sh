#!/usr/bin/env bash

#
#  $Id$
#
#  build-mysql-client.sh
#  sequel-pro
#
#  Created by Stuart Connolly (stuconnolly.com)
#  Copyright (c) 2009 Stuart Connolly. All rights reserved.
#
#  Permission is hereby granted, free of charge, to any person
#  obtaining a copy of this software and associated documentation
#  files (the "Software"), to deal in the Software without
#  restriction, including without limitation the rights to use,
#  copy, modify, merge, publish, distribute, sublicense, and/or sell
#  copies of the Software, and to permit persons to whom the
#  Software is furnished to do so, subject to the following
#  conditions:
#
#  The above copyright notice and this permission notice shall be
#  included in all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
#  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
#  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
#  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
#  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
#  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
#  OTHER DEALINGS IN THE SOFTWARE.
#
#  More info at <https://github.com/sequelpro/sequelpro>

# Rebuild the existing MySQL 5.5.56 client ABI for modern macOS.
# CMake 3.x is required by this upstream release (CMake 4 removed its policies).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_VERSION=5.5.56
SOURCE_URL="https://codeload.github.com/mysql/mysql-server/tar.gz/refs/tags/mysql-${SOURCE_VERSION}"
SOURCE_SHA256=deeece396b04bc931fb4c4d3188281b591ea097e47a400ef91242253b199b41b
BUILD_ROOT="${TMPDIR:-/tmp}/sequelpro-mysql-${SOURCE_VERSION}"
OUTPUT_DIR="${SCRIPT_DIR}/MySQL Client Libraries"
ARCHITECTURES="arm64 x86_64"
MIN_MACOS_VERSION="${MACOSX_DEPLOYMENT_TARGET:-12.0}"
CMAKE="${CMAKE:-cmake}"
SOURCE_DIR=""
QUIET=NO

usage() {
    cat <<EOF
Usage: $(basename "$0") [-s pristine_mysql_source] [-a "arm64 x86_64"] [-b build_dir] [-o output_dir] [-q] [-d]

Builds MySQL ${SOURCE_VERSION} with its bundled yaSSL and TaoCrypt libraries.
Defaults to a universal arm64/x86_64 static library for macOS 12 or later,
written to the framework's MySQL Client Libraries directory. The obsolete
32-bit slice is not built. Sources are downloaded and SHA-256 checked unless
-s is given; a supplied source tree is copied before any patches are applied.

Requires Xcode command-line tools and CMake 3.x. Set CMAKE to its executable
path when it is not on PATH. No Homebrew libraries are linked into the result.
Set MACOSX_DEPLOYMENT_TARGET to override the minimum macOS version.
EOF
}

while getopts ':s:a:b:o:qdh' option; do
    case "$option" in
        s) SOURCE_DIR="$OPTARG" ;;
        a) ARCHITECTURES="$OPTARG" ;;
        b) BUILD_ROOT="$OPTARG" ;;
        o) OUTPUT_DIR="$OPTARG" ;;
        q) QUIET=YES ;;
        d) set -x ;;
        h) usage; exit 0 ;;
        *) usage >&2; exit 1 ;;
    esac
done

[[ "$(uname -s)" == Darwin ]] || { echo 'This script requires macOS.' >&2; exit 1; }
CMAKE_VERSION="$("$CMAKE" --version | head -1)"
[[ "$CMAKE_VERSION" == 'cmake version 3.'* ]] || {
    echo "MySQL ${SOURCE_VERSION} requires CMake 3.x; set CMAKE to a CMake 3 executable." >&2
    exit 1
}
SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
C_COMPILER="$(xcrun -f clang)"
CXX_COMPILER="$(xcrun -f clang++)"
JOBS="${JOBS:-$(sysctl -n hw.ncpu 2>/dev/null || echo 4)}"
mkdir -p "$BUILD_ROOT" "$OUTPUT_DIR/include" "$OUTPUT_DIR/lib"
BUILD_ROOT="$(cd "$BUILD_ROOT" && pwd)"
OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd)"
STAGED_SOURCE="$BUILD_ROOT/source"

# A fresh source copy also prevents stale/generated configuration from being
# reused across SDK upgrades. The build products stay in per-architecture dirs.
if [[ -e "$STAGED_SOURCE" ]]; then
    rm -rf "$STAGED_SOURCE"
fi
mkdir -p "$STAGED_SOURCE"
if [[ -n "$SOURCE_DIR" ]]; then
    [[ -f "$SOURCE_DIR/VERSION" && ! -f "$SOURCE_DIR/CMakeCache.txt" ]] || {
        echo '-s must point to a pristine MySQL 5.5.56 source tree.' >&2; exit 1;
    }
    cp -R "$SOURCE_DIR/." "$STAGED_SOURCE/"
else
    ARCHIVE="$BUILD_ROOT/mysql-${SOURCE_VERSION}.tar.gz"
    if [[ ! -f "$ARCHIVE" ]]; then
        curl --fail --location --retry 3 "$SOURCE_URL" -o "$ARCHIVE.part"
        mv "$ARCHIVE.part" "$ARCHIVE"
    fi
    printf '%s  %s\n' "$SOURCE_SHA256" "$ARCHIVE" | shasum -a 256 -c -
    tar -xzf "$ARCHIVE" --strip-components=1 -C "$STAGED_SOURCE"
fi
for version_line in MYSQL_VERSION_MAJOR=5 MYSQL_VERSION_MINOR=5 MYSQL_VERSION_PATCH=56; do
    grep -qx "$version_line" "$STAGED_SOURCE/VERSION" || {
        echo "Source must be MySQL ${SOURCE_VERSION}." >&2; exit 1;
    }
done
for patch_file in "$SCRIPT_DIR/MySQL Client Libraries/Patches/"*.diff; do
    patch --batch -d "$STAGED_SOURCE" -p1 < "$patch_file"
done

LIBRARIES=()
for architecture in $ARCHITECTURES; do
    case "$architecture" in
        arm64|x86_64) ;;
        *) echo "Unsupported architecture: $architecture" >&2; exit 1 ;;
    esac
    ARCH_BUILD="$BUILD_ROOT/build-$architecture"
    # CMake's platform checks are SDK-specific. Reconfigure from a clean build.
    [[ ! -e "$ARCH_BUILD" ]] || rm -rf "$ARCH_BUILD"
    mkdir -p "$ARCH_BUILD/sql/share"
    LOG_FILE="$BUILD_ROOT/$architecture.log"
    echo "Building MySQL ${SOURCE_VERSION} for $architecture (log: $LOG_FILE)"
    if ! (
        "$CMAKE" -S "$STAGED_SOURCE" -B "$ARCH_BUILD" \
            -DCMAKE_OSX_ARCHITECTURES="$architecture" \
            -DCMAKE_OSX_SYSROOT="$SDK_PATH" \
            -DCMAKE_OSX_DEPLOYMENT_TARGET="$MIN_MACOS_VERSION" \
            -DCMAKE_C_COMPILER="$C_COMPILER" \
            -DCMAKE_CXX_COMPILER="$CXX_COMPILER" \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_CXX_FLAGS='-std=c++98 -fno-exceptions -fno-rtti' \
            -DWITHOUT_SERVER=1 -DWITH_SSL=bundled -DWITH_ZLIB=system \
            -DWITH_UNIT_TESTS=0 -DENABLED_LOCAL_INFILE=1 -DENABLE_DTRACE=OFF &&
        "$CMAKE" --build "$ARCH_BUILD" --target mysqlclient --parallel "$JOBS"
    ) > "$LOG_FILE" 2>&1; then
        tail -80 "$LOG_FILE" >&2
        exit 1
    fi
    [[ "$QUIET" == YES ]] || tail -5 "$LOG_FILE"
    LIBRARIES+=("$ARCH_BUILD/libmysql/libmysqlclient.a")
done
[[ ${#LIBRARIES[@]} -gt 0 ]] || { echo 'No architecture selected.' >&2; exit 1; }
xcrun lipo -create "${LIBRARIES[@]}" -output "$OUTPUT_DIR/lib/libmysqlclient.a.new"
xcrun lipo -info "$OUTPUT_DIR/lib/libmysqlclient.a.new"
mv "$OUTPUT_DIR/lib/libmysqlclient.a.new" "$OUTPUT_DIR/lib/libmysqlclient.a"
for header in my_alloc.h my_list.h mysql_com.h mysql_time.h mysql.h typelib.h; do
    cp "$STAGED_SOURCE/include/$header" "$OUTPUT_DIR/include/"
done
cp "$BUILD_ROOT/build-${ARCHITECTURES%% *}/include/mysql_version.h" "$OUTPUT_DIR/include/"
echo "Native MySQL client library is ready in $OUTPUT_DIR"
