#[test]
fn some_unique_some_overlap() {
    let fa = foo::byteorder_141();
    let fb = foo::byteorder_142();
    let fc = foo::byteorder_143();

    let ba = bar::byteorder_141();
    let bb = bar::byteorder_142();
    let bc = bar::byteorder_143();

    assert_eq!(fa, ba);
    assert_ne!(fb, bb);
    assert_eq!(fc, bc);
}
