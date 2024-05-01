use std::{collections::HashMap, fmt::Write};

use axum::{extract::Query, response::Html, routing::get, Extension, Router};

async fn home(Extension(pool): Extension<sqlx::PgPool>) -> Html<String> {
    let users: Vec<(String,)> = sqlx::query_as("SELECT name FROM users")
        .fetch_all(&pool)
        .await
        .unwrap();

    let cap = users.len() * 9;
    let users_names = users
        .into_iter()
        .fold(String::with_capacity(cap), |mut s, (u,)| {
            let _ = write!(s, "<li>{u}</li>");
            s
        });

    Html(format!(
        r#"
        <form action="user">
            <label for="username">Your name: </label>
            <input id="username" name="username" />
            <button type="submit">Submit</button>
        </form>

        <ul>{users_names}</ul>
        "#,
    ))
}

async fn user(
    Query(query): Query<HashMap<String, String>>,
    Extension(pool): Extension<sqlx::PgPool>,
) -> Html<String> {
    let username = query.get("username").unwrap();

    sqlx::query("INSERT INTO users(name) VALUES ($1)")
        .bind(username)
        .execute(&pool)
        .await
        .unwrap();

    Html(format!("<h1>Hello {username}</h1>"))
}

#[tokio::main]
async fn main() {
    let db_url = std::env::var("DATABASE_URL").unwrap();
    let pool = sqlx::postgres::PgPool::connect(&db_url).await.unwrap();

    let app = Router::new()
        .route("/", get(home))
        .route("/user", get(user))
        .layer(Extension(pool));

    let addr = "0.0.0.0:8000";
    eprintln!("Listening on {addr}");
    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
