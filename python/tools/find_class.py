#!/usr/bin/env python3
"""Locate which DEX file defines a class descriptor (exact match).

Usage: python -I find_class.py "Ly22/e;" <dex> [<dex> ...]
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from dex_dump import Dex


def main():
    target = sys.argv[1]
    for path in sys.argv[2:]:
        with open(path, "rb") as f:
            d = Dex(f.read())
        for c in d.classes:
            if c["type"] == target:
                print(f"{path}: {c['type']} super={c['super']} interfaces={d.interfaces(c)} "
                      f"methods={sum(1 for _ in d.iter_methods(c))}")


if __name__ == "__main__":
    main()
