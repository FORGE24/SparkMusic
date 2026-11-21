# sparkmusic-protocol

Shared protocol layer for SparkMusic's Rust crates (Apache-2.0).

* `crypto` — eapi / weapi / linuxapi envelopes: AES-128-ECB/CBC, PKCS#7, MD5,
  textbook RSA over NetEase's public key. Known-answer tests included.
* `catalog` — the 1,293-route catalog recovered from the 9.6.30 APK, with
  prefix/version-tolerant lookup (`Catalog::get`, `Catalog::find`).

`core/` and `api/` both depend on it via a path dependency; HTTP transports stay
in those crates (blocking ureq vs. async reqwest), so this crate has no runtime
or TLS dependencies.

```console
$ cargo test
```
