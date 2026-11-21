//! Runtime configuration, read from the environment.

use std::collections::HashMap;
use std::time::Duration;

/// App version advertised in the injected eapi defaults.  Keeping it in step
/// with the APK the catalog was recovered from keeps server-side feature
/// flags consistent with the routes we expose.
pub const APP_VERSION: &str = "9.6.30";

pub const DEFAULT_USER_AGENT: &str = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 \
     (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36";

#[derive(Debug, Clone)]
pub struct Config {
    /// `host:port` to bind.
    pub bind: String,
    /// Default transport mode: `eapi`, `weapi`, `api` or `linuxapi`.
    pub mode: String,
    pub timeout: Duration,
    pub retries: u32,
    /// Inject `os`/`appver`/`deviceId`/… into eapi bodies.
    pub inject_defaults: bool,
    pub user_agent: String,
    pub base_urls: HashMap<String, String>,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            bind: "127.0.0.1:8080".to_string(),
            mode: "eapi".to_string(),
            timeout: Duration::from_secs(15),
            retries: 2,
            inject_defaults: true,
            user_agent: DEFAULT_USER_AGENT.to_string(),
            base_urls: default_base_urls(),
        }
    }
}

impl Config {
    /// Read `SPARKMUSIC_*` variables, falling back to the defaults.
    pub fn from_env() -> Self {
        let mut cfg = Self::default();
        if let Ok(v) = std::env::var("SPARKMUSIC_BIND") {
            cfg.bind = v;
        }
        if let Ok(v) = std::env::var("SPARKMUSIC_MODE") {
            cfg.mode = v;
        }
        if let Ok(v) = std::env::var("SPARKMUSIC_TIMEOUT_MS") {
            if let Ok(ms) = v.parse::<u64>() {
                cfg.timeout = Duration::from_millis(ms);
            }
        }
        if let Ok(v) = std::env::var("SPARKMUSIC_RETRIES") {
            if let Ok(n) = v.parse::<u32>() {
                cfg.retries = n;
            }
        }
        if let Ok(v) = std::env::var("SPARKMUSIC_NO_DEFAULTS") {
            cfg.inject_defaults = !matches!(v.as_str(), "1" | "true" | "yes");
        }
        if let Ok(v) = std::env::var("SPARKMUSIC_EAPI_BASE") {
            cfg.base_urls.insert("eapi".into(), v);
        }
        if let Ok(v) = std::env::var("SPARKMUSIC_WEAPI_BASE") {
            cfg.base_urls.insert("weapi".into(), v);
        }
        if let Ok(v) = std::env::var("SPARKMUSIC_API_BASE") {
            cfg.base_urls.insert("api".into(), v);
        }
        cfg
    }
}

pub fn default_base_urls() -> HashMap<String, String> {
    [
        ("eapi", "https://interface.music.163.com/eapi/"),
        ("weapi", "https://music.163.com/weapi/"),
        ("api", "https://music.163.com/api/"),
        ("linuxapi", "https://music.163.com/api/linux/forward"),
    ]
    .into_iter()
    .map(|(k, v)| (k.to_string(), v.to_string()))
    .collect()
}
