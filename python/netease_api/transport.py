"""HTTP transport for the recovered NetEase routes.

Four transport modes are supported:

``eapi``      /eapi/<route> on interface.music.163.com (AES-ECB body). Default.
``weapi``     /weapi/<route> on music.163.com (AES-CBC + RSA body).
``api``       /api/<route> on music.163.com, plain form.
``linuxapi``  /api/linux/forward, AES-ECB ``eparams``.

The APK's own ``xeapi``/native envelope is *not* implemented; see
:class:`~netease_api.errors.NativeEncryptionUnavailable`.
"""
from __future__ import annotations

import json
import os
import threading
import time
import uuid
from dataclasses import dataclass, field
from typing import Any, Iterable, Mapping, MutableMapping
from urllib.parse import parse_qsl, urlsplit

import requests

from . import crypto
from .errors import ApiError, NativeEncryptionUnavailable, TransportError, UnsupportedMode

__all__ = ["TransportConfig", "Transport", "DEFAULT_BASE_URLS", "DESKTOP_UA"]

DEFAULT_BASE_URLS = {
    "eapi": "https://interface.music.163.com/eapi/",
    "weapi": "https://music.163.com/weapi/",
    "api": "https://music.163.com/api/",
    "linuxapi": "https://music.163.com/api/linux/forward",
}

DESKTOP_UA = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
)

PREFIXES = ("api/", "weapi/", "eapi/", "xeapi/", "neapi/", "linuxapi/")
STATUSES_TO_RETRY = {408, 425, 429, 500, 502, 503, 504}


def normalize_route(route: str) -> tuple[str, dict[str, str]]:
    """Return (canonical path, query params) for any spelling of a route."""
    if "://" in route:
        parts = urlsplit(route)
        path = parts.path
        query = parts.query
    else:
        path, _, query = route.partition("?")
    path = path.strip().strip("/")
    for prefix in PREFIXES:
        if path.startswith(prefix):
            path = path[len(prefix):]
            break
    params: dict[str, str] = {}
    if query:
        for k, v in parse_qsl(query, keep_blank_values=True):
            params.setdefault(k, v)
    return path, params


@dataclass
class TransportConfig:
    mode: str = "eapi"
    base_urls: dict[str, str] = field(default_factory=lambda: dict(DEFAULT_BASE_URLS))
    timeout: float = 15.0
    retries: int = 2
    user_agent: str = DESKTOP_UA
    headers: dict[str, str] = field(default_factory=dict)
    cookies: dict[str, str] = field(default_factory=dict)
    proxies: dict[str, str] | None = None
    inject_defaults: bool = True
    default_params: dict[str, Any] = field(default_factory=dict)
    raise_on_api_error: bool = False
    verify: bool | str = True

    def __post_init__(self) -> None:
        if self.mode not in self.base_urls:
            raise UnsupportedMode(
                f"mode {self.mode!r} is not available; choose from {sorted(self.base_urls)}"
            )


