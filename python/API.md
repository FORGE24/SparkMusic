# NetEase Cloud Music 9.6.30 — recovered API and Python client

This document describes the API recovered from the Android APK
`NeteaseCloudMusic_Music_official_9.6.30.261118204504_3264.apk` and the
class-style Python client in `netease_api/` that exposes it.

- APK size: 211,786,350 bytes
- SHA-256: `c9a8c1b30afb467426ceb88a985f9405eaa2f9d8a357bf76291c26d4c4cb40e1`
- MD5: `faa4d0a3b410d7a2d5a8922a3c79a48d`
- DEX files: 20 (`classes.dex`, `classes2.dex`, … `classes20.dex`)
- Result: **1,293 canonical routes in 150 groups**, 1,045 tied to a recovered
  request-builder method and 248 inferred from route-shaped string constants.

The package is a faithful *route and parameter recovery*, not a byte-for-byte
reimplementation of the app's native security layer. That distinction —
what was recovered, what was reimplemented for interoperability, and what was
deliberately left out — is explained in §5.

---

## 1. Contents

| Path | What it is |
|---|---|
| `netease_api/` | The Python client package |
| `netease_api/client.py` | `NeteaseClient`: combines all resource mixins |
| `netease_api/apis/` | Resource mixins (songs, playlists, comments, …) |
| `netease_api/routes.py` | Generated catalog: 1,293 `Endpoint` records |
| `netease_api/crypto.py` | Pure-Python AES/RSA implementations for eapi/weapi/linuxapi |
| `netease_api/transport.py` | HTTP transport, payload building, retries, batch |
| `netease_api/errors.py` | Exception hierarchy |
| `netease_api/cli.py` | `python -m netease_api` command line |
| `tests/` | 92 offline tests (codec, transport, client, API, CLI, routes) |
| `docs/` | Sphinx documentation (autodoc API reference + generated route catalog) |
| `scripts/build_wheel.py` | Wheel/sdist build helper with content verification |
| `ROUTES.md` | Full appendix: every route, parameter key and confidence tier |
| `tools/dex_dump.py` | DEX parser/disassembler |
| `tools/extract_endpoints.py` | Request-builder and parameter extractor |
| `tools/gen_routes.py` | Catalog generator (writes `netease_api/routes.py`) |
| `tools/gen_docs.py` | Writes `ROUTES.md` |
| `extracted/endpoints.json` | Raw extraction output (1,077 records, 1,148 route strings) |
| `extracted/all_strings.txt` | All 1,482,123 strings from the 20 DEX files |

---

## 2. Analysis method

No `apktool`, `jadx`, `androguard`, or network access was used. The APK is a
ZIP; the DEX files were read directly with a small parser written for this
task (`tools/dex_dump.py`).

### 2.1 DEX parsing

The parser implements the parts of the DEX format needed to recover request
construction:

- header and map list (`string_ids`, `type_ids`, `proto_ids`, `field_ids`,
  `method_ids`, `class_defs`)
- `class_data_item` (direct/virtual method lists, code offsets)
- `code_item` with ULEB128 instruction widths and payload pseudo-instructions
  (`packed-switch`, `sparse-switch`, `fill-array-data`)
- MUTF-8 string decoding

Each method is disassembled to a `(address, opcode, operands)` stream. This is
what makes register-level analysis possible despite R8 obfuscation.

### 2.2 Finding request builders

The app funnels requests through a small set of generic builders, so the
extractor does not look for route strings in isolation. It looks for calls to
known entry points:

```
Ly22/e;->a(…)  …  Ly22/e;->g(…)     # request builder overloads
Ly32/a;-><init>(…)  Ly32/b;-><init>(…)  Ly32/c;-><init>(…)
Ly32/c;->H1(…)
```

For every such call site the disassembly is scanned backwards for the
`const-string` that supplies the route, with `move-object` chains followed.
The surrounding method is recorded as the source of the route.

