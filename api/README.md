# sparkmusic-api

NetEase Cloud Music API in Rust, built with [Axum](https://github.com/tokio-rs/axum).
It serves the **1,293-route catalog recovered from the 9.6.30 Android APK** —
the same catalog the Python client in `../python` exposes —
behind an HTTP/JSON interface.

```console
$ ./cargo.sh run          # or plain `cargo run` on a normal machine
$ curl 'http://127.0.0.1:8080/health'
{"status":"ok","app_version":"9.6.30","routes":1293,"groups":150}
```

`cargo.sh` is a convenience wrapper: this build host mounts `~/.cargo` and
`/home` read-only and ccache cannot write its cache, so it keeps the registry
cache inside the project (`.cargo-home/`) and disables ccache.

## What it does

* Implements the four server-accepted request envelopes (**eapi**, **weapi**,
  **linuxapi**, plain **api**) in Rust: AES-128-ECB/CBC, PKCS#7, MD5 and
  textbook RSA over NetEase's public key. TLS uses rustls, so there is no
  OpenSSL dependency.
* Embeds the recovered route catalog at build time, so `/routes` and
  `/routes/{route}` work offline and stay in sync with the Python tooling.
* Exposes typed endpoints for the common music features plus a **generic
  proxy** for any of the 1,293 routes.
* Handles session cookies (`MUSIC_U`, `__csrf`) and injects the app defaults
  (`os`, `appver`, `deviceId`, …) into eapi bodies.

## Endpoints

| Method | Path | Purpose |
|---|---|---|
| GET | `/health` | Service status and catalog size |
| GET | `/routes?q=&group=&limit=&offset=` | Search the catalog |
| GET | `/routes/{*route}` | Metadata for one route (any spelling) |
| POST | `/call/{*route}` | Call any route; JSON object becomes the params |
| GET | `/api/search?keywords=&limit=&offset=&type=` | Unified search |
| GET | `/api/song/{id}` | Song detail |
| GET | `/api/song/url?ids=347230&level=exhigh` | Playback URLs |
| GET | `/api/song/{id}/lyric` | Lyrics |
| GET | `/api/song/{id}/comments?limit=&offset=` | Song comments |
| GET | `/api/playlist/{id}?limit=&offset=` | Playlist detail |
| GET | `/api/album/{id}` | Album detail |
| GET | `/api/artist/{id}` | Artist detail |
| GET | `/api/login/qr/key` | QR login: get a key |
| GET | `/api/login/qr/create?key=` | QR login: render the code |
| GET | `/api/login/qr/check?key=` | QR login: poll the scan state |
| POST | `/api/login/cookie` | Store `MUSIC_U=…` and verify it |

Examples:

```console
# search
curl -G --data-urlencode 'keywords=海阔天空' --data 'limit=5' \
  http://127.0.0.1:8080/api/search

# any catalog route, with a mode override
curl -X POST -H 'content-type: application/json' \
  -d '{"ids":"[347230]"}' 'http://127.0.0.1:8080/call/song/detail?mode=weapi'

# sign in with a cookie, then read the profile
curl -X POST -H 'content-type: application/json' \
  -d '{"cookie":"MUSIC_U=…; __csrf=…"}' http://127.0.0.1:8080/api/login/cookie
```

## Configuration

All settings come from the environment:

| Variable | Default | Meaning |
|---|---|---|
| `SPARKMUSIC_BIND` | `127.0.0.1:8080` | Listen address |
| `SPARKMUSIC_MODE` | `eapi` | Default envelope (`eapi`/`weapi`/`api`/`linuxapi`) |
| `SPARKMUSIC_TIMEOUT_MS` | `15000` | Upstream timeout |
| `SPARKMUSIC_RETRIES` | `2` | Retries for 5xx/429/network errors |
| `SPARKMUSIC_NO_DEFAULTS` | unset | Skip injecting app defaults into eapi bodies |
| `SPARKMUSIC_EAPI_BASE` / `_WEAPI_BASE` / `_API_BASE` | upstream URLs | Point at a mirror |

## Layout

```text
src/crypto.rs      eapi/weapi/linuxapi envelopes, AES/MD5/RSA (+ known-answer tests)
src/transport.rs   reqwest client, payload building, cookies, retries
src/catalog.rs     1,293-route catalog, lookup with prefix/version tolerance
src/api.rs         Axum router, typed handlers, generic proxy
src/config.rs      environment configuration
src/error.rs       error → HTTP status/JSON mapping
assets/routes.json exported from the Python catalog (build-time include)
```

## Tests

```console
$ cargo test
```

32 tests: AES known-answer vectors (computed independently with pycryptodome),
envelope round-trips, transport payload shapes, catalog integrity and the
router (validated with `tower` `oneshot`, no network).

Live check used during development: `/api/search?keywords=海阔天空` returns the
same track ids as the Python client (`1357375695`, `1357374736`), and
`/api/song/347230` resolves «海阔天空» by Beyond.

## Limitations

* **Native `xeapi` is not implemented.** The APK's session-key envelope needs
  the arm64 libraries and the `bsr/sk/get` handshake; choose `eapi`, `weapi`,
  `api` or `linuxapi`.
* **Entitlements still apply.** Playback URLs for VIP/paid tracks come back
  empty for anonymous callers (`fee: 1`); authenticate with `/api/login/cookie`
  or the QR flow.
* **Recovered parameters are indicative.** Routes come from the 9.6.30
  string-scanning fallback (see `../python/API.md` §2.2),
  so a few parameter lists may be incomplete.
* **No persistence.** Cookies live in memory for the process lifetime.

Use only with accounts and content you are authorized to access.
