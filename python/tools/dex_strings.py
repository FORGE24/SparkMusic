#!/usr/bin/env python3
"""Minimal DEX string-pool extractor.

Usage: python -I dex_strings.py <dexfile> [<dexfile> ...] > strings.txt
Prints one string per line (MUTF-8 decoded, deduplicated in order).
"""
import struct
import sys


def read_uleb128(buf, off):
    result = 0
    shift = 0
    while True:
        b = buf[off]
        off += 1
        result |= (b & 0x7F) << shift
        if b < 0x80:
            break
        shift += 7
    return result, off


def decode_mutf8(raw):
    # MUTF-8 differs from UTF-8 for NUL and surrogate pairs. Decode permissively.
    try:
        return raw.decode("utf-8", "replace")
    except Exception:
        return raw.decode("latin-1", "replace")


def dex_strings(path):
    with open(path, "rb") as f:
        buf = f.read()
    if buf[:4] != b"dex\n":
        raise ValueError(f"not a dex: {path}")
    (string_ids_size, string_ids_off) = struct.unpack_from("<II", buf, 56)
    out = []
    for i in range(string_ids_size):
        (data_off,) = struct.unpack_from("<I", buf, string_ids_off + 4 * i)
        _utf16_len, p = read_uleb128(buf, data_off)
        end = buf.index(b"\x00", p)
        out.append(decode_mutf8(buf[p:end]))
    return out


def main():
    seen = set()
    out = sys.stdout.buffer
    for path in sys.argv[1:]:
        for s in dex_strings(path):
            if s not in seen:
                seen.add(s)
                out.write(s.encode("utf-8", "replace") + b"\n")


if __name__ == "__main__":
    main()
