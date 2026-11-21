"""Transport tests with a fake HTTP session (no network)."""
from __future__ import annotations

import json
import os
import stat
import tempfile
import unittest
from unittest import mock

import requests
from requests.cookies import RequestsCookieJar
from requests.structures import CaseInsensitiveDict

from netease_api import crypto
from netease_api.errors import ApiError, NativeEncryptionUnavailable, TransportError
from netease_api.transport import Transport, TransportConfig

try:
    from Crypto.Cipher import AES
    from Crypto.Util.Padding import unpad
except ImportError:  # pragma: no cover
    AES = None


class FakeResponse:
    def __init__(self, body: str = '{"code":200}', status: int = 200) -> None:
        self.text = body
        self.status_code = status


class FakeSession:
    """Minimal stand-in for requests.Session that records requests."""

    def __init__(self) -> None:
        self.headers = CaseInsensitiveDict()
        self.cookies = RequestsCookieJar()
        self.proxies: dict[str, str] = {}
        self.calls: list[dict] = []
        self.responses: list[FakeResponse] = []

    def _record(self, method: str, url: str, **kwargs) -> FakeResponse:
        self.calls.append({"method": method, "url": url, **kwargs})
        if self.responses:
            return self.responses.pop(0)
        return FakeResponse()

    def post(self, url, data=None, headers=None, timeout=None, verify=True):
        return self._record("POST", url, data=data, headers=headers, timeout=timeout)

    def get(self, url, params=None, headers=None, timeout=None, verify=True):
        return self._record("GET", url, params=params, headers=headers, timeout=timeout)

    def close(self) -> None:
        pass


def make_transport(mode: str = "eapi", **config_kw) -> tuple[Transport, FakeSession]:
    session = FakeSession()
    kwargs = dict(mode=mode, retries=0)
    kwargs.update(config_kw)
    return Transport(TransportConfig(**kwargs), session=session), session


class UrlTests(unittest.TestCase):
    def test_prefixes_are_stripped(self) -> None:
        transport, _ = make_transport("eapi")
        for route in ("song/detail", "/api/song/detail", "eapi/song/detail", "weapi/song/detail"):
            self.assertEqual(
                transport.url_for(route), "https://interface.music.163.com/eapi/song/detail"
            )

    def test_weapi_adds_csrf_token(self) -> None:
        transport, _ = make_transport("weapi")
        transport.set_cookies({"__csrf": "tok123"})
        self.assertTrue(transport.url_for("user/playlist").endswith(
            "https://music.163.com/weapi/user/playlist?csrf_token=tok123"
        ))

    def test_native_is_rejected(self) -> None:
        transport, _ = make_transport()
        with self.assertRaises(NativeEncryptionUnavailable):
            transport.url_for("song/detail", mode="native")
        with self.assertRaises(NativeEncryptionUnavailable):
            transport.url_for("song/detail", mode="xeapi")


