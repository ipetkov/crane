# Strip any references to the sources directory (which may have slipped in via
# panic info) so depending on the binary doesn't pull in all the sources as well.
removeReferencesToVendoredSources() {
  local installLocation="${1:-${out:?not defined}}"
  local vendoredDir="${2:-${cargoVendorDir:?not defined}}"

  echo "stripping references to cargoVendorDir"

  local allSources=$(
    (
      # Include the root of the vendor dir itself
      echo "${vendoredDir}"

      # Include the individual crates themselves in case
      # something else slips in a reference to them
      find -L "${vendoredDir}" -mindepth 1 -maxdepth 1 -type d | \
        xargs -I DIR find -H DIR -type l -exec readlink '{}' \;
    ) | sort -u
  )

  local installedFile
  while read installedFile; do
    comm -1 -2 <(echo "$allSources") <(strings "${installedFile}" | \
      grep --only-matching '\(@storeDir@/[^/]\+\)' | \
      sort -u) | \
      xargs --verbose -I REF remove-references-to -t REF "${installedFile}"
  done < <(find "${installLocation}" -type f)
}

if [ -n "${doNotRemoveReferencesToVendorDir-}" ]; then
  echo "removeReferencesToVendoredSources disabled"
elif [ -n "${cargoVendorDir-}" ]; then
  postInstallHooks+=(removeReferencesToVendoredSources)
else
  echo "cargoVendorDir not set, will not attempt to remove any references"
fi