**9.6.30 result.** None of those signatures survives in this build. R8 renames
every class per release, and the call sites that carry route strings now also
touch OkHttp/Retrofit-style builders (`okhttp3`, `retrofit2` and their request
`Builder` methods are present in the string pool), so an equivalent marker set
could not be re-identified with the same confidence. `tools/extract_endpoints.py`
therefore reports that no known builder matched and falls back to scanning
every method that contains route-shaped strings:

- 1,077 route-bearing methods were recovered (against 873 marker-matched ones
  for 9.6.22).
- They contain 1,148 distinct route strings (a method may build several).
- The fallback keeps the route and parameter-key surface but no longer proves
  which method issues which call, so `sources` is weaker evidence than before:
  treat per-route `params` as indicative rather than authoritative.

### 2.3 Recovering parameter keys

Parameter keys are not annotations in the app; they are arguments to
`Map.put`, `JSONObject.put`, and similar calls. The extractor tracks what each
register holds:

- `const-string` (`0x1a`/`0x1b`) assigns a string to a register
- `move-object` (`0x07`/`0x08`/`0x09`, and the `/from16`, `/16` variants)
  copies it
- `move-result-object` clears the tracked value
- on an `invoke` with a `put`-like descriptor, the key register is read:
  - `35c`: argument registers from unit 2 (`unit 3` for `45cc`)
  - `3rc`: first register in the range + 1 (the instance receiver is arg 0)

Tracked values expire after 80 instructions, which prevents stale keys from
leaking across branches. This produced parameter lists for 245 records, 454
unique parameter keys.

Query-template routes (e.g. `user/playlist?uid=%d&limit=%d…`) are additionally
parsed with `parse_qsl` so their `%d`/`%s` placeholders contribute keys.

### 2.4 The inferred tier

Some routes are assembled at runtime and never appear in the argument of a
recovered builder call — for example `v1/search/get`. A second pass scans the
string pool for route-shaped constants:

- starts with a known service prefix (`api/`, `eapi/`, `weapi/`, `neapi/`,
  `linuxapi/`) or a known root segment, or is a multi-segment relative path
- rejects whitespace, MIME types, `$`/`..` fragments, and over-long strings

These are marked `inferred=True`. They are real strings from the APK, but their
parameter list is usually unknown and they may carry less confidence than a
recovered builder route.

### 2.5 Canonicalization and grouping

Routes are stripped of transport prefixes and query strings, so
`/api/user/playlist?uid=%d` becomes `user/playlist`. Group names come from the
first meaningful path segment (with a few app-specific ones such as
`play-record`, `mlog`, `djradio`).

### 2.6 Reproducing the extraction

```bash
cd D:/163music/tools
python -I extract_endpoints.py ../extracted/endpoints.json ../extracted/classes*.dex
python -I gen_routes.py ../extracted/endpoints.json ../netease_api/routes.py \
    ../extracted/all_strings.txt
python -I gen_docs.py                          # writes ROUTES.md
python -I check_routes_used.py                 # validates mixin route literals
```

`extract_endpoints.py` takes the output JSON followed by any number of DEX
paths; `gen_routes.py` takes the extraction JSON, the output module, and
optionally the string dump used for the inferred tier. `gen_docs.py` reads the
generated catalog.

---

## 3. Recovered request architecture

The recovered call chain is:

```
NeteaseMusicApiImpl                      (public API surface, 91 references)
        │
        ▼
y22/e.a/b/c/d/e/f/g(route, Map)          (generic request builder)
        │
        ▼
y32/a, y32/b, y32/c (constructor/H1)     (request objects: URL, params, headers)
        │
        ▼
OkHttp interceptors                      (headers, cookies, encryption)
        │
        ▼
native crypto:
  crypto.caesar.APICryptor
  crypto.caesarson.CaesarsonCryptor
  AegisNative
  s32/c, s32/f
```

Evidence for this chain:

- `Lcom/netease/cloudmusic/api/impl/NeteaseMusicApiImpl;` appears 91 times in
  the string pool, mostly as a source for recovered routes.
- The builder markers above appear as invoke targets in hundreds of methods.
- `s32/c` and `s32/f` reference the encryption classes; `APICryptor` appears 15
  times and `AegisNative` twice in the string pool.
