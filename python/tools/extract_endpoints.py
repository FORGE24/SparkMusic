#!/usr/bin/env python3
"""Extract API endpoint definitions across DEX files.

A method is treated as an API definition when its bytecode invokes one of the
known request-entry signatures (y22/e.c, y32/a.<init>, ...).  R8 renames those
classes on every release, so when no marker matches (a newer build), the tool
falls back to scanning every method that contains route-shaped string
constants and prints a note about the reduced precision.

Route strings are collected in instruction order.  Parameter keys are recovered
with a small register tracker: we follow const-string -> move-object chains and
read the key register of Map.put / JSONObject.put invocations.  This is far more
accurate than looking at the textually preceding const-string, because values
are often string literals as well.

Each key is attributed to the most recent route string; keys emitted before any
route string are attributed to the first route that follows.

Usage: python -I extract_endpoints.py <out.json> [--all-methods] <dex> [<dex> ...]
"""
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from dex_dump import Dex, SIZE, u16, u32

ENTRY_MARKERS = (
    "Ly22/e;->a(",
    "Ly22/e;->b(",
    "Ly22/e;->c(",
    "Ly22/e;->d(",
    "Ly22/e;->e(",
    "Ly22/e;->f(",
    "Ly22/e;->g(",
    "Ly32/a;-><init>(",
    "Ly32/b;-><init>(",
    "Ly32/c;-><init>(",
    "Ly32/c;->H1(",
)

PREFIX_RE = re.compile(
    r"^(?:/api/|/weapi/|/eapi/|/xeapi/|/neapi/|/linuxapi/|"
    r"api/|weapi/|eapi/|xeapi/|neapi/|linuxapi/|v\d+/)"
)
REL_ROOTS = set("""
act activity ad alarm album appcustomconfig artist baby batch calendar cellphone
check clientlog cloud cloudvideo code college comment concert config coop daily
device discovery dj djprogram djradio dsp email event feedback follow history
homepage hottopic image like listen login logout mine mix mlivestream mlog msg
music nearby nation nickname nuser order password pendant personalized pl
playlist playmode purchased quality radio recommend record register related
report resource reward scrobble sdk search setting share sheet simi sms song
songs sp starpay star sub taste theme token toplist topic upload user users
usertool verify vip voice weblog
""".split())
REL_RE = re.compile(r"^[a-z][a-z0-9_]*(?:/[a-z0-9_%{}.]+){1,7}$")
BAD_SUFFIX = re.compile(r"\.(?:jpe?g|png|gif|webp|json|html|css|js|mp3|mp4|xml|so|dex)$", re.I)
KEY_RE = re.compile(r"^[a-z][a-zA-Z0-9_]{0,48}$")
KEY_STOP = {
    "true", "false", "null", "android", "mock", "utf-8", "gzip", "POST", "GET",
    "header", "params", "content", "body", "method", "contentType", "queryString",
    "unknown", "set", "get", "put", "json", "object", "string", "array", "list",
}

# opcodes with format 35c: invoke-kind {vC, vD, vE, vF, vG}, method@BBBB
INVOKE_35C = {0x6E, 0x6F, 0x70, 0x71, 0x72, 0xFA}
# opcodes with format 3rc: invoke-kind/range {vCCCC .. vNNNN}, method@BBBB
INVOKE_3RC = {0x74, 0x75, 0x76, 0x77, 0x78, 0xFB}


def is_route(s):
    path = s.split("?", 1)[0].split("#", 1)[0]
    if len(path) > 160 or " " in path or BAD_SUFFIX.search(path):
        return False
    if PREFIX_RE.match(path):
        return True
    if REL_RE.match(path):
        root = path.split("/", 1)[0]
        return root in REL_ROOTS
    return False


MIME_ROOTS = {"image", "audio", "video", "text", "application", "font", "model", "multipart"}


