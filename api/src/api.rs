//! Axum router and handlers.
//!
//! Three layers of surface:
//!
//! * discovery — `/health`, `/routes`, `/routes/{*route}`
//! * generic proxy — `POST /call/{*route}` for any of the 1,293 routes
//! * typed endpoints — search, songs, lyrics, playlists, albums, artists,
//!   comments and QR/cookie login

use std::sync::Arc;

use axum::extract::{Path, Query, State};
use axum::routing::{get, post};
use axum::{Json, Router};
use serde::Deserialize;
use serde_json::{Map, Value};
use tower_http::cors::{Any, CorsLayer};
use tower_http::trace::TraceLayer;

use crate::catalog::Catalog;
use crate::config::APP_VERSION;
use crate::error::{Error, Result};
use crate::transport::Transport;

#[derive(Clone)]
pub struct AppState {
    pub transport: Arc<Transport>,
}

pub fn router(state: AppState) -> Router {
    Router::new()
        .route("/", get(index))
        .route("/health", get(health))
        .route("/routes", get(list_routes))
        .route("/routes/{*route}", get(route_info))
        .route("/call/{*route}", post(call_route))
        .route("/api/search", get(search))
        .route("/api/song/url", get(song_url))
        .route("/api/song/{id}", get(song_detail))
        .route("/api/song/{id}/lyric", get(lyric))
        .route("/api/song/{id}/comments", get(song_comments))
        .route("/api/playlist/{id}", get(playlist_detail))
        .route("/api/album/{id}", get(album_detail))
        .route("/api/artist/{id}", get(artist_detail))
        .route("/api/login/qr/key", get(qr_key))
        .route("/api/login/qr/create", get(qr_create))
        .route("/api/login/qr/check", get(qr_check))
        .route("/api/login/cookie", post(login_cookie))
        .layer(TraceLayer::new_for_http())
        .layer(
            CorsLayer::new()
                .allow_origin(Any)
                .allow_methods(Any)
                .allow_headers(Any),
        )
        .with_state(state)
}

async fn index() -> Json<Value> {
    Json(serde_json::json!({
        "service": "sparkmusic-api",
        "app_version": APP_VERSION,
        "endpoints": [
            "GET  /health",
            "GET  /routes?q=&group=&limit=&offset=",
            "GET  /routes/{route}",
            "POST /call/{route}",
            "GET  /api/search?keywords=",
            "GET  /api/song/{id}",
            "GET  /api/song/url?ids=",
            "GET  /api/song/{id}/lyric",
            "GET  /api/song/{id}/comments",
            "GET  /api/playlist/{id}",
            "GET  /api/album/{id}",
            "GET  /api/artist/{id}",
            "GET  /api/login/qr/key",
            "GET  /api/login/qr/create?key=",
            "GET  /api/login/qr/check?key=",
            "POST /api/login/cookie",
        ],
    }))
}

// ------------------------------------------------------------------ discovery

async fn health() -> Json<Value> {
    let catalog = Catalog::global();
    Json(serde_json::json!({
        "status": "ok",
        "app_version": APP_VERSION,
        "routes": catalog.len(),
        "groups": catalog.group_count(),
    }))
}

#[derive(Debug, Deserialize)]
struct ListQuery {
    q: Option<String>,
    group: Option<String>,
    limit: Option<usize>,
    offset: Option<usize>,
}

async fn list_routes(Query(query): Query<ListQuery>) -> Json<Value> {
    let catalog = Catalog::global();
    let matched = catalog.find(query.q.as_deref().unwrap_or(""), query.group.as_deref());
    let total = matched.len();
    let offset = query.offset.unwrap_or(0).min(total);
    let limit = query.limit.unwrap_or(100).min(1000);
    let items: Vec<Value> = matched
        .iter()
        .skip(offset)
        .take(limit)
        .map(|route| serde_json::to_value(route).unwrap_or(Value::Null))
        .collect();
    Json(serde_json::json!({
        "total": total,
        "offset": offset,
        "limit": limit,
        "groups": catalog.group_count(),
        "routes": items,
    }))
}

async fn route_info(Path(route): Path<String>) -> Result<Json<Value>> {
    let catalog = Catalog::global();
    let normalized = route.trim_start_matches('/');
    match catalog.get(normalized) {
        Some(info) => Ok(Json(serde_json::to_value(info).unwrap_or(Value::Null))),
        None => Err(Error::UnknownRoute(normalized.to_string())),
    }
}

#[derive(Debug, Deserialize)]
struct CallQuery {
    mode: Option<String>,
}

