//! Router-level tests. No network: only handlers that never call upstream.

use std::sync::Arc;

use axum::body::Body;
use axum::http::{Request, StatusCode};
use http_body_util::BodyExt;
use sparkmusic_api::api::{AppState, router};
use sparkmusic_api::config::Config;
use sparkmusic_api::transport::Transport;
use tower::ServiceExt;

fn app() -> axum::Router {
    let transport = Arc::new(Transport::new(Config::default()));
    router(AppState { transport })
}

async fn get(path: &str) -> (StatusCode, serde_json::Value) {
    let request = Request::builder()
        .uri(path)
        .body(Body::empty())
        .expect("request");
    let response = app().oneshot(request).await.expect("response");
    let status = response.status();
    let bytes = response
        .into_body()
        .collect()
        .await
        .expect("body")
        .to_bytes();
    let json = serde_json::from_slice(&bytes).unwrap_or(serde_json::Value::Null);
    (status, json)
}

#[tokio::test]
async fn health_reports_the_catalog() {
    let (status, body) = get("/health").await;
    assert_eq!(status, StatusCode::OK);
    assert_eq!(body["status"], "ok");
    assert_eq!(body["routes"], 1293);
    assert_eq!(body["groups"], 150);
}

#[tokio::test]
async fn routes_can_be_searched_and_paged() {
    let (status, body) = get("/routes?q=song/detail&limit=5").await;
    assert_eq!(status, StatusCode::OK);
    assert!(body["total"].as_u64().unwrap() >= 1);
    assert!(body["routes"].as_array().unwrap().len() <= 5);
}

#[tokio::test]
async fn single_route_lookup_accepts_any_spelling() {
    let (status, body) = get("/routes/v3/song/detail").await;
    assert_eq!(status, StatusCode::OK);
    assert_eq!(body["route"], "v3/song/detail");
    assert_eq!(body["group"], "song");

    let (status, body) = get("/routes/api/song/detail").await;
    assert_eq!(status, StatusCode::OK);
    assert_eq!(body["route"], "v3/song/detail");
}

#[tokio::test]
async fn unknown_route_is_404_with_a_message() {
    let (status, body) = get("/routes/definitely/not/a/route").await;
    assert_eq!(status, StatusCode::NOT_FOUND);
    assert_eq!(body["code"], -1);
    assert!(body["message"].as_str().unwrap().contains("unknown route"));
}

#[tokio::test]
async fn search_requires_a_keyword() {
    let (status, body) = get("/api/search").await;
    assert_eq!(status, StatusCode::BAD_REQUEST);
    assert!(body["message"].as_str().unwrap().contains("keywords"));
}

#[tokio::test]
async fn song_url_requires_ids() {
    let (status, body) = get("/api/song/url").await;
    assert_eq!(status, StatusCode::BAD_REQUEST);
    assert!(body["message"].as_str().unwrap().contains("ids"));
}

#[tokio::test]
async fn qr_check_requires_a_key() {
    let (status, body) = get("/api/login/qr/check").await;
    assert_eq!(status, StatusCode::BAD_REQUEST);
    assert!(body["message"].as_str().unwrap().contains("key"));
}