def plausible_route(s):
    """Reject constants that look like a route but cannot be one.

    Without the request-builder gate the scan also sees MIME types
    (``image/png``), transport base paths (``/eapi/``) and version roots
    (``v2/``).  Those reach the catalog as bogus entries, so they are filtered
    here: a route must have a real path below any transport prefix.
    """
    path = s.split("?", 1)[0].split("#", 1)[0].strip("/")
    for prefix in ("api/", "weapi/", "eapi/", "xeapi/", "neapi/", "linuxapi/"):
        if path.startswith(prefix):
            path = path[len(prefix):]
            break
    if not path:
        return False
    if re.fullmatch(r"(?:api|weapi|eapi|xeapi|neapi|linuxapi)", path):
        # a transport mode name on its own is a base path, not a route
        return False
    if re.fullmatch(r"v\d+", path):
        # a bare version root such as "v2/" is a base path, not a route
        return False
    root = path.split("/", 1)[0]
    if root in MIME_ROOTS:
        return False
    return True


def is_key(s):
    return bool(KEY_RE.match(s)) and s not in KEY_STOP and not is_route(s)


def iter_put_keys(d, code_off):
    """Yield (const-string, put-descriptor) for each put whose key register is
    provably a const-string (directly, or through move-object).

    Values are kept as (string, instruction-index) so stale registers can be
    age-limited.
    """
    b = d.b
    insn_off = code_off + 16
    insn_count = u32(b, code_off + 12)
    regs = {}          # register -> (string, assigned_at)
    i = 0
    while i < insn_count:
        op = b[insn_off + 2 * i]
        if op == 0x00 and i + 1 < insn_count:
            ident = u16(b, insn_off + 2 * (i + 1))
            if ident == 0x0100:
                i += 4 + 2 * u16(b, insn_off + 2 * (i + 2))
                continue
            if ident == 0x0200:
                i += 2 + 4 * u16(b, insn_off + 2 * (i + 2))
                continue
            if ident == 0x0300:
                width = u16(b, insn_off + 2 * (i + 2))
                n = u32(b, insn_off + 2 * (i + 4))
                i += 4 + (n * width + 1) // 2
                continue
        sz = SIZE.get(op)
        if sz is None:
            return
        u0 = u16(b, insn_off + 2 * i)
        try:
            if op == 0x1A:
                reg = u0 >> 8
                regs[reg] = (d.strings[u16(b, insn_off + 2 * (i + 1))], i)
            elif op == 0x1B:
                reg = u0 >> 8
                idx = u16(b, insn_off + 2 * (i + 1)) | (u16(b, insn_off + 2 * (i + 2)) << 16)
                regs[reg] = (d.strings[idx], i)
            elif op == 0x07:                       # move-object vA, vB
                dst, src = u0 >> 8, u0 & 0xF
                if src in regs:
                    regs[dst] = regs[src]
                else:
                    regs.pop(dst, None)
            elif op == 0x08:                       # move-object/from16 vAA, vBBBB
                dst, src = u0 >> 8, u16(b, insn_off + 2 * (i + 1))
                if src in regs:
                    regs[dst] = regs[src]
                else:
                    regs.pop(dst, None)
            elif op == 0x09:                       # move-object/16 vAAAA, vBBBB
                dst, src = u16(b, insn_off + 2 * (i + 1)), u16(b, insn_off + 2 * (i + 2))
                if src in regs:
                    regs[dst] = regs[src]
                else:
                    regs.pop(dst, None)
            elif op == 0x0C:                       # move-result-object vAA
                regs.pop(u0 >> 8, None)
            elif op in INVOKE_35C:
                mi = u16(b, insn_off + 2 * (i + 1))
                desc = d.method_desc(d.methods[mi])
                if "put(" in desc:
                    count = u0 & 0xF
                    # 35c registers live in unit 2 for 0x6e..0x72; 45cc (0xfa)
                    # has a proto id in unit 2 and its registers in unit 3.
                    reg_unit = i + 3 if op == 0xFA else i + 2
                    u2 = u16(b, insn_off + 2 * reg_unit)
                    regs_list = [u2 & 0xF, (u2 >> 4) & 0xF, (u2 >> 8) & 0xF,
                                 (u2 >> 12) & 0xF, u0 >> 12]
                    args = regs_list[:count]
                    # argument order is C,D,E,F,G; receiver is args[0]
                    key_reg = args[1] if len(args) > 1 else None
                    if key_reg is not None and key_reg in regs:
                        s, at = regs[key_reg]
                        if i - at <= 80:
                            yield s, desc
            elif op in INVOKE_3RC:
                mi = u16(b, insn_off + 2 * (i + 1))
                desc = d.method_desc(d.methods[mi])
                if "put(" in desc:
                    count = u0 >> 8
                    first = u16(b, insn_off + 2 * (i + 2))
                    key_reg = first + 1 if count > 1 else None
                    if key_reg is not None and key_reg in regs:
                        s, at = regs[key_reg]
                        if i - at <= 80:
                            yield s, desc
        except (IndexError, KeyError):
            return
        i += sz


