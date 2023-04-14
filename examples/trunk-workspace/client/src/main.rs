use gloo::net;
use yew::prelude::*;

use shared::Post;

async fn request_posts() -> Vec<Post> {
    net::http::Request::get("http://localhost:8000/posts")
        .send()
        .await
        .expect("Failed to connect with server, is it runnig at localhost:8000?")
        .json()
        .await
        .expect("Received invalid response from server")
}

struct AppStruct(Vec<Post>);

impl Component for AppStruct {
    type Message = Vec<Post>;
    type Properties = ();

    fn create(ctx: &Context<Self>) -> Self {
        ctx.link().send_future(request_posts());
        Self(Default::default())
    }

    fn update(&mut self, _ctx: &Context<Self>, msg: Self::Message) -> bool {
        self.0 = msg;
        true
    }

    fn view(&self, _ctx: &Context<Self>) -> Html {
        html! {
          <ul>
            {for self.0.iter().map(|post| html! {
              <li>
                {format!("{} by {}", post.title, post.author_name)}
              </li>
            })}
          </ul>
        }
    }
}

fn main() {
    yew::Renderer::<AppStruct>::new().render();
}
