"""Client tests: dispatch, parameter construction and login-state tracking."""
from __future__ import annotations

import json
import os
import unittest
from unittest import mock

import requests

from netease_api import NeteaseClient
from netease_api.errors import NeteaseError
from netease_api.transport import TransportConfig


class RecordingTransport:
    """Transport stand-in that records calls and returns a canned response."""

    def __init__(self, response: object | None = None) -> None:
        self.config = TransportConfig()
        self.session = requests.Session()
        self.cookies: dict[str, str] = {}
        self.calls: list[dict] = []
        self.response = {"code": 200} if response is None else response
        self.closed = False
        self.batches: list[dict] = []

    def request(self, route, params, *, mode=None, method=None, headers=None, timeout=None):
        self.calls.append(
            {
                "route": route,
                "params": dict(params),
                "mode": mode,
                "method": method,
                "headers": headers,
                "timeout": timeout,
            }
        )
        return self.response

    @property
    def csrf_token(self) -> str:
        return self.cookies.get("__csrf", "")

    def set_cookies(self, cookies):
        if isinstance(cookies, str):
            for part in cookies.split(";"):
                if "=" in part:
                    k, v = part.split("=", 1)
                    self.cookies[k.strip()] = v.strip()
        elif cookies:
            self.cookies.update(dict(cookies))

    def save_cookies(self, path):
        self.saved_cookie_path = path

    def load_cookies(self, path):
        self.loaded_cookie_path = path

    def batch(self, calls, *, workers=1, mode=None):
        self.batches.append({"calls": list(calls), "workers": workers, "mode": mode})
        return [{"route": c[0], "ok": True, "data": self.response} for c in calls]

    def close(self):
        self.closed = True


class ClientDispatchTests(unittest.TestCase):
    def setUp(self) -> None:
        self.transport = RecordingTransport()
        self.client = NeteaseClient(transport=self.transport)

    def test_song_detail(self) -> None:
        self.client.song_detail([1, 2])
        call = self.transport.calls[-1]
        self.assertEqual(call["route"], "v3/song/detail")
        self.assertEqual(call["params"]["id"], "1,2")
        self.assertEqual(json.loads(call["params"]["c"]), [{"id": 1}, {"id": 2}])
        self.assertEqual(call["params"]["v"], 1)
        self.assertEqual(call["params"]["rv"], 1)

    def test_song_url(self) -> None:
        self.client.song_url(347230, level="exhigh")
        call = self.transport.calls[-1]
        self.assertEqual(call["route"], "song/enhance/player/url/v1")
        self.assertEqual(call["params"]["ids"], "[347230]")
        self.assertEqual(call["params"]["level"], "exhigh")

    def test_playlist_detail(self) -> None:
        self.client.playlist_detail(3778678, track_limit=1000, offset=8)
        call = self.transport.calls[-1]
        self.assertEqual(call["route"], "v6/playlist/detail")
        self.assertEqual(call["params"]["id"], 3778678)
        self.assertEqual(call["params"]["n"], 1000)
        self.assertEqual(call["params"]["s"], 8)

    def test_comment_thread(self) -> None:
        self.client.comment_music(347230)
        call = self.transport.calls[-1]
        self.assertEqual(call["route"], "v1/resource/comments")
        self.assertEqual(call["params"]["threadId"], "R_SO_4_347230")
        self.assertEqual(call["params"]["resourceId"], 347230)
        self.assertEqual(call["params"]["resourceType"], 4)

    def test_thread_id_helper(self) -> None:
        self.assertEqual(self.client.thread_id("song", 1), "R_SO_4_1")
        self.assertEqual(self.client.thread_id(2, 1), "R_PL_2_1")
        with self.assertRaises(ValueError):
            self.client.thread_id("nope", 1)

    def test_call_controls_are_popped(self) -> None:
        self.client.call(
            "song/detail",
            ids="[1]",
            _mode="weapi",
            _method="GET",
            _headers={"X-Test": "1"},
            _timeout=3,
        )
        call = self.transport.calls[-1]
        self.assertEqual(call["params"], {"ids": "[1]"})
        self.assertEqual(call["mode"], "weapi")
        self.assertEqual(call["method"], "GET")
        self.assertEqual(call["headers"], {"X-Test": "1"})
        self.assertEqual(call["timeout"], 3)

    def test_login_state_absorbed(self) -> None:
        self.transport.response = {
            "code": 200,
            "profile": {"userId": 42, "nickname": "x"},
            "account": {"id": 42},
        }
        self.client.whoami()
        self.assertEqual(self.client.user_id, "42")
        self.assertEqual(self.client.profile["nickname"], "x")

    def test_batch_delegates(self) -> None:
        result = self.client.batch([("a", {"x": 1})], workers=2)
        self.assertEqual(result[0]["route"], "a")
        self.assertEqual(self.transport.batches[-1]["workers"], 2)

    def test_routes_helpers(self) -> None:
        self.assertGreater(self.client.route_count(), 1200)
        self.assertEqual(self.client.endpoint("v3/song/detail").group, "song")
        self.assertTrue(self.client.find_routes("playlist/detail"))
        self.assertIn("params", self.client.route_info("v3/song/detail"))

    def test_close_and_context_manager(self) -> None:
        with NeteaseClient(transport=self.transport) as client:
            self.assertIsInstance(client, NeteaseClient)
        self.assertTrue(self.transport.closed)

    def test_repr(self) -> None:
        text = repr(self.client)
        self.assertIn("mode='eapi'", text)
        self.assertIn("anonymous", text)

    def test_mode_property(self) -> None:
        self.client.mode = "weapi"
        self.assertEqual(self.transport.config.mode, "weapi")
        with self.assertRaises(ValueError):
            self.client.mode = "nope"


class CookieTests(unittest.TestCase):
    def test_from_env(self) -> None:
        env = {"NETEASE_COOKIE": "MUSIC_U=abc; __csrf=tok"}
        with mock.patch.dict(os.environ, env, clear=False):
            client = NeteaseClient.from_env()
        self.assertEqual(client.cookies["MUSIC_U"], "abc")
        self.assertEqual(client.csrf_token, "tok")

    def test_from_env_music_u(self) -> None:
        with mock.patch.dict(os.environ, {"NETEASE_MUSIC_U": "xyz"}, clear=True):
            client = NeteaseClient.from_env()
        self.assertEqual(client.cookies["MUSIC_U"], "xyz")

    def test_from_env_missing(self) -> None:
        with mock.patch.dict(os.environ, {}, clear=True):
            with self.assertRaises(NeteaseError):
                NeteaseClient.from_env()

    def test_from_cookie(self) -> None:
        client = NeteaseClient.from_cookie("MUSIC_U=abc")
        self.assertEqual(client.cookies["MUSIC_U"], "abc")


if __name__ == "__main__":
    unittest.main()
