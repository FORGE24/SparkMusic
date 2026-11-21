#!/usr/bin/env python3
"""Minimal DEX class/method dumper for API recovery.

Usage:
  python -I dex_dump.py <dexfile> [class-substring ...] [--all]

Dumps class name, methods, and for each method:
  STR  <const-string literal>
  TY   <const-class / new-instance type>
  FLD  <field class->name:type>
  INV  <invoked class->name(descriptor)>
  ANN  <annotation type> key=value ...
"""
import struct
import sys

SIZE = {}
for op, sz in {
    0x00: 1, 0x01: 1, 0x02: 2, 0x03: 3, 0x04: 1, 0x05: 2, 0x06: 3,
    0x07: 1, 0x08: 2, 0x09: 3, 0x0A: 1, 0x0B: 1, 0x0C: 1, 0x0D: 1,
    0x0E: 1, 0x0F: 1, 0x10: 1, 0x11: 1, 0x12: 1, 0x13: 2, 0x14: 3,
    0x15: 2, 0x16: 2, 0x17: 3, 0x18: 5, 0x19: 2, 0x1A: 2, 0x1B: 3,
    0x1C: 2, 0x1D: 1, 0x1E: 1, 0x1F: 2, 0x20: 2, 0x21: 1, 0x22: 2,
    0x23: 2, 0x24: 3, 0x25: 3, 0x26: 3, 0x27: 1, 0x28: 1, 0x29: 2,
    0x2A: 3, 0x2B: 2, 0x2C: 2, 0x2D: 2, 0x2E: 2, 0x2F: 2, 0x30: 2,
    0x31: 2, 0x32: 2, 0x33: 2, 0x34: 2, 0x35: 2, 0x36: 2, 0x37: 2,
    0x38: 2, 0x39: 2, 0x3A: 2, 0x3B: 2, 0x3C: 2, 0x3D: 2,
    0x6E: 3, 0x6F: 3, 0x70: 3, 0x71: 3, 0x72: 3, 0x74: 3, 0x75: 3,
    0x76: 3, 0x77: 3, 0x78: 3, 0xFA: 4, 0xFB: 4, 0xFC: 3, 0xFD: 3,
    0xFE: 2, 0xFF: 2,
}.items():
    SIZE[op] = sz
for op in range(0x3E, 0x44):
    SIZE[op] = 1
for op in range(0x44, 0x6E):
    SIZE[op] = 2
for op in range(0x73, 0x74):
    SIZE[op] = 1
for op in range(0x79, 0x8F + 1):
    SIZE[op] = 1
for op in range(0x90, 0xB0):
    SIZE[op] = 2
for op in range(0xB0, 0xD0):
    SIZE[op] = 1
for op in range(0xD0, 0xE3):
    SIZE[op] = 2
for op in range(0xE3, 0xFA):
    SIZE[op] = 1


def u16(b, o):
    return struct.unpack_from("<H", b, o)[0]


def u32(b, o):
    return struct.unpack_from("<I", b, o)[0]


def uleb(b, o):
    r = 0
    s = 0
    while True:
        x = b[o]
        o += 1
        r |= (x & 0x7F) << s
        if x < 0x80:
            return r, o
        s += 7


def mutf8(b, o):
    n, p = uleb(b, o)
    e = b.index(b"\x00", p)
    return b[p:e].decode("utf-8", "replace"), e + 1


