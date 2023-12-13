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
use toml_edit::Item;

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
        .write_all(cargo_toml.to_string().as_bytes())
        .context("failed to print updated Cargo.toml")
}

fn parse_toml(path: &Path) -> anyhow::Result<toml_edit::Document> {
    let mut buf = String::new();
    File::open(path)
        .and_then(|mut file| file.read_to_string(&mut buf))
        .with_context(|| format!("cannot read {}", path.display()))?;

    toml_edit::Document::from_str(&buf).with_context(|| format!("cannot parse {}", path.display()))
}

/// Merge the workspace `root` toml into the specified crate's `cargo_toml`
fn merge(cargo_toml: &mut toml_edit::Document, root: &toml_edit::Document) {
    let w: &dyn toml_edit::TableLike =
        if let Some(w) = root.get("workspace").and_then(try_as_table_like) {
            w
        } else {
            // no "workspace" entry, nothing to merge
            return;
        };

    // https://doc.rust-lang.org/cargo/reference/workspaces.html#workspaces
    for (key, ws_key, inherit) in [
        ("package", "package", false),
        ("dependencies", "dependencies", false),
        ("dev-dependencies", "dependencies", false),
        ("build-dependencies", "dependencies", false),
        ("lints", "lints", true),
    ] {
        if let Some((cargo_toml, root)) = cargo_toml.get_mut(key).zip(w.get(ws_key)) {
            if inherit {
                try_inherit_cargo_table(cargo_toml, root);
            } else {
                try_merge_cargo_tables(cargo_toml, root);
            }
        };

        if let Some(targets) = cargo_toml.get_mut("target").and_then(try_as_table_like_mut) {
            for (_, tp) in targets.iter_mut() {
                if let Some((cargo_toml, root)) = tp.get_mut(key).zip(w.get(ws_key)) {
                    if inherit {
                        try_inherit_cargo_table(cargo_toml, root);
                    } else {
                        try_merge_cargo_tables(cargo_toml, root);
                    }
                }
            }
        }
    }
}

/// Return a [`toml_edit::TableLike`] representation of the [`Item`] (if any)
fn try_as_table_like(item: &Item) -> Option<&dyn toml_edit::TableLike> {
    match item {
        Item::Table(w) => Some(w),
        Item::Value(toml_edit::Value::InlineTable(w)) => Some(w),
        _ => None,
    }
}

/// Return a mutable [`toml_edit::TableLike`] representation of the [`Item`] (if any)
fn try_as_table_like_mut(item: &mut Item) -> Option<&mut dyn toml_edit::TableLike> {
    match item {
        Item::Table(w) => Some(w),
        Item::Value(toml_edit::Value::InlineTable(w)) => Some(w),
        _ => None,
    }
}

/// Inherit the specified `cargo_toml` from workspace `root` if the former is a table
fn try_inherit_cargo_table(cargo_toml: &mut Item, root: &Item) {
    let Some(t) = try_as_table_like_mut(cargo_toml) else {
        return;
    };
    if t.get("workspace")
        .and_then(Item::as_bool)
        .unwrap_or_default()
    {
        t.remove("workspace");
        let orig_val = mem::replace(cargo_toml, root.clone());
        merge_items(cargo_toml, orig_val);
    }
}

/// Merge the specified `cargo_toml` and workspace `root` if both are tables
fn try_merge_cargo_tables(cargo_toml: &mut Item, root: &Item) {
    let cargo_toml = try_as_table_like_mut(cargo_toml);
    let root = try_as_table_like(root);

    if let Some((cargo_toml, root)) = cargo_toml.zip(root) {
        merge_cargo_tables(cargo_toml, root);
    }
}
/// Merge the specified `cargo_toml` and workspace `root` tables
fn merge_cargo_tables<T, U>(cargo_toml: &mut T, root: &U)
where
    T: toml_edit::TableLike + ?Sized,
    U: toml_edit::TableLike + ?Sized,
{
    cargo_toml.iter_mut().for_each(|(k, v)| {
        // Bail if:
        // - cargo_toml isn't a table (otherwise `workspace = true` can't show up
        // - the workspace root doesn't have this key
        let (t, root_val) = match try_as_table_like_mut(&mut *v).zip(root.get(&k)) {
            Some((t, root_val)) => (t, root_val),
            _ => return,
        };

        if let Some(Item::Value(toml_edit::Value::Boolean(bool_value))) = t.get("workspace") {
            if *bool_value.value() {
                t.remove("workspace");
                let orig_val = mem::replace(v, root_val.clone());
                merge_items(v, orig_val);
            }
        }
    });
}

