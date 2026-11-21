#!/usr/bin/env python3
"""Find classes implementing/mentioning an interface descriptor.

Usage: python -I find_impl.py <interface-descriptor> <dex> [<dex> ...]
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
            ifaces = d.interfaces(c)
            if target in ifaces or target in (c["super"] or ""):
                print(f"{path}: {c['type']} super={c['super']} interfaces={ifaces} "
                      f"methods={sum(1 for _ in d.iter_methods(c))}")


if __name__ == "__main__":
    main()
