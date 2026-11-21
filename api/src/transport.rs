//! HTTP transport: payload construction, cookies, retries.

use std::collections::HashMap;
use std::sync::RwLock;

use reqwest::header::{HeaderMap, HeaderValue};
use reqwest::Client;
use serde_json::{Map, Value};

use crate::config::{Config, APP_VERSION};
use crate::crypto;
use crate::error::{Error, Result};

const TRANSPORT_MODES: [&str; 4] = ["eapi", "weapi", "api", "linuxapi"];

pub struct Transport {
    client: Client,
    config: Config,
    cookies: RwLock<HashMap<String, String>>,
    device_id: String,
}

impl Transport {
    pub fn new(config: Config) -> Self {
        let client = Client::builder()
            .timeout(config.timeout)
            .build()
            .expect("reqwest client configuration is valid");
        Self {
            client,
            config,
            cookies: RwLock::new(HashMap::new()),
            device_id: random_hex(16),
        }
    }

    pub fn config(&self) -> &Config {
        &self.config
    }

    /// Accept `MUSIC_U=…; __csrf=…` (or a cookie map) as the session.
    pub fn set_cookie(&self, raw: &str) {
        let mut jar = self.cookies.write().expect("cookie lock");
        for part in raw.split(';') {
            let part = part.trim();
            if let Some((key, value)) = part.split_once('=') {
                let key = key.trim();
                if !key.is_empty() {
                    jar.insert(key.to_string(), value.trim().to_string());
                }
            }
        }
    }

    pub fn cookies(&self) -> HashMap<String, String> {
        self.cookies.read().expect("cookie lock").clone()
    }

    pub fn cookie_header(&self) -> String {
        let jar = self.cookies.read().expect("cookie lock");
        let mut pairs: Vec<(&String, &String)> = jar.iter().collect();
        // Sorted so the header is deterministic across runs.
        pairs.sort_by(|a, b| a.0.cmp(b.0));
        pairs
            .into_iter()
            .map(|(k, v)| format!("{k}={v}"))
            .collect::<Vec<_>>()
            .join("; ")
    }

    fn csrf_token(&self) -> String {
        self.cookies
            .read()
            .expect("cookie lock")
            .get("__csrf")
            .cloned()
            .unwrap_or_default()
    }

    /// Call a route with the configured default mode.
    pub async fn call(&self, route: &str, params: &Map<String, Value>) -> Result<Value> {
        self.call_with_mode(route, params, None).await
    }

    /// Call a route, optionally overriding the transport mode.
    pub async fn call_with_mode(
        &self,
        route: &str,
        params: &Map<String, Value>,
        mode: Option<&str>,
    ) -> Result<Value> {
        let mode = mode.unwrap_or(&self.config.mode);
        if !TRANSPORT_MODES.contains(&mode) {
            return Err(Error::UnsupportedMode(format!(
                "{mode} (supported: {})",
                TRANSPORT_MODES.join(", ")
            )));
        }

        let (path, query) = split_route(route);
        let mut body = Map::new();
        for (k, v) in query {
            body.insert(k, Value::String(v));
        }
        for (k, v) in params {
            if !v.is_null() {
                body.insert(k.clone(), v.clone());
            }
        }

        let (url, form) = self.build_request(mode, &path, body)?;
        let text = self.post(&url, form).await?;
        Ok(parse_body(&text))
    }

    fn build_request(
        &self,
        mode: &str,
        path: &str,
        mut body: Map<String, Value>,
    ) -> Result<(String, Vec<(String, String)>)> {
        let base = self
            .config
            .base_urls
            .get(mode)
            .ok_or_else(|| Error::UnsupportedMode(mode.to_string()))?;
        let csrf = self.csrf_token();

        match mode {
            "eapi" => {
                if self.config.inject_defaults {
                    self.inject_defaults(&mut body);
                }
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
                Ok((base.clone(), vec![("eparams".into(), eparams)]))
            }
            other => Err(Error::UnsupportedMode(other.to_string())),
        }
    }

