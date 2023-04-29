use serde::{Deserialize, Serialize};

#[derive(Debug, PartialEq, Serialize, Deserialize)]
pub struct Post {
    pub title: String,
    pub text: String,
    pub author_name: String,
}
