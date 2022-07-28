use axum::{http::StatusCode, response::IntoResponse, Json};
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize)]
pub struct Post {
    id: usize,
    title: String,
    body: String,
}

#[derive(Serialize, Deserialize)]
pub struct CreatePost {
    title: String,
    body: String,
}

pub async fn create_post(Json(payload): Json<CreatePost>) -> impl IntoResponse {
    let post = Post {
        id: 1,
        title: payload.title,
        body: payload.body,
    };

    (StatusCode::CREATED, Json(post))
}
