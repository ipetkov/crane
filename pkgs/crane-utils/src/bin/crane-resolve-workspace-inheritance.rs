use anyhow::Context;
use serde::Deserialize;
use std::{
    env,
    fs::File,
    io::{stdout, Read, Write},
    mem,
    path::Path,
    process::{Command, Stdio},
};
use toml::value::Table;

fn main() {
    let mut args = env::args();

    let _ = args.next(); // Skip our name

    let cargo_toml = args
        .next()
        .expect("please specify a path to a Cargo.toml file");
    let cargo_toml = Path::new(&cargo_toml);

    args.for_each(|arg| eprintln!("ignoring argument: {arg}"));

    env::set_current_dir(cargo_toml.parent().expect("can't cd into Cargo.toml dir"))
        .expect("can't cd into Cargo.toml dir");

    if let Err(err) = resolve_and_print_cargo_toml(cargo_toml) {
        eprintln!("ignoring error in resolving workspace inheritance: {err:?}");
    }
}

#[derive(Deserialize)]
struct CargoMetadata {
    workspace_root: String,
}

fn resolve_and_print_cargo_toml(cargo_toml: &Path) -> anyhow::Result<()> {
    let root_toml = Command::new("cargo")
        .arg("metadata")
        .arg("--no-deps")
        .arg("--format-version")
        .arg("1")
        .stdin(Stdio::null())
        .stdout(Stdio::piped())
        .stderr(Stdio::inherit())
        .output()
        .context("failed to get cargo metadata")
        .and_then(|output| {
            if output.status.success() {
                serde_json::from_slice::<CargoMetadata>(&output.stdout)
                    .map(|metadata| metadata.workspace_root)
                    .context("cannot parse Cargo.toml")
            } else {
                anyhow::bail!("`cargo metadata` failed")
            }
        })?;

    let root_toml = Path::new(&root_toml);
    if !root_toml.exists() {
        anyhow::bail!("cannot read workspace root Cargo.toml");
    }

    let mut cargo_toml = parse_toml(cargo_toml)?;
    merge(&mut cargo_toml, &parse_toml(&root_toml.join("Cargo.toml"))?);

    toml::to_string(&cargo_toml)
        .context("failed to serialize updated Cargo.toml")
        .and_then(|string| {
            stdout()
                .write_all(string.as_bytes())
                .context("failed to print updated Cargo.toml")
                .map(drop)
        })
}

fn parse_toml(path: &Path) -> anyhow::Result<toml::Value> {
    let mut buf = String::new();
    File::open(path)
        .and_then(|mut file| file.read_to_string(&mut buf))
        .with_context(|| format!("cannot read {}", path.display()))?;

    toml::from_str(&buf).with_context(|| format!("cannot parse {}", path.display()))
}

fn merge(cargo_toml: &mut toml::Value, root: &toml::Value) {
    let (t, rt) = match (cargo_toml, root) {
        (toml::Value::Table(t), toml::Value::Table(rt)) => (t, rt),

        // Bail if cargo_toml or workspace root are malformed
        _ => return,
    };

    let w = if let Some(toml::Value::Table(w)) = rt.get("workspace") {
        w
    } else {
        // no "workspace" entry, nothing to merge
        return;
    };

    // https://doc.rust-lang.org/cargo/reference/workspaces.html#workspaces
    for (key, ws_key) in [
        ("package", "package"),
        ("dependencies", "dependencies"),
        ("dev-dependencies", "dependencies"),
        ("build-dependencies", "dependencies"),
    ] {
        if let (Some(toml::Value::Table(p)), Some(toml::Value::Table(wp))) =
            (t.get_mut(key), w.get(ws_key))
        {
            merge_tables(p, wp);
        };

        if let Some(toml::Value::Table(targets)) = t.get_mut("target") {
            for (_, tp) in targets {
                if let (Some(toml::Value::Table(p)), Some(toml::Value::Table(wp))) =
                    (tp.get_mut(key), w.get(ws_key))
                {
                    merge_tables(p, wp);
                };
            }
        }
    }
}

fn merge_tables(cargo_toml: &mut Table, root: &Table) {
    cargo_toml.iter_mut().for_each(|(k, v)| {
        // Bail if:
        // - cargo_toml isn't a table (otherwise `workspace = true` can't show up
        // - the workspace root doesn't have this key
        let (t, root_val) = match (&mut *v, root.get(k)) {
            (toml::Value::Table(t), Some(root_val)) => (t, root_val),
            _ => return,
        };

        if let Some(toml::Value::Boolean(true)) = t.get("workspace") {
            t.remove("workspace");
            let orig_val = mem::replace(v, root_val.clone());
            merge_into(v, orig_val);
        }
    });
}

