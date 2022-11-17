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
    echo removing references to "${installedFile}"
    time sed -i'' "${installedFile}" -f <(
      echo -n 's!'

      # Print all matches as one big regex
      # We replace all newlines with pipes
      # Then strip out the last pipe
      # And finally escape all pipes
      (
        # NB: ensure we always have at least one entry in the regex
        echo '@storeDir@/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee'
        comm -1 -2 <(echo "$allSources") <(strings "${installedFile}" | \
          grep --only-matching '\(@storeDir@/[^/]\+\)' | \
          sort -u
        )
      ) | \
        grep --only-matching '@storeDir@/[a-z0-9]\{32\}' | \
        tr '\n' '|' | \
        sed 's/|$//g' | \
        sed 's/|/\\|/g'

      echo -n '!@storeDir@/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee!g'
    )
  done < <(find "${installLocation}" -type f)
}

if [ -n "${doNotRemoveReferencesToVendorDir-}" ]; then
  echo "removeReferencesToVendoredSources disabled"
elif [ -n "${cargoVendorDir-}" ]; then
  postInstallHooks+=(removeReferencesToVendoredSources)
else
  echo "cargoVendorDir not set, will not attempt to remove any references"
fi