- The APK ships `libcaesar.so`, `libcaesarson.so`, `libnesec.so`,
  `libsec-lib.so`, `libnetmobsec-4.4.7.so`, `libns.so`, and
  `libsimple.so` under `lib/arm64-v8a/`.

### 3.1 Session-encryption markers

The 9.6.30 client negotiates a per-session key and marks encrypted requests
with these strings (each confirmed in the string pool):

| String | Role |
|---|---|
| `bsr/sk/get` | session-key route |
| `x-encr-ssid` | session id header |
| `x-encr-sskey` | session key header |
| `X-Client-Enc-State` | encryption-state header |
| `x-aeapi` | API envelope marker |
| `x-mg-zip` | payload/compression marker |

This native envelope is **documented but not implemented** in the Python
client. See §5.

---

## 4. Route catalog

`netease_api/routes.py` is generated from the extraction output. Each entry is
an immutable `Endpoint`:

```python
Endpoint(
    route="v6/playlist/detail",
    params=("id", "v", "c", "trialMode", "t", "n", "s"),
    sources=("Lcom/netease/cloudmusic/…", ...),
    variants=("v6/playlist/detail", "/api/v6/playlist/detail"),
    group="playlist",
    shared_params=True,
    inferred=False,
)
```

- `params` — recovered body/query keys, in first-seen order.
- `sources` — obfuscated methods that build the route.
- `variants` — raw spellings seen in the APK.
- `shared_params` — the source method builds several routes, so a key may
  belong to a sibling route. Treat as a superset.
- `inferred` — string-pool-only route (see §2.4).

### 4.1 Largest groups

| group | routes | group | routes |
|---|---:|---|---:|
| livestream | 114 | event | 49 |
| user | 82 | music | 43 |
| listen | 68 | song | 37 |
| mlog | 65 | dj | 35 |
| playlist | 57 | ad | 32 |

150 groups exist in total; the complete table and every route are in
[`ROUTES.md`](ROUTES.md).

### 4.2 Looking routes up

```python
from netease_api import routes

routes.get("song/detail")        # tolerant: prefixes, /api/, ?query
routes.get("v3/song/detail")     # v3/song/detail
routes.find("comment")           # case-insensitive substring search
routes.summary()                 # group counts
```

`get()` is deliberately strict: it matches an exact canonical route, then
`v1/`…`v9/` prefixed forms. It never fuzzy-matches a suffix, so
`get("song/url")` raises `KeyError` instead of silently returning
`alarm/song/url`.

### 4.3 Changes between the 9.6.22 and 9.6.30 catalogs

Re-running the pipeline on 9.6.30 yields 1,293 routes against 1,287: 1,285 are
common, 8 appear and 2 disappear. The catalog is therefore stable — the app
did not restructure its API surface between these builds.

| Added (9.6.30) | Params | Note |
|---|---:|---|
| `djradio/v5/resume/point` | 0 | a real new endpoint |
| `music/multi/terminal/tuning/nos/save` | 0 | a real new endpoint |
| `batch` | 4 | batch-call route, previously only invoked by the generic client helper |
| `login` | 3 | legacy login route that the marker gate had hidden |
| `clientlog`, `feedback`, `log`, `spider` | 0 | single-word routes seen only as string constants |

| Removed | Params | Note |
|---|---:|---|
| `api` | 8 | not a route at all: a base-path constant, now filtered |
| `mine/collect/artist/award/info/query` | 1 | dropped; the same call now lives at `song/more/artist/award/info/query`, which remains in the catalog |

23 common routes changed their recovered `params` list. Because 9.6.30 has no
matching builder marker, those lists come from the lower-precision fallback
(see §2.2), so treat them as indicative; the route set itself is reliable.

---

## 5. Encryption: what the APK does vs. what the client does

### 5.1 The APK no longer contains the classic keys

The widely documented `weapi`/`eapi` schemes depend on three constants:

