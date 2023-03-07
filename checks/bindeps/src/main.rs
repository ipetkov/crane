#![cfg_attr(target_os = "none", no_std)]
#![cfg_attr(target_os = "none", no_main)]

#[cfg_attr(target_os = "none", panic_handler)]
fn panic(_info: &::core::panic::PanicInfo<'_>) -> ! {
    loop {}
}

pub fn main() {
    let _ = env!("CARGO_BIN_FILE_FOO");
    let _ = env!("CARGO_CDYLIB_FILE_FOO");
    let _ = env!("CARGO_STATICLIB_FILE_FOO");
}
