# NetEase Cloud Music 9.6.30 — recovered API client

A class-style Python client for the API recovered from the Android APK
`NeteaseCloudMusic_Music_official_9.6.30.261118204504_3264.apk`:
**1,293 routes in 150 groups**, 334 typed methods, no crypto dependency beyond
the standard library (HTTP uses `requests`).

```python
from netease_api import NeteaseClient

client = NeteaseClient()
client.search_songs("海阔天空", limit=10)
client.song_url(347230, level="exhigh")
client.playlist_detail(3778678, track_limit=30)
client.call("mlog/detail", id="…")          # any catalog route
```

```bash
python -m netease_api routes comment --params
python -m netease_api call song/detail "ids=[347230]"
```

## Rebuilding the catalog

`extracted/` holds the intermediate artifacts, so the catalog can be rebuilt
from them without touching the APK:

```bash
python -I tools/gen_routes.py extracted/endpoints.json netease_api/routes.py extracted/all_strings.txt
python -I tools/gen_docs.py      # ROUTES.md + docs/route_catalog.rst
```

To regenerate the artifacts from the APK itself, unzip `classes*.dex` and run:

```bash
python -I tools/dex_strings.py classes*.dex > extracted/all_strings.txt
python -I tools/extract_endpoints.py extracted/endpoints.json --all-methods classes*.dex
```

The extractor normally recognises the app's generic request builder by its
obfuscated signatures (`y22/e;->a(…` and friends). R8 renames that class on
every release, so for 9.6.30 no marker matches and the tool falls back to
scanning every method that contains route-shaped strings; it prints a note
when it does. That fallback is lower precision: it recovers the route and
parameter-key surface, but it no longer proves which method issues which call.

## Documentation

- [`API.md`](API.md) — analysis method, recovered request architecture,
  encryption findings, client reference and limitations.
- [`ROUTES.md`](ROUTES.md) — full route appendix with parameter keys and
  confidence tier.

## Tests

```bash
pip install -r requirements.txt
python -m unittest discover -s tests -t .
```

## Legal

This is a reverse-engineering study of an application you supplied, aimed at
interoperability and protocol documentation. Use it only with accounts and
content you are authorized to access; respect NetEase's terms of service.