    fn inject_defaults(&self, body: &mut Map<String, Value>) {
        let defaults = [
            ("os", "android".to_string()),
            ("appver", APP_VERSION.to_string()),
            ("osver", "13".to_string()),
            ("channel", "netease".to_string()),
            ("deviceId", self.device_id.clone()),
            ("requestId", random_hex(16)),
        ];
        for (key, value) in defaults {
            body.entry(key.to_string()).or_insert(Value::String(value));
        }
    }

    async fn post(&self, url: &str, form: Vec<(String, String)>) -> Result<String> {
        let attempts = self.config.retries.saturating_add(1);
        let mut last_error = None;

        for attempt in 0..attempts {
            let mut request = self
                .client
                .post(url)
                .headers(self.headers())
                .form(&form);
            if self.config.timeout.as_millis() > 0 {
                request = request.timeout(self.config.timeout);
            }

            match request.send().await {
                Ok(response) => {
                    let status = response.status();
                    if status.is_server_error() || status.as_u16() == 429 {
                        last_error = Some(Error::Http {
                            status: status.as_u16(),
                            body: response.text().await.unwrap_or_default(),
                        });
                    } else if !status.is_success() {
                        let body = response.text().await.unwrap_or_default();
                        return Err(Error::Http {
                            status: status.as_u16(),
                            body: truncate(&body, 300),
                        });
                    } else {
                        return response
                            .text()
                            .await
                            .map_err(|e| Error::Upstream(e.to_string()));
                    }
                }
                Err(err) => last_error = Some(Error::Upstream(err.to_string())),
            }

            if attempt + 1 < attempts {
                let backoff = 400u64.saturating_mul(1 << attempt).min(4000);
                tokio::time::sleep(std::time::Duration::from_millis(backoff)).await;
            }
        }

        Err(last_error.unwrap_or_else(|| Error::Upstream("request failed".into())))
    }

    fn headers(&self) -> HeaderMap {
        let mut headers = HeaderMap::new();
        headers.insert("User-Agent", header_value(&self.config.user_agent));
        headers.insert("Accept", header_value("*/*"));
        headers.insert(
            "Accept-Language",
            header_value("zh-CN,zh;q=0.9,en;q=0.6"),
        );
        headers.insert(
            "Content-Type",
            header_value("application/x-www-form-urlencoded"),
        );
        headers.insert("Referer", header_value("https://music.163.com/"));
        headers.insert("Origin", header_value("https://music.163.com"));
        let cookie = self.cookie_header();
        if !cookie.is_empty() {
            headers.insert("Cookie", header_value(&cookie));
        }
        headers
    }
}

fn header_value(value: &str) -> HeaderValue {
    HeaderValue::from_str(value).unwrap_or_else(|_| HeaderValue::from_static(""))
}

fn truncate(text: &str, max: usize) -> String {
    if text.len() <= max {
        text.to_string()
    } else {
        format!("{}…", &text[..text.floor_char_boundary(max)])
    }
}

fn parse_body(text: &str) -> Value {
    let trimmed = text.trim_start_matches('\u{feff}').trim();
    if trimmed.is_empty() {
        return Value::Null;
    }
    serde_json::from_str(trimmed).unwrap_or_else(|_| Value::String(trimmed.to_string()))
}

