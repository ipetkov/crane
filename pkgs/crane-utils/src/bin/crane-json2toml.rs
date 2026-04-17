use std::{
    error::Error,
    io::{stdin, stdout, BufReader, Write},
    mem,
};

fn main() -> Result<(), Box<dyn Error>> {
    let stdin = stdin();
    let value: serde_json::Value = serde_json::from_reader(BufReader::new(stdin.lock()))?;

    let out = toml::to_string_pretty(&value);
    mem::forget(value); // "Leak" memory, but avoid running destructors, we're about to exit anyway

    let out = out?;
    let ret = stdout().lock().write_all(out.as_bytes());
    mem::forget(out); // "Leak" memory, but avoid running destructors, we're about to exit anyway
    ret.map_err(Into::into)
}
