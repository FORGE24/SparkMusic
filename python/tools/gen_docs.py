"""Generate ROUTES.md (full route appendix) from the recovered catalog."""
from __future__ import annotations

import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from netease_api import routes  # noqa: E402

OUT = ROOT / "ROUTES.md"
RST_OUT = ROOT / "docs" / "route_catalog.rst"


def main() -> None:
    lines: list[str] = []
    total = len(routes.ENDPOINTS)
    inferred = sum(1 for e in routes.ENDPOINTS.values() if e.inferred)
    recovered = total - inferred
    lines.append("# Recovered route catalog")
    lines.append("")
    lines.append(
        f"{total} canonical routes in {len(routes.GROUPS)} groups. "
        f"{recovered} are tied to a request-builder method recovered from the "
        f"9.6.30 DEX code; {inferred} were inferred from route-shaped string "
        "constants that the app assembles dynamically."
    )
    lines.append("")
    lines.append(
        "`params` lists the body/query keys recovered from the app's `put` "
        "calls or query templates. A route marked **inferred** has no "
        "recovered parameter list unless one is shown."
    )
    lines.append("")
    lines.append("| group | routes |")
    lines.append("|---|---:|")
    for group, endpoints in routes.GROUPS.items():
        lines.append(f"| {group} | {len(endpoints)} |")
    lines.append("")

    for group, endpoints in routes.GROUPS.items():
        lines.append(f"## {group} ({len(endpoints)})")
        lines.append("")
        for endpoint in sorted(
            (routes.ENDPOINTS[r] for r in endpoints), key=lambda e: e.route
        ):
            suffix = ""
            if endpoint.params:
                suffix = "  — `" + "`, `".join(endpoint.params) + "`"
            if endpoint.inferred:
                suffix += "  *(inferred)*"
            lines.append(f"- `{endpoint.route}`{suffix}")
        lines.append("")

    OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"wrote {OUT} ({len(lines)} lines, {total} routes)")
    write_rst(total, recovered, inferred)


def write_rst(total: int, recovered: int, inferred: int) -> None:
    lines: list[str] = []
    lines.append("Route catalog")
    lines.append("=============")
    lines.append("")
    lines.append(
        f"{total} canonical routes in {len(routes.GROUPS)} groups. {recovered} are "
        f"tied to a request-builder method recovered from the 9.6.30 DEX code; "
        f"{inferred} were inferred from route-shaped string constants that the app "
        "assembles dynamically."
    )
    lines.append("")
    lines.append(
        "``params`` lists the body/query keys recovered from the app's ``put`` "
        "calls or query templates. A route marked **inferred** has no recovered "
        "parameter list unless one is shown."
    )
    lines.append("")
    lines.append(".. list-table:: Routes per group")
    lines.append("   :header-rows: 1")
    lines.append("   :widths: 40 10")
    lines.append("")
    lines.append("   * - Group")
    lines.append("     - Routes")
    for group, endpoints in routes.GROUPS.items():
        lines.append(f"   * - {group}")
        lines.append(f"     - {len(endpoints)}")
    lines.append("")

    for group, endpoints in routes.GROUPS.items():
        title = f"{group} ({len(endpoints)})"
        lines.append(title)
        lines.append("-" * len(title))
        lines.append("")
        for endpoint in sorted(
            (routes.ENDPOINTS[r] for r in endpoints), key=lambda e: e.route
        ):
            suffix = ""
            if endpoint.params:
                suffix = " — " + ", ".join(f"``{p}``" for p in endpoint.params)
            if endpoint.inferred:
                suffix += " *(inferred)*"
            lines.append(f"* ``{endpoint.route}``{suffix}")
        lines.append("")

    RST_OUT.parent.mkdir(parents=True, exist_ok=True)
    RST_OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"wrote {RST_OUT} ({len(lines)} lines)")


if __name__ == "__main__":
    main()