class Transport:
    """Builds, encrypts, sends and parses one request per call."""

    def __init__(
        self,
        config: TransportConfig | None = None,
        session: requests.Session | None = None,
        cookies: Mapping[str, str] | str | None = None,
    ) -> None:
        self.config = config or TransportConfig()
        self.session = session or requests.Session()
        self._local = threading.local()
        self.session.headers.update(self._default_headers())
        if self.config.proxies:
            self.session.proxies.update(self.config.proxies)
        self.session.cookies.update(self.config.cookies)
        if cookies:
            self.set_cookies(cookies)

    # ------------------------------------------------------------------ setup
    def _default_headers(self) -> dict[str, str]:
        headers = {
            "User-Agent": self.config.user_agent,
            "Accept": "*/*",
            "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.6",
            "Content-Type": "application/x-www-form-urlencoded",
            "Referer": "https://music.163.com/",
            "Origin": "https://music.163.com",
        }
        headers.update(self.config.headers)
        return headers

    def _new_session(self) -> requests.Session:
        session = requests.Session()
        session.headers.update(dict(self.session.headers))
        session.cookies.update(self.session.cookies)
        if self.config.proxies:
            session.proxies.update(self.config.proxies)
        return session

    def _thread_session(self) -> requests.Session:
        session = getattr(self._local, "session", None)
        if session is None:
            session = self._new_session()
            self._local.session = session
        return session

    # ---------------------------------------------------------------- cookies
    def set_cookies(self, cookies: Mapping[str, str] | str | None) -> None:
        if not cookies:
            return
        if isinstance(cookies, str):
            pairs = {}
            for part in cookies.split(";"):
                if "=" in part:
                    k, v = part.split("=", 1)
                    pairs[k.strip()] = v.strip()
            cookies = pairs
        self.session.cookies.update(dict(cookies))

    @property
    def cookies(self) -> dict[str, str]:
        return requests.utils.dict_from_cookiejar(self.session.cookies)

    @property
    def cookie_header(self) -> str:
        return "; ".join(f"{k}={v}" for k, v in self.cookies.items())

    @property
    def csrf_token(self) -> str:
        return self.cookies.get("__csrf", "")

    def save_cookies(self, path: str) -> None:
        """Write the cookie jar to ``path`` readable only by its owner.

        The file is a live credential; it is created with mode ``0600`` (and
        re-tightened if it already existed) so other local users cannot read
        it. On platforms without POSIX modes the mode is simply ignored.
        """
        fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            json.dump(self.cookies, f, ensure_ascii=False, indent=2)
        try:
            os.chmod(path, 0o600)
        except OSError:  # pragma: no cover - non-POSIX filesystems
            pass

    def load_cookies(self, path: str) -> None:
        with open(path, encoding="utf-8") as f:
            self.set_cookies(json.load(f))

    # ------------------------------------------------------------------- URLs
    def url_for(self, route: str, mode: str | None = None) -> str:
        mode = mode or self.config.mode
        if mode == "native" or mode == "xeapi":
            raise NativeEncryptionUnavailable(
                "the APK's native xeapi/Aegis envelope is not implemented; "
                "use mode='eapi', 'weapi', 'api' or 'linuxapi'"
            )
        if mode not in self.config.base_urls:
            raise UnsupportedMode(f"unknown transport mode: {mode!r}")
        path, _ = normalize_route(route)
        if mode == "linuxapi":
            return self.config.base_urls[mode]
        url = self.config.base_urls[mode] + path
        if mode == "weapi":
            url += f"?csrf_token={self.csrf_token}"
        return url

    # --------------------------------------------------------------- payloads
    def _defaults(self, params: MutableMapping[str, Any]) -> None:
        defaults = {
            "os": "android",
            "appver": "9.6.30",
            "osver": "13",
            "channel": "netease",
            "deviceId": self._device_id(),
            "requestId": uuid.uuid4().hex,
        }
        defaults.update(self.config.default_params)
        for key, value in defaults.items():
            params.setdefault(key, value)

    def _device_id(self) -> str:
        if not hasattr(self, "_cached_device_id"):
            self._cached_device_id = uuid.uuid4().hex
        return self._cached_device_id

    def build_payload(
        self, route: str, params: Mapping[str, Any] | None = None, mode: str | None = None
    ) -> dict[str, Any]:
        mode = mode or self.config.mode
        path, query = normalize_route(route)
        body: dict[str, Any] = dict(query)
        if params:
            body.update({k: v for k, v in params.items() if v is not None})
        if mode == "eapi":
            if self.config.inject_defaults:
                self._defaults(body)
            if self.csrf_token:
                # NetEase rejects authenticated writes from eapi with
                # "illegal request!" unless the CSRF token is in the body.
                body.setdefault("csrf_token", self.csrf_token)
            api_path = "/api/" + path
            return {"params": crypto.eapi_encrypt(api_path, body)}
        if mode == "weapi":
            encrypted = crypto.weapi_encrypt(body)
            encrypted["csrf_token"] = self.csrf_token
            return encrypted
        if mode == "api":
            if self.csrf_token:
                body.setdefault("csrf_token", self.csrf_token)
            return body
        if mode == "linuxapi":
            return {"eparams": crypto.linuxapi_encrypt("/api/" + path, body)}
        raise UnsupportedMode(f"unknown transport mode: {mode!r}")

    # -------------------------------------------------------------- requests
    def request(
        self,
        route: str,
        params: Mapping[str, Any] | None = None,
        *,
        mode: str | None = None,
        method: str | None = None,
        headers: Mapping[str, str] | None = None,
        timeout: float | None = None,
        session: requests.Session | None = None,
    ) -> Any:
        mode = mode or self.config.mode
        if mode in ("native", "xeapi"):
            raise NativeEncryptionUnavailable(
                "the APK's native xeapi/Aegis envelope is not implemented; "
                "use mode='eapi', 'weapi', 'api' or 'linuxapi'"
            )
        url = self.url_for(route, mode)
        payload = self.build_payload(route, params, mode)
        method = (method or "POST").upper()
        request_headers = dict(self._default_headers())
        if headers:
            request_headers.update(headers)
        request_session = session or self.session
        attempts = max(0, int(self.config.retries)) + 1
        last_error: Exception | None = None

        for attempt in range(attempts):
            try:
                if method == "GET":
                    response = request_session.get(
                        url,
                        params=payload,
                        headers=request_headers,
                        timeout=timeout or self.config.timeout,
                        verify=self.config.verify,
                    )
                else:
                    response = request_session.post(
                        url,
                        data=payload,
                        headers=request_headers,
                        timeout=timeout or self.config.timeout,
                        verify=self.config.verify,
                    )
            except requests.RequestException as exc:
                last_error = exc
                if attempt + 1 < attempts:
                    time.sleep(min(0.4 * (2 ** attempt), 4.0))
                    continue
                raise TransportError(f"request failed: {exc}") from exc

            if response.status_code in STATUSES_TO_RETRY and attempt + 1 < attempts:
                time.sleep(min(0.4 * (2 ** attempt), 4.0))
                continue
            if response.status_code >= 400:
                snippet = response.text[:300]
                raise TransportError(
                    f"HTTP {response.status_code} for {url}: {snippet}",
                    status=response.status_code,
                    payload=snippet,
                )
            data = self._parse(response)
            if (
                self.config.raise_on_api_error
                and isinstance(data, dict)
                and data.get("code") not in (None, 200)
            ):
                raise ApiError(
                    data.get("code"),
                    str(data.get("message") or data.get("msg") or ""),
                    payload=data,
                )
            return data

        raise TransportError(f"request failed after {attempts} attempts: {last_error}")

    @staticmethod
    def _parse(response: requests.Response) -> Any:
        text = response.text.lstrip("﻿").strip()
        if not text:
            return None
        try:
            return json.loads(text)
        except json.JSONDecodeError:
            return text

    # ------------------------------------------------------------------ batch
    def batch(
        self,
        calls: Iterable[tuple[str, Mapping[str, Any] | None] | Mapping[str, Any]],
        *,
        workers: int = 1,
        mode: str | None = None,
    ) -> list[dict[str, Any]]:
        """Run several calls; each result is ``{route, ok, data|error}``.

        ``workers > 1`` uses one requests session per thread.  It is intended
        for independent read-only calls; cookie changes from concurrent calls
        are not merged back into the main session.
        """
        normalized: list[tuple[str, Mapping[str, Any] | None]] = []
        for call in calls:
            if isinstance(call, Mapping):
                normalized.append((call["route"], call.get("params")))
            else:
                normalized.append((call[0], call[1] if len(call) > 1 else None))

        def run(item: tuple[str, Mapping[str, Any] | None]) -> dict[str, Any]:
            route, params = item
            session = self.session if workers <= 1 else self._thread_session()
            try:
                return {"route": route, "ok": True,
                        "data": self.request(route, params, mode=mode, session=session)}
            except Exception as exc:  # keep batch results homogeneous
                return {"route": route, "ok": False, "error": exc, "params": params}

        if workers <= 1:
            return [run(item) for item in normalized]
        from concurrent.futures import ThreadPoolExecutor

        with ThreadPoolExecutor(max_workers=workers) as pool:
            return list(pool.map(run, normalized))

    def close(self) -> None:
        self.session.close()
