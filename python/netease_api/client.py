"""The high-level client: one object exposing every recovered endpoint."""
from __future__ import annotations

import os
from typing import Any, Iterable, Mapping

import requests

from . import routes
from .apis import MIXINS
from .errors import NeteaseError
from .transport import DESKTOP_UA, Transport, TransportConfig

__all__ = ["NeteaseClient"]


class NeteaseClient(*MIXINS):
    """Class-style facade over all recovered 9.6.30 routes.

    Every method on the mixins (``song_detail``, ``playlist_detail``,
    ``comment_music``...) funnels into :meth:`call`, which encrypts and sends
    one request::

        client = NeteaseClient()
        client.search_songs("海阔天空")
        client.playlist_detail(3778678)
        client.song_url(347230, level="exhigh")

    Arbitrary catalog routes work through :meth:`call`::

        client.call("user/playlist", uid=123, limit=100)

    Transport modes: ``eapi`` (default), ``weapi``, ``api``, ``linuxapi``.
    Per-call overrides use underscore-prefixed keywords: ``_mode``, ``_method``,
    ``_headers``, ``_timeout``.
    """

    def __init__(
        self,
        mode: str = "eapi",
        *,
        cookies: Mapping[str, str] | str | None = None,
        cookie_file: str | None = None,
        session: requests.Session | None = None,
        transport: Transport | None = None,
        config: TransportConfig | None = None,
        base_url: str | None = None,
        base_urls: Mapping[str, str] | None = None,
        timeout: float = 15.0,
        retries: int = 2,
        user_agent: str = DESKTOP_UA,
        headers: Mapping[str, str] | None = None,
        proxies: Mapping[str, str] | None = None,
        inject_defaults: bool = True,
        default_params: Mapping[str, Any] | None = None,
        raise_on_api_error: bool = False,
        verify: bool | str = True,
    ) -> None:
        if transport is None:
            if config is None:
                config = TransportConfig(
                    mode=mode,
                    timeout=timeout,
                    retries=retries,
                    user_agent=user_agent,
                    headers=dict(headers or {}),
                    proxies=dict(proxies) if proxies else None,
                    inject_defaults=inject_defaults,
                    default_params=dict(default_params or {}),
                    raise_on_api_error=raise_on_api_error,
                    verify=verify,
                )
            if base_urls:
                config.base_urls.update(dict(base_urls))
            if base_url:
                config.base_urls[config.mode] = base_url
            transport = Transport(config, session=session, cookies=cookies)
        self.transport = transport
        self.session = transport.session
        self.profile: dict[str, Any] | None = None
        self.user_id: str | None = None
        self.last_response: Any = None
        if cookie_file:
            self.load_cookies(cookie_file)

    # ------------------------------------------------------------- transport
    @property
    def config(self) -> TransportConfig:
        return self.transport.config

    @property
    def mode(self) -> str:
        return self.transport.config.mode

    @mode.setter
    def mode(self, value: str) -> None:
        if value not in self.transport.config.base_urls:
            raise ValueError(f"unknown transport mode: {value!r}")
        self.transport.config.mode = value

    @property
    def cookies(self) -> dict[str, str]:
        return self.transport.cookies

    @property
    def csrf_token(self) -> str:
        return self.transport.csrf_token

    # ------------------------------------------------------------------ calls
    def call(self, route: str, /, **params: Any) -> Any:
        """Send one request and return the parsed response.

        ``route`` is positional-only so protocol parameters named ``self``
        (as in ``playlist/remove``) can be passed as keywords.  Underscore-
        prefixed keywords are transport controls, not parameters:

        ``_mode``     override the transport mode for this call
        ``_method``   ``"GET"`` or ``"POST"`` (default POST)
        ``_headers``  extra HTTP headers
        ``_timeout``  request timeout in seconds
        """
        mode = params.pop("_mode", None)
        method = params.pop("_method", None)
        headers = params.pop("_headers", None)
        timeout = params.pop("_timeout", None)
        data = self.transport.request(
            route,
            params,
            mode=mode,
            method=method,
            headers=headers,
            timeout=timeout,
        )
        self.last_response = data
        self._absorb(route, data)
        return data

    #: Aliases for :meth:`call`.
    request = call

    def raw(self, route: str, **params: Any) -> Any:
        """Alias for :meth:`call` (returns the unmodified response)."""
        return self.call(route, **params)

    def _absorb(self, route: str, data: Any) -> None:
        """Track login state from responses that carry a profile/account."""
        if not isinstance(data, dict):
            return
        profile = data.get("profile")
        account = data.get("account")
        if isinstance(profile, dict):
            self.profile = profile
        if isinstance(account, dict):
            if account.get("id") is not None:
                self.user_id = str(account["id"])
        if isinstance(profile, dict) and profile.get("userId") is not None:
            self.user_id = str(profile["userId"])

    def batch(
        self,
        calls: Iterable[tuple[str, Mapping[str, Any] | None] | Mapping[str, Any]],
        *,
        workers: int = 1,
        mode: str | None = None,
    ) -> list[dict[str, Any]]:
        """Run several independent calls; see :meth:`Transport.batch`."""
        return self.transport.batch(calls, workers=workers, mode=mode)

    # ---------------------------------------------------------------- routes
    @staticmethod
    def endpoint(route: str) -> routes.Endpoint:
        """Catalog metadata for a route."""
        return routes.get(route)

    @staticmethod
    def route_info(route: str) -> dict[str, Any]:
        """Catalog metadata as a plain dict."""
        return routes.get(route).as_dict()

    @staticmethod
    def find_routes(pattern: str) -> list[routes.Endpoint]:
        """Case-insensitive substring search across the catalog."""
        return routes.find(pattern)

    @staticmethod
    def route_count() -> int:
        """Number of catalog routes."""
        return len(routes.ENDPOINTS)

    # --------------------------------------------------------------- cookies
    def set_cookie(self, cookie: str) -> None:
        """Set a raw ``k=v; k=v`` cookie string."""
        self.transport.set_cookies(cookie)

    def save_cookies(self, path: str) -> None:
        self.transport.save_cookies(path)

    def load_cookies(self, path: str) -> None:
        self.transport.load_cookies(path)

    @classmethod
    def from_cookie(cls, cookie: str, **kwargs: Any) -> "NeteaseClient":
        """Build a client from a raw cookie string."""
        return cls(cookies=cookie, **kwargs)

    @classmethod
    def from_cookie_file(cls, path: str, **kwargs: Any) -> "NeteaseClient":
        """Build a client from a JSON cookie file."""
        return cls(cookie_file=path, **kwargs)

    @classmethod
    def from_env(cls, **kwargs: Any) -> "NeteaseClient":
        """Build a client from ``NETEASE_COOKIE`` or ``NETEASE_MUSIC_U``."""
        cookie = os.environ.get("NETEASE_COOKIE")
        if not cookie:
            music_u = os.environ.get("NETEASE_MUSIC_U")
            if music_u:
                cookie = f"MUSIC_U={music_u}"
        if not cookie:
            raise NeteaseError(
                "set NETEASE_COOKIE (full cookie string) or NETEASE_MUSIC_U in the environment"
            )
        return cls(cookies=cookie, **kwargs)

    # ------------------------------------------------------------- lifecycle
    def whoami(self) -> dict[str, Any]:
        """Refresh and return the logged-in profile."""
        data = self.call("nuser/account/get", _mode="api")
        self._absorb("nuser/account/get", data)
        return data

    def close(self) -> None:
        self.transport.close()

    def __enter__(self) -> "NeteaseClient":
        return self

    def __exit__(self, *exc_info: Any) -> None:
        self.close()

    def __repr__(self) -> str:
        who = self.user_id or "anonymous"
        return f"<NeteaseClient mode={self.mode!r} user={who} routes={self.route_count()}>"
