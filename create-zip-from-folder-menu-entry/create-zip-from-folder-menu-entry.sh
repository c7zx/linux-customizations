#!/usr/bin/env bash
set -u

create_zip() (
    local path="$1"

    [[ -d "$path" ]] || return 1

    local parent folder output i
    parent="$(dirname -- "$path")"
    folder="$(basename -- "$path")"

    cd -- "$parent" || return 1

    output="${folder}.zip"

    if [[ -e "$output" || -L "$output" ]]; then
        i=2
        while [[ -e "${folder}-${i}.zip" || -L "${folder}-${i}.zip" ]]; do
            ((i++))
        done
        output="${folder}-${i}.zip"
    fi

    # Store symlinks as links (-y) instead of following files outside the folder.
    zip -rqy "./$output" -- "$folder"
)

status=0

# Dolphin passes selected folders as arguments.
if (( $# > 0 )); then
    for path in "$@"; do
        create_zip "$path" || status=1
    done
    exit "$status"
fi

# Nautilus exposes selected folders through this environment variable.
if [[ -n "${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS:-}" ]]; then
    while IFS= read -r path; do
        if [[ -n "$path" ]]; then
            create_zip "$path" || status=1
        fi
    done <<< "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS"
fi

exit "$status"
