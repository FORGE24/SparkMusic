//! Core error type. Every failure the Qt API can observe maps to one variant.

use std::fmt;

#[derive(Debug, Clone)]
pub enum CoreError {
    UnknownRoute(String),
    UnsupportedMode(String),
    BadRequest(String),
    Crypto(String),
    Transport(String),
    Http { status: u16, body: String },
    Json(String),
}

impl fmt::Display for CoreError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            CoreError::UnknownRoute(route) => write!(f, "unknown route: {route}"),
            CoreError::UnsupportedMode(mode) => write!(f, "unsupported transport mode: {mode}"),
            CoreError::BadRequest(msg) => write!(f, "bad request: {msg}"),
            CoreError::Crypto(msg) => write!(f, "encryption failed: {msg}"),
            CoreError::Transport(msg) => write!(f, "transport failed: {msg}"),
            CoreError::Http { status, body } => write!(f, "upstream returned HTTP {status}: {body}"),
            CoreError::Json(msg) => write!(f, "invalid JSON: {msg}"),
        }
    }
}

pub type CoreResult<T> = Result<T, CoreError>;

impl CoreError {
    /// JSON object the Qt side receives for a failure.
    pub fn to_json(&self) -> serde_json::Value {
        serde_json::json!({
            "code": -1,
            "message": self.to_string(),
        })
    }
}
