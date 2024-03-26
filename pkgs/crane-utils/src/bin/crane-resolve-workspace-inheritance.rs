use anyhow::Context;
use serde::Deserialize;
use std::{
    env,
    fs::File,
    io::{stdout, Read, Write},
    mem,
    path::Path,
    process::{Command, Stdio},
    str::FromStr,
};
use toml::{Table, Value};

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

    stdout()
        .write_all(
            toml::to_string(&cargo_toml)
                .expect("can't serialize toml::Value")
                .as_bytes(),
        )
        .context("failed to print updated Cargo.toml")
}

fn parse_toml(path: &Path) -> anyhow::Result<Value> {
    let mut buf = String::new();
    File::open(path)
        .and_then(|mut file| file.read_to_string(&mut buf))
        .with_context(|| format!("cannot read {}", path.display()))?;

    Value::from_str(&buf).with_context(|| format!("cannot parse {}", path.display()))
}

/// Merge the workspace `root` toml into the specified crate's `cargo_toml`
fn merge(cargo_toml: &mut Value, root: &Value) {
    let Some(Value::Table(w)) = root.get("workspace") else {
        // no "workspace" entry, nothing to merge
        return;
    };

    // https://doc.rust-lang.org/cargo/reference/workspaces.html#workspaces
    let w_deps = w.get("dependencies");
    for key in ["dependencies", "dev-dependencies", "build-dependencies"] {
        if let Some((cargo_toml, root)) = cargo_toml.get_mut(key).zip(w_deps) {
            try_merge_dependencies_tables(cargo_toml, root);
        };

        if let Some(Value::Table(targets)) = cargo_toml.get_mut("target") {
            for (_, tp) in targets.iter_mut() {
                if let Some((cargo_toml, root)) = tp.get_mut(key).zip(w_deps) {
                    try_merge_dependencies_tables(cargo_toml, root);
                }
            }
        }
    }

    if let Some((cargo_toml, root)) = cargo_toml.get_mut("package").zip(w.get("package")) {
        try_merge_cargo_tables(cargo_toml, root);
    };

    if let Some((cargo_toml, root)) = cargo_toml.get_mut("lints").zip(w.get("lints")) {
        try_inherit_cargo_table(cargo_toml, root);
    };
}

/// Inherit the specified `cargo_toml` from workspace `root` if the former is a table
fn try_inherit_cargo_table(cargo_toml: &mut Value, root: &Value) {
    let Value::Table(t) = cargo_toml else {
        return;
    };
    if t.get("workspace")
        .and_then(Value::as_bool)
        .unwrap_or_default()
    {
        t.remove("workspace");
        let orig_val = mem::replace(cargo_toml, root.clone());
        merge_items(cargo_toml, &orig_val);
    }
}

/// Merge the specified `cargo_toml` and workspace `root` if both are tables
fn try_merge_cargo_tables(cargo_toml: &mut Value, root: &Value) {
    let Some(cargo_toml) = cargo_toml.as_table_mut() else {
        return;
    };
    let Some(root) = root.as_table() else {
        return;
    };

    merge_cargo_tables(cargo_toml, root);
}
/// Merge the specified `cargo_toml` and workspace `root` tables
fn merge_cargo_tables(cargo_toml: &mut Table, root: &Table) {
    cargo_toml.iter_mut().for_each(|(k, v)| {
        // Bail if:
        // - cargo_toml isn't a table (otherwise `workspace = true` can't show up
        // - the workspace root doesn't have this key
        let (t, root_val) = match v.as_table_mut().zip(root.get(k)) {
            Some((t, root_val)) => (t, root_val),
            _ => return,
        };

        if let Some(Value::Boolean(bool_value)) = t.get("workspace") {
            if *bool_value {
                t.remove("workspace");
                let orig_val = mem::replace(v, root_val.clone());
                merge_items(v, &orig_val);
            }
        }
    });
}

/// Merge the specified `cargo_toml` and workspace `root` if both are dependency tables
fn try_merge_dependencies_tables(cargo_toml: &mut Value, root: &Value) {
    let Some(cargo_toml) = cargo_toml.as_table_mut() else {
        return;
    };
    let Some(root) = root.as_table() else {
        return;
    };

    merge_dependencies_tables(cargo_toml, root);
}

