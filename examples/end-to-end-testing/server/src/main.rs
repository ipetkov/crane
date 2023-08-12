use std::collections::HashMap;

use axum::{extract::Query, response::Html, routing::get, Extension, Router};

async fn home(Extension(pool): Extension<sqlx::PgPool>) -> Html<String> {
    let users: Vec<(String,)> = sqlx::query_as("SELECT name FROM users")
        .fetch_all(&pool)
        .await
        .unwrap();

    let users_names: String = users
        .into_iter()
        .map(|u| format!("<li>{}</li>", u.0))
        .collect();

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
        .bind(&username)
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
    axum::Server::bind(&addr.parse().unwrap())
        .serve(app.into_make_service())
        .await
        .unwrap();
}
