use std::any::TypeId;

fn main() {
    println!("{:?}", TypeId::of::<tokio::io::ReadBuf>());
    println!("{:?}", TypeId::of::<tokio_util::either::Either<(), ()>>());
}
