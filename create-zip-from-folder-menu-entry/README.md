# Create ZIP from Folder Menu Entry

Adds **Create ZIP from Folder** to the right-click menu in **Nautilus** and **Dolphin**.

## Install

```bash
chmod +x install.sh
./install.sh
```

Requires `zip`:

```bash
sudo dnf install zip
sudo apt install zip
sudo pacman -S zip
sudo zypper install zip
sudo apk add zip
```

## Usage

Right-click a folder and choose **Create ZIP from Folder**.

```text
my-folder/ → my-folder.zip
```

The folder itself stays inside the ZIP. Existing archives are not overwritten:

```text
my-folder.zip
my-folder-2.zip
my-folder-3.zip
```

In Nautilus, the entry appears under **Scripts**. In Dolphin, it appears in the context menu.

## Uninstall

```bash
chmod +x uninstall.sh
./uninstall.sh
```

Symbolic links are stored as links instead of copying the contents of their targets.

## License

MIT License. See `LICENSE`.
