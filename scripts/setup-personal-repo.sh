#!/usr/bin/env bash
set -euo pipefail

config_url='https://github.com/magfje/chatgpt-arch/releases/download/pacman-repo/chatgpt-arch.conf'
config_path='/etc/pacman.conf.d/chatgpt-arch.conf'
include_line='Include = /etc/pacman.conf.d/chatgpt-arch.conf'
temporary_config=$(mktemp)

cleanup() {
  rm -f "$temporary_config"
}
trap cleanup EXIT

curl --fail --location --silent --show-error "$config_url" --output "$temporary_config"
sudo install -Dm644 "$temporary_config" "$config_path"

if ! grep -Fqx "$include_line" /etc/pacman.conf; then
  printf '\n%s\n' "$include_line" | sudo tee -a /etc/pacman.conf >/dev/null
fi

sudo pacman -Syu --needed chatgpt-native-bin

