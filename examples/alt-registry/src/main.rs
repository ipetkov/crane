use std::any::TypeId;

fn main() {
    let le = TypeId::of::<byteorder::LittleEndian>();
    let krate = TypeId::of::<registry_conformance::CreatedCrate>();

    println!("TypeId of byteorder::LittleEndian (from crates.io): {:?}", le);
    println!("TypeId of epitech_api::Client (from alexandrie): {:?}", krate);
}
