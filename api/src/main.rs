//! sparkmusic-api — NetEase Cloud Music API in Rust.

use std::sync::Arc;

use anyhow::Context;
use sparkmusic_api::api::{AppState, router};
use sparkmusic_api::config::Config;
use sparkmusic_api::transport::Transport;
use tracing_subscriber::EnvFilter;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(
            EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("info")),
        )
        .init();

    let config = Config::from_env();
    let transport = Arc::new(Transport::new(config.clone()));
    let state = AppState {
        transport: transport.clone(),
    };

    let app = router(state);
    let listener = tokio::net::TcpListener::bind(&config.bind)
        .await
        .with_context(|| format!("cannot bind {}", config.bind))?;

    tracing::info!(
        bind = %config.bind,
        mode = %config.mode,
        routes = sparkmusic_api::catalog::Catalog::global().len(),
        "sparkmusic-api ready"
    );

    axum::serve(listener, app)
        .with_graceful_shutdown(shutdown_signal())
        .await
        .context("server error")?;
    Ok(())
}

async fn shutdown_signal() {
    let ctrl_c = async {
        tokio::signal::ctrl_c()
            .await
            .expect("failed to install Ctrl+C handler");
    };

    #[cfg(unix)]
    let terminate = async {
        tokio::signal::unix::signal(tokio::signal::unix::SignalKind::terminate())
            .expect("failed to install SIGTERM handler")
            .recv()
            .await;
    };

    #[cfg(not(unix))]
    let terminate = std::future::pending::<()>();

    tokio::select! {
        _ = ctrl_c => {},
        _ = terminate => {},
    }

    tracing::info!("shutting down");
}
