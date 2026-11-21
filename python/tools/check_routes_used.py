"""Static check: every literal route passed to self.call() exists in the catalog."""
from __future__ import annotations

import ast
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from netease_api import routes  # noqa: E402

#: Public endpoints the client ships as compatibility fallbacks.  These were
#: not recovered from the 9.6.30 APK (the app no longer calls them directly).
CLASSIC = {
    "login",
    "login/qrcode/unikey",
    "login/qrcode/client/login",
    "nuser/account/get",
    "logout",
    "user/getfolloweds",
    "user/level",
    "user/subcount",
}

missing: list[tuple[str, int, str]] = []
used: set[str] = set()

for path in sorted((ROOT / "netease_api" / "apis").glob("*.py")):
    tree = ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
    for node in ast.walk(tree):
        if not isinstance(node, ast.Call):
            continue
        func = node.func
        if not isinstance(func, ast.Attribute) or func.attr != "call":
            continue
        if not node.args:
            continue
        arg = node.args[0]
        if isinstance(arg, ast.Constant) and isinstance(arg.value, str):
            route = arg.value
            used.add(route)
            if route not in routes.ENDPOINTS and route not in CLASSIC:
                missing.append((str(path.relative_to(ROOT)), node.lineno, route))

print(f"literal calls: {len(used)}")
if missing:
    print(f"missing routes: {len(missing)}")
    for path, line, route in missing:
        print(f"  {path}:{line}  {route}")
    raise SystemExit(1)
print("all literal routes exist")

# report dynamic call sites (f-strings / variables) for manual review
dynamic = []
for path in sorted((ROOT / "netease_api" / "apis").glob("*.py")):
    tree = ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
    for node in ast.walk(tree):
        if isinstance(node, ast.Call) and isinstance(node.func, ast.Attribute) and node.func.attr == "call":
            if node.args and not (isinstance(node.args[0], ast.Constant) and isinstance(node.args[0].value, str)):
                dynamic.append((str(path.relative_to(ROOT)), node.lineno, ast.unparse(node.args[0])))
print(f"dynamic call sites: {len(dynamic)}")
for item in dynamic:
    print("  %s:%d  %s" % item)
