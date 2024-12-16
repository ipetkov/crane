#[rustversion::stable]
const CHANNEL: &str = "stable";
#[rustversion::nightly]
const CHANNEL: &str = "nightly";

fn main() {
    println!("{:?}", std::any::TypeId::of::<byteorder::LittleEndian>());
    println!("{:?}", std::any::TypeId::of::<libc::c_int>());
    println!("{}: {}", CHANNEL, num_cpus::get());
    crane_test_repo::print();
}
