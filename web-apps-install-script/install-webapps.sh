#!/usr/bin/env bash
#
# Create isolated Chromium web apps from the lists in CONFIG 1.
# Re-running the script adds only missing apps and refreshes copied icons.

set -euo pipefail

# ============================================================
# CONFIG 1 — EDIT THIS
# ============================================================

# Normal web apps open as app-style windows without a regular tab bar.
# Format: "website-or-full-url - Display Name"
NORMAL_WEBAPPS=(
  "example.com - Example"
  "example-2.com - Example Tabs 2"
)

# Tabbed web apps open as regular Chromium windows with tabs,
# but still use their own isolated Chromium profile.
TABBED_WEBAPPS=(
  "example.com - Example Tabs"
  "example-2.com - Example Tabs 2"
)

# ICON SOURCE PATH — EDIT IF NEEDED

# The script creates the folder if it does not exist.
# Icon names are generated from the display name:
# "Example" -> example.png
# "Example Test" -> example-test.png

# Use the system's configured Pictures directory.
# If xdg-user-dir is unavailable, fall back to ~/Pictures.
PICTURES_DIR="$(xdg-user-dir PICTURES 2>/dev/null || true)"
PICTURES_DIR="${PICTURES_DIR:-$HOME/Pictures}"

# Put custom web-app icons here.
# By default, this is a subfolder inside the system Pictures directory.
ICON_SOURCE_DIR="$PICTURES_DIR/Webapp-Icons"

# ============================================================
# CONFIG 2 — USUALLY LEAVE AS-IS
# ============================================================

# Follow the XDG Base Directory standard.
# If XDG_DATA_HOME is not set, ~/.local/share is used.
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

# Persistent copies of icons used by the generated launchers.
ICON_TARGET_DIR="$XDG_DATA_HOME/icons/webapps"

# One isolated Chromium profile directory is created per app.
PROFILE_DIR="$XDG_DATA_HOME/chromium-webapps"

# Linux application launchers are created here.
APPLICATIONS_DIR="$XDG_DATA_HOME/applications"

# Install Chromium automatically if it is not available.
AUTO_INSTALL_CHROMIUM=true

# ============================================================
# SAFETY AND SMALL HELPERS
# ============================================================

# The script belongs to the current desktop user. Running the whole script
# with sudo would create files for the wrong account.
[[ ${EUID:-$(id -u)} -ne 0 ]] || {
  echo "Do not run this script as root or with sudo."
  exit 1
}

# Remove surrounding whitespace from one config field.
trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

# Turn a display name into a reusable local identifier.
# Examples: "Example Test" -> "example-test"
slugify() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

