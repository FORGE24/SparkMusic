#!/usr/bin/env bash
# Create the source archive Copr expects: sparkmusic-<version>.tar.gz with a
# sparkmusic-<version>/ top-level directory (matches %autosetup -n).
set -eu
v=$(git describe --tags --abbrev=0 | sed -e 's/^v//' -e 's/-.*//')
out="sparkmusic-${v}.tar.gz"
git archive --format=tar.gz --prefix="sparkmusic-${v}/" -o "$out" HEAD
echo "$out"
