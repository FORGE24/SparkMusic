#!/usr/bin/env bash
# Build/run helper for this machine.
#
# ~/.cargo and /home are mounted read-only here, and ccache cannot write its
# cache, so a plain `cargo ...` fails.  This wrapper keeps the registry cache
# inside the project and disables ccache.
set -euo pipefail

cd "$(dirname "$0")"
export CARGO_HOME="$PWD/.cargo-home"
export CCACHE_DISABLE=1

exec cargo "$@"