# Allow short config entries such as "example.com".
normalize_url() {
  [[ "$1" =~ ^https?:// ]] && printf '%s' "$1" || printf 'https://%s' "$1"
}

# Fedora normally exposes chromium-browser; other distributions may use chromium.
find_chromium() {
  command -v chromium-browser 2>/dev/null || command -v chromium 2>/dev/null || true
}

# Install Chromium only when it is missing.
install_chromium() {
  echo "Chromium is missing. Installing it..."

  if command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y chromium
  elif command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y chromium || sudo apt-get install -y chromium-browser
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm chromium
  else
    echo "No supported package manager found."
    echo "Install Chromium manually, then run this script again."
    exit 1
  fi
}

# Existing apps are identified by the visible Name= entry in desktop launchers.
app_exists() {
  grep -Rqs --include='*.desktop' -Fx "Name=$1" "$APPLICATIONS_DIR"
}

# Pick the first matching icon format for the generated app slug.
icon_for() {
  local slug="$1" ext

  for ext in png svg ico webp jpg jpeg; do
    if [[ -f "$ICON_TARGET_DIR/$slug.$ext" ]]; then
      printf '%s' "$ICON_TARGET_DIR/$slug.$ext"
      return
    fi
  done

  printf 'web-browser'
}

# Build the desktop ID and StartupWMClass used by Chromium --app windows.
# This is what lets GNOME/Wayland associate the running window with its launcher.
normal_ids() {
  local url="$1" rest host path desktop_id wm_class

  rest="${url#*://}"
  host="${rest%%/*}"
  host="${host%%\?*}"
  host="${host%%\#*}"

  rest="${rest#"$host"}"
  path="${rest%%\?*}"
  path="${path%%\#*}"
  [[ -n "$path" ]] || path="/"

  path="${path#/}"
  path="${path//\//_}"

  desktop_id="${host}__${path}"
  wm_class="$desktop_id"

  # Chromium's window class omits trailing underscores from the path form.
  while [[ "$wm_class" == *_ ]]; do
    wm_class="${wm_class%_}"
  done

  printf '%s|%s' "$desktop_id" "$wm_class"
}

# Create one isolated profile and one .desktop launcher.
# Existing apps are deliberately skipped rather than rewritten.
create_app() {
  local mode="$1" entry="$2"
  local raw_url name url slug profile icon desktop_file exec_line
  local ids desktop_id wm_class

  if [[ "$entry" != *" - "* ]]; then
    echo "SKIP  Invalid entry: $entry"
    return
  fi

  raw_url="$(trim "${entry%% - *}")"
  name="$(trim "${entry#* - }")"
  url="$(normalize_url "$raw_url")"
  slug="$(slugify "$name")"

  if app_exists "$name"; then
    echo "SKIP  $name (already exists)"
    return
  fi

  profile="$PROFILE_DIR/$slug"
  icon="$(icon_for "$slug")"
  mkdir -p "$profile"

  if [[ "$mode" == "normal" ]]; then
    # App-style Chromium window.
    ids="$(normal_ids "$url")"
    desktop_id="${ids%%|*}"
    wm_class="${ids#*|}"
    desktop_file="$APPLICATIONS_DIR/chrome-${desktop_id}-Default.desktop"
    exec_line="$CHROMIUM_BIN --user-data-dir=\"$profile\" --profile-directory=Default --app=\"$url\""
  else
    # Regular Chromium window with tabs and a dedicated window class.
    wm_class="$slug"
    desktop_file="$APPLICATIONS_DIR/$slug.desktop"
    exec_line="$CHROMIUM_BIN --class=$slug --user-data-dir=\"$profile\" --new-window \"$url\""
  fi

  cat > "$desktop_file" <<EOF
[Desktop Entry]
Version=1.0
Name=$name
Comment=$name Web App
Exec=$exec_line
TryExec=$CHROMIUM_BIN
Terminal=false
Type=Application
Icon=$icon
Categories=Network;
StartupWMClass=$wm_class
StartupNotify=true
EOF

  echo "ADD   $name"
}

# ============================================================
# PREPARE THE SYSTEM
# ============================================================

# Chromium is the only required application for these web apps.
CHROMIUM_BIN="$(find_chromium)"
if [[ -z "$CHROMIUM_BIN" ]]; then
  [[ "$AUTO_INSTALL_CHROMIUM" == true ]] || {
    echo "Chromium is required but not installed."
    exit 1
  }

  install_chromium
  CHROMIUM_BIN="$(find_chromium)"
fi

[[ -n "$CHROMIUM_BIN" ]] || {
  echo "Chromium installation finished, but no Chromium executable was found."
  exit 1
}

# Make the script usable on a fresh user account.
mkdir -p "$ICON_SOURCE_DIR" "$ICON_TARGET_DIR" "$PROFILE_DIR" "$APPLICATIONS_DIR"

# Copy/overwrite source icons into the persistent local icon store.
# Deleting a source icon later does not remove the already copied target icon.
shopt -s nullglob
for icon in "$ICON_SOURCE_DIR"/*.{png,svg,ico,webp,jpg,jpeg}; do
  cp -f "$icon" "$ICON_TARGET_DIR/"
done
shopt -u nullglob

# ============================================================
# CREATE ONLY THE MISSING WEB APPS
# ============================================================

echo "Chromium: $CHROMIUM_BIN"
echo "Icons:    $ICON_SOURCE_DIR -> $ICON_TARGET_DIR"
echo

for entry in "${NORMAL_WEBAPPS[@]}"; do
  create_app normal "$entry"
done

for entry in "${TABBED_WEBAPPS[@]}"; do
  create_app tabs "$entry"
done

# Refresh the desktop menu cache when the utility is installed.
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$APPLICATIONS_DIR"
fi

echo
echo "Done."
