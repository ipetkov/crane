pub fn fun() {
    let msg = if cfg!(feature = "dev") { "dev" } else { "prod" };
    println!("{msg}");
}
