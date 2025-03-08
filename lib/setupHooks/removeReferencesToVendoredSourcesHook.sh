# Strip any references to the sources directory (which may have slipped in via
# panic info) so depending on the binary doesn't pull in all the sources as well.
removeReferencesToVendoredSources() {
  local installLocation="${1:-${out:?not defined}}"
  local vendoredDir="${2:-${cargoVendorDir:?not defined}}"

  (
    exec 3>&1
    echo stripping references to cargoVendorDir from:
    find "${installLocation}" -type f -print0 |
      sort -z |
      tee -a >(tr '\0' '\n' >&3) |
      xargs -0 --no-run-if-empty sed -i'' -f <(
        echo -n 's!@storeDir@/\(eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee'

        (
          # Include the root of the vendor dir itself
          echo "${vendoredDir}"

          # Include the individual crates themselves in case
          # something else slips in a reference to them
          find -L "${vendoredDir}" -mindepth 1 -maxdepth 1 -type d -print0 | \
            xargs -0 -I DIR find -H DIR -type l -exec readlink '{}' \;
        ) |
          grep --only-matching '@storeDir@/[a-z0-9]\{32\}' |
          sort -u |
          while read crateSource; do
            echo -n '\|'"${crateSource#@storeDir@/}";
          done || true # Handle if vendoredDir doesn't point to the store

        echo -n '\)!@storeDir@/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee!g'
      )

    echo stripping references done
  )

  @signIfRequired@
}

@sourceSigningUtils@

if [ -n "${doNotRemoveReferencesToVendorDir-}" ]; then
  echo "removeReferencesToVendoredSources disabled"
elif [ -n "${cargoVendorDir-}" ]; then
  postInstallHooks+=(removeReferencesToVendoredSources)
else
  echo "cargoVendorDir not set, will not attempt to remove any references"
fi
