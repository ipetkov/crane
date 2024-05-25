# Strip any references to the sources directory (which may have slipped in via
# panic info) so depending on the binary doesn't pull in all the sources as well.
removeReferencesToVendoredSources() {
  local installLocation="${1:-${out:?not defined}}"
  local vendoredDir="${2:-${cargoVendorDir:?not defined}}"

  local sedScript="$(mktemp removeReferencesScriptXXXX)"
  (
    echo -n 's!@storeDir@/\(eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee'

    (
      # Include the root of the vendor dir itself
      echo "${vendoredDir}"

      # Include the individual crates themselves in case
      # something else slips in a reference to them
      find -L "${vendoredDir}" -mindepth 1 -maxdepth 1 -type d | \
        xargs -I DIR find -H DIR -type l -exec readlink '{}' \;
    ) |
      grep --only-matching '@storeDir@/[a-z0-9]\{32\}' |
      while read crateSource; do
        echo -n '\|'"${crateSource#@storeDir@/}";
      done

    echo -n '\)!@storeDir@/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee!g'
  ) >"${sedScript}"

  local installedFile
  find "${installLocation}" -type f | while read installedFile; do
    echo stripping references to cargoVendorDir from "${installedFile}"
    sed -i'' "${installedFile}" -f "${sedScript}"

    @signIfRequired@
  done
}

@sourceSigningUtils@

if [ -n "${doNotRemoveReferencesToVendorDir-}" ]; then
  echo "removeReferencesToVendoredSources disabled"
elif [ -n "${cargoVendorDir-}" ]; then
  postInstallHooks+=(removeReferencesToVendoredSources)
else
  echo "cargoVendorDir not set, will not attempt to remove any references"
fi
