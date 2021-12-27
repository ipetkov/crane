configureCargoVendoredDepsHook() {
  echo "Executing configureCargoVendoredDepsHook"

  mkdir -p .cargo
  cat >>.cargo/config <<EOF
[source.crates-io]
replace-with = "nix-sources"

[source.nix-sources]
directory = "${cargoVendorDir}"
EOF

  echo "Finished configureCargoVendoredDepsHook"
}

if [ -n "${cargoVendorDir-}" ]; then
  preConfigureHooks+=(configureCargoVendoredDepsHook)
else
  echo "cargoVendorDir not set"
fi
