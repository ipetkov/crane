use axum::{routing::get, Json, Router};

use shared::Post;
use tower_http::{cors::CorsLayer, services::ServeDir};

async fn list_posts() -> Json<Vec<Post>> {
    Json(vec![
        Post {
            title: "How to use yew???????".to_string(),
            text: "...".to_string(),
            author_name: "Jane Doe".to_string(),
        },
        Post {
            title: "How to use axum???????".to_string(),
            text: "...".to_string(),
            author_name: "Jonh Doe".to_string(),
        },
    ])
}

#[tokio::main]
async fn main() {
    let app = Router::new()
        .nest_service("/", ServeDir::new(env!("CLIENT_DIST")))
        .route("/posts", get(list_posts))
        .layer(CorsLayer::permissive());

    let addr = "0.0.0.0:8000";
    eprintln!("Listening on {addr}");
    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
