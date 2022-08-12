#[tokio::main(flavor = "current_thread")]
async fn main() {
    println!("{:?}", std::any::TypeId::of::<tokio_util::sync::DropGuard>());
}
