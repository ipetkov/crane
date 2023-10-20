fn main() {
    println!("Hello, world!");
}

#[test]
fn first() {
    assert_eq!(1 + 1, 2);
}

#[test]
fn second() {
    assert_eq!(84 / 2, 42);
}

#[test]
fn third() {
    assert_eq!(5 * 5, 25);
}

#[test]
fn fourth() {
    assert_eq!(81 / 3, 27);
}
