"""Command-line interface for the recovered NetEase Cloud Music API.

Examples::

    python -m netease_api routes comment --group comment --params
    python -m netease_api call song/detail ids=[347230]
    python -m netease_api search 海阔天空 --type song --limit 5
    python -m netease_api playlist 3778678
    python -m netease_api login cellphone --phone 13800000000 --password secret \
        --save-cookies cookies.json
"""
from __future__ import annotations

import argparse
import json
import os
import sys
from typing import Any

from . import __version__, routes
from .apis import SEARCH_TYPES
from .client import NeteaseClient
from .errors import NeteaseError


# --------------------------------------------------------------------- output
def emit(data: Any, as_json: bool = True) -> None:
    if as_json or not isinstance(data, str):
        text = json.dumps(data, ensure_ascii=False, indent=2, default=str)
    else:
        text = data
    stream = getattr(sys.stdout, "buffer", None)
    if stream is not None:
        stream.write((text + "\n").encode("utf-8", "replace"))
    else:  # pragma: no cover - unusual stdout
        print(text)


# -------------------------------------------------------------------- parsing
def parse_value(value: str) -> Any:
    lowered = value.lower()
    if lowered in ("true", "false"):
        return lowered == "true"
    if lowered == "null":
        return None
    try:
        return int(value)
    except ValueError:
        pass
    try:
        return float(value)
    except ValueError:
        pass
    if value[:1] in "[{":
        try:
            return json.loads(value)
        except json.JSONDecodeError:
            pass
    if value.startswith("@"):
        with open(value[1:], encoding="utf-8") as f:
            return f.read()
    return value


def parse_params(pairs: list[str]) -> dict[str, Any]:
    params: dict[str, Any] = {}
    for pair in pairs:
        if "=" not in pair:
            raise SystemExit(f"expected key=value, got {pair!r}")
        key, value = pair.split("=", 1)
        parsed = parse_value(value)
        if key in params:
            existing = params[key]
            if isinstance(existing, list):
                existing.append(parsed)
            else:
                params[key] = [existing, parsed]
        else:
            params[key] = parsed
    return params


def make_client(args: argparse.Namespace) -> NeteaseClient:
    return NeteaseClient(
        mode=getattr(args, "mode", "eapi"),
        cookies=getattr(args, "cookie", None),
        cookie_file=getattr(args, "cookie_file", None),
        timeout=getattr(args, "timeout", 15.0),
        raise_on_api_error=getattr(args, "strict", False),
    )


# -------------------------------------------------------------------- commands
def cmd_routes(args: argparse.Namespace) -> int:
    found = routes.find(args.search) if args.search else list(routes.ENDPOINTS.values())
    if args.group:
        found = [e for e in found if e.group == args.group]
    if args.recovered:
        found = [e for e in found if not e.inferred]
    if args.inferred:
        found = [e for e in found if e.inferred]
    found.sort(key=lambda e: e.route)
    if args.json:
        payload = [e.as_dict() for e in found]
    else:
        payload = []
        for endpoint in found:
            line = endpoint.route
            if args.params and endpoint.params:
                line += "  " + ", ".join(endpoint.params)
            if endpoint.inferred and not args.quiet:
                line += "  [inferred]"
            payload.append(line)
    emit(payload)
    return 0


def cmd_call(args: argparse.Namespace) -> int:
    client = make_client(args)
    params = parse_params(args.params)
    if args.param_file:
        with open(args.param_file, encoding="utf-8") as f:
            params.update(json.load(f))
    data = client.call(
        args.route,
        _mode=args.mode,
        _method="GET" if args.get else None,
        _timeout=args.timeout,
        **params,
    )
    emit(data)
    return 0


def cmd_login(args: argparse.Namespace) -> int:
    client = make_client(args)
    if args.login_kind == "cellphone":
        data = client.login_cellphone(
            args.phone, password=args.password, captcha=args.captcha,
            country_code=args.country_code,
        )
    elif args.login_kind == "email":
        data = client.login_email(args.email, args.password)
    elif args.login_kind == "qr":
        data = client.login_qrcode_create()
        key = data.get("unikey") if isinstance(data, dict) else None
        emit(data)
        if key:
            print(f"QR key: {key} (poll with: login qr-check {key})", file=sys.stderr)
        return 0
    elif args.login_kind == "qr-check":
        data = client.login_qrcode_check(args.key)
    else:  # pragma: no cover - argparse restricts choices
        raise SystemExit(f"unknown login kind {args.login_kind}")
    emit(data)
    if args.save_cookies:
        client.save_cookies(args.save_cookies)
        print(f"cookies saved to {args.save_cookies}", file=sys.stderr)
    return 0