/// Split any route spelling into a canonical path and its query pairs.
fn split_route(route: &str) -> (String, Vec<(String, String)>) {
    let mut path = route;
    if let Some((_, rest)) = path.split_once("://") {
        path = rest.split_once('/').map(|(_, p)| p).unwrap_or("");
    }
    let (path, query) = match path.split_once('?') {
        Some((p, q)) => (p, q),
        None => (path, ""),
    };
    let mut path = path.trim_matches('/');
    for prefix in ["api/", "weapi/", "eapi/", "xeapi/", "neapi/", "linuxapi/"] {
        if let Some(rest) = path.strip_prefix(prefix) {
            path = rest;
            break;
        }
    }
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
    (path.trim_matches('/').to_string(), pairs)
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

/// Form encoding: scalars as-is, structured values as JSON.
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

#[cfg(test)]
mod tests {
    use super::*;

    fn transport() -> Transport {
        Transport::new(Config::default())
    }

    #[test]
    fn splits_any_route_spelling() {
        let (path, query) = split_route("song/detail?ids=1&level=exhigh");
        assert_eq!(path, "song/detail");
        assert_eq!(query.len(), 2);
        assert_eq!(query[0], ("ids".into(), "1".into()));

        let (path, _) = split_route("/api/v3/song/detail");
        assert_eq!(path, "v3/song/detail");

        let (path, _) = split_route("https://music.163.com/weapi/song/detail?a=1");
        assert_eq!(path, "song/detail");
    }

    #[test]
    fn percent_decodes_query_values() {
        let (_, query) = split_route("song/detail?q=%E6%B5%B7&x=a+b");
        assert_eq!(query[0].1, "海");
        assert_eq!(query[1].1, "a b");
    }

    #[test]
    fn eapi_request_is_signed_for_the_api_path() {
        let t = transport();
        let mut body = Map::new();
        body.insert("ids".into(), Value::String("[347230]".into()));
        let (url, form) = t.build_request("eapi", "song/enhance/player/url/v1", body).unwrap();
        assert_eq!(url, "https://interface.music.163.com/eapi/song/enhance/player/url/v1");
        assert_eq!(form.len(), 1);
        assert_eq!(form[0].0, "params");
        assert!(!form[0].1.is_empty());
    }

    #[test]
    fn eapi_defaults_are_injected_once() {
        let t = transport();
        let mut body = Map::new();
        body.insert("os".into(), Value::String("pc".into()));
        t.inject_defaults(&mut body);
        assert_eq!(body["os"], "pc");
        assert_eq!(body["appver"], APP_VERSION);
        assert!(body.contains_key("deviceId"));
        assert!(body.contains_key("requestId"));
    }

    #[test]
    fn weapi_url_carries_the_csrf_query() {
        let t = transport();
        t.set_cookie("MUSIC_U=abc; __csrf=tok123");
        let (url, form) = t
            .build_request("weapi", "song/detail", Map::new())
            .unwrap();
        assert!(url.ends_with("?csrf_token=tok123"));
        let names: Vec<&str> = form.iter().map(|(k, _)| k.as_str()).collect();
        assert_eq!(names, ["params", "encSecKey", "csrf_token"]);
    }

    #[test]
    fn api_mode_sends_plain_form_with_csrf() {
        let t = transport();
        t.set_cookie("__csrf=tok");
        let mut body = Map::new();
        body.insert("id".into(), Value::Number(1.into()));
        let (_, form) = t.build_request("api", "song/detail", body).unwrap();
        assert!(form.contains(&("id".into(), "1".into())));
        assert!(form.contains(&("csrf_token".into(), "tok".into())));
    }

    #[test]
    fn linuxapi_posts_to_the_forward_endpoint() {
        let t = transport();
        let (url, form) = t.build_request("linuxapi", "song/detail", Map::new()).unwrap();
        assert_eq!(url, "https://music.163.com/api/linux/forward");
        assert_eq!(form[0].0, "eparams");
    }

    #[test]
    fn native_modes_are_rejected() {
        let t = transport();
        let err = t
            .build_request("xeapi", "song/detail", Map::new())
            .unwrap_err();
        assert!(matches!(err, Error::UnsupportedMode(_)));
    }

    #[test]
    fn cookie_header_round_trips() {
        let t = transport();
        t.set_cookie("MUSIC_U=abc; __csrf=tok");
        assert_eq!(t.cookie_header(), "MUSIC_U=abc; __csrf=tok");
        assert_eq!(t.csrf_token(), "tok");
    }
}
