#!/usr/bin/env bash
set -euo pipefail

# ── Configure the command to pipe each generated string into ─────────────────
COMMAND=(cryptsetup luksOpen --test-passphrase /dev/nvme0n1p2)
# ─────────────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TRIED_FILE="$SCRIPT_DIR/tried.txt"

# Mirror the --resume offset so the audit log index matches the generator index.
index=0
prev_arg=""
for arg in "$@"; do
    if [[ "$prev_arg" == "--resume" || "$prev_arg" == "-r" ]]; then
        index="$arg"
    elif [[ "$arg" =~ ^(--resume|-r)=([0-9]+)$ ]]; then
        index="${BASH_REMATCH[2]}"
    fi
    prev_arg="$arg"
done

# Load tried strings from file into an associative array for O(1) lookup.
declare -A tried=()
if [[ -f "$TRIED_FILE" ]]; then
    while IFS= read -r s; do
        tried["$s"]=1
    done < "$TRIED_FILE"
fi

# Single temp file for capturing command stderr, created once and reused.
cmd_stderr_file=$(mktemp)
trap 'rm -f "$cmd_stderr_file"' EXIT

first_output=""
first_input=""

# Suppress node's stderr — we own all audit logging below (index, input, output).
while IFS= read -r line; do
    if [[ -n "${tried[$line]+_}" ]]; then
        index=$((index + 1))
        continue
    fi

    if [[ -f "$SCRIPT_DIR/filter.js" ]]; then
        if ! node "$SCRIPT_DIR/filter.js" "$line" 2>/dev/null; then
            index=$((index + 1))
            continue
        fi
    fi

    cmd_stdout=$(printf '%s\n' "$line" | "${COMMAND[@]}" 2>"$cmd_stderr_file") && exit_code=0 || exit_code=$?
    output="$exit_code:$cmd_stdout$(< "$cmd_stderr_file")"

    tried["$line"]=1
    printf '%s\n' "$line" >> "$TRIED_FILE"

    printf '%d\t%s\t%s\n' "$index" "$line" "$output" >&2
    index=$((index + 1))

    if [[ -z "$first_output" ]]; then
        first_output="$output"
        first_input="$line"
        continue
    fi

    if [[ "$output" != "$first_output" ]]; then
        printf 'Output changed.\nBaseline input:  %s\nBaseline output: %s\nCurrent input:   %s\nCurrent output:  %s\n' \
            "$first_input" "$first_output" "$line" "$output" >&2
        printf '%s\n' "$line"
        exit 0
    fi
done < <(node "$SCRIPT_DIR/src/main.js" "$@" 2>/dev/null)
