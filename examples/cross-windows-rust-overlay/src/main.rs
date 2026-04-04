use std::thread;

fn main() {
    thread::spawn(move || {
        println!("hello world");
    });
}

#[test]
fn it_works() {
    assert_eq!(2, 1 + 1);
}
