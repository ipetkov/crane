#![allow(clippy::all)]
#![allow(dead_code)]
#![cfg_attr(any(target_os = "none", target_os = "uefi", target_arch = "amdgpu"), no_std)]
#![cfg_attr(any(target_os = "none", target_os = "uefi", target_arch = "amdgpu"), no_main)]

#[allow(unused_extern_crates)]
extern crate core;

#[cfg_attr(any(target_os = "none", target_os = "uefi", target_arch = "amdgpu"), panic_handler)]
fn panic(_info: &::core::panic::PanicInfo<'_>) -> ! {
    loop {}
}

pub fn main() {}
