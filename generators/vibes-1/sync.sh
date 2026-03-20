#!/usr/bin/env bash
set -euo pipefail

# Usage: ./sync.sh [<start>] <size>
# Appends <size> consecutive strings from the generator (starting at index
# <start>, default 0) to tried.txt, marking them as already tried.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TRIED_FILE="$SCRIPT_DIR/tried.txt"

if [[ $# -eq 1 ]]; then
    start=0
    size=$1
elif [[ $# -eq 2 ]]; then
    start=$1
    size=$2
else
    printf 'Usage: %s [<start>] <size>\n' "$0" >&2
    exit 1
fi

if ! [[ "$start" =~ ^[0-9]+$ ]] || ! [[ "$size" =~ ^[0-9]+$ ]] || (( size == 0 )); then
    printf 'Error: start and size must be non-negative integers, size must be > 0\n' >&2
    exit 1
fi

node "$SCRIPT_DIR/src/main.js" --resume "$start" 2>/dev/null \
    | head -n "$size" >> "$TRIED_FILE" || true

printf 'Recorded %d strings (from index %d) as tried in %s\n' "$size" "$start" "$TRIED_FILE" >&2
