#!/usr/bin/env bash
# Upstream version for Packit/Copr: v0.1.2-beta -> 0.1.2
set -eu
git describe --tags --abbrev=0 | sed -e 's/^v//' -e 's/-.*//'
