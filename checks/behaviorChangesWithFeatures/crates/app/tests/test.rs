#[test]
fn some_test() {
    assert!(std::env!("CARGO_BIN_EXE_app").ends_with("app"));
}