| Constant | Occurrences in the 20 DEX files |
|---|---:|
| `0CoJUm6Qyw8W8jud` (weapi preset key) | 0 |
| `e82ckenh8dichen8` (eapi key) | 0 |
| `md5forencrypt` (eapi digest template) | 0 |

The string `0102030405060708` occurs only inside a longer, unrelated
hex constant (`000102…1F`). In other words, 9.6.30 has moved request encryption
into native code keyed by a server-negotiated session, and the classic
pure-Python envelope is not present.

### 5.2 What the Python client implements

To make the recovered routes usable from Python, the package reimplements the
four well-known server-accepted transports. None of these keys are extracted
from the APK; they are protocol constants:

| Mode | URL base | Body | Key material |
|---|---|---|---|
| `eapi` (default) | `https://interface.music.163.com/eapi/` | `{"params": HEX}` | AES-128-ECB, `e82ckenh8dichen8` |
| `weapi` | `https://music.163.com/weapi/` | `params` + `encSecKey` | AES-128-CBC twice + RSA |
| `api` | `https://music.163.com/api/` | plain form (`csrf_token`) | none |
| `linuxapi` | `https://music.163.com/api/linux/forward` | `{"eparams": HEX}` | AES-128-ECB, `rFgB&h#%2?^eDg:Q` |

`crypto.py` implements AES-128 (ECB and CBC), PKCS#7 padding, MD5, and
textbook RSA with NetEase's public modulus — **no third-party crypto
dependency**. It is verified against the FIPS-197 AES vector and against
pycryptodome for data sizes 1, 15, 16, 17 and 100 bytes.

eapi request bodies are built as:

```
message = url + "-36cd479b6b5-" + json(params) + "-36cd479b6b5-" + md5(
    "nobody" + url + "use" + json(params) + "md5forencrypt")
```

then AES-ECB encrypted and hex-encoded (uppercase).

weapi bodies are `json(params)` AES-CBC encrypted with
`0CoJUm6Qyw8W8jud`, base64-encoded, encrypted again with a random 16-character
secret, and accompanied by `encSecKey = RSA(reversed(secret))`.

### 5.3 What is intentionally not implemented

Mode `native`/`xeapi` raises `NativeEncryptionUnavailable` with a message
pointing at the supported modes. Reproducing the native envelope would require
the arm64 encryption libraries, the `bsr/sk/get` session handshake, and the
Aegis/`libnesec` conventions — a fundamentally different job from recovering
the API surface, and one this client does not attempt.

### 5.4 Defaults injected into eapi bodies

When `inject_defaults=True` (default), eapi requests add:

```
os=android  appver=9.6.30  osver=13  channel=netease
deviceId=<random 32-hex>  requestId=<random 32-hex uuid>
```

Override or disable them through `TransportConfig.default_params` and
`inject_defaults=False`.

When a `__csrf` cookie is present, every eapi body also carries
`csrf_token=<value>`. Authenticated writes such as playlist renaming are
rejected with `403 illegal request!` without it; read-only eapi calls work
either way.

---

## 6. Python client

### 6.1 Requirements and import

Python 3.9+ and `requests`. From the project root:

```bash
pip install -r requirements.txt
```

```python
from netease_api import NeteaseClient
```

### 6.2 Quick start

```python
from netease_api import NeteaseClient

client = NeteaseClient()                    # anonymous, eapi mode

songs = client.search_songs("海阔天空", limit=10)
detail = client.song_detail(347230)
url = client.song_url(347230, level="exhigh")
playlist = client.playlist_detail(3778678, track_limit=30)
```

Every method returns the decoded JSON response (a `dict`, usually) unchanged.
Responses with non-200 `code` values are returned, not raised, unless strict
mode is enabled — NetEase uses non-200 codes for partial successes too.

### 6.3 Authentication

Most write endpoints and personalized reads need a logged-in session cookie
(`MUSIC_U`). Three options:

```python
client = NeteaseClient.from_env()           # NETEASE_COOKIE or NETEASE_MUSIC_U
client = NeteaseClient.from_cookie_file("cookies.json")
client = NeteaseClient(cookies="MUSIC_U=…; __csrf=…")

data = client.login_cellphone("13800000000", "password")
client.save_cookies("cookies.json")
```

