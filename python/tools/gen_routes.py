#!/usr/bin/env python3
"""Generate the Python route catalog from endpoints.json.

Usage: python -I gen_routes.py <endpoints.json> <out_routes.py>
"""
import json
import re
import sys
from collections import Counter, OrderedDict
from urllib.parse import parse_qsl

VERSION_RE = re.compile(r"^v\d+/")
PREFIXES = ("api/", "weapi/", "eapi/", "xeapi/", "neapi/", "linuxapi/")


def canonical(route):
    r = route.strip().strip("/")
    # Drop query strings and fragments, keep the path only.
    r = re.split(r"[?#]", r, maxsplit=1)[0].strip("/")
    for p in PREFIXES:
        if r.startswith(p):
            r = r[len(p):]
            break
    # An app route can contain a doubled slash after the prefix
    # ("/api//usertool/..."), which would otherwise leave a leading slash.
    return r.strip("/")


def query_keys(route):
    if "?" not in route:
        return []
    q = route.split("?", 1)[1].split("#", 1)[0]
    keys = []
    for k, _ in parse_qsl(q, keep_blank_values=True):
        if k and k not in keys:
            keys.append(k)
    return keys


def group_of(route):
    parts = route.split("/")
    if VERSION_RE.match(route):
        parts = parts[1:]
    return parts[0] if parts else "misc"


