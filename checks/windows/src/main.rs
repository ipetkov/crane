
fn main() {
    use std::thread;

    thread::spawn(move || {
        println!("test");
    });
}