def cmd_search(args: argparse.Namespace) -> int:
    client = make_client(args)
    emit(client.search(args.keyword, args.type, args.limit, args.offset))
    return 0


def cmd_song(args: argparse.Namespace) -> int:
    client = make_client(args)
    if args.lyric:
        emit(client.song_lyric(args.id))
    elif args.url:
        emit(client.song_url(args.id, level=args.level))
    else:
        emit(client.song_detail(args.id))
    return 0


def cmd_playlist(args: argparse.Namespace) -> int:
    client = make_client(args)
    emit(client.playlist_detail(args.id, track_limit=args.limit))
    return 0


def cmd_user(args: argparse.Namespace) -> int:
    client = make_client(args)
    if args.playlists:
        emit(client.user_playlists(args.id))
    else:
        emit(client.user_detail(args.id))
    return 0


# ---------------------------------------------------------------------- parser
def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="netease_api",
        description="Client for the NetEase Cloud Music API recovered from Android 9.6.30",
    )
    parser.add_argument("--version", action="version", version=f"%(prog)s {__version__}")
    sub = parser.add_subparsers(dest="command", required=True)

    def add_common(p: argparse.ArgumentParser) -> None:
        p.add_argument("--mode", default="eapi", choices=["eapi", "weapi", "api", "linuxapi"])
        p.add_argument("--cookie", default=os.environ.get("NETEASE_COOKIE"))
        p.add_argument("--cookie-file")
        p.add_argument("--timeout", type=float, default=15.0)
        p.add_argument("--strict", action="store_true", help="raise on non-200 JSON codes")

    p_routes = sub.add_parser("routes", help="list/search the recovered route catalog")
    p_routes.add_argument("search", nargs="?", help="substring filter")
    p_routes.add_argument("--group")
    p_routes.add_argument("--params", action="store_true", help="show parameter keys")
    p_routes.add_argument("--recovered", action="store_true", help="builder-recovered only")
    p_routes.add_argument("--inferred", action="store_true", help="string-pool inferred only")
    p_routes.add_argument("--json", action="store_true")
    p_routes.add_argument("--quiet", action="store_true")
    p_routes.set_defaults(func=cmd_routes)

    p_call = sub.add_parser("call", help="call any catalog route")
    p_call.add_argument("route")
    p_call.add_argument("params", nargs="*", help="key=value (repeatable)")
    p_call.add_argument("--param-file", help="JSON file with extra parameters")
    p_call.add_argument("--get", action="store_true")
    add_common(p_call)
    p_call.set_defaults(func=cmd_call)

    p_login = sub.add_parser("login", help="log in and optionally save cookies")
    p_login.add_argument("login_kind", choices=["cellphone", "email", "qr", "qr-check"])
    p_login.add_argument("--phone")
    p_login.add_argument("--email")
    p_login.add_argument("--password")
    p_login.add_argument("--captcha")
    p_login.add_argument("--country-code", default="86")
    p_login.add_argument("--key", help="QR unikey for qr-check")
    p_login.add_argument("--save-cookies")
    add_common(p_login)
    p_login.set_defaults(func=cmd_login)

    p_search = sub.add_parser("search", help="search songs/albums/artists/...")
    p_search.add_argument("keyword")
    p_search.add_argument(
        "--type", default="song", choices=sorted(SEARCH_TYPES)
    )
    p_search.add_argument("--limit", type=int, default=30)
    p_search.add_argument("--offset", type=int, default=0)
    add_common(p_search)
    p_search.set_defaults(func=cmd_search)

    p_song = sub.add_parser("song", help="song detail / url / lyric")
    p_song.add_argument("id", type=int)
    p_song.add_argument("--url", action="store_true")
    p_song.add_argument("--lyric", action="store_true")
    p_song.add_argument("--level", default="standard")
    add_common(p_song)
    p_song.set_defaults(func=cmd_song)

    p_playlist = sub.add_parser("playlist", help="playlist detail")
    p_playlist.add_argument("id", type=int)
    p_playlist.add_argument("--limit", type=int, default=1000)
    add_common(p_playlist)
    p_playlist.set_defaults(func=cmd_playlist)

    p_user = sub.add_parser("user", help="user detail / playlists")
    p_user.add_argument("id", type=int)
    p_user.add_argument("--playlists", action="store_true")
    add_common(p_user)
    p_user.set_defaults(func=cmd_user)

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        return int(args.func(args) or 0)
    except NeteaseError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2
    except BrokenPipeError:  # pragma: no cover
        return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