def main():
    src, out_path = sys.argv[1], sys.argv[2]
    strings_path = sys.argv[3] if len(sys.argv) > 3 else None
    records = json.load(open(src, encoding="utf-8"))

    routes = OrderedDict()
    for rec in records:
        for raw in rec["routes"]:
            route = canonical(raw)
            if not route:
                continue
            e = routes.setdefault(route, {
                "params": [],
                "sources": [],
                "variants": [],
                "exact": False,
                "shared": False,
            })
            if raw not in e["variants"]:
                e["variants"].append(raw)
            source = f"{rec['class']}->{rec['method']}{rec['desc']}"
            if source not in e["sources"]:
                e["sources"].append(source)
            # Query-template keys are confident request parameters.
            for k in query_keys(raw):
                if k not in e["params"]:
                    e["params"].append(k)
            if len(rec["routes"]) == 1:
                e["exact"] = True
                for k in rec["params"]:
                    if k not in e["params"]:
                        e["params"].append(k)
            else:
                e["shared"] = True
                for k in rec["route_params"].get(raw, []):
                    if k not in e["params"]:
                        e["params"].append(k)

    # Routes that only ever appear in multi-route methods: fall back to the
    # method-level keys and flag them as shared.
    by_source = {}
    for rec in records:
        key = (rec["class"], rec["method"], rec["desc"])
        by_source.setdefault(key, rec)
    for route, e in routes.items():
        if not e["params"]:
            for s in e["sources"]:
                prefix = s.split("->", 1)[0]
                m = s.split("->", 1)[1]
                for (cls, meth, desc), rec in by_source.items():
                    if cls == prefix and f"{meth}{desc}" == m and len(rec["routes"]) > 1:
                        e["params"] = list(rec["params"])
                        e["shared"] = True
                        break
                if e["params"]:
                    break

    # Second confidence tier: route-shaped string constants found anywhere in
    # the APK string pool.  These may be selected dynamically or live in
    # embedded SDKs, so they are flagged as inferred.
    inferred = 0
    if strings_path:
        import os
        sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
        from extract_endpoints import is_route, plausible_route

        bad_roots = {"image", "audio", "video", "text", "application"}
        with open(strings_path, encoding="utf-8", errors="replace") as f:
            for line in f:
                raw = line.rstrip("\n")
                if not is_route(raw) or not plausible_route(raw):
                    continue
                route = canonical(raw)
                if not route or "$" in route or ".." in route:
                    continue
                if "/" not in route and route not in {"cdns"}:
                    continue
                if route.split("/", 1)[0].lower() in bad_roots:
                    continue
                if route in routes:
                    continue
                e = routes.setdefault(route, {
                    "params": [], "sources": [], "variants": [],
                    "exact": False, "shared": False, "inferred": True,
                })
                e["inferred"] = True
                if raw not in e["variants"]:
                    e["variants"].append(raw)
                for k in query_keys(raw):
                    if k not in e["params"]:
                        e["params"].append(k)
                inferred += 1

    groups = {}
    for route in routes:
        groups.setdefault(group_of(route), []).append(route)
    for g in groups.values():
        g.sort()
    groups = OrderedDict(sorted(groups.items(), key=lambda kv: (-len(kv[1]), kv[0])))

    inferred_total = sum(1 for e in routes.values() if e.get("inferred"))
    lines = []
    w = lines.append
    w('"""Recovered NetEase Cloud Music API route catalog (auto-generated).')
    w("")
    w(f"Source: {len(records)} request-building methods recovered from the APK's 20 DEX files.")
    w(f"Routes: {len(routes)} canonical endpoints in {len(groups)} groups "
      f"({len(routes) - inferred_total} tied to a request builder, "
      f"{inferred_total} inferred from string constants).")
    w("")
    w("Params are recovered from the app's Map/JSONObject.put calls and query")
    w("templates where possible; `shared_params` marks routes whose parameter list")
    w("came from a method that builds several routes, so it may contain keys used")
    w("by a sibling route.  `inferred` routes were found only as string constants.")
    w('"""')
    w("from __future__ import annotations")
    w("")
    w("from dataclasses import dataclass, field")
    w("")
    w("")
    w("@dataclass(frozen=True)")
    w("class Endpoint:")
    w("    route: str")
    w("    params: tuple[str, ...] = ()")
    w("    sources: tuple[str, ...] = ()")
    w("    variants: tuple[str, ...] = ()")
    w("    group: str = \"misc\"")
    w("    shared_params: bool = False")
    w("    inferred: bool = False")
    w("")
    w("    def __str__(self) -> str:")
    w('        return self.route + ("?" + "&".join(self.params) if self.params else "")')
    w("")
    w("    def as_dict(self) -> dict:")
    w("        return {")
    w('            "route": self.route,')
    w('            "params": list(self.params),')
    w('            "sources": list(self.sources),')
    w('            "variants": list(self.variants),')
    w('            "group": self.group,')
    w('            "shared_params": self.shared_params,')
    w('            "inferred": self.inferred,')
    w("        }")
    w("")
    w("")
    def tup(items):
        if not items:
            return "()"
        body = ",".join(repr(i) for i in items)
        return f"({body},)" if len(items) == 1 else f"({body})"

    w("ENDPOINTS: dict[str, Endpoint] = {")
    for route, e in routes.items():
        srcs = tup(e["sources"])
        variants = tup(e["variants"])
        params = tup(e["params"])
        w(f"    {route!r}: Endpoint(route={route!r}, params={params},")
        w(f"        sources={srcs}, variants={variants}, group={group_of(route)!r},")
        w(f"        shared_params={e['shared']}, inferred={bool(e.get('inferred'))}),")
    w("}")
    w("")
    w("ROUTES: tuple[str, ...] = tuple(ENDPOINTS)")
    w("")
    w("GROUPS: dict[str, tuple[str, ...]] = {")
    for g, routes_in_group in groups.items():
        w(f"    {g!r}: (")
        line = "        "
        for r in routes_in_group:
            piece = repr(r) + ", "
            if len(line) + len(piece) > 100:
                w(line)
                line = "        "
            line += piece
        if line.strip():
            w(line)
        w("    ),")
    w("}")
    w("")
    w("")
    w("def get(route: str) -> Endpoint:")
    w('    """Look up an endpoint; tolerates leading slashes and /api/ prefixes."""')
    w("    key = route.strip().strip(\"/\")")
    w("    for prefix in (\"api/\", \"weapi/\", \"eapi/\", \"xeapi/\", \"neapi/\", \"linuxapi/\"):")
    w("        if key.startswith(prefix):")
    w("            key = key[len(prefix):]")
    w("            break")
    w("    key = key.split(\"?\", 1)[0].split(\"#\", 1)[0]")
    w("    if key in ENDPOINTS:")
    w("        return ENDPOINTS[key]")
    w("    for n in range(1, 10):")
    w("        candidate = f\"v{n}/{key}\"")
    w("        if candidate in ENDPOINTS:")
    w("            return ENDPOINTS[candidate]")
    w("    raise KeyError(f\"unknown route: {route!r}\")")
    w("")
    w("")
    w("def find(pattern: str) -> list[Endpoint]:")
    w('    """Case-insensitive substring search over all routes."""')
    w("    needle = pattern.lower()")
    w("    return [ep for r, ep in ENDPOINTS.items() if needle in r.lower()]")
    w("")
    w("")
    w("def summary() -> str:")
    w("    counts = {g: len(rs) for g, rs in GROUPS.items()}")
    w("    width = max((len(g) for g in counts), default=0)")
    w("    rows = [f\"{len(ENDPOINTS)} routes / {len(GROUPS)} groups\", \"\"]")
    w("    for g, n in counts.items():")
    w("        rows.append(f\"{g:<{width}}  {n:>4}\")")
    w("    return \"\\n\".join(rows)")
    w("")
    with open(out_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    print(f"routes={len(routes)} groups={len(groups)} -> {out_path}")
    print(Counter(group_of(r) for r in routes).most_common(15))


if __name__ == "__main__":
    main()