`login_cellphone` uses the recovered `login/cellphone` route and hashes the
password with MD5 (disable with `md5_password=False`); an SMS code is used if
`captcha=` is passed instead. When a response contains `profile`/`account`,
the client records `client.profile` and `client.user_id` automatically.

QR login:

```python
client.login_qrcode_create()                # returns unikey
client.login_qrcode_check(key)              # poll until code == 803
```

The recovered app-server QR route is also available as
`login_qrcode_server(key, …)`.

### 6.4 Generic access to all 1,293 routes

Mixins cover the common flows; anything else is one call away:

```python
client.call("v6/playlist/detail", id=3778678, n=30, s=0, v=1)
client.call("mlog/detail", id="…")
```

Per-call transport controls are underscore-prefixed keywords:

```python
client.call("user/playlist", uid=123, _mode="weapi", _method="GET", _timeout=5)
```

| Keyword | Meaning |
|---|---|
| `_mode` | `eapi`, `weapi`, `api`, `linuxapi` |
| `_method` | `GET` or `POST` (default POST) |
| `_headers` | extra HTTP headers |
| `_timeout` | per-request timeout in seconds |

`client.raw()` is an alias for `call()`. `client.request` also aliases it.

### 6.5 Configuration

```python
client = NeteaseClient(
    mode="eapi",
    timeout=15.0,
    retries=2,
    proxies={"https": "http://127.0.0.1:8080"},
    headers={"X-My-Header": "1"},
    inject_defaults=True,
    raise_on_api_error=False,
    verify=True,
)
```

`client.config` is a `TransportConfig`; `client.mode`, `client.cookies` and
`client.csrf_token` are convenience accessors. Custom base URLs:

```python
NeteaseClient(base_url="https://interface.music.163.com/eapi/")
NeteaseClient(base_urls={"eapi": "https://example.test/eapi/"})
```

### 6.6 Method map

25 mixins provide **334 methods**. The table lists each area and its main
routes; every method's docstring names the exact route it calls.

| Mixin | Methods | Representative routes |
|---|---:|---|
| `LoginApi` | 13 | `login/cellphone`, `login/qrcode/server/login`, `login/token/refresh`, `register/cellphone` |
| `UserApi` | 27 | `v1/user/detail/{uid}`, `user/playlist`, `user/getfollows/{uid}`, `play-record/{kind}/list` |
| `SongApi` | 19 | `v3/song/detail`, `song/enhance/player/url/v1`, `song/lyric/v1`, `song/like` |
| `AlbumApi` | 7 | `album/{id}`, `album/{sub,unsub}`, `album/sublist` |
| `ArtistApi` | 15 | `artist/detail/dynamic/v2`, `v2/artist/songs`, `artist/albums/{id}`, `v1/artist/sub` |
| `MvApi` | 6 | `v1/mv/detail`, `song/enhance/download/mv/url`, `mv/all` |
| `PlaylistApi` | 25 | `v6/playlist/detail`, `playlist/manipulate/tracks`, `playlist/subscribe`, `playlist/category/list` |
| `SearchApi` | 21 | `v1/search/get`, `search/complex/page`, `search/suggest/keyword`, `search/mlog/get` |
| `CommentApi` | 18 | `v1/resource/comments`, `v2/resource/comment/floor/get`, `v1/resource/comments/add` |
| `DjApi` | 17 | `dj/program/detail`, `v1/dj/program/byradio`, `djradio/get`, `djradio/sub` |
| `RadioApi` | 10 | `v1/radio/get`, `v1/radio/like`, `radio/sport/get` |
| `RecommendApi` | 13 | `v3/discovery/recommend/songs`, `v1/discovery/simiSong`, `discovery/new/albums` |
| `PersonalizedApi` | 3 | `personalized/mv`, `personalized/playlist/tag/rcmd` |
| `ToplistApi` | 5 | `toplist/detail/v2`, `toplist/artist`, `reward/resource/toplist` |
| `EventApi` | 18 | `event/get/{uid}`, `event/detail/get/v1`, `event/forward` |
| `MlogApi` | 32 | `mlog/detail`, `mlog/rcmd/v3`, `mlog/songmlog/bytime/get/v2` |
| `TopicApi` | 11 | `topic/hot`, `topic/sub`, `topic/category/hot/list` |
| `MsgApi` | 5 | `msg/recentcontact/get`, `msg/private/send`, `msg/notice/delete` |
| `CloudApi` | 17 | `v3/cloud/get`, `cloud/file/upload/check`, `cloud/pub/v2`, `cloud/del` |
| `VipApi` | 9 | `music-vip-membership/client/vip/info`, `vip/config/url`, `vipauth/app/auth/query` |
| `SettingApi` | 5 | `setting/user/module/tags`, `setting/developer` |
| `ReportApi` | 8 | `report/reportuser`, `report/reportcomment`, `report/type/get` |
| `FeedbackApi` | 2 | `v1/feedback/lyric`, `feedback/log/android` |
| `ListenTogetherApi` | 18 | `listen/together/status/get`, `listen/together/room/create`, `listen/together/heartbeat` |
| `MineApi` | 7 | `mine/collect/header/info`, `mine/page/tab/nums/count` |

