replaceCargoLock() {
  local cargoLockOverride="${1:-${cargoLock:?not defined}}"

  if [[ -f Cargo.lock ]]; then
    echo "moving Cargo.lock to Cargo.lock.orig, then will use ${cargoLockOverride} as Cargo.lock"
     mv Cargo.lock Cargo.lock.orig
  else
    echo "will use ${cargoLockOverride} as Cargo.lock"
  fi

  cp --no-preserve=ownership,mode "${cargoLock}" Cargo.lock
}

if [ -n "${cargoLock:-}" ]; then
  if [ -n "${doNotReplaceCargoLock:-}" ]; then
    echo "skipping Cargo.lock override as requested";
  else
    prePatchHooks+=(replaceCargoLock)
  fi
fi
