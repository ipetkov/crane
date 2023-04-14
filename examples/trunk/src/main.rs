use yew::prelude::*;

#[function_component]
fn App() -> Html {
    html! {
      <h1>
        {"Hello world!"}
      </h1>
    }
}

fn main() {
    yew::Renderer::<App>::new().render();
}