/// Recursively merge the `additional` item into the specified `dest`
fn merge_items(dest: &mut Item, additional: Item) {
    use toml_edit::Value;

    match additional {
        Item::Value(additional) => match additional {
            Value::String(_)
            | Value::Integer(_)
            | Value::Float(_)
            | Value::Boolean(_)
            | Value::Datetime(_) => {
                // Override dest completely for raw values
                *dest = Item::Value(additional);
            }

            Value::Array(additional) => {
                if let Item::Value(Value::Array(dest)) = dest {
                    dest.extend(additional);
                } else {
                    // Override dest completely if types don't match
                    *dest = Item::Value(Value::Array(additional));
                }
            }

            Value::InlineTable(additional) => {
                merge_tables(dest, additional);
            }
        },
        Item::Table(additional) => {
            merge_tables(dest, additional);
        }
        Item::None => {}
        Item::ArrayOfTables(additional) => {
            if let Item::ArrayOfTables(dest) = dest {
                dest.extend(additional);
            } else {
                // Override dest completely if types don't match
                *dest = Item::ArrayOfTables(additional);
            }
        }
    }
}

use table_like_ext::merge_tables;
mod table_like_ext {
    //! Helper functions to merge values in any combination of the two [`TableLike`] items
    //! found in [`toml_edit`]

    use toml_edit::{Item, TableLike};

    /// Recursively merge the `additional` table into `dest` (overwriting if `dest` is not a table)
    pub(super) fn merge_tables<T>(dest: &mut Item, additional: T)
    where
        T: TableLikeExt,
    {
        match dest {
            Item::Table(dest) => merge_table_like(dest, additional),
            Item::Value(toml_edit::Value::InlineTable(dest)) => merge_table_like(dest, additional),
            _ => {
                // Override dest completely if types don't match, but also
                // skip empty tables (i.e. if we had `key = { workspace = true }`
                if !additional.is_empty() {
                    *dest = additional.into_item();
                }
            }
        }
    }

    /// Recursively merge two tables
    fn merge_table_like<T, U>(dest: &mut T, additional: U)
    where
        T: TableLike,
        U: TableLikeExt,
    {
        additional
            .into_iter()
            .map(U::map_iter_item)
            .for_each(|(k, v)| match dest.get_mut(&k) {
                Some(existing) => super::merge_items(existing, v),
                None => {
                    dest.insert(&k, v);
                }
            });
    }

    /// Generalized form of the item yielded by [`IntoIterator`] for the two [`TableLike`] types
    /// in [`toml_edit`]
    type CommonIterItem = (toml_edit::InternalString, Item);

    /// Extension trait to iterate [`Item`]s from a [`TableLike`] item
    pub(super) trait TableLikeExt: TableLike + IntoIterator {
        /// Convert the iterator item to a common type
        fn map_iter_item(item: Self::Item) -> CommonIterItem;

        /// Convert the table into an [`Item`]
        fn into_item(self) -> Item;
    }

    impl TableLikeExt for toml_edit::Table {
        fn map_iter_item(item: Self::Item) -> CommonIterItem {
            item
        }

        fn into_item(self) -> Item {
            Item::Table(self)
        }
    }

    impl TableLikeExt for toml_edit::InlineTable {
        fn map_iter_item(item: Self::Item) -> CommonIterItem {
            let (k, v) = item;
            (k, Item::Value(v))
        }

