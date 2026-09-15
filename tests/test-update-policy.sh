#!/usr/bin/env bash
set -euo pipefail

project_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
version_check="$project_root/scripts/check-architecture-versions.sh"

"$version_check" 26.908.70816 26.908.70816

status=0
output=$("$version_check" 26.908.61612 26.908.70816) || status=$?
[[ "$status" -eq 75 ]]
[[ "$output" == *'staged rollout detected'* ]]
[[ "$output" == *'deferring until both architectures match'* ]]

status=0
output=$("$version_check" '' 26.908.70816 2>&1) || status=$?
[[ "$status" -eq 1 ]]
[[ "$output" == *'amd64=missing'* ]]

printf 'Updater rollout policy tests passed\n'
