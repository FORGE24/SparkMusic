#!/usr/bin/env bash
# Build entry point for the SparkMusic monorepo.
#
#   ./build.sh            # gui (brings core along) + api release binary
#   ./build.sh gui        # Qt shell + libsparkmusic_core.so
#   ./build.sh core       # only the shared library
#   ./build.sh api        # Axum service
#   ./build.sh protocol   # shared crate (tests)
#   ./build.sh test       # protocol + core + api tests
#   ./build.sh clean
#
# Qt is discovered from QT_PREFIX (or CMAKE_PREFIX_PATH); on this host the
# qt611 install is picked up automatically. CCACHE_DISABLE is forced because
# /home is read-only there, and CARGO_HOME falls back to the in-repo cache.
set -euo pipefail

cd "$(dirname "$0")"
ROOT="$PWD"

QT="${QT_PREFIX:-${CMAKE_PREFIX_PATH:-}}"
if [ -z "$QT" ]; then
    for candidate in \
        "$HOME/qt611/6.11.2/gcc_64" \
        "/run/media/forge/889dc643-5963-4417-b219-508778766cc7/qt611/6.11.2/gcc_64"
    do
        [ -d "$candidate" ] && QT="$candidate" && break
    done
fi
if [ -z "$QT" ]; then
    echo "error: set QT_PREFIX (or CMAKE_PREFIX_PATH) to a Qt 6.5+ prefix" >&2
    exit 1
fi

CXX_BIN="/usr/bin/g++"
[ -x "$CXX_BIN" ] || CXX_BIN="${CXX:-g++}"

export CCACHE_DISABLE=1
export CARGO_HOME="${CARGO_HOME:-$ROOT/.cargo-home}"
export QMAKE="${QMAKE:-$QT/bin/qmake}"

CMAKE_ARGS=(-G Ninja -DCMAKE_BUILD_TYPE=Release
            -DCMAKE_CXX_COMPILER="$CXX_BIN"
            -DCMAKE_PREFIX_PATH="$QT")

case "${1:-all}" in
    gui|all)
        echo "== gui (core is added as a subproject) =="
        cmake -S gui -B gui/build "${CMAKE_ARGS[@]}"
        cmake --build gui/build
        echo "   -> gui/build/sparkmusic"
        echo "   -> gui/build/core/libsparkmusic_core.so.0"
        if [ "${1:-all}" = "all" ]; then
            echo
            echo "== api (release) =="
            cargo build --release --manifest-path api/Cargo.toml
            echo "   -> api/target/release/sparkmusic-api"
        fi
        ;;
    core)
        echo "== core =="
        cmake -S core -B core/build "${CMAKE_ARGS[@]}"
        cmake --build core/build
        echo "   -> core/build/libsparkmusic_core.so.0"
        ;;
    api)
        echo "== api =="
        cargo build --release --manifest-path api/Cargo.toml
        echo "   -> api/target/release/sparkmusic-api"
        ;;
    protocol)
        echo "== protocol tests =="
        cargo test --manifest-path protocol/Cargo.toml
        ;;
    test)
        cargo test --manifest-path protocol/Cargo.toml
        cargo test --manifest-path core/Cargo.toml
        cargo test --manifest-path api/Cargo.toml
        ;;
    clean)
        rm -rf core/build gui/build protocol/target
        echo "cleaned build dirs (cargo target dirs under api/target kept)"
        ;;
    *)
        echo "usage: ./build.sh [all|gui|core|api|protocol|test|clean]" >&2
        exit 2
        ;;
esac
