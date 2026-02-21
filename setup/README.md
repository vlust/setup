# Setup (minimal)

Minimal dual-target setup with:
- one config file: `packages.conf`
- one i3 installer for Ubuntu: `install-i3.sh`
- one Omarchy installer: `install-omarchy.sh`

Both scripts:
- update the system
- install one shared common package list + profile packages from `packages.conf`
- clone/pull the same dotfiles repo (`dotfiles` by default path at `$HOME/dotfiles`)
- apply dotfiles via `stow` (common targets include `ghostty`, `nvim`, `starship`, `zed`)
- install `zed` via `curl -f https://zed.dev/install.sh | sh` if missing
- install `uv` via `curl -LsSf https://astral.sh/uv/install.sh | sh` if missing

Platform behavior:
- `install-i3.sh` uses `apt` (Ubuntu/Debian target).
- `install-omarchy.sh` uses `yay` and assumes it is already installed.

## Usage

```bash
chmod +x install-i3.sh install-omarchy.sh
./install-i3.sh
```

or

```bash
./install-omarchy.sh
```

## Dotfiles repo override (optional)

```bash
DOTFILES_REPO=https://github.com/you/dotfiles ./install-i3.sh
DOTFILES_DIR=$HOME/my-dotfiles ./install-omarchy.sh
```