class PayloadTests(unittest.TestCase):
    def test_eapi_defaults_and_body(self) -> None:
        transport, _ = make_transport("eapi")
        payload = transport.build_payload("song/detail", {"ids": "[1]"})
        self.assertEqual(set(payload), {"params"})
        body = payload["params"]
        self.assertEqual(body, body.upper())
        int(body, 16)
        if AES is None:
            self.skipTest("pycryptodome not installed")
        raw = unpad(AES.new(crypto.EAPI_KEY, AES.MODE_ECB).decrypt(bytes.fromhex(body)), 16)
        url, text, digest = raw.decode().split(crypto.EAPI_SEPARATOR)
        self.assertEqual(url, "/api/song/detail")
        params = json.loads(text)
        self.assertEqual(params["ids"], "[1]")
        for key in ("os", "appver", "osver", "channel", "deviceId", "requestId"):
            self.assertIn(key, params)
            self.assertTrue(params[key])
        self.assertEqual(digest, crypto.eapi_digest(url, text))

    def test_eapi_without_defaults(self) -> None:
        transport, _ = make_transport("eapi", inject_defaults=False)
        payload = transport.build_payload("x/y", {"a": 1})
        if AES is None:
            self.skipTest("pycryptodome not installed")
        raw = unpad(
            AES.new(crypto.EAPI_KEY, AES.MODE_ECB).decrypt(bytes.fromhex(payload["params"])), 16
        )
        _, text, _ = raw.decode().split(crypto.EAPI_SEPARATOR)
        self.assertEqual(json.loads(text), {"a": 1})

    def test_eapi_includes_csrf_token(self) -> None:
        transport, _ = make_transport("eapi", inject_defaults=False)
        transport.set_cookies({"__csrf": "tok"})
        payload = transport.build_payload("x/y", {"a": 1})
        if AES is None:
            self.skipTest("pycryptodome not installed")
        raw = unpad(
            AES.new(crypto.EAPI_KEY, AES.MODE_ECB).decrypt(bytes.fromhex(payload["params"])), 16
        )
        _, text, _ = raw.decode().split(crypto.EAPI_SEPARATOR)
        self.assertEqual(
            json.loads(text), {"a": 1, "csrf_token": "tok"}
        )

    def test_weapi_payload_shape(self) -> None:
        transport, _ = make_transport("weapi")
        transport.set_cookies({"__csrf": "c"})
        payload = transport.build_payload("user/playlist", {"uid": 1})
        self.assertEqual(set(payload), {"params", "encSecKey", "csrf_token"})
        self.assertTrue(len(payload["encSecKey"]) == 256)
        int(payload["encSecKey"], 16)

    def test_api_payload_plain(self) -> None:
        transport, _ = make_transport("api")
        transport.set_cookies({"__csrf": "tok"})
        payload = transport.build_payload("user/playlist", {"uid": 1})
        self.assertEqual(payload["uid"], 1)
        self.assertEqual(payload["csrf_token"], "tok")

    def test_linuxapi_payload(self) -> None:
        transport, _ = make_transport("linuxapi")
        payload = transport.build_payload("song/detail", {"ids": "[1]"})
        self.assertEqual(set(payload), {"eparams"})
        if AES is None:
            self.skipTest("pycryptodome not installed")
        raw = unpad(
            AES.new(crypto.LINUXAPI_KEY, AES.MODE_ECB).decrypt(bytes.fromhex(payload["eparams"])), 16
        )
        inner = json.loads(raw)
        self.assertEqual(inner["url"], "/api/song/detail")
        self.assertEqual(inner["params"], {"ids": "[1]"})

    def test_query_template_route(self) -> None:
        transport, _ = make_transport("eapi")
        payload = transport.build_payload("user/playlist?uid=5&limit=2", {"offset": 0})
        if AES is None:
            self.skipTest("pycryptodome not installed")
        raw = unpad(
            AES.new(crypto.EAPI_KEY, AES.MODE_ECB).decrypt(bytes.fromhex(payload["params"])), 16
        )
        _, text, _ = raw.decode().split(crypto.EAPI_SEPARATOR)
        body = json.loads(text)
        self.assertEqual((body["uid"], body["limit"], body["offset"]), ("5", "2", 0))


