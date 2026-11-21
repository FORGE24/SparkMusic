#!/usr/bin/env bash
# Build helper for this machine.
#
# /home (and therefore ~/.cargo) is mounted read-only and ccache cannot write
# its cache, so plain `cargo`/`cmake` fail here.  This wrapper pins a writable
# CARGO_HOME (symlinked to the shared registry cache) and disables ccache.
#
# Point QMAKE/CMAKE_PREFIX_PATH at a different Qt with:
#   QMAKE=/opt/Qt/6.8.0/gcc_64/bin/qmake ./build.sh build
set -euo pipefail

cd "$(dirname "$0")"

export CCACHE_DISABLE=1
export CARGO_HOME="${CARGO_HOME:-$PWD/.cargo-home}"
export QMAKE="${QMAKE:-/run/media/forge/889dc643-5963-4417-b219-508778766cc7/qt611/6.11.2/gcc_64/bin/qmake}"
export CMAKE_PREFIX_PATH="${CMAKE_PREFIX_PATH:-/run/media/forge/889dc643-5963-4417-b219-508778766cc7/qt611/6.11.2/gcc_64}"

exec cargo "$@"