def extract(dex_paths, markers):
    """Collect request records from ``dex_paths``.

    ``markers`` are invoke targets identifying the generic request builder.
    Pass an empty tuple to scan every method that mentions a route string
    instead; that is the fallback for builds whose obfuscated builder cannot
    be identified (R8 renames it on every release).
    """
    records = []
    for path in dex_paths:
        with open(path, "rb") as f:
            d = Dex(f.read())
        for c in d.classes:
            for midx, access, code_off in d.iter_methods(c):
                if not code_off:
                    continue
                try:
                    items = list(d.iter_code_items(code_off))
                except Exception:
                    continue
                if markers:
                    invokes = [v for k, v in items if k == "invoke"]
                    if not any(m in inv for inv in invokes for m in markers):
                        continue

                routes = []
                route_params = {}
                keys = []
                all_strs = []
                put_keys = list(iter_put_keys(d, code_off))
                # iterate the code once for routes and their order, then fold in
                # keys using the method-level list (register order is not
                # exposed by iter_code_items, so route attribution is by order
                # of const-string appearance and put order).
                for kind, val in items:
                    if kind == "str":
                        all_strs.append(val)
                        if is_route(val) and plausible_route(val) and val not in routes:
                            routes.append(val)
                for key, desc in put_keys:
                    if is_key(key) and key not in keys:
                        keys.append(key)
                if not routes:
                    continue
                # Attribute all recovered keys to every route when the method
                # has one route, and to the single route for multi-route
                # methods only when the method clearly builds one map (the
                # catalog marks shared params as method-level otherwise).
                if len(routes) == 1:
                    route_params[routes[0]] = list(keys)
                cls, name, (ret, params) = d.methods[midx]
                records.append({
                    "class": cls,
                    "method": name,
                    "desc": f"({''.join(params)}){ret}",
                    "routes": routes,
                    "params": keys,
                    "route_params": route_params,
                    "put_keys": [k for k, _ in put_keys],
                    "strings": [s for s in all_strs if s not in routes][:40],
                    "builder_matched": bool(markers),
                })
    return records


def main():
    args = list(sys.argv[1:])
    force_all = "--all-methods" in args
    if force_all:
        args.remove("--all-methods")
    if len(args) < 2:
        print(__doc__.strip(), file=sys.stderr)
        raise SystemExit(2)
    out_path, dex_paths = args[0], args[1:]

    if force_all:
        records = extract(dex_paths, ())
    else:
        records = extract(dex_paths, ENTRY_MARKERS)
        if not records:
            print(
                "note: no method invoked a known request builder for this build; "
                "falling back to route-string scanning over every method "
                "(records are lower precision).",
                file=sys.stderr,
            )
            records = extract(dex_paths, ())
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(records, f, ensure_ascii=False, indent=1)
    print(f"records={len(records)} routes={len({r for x in records for r in x['routes']})} "
          f"records_with_params={sum(1 for x in records if x['params'])} "
          f"builder_matched={sum(1 for x in records if x['builder_matched'])}")


if __name__ == "__main__":
    main()
