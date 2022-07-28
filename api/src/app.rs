use api::{posts::create_post, root};
use axum::{
    routing::{get, post},
    Router,
};
use std::net::SocketAddr;
use tracing::info;

pub async fn run_app(addr: SocketAddr) {
    let app = Router::new()
        .route("/", get(root))
        .route("/posts", post(create_post));

    info!("listening on {}", addr);
    axum::Server::bind(&addr)
        .serve(app.into_make_service())
        .await
        .unwrap();
}
