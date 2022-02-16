fn main() {
    // Pretend to use openssl here
    println!("{:?}", std::any::TypeId::of::<openssl_sys::SHA_LONG>());
}

#[test]
fn it_works() {
    assert_eq!(2, 1 + 1);
}
