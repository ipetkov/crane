# Strip any references to the sources directory (which may have slipped in via
# panic info) so depending on the binary doesn't pull in all the sources as well.
removeReferencesToVendoredSources() {
  local installLocation="${1:-${out:?not defined}}"
  local vendoredDir="${2:-${cargoVendorDir:?not defined}}"

  local installedFile
  while read installedFile; do
    echo stripping references to cargoVendorDir from "${installedFile}"
    time sed -i'' "${installedFile}" -f <(
      echo -n 's!@storeDir@/\(eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee'

      while read crateSource; do
        echo -n '\|'"${crateSource#@storeDir@/}";
      done < <(
        (
          # Include the root of the vendor dir itself
          echo "${vendoredDir}"

          # Include the individual crates themselves in case
          # something else slips in a reference to them
          find -L "${vendoredDir}" -mindepth 1 -maxdepth 1 -type d | \
            xargs -I DIR find -H DIR -type l -exec readlink '{}' \;
        ) | grep --only-matching '@storeDir@/[a-z0-9]\{32\}'
      )

      echo -n '\)!@storeDir@/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee!g'
    )

    @signIfRequired@
  done < <(find "${installLocation}" -type f)
}

@sourceSigningUtils@

if [ -n "${doNotRemoveReferencesToVendorDir-}" ]; then
  echo "removeReferencesToVendoredSources disabled"
elif [ -n "${cargoVendorDir-}" ]; then
  postInstallHooks+=(removeReferencesToVendoredSources)
else
  echo "cargoVendorDir not set, will not attempt to remove any references"
fi
