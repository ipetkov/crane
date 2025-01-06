# Strip any references to the rust toolchain (which can slip in through stdlib panic info) to avoid 
# including the toolchain in the runtime closure

removeReferencesToRustToolchain() {
    local installLocation="${1:-${out:?not defined}}"
    # NOTE(adam.dayan): would it be better to explicitly point to $(rustc --print sysroot)/lib/rustlib/src so we only scrub references to
    # the src? are there any reasons one might want a reference to the rest of the toolchain?
    echo "stripping references to Rust toolchain"
    local rustToolchainLocation rustToolchainStoreHash
    rustToolchainLocation=$(rustc --print sysroot)
    echo "Rust toolchain at: $rustToolchainLocation"
    rustToolchainStoreHash=$(echo "$rustToolchainLocation" | rg "^@storeDir@/([a-z0-9]{32})" -or '$1')

    find "${installLocation}" -type f -exec sed -i -E "s|@storeDir@/${rustToolchainStoreHash}([^/]*)|@storeDir@/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee\1|g" {} +;
    echo "stripping references done"
}

if [ -n "${doNotRemoveReferencesToRustToolchain-}" ]; then
    echo "removeReferencesToRustToolchain disabled"
else
    postInstallHooks+=(removeReferencesToRustToolchain)
fi