/// Merge the specified `cargo_toml` and workspace `root` dependencies tables
fn merge_dependencies_tables(cargo_toml: &mut Table, root: &Table) {
    cargo_toml.iter_mut().for_each(|(k, v)| {
        // Bail if:
        // - cargo_toml isn't a table (otherwise `workspace = true` can't show up
        // - the workspace root doesn't have this key
        let (t, root_val) = match v.as_table_mut().zip(root.get(k)) {
            Some((t, root_val)) => (t, root_val),
            _ => return,
        };

        if let Some(Value::Boolean(bool_value)) = t.get("workspace") {
            if *bool_value {
                t.remove("workspace");
                let orig_val = mem::replace(
                    v,
                    match root_val.clone() {
                        s @ Value::String(_) => {
                            let mut table = Table::new();
                            table.insert("version".to_string(), s);
                            Value::Table(table)
                        }
                        v => v,
                    },
                );

                merge_items(v, &orig_val);
            }
        }
    });
}

/// Recursively merge the `additional` item into the specified `dest`
fn merge_items(dest: &mut Value, additional: &Value) {
    match additional {
        Value::String(_)
        | Value::Integer(_)
        | Value::Float(_)
        | Value::Boolean(_)
        | Value::Datetime(_) => {
            // Override dest completely for raw values
            *dest = additional.clone();
        }

        Value::Array(additional) => {
            if let Value::Array(dest) = dest {
                dest.extend(additional.clone());
            } else {
                // Override dest completely if types don't match
                *dest = Value::Array(additional.clone());
            }
        }
        Value::Table(additional) => {
            merge_tables(dest, additional);
        }
    }
}

fn merge_tables(dest: &mut Value, additional: &Table) {
    if let Some(dest) = dest.as_table_mut() {
        additional
            .into_iter()
            .for_each(|(k, v)| match dest.get_mut(k) {
                Some(existing) => merge_items(existing, v),
                None => {
                    dest.insert(k.to_string(), v.clone());
                }
            });
    } else if !additional.is_empty() {
        *dest = Value::Table(additional.clone());
    }
}

#[cfg(test)]
mod tests {
    use pretty_assertions::assert_eq;
    use std::str::FromStr;

    #[test]
    fn smoke() {
        let mut cargo_toml = toml::Value::from_str(
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
            fred.workspace = true
            plugh = { workspace = true, optional = true }

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

            [features]
            my_feature = []

            [lints]
            workspace = true
        "#,
        )
        .unwrap();

        let root_toml = toml::Value::from_str(
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
            fred = "0.1.3"
            plugh = "0.2.4"

            [workspace.lints.rust]
            unused_extern_crates = 'warn'

            [workspace.lints.clippy]
            all = 'allow'
        "#,
        )
        .unwrap();

        let expected_toml = toml::Value::from_str(
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
            qux = { version = "qux-vers", features = ["qux-feat","qux-additional"] }
            corge = { version = "corge-vers-override" , features = ["qux-feat"] }
            grault = { version = "grault-vers" }
            garply = "garply-vers"
            waldo = "waldo-vers"

            [dependencies.fred]
            version = "0.1.3"

            [dependencies.plugh]
            version = "0.2.4"
            optional = true 

            [target.'cfg(unix)'.dependencies]
            unix = { version = "unix-vers" , features = ["some"] }

            [lints.rust]
            unused_extern_crates = 'warn'

            [dev-dependencies]
            foo = { version = "foo-vers" }
            bar = { version = "bar-vers", default-features = false }
            baz = { version = "baz-vers", features = ["baz-feat", "baz-feat2"] }
            qux = { version = "qux-vers", features = ["qux-feat","qux-additional"] }
            corge = { version = "corge-vers-override" , features = ["qux-feat"] }
            grault = { version = "grault-vers" }
            garply = "garply-vers"
            waldo = "waldo-vers"

            [lints.clippy]
            all = 'allow'

            [build-dependencies]
            foo = { version = "foo-vers" }
            bar = { version = "bar-vers", default-features = false }
            baz = { version = "baz-vers", features = ["baz-feat", "baz-feat2"] }
            qux = { version = "qux-vers", features = ["qux-feat","qux-additional"] }
            corge = { version = "corge-vers-override" , features = ["qux-feat"] }
            grault = { version = "grault-vers" }
            garply = "garply-vers"
            waldo = "waldo-vers"

            [features]
            my_feature = []
        "#,
        )
        .unwrap();

        super::merge(&mut cargo_toml, &root_toml);

        assert_eq!(expected_toml, cargo_toml);
    }
}
