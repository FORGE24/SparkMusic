"""CLI tests (offline subcommands only)."""
from __future__ import annotations

import io
import json
import sys
import unittest

from netease_api import cli


def run(argv: list[str]) -> tuple[int, str]:
    buffer = io.BytesIO()
    wrapper = io.TextIOWrapper(buffer, encoding="utf-8")
    old = sys.stdout
    sys.stdout = wrapper
    try:
        code = cli.main(argv)
    finally:
        sys.stdout = old
        wrapper.flush()
    return code, buffer.getvalue().decode("utf-8")


class ParseTests(unittest.TestCase):
    def test_parse_value(self) -> None:
        self.assertEqual(cli.parse_value("1"), 1)
        self.assertEqual(cli.parse_value("1.5"), 1.5)
        self.assertIs(cli.parse_value("true"), True)
        self.assertIsNone(cli.parse_value("null"))
        self.assertEqual(cli.parse_value("[1,2]"), [1, 2])
        self.assertEqual(cli.parse_value('{"a":1}'), {"a": 1})
        self.assertEqual(cli.parse_value("plain"), "plain")

    def test_parse_params_repeated_keys(self) -> None:
        params = cli.parse_params(["id=1", "id=2", "level=exhigh"])
        self.assertEqual(params["id"], [1, 2])
        self.assertEqual(params["level"], "exhigh")

    def test_parse_params_requires_equals(self) -> None:
        with self.assertRaises(SystemExit):
            cli.parse_params(["nope"])


class CommandTests(unittest.TestCase):
    def test_routes_listing(self) -> None:
        code, out = run(["routes", "song/detail", "--params"])
        self.assertEqual(code, 0)
        data = json.loads(out)
        self.assertTrue(any(line.startswith("v3/song/detail") for line in data))

    def test_routes_group_filter(self) -> None:
        code, out = run(["routes", "--group", "comment", "--json"])
        self.assertEqual(code, 0)
        data = json.loads(out)
        self.assertTrue(data)
        self.assertTrue(all(item["group"] == "comment" for item in data))

    def test_routes_recovered_filter(self) -> None:
        code, out = run(["routes", "search", "--recovered", "--json"])
        self.assertEqual(code, 0)
        self.assertTrue(all(not item["inferred"] for item in json.loads(out)))

    def test_help(self) -> None:
        with self.assertRaises(SystemExit) as ctx:
            run(["--version"])
        self.assertEqual(ctx.exception.code, 0)


if __name__ == "__main__":
    unittest.main()