Comment threads are built for you:

```python
client.comment_music(347230)        # R_SO_4_347230
client.comment_playlist(3778678)    # R_PL_2_3778678
client.thread_id("song", 347230)    # "R_SO_4_347230"
client.comment_floor("R_SO_4_347230", parent_comment_id=…)
```

`thread_id`/`RESOURCE_TYPES` cover event=1, playlist=2, album=3, song=4,
mv=5, dj=6, radio=7, video=8, mlog=13.

### 6.7 Batch calls

```python
results = client.batch(
    [("v6/playlist/detail", {"id": 3778678}),
     {"route": "song/detail", "params": {"ids": "347230"}}],
    workers=4,
)
# [{"route": …, "ok": True, "data": …}, …]
```

Parallel batches use one requests session per worker. They are intended for
independent reads; cookie changes made by concurrent calls are not merged back
into the main session.

### 6.8 Errors

```
NeteaseError
├── TransportError            network failure or HTTP >= 400 (status/payload)
├── ApiError                  JSON code != 200 (strict mode only)
├── EncryptionError
│   └── NativeEncryptionUnavailable   native/xeapi requested
└── UnsupportedMode
```

`TransportError` and `ApiError` carry `status`/`code` and the response payload
where available. `NeteaseClient(raise_on_api_error=True)` turns non-200 codes
into `ApiError`; the default is to return the raw response.

### 6.9 CLI

```bash
python -m netease_api --version
python -m netease_api routes comment --group comment --params
python -m netease_api routes search --inferred --json
python -m netease_api call song/detail "ids=[347230]"
python -m netease_api call v6/playlist/detail id=3778678 n=30 --mode eapi
python -m netease_api search 海阔天空 --type song --limit 5
python -m netease_api song 347230 --url
python -m netease_api song 347230 --lyric
python -m netease_api playlist 3778678
python -m netease_api user 123456 --playlists
python -m netease_api login cellphone --phone 13800000000 --password secret \
    --save-cookies cookies.json
```

Values are auto-typed (`1`, `true`, `null`, JSON arrays/objects) and
`--param-file` merges a JSON object into the parameters.

### 6.10 Wheel and Sphinx documentation

```bash
python scripts/build_wheel.py                 # dist/*.whl, verified
python scripts/build_wheel.py --clean --sdist # rebuild everything
pip install -r docs/requirements.txt
python -m sphinx -b html -W docs docs/_build/html
```

The wheel helper prefers PEP 517 (`build`), falls back to
`pip wheel --no-build-isolation` when offline, and refuses to ship tests,
extraction artifacts, the APK, DEX files or native libraries. The Sphinx tree
in `docs/` contains installation, usage, authentication, transport/recovery
notes, an autodoc API reference for every mixin, and the generated full route
catalog (`docs/route_catalog.rst`, written by `tools/gen_docs.py` alongside
`ROUTES.md`).