fn merge_into(dest: &mut toml::Value, additional: toml::Value) {
    match additional {
        toml::Value::String(_)
        | toml::Value::Integer(_)
        | toml::Value::Float(_)
        | toml::Value::Boolean(_)
        | toml::Value::Datetime(_) => {
            // Override dest completely for raw values
            *dest = additional;
        }

        toml::Value::Array(additional) => {
            if let toml::Value::Array(dest) = dest {
                dest.extend(additional);
            } else {
                // Override dest completely if types don't match
                *dest = toml::Value::Array(additional);
            }
        }

        toml::Value::Table(additional) => {
            if let toml::Value::Table(dest) = dest {
                additional
                    .into_iter()
                    .for_each(|(k, v)| match dest.get_mut(&k) {
                        Some(existing) => merge_into(existing, v),
                        None => {
                            dest.insert(k, v);
                        }
                    });
            } else {
                // Override dest completely if types don't match, but also
                // skip empty tables (i.e. if we had `key = { workspace = true }`
                if !additional.is_empty() {
                    *dest = toml::Value::Table(additional);
                }
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use pretty_assertions::assert_eq;

    #[test]
    fn smoke() {
        let mut cargo_toml = toml::from_str(
            r#"
            [package]
            authors.workspace = true
            categories.workspace = true
            description.workspace = true
            documentation.workspace = true
            edition.workspace = true
            exclude.workspace = true
            homepage.workspace = true
            include.workspace = true
            keyword.workspace = true
            license.workspace = true
            license-file.workspace = true
            publish.workspace = true
            readme.workspace = true
            repository.workspace = true
            rust-version.workspace = true
            version.workspace = true

            [dependencies]
            foo.workspace = true
            bar.workspace = true
            baz.workspace = true
            qux = { workspace = true, features = ["qux-additional"] }
            corge = { workspace = true, version = "corge-vers-override" }
            grault = { version = "grault-vers" }
            garply = "garply-vers"
            waldo = "waldo-vers"

            [target.'cfg(unix)'.dependencies]
            unix = { workspace = true, features = ["some"] }

            [dev-dependencies]
            foo.workspace = true
            bar.workspace = true
            baz.workspace = true
            qux = { workspace = true, features = ["qux-additional"] }
            corge = { workspace = true, version = "corge-vers-override" }
            grault = { version = "grault-vers" }
            garply = "garply-vers"
            waldo = "waldo-vers"

            [build-dependencies]
            foo.workspace = true
            bar.workspace = true
            baz.workspace = true
            qux = { workspace = true, features = ["qux-additional"] }
            corge = { workspace = true, version = "corge-vers-override" }
            grault = { version = "grault-vers" }
            garply = "garply-vers"
            waldo = "waldo-vers"
        "#,
        )
        .unwrap();

        let root_toml = toml::from_str(
            r#"
            [workspace.package]
            authors = ["first author", "second author"]
            categories = ["first category", "second category" ]
            description = "some description"
            documentation = "some doc url"
            edition = "2021"
            exclude = ["first exclusion", "second exclusion"]
            homepage = "some home page"
            include = ["first inclusion", "second inclusion"]
            keyword = ["first keyword", "second keyword"]
            license = "some license"
            license-file = "some license-file"
            publish = true
            readme = "some readme"
            repository = "some repository"
            rust-version = "some rust-version"
            version = "some version"

            [workspace.dependencies]
            foo = { version = "foo-vers" }
            bar = { version = "bar-vers", default-features = false }
            baz = { version = "baz-vers", features = ["baz-feat", "baz-feat2"] }
            qux = { version = "qux-vers", features = ["qux-feat"] }
            corge = { version = "corge-vers", features = ["qux-feat"] }
            garply = "garply-workspace-vers"
            waldo = { version = "waldo-workspace-vers" }
            unix = { version = "unix-vers" }

        "#,
        )
        .unwrap();

        let expected_toml = toml::from_str::<toml::Value>(
            r#"
            [package]
            authors = ["first author", "second author"]
            categories = ["first category", "second category" ]
            description = "some description"
            documentation = "some doc url"
            edition = "2021"
            exclude = ["first exclusion", "second exclusion"]
            homepage = "some home page"
            include = ["first inclusion", "second inclusion"]
            keyword = ["first keyword", "second keyword"]
            license = "some license"
            license-file = "some license-file"
            publish = true
            readme = "some readme"
            repository = "some repository"
            rust-version = "some rust-version"
            version = "some version"

            [dependencies]
            foo = { version = "foo-vers" }
            bar = { version = "bar-vers", default-features = false }
            baz = { version = "baz-vers", features = ["baz-feat", "baz-feat2"] }
            qux = { version = "qux-vers", features = ["qux-feat", "qux-additional"] }
            corge = { version = "corge-vers-override", features = ["qux-feat"] }
            grault = { version = "grault-vers" }
            garply = "garply-vers"
            waldo = "waldo-vers"

            [target.'cfg(unix)'.dependencies]
            unix = { version = "unix-vers", features = ["some"] }

            [dev-dependencies]
            foo = { version = "foo-vers" }
            bar = { version = "bar-vers", default-features = false }
            baz = { version = "baz-vers", features = ["baz-feat", "baz-feat2"] }
            qux = { version = "qux-vers", features = ["qux-feat", "qux-additional"] }
            corge = { version = "corge-vers-override", features = ["qux-feat"] }
            grault = { version = "grault-vers" }
            garply = "garply-vers"
            waldo = "waldo-vers"

            [build-dependencies]
            foo = { version = "foo-vers" }
            bar = { version = "bar-vers", default-features = false }
            baz = { version = "baz-vers", features = ["baz-feat", "baz-feat2"] }
            qux = { version = "qux-vers", features = ["qux-feat", "qux-additional"] }
            corge = { version = "corge-vers-override", features = ["qux-feat"] }
            grault = { version = "grault-vers" }
            garply = "garply-vers"
            waldo = "waldo-vers"
        "#,
        )
        .unwrap();

        super::merge(&mut cargo_toml, &root_toml);

        assert_eq!(expected_toml, cargo_toml);
    }
}
