#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
MAIN_SCRIPT="create-zip-from-folder-menu-entry.sh"

if ! command -v zip >/dev/null 2>&1; then
    echo "Error: 'zip' is not installed."
    echo
    echo "sudo dnf install zip"
    echo "sudo apt install zip"
    echo "sudo pacman -S zip"
    echo "sudo zypper install zip"
    echo "sudo apk add zip"
    exit 1
fi

BIN_DIR="$HOME/.local/bin"
BIN_TARGET="$BIN_DIR/create-zip-from-folder-menu-entry"

mkdir -p "$BIN_DIR"
install -m 755 "$SOURCE_DIR/$MAIN_SCRIPT" "$BIN_TARGET"

installed=0

if command -v nautilus >/dev/null 2>&1; then
    NAUTILUS_DIR="$HOME/.local/share/nautilus/scripts"
    mkdir -p "$NAUTILUS_DIR"
    install -m 755 "$SOURCE_DIR/nautilus-menu-entry" \
        "$NAUTILUS_DIR/Create ZIP from Folder"

    nautilus -q >/dev/null 2>&1 || true
    echo "Installed for Nautilus."
    installed=1
fi

if command -v dolphin >/dev/null 2>&1; then
    DOLPHIN_DIR="$HOME/.local/share/kio/servicemenus"
    mkdir -p "$DOLPHIN_DIR"
    install -m 755 "$SOURCE_DIR/dolphin-menu-entry.desktop" \
        "$DOLPHIN_DIR/create-zip-from-folder.desktop"

    echo "Installed for Dolphin."
    installed=1
fi

if (( installed == 0 )); then
    echo "The ZIP helper was installed, but Nautilus or Dolphin was not found."
    exit 0
fi

echo
echo "Done."