---

## 7. Verification

```bash
cd D:/163music
python -m unittest discover -s tests -t .     # offline test suite
python scripts/build_wheel.py                 # wheel + content checks
python -m sphinx -b html -W docs docs/_build/html
```

| Suite | Covers |
|---|---|
| `test_crypto.py` | FIPS-197 vector, padding, pycryptodome cross-checks, weapi/eapi/linuxapi envelope round-trips, RSA shape |
| `test_transport.py` | URL spelling, payload encryption, defaults, GET/POST, retry, strict mode, batch, cookies |
| `test_client.py` | dispatch, parameter construction, call controls, login-state tracking, env cookies |
| `test_apis.py` | smoke tests across all 25 mixins, thread ids, duplicate-method check |
| `test_routes.py` | catalog size, lookup semantics, prefix tolerance, no suffix fuzzy match, metadata |
| `test_cli.py` | value/parameter parsing, offline `routes` subcommands |

pycryptodome is optional: tests that need it to *decrypt* our output are
skipped when it is absent (`crypto.py` itself has no such dependency).
`tools/check_routes_used.py` statically verifies that all 293 literal route
strings used by the mixins exist in the catalog (8 classic fallbacks are
explicitly allow-listed).

---

## 8. Limitations and caveats

1. **Native encryption is not reproduced.** The app's session-key envelope is
   documented in §3.1/§5.3 but not implemented. Calls use the server-accepted
   eapi/weapi/api/linuxapi transports instead. Behavior that depends on native
   attestation or session headers (some risk-control, anti-abuse or
   device-bound endpoints) may fail where the app succeeds.
2. **9.6.30 extraction is lower precision.** The 9.6.22 request-builder
   markers do not exist in this build (R8 renamed them), so routes come from
   the string-scanning fallback. The route set matches the previous catalog
   almost exactly (1,285 common of 1,293), but `sources` no longer proves which
   method issues which call and per-route `params` are indicative.
3. **App-internal routes may be server-gated.** The catalog is what the app
   can call when it has the right account, region, VIP level, client version
   and signature headers. Many routes (livestream, ad, `icreator`,
   `sociallive`, …) are internal or experimental and can return errors or
   empty data for third-party callers.
4. **Parameters are recovered, not typed.** The extractor recovers key names,
   not value formats or required/optional status. `shared_params` routes may
   list keys belonging to a sibling route. Method docstrings encode the
   conventions the app is known to use, but unusual fields should be checked
   against a capture.
5. **`inferred` routes are lower confidence.** They come from the string pool;
   the route may be dead code, a fragment, or require dynamic segments.
   Templated variants end in `%d`/`%s`; substitute real ids before calling.
6. **Route drift.** The server changes; a route present in a 2025 build may be
   retired. There is no guarantee of stability beyond what the live service
   offers.
7. **No captcha/verify solver.** Login may require SMS verification or a
   captcha token for new devices; the client exposes the endpoints but does not
   bypass these checks.
8. **Classic fallbacks.** A small number of long-standing public routes used by
   `LoginApi`/`UserApi` (for example `logout`, `user/getfolloweds`, `user/subcount`)
   are not in the 9.6.30 catalog; their docstrings say so.

---

## 9. Legal and ethical use

This work is a reverse-engineering study of an application you supplied, aimed
at interoperability, protocol documentation and security research. Use it only
with accounts and content you are authorized to access. It does not bypass
authentication, payment, DRM, or regional restrictions, and it should not be
used to scrape at scale or to redistribute copyrighted media. Respect
NetEase's terms of service and applicable law. The route catalog is
descriptive metadata, not a license to the service.

---

## 10. Appendix

- [`ROUTES.md`](ROUTES.md) — all 1,293 routes, grouped, with parameter keys and
  confidence tier.
- `extracted/endpoints.json` — raw records: class, method, descriptor, routes,
  params, put keys, nearby strings.
- `extracted/all_strings.txt` — all strings recovered from the DEX files.
- `tools/` — the extraction and generation pipeline, reproducible from the APK.