class RequestTests(unittest.TestCase):
    def test_post_returns_json(self) -> None:
        transport, session = make_transport("api")
        result = transport.request("user/playlist", {"uid": 1})
        self.assertEqual(result, {"code": 200})
        call = session.calls[0]
        self.assertEqual(call["method"], "POST")
        self.assertTrue(call["url"].endswith("/api/user/playlist"))
        self.assertEqual(call["data"]["uid"], 1)

    def test_get_uses_query_params(self) -> None:
        transport, session = make_transport("api")
        transport.request("user/playlist", {"uid": 1}, method="get")
        call = session.calls[0]
        self.assertEqual(call["method"], "GET")
        self.assertEqual(call["params"]["uid"], 1)

    def test_non_json_returns_text(self) -> None:
        transport, session = make_transport("api")
        session.responses.append(FakeResponse("<html>ok</html>"))
        self.assertEqual(transport.request("x", {}), "<html>ok</html>")

    def test_http_error_raises(self) -> None:
        transport, session = make_transport("api")
        session.responses.append(FakeResponse("bad", status=403))
        with self.assertRaises(TransportError) as ctx:
            transport.request("x", {})
        self.assertEqual(ctx.exception.status, 403)

    def test_retry_then_success(self) -> None:
        transport, session = make_transport("api", retries=1)
        session.responses.extend([FakeResponse("down", status=503), FakeResponse('{"code":200}')])
        with mock.patch("netease_api.transport.time.sleep"):
            self.assertEqual(transport.request("x", {}), {"code": 200})
        self.assertEqual(len(session.calls), 2)

    def test_retry_exhausted_raises(self) -> None:
        transport, session = make_transport("api", retries=1)
        session.responses.extend([FakeResponse("down", status=503), FakeResponse("down", status=503)])
        with mock.patch("netease_api.transport.time.sleep"):
            with self.assertRaises(TransportError):
                transport.request("x", {})
        self.assertEqual(len(session.calls), 2)

    def test_api_error_when_strict(self) -> None:
        transport, session = make_transport("api", raise_on_api_error=True)
        session.responses.append(FakeResponse('{"code":400,"message":"nope"}'))
        with self.assertRaises(ApiError) as ctx:
            transport.request("x", {})
        self.assertEqual(ctx.exception.code, 400)
        self.assertEqual(ctx.exception.payload["message"], "nope")

    def test_api_error_not_raised_by_default(self) -> None:
        transport, session = make_transport("api")
        session.responses.append(FakeResponse('{"code":400,"message":"nope"}'))
        self.assertEqual(transport.request("x", {})["code"], 400)

    def test_batch(self) -> None:
        transport, session = make_transport("api")
        results = transport.batch([("a", {"x": 1}), {"route": "b", "params": {"y": 2}}])
        self.assertEqual([r["route"] for r in results], ["a", "b"])
        self.assertTrue(all(r["ok"] for r in results))
        self.assertEqual(len(session.calls), 2)

    def test_batch_workers(self) -> None:
        transport, _ = make_transport("api")
        results = transport.batch([("a", {"x": i}) for i in range(4)], workers=2)
        self.assertEqual(len(results), 4)
        self.assertTrue(all(r["ok"] for r in results))


class CookieTests(unittest.TestCase):
    def test_string_cookies(self) -> None:
        transport, _ = make_transport()
        transport.set_cookies("MUSIC_U=abc; __csrf=tok")
        self.assertEqual(transport.cookies["MUSIC_U"], "abc")
        self.assertEqual(transport.csrf_token, "tok")
        self.assertIn("MUSIC_U=abc", transport.cookie_header)

    @unittest.skipUnless(os.name == "posix", "POSIX file modes only")
    def test_saved_cookie_file_is_owner_only(self) -> None:
        """The cookie file is a live credential and must be 0600."""
        transport, _ = make_transport()
        transport.set_cookies("MUSIC_U=secret")
        with tempfile.TemporaryDirectory() as tmp:
            path = os.path.join(tmp, "cookies.json")
            transport.save_cookies(path)
            mode = stat.S_IMODE(os.stat(path).st_mode)
            self.assertEqual(mode, 0o600)
            reloaded, _ = make_transport()
            reloaded.load_cookies(path)
            self.assertEqual(reloaded.cookies["MUSIC_U"], "secret")

    @unittest.skipUnless(os.name == "posix", "POSIX file modes only")
    def test_saved_cookie_file_tightens_existing_mode(self) -> None:
        transport, _ = make_transport()
        transport.set_cookies("MUSIC_U=secret")
        with tempfile.TemporaryDirectory() as tmp:
            path = os.path.join(tmp, "cookies.json")
            with open(path, "w", encoding="utf-8") as f:
                f.write("{}")
            os.chmod(path, 0o644)
            transport.save_cookies(path)
            self.assertEqual(stat.S_IMODE(os.stat(path).st_mode), 0o600)


if __name__ == "__main__":
    unittest.main()