/// Generic proxy: `POST /call/song/detail` with a JSON object of parameters.
async fn call_route(
    State(state): State<AppState>,
    Path(route): Path<String>,
    Query(query): Query<CallQuery>,
    body: Option<Json<Value>>,
) -> Result<Json<Value>> {
    let route = route.trim_start_matches('/').to_string();
    let params = match body {
        None => Map::new(),
        Some(Json(Value::Object(map))) => map,
        Some(Json(_)) => return Err(Error::BadRequest("body must be a JSON object".into())),
    };
    let data = state
        .transport
        .call_with_mode(&route, &params, query.mode.as_deref())
        .await?;
    Ok(Json(data))
}

// ---------------------------------------------------------------------- typed

#[derive(Debug, Deserialize)]
struct SearchQuery {
    keywords: Option<String>,
    s: Option<String>,
    limit: Option<u32>,
    offset: Option<u32>,
    #[serde(rename = "type")]
    kind: Option<u32>,
}

async fn search(
    State(state): State<AppState>,
    Query(query): Query<SearchQuery>,
) -> Result<Json<Value>> {
    let keyword = query
        .keywords
        .or(query.s)
        .filter(|k| !k.trim().is_empty())
        .ok_or_else(|| Error::BadRequest("keywords is required".into()))?;

    let mut params = Map::new();
    params.insert("s".into(), Value::String(keyword.clone()));
    params.insert("keyword".into(), Value::String(keyword));
    params.insert("type".into(), Value::from(query.kind.unwrap_or(1)));
    params.insert("limit".into(), Value::from(query.limit.unwrap_or(30)));
    params.insert("offset".into(), Value::from(query.offset.unwrap_or(0)));
    params.insert("total".into(), Value::Bool(true));

    let data = state.transport.call("v1/search/get", &params).await?;
    Ok(Json(data))
}

#[derive(Debug, Deserialize)]
struct DetailQuery {
    level: Option<String>,
}

async fn song_detail(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Query(query): Query<DetailQuery>,
) -> Result<Json<Value>> {
    let mut params = Map::new();
    params.insert("id".into(), Value::String(id.clone()));
    params.insert("c".into(), Value::String(format!("[{{\"id\":{}}}]", id_value(&id))));
    params.insert("v".into(), Value::from(1));
    params.insert("rv".into(), Value::from(1));
    params.insert(
        "level".into(),
        Value::String(query.level.unwrap_or_else(|| "exhigh".into())),
    );
    let data = state.transport.call("v3/song/detail", &params).await?;
    Ok(Json(data))
}

#[derive(Debug, Deserialize)]
struct UrlQuery {
    ids: Option<String>,
    id: Option<String>,
    level: Option<String>,
    #[serde(rename = "encodeType")]
    encode_type: Option<String>,
}

async fn song_url(
    State(state): State<AppState>,
    Query(query): Query<UrlQuery>,
) -> Result<Json<Value>> {
    let ids = query
        .ids
        .or(query.id)
        .filter(|v| !v.trim().is_empty())
        .ok_or_else(|| Error::BadRequest("ids is required, e.g. ?ids=347230".into()))?;
    let ids = ids_json(&ids);

    let mut params = Map::new();
    params.insert("ids".into(), Value::String(ids));
    params.insert(
        "level".into(),
        Value::String(query.level.unwrap_or_else(|| "exhigh".into())),
    );
    params.insert(
        "encodeType".into(),
        Value::String(query.encode_type.unwrap_or_else(|| "flac".into())),
    );

    let data = state
        .transport
        .call("song/enhance/player/url/v1", &params)
        .await?;
    Ok(Json(data))
}

async fn lyric(State(state): State<AppState>, Path(id): Path<String>) -> Result<Json<Value>> {
    let mut params = Map::new();
    params.insert("id".into(), Value::String(id));
    params.insert("cp".into(), Value::Bool(false));
    params.insert("lv".into(), Value::from(-1));
    params.insert("tv".into(), Value::from(-1));
    params.insert("rv".into(), Value::from(-1));
    params.insert("kv".into(), Value::from(-1));
    let data = state.transport.call("song/lyric/v1", &params).await?;
    Ok(Json(data))
}

#[derive(Debug, Deserialize)]
struct PageQuery {
    limit: Option<u32>,
    offset: Option<u32>,
}

