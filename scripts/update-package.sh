#!/usr/bin/env bash
set -euo pipefail

repository_base='https://persistent.oaistatic.com/codex-app-prod/linux/deb'
expected_fingerprint='3BFA0E4AE8B8CC16A2D9BA684A3B4A566C4660E4'
project_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
key_file="$project_root/keys/openai-chatgpt-repository.asc"
pkgbuild="$project_root/PKGBUILD"
check_only=false

if [[ "${1:-}" == '--check' ]]; then
  check_only=true
elif [[ $# -ne 0 ]]; then
  printf 'Usage: %s [--check]\n' "$0" >&2
  exit 2
fi

work_dir=$(mktemp -d)
cleanup() {
  rm -rf "$work_dir"
}
trap cleanup EXIT

mkdir -m 700 "$work_dir/gnupg"
fingerprint=$(gpg --batch --show-keys --with-colons "$key_file" |
  awk -F: '$1 == "fpr" { print $10; exit }')

if [[ "$fingerprint" != "$expected_fingerprint" ]]; then
  printf 'Unexpected OpenAI repository key fingerprint: %s\n' "$fingerprint" >&2
  exit 1
fi

gpg --batch --homedir "$work_dir/gnupg" --import "$key_file" >/dev/null 2>&1
curl --fail --location --silent --show-error \
  "$repository_base/dists/stable/InRelease" \
  --output "$work_dir/InRelease"
gpg --batch --homedir "$work_dir/gnupg" \
  --output "$work_dir/Release" \
  --decrypt "$work_dir/InRelease" >/dev/null

release_sha256() {
  local target=$1
  awk -v target="$target" '
    $0 == "SHA256:" { in_sha256 = 1; next }
    in_sha256 && /^[^ ]/ { in_sha256 = 0 }
    in_sha256 && $3 == target { print $1; exit }
  ' "$work_dir/Release"
}

package_field() {
  local packages_file=$1
  local architecture=$2
  local field=$3

  awk -v architecture="$architecture" -v field="$field" '
    BEGIN { RS = ""; FS = "\n" }
    {
      package_name = ""
      package_architecture = ""
      for (line = 1; line <= NF; line++) {
        if ($line ~ /^Package: /) package_name = substr($line, 10)
        if ($line ~ /^Architecture: /) package_architecture = substr($line, 15)
      }
      if (package_name == "chatgpt" && package_architecture == architecture) {
        prefix = field ": "
        for (line = 1; line <= NF; line++) {
          if (index($line, prefix) == 1) {
            print substr($line, length(prefix) + 1)
            exit
          }
        }
      }
    }
  ' "$packages_file"
}

fetch_packages() {
  local architecture=$1
  local relative_path="main/binary-${architecture}/Packages.gz"
  local archive="$work_dir/Packages-${architecture}.gz"
  local packages="$work_dir/Packages-${architecture}"
  local expected_sha

  expected_sha=$(release_sha256 "$relative_path")
  if [[ ! "$expected_sha" =~ ^[0-9a-f]{64}$ ]]; then
    printf 'Missing SHA-256 for %s in signed Release metadata\n' "$relative_path" >&2
    exit 1
  fi

  curl --fail --location --silent --show-error \
    "$repository_base/dists/stable/$relative_path" \
    --output "$archive"
  printf '%s  %s\n' "$expected_sha" "$archive" | sha256sum --check --status
  gzip --decompress --stdout "$archive" > "$packages"
  printf '%s\n' "$packages"
}

amd64_packages=$(fetch_packages amd64)
arm64_packages=$(fetch_packages arm64)
version_amd64=$(package_field "$amd64_packages" amd64 Version)
version_arm64=$(package_field "$arm64_packages" arm64 Version)

if [[ -z "$version_amd64" || "$version_amd64" != "$version_arm64" ]]; then
  printf 'OpenAI architecture versions differ: amd64=%s arm64=%s\n' \
    "$version_amd64" "$version_arm64" >&2
  exit 1
fi

path_amd64=$(package_field "$amd64_packages" amd64 Filename)
path_arm64=$(package_field "$arm64_packages" arm64 Filename)
sha_amd64=$(package_field "$amd64_packages" amd64 SHA256)
sha_arm64=$(package_field "$arm64_packages" arm64 SHA256)

current_version=$(sed -n 's/^pkgver=//p' "$pkgbuild")
current_path_amd64=$(sed -n "s/^_deb_path_x86_64='\(.*\)'$/\1/p" "$pkgbuild")
current_path_arm64=$(sed -n "s/^_deb_path_aarch64='\(.*\)'$/\1/p" "$pkgbuild")
current_sha_amd64=$(sed -n "s/^sha256sums_x86_64=('\(.*\)')$/\1/p" "$pkgbuild")
current_sha_arm64=$(sed -n "s/^sha256sums_aarch64=('\(.*\)')$/\1/p" "$pkgbuild")

if [[ "$current_version" == "$version_amd64" &&
      "$current_path_amd64" == "$path_amd64" &&
      "$current_path_arm64" == "$path_arm64" &&
      "$current_sha_amd64" == "$sha_amd64" &&
      "$current_sha_arm64" == "$sha_arm64" ]]; then
  printf 'PKGBUILD is current at %s\n' "$version_amd64"
  exit 0
fi

if [[ "$check_only" == true ]]; then
  printf 'PKGBUILD is stale: current=%s upstream=%s\n' \
    "$current_version" "$version_amd64" >&2
  exit 1
fi

sed -i \
  -e "s|^pkgver=.*$|pkgver=${version_amd64}|" \
  -e "s|^_deb_path_x86_64='.*'$|_deb_path_x86_64='${path_amd64}'|" \
  -e "s|^_deb_path_aarch64='.*'$|_deb_path_aarch64='${path_arm64}'|" \
  -e "s|^sha256sums_x86_64=('.*')$|sha256sums_x86_64=('${sha_amd64}')|" \
  -e "s|^sha256sums_aarch64=('.*')$|sha256sums_aarch64=('${sha_arm64}')|" \
  "$pkgbuild"

printf 'Updated PKGBUILD to %s\n' "$version_amd64"
