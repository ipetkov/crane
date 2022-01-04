fn main() {
    println!("hello");
    #[cfg(feature = "foo")]
    println!("foo");
    #[cfg(feature = "bar")]
    println!("bar");
}
