#!/usr/bin/env bash
# Cross-build sparkmusic-core for Android arm64-v8a.
#
# Required:
#   ANDROID_NDK_ROOT   e.g. .../ndk/27.2.12479018
#   QMAKE              Qt 6.11 android_arm64_v8a/bin/qmake
#   RUSTUP_HOME        writable rustup home with the aarch64-linux-android target
# Optional:
#   CARGO_HOME         writable cargo home (defaults to ../.cargo-home)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CORE="$ROOT/../core"

: "${ANDROID_NDK_ROOT:?set ANDROID_NDK_ROOT to an Android NDK r27c installation}"
: "${QMAKE:?set QMAKE to the Qt 6.11 android_arm64_v8a qmake}"
: "${RUSTUP_HOME:?set RUSTUP_HOME to a writable rustup home}"

TOOLCHAIN="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin"
export CC_aarch64_linux_android="$TOOLCHAIN/aarch64-linux-android28-clang"
export CXX_aarch64_linux_android="$TOOLCHAIN/aarch64-linux-android28-clang++"
export AR_aarch64_linux_android="$TOOLCHAIN/llvm-ar"
export RANLIB_aarch64_linux_android="$TOOLCHAIN/llvm-ranlib"
export CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER="$TOOLCHAIN/aarch64-linux-android28-clang"
export CARGO_HOME="${CARGO_HOME:-$ROOT/../.cargo-home}"
export CCACHE_DISABLE=1

cd "$CORE"
cargo build --target aarch64-linux-android --release