async fn song_comments(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Query(query): Query<PageQuery>,
) -> Result<Json<Value>> {
    let mut params = Map::new();
    params.insert("threadId".into(), Value::String(format!("R_SO_4_{id}")));
    params.insert("resourceId".into(), Value::from(id_value(&id)));
    params.insert("resourceType".into(), Value::from(4));
    params.insert("limit".into(), Value::from(query.limit.unwrap_or(20)));
    params.insert("offset".into(), Value::from(query.offset.unwrap_or(0)));
    let data = state.transport.call("v1/resource/comments", &params).await?;
    Ok(Json(data))
}

async fn playlist_detail(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Query(query): Query<PageQuery>,
) -> Result<Json<Value>> {
    let mut params = Map::new();
    params.insert("id".into(), Value::String(id));
    params.insert("n".into(), Value::from(query.limit.unwrap_or(1000)));
    params.insert("s".into(), Value::from(query.offset.unwrap_or(0)));
    params.insert("v".into(), Value::from(1));
    let data = state.transport.call("v6/playlist/detail", &params).await?;
    Ok(Json(data))
}

async fn album_detail(State(state): State<AppState>, Path(id): Path<String>) -> Result<Json<Value>> {
    let route = format!("album/{id}");
    let data = state.transport.call(&route, &Map::new()).await?;
    Ok(Json(data))
}

async fn artist_detail(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> Result<Json<Value>> {
    let mut params = Map::new();
    params.insert("artistId".into(), Value::from(id_value(&id)));
    let data = state
        .transport
        .call("artist/detail/dynamic/v2", &params)
        .await?;
    Ok(Json(data))
}

// ---------------------------------------------------------------------- login

async fn qr_key(State(state): State<AppState>) -> Result<Json<Value>> {
    let mut params = Map::new();
    params.insert("type".into(), Value::from(1));
    let data = state
        .transport
        .call_with_mode("login/qrcode/unikey", &params, Some("weapi"))
        .await?;
    Ok(Json(data))
}

#[derive(Debug, Deserialize)]
struct KeyQuery {
    key: Option<String>,
}

async fn qr_create(
    State(state): State<AppState>,
    Query(query): Query<KeyQuery>,
) -> Result<Json<Value>> {
    qr_client_login(state, query.key, "qr create").await
}

async fn qr_check(
    State(state): State<AppState>,
    Query(query): Query<KeyQuery>,
) -> Result<Json<Value>> {
    qr_client_login(state, query.key, "qr check").await
}

async fn qr_client_login(
    state: AppState,
    key: Option<String>,
    what: &str,
) -> Result<Json<Value>> {
    let key = key
        .filter(|k| !k.trim().is_empty())
        .ok_or_else(|| Error::BadRequest(format!("key is required for {what}")))?;
    let mut params = Map::new();
    params.insert("key".into(), Value::String(key));
    params.insert("type".into(), Value::from(1));
    let data = state
        .transport
        .call_with_mode("login/qrcode/client/login", &params, Some("weapi"))
        .await?;
    Ok(Json(data))
}

#[derive(Debug, Deserialize)]
struct CookieBody {
    cookie: String,
}

/// Store a session cookie and confirm it with the account endpoint.
///
/// The cookie is never echoed back — only the resulting account/profile.
async fn login_cookie(
    State(state): State<AppState>,
    Json(body): Json<CookieBody>,
) -> Result<Json<Value>> {
    if body.cookie.trim().is_empty() {
        return Err(Error::BadRequest("cookie must not be empty".into()));
    }
    state.transport.set_cookie(&body.cookie);
    let account = state
        .transport
        .call_with_mode("nuser/account/get", &Map::new(), Some("api"))
        .await?;
    let cookies = state.transport.cookies().len();
    Ok(Json(serde_json::json!({
        "cookies": cookies,
        "account": account,
    })))
}

// -------------------------------------------------------------------- helpers

fn id_value(id: &str) -> Value {
    match id.parse::<u64>() {
        Ok(number) => Value::from(number),
        Err(_) => Value::String(id.to_string()),
    }
}

/// `"347230,347231"` -> `"[347230,347231]"`, matching the app's JSON-array form.
fn ids_json(ids: &str) -> String {
    let items: Vec<String> = ids
        .split(',')
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .map(|s| id_value(s).to_string())
        .collect();
    format!("[{}]", items.join(","))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn ids_become_a_json_array() {
        assert_eq!(ids_json("347230"), "[347230]");
        assert_eq!(ids_json("347230, 347231"), "[347230,347231]");
        assert_eq!(ids_json("abc"), "[\"abc\"]");
    }

    #[test]
    fn ids_value_keeps_large_numbers_exact() {
        assert_eq!(id_value("347230").to_string(), "347230");
        assert_eq!(id_value("not-a-number").to_string(), "\"not-a-number\"");
    }
}
