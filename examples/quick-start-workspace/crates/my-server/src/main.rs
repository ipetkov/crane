//! An HTTP server which will echo back query params sent to /ping

use axum::{extract::Query, response::Html, routing::get, Router};
use std::collections::HashMap;

#[tokio::main]
async fn main() {
    let app = Router::new()
        .route("/", get(handler))
        .route("/ping", get(ping));

    let listener = tokio::net::TcpListener::bind("127.0.0.1:3000")
        .await
        .unwrap();
    println!("listening on {}", listener.local_addr().unwrap());
    axum::serve(listener, app).await.unwrap();
}

async fn handler() -> Html<&'static str> {
    Html("<h1>Hello, World!</h1>")
}

async fn ping(Query(params): Query<HashMap<String, String>>) -> Html<String> {
    let (tx, mut rx, fut) = my_common::echo_task(10, "ping".into());
    tokio::spawn(fut);
    tokio::spawn(async move {
        for (k, v) in params {
            if tx.send(format!("{k}: {v}").into()).await.is_err() {
                break;
            }
        }
    });

    let mut body = String::from("<pre>");

    while let Some(msg) = rx.recv().await {
        body.push_str(&msg);
    }

    body.push_str("</pre>");
    Html(body)
}
