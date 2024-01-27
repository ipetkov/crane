#![allow(dead_code)]
#![cfg_attr(any(target_os = "none", target_os = "uefi"), no_std)]
#![cfg_attr(any(target_os = "none", target_os = "uefi"), no_main)]

#[allow(unused_extern_crates)]
extern crate core;

#[cfg_attr(any(target_os = "none", target_os = "uefi"), panic_handler)]
fn panic(_info: &::core::panic::PanicInfo<'_>) -> ! {
    loop {}
}

pub fn main() {}
