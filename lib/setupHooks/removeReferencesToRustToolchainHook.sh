# Strip any references to the rust toolchain (which can slip in through stdlib panic info) to avoid 
# including the toolchain in the runtime closure

removeReferencesToRustToolchain() {
    local installLocation="${1:-${out:?not defined}}"
    echo "stripping references to Rust toolchain"
    local rustToolchainLocation rustToolchainStoreHash
    rustToolchainLocation=$(rustc --print sysroot)
    echo "Rust toolchain at: $rustToolchainLocation"
    rustToolchainStoreHash=$(echo "$rustToolchainLocation" | grep --only-matching '@storeDir@/[a-z0-9]\{32\}')

    find "${installLocation}" -type f -print0 | xargs -0 --no-run-if-empty sed -i'' "s|${rustToolchainStoreHash}|@storeDir@/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee|g"
    echo "stripping Rust toolchain references done"
}

if [ -n "${doNotRemoveReferencesToRustToolchain-}" ]; then
    echo "removeReferencesToRustToolchain disabled"
else
    postInstallHooks+=(removeReferencesToRustToolchain)
fi
