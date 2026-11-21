"""Catalog tests: structure, lookup helpers and metadata sanity."""
from __future__ import annotations

import unittest

from netease_api import routes


class CatalogTests(unittest.TestCase):
    def test_size(self) -> None:
        self.assertGreater(len(routes.ENDPOINTS), 1200)
        self.assertGreaterEqual(len(routes.GROUPS), 100)
        self.assertEqual(len(routes.ROUTES), len(routes.ENDPOINTS))

    def test_every_group_non_empty(self) -> None:
        for group, endpoints in routes.GROUPS.items():
            self.assertTrue(endpoints, group)

    def test_known_routes(self) -> None:
        cases = {
            "song/enhance/player/url/v1": "song",
            "v3/song/detail": "song",
            "v1/resource/comments": "resource",
            "user/playlist": "user",
            "v1/search/get": "search",
            "mlog/detail": "mlog",
        }
        for route, group in cases.items():
            endpoint = routes.get(route)
            self.assertEqual(endpoint.route, route)
            self.assertEqual(endpoint.group, group)

    def test_get_accepts_prefixes_and_query(self) -> None:
        for spelling in (
            "song/detail",
            "/api/song/detail",
            "weapi/song/detail",
            "eapi/song/detail?x=1",
            "song/detail?ids=1",
        ):
            self.assertEqual(routes.get(spelling).route, "v3/song/detail")

    def test_get_unknown_raises(self) -> None:
        with self.assertRaises(KeyError):
            routes.get("definitely/not/a/route")

    def test_get_does_not_fuzzy_match_suffix(self) -> None:
        # Regression: "song/url" used to match "alarm/song/url".
        with self.assertRaises(KeyError):
            routes.get("song/url")

    def test_find_is_case_insensitive(self) -> None:
        upper = routes.find("SONG/DETAIL")
        lower = routes.find("song/detail")
        self.assertEqual(upper, lower)
        self.assertTrue(any(e.route == "v3/song/detail" for e in lower))

    def test_params_are_strings(self) -> None:
        for endpoint in routes.ENDPOINTS.values():
            for key in endpoint.params:
                self.assertIsInstance(key, str)
                self.assertTrue(key)

    def test_some_params_recovered(self) -> None:
        with_params = [e for e in routes.ENDPOINTS.values() if e.params]
        self.assertGreater(len(with_params), 200)
        self.assertIn("id", routes.get("v6/playlist/detail").params)

    def test_inferred_flag(self) -> None:
        inferred = [e for e in routes.ENDPOINTS.values() if e.inferred]
        recovered = [e for e in routes.ENDPOINTS.values() if not e.inferred]
        self.assertTrue(inferred)
        self.assertTrue(recovered)
        self.assertEqual(len(inferred) + len(recovered), len(routes.ENDPOINTS))

    def test_as_dict(self) -> None:
        endpoint = routes.get("user/playlist")
        data = endpoint.as_dict()
        self.assertEqual(data["route"], "user/playlist")
        self.assertEqual(data["group"], "user")
        self.assertIsInstance(data["params"], list)
        self.assertIsInstance(data["sources"], list)
        self.assertIsInstance(data["inferred"], bool)

    def test_str(self) -> None:
        endpoint = routes.get("v3/song/detail")
        self.assertEqual(str(endpoint), "v3/song/detail?" + "&".join(endpoint.params))

    def test_summary(self) -> None:
        text = routes.summary()
        self.assertIn("routes /", text)
        self.assertIn("song", text)


if __name__ == "__main__":
    unittest.main()
