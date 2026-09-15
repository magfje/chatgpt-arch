#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  printf 'Usage: %s AMD64_VERSION ARM64_VERSION\n' "$0" >&2
  exit 2
fi

version_amd64=$1
version_arm64=$2

if [[ -z "$version_amd64" || -z "$version_arm64" ]]; then
  printf 'Missing OpenAI package version: amd64=%s arm64=%s\n' \
    "${version_amd64:-missing}" "${version_arm64:-missing}" >&2
  exit 1
fi

if [[ "$version_amd64" != "$version_arm64" ]]; then
  printf 'OpenAI staged rollout detected: amd64=%s arm64=%s; deferring until both architectures match\n' \
    "$version_amd64" "$version_arm64"
  exit 75
fi
