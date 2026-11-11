#!/usr/bin/env bash
# Prints the latest upstream Debian 13 cloud image version on stdout.
#
# Parses the directory listing at
#   https://cloud.debian.org/images/cloud/trixie/
# for dated build directories and prints <13>-<build id> for the highest
# one (e.g. 13-20261103-2651). Runs in the upstream-watch reusable workflow
# (no KVM needed): keep it portable bash + curl + grep + sort only.

set -euo pipefail

URL='https://cloud.debian.org/images/cloud/trixie/'

listing=$(curl -fsL "$URL")
if [[ -z "$listing" ]]; then
  echo "::error::could not fetch $URL" >&2
  exit 1
fi

latest=$(printf '%s\n' "$listing" \
  | grep -oE 'href="[0-9]{8}-[0-9]+/"' \
  | sed -E 's#href="([0-9]{8}-[0-9]+)/"#\1#' \
  | sort -uV \
  | tail -n1)

if [[ -z "$latest" ]]; then
  echo "::error::no build directory found in $URL" >&2
  exit 1
fi

printf '13-%s\n' "$latest"