        fn into_item(self) -> Item {
            Item::Value(toml_edit::Value::InlineTable(self))
        }
    }
}

#[cfg(test)]
mod tests {
    use pretty_assertions::assert_eq;
    use std::str::FromStr;

    #[test]
    fn smoke() {
        let mut cargo_toml = toml_edit::Document::from_str(
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
            # the `foo` dependency is most imporant, so it goes first
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

            [features]
            # this feature is a demonstration that comments are preserved
            my_feature = []

            [lints]
            workspace = true
        "#,
        )
        .unwrap();

        let root_toml = toml_edit::Document::from_str(
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
            # top-level workspace comments are not copied - only the values are merged
            foo = { version = "foo-vers" }
            bar = { version = "bar-vers", default-features = false }
            baz = { version = "baz-vers", features = ["baz-feat", "baz-feat2"] }
            qux = { version = "qux-vers", features = ["qux-feat"] }
            corge = { version = "corge-vers", features = ["qux-feat"] }
            garply = "garply-workspace-vers"
            waldo = { version = "waldo-workspace-vers" }
            unix = { version = "unix-vers" }

            [workspace.lints.rust]
            unused_extern_crates = 'warn'

            [workspace.lints.clippy]
            all = 'allow'
        "#,
        )
        .unwrap();

        // NOTE: The nonstandard spacing is due to reusing decorations from original keys/values
        // in cargo_toml
        let expected_toml_str = r#"
            [package]
            authors= ["first author", "second author"]
            categories= ["first category", "second category" ]
            description= "some description"
            documentation= "some doc url"
            edition= "2021"
            exclude= ["first exclusion", "second exclusion"]
            homepage= "some home page"
            include= ["first inclusion", "second inclusion"]
            keyword= ["first keyword", "second keyword"]
            license= "some license"
            license-file= "some license-file"
            publish= true
            readme= "some readme"
            repository= "some repository"
            rust-version= "some rust-version"
            version= "some version"

            [dependencies]
            # the `foo` dependency is most imporant, so it goes first
            foo= { version = "foo-vers" }
            bar= { version = "bar-vers", default-features = false }
            baz= { version = "baz-vers", features = ["baz-feat", "baz-feat2"] }
            qux = { version = "qux-vers", features = ["qux-feat","qux-additional"] }
            corge = { version = "corge-vers-override" , features = ["qux-feat"] }
            grault = { version = "grault-vers" }
            garply = "garply-vers"
            waldo = "waldo-vers"

            [target.'cfg(unix)'.dependencies]
            unix = { version = "unix-vers" , features = ["some"] }

            [lints.rust]
            unused_extern_crates = 'warn'

            [dev-dependencies]
            foo= { version = "foo-vers" }
            bar= { version = "bar-vers", default-features = false }
            baz= { version = "baz-vers", features = ["baz-feat", "baz-feat2"] }
            qux = { version = "qux-vers", features = ["qux-feat","qux-additional"] }
            corge = { version = "corge-vers-override" , features = ["qux-feat"] }
            grault = { version = "grault-vers" }
            garply = "garply-vers"
            waldo = "waldo-vers"

            [lints.clippy]
            all = 'allow'

            [build-dependencies]
            foo= { version = "foo-vers" }
            bar= { version = "bar-vers", default-features = false }
            baz= { version = "baz-vers", features = ["baz-feat", "baz-feat2"] }
            qux = { version = "qux-vers", features = ["qux-feat","qux-additional"] }
            corge = { version = "corge-vers-override" , features = ["qux-feat"] }
            grault = { version = "grault-vers" }
            garply = "garply-vers"
            waldo = "waldo-vers"

            [features]
            # this feature is a demonstration that comments are preserved
            my_feature = []
        "#;

        super::merge(&mut cargo_toml, &root_toml);

        assert_eq!(expected_toml_str, cargo_toml.to_string());
    }
}
