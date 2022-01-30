fn main() {
    println!("LittleEndian: {:?}", std::any::TypeId::of::<byteorder::LittleEndian>());
}
