# Third-party components

SparkMusic's own code is Apache-2.0 (`core/`, `api/`) and MIT (`python/`).
Those licenses do **not** replace the licenses of the dependencies below.

## Desktop shell (`core/`)

| Component | License | Notes |
|---|---|---|
| Qt 6.11 (Core, Gui, Qml, Quick, Multimedia, Network) | LGPL-3.0 / GPL-3.0 / commercial | linked dynamically; distributing binaries requires complying with LGPL-3.0 (or a Qt commercial license) |
| cxx, cxx-qt, cxx-qt-lib, cxx-qt-build | MIT OR Apache-2.0 | Rust/Qt bridge |
| OpenSSL 3 | Apache-2.0 | TLS/X.509 primitives |
| rusqlite (bundled SQLite) | MIT | SQLite itself is public domain |
| ureq | MIT OR Apache-2.0 | HTTP client (rustls) |
| rustls, ring, webpki | ISC / Apache-2.0 / MIT | TLS stack |
| qrcode | MIT OR Apache-2.0 | QR matrix generation |
| aes, cbc, cipher, md-5, num-bigint, rand, hex, base64, serde, serde_json | MIT OR Apache-2.0 | |

## HTTP service (`api/`)

| Component | License |
|---|---|
| axum, tokio, tower-http, reqwest, tracing | MIT |
| serde, serde_json | MIT OR Apache-2.0 |
| Rust standard library | MIT OR Apache-2.0 |

## Python client (`python/`)

| Component | License |
|---|---|
| requests | Apache-2.0 |
| pycryptodome (optional test oracle) | BSD-2-Clause / public domain |
| Flask / PySide6 | **not bundled** (the GUI was removed from this client) |

## Data

`core/assets/routes.json` and `python/extracted/endpoints.json` are metadata
recovered from an APK you supply; they are descriptive route/parameter
information, not a license to the NetEase service. Use them only with accounts
and content you are authorized to access.