class Dex:
    def __init__(self, buf):
        self.b = buf
        self.strings = []
        n, off = u32(buf, 56), u32(buf, 60)
        for i in range(n):
            s, _ = mutf8(buf, u32(buf, off + 4 * i))
            self.strings.append(s)
        self.types = [self.strings[u32(buf, u32(buf, 68) + 4 * i)]
                      for i in range(u32(buf, 64))]
        poff = u32(buf, 76)
        self.protos = []
        for i in range(u32(buf, 72)):
            o = poff + 12 * i
            ret = self.types[u32(buf, o + 4)]
            params = []
            p = u32(buf, o + 8)
            if p:
                sz = u32(buf, p)
                params = [self.types[u16(buf, p + 4 + 2 * j)] for j in range(sz)]
            self.protos.append((ret, params))
        foff = u32(buf, 84)
        self.fields = []
        for i in range(u32(buf, 80)):
            o = foff + 8 * i
            self.fields.append((self.types[u16(buf, o)],
                                self.strings[u32(buf, o + 4)],
                                self.types[u16(buf, o + 2)]))
        moff = u32(buf, 92)
        self.methods = []
        for i in range(u32(buf, 88)):
            o = moff + 8 * i
            self.methods.append((self.types[u16(buf, o)],
                                 self.strings[u32(buf, o + 4)],
                                 self.protos[u16(buf, o + 2)]))
        self.classes = []
        coff = u32(buf, 100)
        for i in range(u32(buf, 96)):
            o = coff + 32 * i
            self.classes.append({
                "type": self.types[u32(buf, o)],
                "access": u32(buf, o + 4),
                "super": self.types[u32(buf, o + 8)] if u32(buf, o + 8) != 0xFFFFFFFF else None,
                "interfaces_off": u32(buf, o + 12),
                "source": self.strings[u32(buf, o + 16)] if u32(buf, o + 16) != 0xFFFFFFFF else None,
                "anno_off": u32(buf, o + 20),
                "data_off": u32(buf, o + 24),
            })

    def method_desc(self, m):
        cls, name, (ret, params) = m
        return f"{cls}->{name}({''.join(params)}){ret}"

    def type_desc(self, t):
        return t

    def class_annotations(self, off):
        annotations = []
        if not off:
            return annotations
        o = off
        class_anno_off = u32(self.b, o)
        n_fields, n_methods, n_params = u32(self.b, o + 4), u32(self.b, o + 8), u32(self.b, o + 12)
        o += 16
        # skip field/method/param directories when only class annotations are wanted
        if class_anno_off:
            annotations.extend(self.annotation_set(class_anno_off))
        return annotations

    def annotation_set(self, off):
        res = []
        n = u32(self.b, off)
        for i in range(n):
            res.append(self.annotation_item(u32(self.b, off + 4 + 4 * i)))
        return res

    def annotation_item(self, off):
        vis = self.b[off]
        o = off + 1
        t_idx, o = uleb(self.b, o)
        size, o = uleb(self.b, o)
        elems = {}
        for _ in range(size):
            n_idx, o = uleb(self.b, o)
            val, o = self.encoded_value(o)
            elems[self.strings[n_idx]] = val
        return (self.types[t_idx], elems)

    def encoded_value(self, o):
        b = self.b
        hdr = b[o]
        o += 1
        vt = hdr & 0x1F
        arg = hdr >> 5
        if vt == 0x00:
            return b[o], o + 1
        if vt == 0x02:
            return struct.unpack_from("<h", b, o)[0], o + 2
        if vt == 0x03:
            return struct.unpack_from("<H", b, o)[0], o + 2
        if vt == 0x04:
            return struct.unpack_from("<i", b, o)[0], o + 4
        if vt == 0x06:
            return struct.unpack_from("<q", b, o)[0], o + 8
        if vt == 0x10:
            return struct.unpack_from("<f", b, o)[0], o + 4
        if vt == 0x11:
            return struct.unpack_from("<d", b, o)[0], o + 8
        if vt in (0x15, 0x16, 0x17, 0x18, 0x19, 0x1A, 0x1B):
            idx, o = uleb(b, o)
            if vt == 0x17:
                return self.strings[idx], o
            if vt == 0x18:
                return self.types[idx], o
            return f"#{idx}", o
        if vt == 0x1C:
            n, o = uleb(b, o)
            arr = []
            for _ in range(n):
                v, o = self.encoded_value(o)
                arr.append(v)
            return arr, o
        if vt == 0x1D:
            t_idx, o = uleb(b, o)
            n, o = uleb(b, o)
            elems = {}
            for _ in range(n):
                n_idx, o = uleb(b, o)
                v, o = self.encoded_value(o)
                elems[self.strings[n_idx]] = v
            return {self.types[t_idx]: elems}, o
        if vt == 0x1E:
            return None, o
        if vt == 0x1F:
            return bool(arg), o
        raise ValueError(f"bad encoded_value type {vt} at {o}")

    def method_annotations(self, data_off):
        """method_idx -> list of annotations, using annotations_directory_item."""
        raise NotImplementedError

    def interfaces(self, c):
        off = c["interfaces_off"]
        if not off:
            return []
        n = u32(self.b, off)
        return [self.types[u16(self.b, off + 4 + 2 * i)] for i in range(n)]

    def iter_methods(self, c):
        """Yield (method_idx, access_flags, code_off) for a class."""
        b = self.b
        off = c["data_off"]
        if not off:
            return
        sf, off = uleb(b, off)
        inf, off = uleb(b, off)
        dm, off = uleb(b, off)
        vm, off = uleb(b, off)
        for _ in range(sf + inf):
            _, off = uleb(b, off)
            _, off = uleb(b, off)
        idx = 0
        for i in range(dm):
            diff, off = uleb(b, off)
            idx = diff if i == 0 else idx + diff
            access, off = uleb(b, off)
            code_off, off = uleb(b, off)
            yield idx, access, code_off
        idx = 0
        for i in range(vm):
            diff, off = uleb(b, off)
            idx = diff if i == 0 else idx + diff
            access, off = uleb(b, off)
            code_off, off = uleb(b, off)
            yield idx, access, code_off

    def iter_code_items(self, code_off):
        """Yield ('str'|'type'|'field'|'invoke', value) in instruction order."""
        b = self.b
        insn_off = code_off + 16
        insn_count = u32(b, code_off + 12)
        i = 0
        while i < insn_count:
            op = b[insn_off + 2 * i]
            if op == 0x00 and i + 1 < insn_count:
                ident = u16(b, insn_off + 2 * (i + 1))
                if ident == 0x0100:
                    n = u16(b, insn_off + 2 * (i + 2))
                    i += 4 + 2 * n
                    continue
                if ident == 0x0200:
                    n = u16(b, insn_off + 2 * (i + 2))
                    i += 2 + 4 * n
                    continue
                if ident == 0x0300:
                    width = u16(b, insn_off + 2 * (i + 2))
                    n = u32(b, insn_off + 2 * (i + 4))
                    i += 4 + (n * width + 1) // 2
                    continue
            sz = SIZE.get(op)
            if sz is None:
                return
            try:
                if op == 0x1A:
                    yield "str", self.strings[u16(b, insn_off + 2 * (i + 1))]
                elif op == 0x1B:
                    yield "str", self.strings[u32(b, insn_off + 2 * (i + 1))]
                elif op in (0x1C, 0x1F, 0x20, 0x22, 0x23):
                    yield "type", self.types[u16(b, insn_off + 2 * (i + 1))]
                elif op in (0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59,
                            0x5A, 0x5B, 0x5C, 0x5D, 0x5E, 0x5F, 0x60, 0x61,
                            0x62, 0x63, 0x64, 0x65, 0x66, 0x67):
                    fc, fn, ft = self.fields[u16(b, insn_off + 2 * (i + 1))]
                    yield "field", f"{fc}->{fn}:{ft}"
                elif op in (0x6E, 0x6F, 0x70, 0x71, 0x72, 0x74, 0x75, 0x76, 0x77, 0x78,
                            0xFA, 0xFB):
                    yield "invoke", self.method_desc(self.methods[u16(b, insn_off + 2 * (i + 1))])
            except IndexError:
                return
            i += sz

    def dump_class(self, c, out):
        b = self.b
        out.append(f"CLASS {c['type']} access=0x{c['access']:x} super={c['super']} "
                   f"interfaces={self.interfaces(c)} source={c['source']}")
        if c["anno_off"]:
            try:
                for t, elems in self.class_annotations(c["anno_off"]):
                    out.append(f"  CANN {t} {elems}")
            except Exception as e:
                out.append(f"  CANN-ERROR {e}")
        off = c["data_off"]
        if not off:
            return
        sf, off = uleb(b, off)
        inf, off = uleb(b, off)
        dm, off = uleb(b, off)
        vm, off = uleb(b, off)
        idx = 0
        for _ in range(sf):
            _, off = uleb(b, off)
            _, off = uleb(b, off)
        idx = 0
        for _ in range(inf):
            _, off = uleb(b, off)
            _, off = uleb(b, off)
        idx = 0
        for i in range(dm):
            diff, off = uleb(b, off)
            idx = diff if i == 0 else idx + diff
            access, off = uleb(b, off)
            code_off, off = uleb(b, off)
            try:
                self.dump_method(idx, access, code_off, out)
            except Exception as e:
                out.append(f"  METHOD-ERROR idx={idx} {e}")
        idx = 0
        for i in range(vm):
            diff, off = uleb(b, off)
            idx = diff if i == 0 else idx + diff
            access, off = uleb(b, off)
            code_off, off = uleb(b, off)
            try:
                self.dump_method(idx, access, code_off, out)
            except Exception as e:
                out.append(f"  METHOD-ERROR idx={idx} {e}")

    def dump_method(self, midx, access, code_off, out):
        cls, name, (ret, params) = self.methods[midx]
        desc = f"{cls}->{name}({''.join(params)}){ret}"
        out.append(f"  METHOD {name}{''.join(params)}{ret} access=0x{access:x} code={code_off}")
        if not code_off:
            return
        b = self.b
        insn_off = code_off + 16
        insn_count = u32(b, code_off + 12)
        i = 0
        while i < insn_count:
            op = b[insn_off + 2 * i]
            # Handle pseudo-instruction payloads embedded in the code array.
            if op == 0x00 and i + 1 < insn_count:
                ident = u16(b, insn_off + 2 * (i + 1))
                if ident == 0x0100:      # packed-switch payload
                    n = u16(b, insn_off + 2 * (i + 2))
                    i += 4 + 2 * n
                    continue
                if ident == 0x0200:      # sparse-switch payload
                    n = u16(b, insn_off + 2 * (i + 2))
                    i += 2 + 4 * n
                    continue
                if ident == 0x0300:      # fill-array-data payload
                    width = u16(b, insn_off + 2 * (i + 2))
                    n = u32(b, insn_off + 2 * (i + 4))
                    i += 4 + (n * width + 1) // 2
                    continue
            sz = SIZE.get(op)
            if sz is None:
                out.append(f"    ?? op=0x{op:02x} at {i}")
                break
            try:
                if op == 0x1A:
                    si = u16(b, insn_off + 2 * (i + 1))
                    out.append(f'    STR {self.strings[si]!r}')
                elif op == 0x1B:
                    si = u32(b, insn_off + 2 * (i + 1))
                    out.append(f'    STR {self.strings[si]!r}')
                elif op in (0x1C, 0x1F, 0x20, 0x22, 0x23):
                    ti = u16(b, insn_off + 2 * (i + 1))
                    out.append(f"    TY {self.types[ti]}")
                elif op in (0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59,
                            0x5A, 0x5B, 0x5C, 0x5D, 0x5E, 0x5F, 0x60, 0x61,
                            0x62, 0x63, 0x64, 0x65, 0x66, 0x67):
                    fi = u16(b, insn_off + 2 * (i + 1))
                    fc, fn, ft = self.fields[fi]
                    out.append(f"    FLD {fc}->{fn}:{ft}")
                elif op in (0x6E, 0x6F, 0x70, 0x71, 0x72, 0x74, 0x75, 0x76, 0x77, 0x78):
                    mi = u16(b, insn_off + 2 * (i + 1))
                    out.append(f"    INV {self.method_desc(self.methods[mi])}")
                elif op in (0xFA, 0xFB):
                    mi = u16(b, insn_off + 2 * (i + 1))
                    out.append(f"    INV {self.method_desc(self.methods[mi])}")
            except IndexError:
                out.append(f"    BAD-IDX op=0x{op:02x} i={i} unit={u16(b, insn_off + 2 * (i + 1))}")
                break
            i += sz


def main():
    args = sys.argv[1:]
    if not args:
        print(__doc__)
        return
    path = args[0]
    filters = [a for a in args[1:] if not a.startswith("--")]
    with open(path, "rb") as f:
        d = Dex(f.read())
    out = []
    for c in d.classes:
        if not filters or any(x in c["type"] for x in filters):
            try:
                d.dump_class(c, out)
            except Exception as e:
                out.append(f"CLASS-ERROR {c['type']} {e}")
    sys.stdout.buffer.write(("\n".join(out) + "\n").encode("utf-8", "replace"))


if __name__ == "__main__":
    main()
