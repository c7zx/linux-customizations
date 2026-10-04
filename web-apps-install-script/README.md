# Web-Apps - Install Script

Creates isolated Chromium web apps on Linux with separate cookies/profiles, custom icons, and optional tabs. Add a website + name, provide an icon, and run the script. Likely works on Debian, Fedora, Ubuntu, and Arch-based desktops. Uses Chromium and standard `.desktop` entries.

---

Create **isolated Chromium web apps** from two short configuration lists.

Each generated app gets its own Chromium profile, separating:

- cookies
- logins
- cache
- local storage
- extensions

The script can be run repeatedly. Existing apps are skipped and only new entries are created.

---

# Requirements

The only required application is **Chromium**.

If Chromium is missing, the script can install it automatically with a supported package manager. Automatic installation is enabled by default, but can be turned off in CONFIG 2.

On Fedora this is equivalent to:

```bash
sudo dnf install chromium
```

---

# First Run

Make the script executable:

```bash
chmod +x install-webapps.sh
```

Run it **without sudo**:

```bash
./install-webapps.sh
```

> Do not run the full script with `sudo`.  
> It creates files inside your own home directory.  
> The script only calls `sudo` itself if Chromium needs to be installed.

---

# Configuration

Normally you only edit **CONFIG 1** at the top of the script.

## Normal Web Apps

These open as app-style Chromium windows without the regular browser tab bar:

```bash
NORMAL_WEBAPPS=(
  "example.com - Example"
  "app.example.com/dashboard - Example Dashboard"
)
```

## Web Apps With Tabs

These open as normal Chromium windows with tabs, but still use an isolated Chromium profile:

```bash
TABBED_WEBAPPS=(
  "example.com - Example Browser"
  "media.example.com - Example Media"
)
```

The format is always:

```text
Website or URL - Display Name
```

`https://` is optional.

Paths and query parameters work too:

```text
app.example.com/?profile=default - Example App
```

---

# Icon Folder

The icon source folder is configured directly in **CONFIG 1**:

```bash
ICON_SOURCE_DIR="$HOME/Pictures/Webapp-Icons/"
```

The folder is required for custom icons.

You do **not** have to create it manually: the script creates it automatically if it is missing.

Place your icon files inside the folder defined in CONFIG 1:

```text
~/Pictures/Webapp-Icons/
```

For the cleanest first setup, put the icon there **before the app is created**.

## Icon Naming

The script derives the expected icon filename from the displayed app name:

- lowercase
- spaces become `-`
- punctuation also becomes `-`

### Example: Example

Config entry:

```text
example.com - Example
```

Generated name:

```text
example
```

Icon:

```text
example.png
```

Full source path, for example:

```text
~/Pictures/Webapp-Icons/example.png
```

### Example: Example Media

Config entry:

```text
media.example.com - Example Media
```

Generated name:

```text
example-media
```

Icon:

```text
example-media.png
```

Full source path, for example:

```text
~/Pictures/Webapp-Icons/example-media.png
```

Supported formats:

```text
.png
.svg
.ico
.webp
.jpg
.jpeg
```

If no matching icon exists when a new app is created, the script uses the generic:

```text
web-browser
```

---

# What Happens to Icons?

Every time the script runs, icons from:

```text
the folder defined under ICON_SOURCE_DIR in CONFIG 1
```

are copied to:

```text
~/.local/share/icons/webapps
```

Rules:

- a target file with the same name is **overwritten**
- deleting an icon from the source folder does **not** delete the already copied target icon
- `~/.local/share/icons/webapps` is the persistent icon store used by the generated launchers

---

# Automatic Names

The displayed app name is converted automatically into a slug.

Examples:

```text
Example App       -> example-app
Example Media     -> example-media
Test Dashboard    -> test-dashboard
My Web App        -> my-web-app
TEST.local        -> test-local
```

That generated value is reused for:

- Chromium profile directories
- icon filenames
- tabbed-app window classes
- tabbed `.desktop` filenames

There is no separate alias list to maintain.

---

# Re-running the Script

The script checks existing `.desktop` launchers for:

```text
Name=...
```

If that display name already exists:

```text
SKIP
```

If it is new:

```text
ADD
```

Typical workflow:

1. Add a line to `NORMAL_WEBAPPS` or `TABBED_WEBAPPS`
2. Put its correctly named icon in the folder defined in CONFIG 1, for example `~/Pictures/Webapp-Icons/`
3. Run the script again

Existing apps are left untouched.

---

# Paths

`ICON_SOURCE_DIR` is in **CONFIG 1** because it is a user-facing setting.

The paths that normally stay unchanged are in **CONFIG 2**:

```bash
ICON_TARGET_DIR="$HOME/.local/share/icons/webapps"
PROFILE_DIR="$HOME/.local/share/chromium-webapps"
APPLICATIONS_DIR="$HOME/.local/share/applications"
AUTO_INSTALL_CHROMIUM=true
```

Default locations:

| Content                 | Location                           |
| ----------------------- | ---------------------------------- |
| Your icon collection    | `~/Pictures/Webapp-Icons/`         |
| Persistent copied icons | `~/.local/share/icons/webapps/`    |
| Chromium profiles       | `~/.local/share/chromium-webapps/` |
| Application launchers   | `~/.local/share/applications/`     |

---

# Optional: Ad Blocking

For Chromium you can use **uBlock Origin Lite**. (The Normal uBlock Orgin is not supported in Chromium, so use the Lite version.)

Short setup:

1. Open Chromium
2. Open the Chrome Web Store
3. Search for `uBlock Origin Lite`
4. Verify that the publisher is **Raymond Hill (gorhill)**
5. Install it

Extensions belong to the Chromium profile where they are installed.

Because the web apps use isolated profiles, the extension may need to be installed separately in each profile where you want it.

---

# Optional: Firefox Favicon Extraction

`firefox-webpage-icons-extraction.sh` extracts saved favicons from a Firefox profile.

The icons are written to:

```text
~/Pictures/Webapp-Icons/extracted
```

The script automatically uses the system's standard Pictures directory, for example `~/Bilder` on German systems.

Before running it, set your Firefox profile path in the configuration section.

```bash
chmod +x firefox-webpage-icons-extraction.sh
./firefox-webpage-icons-extraction.sh
```

---

# Recreate an Existing App

Existing apps are intentionally skipped.

To recreate one, first remove its `.desktop` launcher from:

```text
~/.local/share/applications/
```

Then run the script again.

The corresponding profile under:

```text
~/.local/share/chromium-webapps/
```

contains cookies, logins, and local browser data.

Only delete that profile directory if you also want to reset those data.

---

# Remove a Web App

To remove a web app, delete its `.desktop` launcher from:

```text
~/.local/share/applications/
```

Then delete its Chromium profile if you also want to remove cookies, logins, cache, and other local data:

```text
~/.local/share/chromium-webapps/<app-name>/
```

Optionally, remove its copied icon from:

```text
~/.local/share/icons/webapps/
```

For example, for an app named `Example App`:

```bash
rm ~/.local/share/applications/example.desktop
rm -rf ~/.local/share/chromium-webapps/example
rm ~/.local/share/icons/webapps/example.png
```

Deleting the profile permanently removes that web app's local Chromium data.

