//! NetEase Cloud Music request envelopes.
//!
//! Four schemes are implemented, matching the ones the server still accepts:
//!
//! | mode       | body                                   | crypto                    |
//! |------------|----------------------------------------|---------------------------|
//! | `eapi`     | `params=<HEX>`                         | AES-128-ECB               |
//! | `weapi`    | `params=<B64>&encSecKey=<HEX>`         | AES-128-CBC ×2 + RSA      |
//! | `linuxapi` | `eparams=<HEX>`                        | AES-128-ECB               |
//! | `api`      | plain form                             | none                      |
//!
//! The APK's own `xeapi`/native envelope is deliberately not implemented: it
//! needs the arm64 session-key handshake rather than a fixed protocol key.

use aes::Aes128;
use base64::engine::general_purpose::STANDARD as BASE64;
use base64::Engine as _;
use cipher::block_padding::Pkcs7;
use cipher::{BlockEncryptMut, KeyInit, KeyIvInit};
use md5::{Digest, Md5};
use num_bigint::BigUint;
use rand::distributions::Alphanumeric;
use rand::Rng;
use serde_json::{Map, Value};

use crate::error::{Error, Result};

pub const WEAPI_PRESET_KEY: &[u8] = b"0CoJUm6Qyw8W8jud";
pub const WEAPI_IV: &[u8] = b"0102030405060708";
pub const EAPI_KEY: &[u8] = b"e82ckenh8dichen8";
pub const LINUXAPI_KEY: &[u8] = b"rFgB&h#%2?^eDg:Q";

const EAPI_SEPARATOR: &str = "-36cd479b6b5-";
const WEAPI_EXPONENT: u32 = 0x1_0001;
const WEAPI_PUBKEY_HEX: &str = "00e0b509f6259df8642dbc35662901477df22677ec152b5ff68ace615bb7b7\
25152b3ab17a876aea8a5aa76d2e417629ec4ee341f56135fccf695280104e0312ecbda92557c93870114af6c\
9d05c4f7f0c3685b7a46bee255932575cce10b424d813cfe4875d3e82047b97ddef52741d546b8e289dc6935b\
3ece0462db0a22b8e7";

fn crypto_err(msg: impl Into<String>) -> Error {
    Error::Crypto(msg.into())
}

pub fn md5_hex(data: &[u8]) -> String {
    hex::encode(Md5::digest(data))
}

fn md5_digest_hex(text: &str) -> String {
    md5_hex(text.as_bytes())
}

/// AES-128-ECB with PKCS#7 padding.
pub fn aes_ecb_encrypt(data: &[u8], key: &[u8]) -> Result<Vec<u8>> {
    let cipher = Aes128::new_from_slice(key).map_err(|_| crypto_err("invalid AES key length"))?;
    Ok(cipher.encrypt_padded_vec_mut::<Pkcs7>(data))
}

/// AES-128-CBC with PKCS#7 padding.
pub fn aes_cbc_encrypt(data: &[u8], key: &[u8], iv: &[u8]) -> Result<Vec<u8>> {
    if iv.len() != 16 {
        return Err(crypto_err("AES IV must be exactly 16 bytes"));
    }
    let cipher = cbc::Encryptor::<Aes128>::new_from_slices(key, iv)
        .map_err(|_| crypto_err("invalid AES key/IV length"))?;
    Ok(cipher.encrypt_padded_vec_mut::<Pkcs7>(data))
}

/// 16 random alphanumerics, the weapi per-request secret.
pub fn random_secret() -> String {
    rand::thread_rng()
        .sample_iter(&Alphanumeric)
        .take(16)
        .map(char::from)
        .collect()
}

/// Textbook RSA over the reversed secret, rendered as 256 hex characters.
pub fn rsa_encrypt(text: &str) -> String {
    let modulus = BigUint::parse_bytes(WEAPI_PUBKEY_HEX.as_bytes(), 16)
        .expect("hard-coded NetEase modulus is valid hex");
    let reversed: Vec<u8> = text.bytes().rev().collect();
    let mut block = vec![0u8; 128usize.saturating_sub(reversed.len())];
    block.extend_from_slice(&reversed);
    let message = BigUint::from_bytes_be(&block);
    let encrypted = message.modpow(&BigUint::from(WEAPI_EXPONENT), &modulus);
    format!("{encrypted:0256x}")
}

