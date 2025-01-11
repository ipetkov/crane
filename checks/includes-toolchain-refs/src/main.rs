use std::cell::Cell;

// the stdlib thread local includes a panic message. After Rust 1.83.0, this panic message includes
// the full path to the stdlib if the toolchain has access to the Rust src. Nix takes the full path
// to mean that the rust toolchain should be added to the runtime closure. We can test this
// behaviour with  the below
thread_local! {
    pub static FOO: Cell<u32> = Cell::new(1);
}

fn main() {
    println!("val: {}", FOO.get());
}
