#!/usr/bin/env bash
set -euo pipefail

# process-wordlist.sh
#
# Usage:
#   ./process-wordlist.sh NEW_WORDLIST OUTPUT_WORDLIST PREVIOUS_WORDLIST...
#
# Example:
#   ./process-wordlist.sh new.txt filtered.txt old1.txt old2.txt old3.txt
#
# Optional:
#   TMPDIR_FOR_SORT=/big/disk ./process-wordlist.sh new.txt filtered.txt old*.txt

if (( $# < 3 )); then
    echo "Usage: $0 NEW_WORDLIST OUTPUT_WORDLIST PREVIOUS_WORDLIST..." >&2
    exit 1
fi

new_wordlist=$1
output_wordlist=$2
shift 2
previous_wordlists=( "$@" )

sort_tmpdir="${TMPDIR_FOR_SORT:-${TMPDIR:-/tmp}}"

tmp_new_sorted=$(mktemp)
tmp_old_sorted=$(mktemp)
trap 'rm -f "$tmp_new_sorted" "$tmp_old_sorted"' EXIT

# 1. Sort + dedupe the new wordlist
sort -T "$sort_tmpdir" -u "$new_wordlist" > "$tmp_new_sorted"

# 2. Combine all previous wordlists, sort + dedupe them
cat "${previous_wordlists[@]}" | sort -T "$sort_tmpdir" -u > "$tmp_old_sorted"

# 3. Keep only entries that are in NEW but not in OLD
comm -23 "$tmp_new_sorted" "$tmp_old_sorted" > "$output_wordlist"

echo "Wrote filtered wordlist to: $output_wordlist"
