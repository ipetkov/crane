#![feature(no_core, lang_items)]
#[no_std]
#[no_core]
// #[no_gods]
// #[no_masters]

#[no_mangle]
extern "C" fn main(_: isize, _: *const *const u8) -> isize {
    0
}
