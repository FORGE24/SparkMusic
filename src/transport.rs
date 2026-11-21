//! Blocking HTTP transport built on ureq.
//!
//! The Qt object calls into here synchronously, so keep an eye on the caller:
//! a QML/GUI thread should hand work to a worker (see the README roadmap).

use std::collections::HashMap;
use std::sync::RwLock;
use std::time::Duration;

use serde_json::{Map, Value};

use crate::catalog::canonical;
use crate::crypto;
use crate::error::{CoreError, CoreResult};

pub const APP_VERSION: &str = "9.6.30";
pub const USER_AGENT: &str = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 \
     (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36";

const TRANSPORT_MODES: [&str; 4] = ["eapi", "weapi", "api", "linuxapi"];

pub fn base_url(mode: &str) -> Option<&'static str> {
    match mode {
        "eapi" => Some("https://interface.music.163.com/eapi/"),
        "weapi" => Some("https://music.163.com/weapi/"),
        "api" => Some("https://music.163.com/api/"),
        "linuxapi" => Some("https://music.163.com/api/linux/forward"),
        _ => None,
    }
}

pub struct Transport {
    mode: RwLock<String>,
    device_id: String,
    cookie: RwLock<HashMap<String, String>>,
    agent: ureq::Agent,
    /// Test-only override; production uses the hard-coded NetEase hosts.
    base_override: Option<String>,
}

impl Transport {
    pub fn new(mode: &str, cookie_header: &str, device_id: &str) -> Self {
        let config = ureq::Agent::config_builder()
            .timeout_global(Some(Duration::from_secs(15)))
            .http_status_as_error(false)
            .build();
        Self {
            mode: RwLock::new(mode.to_string()),
            device_id: device_id.to_string(),
            cookie: RwLock::new(parse_cookie_header(cookie_header)),
            agent: config.new_agent(),
            base_override: None,
        }
    }

    #[cfg(test)]
    fn with_base(mut self, base: &str) -> Self {
        self.base_override = Some(base.to_string());
        self
    }

    pub fn mode(&self) -> String {
        self.mode.read().expect("mode lock").clone()
    }

    pub fn device_id(&self) -> &str {
        &self.device_id
    }

    pub fn set_mode(&self, mode: &str) {
        *self.mode.write().expect("mode lock") = mode.to_string();
    }

    /// Replace the cookie jar from a `MUSIC_U=…; __csrf=…` header.
    ///
    /// A new `MUSIC_U` means a new session, so old account cookies (including
    /// a stale `__csrf`) are dropped instead of being mixed with it.
    pub fn set_cookie_header(&self, raw: &str) {
        let parsed = parse_cookie_header(raw);
        let mut jar = self.cookie.write().expect("cookie lock");
        if parsed.contains_key("MUSIC_U") {
            jar.clear();
        }
        jar.extend(parsed);
    }

    /// Drop every cookie (used when switching accounts).
    pub fn clear_cookies(&self) {
        self.cookie.write().expect("cookie lock").clear();
    }

    /// Current cookie header (includes cookies captured from login responses).
    pub fn current_cookie_header(&self) -> String {
        cookie_header_of(&self.cookie.read().expect("cookie lock"))
    }

    /// Stable, non-secret identifier for the current login session.
    ///
    /// Cache keys use this so an anonymous lookup can never be served to a
    /// logged-in account (or the other way round) and two accounts cannot
    /// share a cached 「我喜欢的音乐」.
    pub fn session_key(&self) -> String {
        let jar = self.cookie.read().expect("cookie lock");
        match jar.get("MUSIC_U").filter(|value| !value.is_empty()) {
            Some(value) => {
                let digest = crypto::md5_hex(value.as_bytes());
                format!("u{}", &digest[..16])
            }
            None => "anon".to_string(),
        }
    }

    pub fn call(&self, route: &str, params: &Map<String, Value>) -> CoreResult<Value> {
        let mode = self.mode();
        self.call_in(&mode, route, params)
    }

    /// Call a route with an explicit envelope mode (login endpoints need weapi).
    pub fn call_mode(
        &self,
        route: &str,
        params: &Map<String, Value>,
        mode: &str,
    ) -> CoreResult<Value> {
        self.call_in(mode, route, params)
    }

