"""Exceptions raised by the NetEase client."""
from __future__ import annotations

from typing import Any

__all__ = [
    "NeteaseError",
    "TransportError",
    "ApiError",
    "EncryptionError",
    "NativeEncryptionUnavailable",
    "UnsupportedMode",
]


class NeteaseError(Exception):
    """Base class for every error raised by this package."""


class TransportError(NeteaseError):
    """The HTTP request failed (network error, timeout, or bad status)."""

    def __init__(self, message: str, status: int | None = None, payload: Any = None):
        super().__init__(message)
        self.status = status
        self.payload = payload


class ApiError(NeteaseError):
    """The server answered, but the JSON ``code`` was not 200.

    Only raised when ``raise_on_api_error=True`` on the client/config; by
    default the raw response is returned so callers can inspect partial
    results and non-200 success codes.
    """

    def __init__(self, code: int | str | None, message: str = "", payload: Any = None):
        self.code = code
        self.payload = payload
        super().__init__(f"API error {code}: {message}" if message else f"API error {code}")


class EncryptionError(NeteaseError):
    """Payload encryption failed."""


class NativeEncryptionUnavailable(EncryptionError):
    """The APK's native xeapi/Aegis envelope was requested but is not implemented.

    The 9.6.30 client encrypts requests inside libcaesar/libcaesarson/Aegis and
    negotiates a per-session key via ``bsr/sk/get``.  Reproducing that scheme
    requires the native libraries and a session handshake, which this pure
    Python client intentionally does not do.  Use ``mode="eapi"`` (default),
    ``"weapi"``, ``"api"`` or ``"linuxapi"`` instead.
    """


class UnsupportedMode(NeteaseError):
    """Unknown transport mode was requested."""