fn json_text(params: &Map<String, Value>) -> Result<String> {
    serde_json::to_string(params).map_err(|e| crypto_err(e.to_string()))
}

/// weapi body: `params` (double CBC + base64) and `encSecKey`.
pub fn weapi_encrypt(params: &Map<String, Value>) -> Result<(String, String)> {
    weapi_encrypt_with_secret(params, &random_secret())
}

/// Same as [`weapi_encrypt`] with a caller-chosen secret (used by tests).
pub(crate) fn weapi_encrypt_with_secret(
    params: &Map<String, Value>,
    secret: &str,
) -> Result<(String, String)> {
    let text = json_text(params)?;
    let first = BASE64.encode(aes_cbc_encrypt(
        text.as_bytes(),
        WEAPI_PRESET_KEY,
        WEAPI_IV,
    )?);
    let second = BASE64.encode(aes_cbc_encrypt(
        first.as_bytes(),
        secret.as_bytes(),
        WEAPI_IV,
    )?);
    Ok((second, rsa_encrypt(secret)))
}

/// eapi digest: md5 of `nobody<url>use<json>md5forencrypt`.
pub fn eapi_digest(url: &str, text: &str) -> String {
    md5_digest_hex(&format!("nobody{url}use{text}md5forencrypt"))
}

/// eapi body: uppercase hex of AES-ECB over `url` + separator + JSON + digest.
pub fn eapi_encrypt(url: &str, params: &Map<String, Value>) -> Result<String> {
    let text = json_text(params)?;
    let digest = eapi_digest(url, &text);
    let message = format!("{url}{EAPI_SEPARATOR}{text}{EAPI_SEPARATOR}{digest}");
    Ok(hex::encode_upper(aes_ecb_encrypt(
        message.as_bytes(),
        EAPI_KEY,
    )?))
}

/// linuxapi `eparams`: uppercase hex of AES-ECB over `{method,url,params}`.
pub fn linuxapi_encrypt(url: &str, params: &Map<String, Value>) -> Result<String> {
    let mut payload = Map::new();
    payload.insert("method".into(), Value::String("POST".into()));
    payload.insert("url".into(), Value::String(url.into()));
    payload.insert("params".into(), Value::Object(params.clone()));
    let text = json_text(&payload)?;
    Ok(hex::encode_upper(aes_ecb_encrypt(
        text.as_bytes(),
        LINUXAPI_KEY,
    )?))
}

#[cfg(test)]
mod tests {
    use super::*;
    use cipher::BlockDecryptMut;

    fn params(json: &str) -> Map<String, Value> {
        serde_json::from_str(json).expect("json object")
    }

    fn aes_ecb_decrypt(data: &[u8], key: &[u8]) -> Vec<u8> {
        let cipher = Aes128::new_from_slice(key).expect("key");
        cipher
            .decrypt_padded_vec_mut::<Pkcs7>(data)
            .expect("valid padding")
    }

    fn aes_cbc_decrypt(data: &[u8], key: &[u8], iv: &[u8]) -> Vec<u8> {
        let cipher = cbc::Decryptor::<Aes128>::new_from_slices(key, iv).expect("key/iv");
        cipher
            .decrypt_padded_vec_mut::<Pkcs7>(data)
            .expect("valid padding")
    }

    // Known answers computed independently with pycryptodome, so these pin
    // the AES core and the PKCS#7 layer, not just self-consistency.
    #[test]
    fn aes_ecb_known_answers() {
        assert_eq!(
            hex::encode(aes_ecb_encrypt(b"hello", EAPI_KEY).unwrap()),
            "3329caba8fb561ff0086a5823d14f529"
        );
        let json = br#"{"ids":"[347230]","level":"exhigh"}"#;
        assert_eq!(
            hex::encode(aes_ecb_encrypt(json, EAPI_KEY).unwrap()),
            "27933fcd570795efe298e7d594781a368d4ebdf181cdbcd4213e43962f96c98c5eeea2ac394bd580eb3c40e66d6de8a0"
        );
    }