    fn call_in(&self, mode: &str, route: &str, params: &Map<String, Value>) -> CoreResult<Value> {
        if !TRANSPORT_MODES.contains(&mode) {
            return Err(CoreError::UnsupportedMode(mode.to_string()));
        }

        let (path, query) = split_route(route);
        let mut body = Map::new();
        for (key, value) in query {
            body.insert(key, Value::String(value));
        }
        for (key, value) in params {
            if !value.is_null() {
                body.insert(key.clone(), value.clone());
            }
        }

        let (url, form) = self.build_request(mode, &path, body)?;
        let text = self.post(&url, &form)?;
        let parsed = parse_body(&text);
        // Login wrappers may return the session in a body field instead of
        // Set-Cookie (SMS/password logins through generic callWithMode do).
        // The field is normally a cookie header string, but some wrappers
        // return a list of strings, so accept both.
        match parsed.get("cookie") {
            Some(Value::String(cookie)) if !cookie.is_empty() => {
                self.set_cookie_header(cookie);
            }
            Some(Value::Array(items)) => {
                for item in items.iter().filter_map(Value::as_str) {
                    if !item.is_empty() {
                        self.set_cookie_header(item);
                    }
                }
            }
            _ => {}
        }
        Ok(parsed)
    }

    /// Base URL for an envelope. `SPARKMUSIC_*_BASE` makes the core usable
    /// against a mirror (and against the mock server in tests); the built-in
    /// NetEase hosts remain the default.
    fn endpoint_base(&self, mode: &str) -> Option<String> {
        let base = if let Some(base) = &self.base_override {
            base.clone()
        } else {
            let var = match mode {
                "eapi" => "SPARKMUSIC_EAPI_BASE",
                "weapi" => "SPARKMUSIC_WEAPI_BASE",
                "api" => "SPARKMUSIC_API_BASE",
                "linuxapi" => "SPARKMUSIC_LINUXAPI_BASE",
                _ => return None,
            };
            match std::env::var_os(var) {
                Some(value) if !value.to_string_lossy().trim().is_empty() => {
                    value.to_string_lossy().trim().to_string()
                }
                _ => base_url(mode)?.to_string(),
            }
        };
        // The directory bases need a trailing slash; linuxapi is a single
        // forwarded endpoint and is used verbatim.
        if mode == "linuxapi" || base.ends_with('/') {
            Some(base)
        } else {
            Some(format!("{base}/"))
        }
    }

    fn build_request(
        &self,
        mode: &str,
        path: &str,
        mut body: Map<String, Value>,
    ) -> CoreResult<(String, Vec<(String, String)>)> {
        let base = self
            .endpoint_base(mode)
            .ok_or_else(|| CoreError::UnsupportedMode(mode.to_string()))?;
        let csrf = self.csrf_token();

        match mode {
            "eapi" => {
                self.inject_defaults(&mut body);
                if !csrf.is_empty() {
                    body.entry("csrf_token".to_string())
                        .or_insert_with(|| Value::String(csrf));
                }
                let signed = crypto::eapi_encrypt(&format!("/api/{path}"), &body)?;
                Ok((format!("{base}{path}"), vec![("params".into(), signed)]))
            }
            "weapi" => {
                let (params, enc_sec_key) = crypto::weapi_encrypt(&body)?;
                let url = format!("{base}{path}?csrf_token={csrf}");
                Ok((
                    url,
                    vec![
                        ("params".into(), params),
                        ("encSecKey".into(), enc_sec_key),
                        ("csrf_token".into(), csrf),
                    ],
                ))
            }
            "api" => {
                if !csrf.is_empty() {
                    body.entry("csrf_token".to_string())
                        .or_insert_with(|| Value::String(csrf));
                }
                Ok((format!("{base}{path}"), flatten_form(&body)))
            }
            "linuxapi" => {
                let eparams = crypto::linuxapi_encrypt(&format!("/api/{path}"), &body)?;
                Ok((base.to_string(), vec![("eparams".into(), eparams)]))
            }
            other => Err(CoreError::UnsupportedMode(other.to_string())),
        }
    }

    fn inject_defaults(&self, body: &mut Map<String, Value>) {
        let defaults = [
            ("os", "android".to_string()),
            ("appver", APP_VERSION.to_string()),
            ("osver", "13".to_string()),
            ("channel", "netease".to_string()),
            ("deviceId", self.device_id.clone()),
            ("requestId", uuid_like()),
        ];
        for (key, value) in defaults {
            body.entry(key.to_string()).or_insert(Value::String(value));
        }
    }

