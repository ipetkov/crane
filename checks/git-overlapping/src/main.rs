use std::any::TypeId;

fn main() {
    println!("{:?}", TypeId::of::<futures_io::Error>());
    println!("{:?}", TypeId::of::<dyn futures_sink::Sink<(), Error = ()>>());
}
