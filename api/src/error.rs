//! Error type shared by the transport and the HTTP layer.

use axum::http::StatusCode;
use axum::response::{IntoResponse, Response};
use serde_json::json;

#[derive(Debug, thiserror::Error)]
pub enum Error {
    #[error("unknown route: {0}")]
    UnknownRoute(String),

    #[error("unsupported transport mode: {0}")]
    UnsupportedMode(String),

    #[error("bad request: {0}")]
    BadRequest(String),

    #[error("encryption failed: {0}")]
    Crypto(String),

    #[error("upstream request failed: {0}")]
    Upstream(String),

    #[error("upstream returned HTTP {status}: {body}")]
    Http { status: u16, body: String },
}

pub type Result<T> = std::result::Result<T, Error>;

impl Error {
    pub fn status(&self) -> StatusCode {
        match self {
            Error::UnknownRoute(_) => StatusCode::NOT_FOUND,
            Error::UnsupportedMode(_) | Error::BadRequest(_) => StatusCode::BAD_REQUEST,
            Error::Crypto(_) => StatusCode::INTERNAL_SERVER_ERROR,
            Error::Upstream(_) | Error::Http { .. } => StatusCode::BAD_GATEWAY,
        }
    }
}

impl IntoResponse for Error {
    fn into_response(self) -> Response {
        let status = self.status();
        let body = json!({
            "code": -1,
            "message": self.to_string(),
        });
        (status, axum::Json(body)).into_response()
    }
}

impl From<reqwest::Error> for Error {
    fn from(value: reqwest::Error) -> Self {
        Error::Upstream(value.to_string())
    }
}
