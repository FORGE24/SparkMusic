#!/usr/bin/env bash
# Headless smoke test for sparkmusic-core + the STILLE shell.
#
#   ./gui/smoke.sh
#
# Builds the Rust core and the GUI, runs the unit tests, renders the three
# views offscreen and checks that the GUI really links the core dynamically.
# Audio output is not required: the player falls back to the simulated clock.
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$PWD"

QT="${QT_PREFIX:-/run/media/forge/889dc643-5963-4417-b219-508778766cc7/qt611/6.11.2/gcc_64}"
export CCACHE_DISABLE=1
export CARGO_HOME="${CARGO_HOME:-$ROOT/.cargo-home}"
export QMAKE="${QMAKE:-$QT/bin/qmake}"
export CMAKE_PREFIX_PATH="${CMAKE_PREFIX_PATH:-$QT}"

step() { printf '\n== %s ==\n' "$1"; }

step "configure"
cmake -S gui -B gui/build -G Ninja \
    -DCMAKE_CXX_COMPILER=/usr/bin/g++ \
    -DCMAKE_PREFIX_PATH="$QT" >/dev/null

step "build (cargo core + Qt shell)"
cmake --build gui/build >/dev/null

step "rust unit tests"
cargo test --quiet --manifest-path "$ROOT/protocol/Cargo.toml" 2>&1 | grep -E "^test result" || true
cargo test --quiet --manifest-path "$ROOT/core/Cargo.toml" 2>&1 | grep -E "^test result" || true
cargo test --quiet --manifest-path "$ROOT/api/Cargo.toml" 2>&1 | grep -E "^test result" | head -3 || true

step "dynamic linkage"
readelf -d gui/build/sparkmusic | grep -q 'libsparkmusic_core.so.0' \
    && echo "GUI links libsparkmusic_core.so.0"
ldd gui/build/sparkmusic | grep -q 'libsparkmusic_core' \
    && echo "loader resolves the shared core"

step "render views (offscreen)"
mkdir -p gui/screenshots
render() {
    local out="$1"; shift
    QT_QPA_PLATFORM=offscreen timeout 90 ./gui/build/sparkmusic \
        --screenshot "gui/screenshots/$out" "$@" >/dev/null 2>&1
    test -s "gui/screenshots/$out" && echo "  $out"
}
render smoke_home.png --view home --delay 5000
render smoke_login.png --view login --delay 6000
render smoke_player.png --play 0 --delay 5000

step "persistence"
rm -rf .testdata && mkdir -p .testdata
XDG_DATA_HOME="$ROOT/.testdata" QT_QPA_PLATFORM=offscreen timeout 90     ./gui/build/sparkmusic --play 0 --delay 5000 --screenshot /tmp/db_smoke.png     >/dev/null 2>&1 || true
python3 - <<'PY2'
import sqlite3
c = sqlite3.connect(".testdata/sparkmusic/sparkmusic.db")
tables = sorted(r[0] for r in c.execute("select name from sqlite_master where type='table'"))
plays = c.execute("select count(*) from plays").fetchone()[0]
settings = dict(c.execute("select key, value from settings"))
print("tables:", ", ".join(tables))
print("plays recorded:", plays, "| settings:", settings)
PY2

step "catalog sanity"
python3 - <<'PY2'
import json
routes = json.load(open("core/assets/routes.json"))
print("routes:", len(routes), "| groups:", len({r["group"] for r in routes}))
PY2

step "done"
echo "screenshots: gui/screenshots/smoke_*.png"
