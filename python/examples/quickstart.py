"""Minimal examples for the recovered NetEase Cloud Music client.

Run:  python examples/quickstart.py
The anonymous calls work without login; the personalized ones need a cookie.
"""
from __future__ import annotations

import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from netease_api import NeteaseClient


def show(title: str, data: object) -> None:
    print(f"\n== {title} ==")
    print(json.dumps(data, ensure_ascii=False, indent=2)[:800])


def main() -> None:
    client = NeteaseClient()  # eapi transport, anonymous session

    show("search", client.search_songs("海阔天空", limit=3))
    show("song detail", client.song_detail(347230))
    show("playback url", client.song_url(347230, level="exhigh"))
    show("playlist", client.playlist_detail(3778678, track_limit=5))

    # Any of the 1,287 catalog routes can be called directly.
    show("generic call", client.call("mlog/detail", id="a_mlog_id"))

    if os.environ.get("NETEASE_COOKIE") or os.environ.get("NETEASE_MUSIC_U"):
        authed = NeteaseClient.from_env()
        show("account", authed.whoami())
        show("daily recommendations", authed.recommend_songs())

    client.close()


if __name__ == "__main__":
    main()
