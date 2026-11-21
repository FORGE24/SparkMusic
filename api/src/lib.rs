//! Rust reimplementation of the recovered NetEase Cloud Music API.
//!
//! The crate is split so the pieces can be tested without a server:
//!
//! * [`crypto`] — eapi / weapi / linuxapi envelopes (AES-128, MD5, RSA)
//! * [`transport`] — HTTP client, payload building, cookies, retries
//! * [`catalog`] — the 1,293-route catalog recovered from the 9.6.30 APK
//! * [`api`] — the Axum router and handlers
//! * [`config`] / [`error`] — runtime configuration and error mapping

pub mod api;
pub mod catalog;
pub mod config;
pub mod crypto;
pub mod error;
pub mod transport;