    /// Merge `Set-Cookie` response headers into the jar (login needs this).
    fn absorb_cookies(&self, response: &ureq::http::Response<ureq::Body>) {
        let mut pairs = Vec::new();
        for value in response.headers().get_all("set-cookie") {
            let Ok(text) = value.to_str() else { continue };
            let pair = text.split(';').next().unwrap_or("");
            if let Some((key, val)) = pair.split_once('=') {
                let key = key.trim();
                if !key.is_empty() {
                    pairs.push((key.to_string(), val.trim().trim_matches('"').to_string()));
                }
            }
        }
        if pairs.is_empty() {
            return;
        }
        let mut jar = self.cookie.write().expect("cookie lock");
        if pairs.iter().any(|(key, _)| key == "MUSIC_U") {
            jar.clear();
        }
        for (key, value) in pairs {
            jar.insert(key, value);
        }
    }

    fn post(&self, url: &str, form: &[(String, String)]) -> CoreResult<String> {
        let mut request = self
            .agent
            .post(url)
            .header("User-Agent", USER_AGENT)
            .header("Accept", "*/*")
            .header("Accept-Language", "zh-CN,zh;q=0.9,en;q=0.6")
            .header("Referer", "https://music.163.com/")
            .header("Origin", "https://music.163.com");

        let cookie = self.cookie_header();
        if !cookie.is_empty() {
            request = request.header("Cookie", &cookie);
        }

        let response = request
            .send_form(form.iter().map(|(k, v)| (k.as_str(), v.as_str())))
            .map_err(|e| CoreError::Transport(e.to_string()))?;

        let status = response.status().as_u16();
        self.absorb_cookies(&response);
        let mut response = response;
        let text = response
            .body_mut()
            .read_to_string()
            .map_err(|e| CoreError::Transport(e.to_string()))?;

        if status >= 400 {
            return Err(CoreError::Http {
                status,
                body: truncate(&text, 300),
            });
        }
        Ok(text)
    }

    fn csrf_token(&self) -> String {
        self.cookie
            .read()
            .expect("cookie lock")
            .get("__csrf")
            .cloned()
            .unwrap_or_default()
    }

    fn cookie_header(&self) -> String {
        cookie_header_of(&self.cookie.read().expect("cookie lock"))
    }
}

fn cookie_header_of(jar: &HashMap<String, String>) -> String {
    let mut pairs: Vec<(&String, &String)> = jar.iter().collect();
    pairs.sort_by(|a, b| a.0.cmp(b.0));
    pairs
        .into_iter()
        .map(|(k, v)| format!("{k}={v}"))
        .collect::<Vec<_>>()
        .join("; ")
}

/// Cookie attributes that may be present when the server returns a whole
/// `Set-Cookie` line in a JSON `cookie` field. They are not cookies and must
/// not be replayed in the `Cookie` request header.
const COOKIE_ATTRIBUTES: [&str; 9] = [
    "path",
    "domain",
    "expires",
    "max-age",
    "samesite",
    "secure",
    "httponly",
    "priority",
    "partitioned",
];

fn parse_cookie_header(header: &str) -> HashMap<String, String> {
    let mut jar = HashMap::new();
    for part in header.split(';') {
        let part = part.trim();
        let Some((key, value)) = part.split_once('=') else {
            continue;
        };
        let key = key.trim();
        if key.is_empty() || COOKIE_ATTRIBUTES.contains(&key.to_ascii_lowercase().as_str()) {
            continue;
        }
        jar.insert(key.to_string(), value.trim().trim_matches('"').to_string());
    }
    jar
}

fn parse_body(text: &str) -> Value {
    let trimmed = text.trim_start_matches('\u{feff}').trim();
    if trimmed.is_empty() {
        return Value::Null;
    }
    serde_json::from_str(trimmed).unwrap_or_else(|_| Value::String(trimmed.to_string()))
}

fn split_route(route: &str) -> (String, Vec<(String, String)>) {
    let canonical = canonical(route);
    let query = route
        .split_once('?')
        .map(|(_, q)| q.split('#').next().unwrap_or(""))
        .unwrap_or("");
    let pairs = query
        .split('&')
        .filter(|p| !p.is_empty())
        .filter_map(|pair| {
            let (k, v) = pair.split_once('=').unwrap_or((pair, ""));
            let key = percent_decode(k);
            if key.is_empty() {
                None
            } else {
                Some((key, percent_decode(v)))
            }
        })
        .collect();
    (canonical, pairs)
}

