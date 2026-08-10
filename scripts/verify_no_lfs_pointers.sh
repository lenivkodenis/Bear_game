#!/usr/bin/env bash
set -euo pipefail

build_dir="${1:-build/web}"

test -f "$build_dir/index.html"
test -f "$build_dir/flutter_bootstrap.js"

lfs_pointers="$(grep -RIl 'version https://git-lfs.github.com/spec/v1' "$build_dir" || true)"
if [[ -n "$lfs_pointers" ]]; then
  echo "Git LFS pointer files found in $build_dir:"
  echo "$lfs_pointers"
  exit 1
fi

echo "Verified $build_dir: required files exist and no Git LFS pointers were found."
