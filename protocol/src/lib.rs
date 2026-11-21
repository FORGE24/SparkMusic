//! Protocol layer shared by the SparkMusic Rust crates.
//!
//! * [`crypto`] — eapi / weapi / linuxapi envelopes (AES-128, MD5, RSA)
//! * [`catalog`] — the 1,293-route catalog recovered from the 9.6.30 APK
//!
//! HTTP transports stay in the consuming crates: `core` uses blocking ureq,
//! `api` uses async reqwest, and neither belongs in a shared protocol crate.

pub mod catalog;
pub mod crypto;

pub use crypto::{CryptoError, CryptoResult};
