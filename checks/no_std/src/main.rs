#![cfg_attr(target_os = "none", no_std)]
#![cfg_attr(target_os = "none", no_main)]
#![allow(dead_code)]

#[cfg_attr(target_os = "none", panic_handler)]
fn panic(_info: &::core::panic::PanicInfo<'_>) -> ! {
    loop {}
}

pub fn main() {
    assert_eq!(u8::from(dep::FortyTwo::new()), 42);
}
