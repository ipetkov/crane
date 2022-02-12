use std::any::TypeId;

pub fn byteorder_141() -> TypeId {
    std::any::TypeId::of::<byteorder_141::LittleEndian>()
}

pub fn byteorder_142() -> TypeId {
    std::any::TypeId::of::<byteorder_142::LittleEndian>()
}

pub fn byteorder_143() -> TypeId {
    std::any::TypeId::of::<byteorder_143::LittleEndian>()
}

#[test]
fn all_unique() {
    let a = byteorder_141();
    let b = byteorder_142();
    let c = byteorder_143();
    assert_ne!(a, b);
    assert_ne!(b, c);
    assert_ne!(a, c);
}
