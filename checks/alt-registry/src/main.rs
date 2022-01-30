use std::any::TypeId;

fn main() {
    println!("byteorder::LittleEndian: {:?}", TypeId::of::<byteorder::LittleEndian>());
    println!("epitech_api::Client: {:?}", TypeId::of::<epitech_api::Client>());
}
