#!/usr/bin/env bash
# Update the gather package to the latest python/gather main commit.
#
# Rewrites the `rev` and `hash` in default.nix to track the current tip of
# gather's default branch, so the package follows main without hand-editing.
set -euo pipefail

domain="gitea.x.home.arpa"
owner="python"
repo="gather"
file="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/default.nix"

rev="$(git ls-remote "git@${domain}:${owner}/${repo}.git" refs/heads/main | cut -f1)"
if [ -z "${rev}" ]; then
  echo "error: could not resolve latest ${owner}/${repo} main" >&2
  exit 1
fi
echo "rev:  ${rev}"

archive="https://${domain}/api/v1/repos/${owner}/${repo}/archive/${rev}.tar.gz"
base32="$(nix-prefetch-url --unpack --type sha256 "${archive}" 2>/dev/null | tail -1)"
hash="$(nix hash to-sri --type sha256 "${base32}" 2>/dev/null)"
if [ -z "${hash}" ]; then
  echo "error: could not compute source hash for ${archive}" >&2
  exit 1
fi
echo "hash: ${hash}"

sed -i \
  -e "s|rev = \".*\";|rev = \"${rev}\";|" \
  -e "s|hash = \".*\";|hash = \"${hash}\";|" \
  "${file}"

echo "updated ${file}"
