#[rustversion::stable]
const CHANNEL: &str = "stable";
#[rustversion::nightly]
const CHANNEL: &str = "nightly";

fn main() {
    println!("{:?}", std::any::TypeId::of::<byteorder::LittleEndian>());
    println!("{}: {}", CHANNEL, num_cpus::get());
    crane_test_repo::print();
}