fn percent_decode(input: &str) -> String {
    let bytes = input.as_bytes();
    let mut out = Vec::with_capacity(bytes.len());
    let mut i = 0;
    while i < bytes.len() {
        match bytes[i] {
            b'%' if i + 2 < bytes.len() => {
                let hex = std::str::from_utf8(&bytes[i + 1..i + 3]).unwrap_or("");
                if let Ok(byte) = u8::from_str_radix(hex, 16) {
                    out.push(byte);
                    i += 3;
                    continue;
                }
                out.push(b'%');
                i += 1;
            }
            b'+' => {
                out.push(b' ');
                i += 1;
            }
            byte => {
                out.push(byte);
                i += 1;
            }
        }
    }
    String::from_utf8_lossy(&out).into_owned()
}

fn flatten_form(body: &Map<String, Value>) -> Vec<(String, String)> {
    body.iter()
        .map(|(k, v)| {
            let value = match v {
                Value::String(s) => s.clone(),
                Value::Null => String::new(),
                other => other.to_string(),
            };
            (k.clone(), value)
        })
        .collect()
}

/// NetEase's eapi defaults carry a UUID v4 shaped requestId; a bare hex blob
/// looks less like the real client which matters for risk control.
fn uuid_like() -> String {
    let hex = random_hex(16);
    format!(
        "{}-{}-{}-{}-{}",
        &hex[0..8],
        &hex[8..12],
        &hex[12..16],
        &hex[16..20],
        &hex[20..32]
    )
}

fn random_hex(bytes: usize) -> String {
    let mut buf = vec![0u8; bytes];
    for chunk in buf.chunks_mut(8) {
        let value: u64 = rand::random();
        let raw = value.to_be_bytes();
        for (slot, byte) in chunk.iter_mut().zip(raw.iter()) {
            *slot = *byte;
        }
    }
    hex::encode(buf)
}

fn truncate(text: &str, max: usize) -> String {
    if text.len() <= max {
        return text.to_string();
    }
    let cut = text
        .char_indices()
        .take_while(|(i, _)| *i < max)
        .last()
        .map(|(i, c)| i + c.len_utf8())
        .unwrap_or(0);
    format!("{}…", &text[..cut])
}

#[cfg(test)]
mod tests {
    use super::*;

    fn transport(mode: &str) -> Transport {
        Transport::new(mode, "", "0123456789abcdef0123456789abcdef")
    }

    #[test]
    fn routes_are_split_from_query_strings() {
        let (path, query) = split_route("song/detail?ids=1&level=exhigh");
        assert_eq!(path, "song/detail");
        assert_eq!(query.len(), 2);
        assert_eq!(query[0], ("ids".into(), "1".into()));
    }

    #[test]
    fn eapi_request_is_signed_for_the_api_path() {
        let t = transport("eapi");
        let (url, form) = t
            .build_request("eapi", "song/enhance/player/url/v1", Map::new())
            .unwrap();
        assert_eq!(
            url,
            "https://interface.music.163.com/eapi/song/enhance/player/url/v1"
        );
        assert_eq!(form[0].0, "params");
        assert!(!form[0].1.is_empty());
    }

    #[test]
    fn weapi_request_carries_csrf() {
        let t = Transport::new("weapi", "MUSIC_U=abc; __csrf=tok", "dev");
        let (url, form) = t.build_request("weapi", "song/detail", Map::new()).unwrap();
        assert!(url.ends_with("?csrf_token=tok"));
        assert_eq!(form.len(), 3);
    }

    #[test]
    fn api_mode_is_plain_form() {
        let t = Transport::new("api", "__csrf=tok", "dev");
        let mut body = Map::new();
        body.insert("id".into(), Value::from(1));
        let (_, form) = t.build_request("api", "song/detail", body).unwrap();
        assert!(form.contains(&("id".into(), "1".into())));
        assert!(form.contains(&("csrf_token".into(), "tok".into())));
    }

    #[test]
    fn unknown_mode_is_rejected() {
        let t = transport("xeapi");
        let err = t.call("song/detail", &Map::new()).unwrap_err();
        assert!(matches!(err, CoreError::UnsupportedMode(_)));
    }

    #[test]
    fn cookies_are_sorted_and_parsed() {
        let t = Transport::new("eapi", "MUSIC_U=abc; __csrf=tok", "dev");
        assert_eq!(t.cookie_header(), "MUSIC_U=abc; __csrf=tok");
        assert_eq!(t.csrf_token(), "tok");
    }

