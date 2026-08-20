#!/usr/bin/env bash
# shellcheck disable=SC2154
set -euo pipefail

project_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$project_root"

# PKGBUILD variables are intentionally imported for metadata assertions.
# shellcheck disable=SC1091
source PKGBUILD

[[ "$pkgname" == 'chatgpt-native-bin' ]]
[[ "$pkgver" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
[[ " ${arch[*]} " == *' x86_64 '* ]]
[[ " ${arch[*]} " == *' aarch64 '* ]]
[[ "${source_x86_64[0]}" == *'persistent.oaistatic.com/'* ]]
[[ "${source_aarch64[0]}" == *'persistent.oaistatic.com/'* ]]
[[ "${sha256sums_x86_64[0]}" =~ ^[0-9a-f]{64}$ ]]
[[ "${sha256sums_aarch64[0]}" =~ ^[0-9a-f]{64}$ ]]

srcinfo_version=$(sed -n 's/^\tpkgver = //p' .SRCINFO)
[[ "$srcinfo_version" == "$pkgver" ]]

if [[ $# -eq 0 ]]; then
  printf 'Package metadata tests passed for %s\n' "$pkgver"
  exit 0
fi

package_file=$1
[[ -f "$package_file" ]]

package_entries=$(bsdtar -tf "$package_file")
for expected in \
  'usr/bin/chatgpt' \
  'usr/lib/chatgpt/ChatGPT' \
  'usr/lib/chatgpt/resources/app.asar' \
  'usr/lib/chatgpt/resources/codex' \
  'usr/share/applications/chatgpt.desktop'; do
  if ! grep -Eq "^${expected}/?$" <<< "$package_entries"; then
    printf 'Package is missing %s\n' "$expected" >&2
    exit 1
  fi
done

if grep -Eq '^etc/apparmor.d/chatgpt$' <<< "$package_entries"; then
  printf 'Package unexpectedly contains the Debian-specific AppArmor profile\n' >&2
  exit 1
fi

printf 'Built package tests passed for %s\n' "$package_file"
