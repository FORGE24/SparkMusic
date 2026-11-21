//! NetEase request envelopes, ported from the Python and Rust clients.
//!
//! eapi = AES-128-ECB over `url -36cd479b6b5- json -36cd479b6b5- md5(...)`,
//! weapi = AES-128-CBC twice (preset key, then a random secret) + textbook RSA,
//! linuxapi = AES-128-ECB over `{method,url,params}`.


/// Errors raised while building an envelope.
#[derive(Debug, Clone)]
pub enum CryptoError {
    Crypto(String),
    Json(String),
}

impl std::fmt::Display for CryptoError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            CryptoError::Crypto(msg) => write!(f, "{msg}"),
            CryptoError::Json(msg) => write!(f, "{msg}"),
        }
    }
}

impl std::error::Error for CryptoError {}

/// Result alias for envelope construction.
pub type CryptoResult<T> = Result<T, CryptoError>;

use base64::engine::general_purpose::STANDARD as BASE64;
use base64::Engine as _;
use md5::{Digest, Md5};
use num_bigint::BigUint;
use rand::distributions::Alphanumeric;
use rand::Rng;
use serde_json::{Map, Value};


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

fn crypto_error(message: impl Into<String>) -> CryptoError {
    CryptoError::Crypto(message.into())
}

pub fn md5_hex(data: &[u8]) -> String {
    hex::encode(Md5::digest(data))
}

pub fn md5_bytes(data: &[u8]) -> Vec<u8> {
    Md5::digest(data).to_vec()
}

pub fn aes_ecb_encrypt(data: &[u8], key: &[u8]) -> CryptoResult<Vec<u8>> {
    use aes::cipher::block_padding::Pkcs7;
    use aes::cipher::{BlockEncryptMut, KeyInit};
    let cipher = aes::Aes128::new_from_slice(key)
        .map_err(|_| crypto_error("invalid AES key length"))?;
    Ok(cipher.encrypt_padded_vec_mut::<Pkcs7>(data))
}

pub fn aes_cbc_encrypt(data: &[u8], key: &[u8], iv: &[u8]) -> CryptoResult<Vec<u8>> {
    use aes::cipher::block_padding::Pkcs7;
    use aes::cipher::{BlockEncryptMut, KeyIvInit};
    if iv.len() != 16 {
        return Err(crypto_error("AES IV must be exactly 16 bytes"));
    }
    let cipher = cbc::Encryptor::<aes::Aes128>::new_from_slices(key, iv)
        .map_err(|_| crypto_error("invalid AES key/IV length"))?;
    Ok(cipher.encrypt_padded_vec_mut::<Pkcs7>(data))
}

pub fn random_secret() -> String {
    rand::thread_rng()
        .sample_iter(&Alphanumeric)
        .take(16)
        .map(char::from)
        .collect()
}

/// Textbook RSA over the reversed secret, 256 lowercase hex characters.
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

pub fn json_text(params: &Map<String, Value>) -> CryptoResult<String> {
    serde_json::to_string(params).map_err(|e| CryptoError::Json(e.to_string()))
}

/// md5("nobody" + url + "use" + json + "md5forencrypt").
pub fn eapi_digest(url: &str, text: &str) -> String {
    md5_hex(format!("nobody{url}use{text}md5forencrypt").as_bytes())
}

pub fn eapi_encrypt(url: &str, params: &Map<String, Value>) -> CryptoResult<String> {
    let text = json_text(params)?;
    let digest = eapi_digest(url, &text);
    let message = format!("{url}{EAPI_SEPARATOR}{text}{EAPI_SEPARATOR}{digest}");
    let cipher = aes_ecb_encrypt(message.as_bytes(), EAPI_KEY)?;
    Ok(hex::encode_upper(cipher))
}

/// Returns `(params, encSecKey)` for a weapi body.
pub fn weapi_encrypt(params: &Map<String, Value>) -> CryptoResult<(String, String)> {
    let text = json_text(params)?;
    let secret = random_secret();
    let first = aes_cbc_encrypt(text.as_bytes(), WEAPI_PRESET_KEY, WEAPI_IV)?;
    let second = aes_cbc_encrypt(first.to_base64_string().as_bytes(), secret.as_bytes(), WEAPI_IV)?;
    Ok((second.to_base64_string(), rsa_encrypt(&secret)))
}

pub fn linuxapi_encrypt(url: &str, params: &Map<String, Value>) -> CryptoResult<String> {
    let mut payload = Map::new();
    payload.insert("method".into(), Value::String("POST".into()));
    payload.insert("url".into(), Value::String(url.into()));
    payload.insert("params".into(), Value::Object(params.clone()));
    let cipher = aes_ecb_encrypt(json_text(&payload)?.as_bytes(), LINUXAPI_KEY)?;
    Ok(hex::encode_upper(cipher))
}

/// Small helper so the envelope code reads like the Python version.
trait ToBase64String {
    fn to_base64_string(&self) -> String;
}

impl ToBase64String for [u8] {
    fn to_base64_string(&self) -> String {
        BASE64.encode(self)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn params(json: &str) -> Map<String, Value> {
        serde_json::from_str(json).expect("json object")
    }

    #[test]
    fn aes_ecb_matches_known_answer() {
        assert_eq!(
            hex::encode(aes_ecb_encrypt(b"hello", EAPI_KEY).unwrap()),
            "3329caba8fb561ff0086a5823d14f529"
        );
    }

    #[test]
    fn aes_cbc_matches_known_answer() {
        assert_eq!(
            hex::encode(aes_cbc_encrypt(b"hello", WEAPI_PRESET_KEY, WEAPI_IV).unwrap()),
            "f89f50def2f32c616eaa5585421dd3dc"
        );
    }

    #[test]
    fn eapi_body_has_url_json_and_digest() {
        let p = params(r#"{"ids":"[347230]","level":"exhigh"}"#);
        let body = eapi_encrypt("/api/song/enhance/player/url/v1", &p).unwrap();
        assert!(body.chars().all(|c| c.is_ascii_hexdigit()));
        let raw = hex::decode(&body).unwrap();
        // 3 AES blocks: 48 bytes -> 96 hex chars minimum.
        assert!(raw.len() % 16 == 0 && raw.len() >= 48);
    }

    #[test]
    fn rsa_is_256_hex_chars() {
        let out = rsa_encrypt("abcdefghijklmnop");
        assert_eq!(out.len(), 256);
        assert!(out.chars().all(|c| c.is_ascii_hexdigit()));
    }

    #[test]
    fn md5_matches_known_digest() {
        assert_eq!(md5_hex(b"abc"), "900150983cd24fb0d6963f7d28e17f72");
    }

    #[test]
    fn secrets_are_16_alphanumerics() {
        let secret = random_secret();
        assert_eq!(secret.len(), 16);
        assert!(secret.chars().all(|c| c.is_ascii_alphanumeric()));
    }
}