    #[test]
    fn set_cookie_attributes_are_not_replayed() {
        // The login response can put a whole `Set-Cookie` line in the JSON
        // `cookie` field; only the name=value pairs may go back on the wire.
        let raw = "MUSIC_U=abc; Max-Age=1296000; Expires=Wed, 21 Nov 2026 18:50:00 GMT; \
                   Path=/; Domain=.music.163.com; HTTPOnly; SameSite=Lax";
        let t = Transport::new("eapi", raw, "dev");
        assert_eq!(t.cookie_header(), "MUSIC_U=abc");
        assert_eq!(t.csrf_token(), "");
    }

    #[test]
    fn quoted_cookie_values_are_unwrapped() {
        let t = Transport::new("eapi", "MUSIC_U=\"abc\"; __csrf=\"tok\"", "dev");
        assert_eq!(t.cookie_header(), "MUSIC_U=abc; __csrf=tok");
    }

    #[test]
    fn body_cookie_is_absorbed_and_attributes_are_dropped() {
        use std::io::{Read, Write};
        use std::net::TcpListener;

        let listener = TcpListener::bind("127.0.0.1:0").expect("bind mock server");
        let port = listener.local_addr().expect("mock addr").port();
        let handle = std::thread::spawn(move || {
            let (mut stream, _) = listener.accept().expect("accept");
            let mut buf = [0u8; 8192];
            let _ = stream.read(&mut buf);
            let body = r#"{"code":200,"account":{"id":1},"cookie":"MUSIC_U=abc; Max-Age=1296000; Path=/; Domain=.music.163.com; HTTPOnly"}"#;
            let response = format!(
                "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{}",
                body.as_bytes().len(),
                body
            );
            let _ = stream.write_all(response.as_bytes());
        });

        let base = format!("http://127.0.0.1:{port}/eapi/");
        let t = Transport::new("eapi", "", "dev").with_base(&base);
        let value = t
            .call("login/cellphone", &Map::new())
            .expect("mock login response");
        handle.join().expect("mock server");

        assert_eq!(value["code"], 200);
        assert_eq!(t.cookie_header(), "MUSIC_U=abc");
        assert_ne!(t.session_key(), "anon");
    }

    #[test]
    fn set_cookie_headers_replace_a_stale_session() {
        use std::io::{Read, Write};
        use std::net::TcpListener;

        let listener = TcpListener::bind("127.0.0.1:0").expect("bind mock server");
        let port = listener.local_addr().expect("mock addr").port();
        let handle = std::thread::spawn(move || {
            let (mut stream, _) = listener.accept().expect("accept");
            let mut buf = [0u8; 8192];
            let _ = stream.read(&mut buf);
            let body = r#"{"code":803}"#;
            let response = format!(
                "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nSet-Cookie: MUSIC_U=header; Path=/; HTTPOnly\r\nSet-Cookie: __csrf=header-csrf; Path=/\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{}",
                body.as_bytes().len(),
                body
            );
            let _ = stream.write_all(response.as_bytes());
        });

        let base = format!("http://127.0.0.1:{port}/eapi/");
        let t = Transport::new("eapi", "MUSIC_U=old; __csrf=old-csrf; NMTID=keep", "dev")
            .with_base(&base);
        t.call("login/qrcode/client/login", &Map::new())
            .expect("mock login response");
        handle.join().expect("mock server");

        assert_eq!(t.cookie_header(), "MUSIC_U=header; __csrf=header-csrf");
        assert_eq!(t.csrf_token(), "header-csrf");
    }

    #[test]
    fn a_new_session_cookie_replaces_the_old_account_cookies() {
        let t = Transport::new("eapi", "MUSIC_U=old; __csrf=old-csrf; NMTID=keep", "dev");
        t.set_cookie_header("MUSIC_U=new; Path=/; HTTPOnly");
        assert_eq!(t.cookie_header(), "MUSIC_U=new");
        assert_eq!(t.csrf_token(), "");
    }

    #[test]
    fn session_key_separates_anonymous_and_accounts() {
        let anon = transport("eapi");
        assert_eq!(anon.session_key(), "anon");

        let first = Transport::new("eapi", "MUSIC_U=account-a; __csrf=1", "dev");
        let same = Transport::new("eapi", "MUSIC_U=account-a; __csrf=2", "dev");
        let other = Transport::new("eapi", "MUSIC_U=account-b; __csrf=1", "dev");
        assert_eq!(first.session_key(), same.session_key());
        assert_ne!(first.session_key(), other.session_key());
        assert_ne!(first.session_key(), "anon");
        assert!(!first.session_key().contains("account-a"));
    }
}
