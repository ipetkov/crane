#[no_mangle]
pub fn bar(a: i32) -> i32 {
    some_dep::foo(a) * a
}
