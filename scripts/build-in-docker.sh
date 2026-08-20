#!/usr/bin/env bash
set -euo pipefail

project_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
host_uid=$(id -u)
host_gid=$(id -g)

docker run --rm \
  --env HOST_UID="$host_uid" \
  --env HOST_GID="$host_gid" \
  --volume "$project_root:/build" \
  --workdir /build \
  archlinux:base-devel \
  bash -lc '
    set -euo pipefail
    group_name=$(getent group "$HOST_GID" | cut -d: -f1 || true)
    if [[ -z "$group_name" ]]; then
      group_name=builder
      groupadd --gid "$HOST_GID" "$group_name"
    fi
    useradd --create-home --uid "$HOST_UID" --gid "$group_name" builder
    su builder -c "cd /build && makepkg --noconfirm --cleanbuild --nodeps"
  '

package_file=$(find "$project_root" -maxdepth 1 -type f -name 'chatgpt-native-bin-*.pkg.tar.zst' -print -quit)
if [[ -z "$package_file" ]]; then
  printf 'makepkg did not produce a package\n' >&2
  exit 1
fi

"$project_root/tests/test-package.sh"
docker run --rm \
  --env PACKAGE_NAME="$(basename "$package_file")" \
  --volume "$project_root:/build:ro" \
  --workdir /build \
  archlinux:base \
  bash -lc './tests/test-package.sh "/build/$PACKAGE_NAME"'
printf '%s\n' "$package_file"
