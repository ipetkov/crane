use std::cell::Cell;

thread_local! {
    pub static FOO: Cell<u32> = Cell::new(1);
}

fn main() {
    println!("val: {}", FOO.get());
}
