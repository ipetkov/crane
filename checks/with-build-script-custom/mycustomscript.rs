use std::{
    fs,
    io::{self, Write},
};

fn main() -> io::Result<()> {
    fs::create_dir_all("./target")?;
    fs::File::create("./target/mydata")?.write_all(b"hello world!\n")?;
    Ok(())
}