    #[test]
    fn aes_cbc_known_answer() {
        assert_eq!(
            hex::encode(aes_cbc_encrypt(b"hello", WEAPI_PRESET_KEY, WEAPI_IV).unwrap()),
            "f89f50def2f32c616eaa5585421dd3dc"
        );
    }

    #[test]
    fn pkcs7_round_trips_for_any_length() {
        for len in [0usize, 1, 15, 16, 17, 100] {
            let data = vec![7u8; len];
            let out = aes_ecb_encrypt(&data, EAPI_KEY).unwrap();
            assert_eq!(out.len() % 16, 0);
            assert_eq!(aes_ecb_decrypt(&out, EAPI_KEY), data);
        }
    }

    #[test]
    fn eapi_body_carries_url_json_and_digest() {
        let p = params(r#"{"ids":"[347230]","level":"exhigh"}"#);
        let body = eapi_encrypt("/api/song/enhance/player/url/v1", &p).unwrap();
        assert!(body.chars().all(|c| c.is_ascii_hexdigit()));

        let raw = hex::decode(&body).unwrap();
        let message = String::from_utf8(aes_ecb_decrypt(&raw, EAPI_KEY)).unwrap();
        let parts: Vec<&str> = message.split(EAPI_SEPARATOR).collect();
        assert_eq!(parts.len(), 3);
        assert_eq!(parts[0], "/api/song/enhance/player/url/v1");
        assert_eq!(parts[1], json_text(&p).unwrap());
        assert_eq!(parts[2], eapi_digest(parts[0], parts[1]));
    }

    #[test]
    fn weapi_layers_decrypt_in_order() {
        let p = params(r#"{"s":"海阔天空","type":1}"#);
        let secret = "abcdefghijklmnop";
        let (params_b64, enc_sec_key) = weapi_encrypt_with_secret(&p, secret).unwrap();
        assert_eq!(enc_sec_key.len(), 256);
        assert!(enc_sec_key.chars().all(|c| c.is_ascii_hexdigit()));

        // Layer 2: the per-request secret protects the base64 of layer 1.
        let layer1 = BASE64.decode(&params_b64).unwrap();
        let first = String::from_utf8(aes_cbc_decrypt(
            &layer1,
            secret.as_bytes(),
            WEAPI_IV,
        ))
        .unwrap();
        // Layer 1: the preset key protects the JSON body.
        let inner = BASE64.decode(first.as_bytes()).unwrap();
        let json = String::from_utf8(aes_cbc_decrypt(&inner, WEAPI_PRESET_KEY, WEAPI_IV)).unwrap();
        assert_eq!(json, json_text(&p).unwrap());
    }

    #[test]
    fn rsa_output_is_256_hex_chars() {
        let out = rsa_encrypt("abcdefghijklmnop");
        assert_eq!(out.len(), 256);
        assert!(out.chars().all(|c| c.is_ascii_hexdigit()));
    }

    #[test]
    fn linuxapi_eparams_wraps_method_url_params() {
        let p = params(r#"{"id":1}"#);
        let body = linuxapi_encrypt("/api/song/detail", &p).unwrap();
        let raw = hex::decode(&body).unwrap();
        let text = String::from_utf8(aes_ecb_decrypt(&raw, LINUXAPI_KEY)).unwrap();
        let v: Value = serde_json::from_str(&text).unwrap();
        assert_eq!(v["method"], "POST");
        assert_eq!(v["url"], "/api/song/detail");
        assert_eq!(v["params"]["id"], 1);
    }

    #[test]
    fn secrets_are_16_alphanumerics() {
        for _ in 0..8 {
            let s = random_secret();
            assert_eq!(s.len(), 16);
            assert!(s.chars().all(|c| c.is_ascii_alphanumeric()));
        }
    }

    #[test]
    fn md5_matches_known_digest() {
        assert_eq!(md5_hex(b"abc"), "900150983cd24fb0d6963f7d28e17f72");
    }
}
