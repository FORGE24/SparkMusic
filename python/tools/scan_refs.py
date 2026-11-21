#!/usr/bin/env python3
"""Find classes/methods whose constant strings contain any target substring.

Usage: python -I scan_refs.py <dexfile> <target1> [<target2> ...]

Prints: CLASS <type>
          METHOD <name><desc> :: <matched unique strings>
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from dex_dump import Dex


def main():
    path = sys.argv[1]
    targets = sys.argv[2:]
    with open(path, "rb") as f:
        d = Dex(f.read())
    out = sys.stdout.buffer
    for c in d.classes:
        methods = []
        for midx, access, code_off in d.iter_methods(c):
            if not code_off:
                continue
            hits = []
            try:
                for kind, val in d.iter_code_items(code_off):
                    if kind == "str" and any(t in val for t in targets):
                        hits.append(val)
            except Exception:
                continue
            if hits:
                cls, name, (ret, params) = d.methods[midx]
                methods.append((f"{name}({''.join(params)}){ret}", sorted(set(hits))))
        if methods:
            out.write(f"CLASS {c['type']}\n".encode("utf-8", "replace"))
            for m, hits in methods:
                out.write(f"  METHOD {m} :: {hits}\n".encode("utf-8", "replace"))


if __name__ == "__main__":
    main()
