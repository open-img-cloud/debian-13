#!/usr/bin/env bash
# Prints the latest upstream Debian 13 cloud image version on stdout.
#
# Parses the directory listing at
#   https://cloud.debian.org/images/cloud/trixie/
# for dated build directories and prints <13>-<build id> for the highest
# one that holds the image (e.g. 13-20261103-2651). Runs in the upstream-watch reusable workflow
# (no KVM needed): keep it portable bash + curl + grep + sort only.

set -euo pipefail

URL='https://cloud.debian.org/images/cloud/trixie/'

listing=$(curl -fsL "$URL")
if [[ -z "$listing" ]]; then
  echo "::error::could not fetch $URL" >&2
  exit 1
fi

# Debian publishes a build directory before every image of it is uploaded
# (20261111-2659 first had only the azure and ec2 images): take the newest
# directory that already holds our amd64 genericcloud qcow2.
latest=''
for dir in $(printf '%s\n' "$listing" \
  | grep -oE 'href="[0-9]{8}-[0-9]+/"' \
  | sed -E 's#href="([0-9]{8}-[0-9]+)/"#\1#' \
  | sort -uVr \
  | head -n5); do
  files=$(curl -fsL "$URL$dir/" || true)
  if [[ "$files" == *"debian-13-genericcloud-amd64-$dir.qcow2"* ]]; then
    latest=$dir
    break
  fi
done

if [[ -z "$latest" ]]; then
  echo "::error::no build directory found in $URL" >&2
  exit 1
fi

printf '13-%s\n' "$latest"
