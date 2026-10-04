#!/usr/bin/env bash
set -euo pipefail

rm -f "$HOME/.local/bin/create-zip-from-folder-menu-entry"
rm -f "$HOME/.local/share/nautilus/scripts/Create ZIP from Folder"
rm -f "$HOME/.local/share/kio/servicemenus/create-zip-from-folder.desktop"

if command -v nautilus >/dev/null 2>&1; then
    nautilus -q >/dev/null 2>&1 || true
fi

echo "Removed Create ZIP from Folder."
