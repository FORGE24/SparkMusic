"""Python client for the NetEase Cloud Music API recovered from Android 9.6.30.

Quick start::

    from netease_api import NeteaseClient

    client = NeteaseClient()                 # anonymous
    client.search_songs("海阔天空", limit=10)
    client.song_url(347230, level="exhigh")

    client = NeteaseClient.from_env()        # NETEASE_COOKIE / NETEASE_MUSIC_U
    client.playlist_detail(3778678)

Every route in the recovered catalog is callable through ``client.call()``;
:mod:`netease_api.routes` exposes the full list and metadata.
"""
from __future__ import annotations

from . import crypto, routes
from .client import NeteaseClient
from .errors import (
    ApiError,
    EncryptionError,
    NativeEncryptionUnavailable,
    NeteaseError,
    TransportError,
    UnsupportedMode,
)
from .transport import DEFAULT_BASE_URLS, DESKTOP_UA, Transport, TransportConfig

__version__ = "1.0.0"

__all__ = [
    "NeteaseClient",
    "Transport",
    "TransportConfig",
    "DEFAULT_BASE_URLS",
    "DESKTOP_UA",
    "crypto",
    "routes",
    "NeteaseError",
    "TransportError",
    "ApiError",
    "EncryptionError",
    "NativeEncryptionUnavailable",
    "UnsupportedMode",
    "__version__",
]
