#!/usr/bin/env bash
set -euo pipefail

# Usage: slugify.sh "Short description"
# Output: short-description

input="${1:-}"
if [[ -z "$input" ]]; then
  echo "usage: $0 \"text to slugify\"" >&2
  exit 2
fi

printf '%s\n' "$input" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g' \
  | cut -c1-60 \
  | sed -E 's/^-+//; s/-+$//'
