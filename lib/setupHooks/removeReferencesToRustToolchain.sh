# Strip any references to the rust toolchain (which can slip in through stdlib panic info) to avoid 
# including the toolchain in the runtime closure

removeReferencesToRustToolchain() {
    local installLocation="${1:-${out:?not defined}}"
    # NOTE(adam.dayan): would it be better to explicitly point to $(rustc --print sysroot)/lib/rustlib/src so we only scrub references to
    # the src? are there any reasons one might want a reference to the rest of the toolchain?
    local rustToolchainLocation rustToolchainStoreHash
    rustToolchainLocation=$(rustc --print sysroot)
    rustToolchainStoreHash=$(echo "$rustToolchainLocation" | grep -oE '^@storeDir@/[a-z0-9](32)')

    echo "stripping references to Rust toolchain"
    find "${installLocation}" -type f -exec sed -i -E "s|$rustToolchainStoreHash[^/]*)|@storeDir@/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee\1|g" \;
    echo "stripping references done"
}

if [ -n "${doNotRemoveReferencesToRustToolchain-}" ]; then
    echo "removeReferencesToRustToolchain disabled"
else
    postInstallHooks+=(removeReferencesToRustToolchain)
fi


