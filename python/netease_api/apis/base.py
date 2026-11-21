"""Shared helpers for the API mixins."""
from __future__ import annotations

import json
from typing import Any, Iterable

from .. import routes

__all__ = ["ApiMixin", "THREAD_PREFIXES", "RESOURCE_TYPES"]


# Standard NetEase comment thread ids.  These are protocol constants, not
# recovered from the APK; the app builds them from the same prefixes.
THREAD_PREFIXES = {
    "event": "R_EV_1_",
    "playlist": "R_PL_2_",
    "album": "R_AL_3_",
    "song": "R_SO_4_",
    "mv": "R_MV_5_",
    "dj": "R_DJ_6_",
    "radio": "R_RD_7_",
    "video": "R_VI_8_",
    "mlog": "R_MLOG_13_",
}

RESOURCE_TYPES = {
    "event": 1,
    "playlist": 2,
    "album": 3,
    "song": 4,
    "mv": 5,
    "dj": 6,
    "radio": 7,
    "video": 8,
    "mlog": 13,
}


class ApiMixin:
    """Base class for the client's resource mixins.

    ``call`` is provided by :class:`netease_api.client.NeteaseClient`; mixins
    never talk to the transport directly.
    """

    def call(self, route: str, /, **params: Any) -> Any:  # pragma: no cover - overridden
        raise NotImplementedError

    # ------------------------------------------------------------- utilities
    @staticmethod
    def endpoint(route: str) -> routes.Endpoint:
        """Return catalog metadata for a route (raises ``KeyError`` if absent)."""
        return routes.get(route)

    @staticmethod
    def _clean(**params: Any) -> dict[str, Any]:
        return {k: v for k, v in params.items() if v is not None}

    @staticmethod
    def _ids(value: str | int | Iterable[str | int]) -> str:
        if isinstance(value, (list, tuple, set, frozenset)):
            return ",".join(str(v) for v in value)
        return str(value)

    @staticmethod
    def _json_ids(value: str | int | Iterable[str | int]) -> str:
        if isinstance(value, (list, tuple, set, frozenset)):
            values = list(value)
        else:
            values = [value]
        ids: list[Any] = []
        for item in values:
            try:
                ids.append(int(item))
            except (TypeError, ValueError):
                ids.append(item)
        return json.dumps(ids, separators=(",", ":"))

    @staticmethod
    def _json(value: Any) -> str:
        return json.dumps(value, ensure_ascii=False, separators=(",", ":"))

    @staticmethod
    def _flag(value: bool | int | str) -> str:
        if isinstance(value, str):
            return value
        return "true" if value else "false"

    @staticmethod
    def _ms(value: str | int | Any) -> str:
        """Turn an id/thread/url into a string, leaving objects alone."""
        return value if isinstance(value, str) else str(value)

    def thread_id(self, resource_type: str | int, resource_id: str | int) -> str:
        """Build a comment thread id, e.g. ``R_SO_4_12345``."""
        if isinstance(resource_type, int):
            for name, code in RESOURCE_TYPES.items():
                if code == resource_type:
                    resource_type = name
                    break
        prefix = THREAD_PREFIXES.get(str(resource_type))
        if prefix is None:
            raise ValueError(f"unknown resource type: {resource_type!r}")
        return f"{prefix}{resource_id}"
