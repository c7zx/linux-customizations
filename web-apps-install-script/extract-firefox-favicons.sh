#!/usr/bin/env bash
#
# Extract favicons from a Firefox profile's favicons.sqlite database.
#
# The script is intended for normal desktop users and should NOT be run as root.
# It creates a configurable Webapp-Icons folder inside the user's standard
# Pictures directory and writes the extracted favicon files into its
# "extracted" subfolder.

set -euo pipefail

# ============================================================
# CONFIG — EDIT THIS
# ============================================================

# Firefox favicon database.
# Replace <YOUR_PROFILE> with your actual Firefox profile directory name.
FIREFOX_FAVICONS_DB="$HOME/.mozilla/firefox/<YOUR_PROFILE>/favicons.sqlite"

# Example of a normal Firefox profile path:
# FIREFOX_FAVICONS_DB="$HOME/.mozilla/firefox/a1b2c3d4.default-release/favicons.sqlite"

# Subfolder created inside the user's standard Pictures directory.
PICTURES_SUBFOLDER="Webapp-Icons"

# Subfolder where the extracted favicons are written.
EXTRACTED_SUBFOLDER="extracted"

# ============================================================
# PREPARE PATHS
# ============================================================

# Do not run the whole script with sudo/root. The Firefox profile and output
# folders belong to the current desktop user.
[[ ${EUID:-$(id -u)} -ne 0 ]] || {
  echo "Do not run this script as root or with sudo."
  exit 1
}

# Python 3 is required for reading the Firefox SQLite database.
command -v python3 >/dev/null 2>&1 || {
  echo "python3 is required but was not found."
  exit 1
}

# Detect the user's standard Pictures directory.
# Examples:
#   English system: /home/user/Pictures
#   German system:  /home/user/Bilder
if command -v xdg-user-dir >/dev/null 2>&1; then
  PICTURES_DIR="$(xdg-user-dir PICTURES)"
else
  PICTURES_DIR=""
fi

# Fallback if xdg-user-dir is unavailable or returns nothing.
[[ -n "$PICTURES_DIR" ]] || PICTURES_DIR="$HOME/Pictures"

# Build the final output paths.
ICON_DIR="$PICTURES_DIR/$PICTURES_SUBFOLDER"
OUT_FOLDER="$ICON_DIR/$EXTRACTED_SUBFOLDER"

# Create the required directories if they do not already exist.
mkdir -p "$ICON_DIR" "$OUT_FOLDER"

# ============================================================
# EXTRACT FIREFOX FAVICONS
# ============================================================

python3 - "$FIREFOX_FAVICONS_DB" "$OUT_FOLDER" <<'PY'
import re
import sqlite3
import sys
from pathlib import Path
from urllib.parse import urlparse

# Paths come from the shell configuration block above.
db = Path(sys.argv[1]).expanduser()
out = Path(sys.argv[2]).expanduser()

# Avoid accidentally creating an empty SQLite file when the configured Firefox
# profile path is still a placeholder or does not exist.
if "<YOUR_PROFILE>" in str(db):
    raise SystemExit(
        "Please edit FIREFOX_FAVICONS_DB and replace <YOUR_PROFILE> "
        "with your real Firefox profile directory."
    )

if not db.is_file():
    raise SystemExit(f"Firefox favicon database not found: {db}")

out.mkdir(parents=True, exist_ok=True)

# Open the Firefox database read-only. The script only extracts icon data and
# never modifies Firefox's favicons.sqlite database.
with sqlite3.connect(f"{db.resolve().as_uri()}?mode=ro", uri=True) as con:
    rows = con.execute(
        """
        SELECT id, icon_url, data
        FROM moz_icons
        WHERE data IS NOT NULL
        """
    ).fetchall()


def extension(data):
    """Detect the image format from its file signature."""
    if data.startswith(b"\x89PNG\r\n\x1a\n"):
        return ".png"
    if data.startswith(b"\xff\xd8\xff"):
        return ".jpg"
    if data.startswith(b"GIF87a") or data.startswith(b"GIF89a"):
        return ".gif"
    if data.startswith(b"\x00\x00\x01\x00"):
        return ".ico"
    if b"<svg" in data[:500].lower():
        return ".svg"
    return ".bin"


for icon_id, url, data in rows:
    try:
        host = urlparse(url).hostname or "unknown"
    except Exception:
        host = "unknown"

    # Keep filenames safe and easy to identify.
    host = re.sub(r"[^A-Za-z0-9._-]+", "_", host)
    ext = extension(data)

    filename = out / f"{host}_{icon_id}{ext}"
    filename.write_bytes(data)

print(f"{len(rows)} favicons extracted to:")
print(out)
PY

echo
echo "Web app icon folder: $ICON_DIR"
echo "Extracted favicons:   $OUT_FOLDER"
echo "Done."
