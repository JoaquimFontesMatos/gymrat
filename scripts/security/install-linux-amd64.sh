#!/usr/bin/env bash
set -euo pipefail
# Install verified upstream release binaries in the directory supplied as $1.
[[ $(uname -s)-$(uname -m) == Linux-x86_64 ]] || { echo 'Only Linux x86_64 is supported by this installer' >&2; exit 1; }
target=${1:?Pass an installation directory}
mkdir -p "$target"
target=$(cd "$target" && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fetch() {
  local url=$1 file=$2 sum=$3
  curl -fsSL --retry 3 "$url" -o "$tmp/$file"
  echo "$sum  $tmp/$file" | sha256sum -c -
}
fetch https://github.com/opengrep/opengrep/releases/download/v2.0.0/opengrep_linux_x86 opengrep 37e93f4da5fd04a18c5c1febbdd12f7e98dfccd4d0c9cf2593bcb25eeb462da0
fetch https://github.com/aquasecurity/trivy/releases/download/v0.76.2/trivy_0.76.2_Linux-64bit.tar.gz trivy.tar.gz bc0fc726e017b8927a62b2d3531d7a84ee01769daf5c99ed866dced54089fdbf
fetch https://github.com/bridgecrewio/checkov/releases/download/3.4.5/checkov_linux_X86_64.zip checkov.zip 8b088b4b7c0ffffa47c5c463978057187c457b62ccdcc2137697d5b3be3de79e
tar -xzf "$tmp/trivy.tar.gz" -C "$tmp" trivy
unzip -q "$tmp/checkov.zip" -d "$tmp"
install -m 755 "$tmp/opengrep" "$tmp/trivy" "$tmp/dist/checkov" "$target/"
